import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {AssistantMatch, IJob, IAppUser} from "../core/Interfaces";
import {MatchingEngine} from "../services/MatchingEngine";
const db = admin.firestore();

export const matchJobToAssistants = onDocumentCreated(
  "jobs/{jobId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const jobData = snapshot.data() as IJob;
    const jobId = event.params.jobId;

    // 1. Check if location exists before continuing
    if (!jobData.location) {
      console.warn(
        `Job ${event.params.jobId} has no location. Skipping matching.`,
      );
      return snapshot.ref.update({
        status: "pending",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // 2. Extract Job details with defaults
    // Since jobData implements IJob, these fields are fully type-safe!
    const jobLocation = jobData.location;
    const requiredSkills: string[] = jobData.requiredSkills || [];

    try {
      // 3. Fetch all assistants
      const assistantsSnap = await db
        .collection("users")
        .where("role", "==", "assistant")
        .where("isVerified", "==", true)
        .get();

      const distanceMap = new Map<string, number>();

      // 4. Stage 1 filtering  ===============================================
      // Filter by location, budget, gender and
      // general schedule (weekly working hours)
      const nearbyCandidates = assistantsSnap.docs.filter((doc) => {
        const assistant = doc.data() as IAppUser;

        // i. HARD FILTERS (Budget & Gender) =============
        // Computationally cheapest filter (simple comparisons)

        // Checking if daily rate is less than the max
        // daily rate given by the seeker
        if (
          jobData.maxDailyRate &&
          assistant.dailyRate &&
          assistant.dailyRate > jobData.maxDailyRate
        ) {
          return false;
        }

        // Checks if preferred gender matches
        if (
          jobData.preferredGender &&
          jobData.preferredGender !== "unspecified" &&
          assistant.gender !== jobData.preferredGender
        ) {
          return false;
        }
        // ===============================================

        // ii. SCHEDULE FILTER =============================
        // moderate computational cost

        if (
          !MatchingEngine.isTimeCompatible(
            jobData.workingTimes,
            assistant.workingTimes || {},
          )
        ) {
          return false;
        }
        // =================================================

        // iii. GEOLOCATION FILTER ========================
        // Expensive trigonometry math

        const assistantLoc = assistant.location;

        if (!assistantLoc) return false;

        // Calculate Distance
        const dist = MatchingEngine.calculateDistance(
          jobLocation,
          assistantLoc,
        );

        // Only suggest assistants within 40km of Job location
        if (dist > 40) return false;

        distanceMap.set(doc.id, dist); // Store for sorting later
        return true;
      });
      // ==================================================

      // 5. Stage 2 filtering ==================================================
      // (Booking and skill check)
      const matchChecks = nearbyCandidates.map(async (doc) => {
        const assistant = doc.data() as IAppUser;
        const assistantId = doc.id;

        // Check booking dates from the database
        // Expensive due to reading files
        const conflictSnap = await db
          .collection("users")
          .doc(assistantId)
          .collection("bookings")
          .where("status", "==", "confirmed")
          .where("endDate", ">=", jobData.startDate)
          .get();

        // ii. Refined Hour-Level Conflict Check
        const hasActualConflict = conflictSnap.docs.some((bDoc) => {
          const bData = bDoc.data();

          // First, check the logical date overlap (Overlap Theorem)
          // Using .toMillis() ensures safe mathematical
          // comparison of Firebase Timestamps
          const datesOverlap =
            (bData.startDate?.toMillis() ?? 0) <=
            (jobData.endDate?.toMillis() ?? 0);

          if (datesOverlap) {
            // If dates overlap, dive into the hours
            // If doHoursOverlap returns true, it's a real conflict
            return MatchingEngine.doHoursOverlap(
              jobData.workingTimes,
              bData.workingTimes,
            );
          }

          return false;
        });

        if (hasActualConflict) return null;
        // Skill Matching score
        const assistantSkills: string[] = assistant.skills || [];
        const matchingSkills = requiredSkills.filter((skill) =>
          assistantSkills.includes(skill),
        );

        // Match percentage based on required skills
        const matchPercentage =
          requiredSkills.length > 0 ?
            (matchingSkills.length / requiredSkills.length) * 100 : 100;

        const dist = distanceMap.get(assistantId) || 0;

        // Logic: Include if they match at least 50% of skills
        // OR are within 15km
        if (matchPercentage >= 50 || dist < 15) {
          const candidateMatch: AssistantMatch = {
            assistantId: doc.id,
            name: assistant.name || "Assistant",
            distance: Number(dist.toFixed(2)),
            matchScore: Number(matchPercentage.toFixed(1)),
            profilePic: assistant.profilePicUrl || null,
            dailyRate: assistant.dailyRate || 0,
            experienceLevel: assistant.experienceLevel || "unspecified",
          };
          return candidateMatch;
        }
        return null;
      });

      // Execute all sub-collection queries in parallel
      const results = await Promise.all(matchChecks);
      const finalMatches = results.filter(
        (m): m is AssistantMatch => m !== null,
      );

      // 6. Sort: Highest skill match first, then closest distance
      finalMatches.sort((a, b) => {
        if (b.matchScore !== a.matchScore) return b.matchScore - a.matchScore;
        return a.distance - b.distance;
      });

      // Update Job with Top 10 matches
      const top10 = finalMatches.slice(0, 10);

      return snapshot.ref.update({
        topMatches: top10,
        status: top10.length > 0 ? "matching" : "no_matches",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error(`Matching failed for job ${jobId}:`, error);
      return null;
    }
  },
);

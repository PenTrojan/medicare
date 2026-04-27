import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {AssistantMatch} from "../models/interfaces";
import {getDistance, isTimeCompatible} from "../utils/matching-helpers";

const db = admin.firestore();

export const matchJobToAssistants = onDocumentCreated(
  "jobs/{jobId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const jobData = snapshot.data();
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
    const jobLocation = jobData.location as admin.firestore.GeoPoint;
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
        const assistant = doc.data();

        // i. HARD FILTERS (Budget & Gender) =============
        // Computationally cheapest filter (simple comparisons)

        // Checking if daily rate is less than the max
        // daily rate given by the seeker
        if (
          jobData.maxDailyRate &&
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

        if (!isTimeCompatible(jobData.workingTimes, assistant.workingTimes)) {
          return false;
        }
        // =================================================

        // iii. GEOLOCATION FILTER ========================
        // Expensive trigonometry math

        const assistantLoc = assistant.location as
          | admin.firestore.GeoPoint
          | undefined;

        if (!assistantLoc) return false;

        // Calculate Distance
        const dist = getDistance(
          jobLocation.latitude,
          jobLocation.longitude,
          assistantLoc.latitude,
          assistantLoc.longitude,
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
        const assistant = doc.data();
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

        // Logical overlap check
        const isBusy = conflictSnap.docs.some((bDoc) => {
          const bData = bDoc.data();
          return bData.startDate <= jobData.endDate;
        });

        if (isBusy) return null;

        // Skill Matching score
        const assistantSkills: string[] = assistant.skills || [];
        const matchingSkills = requiredSkills.filter((skill) =>
          assistantSkills.includes(skill),
        );

        const dist = distanceMap.get(assistantId) || 0;

        // Logic: Include if they have skills OR are within 15km
        if (matchingSkills.length > 0 || dist < 15) {
          return {
            assistantId: doc.id,
            name: assistant.name || "Assistant",
            distance: Number(dist.toFixed(2)),
            matchScore: matchingSkills.length,
            profilePic: assistant.profilePic || null,
            dailyRate: assistant.dailyRate || 0,
            experienceLevel: assistant.experienceLevel || "unspecified",
          };
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

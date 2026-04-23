import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// Define interfaces for Type Safety
interface AssistantMatch {
  assistantId: string;
  name: string;
  distance: number;
  matchScore: number;
}

/**
 * Helper: Haversine Formula for Distance
 * @param {number} lat1 Latitude of point 1
 * @param {number} lon1 Longitude of point 1
 * @param {number} lat2 Latitude of point 2
 * @param {number} lon2 Longitude of point 2
 * @return {number} Distance in kilometers
 */
function getDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371; // Radius of earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Checks if assistant availability fully covers job requirements.
 * Logic: Assistant must work all job days, and the job window must
 * fit entirely within the assistant's window.
 *
 * @param {any} jobTimes - Map of days to [start, end] times.
 * @param {any} assistantTimes - Map of days to [start, end] times.
 * @return {boolean} True if schedule is compatible.
 */
function isTimeCompatible(
  jobTimes: Record<string, string[]>,
  assistantTimes: Record<string, string[]>,
): boolean {
  // Null checks
  if (!jobTimes || !assistantTimes) return false;

  // Loops through each day
  for (const day in jobTimes) {
    // This if statement satisfies the guard-for-in rule
    if (Object.prototype.hasOwnProperty.call(jobTimes, day)) {
      // If the assistant doesnt work on this day return false
      if (!assistantTimes[day]) return false;

      const [jStart, jEnd] = jobTimes[day];
      const [aStart, aEnd] = assistantTimes[day];

      // String comparison works because times are padded (e.g., "08:00")
      // If Job starts EARLIER than Assistant can start -> Incompatible
      // If Job ends LATER than Assistant can finish -> Incompatible
      if (jStart < aStart || jEnd > aEnd) return false;
    }
  }
  return true;
}

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

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

export const matchJobToAssistants = onDocumentCreated(
  "jobs/{jobId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const jobData = snapshot.data();
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
    const jobId = event.params.jobId;

    // Extract Job details with defaults
    const jobLocation = jobData.location as admin.firestore.GeoPoint;
    const requiredSkills: string[] = jobData.requiredSkills || [];

    try {
      // 1. Fetch all assistants
      const assistantsSnap = await db
        .collection("users")
        .where("role", "==", "assistant")
        .get();

      const potentialMatches: AssistantMatch[] = [];

      assistantsSnap.forEach((doc) => {
        const assistant = doc.data();
        const assistantLoc = assistant.location as
          | admin.firestore.GeoPoint
          | undefined;

        if (assistantLoc) {
          // 2. Calculate Distance
          const dist = getDistance(
            jobLocation.latitude,
            jobLocation.longitude,
            assistantLoc.latitude,
            assistantLoc.longitude,
          );

          // 3. Skill Matching
          const assistantSkills: string[] = assistant.skills || [];
          const matchingSkills = requiredSkills.filter((skill) =>
            assistantSkills.includes(skill),
          );

          // Logic: Include if they have skills OR are within 15km
          if (matchingSkills.length > 0 || dist < 15) {
            potentialMatches.push({
              assistantId: doc.id,
              name: assistant.name || "Assistant",
              distance: Number(dist.toFixed(2)),
              matchScore: matchingSkills.length,
            });
          }
        }
      });

      // 4. Sort: Highest skill match first, then closest distance
      potentialMatches.sort((a, b) => {
        if (b.matchScore !== a.matchScore) return b.matchScore - a.matchScore;
        return a.distance - b.distance;
      });

      // 5. Update Job with Top 5 matches
      const top5 = potentialMatches.slice(0, 5);

      return snapshot.ref.update({
        topMatches: top5,
        status: "matching",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error(`Matching failed for job ${jobId}:`, error);
      return null;
    }
  },
);

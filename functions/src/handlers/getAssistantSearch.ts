import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Public profile parameters exposed safely to unauthenticated clients.
 */
interface MaskedAssistantProfile {
  id: string;
  name: string;
  gender: string;
  profilePicUrl: string | null;
  age: number | null;
  address: string;
  skills: string[];
  workingTimes: Record<string, unknown>;
  dailyRate: number;
  experienceLevel: string;
  bio: string;
  experienceDescription: string;
}

/**
 * HTTPS Cloud Function that retrieves an individual assistant profile.
 * Completely accessible by public unauthenticated anonymous seeker clients.
 *
 * @param {import("firebase-functions/v2/https").HttpsRequest} req - HTTP
 * context containing the target assistantId in the query or body frame.
 * @param {import("firebase-functions/v2/https").Response} res - HTTP response
 * writer channel.
 * @returns {Promise<void>} Resolves when profile evaluation finishes.
 */
export const getPublicAssistantProfile = onRequest(
  {cors: true},
  async (req, res): Promise<void> => {
    try {
      if (req.method !== "GET" && req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      // Read assistantId from query parameters or body payload
      const assistantId = (
        req.query.assistantId as string
      ) || req.body.assistantId;

      if (!assistantId) {
        res.status(400).send("Assistant ID is required.");
        return;
      }

      const doc = await admin
        .firestore()
        .collection("users")
        .doc(assistantId)
        .get();

      if (!doc.exists) {
        res.status(404).send("Assistant profile not found.");
        return;
      }

      const data = doc.data();
      if (!data || data.role !== "assistant") {
        res.status(403).send("Target user is not a Medical Assistant.");
        return;
      }

      const profile: MaskedAssistantProfile = {
        id: doc.id,
        name: data.name || "Assistant",
        gender: data.gender || "unspecified",
        profilePicUrl: data.profilePicUrl || null,
        age: data.age || null,
        address: data.address || "Address not provided",
        skills: Array.isArray(data.skills) ? data.skills : [],
        workingTimes: data.workingTimes || {},
        dailyRate: data.dailyRate ?? 0,
        experienceLevel: data.experienceLevel || "unspecified",
        bio: data.bio || "No bio available.",
        experienceDescription:
          data.experience || "No experience details provided.",
      };

      res.status(200).json(profile);
    } catch (error) {
      console.error("Error fetching public assistant profile:", error);
      res.status(500).send("Internal Server Error");
    }
  }
);

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const getAssistantPublicProfile = onCall(async (request) => {
  // 1. Auth Check
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const assistantId = request.data.assistantId;
  if (!assistantId) {
    throw new HttpsError("invalid-argument", "Assistant ID is required.");
  }

  try {
    const assistantDoc = await db.collection("users").doc(assistantId).get();

    if (!assistantDoc.exists) {
      throw new HttpsError("not-found", "Assistant not found.");
    }

    const data = assistantDoc.data();

    if (!data) {
      throw new HttpsError("not-found", "Assistant data is empty.");
    }

    // 2. Return the Full Public Profile (Masked for Seeker)
    return {
      name: data.name || "Assistant",
      gender: data.gender || "unspecified",
      profilePicUrl: data.profilePicUrl || null,
      age: data.age || null,
      address: data.address || "Address not provided",
      skills: data.skills || [],
      workingTimes: data.workingTimes || {},
      dailyRate: data.dailyRate || 0,
      experienceLevel: data.experienceLevel || "unspecified",
      bio: data.bio || "No bio available.",
      experienceDescription:
        data.experienceDescription || "No experience details provided.",
      // rating and isVerified removed
    };
  } catch (error) {
    console.error("Error fetching public profile:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while fetching the profile.",
    );
  }
});

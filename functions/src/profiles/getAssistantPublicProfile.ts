import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {IAppUser} from "../core/Interfaces";

const db = admin.firestore();

export const getAssistantPublicProfile = onCall(async (request) => {
  const assistantId = request.data.assistantId;
  if (!assistantId) {
    throw new HttpsError("invalid-argument", "Assistant ID is required.");
  }

  if (!assistantId || typeof assistantId !== "string") {
    throw new HttpsError(
      "invalid-argument", "A valid Assistant ID is required."
    );
  }

  try {
    const assistantDoc = await db.collection("users").doc(assistantId).get();

    if (!assistantDoc.exists) {
      throw new HttpsError("not-found", "Assistant not found.");
    }

    const data = assistantDoc.data() as IAppUser;

    if (!data || data.role !== "assistant") {
      throw new HttpsError("permission-denied",
        "Target user is not a registered Medical Assistant."
      );
    }

    // 2. Return the Full Public Profile (Masked for Seeker)
    return {
      id: assistantDoc.id,
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
        data.experienceDescription || "No experience details provided.",
    };
  } catch (error) {
    console.error("Error fetching public profile:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError(
      "internal",
      "An error occurred while fetching the profile.",
    );
  }
});

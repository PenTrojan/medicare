import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Ensure admin is initialized in your entry file (e.g., admin.initializeApp();)
const db = admin.firestore();

// ============================================================================
// 2. RETRY JOB FUNCTION
// ============================================================================
export const retryJob = onCall(async (request) => {
  // 1. Authentication Check
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to retry a job."
    );
  }

  const uid = request.auth.uid;
  const {jobId} = request.data;

  if (!jobId || typeof jobId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with a valid 'jobId'."
    );
  }

  const jobRef = db.collection("jobs").doc(jobId);
  const jobSnap = await jobRef.get();

  // 2. Existence Check
  if (!jobSnap.exists) {
    throw new HttpsError("not-found", "The requested job does not exist.");
  }

  const jobData = jobSnap.data();

  // 3. Authorization Check
  if (jobData?.seekerId !== uid) {
    throw new HttpsError(
      "permission-denied",
      "You do not have permission to modify this job."
    );
  }

  // 4. State Verification (Ensure it's actually in a state that can be retried)
  if (jobData?.status !== "no_matches" && jobData?.status !== "matching") {
    throw new HttpsError(
      "failed-precondition",
      "Only jobs with 'no_matches' or 'matching' status can be retried."
    );
  }

  // 5. Execute Update
  try {
    // This update will trigger your onDocumentWritten matching function!
    await jobRef.update({
      status: "pending",
      topMatches: [], // Clear any old data
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {success: true, message: "Job reset to pending status."};
  } catch (error) {
    console.error(`Error retrying job ${jobId}:`, error);
    throw new HttpsError(
      "internal", "An error occurred while retrying the job."
    );
  }
});

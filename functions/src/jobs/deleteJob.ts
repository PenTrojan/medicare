import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Ensure admin is initialized in your entry file (e.g., admin.initializeApp();)
const db = admin.firestore();

// ============================================================================
// 1. DELETE JOB FUNCTION
// ============================================================================
export const deleteJob = onCall(async (request) => {
  // 1. Authentication Check
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to delete a job."
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

  // 3. Authorization Check (Only the job creator can delete it)
  if (jobData?.seekerId !== uid) {
    throw new HttpsError(
      "permission-denied",
      "You do not have permission to delete this job."
    );
  }

  // Prevent deletion if the job is already active/completed
  if (jobData?.status === "in_progress" || jobData?.status === "completed") {
    throw new HttpsError(
      "failed-precondition",
      "Cannot delete a job that is already in progress or completed."
    );
  }

  // 4. Execute Deletion
  try {
    await jobRef.delete();
    return {success: true, message: "Job successfully deleted."};
  } catch (error) {
    console.error(`Error deleting job ${jobId}:`, error);
    throw new HttpsError(
      "internal", "An error occurred while deleting the job."
    );
  }
});

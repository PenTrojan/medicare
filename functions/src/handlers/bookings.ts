import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const requestAssistantBooking = onCall(async (request) => {
  // 1. Authenticate the Seeker
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const {jobId, assistantId} = request.data;
  const db = admin.firestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const jobRef = db.collection("jobs").doc(jobId);
      const jobDoc = await transaction.get(jobRef);

      // 2. Validate Ownership
      if (!jobDoc.exists || jobDoc.data()?.seekerId !== request.auth?.uid) {
        throw new HttpsError("permission-denied", "You do not own this job.");
      }

      // 3. Create Invitation
      const inviteRef = db.collection("invitations").doc();
      transaction.set(inviteRef, {
        jobId,
        assistantId,
        seekerId: request.auth?.uid,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: true, invitationId: inviteRef.id};
    });
  } catch (error) {
    throw new HttpsError("internal", "Failed to process booking.");
  }
});

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const requestAssistantBooking = onCall(async (request) => {
  // 1. Authenticate the Seeker
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const {jobId, assistantId} = request.data;
  const db = admin.firestore();

  // Create the Composite ID to prevent duplicates
  const inviteId = `${jobId}_${assistantId}`;

  try {
    return await db.runTransaction(async (transaction) => {
      const jobRef = db.collection("jobs").doc(jobId);
      const inviteRef = db.collection("invitations").doc(inviteId);

      const [jobDoc, inviteDoc] = await Promise.all([
        transaction.get(jobRef),
        transaction.get(inviteRef),
      ]);

      // 2. Validate Ownership
      if (!jobDoc.exists || jobDoc.data()?.seekerId !== request.auth?.uid) {
        throw new HttpsError("permission-denied", "You do not own this job.");
      }

      // 3. De-duplication Check
      // only allow a new invitation if one doesn't exist OR
      // if the existing one was declined OR cancelled
      if (
        inviteDoc.exists &&
        inviteDoc.data()?.status !== "declined" &&
        inviteDoc.data()?.status !== "cancelled"
      ) {
        throw new HttpsError(
          "already-exists",
          "An active invitation already exists for this assistant.",
        );
      }

      // 4. Create or Reset Invitation
      transaction.set(
        inviteRef,
        {
          jobId,
          assistantId,
          seekerId: request.auth?.uid,
          patientName: jobDoc.data()?.patientName, // for easy UI rendering
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      ); // Merge: true is important if resetting a declined invite

      return {success: true, invitationId: inviteRef.id};
    });
  } catch (error) {
    // If it's one of our thrown HttpsErrors, pass it through
    if (error instanceof HttpsError) throw error;

    // Otherwise, throw a generic internal error
    console.error("Booking Transaction Error:", error);
    throw new HttpsError("internal", "Failed to process booking.");
  }
});

export const cancelAssistantBooking = onCall(async (request) => {
  // 1. Authenticate
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const {jobId, assistantId} = request.data;
  const inviteId = `${jobId}_${assistantId}`;
  const db = admin.firestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const inviteRef = db.collection("invitations").doc(inviteId);
      const inviteDoc = await transaction.get(inviteRef);

      // 2. Validate Ownership & Existence
      if (!inviteDoc.exists) {
        throw new HttpsError("not-found", "Invitation does not exist.");
      }

      if (inviteDoc.data()?.seekerId !== request.auth?.uid) {
        throw new HttpsError(
          "permission-denied",
          "You do not own this request.",
        );
      }

      // 3. Perform Soft Delete (Status Update)
      transaction.update(inviteRef, {
        status: "cancelled",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: true};
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to cancel booking.");
  }
});

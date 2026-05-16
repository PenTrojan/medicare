import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// ==============================================================
// ===================== 1. CREATION ============================
// ==============================================================

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

// ==============================================================
// ===================== 2. CANCELLATION ========================
// ==============================================================

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

// ==============================================================
// ===================== 3. ACCEPT ==============================
// ==============================================================

export const acceptInvitation = onCall(async (request) => {
  // 1. Authenticate the Assistant
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const {jobId, assistantId} = request.data;
  const uid = request.auth.uid;
  const inviteId = `${jobId}_${assistantId}`;
  const db = admin.firestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const inviteRef = db.collection("invitations").doc(inviteId);
      const jobRef = db.collection("jobs").doc(jobId);
      const assistantRef = db.collection("users").doc(assistantId);
      const bookingRef = assistantRef.collection("bookings").doc(jobId);

      const [inviteDoc, jobDoc] = await Promise.all([
        transaction.get(inviteRef),
        transaction.get(jobRef),
      ]);

      // 2. Initial Validations
      if (!inviteDoc.exists || !jobDoc.exists) {
        throw new Error("Required documents (Job or Invitation) not found.");
      }

      const inviteData = inviteDoc.data();
      const jobData = jobDoc.data();

      // Security Check: Only the invited assistant can accept
      if (inviteData?.assistantId !== uid) {
        throw new Error("Unauthorized: You were not invited to this job.");
      }

      // State Check: Prevent double-processing
      if (inviteData?.status !== "pending") {
        throw new Error("This invitation is no longer pending.");
      }

      // 3. Update the Invitation Lifecycle
      transaction.update(inviteRef, {
        status: "accepted",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 4. Update the Job Status (Mapped to JobStatus.assigned)
      transaction.update(jobRef, {
        status: "assigned",
        assignedAssistantId: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 5. Update Assistant Profile Flags
      transaction.update(assistantRef, {
        isBooked: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 6. Create the Booking entry for the Matching Algorithm
      // This ensures the overlap check captures this commitment
      transaction.set(bookingRef, {
        jobId: jobId,
        seekerId: jobData?.seekerId,
        patientName: jobData?.patientName,
        startDate: jobData?.startDate, // Stored as Timestamp
        endDate: jobData?.endDate, // Stored as Timestamp
        workingTimes: jobData?.workingTimes, // Map<String, List<String>>
        status: "confirmed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 7. Cleanup: Automatically cancel other pending invitations for this Job
      const otherInvitesQuery = await db
        .collection("invitations")
        .where("jobId", "==", jobId)
        .where("status", "==", "pending")
        .get();

      otherInvitesQuery.docs.forEach((doc) => {
        if (doc.id !== inviteId) {
          transaction.update(doc.ref, {
            status: "cancelled_by_system",
            reason: "Job assigned to another assistant",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      return {success: true, message: "Job successfully accepted and booked."};
    });
  } catch (error: unknown) {
    // Log the error for Firebase logs
    console.error("Accept Invitation Error:", error);

    // Safely extract the message
    let errorMessage = "Failed to accept job.";

    if (error instanceof Error) {
      errorMessage = error.message;
    }

    // Pass the specific error back to Flutter
    throw new HttpsError("internal", errorMessage);
  }
});

// ==============================================================
// ===================== 4. DECILNE =============================
// ==============================================================

export const declineInvitation = onCall(async (request) => {
  // 1. Authenticate the Assistant
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const {jobId, assistantId} = request.data;

  // Reuse the composite ID logic
  const inviteId = `${jobId}_${assistantId}`;
  const db = admin.firestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const inviteRef = db.collection("invitations").doc(inviteId);
      const inviteDoc = await transaction.get(inviteRef);

      // 2. Validate Existence
      if (!inviteDoc.exists) {
        throw new Error("Invitation not found.");
      }

      // 3. Security: Only the invited assistant can decline
      if (inviteDoc.data()?.assistantId !== request.auth?.uid) {
        throw new Error("You are not authorized to decline this invitation.");
      }

      // 4. State Check: Can only decline if it's still pending
      if (inviteDoc.data()?.status !== "pending") {
        throw new Error("Invitation is no longer pending.");
      }

      // 5. Perform the update
      transaction.update(inviteRef, {
        status: "declined",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: true};
    });
  } catch (error: unknown) {
    console.error("Decline Transaction Error:", error);

    // Default message in case the error isn't a standard object
    let message = "Failed to decline invitation.";

    if (error instanceof Error) {
      message = error.message;
    }

    throw new HttpsError("internal", message);
  }
});

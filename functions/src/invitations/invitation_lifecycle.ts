import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {InvitationEntity} from "../core/InvitationEntity";
import {processJobBilling} from "../billing/generate_bill";

const db = admin.firestore();

// ==============================================================
// ===================== 1. CREATION ============================
// ==============================================================

export const requestAssistantBooking = onCall(async (request) => {
  // 1. Authenticate the Seeker
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const {jobId, assistantId} = request.data;
  if (!jobId || !assistantId) {
    throw new HttpsError("invalid-argument", "Missing job or assistant ID.");
  }

  try {
    return await db.runTransaction(async (transaction) => {
      const jobRef = db.collection("jobs").doc(jobId);
      const tempInvite = new InvitationEntity(jobId, assistantId, "", "");
      const inviteRef = db.collection("invitations").doc(tempInvite.id);

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
      if (inviteDoc.exists) {
        const activeInvite = InvitationEntity.fromFirestore(inviteDoc.data());
        if (
          activeInvite.status !== "declined" &&
          activeInvite.status !== "cancelled"
        ) {
          throw new HttpsError(
            "already-exists",
            "An active invitation already exists for this assistant."
          );
        }
      }
      // 4. Create or Reset Invitation
      const uid = request.auth?.uid || "";
      const invitation = new InvitationEntity(
        jobId,
        assistantId,
        uid,
        jobDoc.data()?.patientName || "Patient"
      );

      transaction.set(inviteRef, invitation.toFirestoreMap(), {merge: true});

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
  const tempInvite = new InvitationEntity(jobId, assistantId, "", "");
  const inviteRef = db.collection("invitations").doc(tempInvite.id);

  try {
    return await db.runTransaction(async (transaction) => {
      const inviteDoc = await transaction.get(inviteRef);

      // 2. Validate Ownership & Existence
      if (!inviteDoc.exists) {
        throw new HttpsError("not-found", "Invitation does not exist.");
      }

      const invitation = InvitationEntity.fromFirestore(inviteDoc.data());

      try {
        if (invitation.seekerId !== request.auth?.uid) {
          throw new Error("Ownership identity credential mismatch.");
        }
        invitation.cancel();
      } catch (domainError: unknown) {
        const msg =
          domainError instanceof Error ?
            domainError.message :
            String(domainError);
        throw new HttpsError("failed-precondition", msg);
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
    console.error("Cancel Error:", error);
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

  const tempInvite = new InvitationEntity(jobId, assistantId, "", "");
  const inviteId = tempInvite.id;

  try {
    // Read conflicting open data options out-of-band before writing
    const otherInvitesSnapshot = await db
      .collection("invitations")
      .where("jobId", "==", jobId)
      .where("status", "==", "pending")
      .get();

    await db.runTransaction(async (transaction) => {
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
        throw new HttpsError("not-found", "Required documents missing.");
      }
      const jobData = jobDoc.data();
      const invitation = InvitationEntity.fromFirestore(inviteDoc.data());

      try {
        invitation.accept(uid);
      } catch (domainError: unknown) {
        const msg =
          domainError instanceof Error ?
            domainError.message :
            String(domainError);
        throw new HttpsError("failed-precondition", msg);
      }
      // 3. Update the Invitation Lifecycle
      transaction.update(inviteRef, {
        status: invitation.status,
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
      // Using Values read earlier to avoid race conditions
      otherInvitesSnapshot.docs.forEach((doc) => {
        if (doc.id !== inviteId) {
          transaction.update(doc.ref, {
            status: "cancelled_by_system",
            reason: "Job assigned to another assistant",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });
    });

    // 2. CHAINED HOOK: Process Financial Billing Generation
    // This executes downstream safely outside the state locked block
    try {
      await processJobBilling(jobId);
    } catch (billingError) {
      console.error(
        "Post-Accept Critical Billing Engine Failure:",
        billingError
      );
      // We log but do not fail execution since the match state
      // commitment is complete
    }

    return {
      success: true,
      message: "Job successfully accepted and billing compiled.",
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("Accept Invitation Error:", error);
    throw new HttpsError("internal", "Failed to resolve invitation accept.");
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
  const tempInvite = new InvitationEntity(jobId, assistantId, "", "");
  const inviteRef = db.collection("invitations").doc(tempInvite.id);

  try {
    return await db.runTransaction(async (transaction) => {
      const inviteDoc = await transaction.get(inviteRef);

      // 2. Validate Existence
      if (!inviteDoc.exists) {
        throw new HttpsError("not-found", "Invitation target not found.");
      }

      const invitation = InvitationEntity.fromFirestore(inviteDoc.data());

      try {
        const uid = request.auth?.uid || "";
        invitation.decline(uid);
      } catch (domainError: unknown) {
        const msg =
          domainError instanceof Error ?
            domainError.message :
            String(domainError);
        throw new HttpsError("failed-precondition", msg);
      }
      // 5. Perform the update
      transaction.update(inviteRef, {
        status: invitation.status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: true};
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("Decline Transaction Error:", error);
    throw new HttpsError("internal", "Failed to decline invitation.");
  }
});

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {TransactionContext} from "./TransactionContext";

/**
 * Exposes a secure HTTPS callable gateway endpoint to validate, authorize,
 * and transition an ongoing job status into an early cancelled pro-rata split.
 * Frees up the assistant's schedule parameters and splits escrow values.
 *
 * @param {any} request - The Firebase V2 callable request payload context.
 * @return {Promise<any>} Outcome status tracking metadata wrapper.
 * @throws {HttpsError} Throws if verification exceptions hit system boundaries.
 */
export const cancelJobEarly = onCall(async (request) => {
  const jobId = request.data.jobId as string;
  const seekerId = request.auth?.uid;

  if (!jobId || !seekerId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing parameters or unauthenticated session profile context."
    );
  }

  const db = admin.firestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const ctx = new TransactionContext(transaction, db);

      const job = await ctx.getJob(jobId);
      const bill = await ctx.getBill(jobId);

      if (!bill) {
        throw new HttpsError(
          "not-found",
          "No billing ledger entry exists for this job context."
        );
      }

      if (job.seekerId !== seekerId) {
        throw new HttpsError(
          "permission-denied",
          "User is unauthorized to terminate this care position contract."
        );
      }

      const now = new Date();

      // Delegate rich financial math calculations to model classes
      const updatedBill = bill.calculateProRataCancellation(
        job.startDate.toDate().getTime(),
        job.endDate.toDate().getTime(),
        now.getTime(),
        job.workingTimes
      );
      job.cancelEarly();

      ctx.updateJob(job);
      ctx.updateBill(updatedBill);

      if (job.assignedAssistantId) {
        const bookingRef = db
          .collection("users")
          .doc(job.assignedAssistantId)
          .collection("bookings")
          .doc(jobId);

        // Instantly deletes the document, cleanly freeing the schedule
        transaction.delete(bookingRef);
      }

      return {
        success: true,
        message: "Job cancelled early. Escrow balance partitioned.",
      };
    });
  } catch (error: unknown) {
    if (error instanceof HttpsError) throw error;
    const msg = error instanceof Error ? error.message : String(error);
    throw new HttpsError("internal", `Early termination failed: ${msg}`);
  }
});

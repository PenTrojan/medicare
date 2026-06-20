import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {TransactionContext} from "../services/TransactionContext";

/**
 * Exposes a secure HTTPS callable gateway endpoint to validate, authorize,
 * and transition a ledger record state into a locked escrow block.
 *
 * @param {any} request - The Firebase V2 callable request payload context.
 * @return {Promise<any>} An outcome status tracking metadata
 *                        verification wrapper.
 * @throws {HttpsError} Throws if execution exceptions hit internal boundaries.
 */
export const confirmEscrowPayment = onCall(async (request) => {
  const jobId = request.data.jobId as string;
  // Fallback to standard request authentication context variables securely
  const seekerId = request.auth?.uid;

  if (!jobId || !seekerId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters or unauthenticated session context."
    );
  }

  const db = admin.firestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const ctx = new TransactionContext(transaction, db);

      // 1. Fetch active domain entities atomically via wrapper structures
      const job = await ctx.getJob(jobId);
      const bill = await ctx.getBill(jobId);

      if (!bill) {
        throw new HttpsError(
          "not-found",
          "No billing ledger entry exists for this job."
        );
      }

      // 2. Validate Authorization parameters
      if (job.seekerId !== seekerId) {
        throw new HttpsError(
          "permission-denied",
          "User is unauthorized to fund this invoice."
        );
      }

      // 3. State Engine Verification
      if (bill.escrowSummary.financialStatus !== "GENERATED") {
        return {
          success: true,
          message: "Payment already captured or released.",
        };
      }

      // 4. Mutate state securely through the entity domain layer code
      const fundedBill = bill.transitionToEscrowHeld();

      // 5. Persist back to database tier using Unit of Work updates
      ctx.updateBill(fundedBill);

      return {
        success: true,
        message: "Capital locked in secured escrow successfully.",
      };
    });
  } catch (error: unknown) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError(
      "internal",
      "Failed to finalize escrow authorization."
    );
  }
});

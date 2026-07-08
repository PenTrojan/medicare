import {HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {TransactionContext} from "./TransactionContext";
import {BillEntity} from "../core/BillEntity";

/**
 * Processes and generates the billing ledger configuration for a given job.
 * Called internally during the invitation acceptance lifecycle.
 *
 * @param {string} jobId - The target unique identifier of the job.
 * @return {Promise<any>} The transaction mapping status metadata outcome.
 */export async function processJobBilling(jobId: string) {
  if (!jobId) {
    throw new HttpsError("invalid-argument", "Missing target jobId parameter.");
  }

  const db = admin.firestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const ctx = new TransactionContext(transaction, db);

      // Clean, atomic, parallel entity reads
      const job = await ctx.getJob(jobId);
      const existingBill = await ctx.getBill(jobId);

      // Idempotency check: Stops double processing network requests
      if (existingBill) {
        return {
          success: true,
          message: "Ledger mapping already compiled.",
          billId: existingBill.id,
        };
      }

      try {
      // Delegate calculation entirely to the hourly domain engine
        const bill = BillEntity.calculate(
          job.id,
          job.seekerId,
          job.assignedAssistantId || "",
          job.startDate.toDate().getTime(),
          job.endDate.toDate().getTime(),
          job.maxDailyRate,
          job.workingTimes,
        );

        // Atomic transaction commit write
        ctx.saveBill(bill);

        return {
          success: true,
          message: "Invoice ledger initialized securely.",
          totalDue: bill.escrowSummary.totalRequiredFromSeeker,
        };
      } catch (domainError: unknown) {
        const msg =
          domainError instanceof Error ?
            domainError.message :
            String(domainError);
        throw new HttpsError("failed-precondition", msg);
      }
    });
  } catch (error: unknown) {
    if (error instanceof HttpsError) throw error;
    const errMsg = error instanceof Error ? error.message : String(error);
    console.error("Billing Engine Exception:", errMsg);
    throw new HttpsError(
      "internal",
      "An error occurred within the isolated billing domain engine.",
    );
  }
}

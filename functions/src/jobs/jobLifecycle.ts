import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import {TransactionContext} from "../billing/TransactionContext";

const db = admin.firestore();

/**
 * Automated lifecycle state engine that runs daily at midnight.
 * Adheres to 80 character limit boundaries and clean domain formatting.
 */
export const dailyJobLifecycleCron = onSchedule(
  {
    schedule: "every day 00:00",
    timeZone: "Asia/Colombo",
    memory: "512MiB",
  },
  async (event) => {
    const now = new Date();
    const nowTimestamp = admin.firestore.Timestamp.fromDate(now);

    console.log(`[JobEngine] Cycle init: ${now.toISOString()}`);

    // =========================================================================
    // PHASE 1: AUTO-ACTIVATE UPCOMING ASSIGNED JOBS
    // =========================================================================
    try {
      const upcomingJobs = await db.collection("jobs")
        .where("status", "==", "assigned")
        .where("startDate", "<=", nowTimestamp)
        .get();

      const activationPromises = upcomingJobs.docs.map((jobDoc) => {
        return db.runTransaction(async (transaction) => {
          const ctx = new TransactionContext(transaction, db);
          const job = await ctx.getJob(jobDoc.id);

          job.activate();
          ctx.updateJob(job); // Persists entity status safely
        });
      });
      await Promise.allSettled(activationPromises);
    } catch (err) {
      console.error("[JobEngine] Activation phase failed:", err);
    }

    // =========================================================================
    // PHASE 2: NATURALLY EXPIRE ACTIVE COMPLETED JOBS
    // =========================================================================
    try {
      const expiredJobs = await db.collection("jobs")
        .where("status", "==", "in_progress")
        .where("endDate", "<=", nowTimestamp)
        .get();

      const expirationPromises = expiredJobs.docs.map((jobDoc) => {
        return db.runTransaction(async (transaction) => {
          const ctx = new TransactionContext(transaction, db);
          const job = await ctx.getJob(jobDoc.id);
          const bill = await ctx.getBill(jobDoc.id);

          if (!bill) return;

          // Mutate through rich business logic contracts
          job.complete();
          const updatedBill = bill.releaseFullEscrow();

          ctx.updateJob(job);
          ctx.updateBill(updatedBill);

          if (job.assignedAssistantId) {
            const bookingRef = db.collection("users")
              .doc(job.assignedAssistantId)
              .collection("bookings")
              .doc(jobDoc.id);

            // Destroys the active schedule index since the job is done
            transaction.delete(bookingRef);
          }
        });
      });
      await Promise.allSettled(expirationPromises);
    } catch (err) {
      console.error("[JobEngine] Expiration phase failed:", err);
    }
  },
);

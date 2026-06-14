import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * GENERATE JOB BILL CONTROLLER
 * (Controller Design Pattern)
 * Triggered automatically when an assistant accepts an invitation.
 * Calculates duration, structures fees, and initializes the escrow ledger.
 */

export const generateJobBill = onCall({cors: true}, async (request) => {
  // 1. SECURITY & INTEGRITY GATEKEEPING CHECK
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication credentials invalid.",
    );
  }

  // Extract input parameters from mobile app network payload
  const {jobId} = request.data;
  if (!jobId) {
    throw new HttpsError("invalid-argument", "Missing target jobId parameter.");
  }

  const db = admin.firestore();

  try {
    // 2. ISOLATED TRANSACTION BLOCK
    // (Prevents concurrent modification race conditions)
    // Using a Firestore transaction
    // ensures that the data inside jobs collection cannot be modified
    // by another user while this calculation is happening.
    return await db.runTransaction(async (transaction) => {
      const jobRef = db.collection("jobs").doc(jobId);
      const billRef = db.collection("bills").doc(jobId);

      // Perform atomic parallel document reads
      const [jobDoc, billDoc] = await Promise.all([
        transaction.get(jobRef),
        transaction.get(billRef),
      ]);

      // Assert that target context exists to
      // prevent operating on missing profiles
      if (!jobDoc.exists) {
        throw new HttpsError(
          "not-found",
          "The specified job profile does not exist.",
        );
      }

      // Idempotency Check: Prevents overwriting
      // financial states if executed twice
      if (billDoc.exists) {
        return {
          success: true,
          message: "Ledger mapping already compiled.",
          billId: billRef.id,
        };
      }

      const jobData = jobDoc.data();

      // non-null protection fallback check
      if (!jobData) {
        throw new HttpsError(
          "failed-precondition",
          "The job document does not contain valid data fields.",
        );
      }

      // 3. TEMPORAL CALENDAR MATH
      // (Converts Firestore Timestamps to native ms integers)
      const start = jobData.startDate.toDate().getTime();
      const end = jobData.endDate.toDate().getTime();
      const timeDifference = end - start;

      // Assert chronological validity
      if (timeDifference < 0) {
        throw new HttpsError(
          "failed-precondition",
          "Invalid temporal range: End date is prior to start date.",
        );
      }

      // Convert millisecond delta into day periods
      // (Rounds up, minimum 1 day baseline)
      const totalDays = Math.max(
        1,
        Math.ceil(timeDifference / (1000 * 60 * 60 * 24)),
      );
      const dailyRate = jobData.maxDailyRate;

      // 4. FINANCIAL EQUATION SYSTEM CALCULATIONS
      const grossContractValue = totalDays * dailyRate; // Base raw cost
      // 10% System application marketplace fee split
      const platformFeeRate = 0.1;
      const platformFeeAmount = Math.round(
        grossContractValue * platformFeeRate,
      );
      // 2% Regulatory platform infrastructure tax surcharge
      const taxRate = 0.02;
      const taxAmount = Math.round(grossContractValue * taxRate);

      // Final calculations: Seeker pays extra charges;
      // Assistant receives base cost minus fee
      const totalRequiredFromSeeker = grossContractValue + taxAmount;
      const netAssistantPayout = grossContractValue - platformFeeAmount;

      // 5. IMMUTABLE ACCOUNT LEDGER PAYLOAD SCHEMA
      const billPayload = {
        // Uses jobId as document ID to cleanly decouple yet associate tables
        id: jobId,
        metadata: {
          jobId,
          seekerId: jobData.seekerId,
          assistantId: jobData.assignedAssistantId,
        },
        pricingStructure: {
          totalDays,
          dailyRate,
          grossContractValue,
        },
        financialBreakdown: {
          platformFeeRate,
          platformFeeAmount,
          netAssistantPayout,
          taxRate,
          taxAmount,
        },
        escrowSummary: {
          totalRequiredFromSeeker,
          // Starts at zero until seeker submits payment
          currentEscrowBalance: 0,
          // Operational states: GENERATED -> ESCROW_HELD -> RELEASED
          financialStatus: "GENERATED",
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Write transaction payload record down into the immutable database tier
      transaction.set(billRef, billPayload);

      return {
        success: true,
        message: "Invoice ledger initialized securely.",
        totalDue: totalRequiredFromSeeker,
      };
    });
  } catch (error) {
    console.error("Billing Engine Exception:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError(
      "internal",
      "An error occurred within the isolated billing domain engine.",
    );
  }
});

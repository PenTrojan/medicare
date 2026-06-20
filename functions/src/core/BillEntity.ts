import {IBill} from "./Interfaces";
import {BILLING_CONFIG} from "../config/BillingConfig";

/**
 * Represents a domain financial ledger invoice for matching milestones.
 */
export class BillEntity implements IBill {
  /**
   * Symmetrical constructor handling structured billing aggregates.
   * @param {string} id The unique identifier of the billing instance.
   * @param {any} metadata Matching stakeholder context.
   * @param {any} pricingStructure Unit rates and values.
   * @param {any} financialBreakdown Deductions, tax.
   * @param {any} escrowSummary Current balance conditions.
   */
  constructor(
    public readonly id: string,
    public readonly metadata: IBill["metadata"],
    public readonly pricingStructure: IBill["pricingStructure"],
    public readonly financialBreakdown: IBill["financialBreakdown"],
    public readonly escrowSummary: IBill["escrowSummary"],
  ) {}

  // ==========================================================================
  // FACTORY METHODS
  // ==========================================================================

  /**
   * Converts Firestore document data into a Bill entity.
   * @param {any} docData The raw data maps from Firestore.
   * @return {BillEntity} A newly instantiated Bill entity.
   */
  public static fromFirestore(docData: unknown): BillEntity {
    if (!docData) {
      throw new Error("Target billing ledger snapshot payload is empty.");
    }
    // Cast to an untyped indexable object so we can read keys safely
    const data = docData as Record<string, unknown>;
    // Explicit type casing for nested indexing to satisfy no-explicit-any
    const id = data.id as string;
    const meta = data.metadata as Record<string, string>;
    const pricing = data.pricingStructure as Record<string, number>;
    const finance = data.financialBreakdown as Record<string, number>;
    const escrow = data.escrowSummary as Record<string, unknown>;
    return new BillEntity(
      id,
      {
        jobId: meta.jobId,
        seekerId: meta.seekerId,
        assistantId: meta.assistantId,
      },
      {
        totalDays: pricing.totalDays,
        dailyRate: pricing.dailyRate,
        grossContractValue: pricing.grossContractValue,
      },
      {
        platformFeeRate: finance.platformFeeRate,
        platformFeeAmount: finance.platformFeeAmount,
        netAssistantPayout: finance.netAssistantPayout,
        taxRate: finance.taxRate,
        taxAmount: finance.taxAmount,
      },
      {
        totalRequiredFromSeeker: escrow.totalRequiredFromSeeker as number,
        currentEscrowBalance: (escrow.currentEscrowBalance as number) || 0,
        financialStatus:
          escrow.financialStatus as IBill["escrowSummary"]["financialStatus"],
      },
    );
  }

  /**
   * CORE DOMAIN ENGINE: Parses explicit start/end string timestamps,
   * accumulates total hours worked, and divides by an 8-hour standard day.
   * @param {string} jobId Associated healthcare milestone identifier.
   * @param {string} seekerId Target patient client payload context.
   * @param {string} assistantId Medical support professional identifier.
   * @param {number} startMs Operational shift boundary initiation epoch.
   * @param {number} endMs Operational shift boundary finalization epoch.
   * @param {number} dailyRate Base fiat compensation structure for matching.
   * @param {Record<string, string[]>} workingTimes Operational week schedules.
   * @return {BillEntity} Formatted financial breakdown matching criteria.
   */
  public static calculate(
    jobId: string,
    seekerId: string,
    assistantId: string,
    startMs: number,
    endMs: number,
    dailyRate: number,
    workingTimes: Record<string, string[]>,
  ): BillEntity {
    if (endMs < startMs) {
      throw new Error("Chronological Error: End date is prior to start date.");
    }

    let totalHoursAccumulated = 0;
    const currentCursor = new Date(startMs);

    const weekDays = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];

    // 1. Accumulate total hours across the calendar range
    while (currentCursor.getTime() <= endMs) {
      const dayName = weekDays[currentCursor.getDay()];
      const timeArray = workingTimes[dayName];

      if (timeArray && timeArray.length >= 2) {
        const startStr = timeArray[0]; // e.g., "09:00"
        const endStr = timeArray[1]; // e.g., "21:00"

        const [startHours, startMins] = startStr.split(":").map(Number);
        const [endHours, endMins] = endStr.split(":").map(Number);

        const startTimeDecimal = startHours + startMins / 60;
        const endTimeDecimal = endHours + endMins / 60;

        const shiftDuration = endTimeDecimal - startTimeDecimal;
        if (shiftDuration > 0) {
          totalHoursAccumulated += shiftDuration;
        }
      }

      currentCursor.setDate(currentCursor.getDate() + 1);
    }

    // 2. Convert total accumulated hours into standard 8-hour day units
    const calculatedDays =
      totalHoursAccumulated / BILLING_CONFIG.HOURS_PER_STANDARD_DAY;

    // Safety Floor: Guarantee a baseline minimum of 1 standard billing unit
    const finalBillableDays = Math.max(
      1,
      parseFloat(calculatedDays.toFixed(2)),
    );

    // 3. Execute core system financial equations
    const grossContractValue = Math.round(finalBillableDays * dailyRate);
    const platformFeeAmount = Math.round(
      grossContractValue * BILLING_CONFIG.PLATFORM_FEE_RATE,
    );
    const taxAmount = Math.round(grossContractValue * BILLING_CONFIG.TAX_RATE);
    const totalRequiredFromSeeker = grossContractValue + taxAmount;
    const netAssistantPayout = grossContractValue - platformFeeAmount;

    // Instantiates matching the symmetrical structural interface 1:1
    return new BillEntity(
      jobId,
      {jobId, seekerId, assistantId},
      {totalDays: finalBillableDays, dailyRate, grossContractValue},
      {
        platformFeeRate: BILLING_CONFIG.PLATFORM_FEE_RATE,
        platformFeeAmount,
        netAssistantPayout,
        taxRate: BILLING_CONFIG.TAX_RATE,
        taxAmount,
      },
      {
        totalRequiredFromSeeker,
        currentEscrowBalance: 0,
        financialStatus: "GENERATED",
      },
    );
  }

  /**
  * Transitions the billing ledger entity status into secure escrow holding.
  * Allocates the required balance matching the seeker funding obligations.
  * Because properties are readonly this return a new object wit
  * updated values.
  *
  * @return {BillEntity} A newly instantiated Bill entity with updated state.
  */
  public transitionToEscrowHeld(): BillEntity {
    return new BillEntity(
      this.id,
      this.metadata,
      this.pricingStructure,
      this.financialBreakdown,
      {
        ...this.escrowSummary,
        financialStatus: "ESCROW_HELD",
        currentEscrowBalance: this.escrowSummary.totalRequiredFromSeeker,
      }
    );
  }

  /**
   * Serializes the domain class properties back into database schema.
   * @return {Record<string, unknown>} Transformed database collection mapper.
   */
  public toFirestoreMap(): Record<string, unknown> {
    return {
      id: this.id,
      metadata: this.metadata,
      pricingStructure: this.pricingStructure,
      financialBreakdown: this.financialBreakdown,
      escrowSummary: this.escrowSummary,
    };
  }
}

import * as admin from "firebase-admin";
import {IJob, AssistantMatch} from "./Interfaces";

/**
 * DOMAIN ENTITY: JOB CASE POSITIONING
 * (GRASP Information Expert Design Pattern)
 * Encapsulates the transactional properties, temporal math rules,
 * and operational invariant boundaries governing a care job case
 * lifecycle.
 */
export class JobEntity implements IJob {
  /**
   * @param {string} id Unique document identifier for the job.
   * @param {string} seekerId The unique user token of the client.
   * @param {string} patientName The designated recipient of care.
   * @param {admin.firestore.Timestamp} startDate Commencement time.
   * @param {admin.firestore.Timestamp} endDate Concluding boundary.
   * @param {number} maxDailyRate Budget boundary set by seeker.
   * @param {any} workingTimes Day shift hours map layout.
   * @param {string[]} requiredSkills Array of medical skills needed.
   * @param {string} preferredGender Gender constraint flag.
   * @param {string} status Current checkpoint tracking state.
   * @param {string} [assignedAssistantId] Selected provider token.
   * @param {any[]} [topMatches] Pre-calculated candidate arrays.
   */
  constructor(
    public readonly id: string,
    public readonly seekerId: string,
    public readonly patientName: string,
    public readonly startDate: admin.firestore.Timestamp,
    public readonly endDate: admin.firestore.Timestamp,
    public readonly maxDailyRate: number,
    public readonly workingTimes: Record<string, string[]>,
    public readonly requiredSkills: string[],
    public readonly preferredGender: IJob["preferredGender"],
    public status: IJob["status"] = "pending",
    public assignedAssistantId?: string,
    public topMatches: AssistantMatch[] = [],
  ) {}

  /**
   * Domain Rule Invariant: Shifts job from assigned state into active progress.
   */
  public activate(): void {
    if (this.status !== "assigned") {
      throw new Error("Domain Rule Exception: Job must be assigned to start.");
    }
    this.status = "in_progress";
  }

  /**
   * Domain Rule Invariant: Closes out a completed job safely.
   */
  public complete(): void {
    if (this.status !== "in_progress") {
      throw new Error("Domain Rule Exception: Only running jobs can complete.");
    }
    this.status = "completed";
  }

  /**
   * Domain Rule Invariant: Handles manual early cancellation routing.
   */
  public cancelEarly(): void {
    if (this.status !== "assigned" && this.status !== "in_progress") {
      throw new Error("Domain Rule Exception: Job is not in an active state.");
    }
    this.status = "cancelled";
  }

  /**
   * Domain Rule Invariant: Safely shifts status checkpoints.
   * Ensures that race conditions cannot double-assign a filled job.
   * @param {string} assistantId Target provider token for enrollment.
   * @return {void}
   * @throws {Error} Throws if position execution thresholds are filled.
   */
  public assignTo(assistantId: string): void {
    if (this.status === "assigned" || this.assignedAssistantId) {
      throw new Error(
        "Domain Rule Exception: This care job context is already filled.",
      );
    }

    this.status = "assigned";
    this.assignedAssistantId = assistantId;
  }
  /**
   * Serializes active functional internal states back to flat objects.
   * @return {Record<string, unknown>} Data map ready for Firestore writes.
   */
  public toFirestoreMap(): Record<string, unknown> {
    return {
      seekerId: this.seekerId,
      patientName: this.patientName,
      startDate: this.startDate,
      endDate: this.endDate,
      maxDailyRate: this.maxDailyRate,
      workingTimes: this.workingTimes,
      requiredSkills: this.requiredSkills,
      preferredGender: this.preferredGender,
      status: this.status,
      topMatches: this.topMatches,
      ...(this.assignedAssistantId && {
        assignedAssistantId: this.assignedAssistantId,
      }),
    };
  }
}

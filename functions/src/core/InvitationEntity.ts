import {IInvitation} from "./Interfaces";

/**
 * DOMAIN ENTITY: INVITATION
 * (Information Expert Design Pattern)
 * Encapsulates state validation rules and life-cycle boundaries
 * for care booking invitations.
 */
export class InvitationEntity implements IInvitation {
  public readonly id: string;

  constructor(
    public readonly jobId: string,
    public readonly assistantId: string,
    public readonly seekerId: string,
    public readonly patientName: string,
    public status: IInvitation["status"] = "pending",
    public reason?: string,
  ) {
    // Computes a unified composite document ID matching our database structure
    this.id = `${this.jobId}_${this.assistantId}`;
  }

  /**
   * Business Rule: Cancel an invitation request.
   * Only allowed if the current state is strictly 'pending'.
   */
  public cancel(): void {
    if (this.status !== "pending") {
      throw new Error(
        `Cannot cancel an invitation that is currently '${this.status}'.`,
      );
    }
    this.status = "cancelled";
  }

  /**
   * Business Rule: Accept an invitation request.
   * Verifies executive credentials and checks lifecycle invariants.
   */
  public accept(executorUid: string): void {
    if (this.assistantId !== executorUid) {
      throw new Error(
        "Security Exception: Executive identity credential mismatch.",
      );
    }
    if (this.status !== "pending") {
      throw new Error(
        "Invalid State Transition: This invitation is no longer pending.",
      );
    }
    this.status = "accepted";
  }

  /**
   * Business Rule: Decline an invitation request.
   */
  public decline(executorUid: string): void {
    if (this.assistantId !== executorUid) {
      throw new Error(
        "Security Exception: Executive identity credential mismatch.",
      );
    }
    if (this.status !== "pending") {
      throw new Error(
        "Invalid State Transition: This invitation is no longer pending.",
      );
    }
    this.status = "declined";
  }

  /**
   * Maps internal data states back into a clean Firestore document payload structure.
   */
  public toFirestoreMap(): Record<string, any> {
    return {
      jobId: this.jobId,
      assistantId: this.assistantId,
      seekerId: this.seekerId,
      patientName: this.patientName,
      status: this.status,
      ...(this.reason && {reason: this.reason}),
    };
  }
}

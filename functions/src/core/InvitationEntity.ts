import {IInvitation} from "./Interfaces";

/**
 * DOMAIN ENTITY: INVITATION
 * (Information Expert Design Pattern)
 * Encapsulates state validation rules and life-cycle boundaries
 * for care booking invitations.
 */
export class InvitationEntity implements IInvitation {
  public readonly id: string;

  /**
   * Symmetrical constructor handling invitation state boundaries.
   * @param {string} jobId Unique identifier of the target job assignment.
   * @param {string} assistantId Targeted care assistant user profile token.
   * @param {string} seekerId Healthcare seeker user profile reference ID.
   * @param {string} patientName Name of the care patient receiver instance.
   * @param {string} status Lifecycle tracking status keyword.
   * @param {string} [reason] Optional rejection or cancellation note text.
   */
  constructor(
    public readonly jobId: string,
    public readonly assistantId: string,
    public readonly seekerId: string,
    public readonly patientName: string,
    public status: IInvitation["status"] = "pending",
    public reason?: string,
  ) {
    // Computes a unified composite document ID matching database structure
    this.id = `${this.jobId}_${this.assistantId}`;
  }

  /**
   * Converts Firestore document snapshot data maps into an Invitation entity.
   * @param {unknown} docData The raw document map data from Firestore.
   * @return {InvitationEntity} A newly instantiated invitation domain entity.
   */
  public static fromFirestore(docData: unknown): InvitationEntity {
    if (!docData) {
      throw new Error("Invitation record payload is empty.");
    }

    const d = docData as Record<string, unknown>;
    return new InvitationEntity(
      d.jobId as string,
      d.assistantId as string,
      d.seekerId as string,
      d.patientName as string,
      d.status as IInvitation["status"],
      d.reason as string | undefined,
    );
  }

  /**
   * Business Rule: Cancel an invitation request.
   * Only allowed if the current state is strictly 'pending'.
   * @return {void}
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
   * @param {string} executorUid The system user id executing this action.
   * @return {void}
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
   * @param {string} executorUid The system user id executing this action.
   * @return {void}
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
   * Maps data states back into a clean Firestore document payload structure.
   * @return {Record<string, unknown>} Serialized NoSQL document properties map.
   */
  public toFirestoreMap(): Record<string, unknown> {
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

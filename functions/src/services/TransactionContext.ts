import * as admin from "firebase-admin";
import {JobEntity} from "../core/JobEntity";
import {InvitationEntity} from "../core/InvitationEntity";
import {IJob, IInvitation} from "../core/Interfaces";

/**
 * Orchestrates atomic database transaction
 * states and handles data transformation.
 * @class TransactionContext
 * @description Acts as a Unit of Work repository
 * wrapper that takes raw NoSQL document snapshots
 * from Firestore and hydrates them into active,
 * state-protected domain entity instances.
 */
export class TransactionContext {
  /**
   * @param {admin.firestore.Transaction} tx - The active,
   *   isolated Firestore transaction context instance.
   * @param {admin.firestore.Firestore} db - The
   *   initialized global database engine handle.
   */
  constructor(
    private readonly tx: admin.firestore.Transaction,
    private readonly db: admin.firestore.Firestore,
  ) {}

  /**
   * Hydrates a fully functional JobEntity domain
   * object directly from database records.
   * @param {string} jobId - The distinct document
   *                           reference key of the target care case.
   * @return  {Promise<JobEntity>} A promise resolving
   *                               to the type-safe Job domain model instance.
   * @throws {Error} Throws an execution exception if
   *                 the target document profile is missing.
   */
  public async getJob(jobId: string): Promise<JobEntity> {
    const ref = this.db.collection("jobs").doc(jobId);
    const snap = await this.tx.get(ref);

    if (!snap.exists) {
      throw new Error(
        "Target care case context missing from database tier storage maps.",
      );
    }

    const d = snap.data() as IJob;
    return new JobEntity(
      snap.id,
      d.seekerId,
      d.patientName,
      d.startDate,
      d.endDate,
      d.maxDailyRate,
      d.workingTimes,
      d.requiredSkills || [],
      d.preferredGender || "unspecified",
      d.status,
      d.assignedAssistantId,
      d.topMatches,
    );
  }

  /**
   * Hydrates a fully functional InvitationEntity domain
   * model from its storage path, or returns null.
   * @param {string} jobId - The associated care case
   *                         reference key string token.
   * @param {string} assistantId - The user document
   *                               identifier of the assistant.
   * @return {Promise<InvitationEntity | null>}
   *    Resolves with the domain entity instance, or null if unallocated.
   */
  public async getInvitation(
    jobId: string,
    assistantId: string,
  ): Promise<InvitationEntity | null> {
    // Standardized composite key calculation pathway
    const id = `${jobId}_${assistantId}`;
    const ref = this.db.collection("invitations").doc(id);
    const snap = await this.tx.get(ref);

    if (!snap.exists) return null;

    const d = snap.data() as IInvitation;
    return new InvitationEntity(
      d.jobId,
      d.assistantId,
      d.seekerId,
      d.patientName,
      d.status,
      d.reason,
    );
  }

  /**
   * Maps an updated InvitationEntity instance back to its
   * document path in Firestore.
   * @param {InvitationEntity} invite - The state-modified
   *                                    domain model instance to serialize.
   * @return {void}
   */
  public saveInvitation(invite: InvitationEntity): void {
    const ref = this.db.collection("invitations").doc(invite.id);
    this.tx.set(
      ref,
      {
        ...invite.toFirestoreMap(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  }

  /**
   * Commits localized state modifications made to a JobEntity
   * instance back down to Firestore.
   * @param {JobEntity} job - The modified job assignment
   *                          entity instance to serialize.
   * @return {void}
   */
  public updateJob(job: JobEntity): void {
    const ref = this.db.collection("jobs").doc(job.id);
    this.tx.update(ref, {
      ...job.toFirestoreMap(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

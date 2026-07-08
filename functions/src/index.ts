import * as admin from "firebase-admin";

// Initialize once
admin.initializeApp();

// Export functions from handlers
export {matchJobToAssistants} from "./jobs/matchJobToAssistants";
export {getAssistantPublicProfile} from "./profiles/profiles";
export {getPublicAssistants} from "./profiles/getPublicAssistants";
export {getPublicAssistantProfile} from "./profiles/getAssistantSearch";
export {dailyJobLifecycleCron} from "./jobs/jobLifecycle";
export {cancelJobEarly} from "./billing/cancelJobEarly";
export {deleteJob} from "./jobs/deleteJob";
export {retryJob} from "./jobs/retryJob";

export {requestAssistantBooking} from "./invitations/invitation_lifecycle";
export {cancelAssistantBooking} from "./invitations/invitation_lifecycle";
export {acceptInvitation} from "./invitations/invitation_lifecycle";
export {declineInvitation} from "./invitations/invitation_lifecycle";

export {confirmEscrowPayment} from "./billing/confirm_payment";

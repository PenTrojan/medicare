import * as admin from "firebase-admin";

// Initialize once
admin.initializeApp();

// Export functions from handlers
export {matchJobToAssistants} from "./handlers/jobs";
export {getAssistantPublicProfile} from "./handlers/profiles";
export {getPublicAssistants} from "./handlers/getPublicAssistants";
export {getPublicAssistantProfile} from "./handlers/getAssistantSearch";
export {dailyJobLifecycleCron} from "./handlers/jobLifecycle";
export {cancelJobEarly} from "./billing/cancelJobEarly";

export {requestAssistantBooking} from "./handlers/invitation_lifecycle";
export {cancelAssistantBooking} from "./handlers/invitation_lifecycle";
export {acceptInvitation} from "./handlers/invitation_lifecycle";
export {declineInvitation} from "./handlers/invitation_lifecycle";

export {confirmEscrowPayment} from "./billing/confirm_payment";

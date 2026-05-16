import * as admin from "firebase-admin";

// Initialize once
admin.initializeApp();

// Export functions from handlers
export {matchJobToAssistants} from "./handlers/jobs";
export {getAssistantPublicProfile} from "./handlers/profiles";

export {requestAssistantBooking} from "./handlers/invitation_lifecycle";
export {cancelAssistantBooking} from "./handlers/invitation_lifecycle";
export {acceptInvitation} from "./handlers/invitation_lifecycle";
export {declineInvitation} from "./handlers/invitation_lifecycle";

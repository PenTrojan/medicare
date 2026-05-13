import * as admin from "firebase-admin";

// Initialize once
admin.initializeApp();

// Export functions from handlers
export {matchJobToAssistants} from "./handlers/jobs";
export {getAssistantPublicProfile} from "./handlers/profiles";

import * as admin from "firebase-admin";

// Initialize once
admin.initializeApp();

// Export function from handlers
export {matchJobToAssistants} from "./handlers/jobs";

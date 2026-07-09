import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Public profile data payload returned to unauthenticated clients.
 */
interface PublicAssistantProfile {
  assistantId: string;
  name: string;
  bio: string;
  profilePicUrl: string;
}

/**
 * Paginated API envelope response.
 */
interface AssistantsResponse {
  assistants: PublicAssistantProfile[];
  hasMore: boolean;
}

/**
 * HTTPS Cloud Function that retrieves public medical assistant profiles.
 * Bypasses Firestore client-side security rules by using the Admin SDK.
 * Supports basic filtering by name and offset-based array pagination.
 *
 * @param {import("firebase-functions/v2/https").HttpsRequest} req - The HTTP
 * request context containing query filters.
 * @param {import("firebase-functions/v2/https").Response} res - The HTTP
 * response wrapper channel.
 * @returns {Promise<void>} Resolves when request processing completes.
 */
export const getPublicAssistants = onRequest(
  {cors: true},
  async (req, res): Promise<void> => {
    try {
      if (req.method !== "GET" && req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      const limit = parseInt(req.query.limit as string, 10) || 20;
      const offset = parseInt(req.query.offset as string, 10) || 0;
      const search = (req.query.search as string || "").toLowerCase().trim();

      const query = admin
        .firestore()
        .collection("users")
        .where("role", "==", "assistant");

      const snapshot = await query.get();

      let assistants: PublicAssistantProfile[] = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          assistantId: doc.id,
          name: data.name || "No Name",
          bio: data.bio || "No bio",
          profilePicUrl: data.profilePicUrl || "",
        };
      });

      if (search.length > 0) {
        assistants = assistants.filter((assistant) =>
          assistant.name.toLowerCase().includes(search)
        );
      }

      const paginatedResults = assistants.slice(offset, offset + limit);
      const hasMore = offset + limit < assistants.length;

      const output: AssistantsResponse = {
        assistants: paginatedResults,
        hasMore,
      };

      res.status(200).json(output);
    } catch (error) {
      console.error("Error fetching public assistants:", error);
      res.status(500).send("Internal Server Error");
    }
  }
);

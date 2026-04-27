// Define interfaces for Type Safety
export interface AssistantMatch {
  assistantId: string;
  name: string;
  distance: number;
  matchScore: number;
  profilePic: string | null;
  dailyRate: number;
  experienceLevel: string;
}

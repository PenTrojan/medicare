import {GeoPoint, Timestamp} from "firebase-admin/firestore";

/**
 * 1. MATCH OUTPUT DATA PACKET (DTO)
 * Pure structured data layout for matching results sent to Flutter.
 */
export interface AssistantMatch {
  assistantId: string;
  name: string;
  distance: number;
  matchScore: number;
  profilePic: string | null;
  dailyRate: number;
  experienceLevel: string;
}

/**
 * 2. APP USER SCHEMA CONTRACT
 * Standardized contract mirroring your app's user profile attributes.
 */
export interface IAppUser {
  uid: string;
  name: string;
  role: "seeker" | "assistant";
  gender: "male" | "female" | "unspecified";
  isVerified: boolean;
  isBooked?: boolean;
  profilePicUrl?: string | null;
  age?: number | null;
  address?: string;
  dailyRate?: number;
  location?: GeoPoint;
  skills?: string[];
  workingTimes?: Record<string, string[]>;
  experienceLevel?: string;
  bio?: string;
  experienceDescription?: string;
}

/**
 * 3. INVITATION SCHEMA CONTRACT
 * Standardized contract mirroring your app's invitation states.
 */
export interface IInvitation {
  jobId: string;
  assistantId: string;
  seekerId: string;
  patientName: string;
  status:
    | "pending"
    | "accepted"
    | "declined"
    | "cancelled"
    | "cancelled_by_system";
  reason?: string;
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

/**
 * 4. JOB SCHEMA CONTRACT
 * Standardized contract mirroring your app's Job model properties.
 */
export interface IJob {
  id: string;
  seekerId: string;
  patientName: string;
  location?: GeoPoint;
  requiredSkills: string[];
  startDate: Timestamp;
  endDate: Timestamp;
  workingTimes: Record<string, string[]>;
  maxDailyRate: number;
  preferredGender: "male" | "female" | "unspecified";
  status: "pending" | "matching" | "no_matches" | "assigned" | "completed";
  assignedAssistantId?: string;
  topMatches: AssistantMatch[];
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

/**
 * 5. BILLING LEDGER CONTRACT
 * Standardized contract mirroring your app's internal invoice fields.
 */
export interface IBill {
  id: string;
  metadata: {
    jobId: string;
    seekerId: string;
    assistantId: string;
  };
  pricingStructure: {
    totalDays: number;
    dailyRate: number;
    grossContractValue: number;
  };
  financialBreakdown: {
    platformFeeRate: number;
    platformFeeAmount: number;
    netAssistantPayout: number;
    taxRate: number;
    taxAmount: number;
  };
  escrowSummary: {
    totalRequiredFromSeeker: number;
    currentEscrowBalance: number;
    financialStatus: "GENERATED" | "ESCROW_HELD" | "RELEASED" | "REFUNDED";
  };
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

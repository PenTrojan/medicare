export const BILLING_CONFIG = {
  /** The baseline number of active care hours that equal 1 daily rate unit */
  HOURS_PER_STANDARD_DAY: 8,

  /** Platform marketplace split commission fee (10%) */
  PLATFORM_FEE_RATE: 0.10,

  /** Regulatory platform infrastructure tax surcharge (2%) */
  TAX_RATE: 0.02,
} as const; // "as const" makes these values read-only at compile time

/**
 * Helper: Haversine Formula for Distance
 * @param {number} lat1 Latitude of point 1
 * @param {number} lon1 Longitude of point 1
 * @param {number} lat2 Latitude of point 2
 * @param {number} lon2 Longitude of point 2
 * @return {number} Distance in kilometers
 */
export function getDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371; // Radius of earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Checks if assistant availability fully covers job requirements.
 * Logic: Assistant must work all job days, and the job window must
 * fit entirely within the assistant's window.
 *
 * @param {any} jobTimes - Map of days to [start, end] times.
 * @param {any} assistantTimes - Map of days to [start, end] times.
 * @return {boolean} True if schedule is compatible.
 */
export function isTimeCompatible(
  jobTimes: Record<string, string[]>,
  assistantTimes: Record<string, string[]>,
): boolean {
  // Null checks
  if (!jobTimes || !assistantTimes) return false;

  // Loops through each day
  for (const day in jobTimes) {
    // This if statement satisfies the guard-for-in rule
    if (Object.prototype.hasOwnProperty.call(jobTimes, day)) {
      // If the assistant doesnt work on this day return false
      if (!assistantTimes[day]) return false;

      const [jStart, jEnd] = jobTimes[day];
      const [aStart, aEnd] = assistantTimes[day];

      // String comparison works because times are padded (e.g., "08:00")
      // If Job starts EARLIER than Assistant can start -> Incompatible
      // If Job ends LATER than Assistant can finish -> Incompatible
      if (jStart < aStart || jEnd > aEnd) return false;
    }
  }
  return true;
}

/**
 * Checks if two working time maps have any hour-level overlaps.
 * @param {Record<string, string[]>} jobTimes - Map of days to [start, end]
 * time strings for the new job.
 * @param {Record<string, string[]>} bookingTimes - Map of days to [start, end]
 * time strings for existing bookings.
 * @return {boolean} True if there is a conflict in hours, false otherwise.
 */
export function doHoursOverlap(
  jobTimes: Record<string, string[]>,
  bookingTimes: Record<string, string[]>,
): boolean {
  for (const day in jobTimes) {
    if (
      Object.prototype.hasOwnProperty.call(jobTimes, day) &&
      bookingTimes[day]
    ) {
      const [jobStart, jobEnd] = jobTimes[day];
      const [bookStart, bookEnd] = bookingTimes[day];

      // Convert to comparable numbers using double quotes for ESLint
      const jS = parseInt(jobStart.replace(":", ""), 10);
      const jE = parseInt(jobEnd.replace(":", ""), 10);
      const bS = parseInt(bookStart.replace(":", ""), 10);
      const bE = parseInt(bookEnd.replace(":", ""), 10);

      // Conflict logic: Job starts before booking ends
      // AND ends after booking starts
      if (jS < bE && jE > bS) {
        return true;
      }
    }
  }
  return false;
}

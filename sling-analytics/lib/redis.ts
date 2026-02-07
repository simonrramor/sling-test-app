import { Redis } from "@upstash/redis";

// Initialize Redis client
// Will use UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN from environment
export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

// Helper to get today's date key
export function getTodayKey(): string {
  return new Date().toISOString().split("T")[0];
}

// Helper to get date key for a specific date
export function getDateKey(date: Date): string {
  return date.toISOString().split("T")[0];
}

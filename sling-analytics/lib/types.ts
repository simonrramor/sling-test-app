// Analytics event types

export interface AnalyticsEvent {
  event: string;
  timestamp: string;
  session_id: string;
  properties?: Record<string, unknown>;
  device?: DeviceInfo;
}

export interface DeviceInfo {
  device_model: string;
  os_version: string;
  app_version: string;
  build_number: string;
  locale: string;
  timezone: string;
}

export interface EventBatch {
  events: AnalyticsEvent[];
  sent_at: string;
}

export interface DailyStats {
  date: string;
  total_events: number;
  unique_sessions: number;
  events_by_type: Record<string, number>;
  signup_steps: Record<string, number>;
  devices: Record<string, number>;
}

export interface DashboardData {
  total_events: number;
  events_today: number;
  active_sessions: number;
  recent_events: AnalyticsEvent[];
  events_by_type: Record<string, number>;
  events_by_hour: { hour: string; count: number }[];
  signup_funnel: { step: string; count: number }[];
  devices: { name: string; count: number }[];
  daily_stats: { date: string; events: number }[];
}

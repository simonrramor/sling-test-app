"use client";

import { useEffect, useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  FunnelChart,
  Funnel,
  LabelList,
} from "recharts";

interface DashboardData {
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

interface AnalyticsEvent {
  event: string;
  timestamp: string;
  session_id: string;
  properties?: Record<string, unknown>;
  device?: {
    device_model: string;
    os_version: string;
    app_version: string;
  };
}

const COLORS = [
  "#3b82f6",
  "#10b981",
  "#f59e0b",
  "#ef4444",
  "#8b5cf6",
  "#ec4899",
  "#06b6d4",
  "#84cc16",
];

function StatCard({
  title,
  value,
  subtitle,
}: {
  title: string;
  value: string | number;
  subtitle?: string;
}) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
      <h3 className="text-sm font-medium text-gray-500">{title}</h3>
      <p className="text-3xl font-bold text-gray-900 mt-2">{value}</p>
      {subtitle && <p className="text-sm text-gray-400 mt-1">{subtitle}</p>}
    </div>
  );
}

function EventRow({ event }: { event: AnalyticsEvent }) {
  const time = new Date(event.timestamp).toLocaleTimeString();
  const props = event.properties
    ? Object.entries(event.properties)
        .map(([k, v]) => `${k}=${v}`)
        .join(", ")
    : "";

  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
      <div className="flex items-center gap-3">
        <span className="inline-flex items-center justify-center w-2 h-2 rounded-full bg-green-500" />
        <div>
          <p className="font-medium text-gray-900">{event.event}</p>
          {props && <p className="text-sm text-gray-500">{props}</p>}
        </div>
      </div>
      <div className="text-right">
        <p className="text-sm text-gray-500">{time}</p>
        <p className="text-xs text-gray-400">
          {event.session_id?.slice(0, 8)}...
        </p>
      </div>
    </div>
  );
}

export default function Dashboard() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  const fetchData = async () => {
    try {
      const response = await fetch("/api/events");
      if (!response.ok) {
        throw new Error("Failed to fetch data");
      }
      const result = await response.json();
      setData(result);
      setLastRefresh(new Date());
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    // Refresh every 30 seconds
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto" />
          <p className="mt-4 text-gray-500">Loading analytics...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-5xl mb-4">⚠️</div>
          <h2 className="text-xl font-bold text-gray-900">Error loading data</h2>
          <p className="text-gray-500 mt-2">{error}</p>
          <p className="text-sm text-gray-400 mt-4">
            Make sure UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN are
            set
          </p>
          <button
            onClick={fetchData}
            className="mt-4 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!data) return null;

  // Prepare event types for bar chart
  const eventTypesData = Object.entries(data.events_by_type)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  return (
    <div className="min-h-screen p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              Sling Analytics
            </h1>
            <p className="text-gray-500 mt-1">TestFlight Build Dashboard</p>
          </div>
          <div className="text-right">
            <p className="text-sm text-gray-400">
              Last updated: {lastRefresh.toLocaleTimeString()}
            </p>
            <button
              onClick={fetchData}
              className="mt-2 text-sm text-blue-500 hover:text-blue-600"
            >
              Refresh now
            </button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Total Events"
            value={data.total_events.toLocaleString()}
            subtitle="All time"
          />
          <StatCard
            title="Events Today"
            value={data.events_today.toLocaleString()}
            subtitle={new Date().toLocaleDateString()}
          />
          <StatCard
            title="Sessions Today"
            value={data.active_sessions}
            subtitle="Unique sessions"
          />
          <StatCard
            title="Event Types"
            value={Object.keys(data.events_by_type).length}
            subtitle="Distinct events"
          />
        </div>

        {/* Charts Row 1 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* Events by Hour */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Events by Hour (Today)
            </h3>
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={data.events_by_hour}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis
                  dataKey="hour"
                  tick={{ fontSize: 12 }}
                  interval={3}
                  stroke="#9ca3af"
                />
                <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
                <Tooltip />
                <Line
                  type="monotone"
                  dataKey="count"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Event Types */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Event Types (Today)
            </h3>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={eventTypesData} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 12 }} stroke="#9ca3af" />
                <YAxis
                  type="category"
                  dataKey="name"
                  tick={{ fontSize: 12 }}
                  width={120}
                  stroke="#9ca3af"
                />
                <Tooltip />
                <Bar dataKey="count" fill="#3b82f6" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Charts Row 2 */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Sign-up Funnel */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Sign-up Funnel
            </h3>
            <div className="space-y-3">
              {data.signup_funnel.map((step, index) => {
                const maxCount = Math.max(
                  ...data.signup_funnel.map((s) => s.count),
                  1
                );
                const width = (step.count / maxCount) * 100;
                return (
                  <div key={step.step}>
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-gray-600 capitalize">
                        {step.step}
                      </span>
                      <span className="font-medium">{step.count}</span>
                    </div>
                    <div className="h-4 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{
                          width: `${width}%`,
                          backgroundColor: COLORS[index % COLORS.length],
                        }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Devices */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Device Types
            </h3>
            {data.devices.length > 0 ? (
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie
                    data={data.devices}
                    dataKey="count"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    outerRadius={80}
                    label={({ name, percent }) =>
                      `${name.slice(0, 10)} ${(percent * 100).toFixed(0)}%`
                    }
                    labelLine={false}
                  >
                    {data.devices.map((_, index) => (
                      <Cell
                        key={`cell-${index}`}
                        fill={COLORS[index % COLORS.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-[200px] flex items-center justify-center text-gray-400">
                No device data yet
              </div>
            )}
          </div>

          {/* Daily Trend */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Daily Events (7 days)
            </h3>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={data.daily_stats}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 10 }}
                  stroke="#9ca3af"
                  tickFormatter={(val) => val.slice(5)} // Show MM-DD
                />
                <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
                <Tooltip />
                <Bar dataKey="events" fill="#10b981" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Recent Events */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Recent Events
          </h3>
          <div className="max-h-[400px] overflow-y-auto">
            {data.recent_events.length > 0 ? (
              data.recent_events.map((event, index) => (
                <EventRow key={`${event.timestamp}-${index}`} event={event} />
              ))
            ) : (
              <div className="text-center py-8 text-gray-400">
                No events yet. Events will appear here when your app starts
                sending data.
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="mt-8 text-center text-sm text-gray-400">
          <p>
            Endpoint:{" "}
            <code className="bg-gray-100 px-2 py-1 rounded">
              POST /api/events
            </code>
          </p>
        </div>
      </div>
    </div>
  );
}

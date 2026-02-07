import { NextRequest, NextResponse } from "next/server";
import { redis, getTodayKey, getDateKey } from "@/lib/redis";
import { AnalyticsEvent, EventBatch, DashboardData } from "@/lib/types";

// POST - Receive events from iOS app
export async function POST(request: NextRequest) {
  try {
    const body: EventBatch = await request.json();
    const { events, sent_at } = body;

    if (!events || !Array.isArray(events) || events.length === 0) {
      return NextResponse.json(
        { error: "No events provided" },
        { status: 400 }
      );
    }

    const today = getTodayKey();
    const pipeline = redis.pipeline();

    // Process each event
    for (const event of events) {
      // Store event in daily list
      pipeline.lpush(`events:${today}`, JSON.stringify(event));

      // Update event type counter
      pipeline.hincrby(`stats:${today}:types`, event.event, 1);

      // Track session
      if (event.session_id) {
        pipeline.sadd(`sessions:${today}`, event.session_id);
        pipeline.set(`session:${event.session_id}:last_seen`, Date.now(), {
          ex: 3600, // 1 hour TTL
        });
      }

      // Track signup steps
      if (event.event === "signup_step" && event.properties?.step) {
        const step = String(event.properties.step);
        pipeline.hincrby(`stats:${today}:signup`, step, 1);
      }

      // Track devices
      if (event.device?.device_model) {
        pipeline.hincrby(`stats:${today}:devices`, event.device.device_model, 1);
      }

      // Track hourly counts
      const hour = new Date(event.timestamp).getHours();
      pipeline.hincrby(`stats:${today}:hourly`, String(hour), 1);
    }

    // Increment total events counter
    pipeline.incrby(`stats:${today}:total`, events.length);
    pipeline.incrby("stats:total", events.length);

    // Set TTL on daily keys (7 days)
    pipeline.expire(`events:${today}`, 604800);
    pipeline.expire(`stats:${today}:types`, 604800);
    pipeline.expire(`stats:${today}:signup`, 604800);
    pipeline.expire(`stats:${today}:devices`, 604800);
    pipeline.expire(`stats:${today}:hourly`, 604800);
    pipeline.expire(`sessions:${today}`, 604800);

    await pipeline.exec();

    return NextResponse.json({
      success: true,
      received: events.length,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("Error processing events:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

// GET - Retrieve dashboard data
export async function GET(request: NextRequest) {
  try {
    const today = getTodayKey();

    // Get data in parallel
    const [
      totalEvents,
      todayEvents,
      recentEventsRaw,
      eventTypes,
      signupSteps,
      devices,
      hourlyStats,
      todaySessions,
    ] = await Promise.all([
      redis.get<number>("stats:total") || 0,
      redis.get<number>(`stats:${today}:total`) || 0,
      redis.lrange(`events:${today}`, 0, 49), // Last 50 events
      redis.hgetall<Record<string, number>>(`stats:${today}:types`) || {},
      redis.hgetall<Record<string, number>>(`stats:${today}:signup`) || {},
      redis.hgetall<Record<string, number>>(`stats:${today}:devices`) || {},
      redis.hgetall<Record<string, number>>(`stats:${today}:hourly`) || {},
      redis.scard(`sessions:${today}`) || 0,
    ]);

    // Parse recent events
    const recentEvents: AnalyticsEvent[] = (recentEventsRaw || []).map(
      (e: string | AnalyticsEvent) => (typeof e === "string" ? JSON.parse(e) : e)
    );

    // Format hourly data for chart
    const eventsForHour: { hour: string; count: number }[] = [];
    for (let i = 0; i < 24; i++) {
      eventsForHour.push({
        hour: `${i.toString().padStart(2, "0")}:00`,
        count: Number((hourlyStats || {})[String(i)] || 0),
      });
    }

    // Format signup funnel
    const signupOrder = [
      "phone",
      "verification",
      "name",
      "birthday",
      "reviewTerms",
    ];
    const signupFunnel = signupOrder.map((step) => ({
      step,
      count: Number((signupSteps || {})[step] || 0),
    }));

    // Format devices for chart
    const deviceList = Object.entries(devices || {}).map(([name, count]) => ({
      name,
      count: Number(count),
    }));

    // Get daily stats for last 7 days
    const dailyStats: { date: string; events: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateKey = getDateKey(date);
      const dayTotal = await redis.get<number>(`stats:${dateKey}:total`);
      dailyStats.push({
        date: dateKey,
        events: Number(dayTotal || 0),
      });
    }

    // Count active sessions (seen in last 5 minutes)
    const activeSessions = todaySessions;

    const dashboardData: DashboardData = {
      total_events: Number(totalEvents || 0),
      events_today: Number(todayEvents || 0),
      active_sessions: activeSessions,
      recent_events: recentEvents,
      events_by_type: eventTypes || {},
      events_by_hour: eventsForHour,
      signup_funnel: signupFunnel,
      devices: deviceList,
      daily_stats: dailyStats,
    };

    return NextResponse.json(dashboardData);
  } catch (error) {
    console.error("Error fetching dashboard data:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

# Sling Analytics Dashboard

A lightweight analytics backend and dashboard for Sling TestFlight builds.

## Quick Start

### 1. Set up Upstash Redis (Free)

1. Go to [console.upstash.com](https://console.upstash.com)
2. Create a free account (no credit card required)
3. Click "Create Database"
4. Choose a name (e.g., "sling-analytics") and region
5. Copy the `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`

### 2. Local Development

```bash
# Install dependencies
npm install

# Create .env.local with your Upstash credentials
cp .env.example .env.local
# Edit .env.local and add your credentials

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the dashboard.

### 3. Deploy to Vercel

The easiest way to deploy:

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy (follow prompts)
vercel

# Add environment variables in Vercel dashboard:
# - UPSTASH_REDIS_REST_URL
# - UPSTASH_REDIS_REST_TOKEN

# Deploy to production
vercel --prod
```

Or connect your GitHub repo to Vercel for automatic deployments.

### 4. Configure iOS App

In your iOS app's `AppDelegate`, set the endpoint URL:

```swift
AnalyticsService.shared.endpointURL = URL(string: "https://your-app.vercel.app/api/events")
```

## API

### POST /api/events

Receive events from the iOS app.

**Request:**
```json
{
  "events": [
    {
      "event": "screen_view",
      "timestamp": "2024-01-15T10:30:00Z",
      "session_id": "abc-123",
      "properties": {
        "screen_name": "HomeView"
      },
      "device": {
        "device_model": "iPhone15,2",
        "os_version": "17.2",
        "app_version": "1.0.0"
      }
    }
  ],
  "sent_at": "2024-01-15T10:30:05Z"
}
```

**Response:**
```json
{
  "success": true,
  "received": 1,
  "timestamp": "2024-01-15T10:30:05Z"
}
```

### GET /api/events

Get dashboard data.

## Dashboard Features

- **Total Events** - All-time event count
- **Events Today** - Today's event count
- **Sessions** - Unique sessions today
- **Events by Hour** - Line chart of hourly activity
- **Event Types** - Bar chart of event breakdown
- **Sign-up Funnel** - Conversion through sign-up steps
- **Device Types** - Pie chart of device models
- **Daily Trend** - 7-day event history
- **Recent Events** - Live feed of last 50 events

## Data Retention

Events are stored for 7 days by default (configurable in the API route).

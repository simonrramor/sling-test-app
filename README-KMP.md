# Sling - Kotlin Multiplatform Setup

This project uses Kotlin Multiplatform (KMP) to share business logic between iOS and Android while maintaining native UI on each platform.

## Project Structure

```
sling-test-app-2/
├── shared/                          # KMP shared module
│   ├── src/
│   │   ├── commonMain/kotlin/       # Shared code (models, services)
│   │   ├── androidMain/kotlin/      # Android-specific implementations
│   │   └── iosMain/kotlin/          # iOS-specific implementations
│   └── build.gradle.kts
├── androidApp/                      # Android application (Jetpack Compose)
│   ├── src/main/kotlin/
│   └── build.gradle.kts
├── Sling/                           # iOS application (SwiftUI)
│   └── Services/
│       ├── SharedActivityService.swift    # KMP wrapper
│       └── SharedPortfolioService.swift   # KMP wrapper
├── settings.gradle.kts
├── build.gradle.kts
└── Podfile                          # CocoaPods for iOS KMP integration
```

## Prerequisites

- **JDK 17** or later
- **Android Studio** Hedgehog (2023.1.1) or later
- **Xcode 15** or later
- **CocoaPods** (`gem install cocoapods`)

## Build Commands

### Build Shared Module

```bash
# Build for all platforms
./gradlew :shared:build

# Build only Android
./gradlew :shared:assembleDebug
```

### Build iOS Framework

```bash
# For iOS Simulator (arm64 - Apple Silicon)
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64

# For iOS Simulator (x64 - Intel)
./gradlew :shared:linkDebugFrameworkIosX64

# For iOS Device
./gradlew :shared:linkDebugFrameworkIosArm64
```

### Build Android App

```bash
# Debug build
./gradlew :androidApp:assembleDebug

# Install on connected device
./gradlew :androidApp:installDebug
```

## iOS Integration

1. Build the shared framework:
   ```bash
   ./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
   ```

2. Install CocoaPods dependencies:
   ```bash
   cd /path/to/sling-test-app-2
   pod install
   ```

3. Open the `.xcworkspace` file in Xcode (not `.xcodeproj`):
   ```bash
   open sling-test-app-2.xcworkspace
   ```

4. Build and run in Xcode

## Migration Guide

### For iOS (SwiftUI)

The existing Swift services are being migrated to use the shared KMP logic:

1. **SharedActivityService.swift** - Wrapper for KMP ActivityService
2. **SharedPortfolioService.swift** - Wrapper for KMP PortfolioService

To migrate your views:

```swift
// Before (using Swift-only service)
@ObservedObject private var activityService = ActivityService.shared

// After (using KMP-backed service)
@ObservedObject private var activityService = SharedActivityService.shared
```

The wrappers provide the same API, so minimal code changes are needed.

### For Android (Jetpack Compose)

The Android app uses the shared services directly:

```kotlin
// Initialize in Application.onCreate()
val persistenceDriver = PersistenceDriver(context)
ServiceLocator.initialize(persistenceDriver)

// Use in Composables
val activityService = remember { ServiceLocator.activityService }
val activities by activityService.activities.collectAsState()
```

## Shared Code

### Data Models

- `ActivityItem` - Transaction/activity item
- `Holding` - Stock holding
- `PortfolioEvent` - Buy/sell events
- `SignUpData` - User registration data
- `Country` - Country selection data

### Services

- `ActivityService` - Manages transaction history
- `PortfolioService` - Manages portfolio and cash balance

### Platform Abstractions

- `PersistenceDriver` - Cross-platform persistence
  - Android: SharedPreferences
  - iOS: NSUserDefaults

## Troubleshooting

### Gradle sync fails

Make sure you have JDK 17 configured:
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

### iOS framework not found

Rebuild the framework and reinstall pods:
```bash
./gradlew clean
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
pod install --repo-update
```

### Android build fails

Sync Gradle files in Android Studio:
- File > Sync Project with Gradle Files

## Development Workflow

1. **Modify shared code** in `shared/src/commonMain/`
2. **Rebuild framework** for iOS: `./gradlew :shared:linkDebugFrameworkIosSimulatorArm64`
3. **Rebuild Android**: Automatic in Android Studio
4. **Test on both platforms** before committing

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Platform Layer                          │
├─────────────────────────────┬───────────────────────────────┤
│   iOS (SwiftUI)             │   Android (Jetpack Compose)   │
│   - Native UI               │   - Native UI                 │
│   - Swift wrappers          │   - Direct service access     │
├─────────────────────────────┴───────────────────────────────┤
│                   Shared KMP Module                         │
│   - Data Models (ActivityItem, Holding, etc.)               │
│   - Business Logic (ActivityService, PortfolioService)      │
│   - Platform Abstractions (PersistenceDriver)               │
└─────────────────────────────────────────────────────────────┘
```

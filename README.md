# Motion

A Strava-style fitness tracking app for iOS, built with **SwiftUI**, **SwiftData**, **MapKit** and **CoreLocation**.

**Developed by Kas-Kazini Inc.** · Bundle ID: `com.kaskazini.motion`

## Requirements
- macOS 13.5 (Ventura) or later
- **Xcode 15.2**, Swift 5.9
- iOS 17.0+ deployment target (iPhone)

## Run it
1. Unzip and open `Motion.xcodeproj` in Xcode 15.2 (or drag the folder onto Xcode).
2. Select the **Motion** target → *Signing & Capabilities* → choose your **Team** (needed for a real device; the simulator works without one). Change the bundle identifier if it clashes with an existing one.
3. Pick an iPhone simulator or device and press **Run** (⌘R).
4. In the simulator, simulate movement with *Features ▸ Location ▸ City Run / Freeway Drive* (or *Debug ▸ Simulate Location* in Xcode).
5. Sign up with any email and a 6+ character password, or tap **Continue as demo user**.

## Features
- Mock email/password sign-up and login (stored locally, salted SHA-256 — replace with a real backend + Keychain for production)
- Record **Running, Cycling, Walking, Hiking, Driving, Swimming, Gym Workout** with Start / Pause / Resume / Finish
- Live duration, distance, pace or speed, elevation gain and a real-time route polyline on a MapKit map
- Swimming: tap to count 25 m pool lengths. Gym: timer and calorie estimate (indoor, no GPS)
- Feed of past activities (newest first) with type filters and route thumbnails (long-press a card to delete)
- Detail screen: route map with start/finish, key stats, interactive elevation / speed charts (Swift Charts), per-km/mi splits, share
- Profile: user info, weekly goal ring, weekly/all-time stats, last-7-days chart, metric/imperial toggle
- Dark, orange-accented athletic design; SF Symbols throughout

## Architecture (MVVM)
```
Motion/
├── MotionApp.swift          App entry + SwiftData container
├── Models/                  ActivityType, ActivityRecord (@Model), TrackPoint
├── ViewModels/              Auth, Feed, Profile, Recording
├── Views/                   Root, Auth, Feed, Detail, Record, Save sheet, Profile
│   └── Components/          Buttons, stat tiles, route thumbnail, progress ring
├── Services/                LocationService (CoreLocation), AuthService (mock)
├── Extensions/              Theme, Formatting (units), Coordinates
└── Assets.xcassets          App icon, accent color
```

## Location notes
- Requests **While Using the App** authorization.
- Standard location updates with `kCLLocationAccuracyBest` (navigation accuracy for driving), a 5 m distance filter, and filtering of inaccurate / stale / jumpy fixes.
- Background location mode is enabled so recording continues with the screen locked.
- Distance totals on the profile exclude driving.

© 2026 Kas-Kazini Inc.

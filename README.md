# Tikkuu Focus

A unique iOS focus timer app that gamifies productivity by turning focus sessions into virtual journeys.

## Concept

**"Focus as a Journey"** - Instead of watching a boring countdown timer, users embark on a virtual journey to a random destination based on their focus duration and chosen mode of transport. As time passes, a virtual avatar travels along real routes, discovering landmarks and points of interest along the way.

## Features

### 🚶 Multiple Transport Modes
- **Walking** (~5 km/h) - Perfect for short focus sessions (15-30 min)
- **Cycling** (~20 km/h) - Ideal for medium sessions (30-60 min)
- **Driving** (~60 km/h) - Best for deep work (60-120 min)

### 🗺️ Real-World Integration
- Uses your actual GPS location as the starting point
- Generates random destinations based on distance calculations
- Calculates real navigation routes using Apple MapKit
- Virtual avatar moves along actual roads and paths

### 🏛️ POI Discovery
- Automatically detects nearby landmarks during the journey
- Discovers popular brands (McDonald's, KFC, Starbucks)
- Finds parks, museums, temples, and tourist attractions
- Shows notifications when passing interesting places

### 🎨 Liquid Glass Design
- Beautiful, modern UI with liquid glass aesthetic
- Smooth animations and transitions
- Floating elements and gradient backgrounds
- Clean, minimalist interface

### 🌍 Internationalization
- Full support for English and Chinese (Simplified)
- Localized UI strings and messages
- Easy to add more languages

## Tech Stack

- **Language:** Swift 6
- **UI Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
- **Map Framework:** MapKit (Native Apple Maps)
- **Location Services:** CoreLocation
- **Minimum iOS Version:** iOS 17.0+

## Project Structure

```
Tikkuu Focus/
├── Models/
│   ├── TransportMode.swift      # Transport mode definitions
│   └── JourneyState.swift        # Journey state and session models
├── Managers/
│   ├── LocationManager.swift    # GPS and location permissions
│   └── JourneyManager.swift     # Journey logic and routing
├── Views/
│   ├── SetupView.swift          # Initial setup screen
│   └── ActiveJourneyView.swift  # Active journey map view
├── Utilities/
│   ├── FormatUtilities.swift    # Formatting helpers
│   └── LiquidGlassStyle.swift   # UI styling components
└── Resources/
    ├── en.lproj/
    │   └── Localizable.strings  # English translations
    └── zh-Hans.lproj/
        └── Localizable.strings  # Chinese translations
```

## How It Works

1. **Setup Phase:**
   - User selects a transport mode (Walking/Cycling/Driving)
   - User chooses focus duration (or uses suggested durations)
   - App requests location permission if needed

2. **Journey Generation:**
   - Calculate distance: `Distance = Speed × Duration`
   - Generate random destination at calculated distance
   - Calculate real navigation route using MapKit
   - Extract route coordinates for smooth animation

3. **Active Journey:**
   - Timer counts down from selected duration
   - Virtual avatar moves along the route based on elapsed time
   - Map camera follows the avatar's position
   - POI scanner checks for nearby landmarks every minute
   - Notifications appear when discovering interesting places

4. **Completion:**
   - Journey completes when timer reaches zero
   - Shows completion screen with journey statistics
   - User can start a new journey

## Key Components

### LocationManager
Handles all location-related functionality:
- Permission requests and status monitoring
- Continuous location updates
- Error handling for location services

### JourneyManager
Core journey logic:
- Random destination generation using bearing calculations
- Route calculation with MapKit Directions
- Position interpolation along the route
- POI discovery using MKLocalSearch
- Journey state management (idle/active/paused/completed)

### Liquid Glass UI
Custom SwiftUI components:
- Glass card backgrounds with blur effects
- Animated gradient backgrounds
- Floating animations
- Progress bars and badges
- Toast notifications

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 6.0
- Location Services enabled
- Internet connection (for map data)

## Privacy

The app requires location access to:
- Get your starting position for journey generation
- Calculate realistic routes and destinations
- Discover nearby points of interest

Location data is only used during active sessions and is not stored or transmitted.

## Future Enhancements

- [ ] Journey history and statistics
- [ ] Achievement system
- [ ] Custom destination selection
- [ ] Social features (share journeys)
- [ ] Offline map support
- [ ] Apple Watch companion app
- [ ] Focus session analytics

## License

Copyright © 2026 Tikkuu. All rights reserved.

---

Built with ❤️ using SwiftUI and MapKit

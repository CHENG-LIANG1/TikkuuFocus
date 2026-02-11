# Setup Instructions for Tikkuu Focus

## Step 1: Add Files to Xcode Project

Since we created files outside of Xcode, you need to add them to your project:

### Method 1: Using Xcode (Recommended)

1. **Open Xcode Project:**
   - Open `Tikkuu Focus.xcodeproj` in Xcode

2. **Add Model Files:**
   - Right-click on "Tikkuu Focus" folder in Project Navigator
   - Select "Add Files to 'Tikkuu Focus'..."
   - Navigate to `Tikkuu Focus/Models/`
   - Select both files:
     - `TransportMode.swift`
     - `JourneyState.swift`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Tikkuu Focus" target
   - Click "Add"

3. **Add Manager Files:**
   - Repeat the process for `Tikkuu Focus/Managers/`:
     - `LocationManager.swift`
     - `JourneyManager.swift`

4. **Add View Files:**
   - Repeat for `Tikkuu Focus/Views/`:
     - `SetupView.swift`
     - `ActiveJourneyView.swift`

5. **Add Utility Files:**
   - Repeat for `Tikkuu Focus/Utilities/`:
     - `FormatUtilities.swift`
     - `LiquidGlassStyle.swift`

6. **Add Localization Files:**
   - Right-click on "Tikkuu Focus" folder
   - Select "Add Files to 'Tikkuu Focus'..."
   - Navigate to `Tikkuu Focus/Resources/`
   - Select both folders:
     - `en.lproj`
     - `zh-Hans.lproj`
   - ✅ Check "Create folder references" (not groups)
   - ✅ Check "Tikkuu Focus" target
   - Click "Add"

7. **Add Info.plist:**
   - If `Info.plist` doesn't exist in your project:
     - Right-click on "Tikkuu Focus" folder
     - Select "Add Files to 'Tikkuu Focus'..."
     - Select `Info.plist`
     - Click "Add"

8. **Delete Old Files (Optional):**
   - Right-click on `ContentView.swift` → Delete → Move to Trash
   - Right-click on `Item.swift` → Delete → Move to Trash

### Method 2: Using Terminal (Alternative)

If you prefer command line, the files are already in the correct locations. Just open Xcode and use "Add Files" as described above.

## Step 2: Configure Project Settings

1. **Set Deployment Target:**
   - Select project in Navigator
   - Select "Tikkuu Focus" target
   - General tab → Deployment Info
   - Set "Minimum Deployments" to **iOS 17.0**

2. **Configure Info.plist:**
   - Select "Tikkuu Focus" target
   - Info tab
   - Verify these keys exist (or add them):
     - `NSLocationWhenInUseUsageDescription`
     - `NSLocationAlwaysAndWhenInUseUsageDescription`

3. **Add Localization:**
   - Select project in Navigator
   - Info tab → Localizations
   - Click "+" to add languages:
     - English (already there)
     - Chinese (Simplified)

4. **Enable Location Capability:**
   - Select "Tikkuu Focus" target
   - Signing & Capabilities tab
   - Click "+ Capability"
   - Add "Location" (if not already present)

## Step 3: Build and Run

### On Simulator (Limited Testing):

```bash
# Build the project
xcodebuild -scheme "Tikkuu Focus" -sdk iphonesimulator -configuration Debug

# Or just press Cmd+R in Xcode
```

**Note:** Simulator has limited GPS simulation. You can:
- Debug → Location → Custom Location
- Enter coordinates manually
- Use "Freeway Drive" or "City Run" for testing

### On Real Device (Recommended):

1. **Connect iPhone via USB**
2. **Select your device** in Xcode toolbar
3. **Trust developer certificate** if prompted
4. **Press Cmd+R** to build and run

## Step 4: Test the App

### Test Checklist:

#### ✅ Location Permissions
1. Launch app
2. Verify permission alert appears
3. Tap "Allow While Using App"
4. Check that location icon appears in status bar

#### ✅ Setup Screen
1. Verify liquid glass UI renders correctly
2. Test transport mode selection (Walking/Cycling/Driving)
3. Test duration selection (preset buttons + slider)
4. Verify suggested durations change with transport mode

#### ✅ Start Journey
1. Select "Cycling" and "25 min"
2. Tap "Start Journey"
3. Wait for route calculation (should take 2-5 seconds)
4. Verify map appears with route drawn

#### ✅ Active Journey
1. Check that avatar appears on map
2. Verify avatar moves along route
3. Check timer counts down
4. Verify progress bar updates
5. Check distance traveled increases

#### ✅ POI Discovery
1. Wait 60 seconds during journey
2. Check if POI toast appears at bottom
3. Verify POI markers appear on map
4. Check that POI names are readable

#### ✅ Journey Controls
1. Tap pause button → verify timer stops
2. Tap resume button → verify timer continues
3. Tap cancel button → verify returns to setup

#### ✅ Journey Completion
1. Let timer run to 0:00
2. Verify completion screen appears
3. Check "Journey Complete!" message
4. Tap "New Journey" → verify returns to setup

#### ✅ Localization
1. Go to Settings → General → Language & Region
2. Change to "Chinese (Simplified)"
3. Relaunch app
4. Verify all text is in Chinese
5. Change back to English

## Step 5: Troubleshooting

### Issue: "No such module 'MapKit'"
**Solution:** MapKit is built-in, but ensure deployment target is iOS 17.0+

### Issue: Location permission not working
**Solution:** 
- Check Info.plist has location usage descriptions
- Reset simulator: Device → Erase All Content and Settings
- On real device: Settings → Privacy → Location Services → Tikkuu Focus → Reset

### Issue: Map not showing route
**Solution:**
- Ensure internet connection is active
- Check that destination is valid (not in ocean)
- Try different transport mode or duration

### Issue: Build errors about missing files
**Solution:**
- Verify all files are added to target (check File Inspector)
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Restart Xcode

### Issue: POIs not appearing
**Solution:**
- POI check runs every 60 seconds (be patient)
- Some areas have fewer POIs (try urban locations)
- Check console for search errors

### Issue: Avatar not moving smoothly
**Solution:**
- This is normal on simulator (limited performance)
- Test on real device for smooth animation
- Reduce map region if needed

## Step 6: Customize (Optional)

### Change Colors:
Edit `LiquidGlassStyle.swift`:
```swift
static let primaryGradient = LinearGradient(
    colors: [
        Color(red: 0.4, green: 0.7, blue: 0.9),  // Change these
        Color(red: 0.3, green: 0.5, blue: 0.8)   // Change these
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Change Speeds:
Edit `TransportMode.swift`:
```swift
var speedKmh: Double {
    switch self {
    case .walking: return 5.0   // Change this
    case .cycling: return 20.0  // Change this
    case .driving: return 60.0  // Change this
    }
}
```

### Change POI Check Interval:
Edit `JourneyManager.swift`:
```swift
private let poiCheckInterval: TimeInterval = 60  // Change to 30 for more frequent checks
```

### Add More POI Categories:
Edit `JourneyManager.checkForPOIs()`:
```swift
let queries = [
    "McDonald's",
    "KFC",
    "Starbucks",
    "restaurant",
    "park",
    "landmark",
    "museum",
    "temple",
    "coffee shop",    // Add your own
    "bookstore",      // Add your own
    "gym"             // Add your own
]
```

## Step 7: Debug Tips

### Enable Verbose Logging:
Add print statements in key locations:

```swift
// In JourneyManager.startJourney()
print("🚀 Starting journey from \(location)")
print("📍 Destination: \(destination)")
print("🛣️ Route distance: \(route.distance)m")

// In JourneyManager.updateJourney()
print("⏱️ Time remaining: \(position.remainingTime)s")
print("📏 Distance traveled: \(position.distanceTraveled)m")

// In JourneyManager.checkForPOIs()
print("🔍 Checking for POIs at \(coordinate)")
print("⭐ Found POI: \(poi.name)")
```

### Use Xcode Debugger:
- Set breakpoints in `startJourney()`, `updateJourney()`, `checkForPOIs()`
- Inspect variables: `po journeyManager.state`
- Check location: `po locationManager.currentLocation`

### Monitor Performance:
- Open Instruments (Cmd+I)
- Select "Time Profiler"
- Look for slow methods
- Optimize if needed

## Step 8: Prepare for App Store (Future)

1. **Add App Icon:**
   - Create 1024x1024 icon
   - Add to Assets.xcassets/AppIcon.appiconset

2. **Add Launch Screen:**
   - Create LaunchScreen.storyboard
   - Or use SwiftUI launch screen

3. **Update Bundle Identifier:**
   - Change from default to your own
   - Format: com.yourcompany.tikkuufocus

4. **Add Privacy Policy:**
   - Required for location usage
   - Host on website or in-app

5. **Test on Multiple Devices:**
   - iPhone SE (small screen)
   - iPhone 15 Pro (standard)
   - iPhone 15 Pro Max (large)

6. **Submit for Review:**
   - Follow Apple's guidelines
   - Explain location usage clearly
   - Provide demo video

---

## Quick Start Commands

```bash
# Navigate to project
cd "/Users/louis/Desktop/Tikkuu Focus"

# Open in Xcode
open "Tikkuu Focus.xcodeproj"

# Build from command line
xcodebuild -scheme "Tikkuu Focus" -sdk iphonesimulator

# Run tests (when added)
xcodebuild test -scheme "Tikkuu Focus" -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

**You're all set!** 🎉 Open Xcode, add the files, and start testing your unique focus timer app!

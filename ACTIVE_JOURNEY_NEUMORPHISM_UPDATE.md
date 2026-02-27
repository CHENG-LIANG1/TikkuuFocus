# Active Journey View - Neumorphism Update

## Summary

Updated the Active Journey view to properly support Neumorphism theme for distance and speed stat cards, and moved the "Warming up" text to the start button.

## Changes

### 1. CompactStatCard Neumorphism Support

Modified `CompactStatCard` to support both Liquid Glass and Neumorphism themes:

- **Neumorphism Theme**: Uses `NeumorphSurface` with `.raised` depth for soft 3D card effect
- **Liquid Glass Theme**: Uses `.thinMaterial` with shadow and stroke (existing behavior)
- **Adaptive Colors**: 
  - Icon color adjusts for light/dark neumorphism themes
  - Label and value colors use dark gray for light neumorphism (better readability)

### 2. Removed "Warming Up" from Stats Panel

Removed the "Warming up..." status message from the stats panel in ActiveJourneyView:

```swift
// Removed this block from statsPanel:
// Transport status message (warming up for walking/cycling)
if let session = journeyManager.state.session,
   session.transportMode == .walking || session.transportMode == .cycling {
    HStack(spacing: 6) {
        Image(systemName: session.transportMode.iconName)
        Text(L("transport.status.warmingUp"))
    }
    ...
}
```

### 3. Button Shows "Warming Up" During Preparing

Updated SetupView start button to show "Warming up" / "正在热身" during the preparing state:

```swift
// Before:
Text(L("label.preparing"))  // "Preparing..." / "准备中..."

// After:
Text(L("transport.status.warmingUp"))  // "Warming up" / "正在热身"
```

## UI Changes

### Before
- Stats cards always used Liquid Glass style
- "Warming up..." appeared as a capsule badge above the stat cards
- Button showed "Preparing..." during start

### After
- Stats cards adapt to current theme (Neumorphism or Liquid Glass)
- "Warming up..." removed from stats panel
- Button shows "Warming up" / "正在热身" during start

## Localization

Uses existing localization keys:
- `transport.status.warmingUp` = "Warming up" / "正在热身"
- `label.distanceTraveled` = "Distance Traveled" / "已行驶距离"
- `label.currentSpeed` = "Current Speed" / "当前速度"

## Files Modified

1. **Tikkuu Focus/Views/ActiveJourneyView.swift**
   - Removed "Warming up" status HStack from statsPanel
   - Updated CompactStatCard with theme support

2. **Tikkuu Focus/Views/SetupView.swift**
   - Changed preparing button text from `label.preparing` to `transport.status.warmingUp`

## Testing

- [ ] Distance and speed cards show Neumorphism effect when theme is Neumorphism
- [ ] Distance and speed cards show Liquid Glass effect when theme is Liquid Glass
- [ ] Light Neumorphism uses correct text colors (dark gray)
- [ ] Dark Neumorphism uses correct text colors (white/light)
- [ ] "Warming up" no longer appears in stats panel
- [ ] Start button shows "Warming up" / "正在热身" during preparing state

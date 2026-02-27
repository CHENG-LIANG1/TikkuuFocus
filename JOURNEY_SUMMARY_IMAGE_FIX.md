# Journey Summary Image Export Fix

## Summary

Fixed blurry image exports and added missing app name to the saved/shared journey summary images.

## Changes

### 1. Increased Rendering Scale

**Before:**
```swift
renderer.scale = PerformanceOptimizer.shared.isEnergySavingMode ? 1.2 : 1.35
```

**After:**
```swift
renderer.scale = 2.0  // High resolution for crisp images
```

### 2. Increased Map Snapshot Size

**Before:**
```swift
let snapshotSize = CGSize(width: 332, height: 180)
```

**After:**
```swift
let snapshotSize = CGSize(width: 700, height: 380)
```

### 3. Added App Name Header

Both Neumorphism and Liquid Glass export cards now include the app name:

```swift
Text("Roam Focus")
    .font(.system(size: 20, weight: .bold, design: .rounded))
    .foregroundColor(...)
    .padding(.top, 32)
```

### 4. Increased Card Size

**Before:**
- Card width: 360pt
- Card height: 700pt
- Route map height: 180pt
- Padding: 16pt

**After:**
- Card width: 390pt
- Card height: 760pt
- Route map height: 200pt
- Padding: 20pt

### 5. Removed/Reduced Compression

**Save to Photos:**
- Before: Compressed to max 450KB
- After: No compression, original high-quality image

**Share:**
- Before: Compressed to max 600KB
- After: No compression for images < 2MB, only compress to 1.5MB if > 2MB

### 6. Improved Map Image Rendering

Added `.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()` to ensure the map snapshot fills the entire route card area without distortion.

## Files Modified

1. **Tikkuu Focus/Views/JourneySummaryView.swift**
   - `renderAsImage()` - Increased scale and snapshot size
   - `neumorphicExportCard()` - Added app name, increased size
   - `liquidGlassExportCard()` - Added app name, increased size
   - `neumorphicExportRouteCard()` - Improved image rendering
   - `exportRouteCard()` - Improved image rendering
   - `saveImageToLibrary()` - Removed compression
   - `shareImage()` - Reduced compression threshold

## Result

- Images are now exported at 2x scale (780 x 1520 pixels)
- Map route images are clearer (700 x 380 base size)
- App name "Roam Focus" is displayed at the top of exported images
- No quality loss from compression when saving to photos
- File sizes are larger but quality is preserved

## Testing Checklist

- [ ] Saved image is crisp and not blurry
- [ ] Shared image is crisp and not blurry
- [ ] App name "Roam Focus" appears at the top of exported images
- [ ] Map route is clearly visible
- [ ] All metrics are readable
- [ ] Both Liquid Glass and Neumorphism themes work correctly

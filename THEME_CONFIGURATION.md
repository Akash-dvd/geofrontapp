# Theme Configuration - Cyan Theme with Auto Dark Mode

## Overview
Created a centralized theme system for GeoFront App with **Cyan** as the seed color.
- ✅ **Automatically follows system theme** (Light/Dark)
- ✅ **Material Design 3** with `ColorScheme.fromSeed`
- ✅ **Single point of control** for entire app theme

## Single Point of Control
All colors and styling are now controlled from one file:
**`lib/config/app_theme.dart`**

## How to Change the Entire Theme Color

### Change ONE Line to Theme the Entire App!
Edit the `seedColor` in `app_theme.dart`:
```dart
static const Color seedColor = Colors.cyan; // Current: Cyan
```

Flutter will automatically generate **all theme colors** from this seed!

Popular alternatives (just use Flutter's built-in colors):
- **`Colors.blue`** - Classic blue theme
- **`Colors.teal`** - Teal/turquoise
- **`Colors.green`** - Natural green
- **`Colors.purple`** - Professional purple
- **`Colors.pink`** - Vibrant pink
- **`Colors.orange`** - Energetic orange
- **`Colors.deepPurple`** - Rich purple
- **`Colors.indigo`** - Deep blue

### Difficulty Colors
```dart
static const Color beginnerColor = Color(0xFFC8E6C9);     // Light Green
static const Color intermediateColor = Color(0xFFFFF9C4);  // Light Yellow
static const Color advancedColor = Color(0xFFFFE0B2);      // Light Orange
static const Color expertColor = Color(0xFFFFCDD2);        // Light Red
```

### Category Color
```dart
static const Color categoryColor = Color(0xFFBBDEFB); // Light Blue
```

## Automatic System Theme Detection

The app automatically follows your system theme:
- **Light mode** → Shows light cyan theme
- **Dark mode** → Shows dark cyan theme

You can test this by:
1. **Windows:** Settings → Personalization → Colors → Choose your mode
2. **The app updates instantly!**

To force a specific theme, change in `main.dart`:
```dart
themeMode: ThemeMode.light,  // Always light
themeMode: ThemeMode.dark,   // Always dark
themeMode: ThemeMode.system, // Auto (current setting)
```

## What Gets Themed Automatically

✅ **AppBar** - Cyan in light mode, dark cyan in dark mode
✅ **Cards** - Elevation 2 (light), elevation 4 (dark)
✅ **Floating Action Button** - Themed cyan
✅ **Text Buttons** - Themed cyan
✅ **Elevated Buttons** - Themed cyan
✅ **Backgrounds** - White (light), dark gray (dark)
✅ **Text Colors** - Dark (light mode), light (dark mode)
✅ **All Material3 Components** - Automatically derived from cyan seed

## Files Modified

1. **`lib/config/app_theme.dart`** (NEW)
   - Centralized theme configuration
   - All color constants
   - Theme data definition

2. **`lib/main.dart`**
   - Changed from `Colors.deepPurple` to `AppTheme.lightTheme`
   - Single line: `theme: AppTheme.lightTheme`

3. **`lib/screens/problem_management_screen.dart`**
   - Now uses `AppTheme.beginnerColor`, `AppTheme.categoryColor`, etc.
   - No more hardcoded `Colors.blue[100]!` throughout code

## Benefits

✅ **Single Point of Control** - Change theme in one place
✅ **Consistency** - All screens use same colors automatically
✅ **Easy Maintenance** - No hunting for hardcoded colors
✅ **Scalability** - Add dark theme easily in future
✅ **Professional** - Material Design 3 compliant

## How ColorScheme.fromSeed Works

Flutter's `ColorScheme.fromSeed` is **magic**! From ONE color, it generates:
- Primary, secondary, tertiary colors
- Container colors
- Surface colors (backgrounds)
- Error colors
- Inverse colors
- And 40+ other theme colors!

All colors are:
- ✅ Harmonious and work well together
- ✅ Accessible (proper contrast ratios)
- ✅ Material Design 3 compliant
- ✅ Automatically adapted for dark mode

## Future Enhancements

You can easily add:
- Multiple theme presets (blue, green, purple)
- In-app theme switcher in settings
- Custom font families
- Custom text styles
- Per-user theme preferences

## Testing
Run the app with F5 - you should see:

**Light Mode:**
- Light cyan AppBar and FAB
- Light cyan accents throughout
- White backgrounds
- Dark text

**Dark Mode:**
- Dark cyan AppBar and FAB
- Dark backgrounds
- Light text
- Higher elevation shadows

**To test dark mode:**
1. Open Windows Settings → Personalization → Colors
2. Switch to "Dark" mode
3. Watch your app instantly update! 🌙

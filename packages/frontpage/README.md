# Frontpage Package

Modern landing page experience for **Akshara Intelligence** implemented in Flutter (web-first).

## Features

- Hero layout with animated geometry mesh, CTA buttons, and navigation anchors.
- Interactive geometry playground mock (client-side) with symbolic steps preview.
- Sections covering value propositions, feature showcase, testimonials, team, and CTA form.
- Request access form with mocked submission feedback.
- Accessibility-aware animations (respects `disableAnimations`).
- Example geometry payload JSON rendered in a code snippet.
- Responsive across desktop, tablet, and mobile breakpoints.

## Getting Started

```bash
# From repository root
flutter pub get

# Run the full application (includes front page + geoapp)
flutter run -d chrome
```

To develop only this package:

```bash
cd packages/frontpage
flutter pub get
flutter run -d chrome
```

> **Note:** The landing page depends on the local `geoapp` package for navigation to the problem list.

## Fonts & Assets

- **Fonts:** [Inter](https://fonts.google.com/specimen/Inter) and [Poppins](https://fonts.google.com/specimen/Poppins) via `google_fonts`.
- **Icons:** Material Icons (built-in).
- **Animations:** Custom `CustomPainter` mesh for hero background; no external animation files required.

## Integration Notes

- To update CTA form handling, replace the mock `Future.delayed` in `_CtaSectionState._submit` with a real API call.
- The interactive demo uses `_GeoPlaygroundPainter` for visuals and mocked symbolic steps (`sampleGeometrySteps`). Replace with real solver hooks when available.
- Example geometry payload is defined in `exampleGeometryPayload` for quick API contract reference.

## Testing Checklist

- [ ] Verify layout on desktop (`>=1200px`), tablet (`~900px`), and mobile (`<=480px`).
- [ ] Run with `--dart-define=FLUTTER_WEB_USE_SKIA=true` if testing high-DPI animations on web.
- [ ] Ensure navigation buttons scroll to the correct sections.
- [ ] Confirm "Open Problem Workspace" navigates to `ProblemManagementScreen` (geoapp).
- [ ] Submit CTA form and observe success/failure messaging.
- [ ] Toggle browser reduced-motion settings (if available) to disable hero animations.

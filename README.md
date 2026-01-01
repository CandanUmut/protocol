# Close the Ramp — Protocol (Flutter)

Offline-first Flutter application that mirrors the original index.html experience for the "Close the Ramp" protocol. The app runs on Android, iOS, and Web with bilingual support (TR/EN), local persistence via Hive, and an always-accurate emergency timer.

## Run

```bash
flutter pub get
flutter run             # mobile/desktop
flutter run -d chrome   # web
flutter build web
```

## Features
- Dashboard with streaks, monthly stats, and supportive chips.
- Calendar with Monday-first month grid, per-day toggles, notes, and emergencies.
- Emergency modal with 30-minute persistent timer and optional notifications.
- Custom todos, import/export/reset JSON state, offline-first storage.
- Premium dark UI, smooth animations, and haptics on key interactions.

## How to run (Android)
1. Start an Android emulator or connect a device.
2. Run `flutter pub get` to fetch dependencies.
3. Launch with `flutter run -d android`.

## How to run (Web)
1. Enable web with `flutter config --enable-web` (once).
2. Run `flutter pub get`.
3. Start with `flutter run -d chrome`.

# 0004: Mandatory Android Gradle Build Pipeline and Target SDK 36

## Context
Google Play Store submission requires Android App Bundles (AAB). In Godot 4.x, exporting an AAB requires the Gradle Build Template to be installed in the project, even if no custom Android plugins or Java dependencies are present. Additionally, Google Play enforces updated minimum target API levels (targetSdk 36 mandatory after August 31, 2026).

## Decision
1. **Gradle Build Template**: Install the official Godot Android Build Template at project initialization (`res://android/build/`) and enable "Use Gradle Build" in the Android export preset.
2. **Target API Level**: Explicitly set the export preset `targetSdk = 36` (with planned upgrade to 37 before August 2027).
3. **Debug Keystore**: Rely on Godot's auto-generated debug keystore (introduced in Godot 4.3) rather than manual `keytool` configuration.

## Consequences
- Eliminates late-stage release pipeline friction when generating production `.aab` packages.
- Guarantees immediate compliance with Google Play Store submission policies.

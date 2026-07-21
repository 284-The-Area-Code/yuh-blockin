# Remove Unused Firebase Components

This plan outlines the removal of unused Firebase dependencies, configuration files, and manifest entries to align the project with the "Firebase-free" declaration for the Google Play Store.

## User Review Required

> [!WARNING]
> This process will completely remove Firebase Messaging support from the project. Since the app currently uses a custom `dataSync` foreground service for real-time alerts, this removal will not impact the core functionality, but it is a permanent architectural change.

## Proposed Changes

### New Branch
- Created branch `cleanup/remove-unused-firebase`.

### 1. Dependencies & Configuration
- **[MODIFY] [pubspec.yaml](file:///home/xthebluepill/Documents/lab/yuh-blockin/pubspec.yaml)**: Remove `firebase_core` and `firebase_messaging`.
- **[DELETE] [firebase_options.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/firebase_options.dart)**: Delete the generated Firebase options file.
- **[DELETE] [google-services.json](file:///home/xthebluepill/Documents/lab/yuh-blockin/android/app/google-services.json)**: Delete the Android Firebase config.
- **[DELETE] [GoogleService-Info.plist](file:///home/xthebluepill/Documents/lab/yuh-blockin/ios/Runner/GoogleService-Info.plist)**: Delete the iOS Firebase config.

### 2. Android Manifest & Build
- **[MODIFY] [AndroidManifest.xml](file:///home/xthebluepill/Documents/lab/yuh-blockin/android/app/src/main/AndroidManifest.xml)**:
    - Remove the `FirebaseInitProvider` removal block.
    - Remove `firebase_messaging_auto_init_enabled` and `firebase_analytics_collection_enabled` meta-data.
- **[MODIFY] [app/build.gradle.kts](file:///home/xthebluepill/Documents/lab/yuh-blockin/android/app/build.gradle.kts)**: Ensure no `com.google.gms.google-services` plugin is applied.

### 3. Flutter Logic
- **[DELETE] [push_notification_service.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/core/services/push_notification_service.dart)**: Delete the unused Firebase service wrapper.
- **[MODIFY] [main.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/main.dart)**: Remove Firebase imports and initialization code in the `main()` and `_initializeApp` functions.

### 4. iOS Cleanup
- **[MODIFY] [Info.plist](file:///home/xthebluepill/Documents/lab/yuh-blockin/ios/Runner/Info.plist)**: Remove Firebase proxy and reporting flags.

## Verification Plan

### Automated Tests
- Run `flutter pub get` to update dependencies.
- Run `flutter build apk --release -t lib/main_premium.dart` to ensure the project still builds successfully without Firebase.
- Verify with `grep` that no Firebase-related strings remain in the `lib/` directory.

# Staged Build Fix and Dependency Upgrade (User Recommended Sequence)

This plan follows the user's recommended sequence to resolve build errors and upgrade dependencies safely, isolating environmental issues from version changes.

## User Review Required

> [!IMPORTANT]
> **Environment Fix**: The `AndroidLocationsBuildService` error was caused by conflicting environment variables (`ANDROID_USER_HOME`, `ANDROID_PREFS_ROOT`). These will be unset during the build process.

> [!WARNING]
> **Kotlin Version**: Kotlin will remain at **2.1.0** to ensure maximum plugin compatibility, as recommended.

## Proposed Changes

### 1. Git Checkpoint
- Perform a git commit to save the current working state (with the code fix already applied) before making build configuration changes.

### 2. Remove Forced ResolutionStrategy
- **[MODIFY] [build.gradle.kts](file:///home/xthebluepill/Documents/lab/yuh-blockin/android/build.gradle.kts)**: Remove the forced `resolutionStrategy` for AGP and Kotlin. This lets the `plugins` block manage versions properly.

### 3. Upgrade Gradle Wrapper
- **[MODIFY] [gradle-wrapper.properties](file:///home/xthebluepill/Documents/lab/yuh-blockin/android/gradle/wrapper/gradle-wrapper.properties)**: Update `distributionUrl` to Gradle **8.14.5**.

### 4. Upgrade Android Gradle Plugin (AGP)
- **[MODIFY] [settings.gradle.kts](file:///home/xthebluepill/Documents/lab/yuh-blockin/android/settings.gradle.kts)**: Update `com.android.application` version to **8.7.3**.

## Verification Plan

### Automated Tests
1. **Unset environment variables**: `unset ANDROID_USER_HOME`, `unset ANDROID_PREFS_ROOT`.
2. **Clean rebuild**:
   - `flutter clean`
   - `flutter pub get`
   - `flutter build apk --release -t lib/main_premium.dart`

### Success Criteria
- [ ] No `AndroidLocationsBuildService` error.
- [ ] `flutter build apk` completes successfully.
- [ ] AGP version warning is resolved.

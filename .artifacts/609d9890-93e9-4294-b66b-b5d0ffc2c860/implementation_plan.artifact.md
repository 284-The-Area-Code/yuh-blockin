# Unify Entry Points and Fix Notification Badges

This plan consolidates the project into a single `main.dart` entry point and resolves the issues with notification badges (Alerts and History) not clearing properly.

## User Review Required

> [!IMPORTANT]
> **Single Entry Point**: I will be deleting `lib/main_premium.dart` and merging its unique UI enhancements (edge-to-edge mode, scroll physics) into `lib/main.dart`. You should use `lib/main.dart` for all future builds.

> [!NOTE]
> **Badge Fix**: The "sticky" notification counts are caused by a race condition between local state resets and the background data refresh. I will ensure resets are persistent and awaited.

## Proposed Changes

### 1. Unified Main Entry Point

#### [MODIFY] [main.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/main.dart)
- Integrate `SystemChrome` configuration (edge-to-edge style) from `main_premium.dart`.
- Add `scrollBehavior` with `BouncingScrollPhysics` to the `MaterialApp` to ensure consistent "premium" feel across platforms.
- Ensure all latest service initializations (like `AccountRecoveryService`) are preserved.

#### [DELETE] [main_premium.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/main_premium.dart)
- Remove the redundant second main file.

### 2. Badge & Logic Fixes (in `main.dart`)

#### [MODIFY] `_PremiumHomeScreenState`
- **History Badge**:
    - In `_buildCompactStatsIcon`, await `_resetUnseenImpact()` before showing the dialog.
    - Ensure `_unseenImpactCount` is explicitly set to 0 in `setState`.
- **Alerts Badge**:
    - In `_buildCompactNotificationIcon`, await `_resetUnseenAlerts()` before navigating to `AlertHistoryScreen`.
    - Mark all current `_recentReceivedAlerts` as read locally to ensure the badge disappears instantly.
- **Refresh Logic**:
    - Update `_refreshAllData` to reliably read the "cleared" state from storage.

### 3. Feature Imports Cleanup

#### [MODIFY] Feature Files
Update the following files to import `main.dart` instead of `main_premium.dart`:
- `lib/features/onboarding/onboarding_flow.dart`
- `lib/features/account_recovery/login_with_key_screen.dart`
- `lib/features/plate_registration/plate_registration_screen.dart`
- `lib/features/theme_settings/theme_settings_screen.dart`

## Verification Plan

### Automated Tests
- Run `flutter clean`.
- Run `flutter run --release -d emulator-5554` (using default `main.dart`).
- Verify the app launches with the edge-to-edge UI and premium scroll physics.

### Manual Verification
1. **Alerts Badge**: Trigger an alert, verify badge appears. Click it, navigate to history, return, and verify badge is GONE.
2. **History Badge**: Increase stats (send/receive alert), verify history badge appears. Click it, close dialog, and verify badge is GONE.
3. **Themes**: Change themes via the menu to ensure `ThemeNotifier` is working from the centralized file.

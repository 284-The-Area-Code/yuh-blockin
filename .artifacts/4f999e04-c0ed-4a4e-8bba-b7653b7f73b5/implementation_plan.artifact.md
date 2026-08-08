# Implementation Plan - Fix Network Cold Start / "Double Launch" Bug

Resolve the issue where the app requires two launches to establish a backend connection. This is caused by a race condition where the app attempts to authenticate and verify the user before the mobile network has fully "warmed up" on cold start.

## User Review Required

> [!IMPORTANT]
> I am implementing a "Network Warmer" logic. This makes the app more patient during the splash screen, allowing it to wait for the system network to stabilize and retrying authentication if it fails initially.

## Proposed Changes

### 1. Connectivity Service (Resilience)

#### [MODIFY] [connectivity_service.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/core/services/connectivity_service.dart)
- Update `initialize` to perform a more robust initial check. If the system reports `none` initially, it will retry once after a 1-second delay to catch "waking" networks.

### 2. Simple Alert Service (Persistent Auth)

#### [MODIFY] [simple_alert_service.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/core/services/simple_alert_service.dart)
- Implement **Automatic Retries** for `signInAnonymously()`. If the initial handshake fails due to network jitter, it will retry up to 3 times with exponential backoff.
- This ensures the `auth.uid()` is properly established during the splash screen.

### 3. App Initialization (Robustness)

#### [MODIFY] [main.dart](file:///home/xthebluepill/Documents/lab/yuh-blockin/lib/main.dart)
- Adjust `_checkOnboardingStatus` to handle the transition more gracefully if the network is taking longer than expected.
- Ensure the app doesn't fall back to "safe mode" (skipping onboarding) unless it's absolutely sure about the user's status.

## Verification Plan

### Manual Verification
1. **Cold Start Simulation**: Kill the app, toggle Airplane mode on and off, then immediately launch the app. It should now reach the home screen on the first try once the bars return.
2. **First-Launch Success**: Delete the app, reinstall, and verify onboarding appears on the first launch without needing a restart.

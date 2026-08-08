# Guide: Uploading a New Version to Google Play Store

Since we have resolved the build issues and the `USE_EXACT_ALARM` policy violation, follow these steps to upload your fixed app bundle (Version Code 2) to the Play Console.

## Step 1: Build the App Bundle

Run the following command in your terminal to create the release production bundle.

```bash
flutter build appbundle --release
```

- **Output Location**: `build/app/outputs/bundle/release/app-release.aab`
- **Verification**: Ensure the build completes without errors. The fixes we applied (namespace injection and task sequencing) will ensure this works with AGP 8.x.

---

## Step 2: Navigate to Google Play Console

1.  Open the [Google Play Console](https://play.google.com/console).
2.  Select your app: **Yuh Blockin**.
3.  In the left-hand menu, scroll down to the **Release** section and select **Production**.
    - *Note: If you are testing first, select **Internal testing** or **Closed testing** instead.*

---

## Step 3: Create a New Release

1.  Click the **Create new release** button in the top right corner.
2.  **Upload the Bundle**:
    - Drag and drop the `app-release.aab` file from your project's `build/app/outputs/bundle/release/` folder into the upload box.
    - Wait for the upload to complete and for Google to process the file.
3.  **Release Name**: This will automatically populate based on your `pubspec.yaml` (e.g., `1.0.0 (2)`).
4.  **Release Notes**: Enter what’s new (e.g., "Resolved background service and alarm permission issues for Android 14+ compatibility.").

---

## Step 4: Review and Roll Out

1.  Click **Next** (or **Save** then **Review release**).
2.  **Check for Warnings**: Google may show warnings about missing obfuscation files (mapping.txt) or API declarations.
    - > [!IMPORTANT]
      > The "Exact Alarm" policy warning should no longer appear for this specific bundle because we removed the permission.
3.  Click **Start rollout to Production**.
4.  Confirm the rollout.

---

## Troubleshooting Common Upload Issues

### "Version Code 2 has already been used"
If you previously uploaded a version 2 and deleted it, you might need to increment the version again.
- Open [pubspec.yaml](file:///home/xthebluepill/Documents/lab/yuh-blockin/pubspec.yaml)
- Change `version: 1.0.0+2` to `version: 1.0.0+3`
- Re-run `flutter build appbundle --release`

### "Namespace not specified" (during build)
We fixed this in `build.gradle.kts`. If it reappears, ensure you have run a `flutter clean` before building to clear stale configuration caches.

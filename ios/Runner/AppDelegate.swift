import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {

  // MARK: - T0 diagnostic instrumentation

  private func diag(_ message: String) {
    print("[APNS-DIAG] \(message)")
  }

  private func describe(_ status: UNAuthorizationStatus) -> String {
    if #available(iOS 14.0, *), status == .ephemeral { return "ephemeral" }
    switch status {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    case .provisional: return "provisional"
    @unknown default: return "unknown(\(status.rawValue))"
    }
  }

  private func describe(_ setting: UNNotificationSetting) -> String {
    switch setting {
    case .notSupported: return "notSupported"
    case .disabled: return "disabled"
    case .enabled: return "enabled"
    @unknown default: return "unknown(\(setting.rawValue))"
    }
  }

  private func describe(_ style: UNAlertStyle) -> String {
    switch style {
    case .none: return "none"
    case .banner: return "banner"
    case .alert: return "alert"
    @unknown default: return "unknown(\(style.rawValue))"
    }
  }

  private func logNotificationSettings(phase: String) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      var fields = [
        "authorizationStatus=\(self.describe(settings.authorizationStatus))",
        "alertSetting=\(self.describe(settings.alertSetting))",
        "lockScreenSetting=\(self.describe(settings.lockScreenSetting))",
        "notificationCenterSetting=\(self.describe(settings.notificationCenterSetting))",
        "soundSetting=\(self.describe(settings.soundSetting))",
        "badgeSetting=\(self.describe(settings.badgeSetting))",
        "criticalAlertSetting=\(self.describe(settings.criticalAlertSetting))",
      ]
      if #available(iOS 15.0, *) {
        fields.append("scheduledDeliverySetting=\(self.describe(settings.scheduledDeliverySetting))")
        fields.append("timeSensitiveSetting=\(self.describe(settings.timeSensitiveSetting))")
      } else {
        fields.append("scheduledDeliverySetting=unavailable")
        fields.append("timeSensitiveSetting=unavailable")
      }
      fields.append("alertStyle=\(self.describe(settings.alertStyle))")
      self.diag("settings[\(phase)] " + fields.joined(separator: " "))
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1. Register Flutter plugins BEFORE starting the engine.
    // FlutterAppDelegate does NOT do this for you - Flutter's own iOS template
    // registers explicitly, and omitting it leaves every plugin's platform channel
    // without a receiver. Removing this line previously broke shared_preferences,
    // firebase_messaging, permission_handler and every other plugin on iOS:
    //   PlatformException(channel-error, Unable to establish connection on channel:
    //   "dev.flutter.pigeon.shared_preferences_foundation.LegacyUserDefaultsApi.getAll")
    GeneratedPluginRegistrant.register(with: self)

    // 2. Start the Flutter engine.
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // 3. Initialize Firebase natively
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      print("🚀 Native: Firebase initialized")
    }

    // 4. T0: request notification authorization, then register with APNs from the
    // authorization callback. Apple documents that without authorization for user-facing
    // notification interactions, remote notifications are delivered silently.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    logNotificationSettings(phase: "launch")

    diag("requestAuthorization(options: [.alert, .sound, .badge]) called")
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { [weak self] granted, error in
      guard let self = self else { return }
      let ns = error as NSError?
      self.diag("requestAuthorization result: granted=\(granted) error="
        + (ns.map { "\($0.domain)/\($0.code) \($0.localizedDescription)" } ?? "nil"))
      self.logNotificationSettings(phase: "postAuthorization")

      DispatchQueue.main.async {
        self.diag("registerForRemoteNotifications() called")
        application.registerForRemoteNotifications()
      }
    }

    return result
  }

  // Handle successful APNs registration
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Invoke super immediately so Flutter plugins get the token first
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

    // Log byte count and a short prefix only. The full token is deliberately not written
    // to CI logs; capture it separately in a controlled diagnostic if validation needs it.
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    diag("didRegisterForRemoteNotifications tokenBytes=\(deviceToken.count) tokenPrefix=\(String(tokenString.prefix(12)))")

    // Explicitly pass APNs token to Firebase Messaging as a backup
    Messaging.messaging().apnsToken = deviceToken
    diag("Messaging.messaging().apnsToken assigned")

    print("✅ APNs: Registration SUCCESS!")
    print("✅ APNs: Device token (first 20 chars): \(String(tokenString.prefix(20)))...")
  }

  // Handle failed APNs registration
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Invoke super immediately
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)

    let ns = error as NSError
    diag("didFailToRegisterForRemoteNotifications domain=\(ns.domain) code=\(ns.code) description=\(ns.localizedDescription)")

    let errorDescription = error.localizedDescription
    print("❌ APNs: Registration FAILED!")
    print("❌ APNs: Error: \(errorDescription)")

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.yuhblockin.v1/push_diagnostics",
                                        binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("onNativeRegistrationError", arguments: ["error": errorDescription])
    }
  }

  // T0: re-read settings after the Dart permission requests have had a chance to run.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    logNotificationSettings(phase: "didBecomeActive")
  }
}

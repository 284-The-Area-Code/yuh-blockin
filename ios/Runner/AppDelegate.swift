import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Initialize Firebase natively
    // This is required for reliable APNs -> FCM token handoff
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      print("🚀 Native: Firebase initialized")
    }

    GeneratedPluginRegistrant.register(with: self)

    // Register for remote notifications with APNs
    // This is required by Apple - must be called at launch
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    print("📱 APNs: Calling registerForRemoteNotifications()")
    application.registerForRemoteNotifications()
    print("📱 APNs: isRegisteredForRemoteNotifications = \(application.isRegisteredForRemoteNotifications)")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle successful APNs registration
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Explicitly pass APNs token to Firebase Messaging
    // This resolves issues where swizzling might fail or be delayed
    Messaging.messaging().apnsToken = deviceToken

    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ APNs: Registration SUCCESS!")
    print("✅ APNs: Device token (first 20 chars): \(String(tokenString.prefix(20)))...")

    // Pass device token to Flutter/Firebase
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle failed APNs registration
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let errorDescription = error.localizedDescription
    print("❌ APNs: Registration FAILED!")
    print("❌ APNs: Error: \(errorDescription)")

    // Pass failure to Dart diagnostic state if the channel is set up
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.yuhblockin.v1/push_diagnostics",
                                        binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("onNativeRegistrationError", arguments: ["error": errorDescription])
    }

    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

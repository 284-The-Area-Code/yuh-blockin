import Flutter
import UIKit
import SwiftUI
import StoreKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let subscriptionStoreChannel = SubscriptionStoreChannel()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Register for remote notifications
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)

    // Register SubscriptionStoreView method channel for App Store compliance
    if let controller = window?.rootViewController as? FlutterViewController {
      subscriptionStoreChannel.register(with: controller)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // APNs token received
  override func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅ APNs token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // APNs registration failed
  override func application(_ application: UIApplication,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

// MARK: - SubscriptionStoreView Method Channel Handler

/// Method Channel handler for Flutter communication
class SubscriptionStoreChannel {
    static let channelName = "com.dezetingz.yuhBlockin/subscription_store"

    private var flutterResult: FlutterResult?

    func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: SubscriptionStoreChannel.channelName,
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSubscriptionStoreViewAvailable":
            if #available(iOS 17.0, *) {
                result(true)
            } else {
                result(false)
            }

        case "showSubscriptionStoreView":
            guard let args = call.arguments as? [String: Any],
                  let productIds = args["productIds"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGS",
                                   message: "productIds required",
                                   details: nil))
                return
            }

            if #available(iOS 17.0, *) {
                self.flutterResult = result
                showNativeSubscriptionStore(productIds: productIds)
            } else {
                result(FlutterError(code: "UNAVAILABLE",
                                   message: "SubscriptionStoreView requires iOS 17+",
                                   details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @available(iOS 17.0, *)
    private func showNativeSubscriptionStore(productIds: [String]) {
        DispatchQueue.main.async { [weak self] in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                self?.flutterResult?(FlutterError(code: "NO_VIEW",
                                                  message: "No root view controller",
                                                  details: nil))
                return
            }

            // Find the topmost presented controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            let subscriptionVC = SubscriptionStoreHostingController(
                productIds: productIds,
                onPurchaseComplete: { [weak self] success, productId in
                    self?.flutterResult?([
                        "success": success,
                        "productId": productId as Any
                    ])
                    self?.flutterResult = nil
                },
                onDismiss: { [weak self] in
                    if self?.flutterResult != nil {
                        self?.flutterResult?([
                            "success": false,
                            "cancelled": true
                        ])
                        self?.flutterResult = nil
                    }
                }
            )

            topController.present(subscriptionVC, animated: true)
        }
    }
}

// MARK: - Native SubscriptionStoreView (iOS 17+)

/// UIHostingController wrapper for SubscriptionStoreView
@available(iOS 17.0, *)
class SubscriptionStoreHostingController: UIHostingController<SubscriptionStoreViewWrapper> {

    init(productIds: [String],
         onPurchaseComplete: @escaping (Bool, String?) -> Void,
         onDismiss: @escaping () -> Void) {
        let view = SubscriptionStoreViewWrapper(
            productIds: productIds,
            onPurchaseComplete: onPurchaseComplete,
            onDismiss: onDismiss
        )
        super.init(rootView: view)
        self.modalPresentationStyle = .pageSheet
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// SwiftUI wrapper for SubscriptionStoreView - provides App Store compliant subscription UI
@available(iOS 17.0, *)
struct SubscriptionStoreViewWrapper: View {
    let productIds: [String]
    let onPurchaseComplete: (Bool, String?) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: productIds) {
                // Header content
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    Text("Yuh Blockin' Premium")
                        .font(.title.bold())

                    Text("Unlock unlimited alerts and premium features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }
            .subscriptionStoreControlStyle(.prominentPicker)
            .storeButton(.visible, for: .restorePurchases)
            .onInAppPurchaseCompletion { product, result in
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        print("✅ Purchase verified: \(transaction.productID)")
                        onPurchaseComplete(true, transaction.productID)
                        await transaction.finish()
                    case .unverified(_, let error):
                        print("❌ Purchase unverified: \(error)")
                        onPurchaseComplete(false, nil)
                    }
                case .failure(let error):
                    print("❌ Purchase failed: \(error)")
                    onPurchaseComplete(false, nil)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

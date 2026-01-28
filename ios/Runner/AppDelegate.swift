import Flutter
import UIKit
import SwiftUI
import StoreKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let subscriptionStoreChannel = SubscriptionStoreChannel()
  private var transactionObserverTask: Task<Void, Never>?

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

    // Start listening for StoreKit 2 transaction updates (required by Apple)
    // This handles transactions that complete while app is backgrounded,
    // Ask to Buy approvals, and Family Sharing transactions
    if #available(iOS 15.0, *) {
      startTransactionObserver()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Start observing StoreKit 2 transaction updates
  @available(iOS 15.0, *)
  private func startTransactionObserver() {
    transactionObserverTask = Task(priority: .background) {
      for await result in Transaction.updates {
        do {
          let transaction = try checkVerified(result)
          print("✅ Transaction update received: \(transaction.productID)")
          // Finish the transaction so it's not delivered again
          await transaction.finish()
          // Notify Flutter side to refresh entitlements
          NotificationCenter.default.post(name: NSNotification.Name("TransactionUpdated"), object: nil)
        } catch {
          print("❌ Transaction verification failed: \(error)")
        }
      }
    }
  }

  @available(iOS 15.0, *)
  private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(_, let error):
      throw error
    case .verified(let safe):
      return safe
    }
  }

  deinit {
    transactionObserverTask?.cancel()
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
    private weak var presentedController: UIViewController?

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

            // CRITICAL: SubscriptionStoreView ONLY supports auto-renewable subscriptions
            // Filter out non-subscription products (like lifetime one-time purchases)
            let subscriptionProductIds = productIds.filter { productId in
                // Only include products that are subscriptions (monthly/yearly patterns)
                productId.contains("monthly") || productId.contains("yearly") ||
                productId.contains("annual") || productId.contains("weekly")
            }

            if subscriptionProductIds.isEmpty {
                result(FlutterError(code: "NO_SUBSCRIPTIONS",
                                   message: "No subscription products provided. SubscriptionStoreView only supports auto-renewable subscriptions.",
                                   details: nil))
                return
            }

            if #available(iOS 17.0, *) {
                self.flutterResult = result
                showNativeSubscriptionStore(productIds: subscriptionProductIds)
            } else {
                result(FlutterError(code: "UNAVAILABLE",
                                   message: "SubscriptionStoreView requires iOS 17+",
                                   details: nil))
            }

        case "purchaseProduct":
            // New method for purchasing non-subscription products (like lifetime)
            guard let args = call.arguments as? [String: Any],
                  let productId = args["productId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS",
                                   message: "productId required",
                                   details: nil))
                return
            }

            if #available(iOS 15.0, *) {
                Task {
                    await self.purchaseNonSubscriptionProduct(productId: productId, result: result)
                }
            } else {
                result(FlutterError(code: "UNAVAILABLE",
                                   message: "StoreKit 2 requires iOS 15+",
                                   details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Purchase a non-subscription product using StoreKit 2
    @available(iOS 15.0, *)
    private func purchaseNonSubscriptionProduct(productId: String, result: @escaping FlutterResult) async {
        do {
            // Fetch the product
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PRODUCT_NOT_FOUND",
                                       message: "Product \(productId) not found in App Store",
                                       details: nil))
                }
                return
            }

            // Attempt purchase
            let purchaseResult = try await product.purchase()

            switch purchaseResult {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("✅ Non-subscription purchase verified: \(transaction.productID)")
                    await transaction.finish()
                    DispatchQueue.main.async {
                        result([
                            "success": true,
                            "productId": transaction.productID
                        ])
                    }
                case .unverified(_, let error):
                    print("❌ Non-subscription purchase unverified: \(error)")
                    DispatchQueue.main.async {
                        result([
                            "success": false,
                            "error": "Purchase verification failed: \(error.localizedDescription)"
                        ])
                    }
                }
            case .pending:
                print("⏳ Non-subscription purchase pending (Ask to Buy)")
                DispatchQueue.main.async {
                    result([
                        "success": false,
                        "pending": true,
                        "error": "Purchase requires approval. You'll be notified when it's complete."
                    ])
                }
            case .userCancelled:
                print("🚫 Non-subscription purchase cancelled")
                DispatchQueue.main.async {
                    result([
                        "success": false,
                        "cancelled": true
                    ])
                }
            @unknown default:
                DispatchQueue.main.async {
                    result([
                        "success": false,
                        "error": "Unknown purchase result"
                    ])
                }
            }
        } catch {
            print("❌ Non-subscription purchase error: \(error)")
            DispatchQueue.main.async {
                result(FlutterError(code: "PURCHASE_ERROR",
                                   message: error.localizedDescription,
                                   details: nil))
            }
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
                    // Dismiss the view controller first
                    self?.presentedController?.dismiss(animated: true) {
                        self?.flutterResult?([
                            "success": success,
                            "productId": productId as Any
                        ])
                        self?.flutterResult = nil
                        self?.presentedController = nil
                    }
                },
                onDismiss: { [weak self] in
                    self?.presentedController?.dismiss(animated: true) {
                        if self?.flutterResult != nil {
                            self?.flutterResult?([
                                "success": false,
                                "cancelled": true
                            ])
                            self?.flutterResult = nil
                        }
                        self?.presentedController = nil
                    }
                }
            )

            self?.presentedController = subscriptionVC
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
                // Handle purchase completion in a Task to properly await transaction.finish()
                Task { @MainActor in
                    await handlePurchaseResult(result)
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

    /// Handle purchase result with proper async/await for transaction.finish()
    @MainActor
    private func handlePurchaseResult(_ result: Result<Product.PurchaseResult, any Error>) async {
        switch result {
        case .success(let purchaseResult):
            switch purchaseResult {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("✅ Subscription purchase verified: \(transaction.productID)")
                    // IMPORTANT: Finish transaction first, then notify
                    await transaction.finish()
                    onPurchaseComplete(true, transaction.productID)
                case .unverified(_, let error):
                    print("❌ Subscription purchase unverified: \(error)")
                    onPurchaseComplete(false, nil)
                }
            case .pending:
                print("⏳ Subscription purchase pending (Ask to Buy)")
                // Don't call onPurchaseComplete for pending - user will be notified later
                // via Transaction.updates listener
                onPurchaseComplete(false, nil)
            case .userCancelled:
                print("🚫 Subscription purchase cancelled by user")
                // Don't show error for user cancellation, just close
                onPurchaseComplete(false, nil)
            @unknown default:
                print("⚠️ Unknown purchase result")
                onPurchaseComplete(false, nil)
            }
        case .failure(let error):
            print("❌ Subscription purchase failed: \(error.localizedDescription)")
            onPurchaseComplete(false, nil)
        }
    }
}

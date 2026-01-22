import UIKit
import SwiftUI
import StoreKit

/// Native SubscriptionStoreView wrapper for App Store compliance
/// Requires iOS 17.0+ - caller must check availability before using
@available(iOS 17.0, *)
class SubscriptionStoreViewController: UIViewController {

    private let productIds: [String]
    private let onPurchaseComplete: ((Bool, String?) -> Void)?
    private let onDismiss: (() -> Void)?

    init(productIds: [String],
         onPurchaseComplete: ((Bool, String?) -> Void)? = nil,
         onDismiss: (() -> Void)? = nil) {
        self.productIds = productIds
        self.onPurchaseComplete = onPurchaseComplete
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubscriptionStoreView()
    }

    private func setupSubscriptionStoreView() {
        let subscriptionView = SubscriptionStoreViewWrapper(
            productIds: productIds,
            onPurchaseComplete: { [weak self] success, productId in
                self?.onPurchaseComplete?(success, productId)
                if success {
                    self?.dismiss(animated: true)
                }
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.onDismiss?()
                }
            }
        )

        let hostingController = UIHostingController(rootView: subscriptionView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}

/// SwiftUI wrapper for SubscriptionStoreView
@available(iOS 17.0, *)
struct SubscriptionStoreViewWrapper: View {
    let productIds: [String]
    let onPurchaseComplete: (Bool, String?) -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

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

/// Method Channel handler for Flutter communication
class SubscriptionStoreChannel {
    static let channelName = "com.dezetingz.yuhBlockin/subscription_store"

    private var flutterResult: FlutterResult?

    func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: SubscriptionStoreChannel.channelName,
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler(handle)
    }

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

            let subscriptionVC = SubscriptionStoreViewController(
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

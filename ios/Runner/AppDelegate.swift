import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  // iOS has no FLAG_SECURE equivalent to block screenshots outright. The
  // standard mitigation is covering sensitive content with a blur view
  // whenever the app resigns active — otherwise iOS's app-switcher snapshot
  // (and, on some versions, the lock-screen "last app" preview) would show
  // whatever was on screen, e.g. a private key or seed phrase.
  private var isSensitiveScreenActive = false
  private var privacyOverlay: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "secure_screen",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "activate":
          self?.isSensitiveScreenActive = true
          result(nil)
        case "deactivate":
          self?.isSensitiveScreenActive = false
          self?.removePrivacyOverlay()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    if isSensitiveScreenActive {
      addPrivacyOverlay()
    }
    super.applicationWillResignActive(application)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    removePrivacyOverlay()
    super.applicationDidBecomeActive(application)
  }

  private func addPrivacyOverlay() {
    guard privacyOverlay == nil, let window = self.window else { return }
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blur.tag = 0x5ec12ee9
    window.addSubview(blur)
    privacyOverlay = blur
  }

  private func removePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}

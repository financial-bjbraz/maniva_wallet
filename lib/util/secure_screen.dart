import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

/// Protects sensitive screens (private key/seed display, send screens, etc.)
/// from appearing in screenshots or OS-level app previews.
///
/// - **Android**: applies [FLAG_SECURE](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#FLAG_SECURE),
///   which blocks screenshots/screen recording outright and blanks the
///   app-switcher thumbnail.
/// - **iOS**: there is no public API to block screenshots. The standard
///   mitigation — covering the window with a blur view whenever the app
///   resigns active — is implemented natively in AppDelegate.swift and
///   toggled here via a method channel, so the app-switcher snapshot never
///   shows sensitive content (screenshots taken while the app is foregrounded
///   and active still work; iOS has no way to prevent those for a
///   third-party app).
/// - Other platforms: no-op.
///
/// Usage — call in the enclosing [State]:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   SecureScreen.activate();
/// }
///
/// @override
/// void dispose() {
///   SecureScreen.deactivate();
///   super.dispose();
/// }
/// ```
class SecureScreen {
  // Pure static helper — not meant to be instantiated.
  const SecureScreen._();

  static const MethodChannel _iosChannel = MethodChannel('secure_screen');

  /// Enable screen-capture protection for the current platform.
  ///
  /// Safe to call from [State.initState] because both the Android window
  /// flag and the iOS method channel call are fire-and-forget — neither
  /// requires the widget tree to be fully mounted.
  static Future<void> activate() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      try {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } catch (_) {
        // Non-fatal: some Android emulators / test environments do not
        // support the FLAG_SECURE window flag. Swallow so the rest of the
        // screen initialisation proceeds normally.
      }
      return;
    }
    if (Platform.isIOS) {
      try {
        await _iosChannel.invokeMethod('activate');
      } catch (_) {
        // Non-fatal — same rationale as above.
      }
    }
  }

  /// Disable screen-capture protection for the current platform.
  ///
  /// Call this **before** [super.dispose()] so the protection is cleared
  /// even if another screen does not set it.
  static Future<void> deactivate() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      try {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      } catch (_) {
        // Non-fatal — same rationale as [activate].
      }
      return;
    }
    if (Platform.isIOS) {
      try {
        await _iosChannel.invokeMethod('deactivate');
      } catch (_) {
        // Non-fatal — same rationale as [activate].
      }
    }
  }
}

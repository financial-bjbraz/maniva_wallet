import 'dart:io' show exit, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';

import '../l10n/app_localizations.dart';
import 'util.dart';

/// Quits the running application using the right mechanism per platform.
///
/// `flutter_exit_app` only ships native implementations for Android and iOS
/// — on macOS/Linux/Windows its method channel call has nothing to answer it
/// and silently fails. Desktop platforms are regular OS processes with no App
/// Store-style restriction against self-terminating, so `dart:io`'s `exit(0)`
/// is the standard, safe way to quit there. A browser tab can't be closed
/// programmatically unless it was opened via script (a security restriction,
/// not a bug), so on web this just tells the user to close the tab.
Future<void> exitApplication(BuildContext context, {bool iosForceExit = false}) async {
  if (kIsWeb) {
    showMessage(AppLocalizations.of(context)!.exitWebMessage, context);
    return;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    await FlutterExitApp.exitApp(iosForceExit: iosForceExit);
    return;
  }
  // macOS, Linux, Windows.
  exit(0);
}

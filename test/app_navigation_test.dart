// Regression test for the double-MaterialApp navigation bug: main.dart used
// to nest a second, unlocalized MaterialApp around MyApp's home route, and
// some routes pushed deep in the wallet-creation flow ended up resolving
// Navigator.of(context) to that outer MaterialApp instead of the properly
// localized inner one, crashing on AppLocalizations.of(context)! (see the
// doc comment on MyApp in lib/main.dart). Boots the real widget tree (real
// providers, real Splash -> Login boot sequence) with fakes only for the
// platform channels (SharedPreferences, path_provider) that don't have a
// native backend under `flutter test`, and asserts: exactly one MaterialApp
// exists, and nothing threw while getting there.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maniva_wallet/main.dart';
import 'package:maniva_wallet/services/create_user_service.dart';
import 'package:maniva_wallet/services/wallet_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String _tempPath = Directory.systemTemp.createTempSync('maniva_test_').path;

  @override
  Future<String?> getApplicationSupportPath() async => _tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // EntityHelper only has a real (native-plugin-backed) sqlite path for
    // android/iOS/macOS (sqlcipher, unavailable under `flutter test`) or the
    // pure-Dart FFI path for everything else — force the latter.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('app boots through Splash to Login with a single MaterialApp and no errors',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      originalOnError?.call(details);
    };

    try {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletServiceImpl>(create: (_) => WalletServiceImpl()),
          ChangeNotifierProvider(create: (_) => CreateUserServiceImpl()),
        ],
        child: const MyApp(),
      ));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'exactly one MaterialApp should exist in the tree — a second one is how '
              'Navigator.of(context) ended up resolving to the wrong Navigator before');

      expect(errors, isEmpty,
          reason: 'widget tree threw while booting: ${errors.map((e) => e.exceptionAsString())}');
    } finally {
      FlutterError.onError = originalOnError;
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

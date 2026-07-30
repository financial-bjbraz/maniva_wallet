import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hux/hux.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/pages/splash.dart';
import 'package:maniva_wallet/services/create_user_service.dart';
import 'package:maniva_wallet/services/wallet_service.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stac/stac.dart';

import 'l10n/app_localizations.dart';
import 'util/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });
  await Stac.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: rootstockBlack,
      systemNavigationBarColor: rootstockBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await dotenv.load(fileName: ".env");
  await SentryFlutter.init(
    (options) {
      final sentryDsn = dotenv.env['SENTRY_DSN'];
      if (sentryDsn != null && sentryDsn.isNotEmpty) {
        options.dsn = sentryDsn;
      }
      // Disabled: this is a wallet app — request headers and user IP aren't
      // needed for crash diagnostics and shouldn't leave the device. See
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = false;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletServiceImpl>(create: (context) => WalletServiceImpl()),
        ChangeNotifierProvider(create: (context) => CreateUserServiceImpl())
      ],
      child: MaterialApp(
        theme: HuxTheme.lightTheme,
        darkTheme: HuxTheme.darkTheme,
        home: const MyApp(),
      )))),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletServiceImpl>();
    walletService.loadLocale();
    walletService.loadCustomNodeUrls();

    Future<bool> myFuture() async {
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      //
      // await FirebaseMessaging.instance.setAutoInitEnabled(true);
      // final fcmToken = await FirebaseMessaging.instance.getToken();
      // if (kDebugMode) {
      //   print("=================================");
      //   print(fcmToken);
      //   print("=================================");
      // }

      return true;
    }

    return FutureBuilder(
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Maniva Wallet',
              theme: rootstockTheme,
              scrollBehavior: AppScrollBehavior(),
              locale: walletService.selectedLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Splash(),
            );
          }
          return const Center(
              child: Center(
            child: CircularProgressIndicator(),
          ));
        },
        future: myFuture());
  }
}

/// Flutter's default ScrollBehavior excludes the mouse from drag-to-scroll
/// devices on desktop platforms (only touch/stylus/trackpad scroll by
/// default), so scrollable content is unreachable with a plain mouse on
/// macOS/Linux/Windows. This adds mouse support app-wide.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

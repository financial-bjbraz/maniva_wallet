import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/pages/splash.dart';
import 'package:my_rootstock_wallet/services/create_user_service.dart';
import 'package:my_rootstock_wallet/services/wallet_service.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stac/stac.dart';

import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Stac.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: Colors.white,
      systemNavigationBarColor: Colors.white,
    ),
  );
  await dotenv.load(fileName: ".env");
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://98a666fc899d04aa52c42976b7b0f2ee@o4509989969657856.ingest.us.sentry.io/4510857924968448';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
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
  // TODO: Remove this line after sending the first sample event to sentry.
  await Sentry.captureException(StateError('This is a sample exception.'));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Maniva Wallet',
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Splash(),
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

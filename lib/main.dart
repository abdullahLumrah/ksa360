import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/locale_controller.dart';
import 'data/push_notifications.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KsaGuideApp());
}

class KsaGuideApp extends StatefulWidget {
  const KsaGuideApp({super.key});

  @override
  State<KsaGuideApp> createState() => _KsaGuideAppState();
}

class _KsaGuideAppState extends State<KsaGuideApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocaleController.instance.addListener(_onLocale);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(PushNotifications.instance.start());
    });
  }

  @override
  void dispose() {
    LocaleController.instance.removeListener(_onLocale);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onLocale() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PushNotifications.instance.start());
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleController.instance.locale;
    return MaterialApp(
      title: 'KSA 360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(locale),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        // Never follow the device language. Saved/default locale only.
        return LocaleController.instance.locale;
      },
      scaffoldMessengerKey: PushNotifications.messengerKey,
      home: const SplashScreen(),
    );
  }
}

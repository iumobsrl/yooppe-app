import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'nav.dart';
import 'services/notifications.dart';
import 'state/app_state.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/landing.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Notifs.init();
  await app.load();
  Notifs.onOpen = Nav.openHref;

  // Esempio: collegare qui l'SDK di tracciamento (Adjust, Meta App Events…)
  // Tracking.sinks.add((event, payload) { ... });

  runApp(ChangeNotifierProvider<AppState>.value(value: app, child: const YooppeApp()));
}

class YooppeApp extends StatelessWidget {
  const YooppeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${Cfg.appName} – Chat e incontri',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorKey: navKey,
      scaffoldMessengerKey: messengerKey,
      navigatorObservers: [tracker, routeObserver],
      // Su tablet l'app resta larga come un telefono, come la web app (max 440px)
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: ColoredBox(
          color: const Color(0xFFE7E7F3),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      home: const RootGate(),
    );
  }
}

/// Landing se non registrato, altrimenti l'app con le schede.
class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    final reg = context.select<AppState, bool>((s) => s.reg);
    return reg ? const HomeShell() : const LandingScreen();
  }
}

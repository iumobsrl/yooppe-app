import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content.dart';
import '../../nav.dart';
import '../../services/notifications.dart';
import '../../state/app_state.dart';
import '../modals.dart';
import '../widgets/common.dart';
import 'chat_list.dart';
import 'me_screens.dart';
import 'notifications_screen.dart';
import 'radar.dart';

const _tabs = ['radar', 'chat', 'notifiche', 'me'];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with RouteAware {
  bool _flowBusy = false;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    app.onPushAsk = (reason, p) {
      final c = navKey.currentContext;
      if (c != null) showPushAsk(c, reason, p);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final h = Notifs.launchHref;
      if (h != null) {
        Notifs.launchHref = null;
        Nav.openHref(h);
      }
      _flow();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (!_subscribed && r != null) {
      routeObserver.subscribe(this, r);
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (app.onPushAsk != null) app.onPushAsk = null;
    super.dispose();
  }

  @override
  void didPopNext() => _flow();

  /// Sequenza della Radar (come AFTER.radar della web app):
  /// offerta di benvenuto → quiz → conferma email.
  Future<void> _flow() async {
    if (_flowBusy || !mounted) return;
    final s = app;
    if (!s.reg || s.tab != 'radar' || tracker.pages.length != 1 || tracker.popupOnTop) return;
    if (s.welcome == 'todo') {
      s.welcome = 'shown';
      s.save();
      _flowBusy = true;
      await Future.delayed(const Duration(milliseconds: 350));
      _flowBusy = false;
      return _flow();
    }
    if (s.welcome == 'shown') {
      _flowBusy = true;
      final yes = await showWelcomeModal(context);
      _flowBusy = false;
      s.welcomeAnswered();
      if (yes == true) {
        s.returnTo = 'radar';
        Nav.push('/checkout', kPkWelcome.id);
        return;
      }
      return _flow();
    }
    if (!s.quizDone) {
      _flowBusy = true;
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      await showQuiz(context);
      _flowBusy = false;
      return _flow();
    }
    if (s.askEmail && !s.verified) {
      _flowBusy = true;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await showEmailModal(context);
      _flowBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.select<AppState, String>((s) => s.tab);
    if (tab == 'radar') WidgetsBinding.instance.addPostFrameCallback((_) => _flow());
    final idx = _tabs.indexOf(tab);
    return Scaffold(
      body: Column(children: [
        TopNav(active: tab),
        Expanded(
          child: IndexedStack(index: idx < 0 ? 0 : idx, children: const [
            RadarTab(),
            ChatListView(),
            NotificationsTab(),
            MeTab(),
          ]),
        ),
      ]),
    );
  }
}

/// Pagine secondarie con il menu fisso in alto (Preferiti, Impostazioni…)
class NavScaffold extends StatelessWidget {
  final String active;
  final Widget child;
  const NavScaffold({super.key, required this.active, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [TopNav(active: active), Expanded(child: child)]),
      );
}

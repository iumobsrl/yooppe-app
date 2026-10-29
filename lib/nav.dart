import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/routes.dart';

final navKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();
final routeObserver = RouteObserver<ModalRoute<void>>();

/// Tiene traccia delle pagine aperte: serve al "motore" per sapere dove si trova l'utente
/// (es. niente notifiche dal vivo nel checkout, niente non-letti se la chat è aperta).
class RouteTracker extends NavigatorObserver {
  final List<Route<dynamic>> stack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => stack.add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => stack.remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => stack.remove(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : stack.indexOf(oldRoute);
    if (newRoute == null) return;
    if (i >= 0) {
      stack[i] = newRoute;
    } else {
      stack.add(newRoute);
    }
  }

  bool get popupOnTop => stack.isNotEmpty && stack.last is PopupRoute;

  List<Route<dynamic>> get pages => stack.where((r) => r is! PopupRoute).toList();

  Route<dynamic>? get topPage {
    final p = pages;
    return p.isEmpty ? null : p.last;
  }
}

final tracker = RouteTracker();

/// '' = landing, 'radar' | 'chat' | 'notifiche' | 'me' = schede, altrimenti nome pagina (crediti, checkout, ok, profilo…)
String currentLocation() {
  final n = tracker.topPage?.settings.name ?? '/';
  if (n == '/') return app.reg ? app.tab : '';
  return n.substring(1);
}

String? currentArg() {
  final a = tracker.topPage?.settings.arguments;
  return a is String ? a : null;
}

class Nav {
  static NavigatorState? get _n => navKey.currentState;

  static Future<void> push(String name, [String? arg]) async {
    final n = _n;
    if (n == null) return;
    final pages = tracker.pages;
    if (pages.length >= 2) {
      final prev = pages[pages.length - 2].settings;
      if (prev.name == name && prev.arguments == arg && !tracker.popupOnTop) {
        n.pop();
        return;
      }
    }
    await n.push(buildRoute(name, arg));
  }

  static void replace(String name, [String? arg]) {
    _n?.pushReplacement(buildRoute(name, arg));
  }

  static void popToRoot() => _n?.popUntil((r) => r.settings.name == '/' || r.isFirst);

  static void back() => _n?.maybePop();

  static void tab(String t) {
    popToRoot();
    app.setTab(t);
  }

  /// href nel formato della web app: /chat/c1, /profilo/c1, /notifiche, /crediti, /radar
  static void openHref(String href) {
    if (!app.reg) return;
    final parts = href.replaceFirst(RegExp(r'^[#./]+'), '').split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return;
    final name = parts[0];
    final arg = parts.length > 1 ? Uri.decodeComponent(parts[1]) : null;
    if (['radar', 'chat', 'notifiche', 'me'].contains(name) && arg == null) {
      tab(name);
      return;
    }
    popToRoot();
    if (name == 'chat' || name == 'profilo') {
      push('/$name', arg);
    } else if (name == 'crediti') {
      goRecharge();
    }
  }

  /// Apre il rate plan ricordando da dove si arriva (per il "TORNA ALLA CHAT").
  static void goRecharge() {
    final loc = currentLocation();
    final arg = currentArg();
    app.returnTo = arg == null ? loc : '$loc/$arg';
    app.save();
    push('/crediti');
  }

  /// Chiude rate plan, checkout ed esito pagamento tornando alla pagina di partenza.
  static void leavePayments() {
    _n?.popUntil((r) => !['/crediti', '/checkout', '/ok'].contains(r.settings.name) || r.isFirst);
  }
}

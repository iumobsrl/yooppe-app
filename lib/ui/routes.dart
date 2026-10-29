import 'package:flutter/material.dart';

import 'screens/chat_list.dart';
import 'screens/chat_screen.dart';
import 'screens/home_shell.dart';
import 'screens/me_screens.dart';
import 'screens/payments.dart';
import 'screens/profile_screen.dart';

/// Pagine dell'app (stessi nomi delle rotte della web app).
Route<dynamic> buildRoute(String name, String? arg) {
  Widget page;
  switch (name) {
    case '/profilo':
      page = ProfileScreen(id: arg ?? 't1');
    case '/chat':
      page = ChatScreen(id: arg ?? 't1');
    case '/preferiti':
      page = const NavScaffold(active: 'chat', child: ChatListView(favMode: true));
    case '/crediti':
      page = const CreditsScreen();
    case '/checkout':
      page = CheckoutScreen(pkId: arg ?? 's100');
    case '/ok':
      page = const OkScreen();
    case '/me-impostazioni':
      page = const SettingsScreen();
    case '/me-notifiche':
      page = const NotifPrefsScreen();
    case '/me-supporto':
      page = const SupportScreen();
    default:
      page = const Scaffold(body: Center(child: Text('Pagina non trovata')));
  }
  return MaterialPageRoute<void>(settings: RouteSettings(name: name, arguments: arg), builder: (_) => page);
}

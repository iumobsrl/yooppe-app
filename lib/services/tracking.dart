import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

typedef TrackSink = void Function(String event, Map<String, dynamic> payload);

/// Stessi eventi della web app. In app il Pixel non esiste: collega qui
/// l'SDK che usate (Adjust, Meta App Events, Firebase) aggiungendo un sink in main.dart:
///
///   Tracking.sinks.add((event, payload) {
///     final meta = Tracking.metaMap[event];
///     if (meta != null) { /* es. FacebookAppEvents().logEvent(name: meta, parameters: payload); */ }
///   });
class Tracking {
  static final List<TrackSink> sinks = [];
  static final Random _r = Random();

  /// Nomi evento Meta, come nella web app.
  static const Map<String, String> metaMap = {
    'landing_view': 'ViewContent',
    'registration': 'CompleteRegistration',
    'email_confirmed': 'Lead',
    'quiz_completed': 'QuizCompleted',
    'view_profile': 'ViewContent',
    'first_message': 'FirstMessage',
    'photo_unlock': 'PhotoUnlock',
    'view_rateplan': 'ViewRatePlan',
    'begin_checkout': 'InitiateCheckout',
    'purchase': 'Purchase',
  };

  /// Attribuzione (es. letta da deep link / install referrer): ad_id, ad_name, cid…
  static Map<String, String> attr = {};
  static String ab = 'A';

  static void track(String event, [Map<String, dynamic> data = const {}]) {
    final eventId = 'e${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${_r.nextInt(1 << 30).toRadixString(36)}';
    final payload = <String, dynamic>{
      'event': event,
      'event_id': eventId,
      ...data,
      'ab': ab,
      'ad_id': attr['v1'] ?? attr['ad_id'] ?? '',
      'ad_name': attr['v4'] ?? attr['ad_name'] ?? attr['utm_content'] ?? '',
      'cid': attr['cid'] ?? attr['clickid'] ?? '',
    };
    if (kDebugMode) debugPrint('[track] $event ${jsonEncode(payload)}');
    for (final s in sinks) {
      try {
        s(event, payload);
      } catch (_) {}
    }
  }
}

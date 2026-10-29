import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/profiles.dart';
import '../nav.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Messaggio breve in basso, con eventuale azione (es. "Ricarica").
void toast(String msg, {String? label, VoidCallback? onTap}) {
  final m = messengerKey.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontSize: 14)),
    duration: Duration(milliseconds: label != null ? 4200 : 2600),
    action: label != null && onTap != null ? SnackBarAction(label: label, textColor: const Color(0xFFFF8DC0), onPressed: onTap) : null,
  ));
}

OverlayEntry? _banner;

/// Notifica in alto stile smartphone: tocca per aprire, scorri verso l'alto per chiudere.
void showBanner(Profile p, String title, String text, String href) {
  final ov = navKey.currentState?.overlay;
  if (ov == null) return;
  _banner?.remove();
  late OverlayEntry e;
  void close() {
    if (_banner == e) _banner = null;
    if (e.mounted) e.remove();
  }

  e = OverlayEntry(builder: (ctx) => _BannerView(p: p, title: title, text: text, onTap: () {
        close();
        Nav.openHref(href);
      }, onClose: close));
  _banner = e;
  ov.insert(e);
  HapticFeedback.lightImpact();
  Future.delayed(const Duration(milliseconds: 5200), close);
}

class _BannerView extends StatefulWidget {
  final Profile p;
  final String title, text;
  final VoidCallback onTap, onClose;
  const _BannerView({required this.p, required this.title, required this.text, required this.onTap, required this.onClose});
  @override
  State<_BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<_BannerView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: top + 8,
      left: 10,
      right: 10,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -100) widget.onClose();
          },
          child: Material(
            color: Colors.white,
            elevation: 8,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Avatar(widget.p, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: K.ink)),
                    const SizedBox(height: 2),
                    Text(widget.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, color: K.ink2)),
                  ]),
                ),
                const SizedBox(width: 8),
                const Text('ora', style: TextStyle(fontSize: 12, color: K.muted)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Complimenti, hai ricevuto 40 crediti in regalo!"
void showGiftBanner() {
  final ov = navKey.currentState?.overlay;
  if (ov == null) return;
  late OverlayEntry e;
  e = OverlayEntry(builder: (ctx) {
    final top = MediaQuery.of(ctx).padding.top;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -1, end: 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (_, v, child) => FractionalTranslation(translation: Offset(0, v), child: child),
        child: Material(
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: K.peri, width: 3)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(children: [
              const CoinsIcon(size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Text.rich(TextSpan(
                  style: const TextStyle(fontSize: 16, color: Color(0xFF444444), height: 1.35),
                  children: [
                    const TextSpan(text: 'Complimenti, hai ricevuto\n'),
                    TextSpan(text: '${Cfg.giftCredits} crediti', style: const TextStyle(fontWeight: FontWeight.w700, color: K.indigo)),
                    const TextSpan(text: ' in regalo!'),
                  ],
                )),
              ),
            ]),
          ),
        ),
      ),
    );
  });
  ov.insert(e);
  Future.delayed(const Duration(milliseconds: 3800), () {
    if (e.mounted) e.remove();
  });
}

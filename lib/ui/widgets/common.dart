import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/profiles.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../theme.dart';

class Logo extends StatelessWidget {
  final double width;
  const Logo({super.key, this.width = 178});
  @override
  Widget build(BuildContext context) => Image.asset('assets/images/logo.png', width: width, fit: BoxFit.contain);
}

class Silhouette extends StatelessWidget {
  final double? iconSize;
  const Silhouette({super.key, this.iconSize});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final s = iconSize ?? (box.maxWidth.isFinite ? box.maxWidth * 0.75 : 60.0);
        return Container(
          color: const Color(0xFFE9E9EC),
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.hardEdge,
          child: Transform.translate(
            offset: Offset(0, s * 0.12),
            child: Icon(Icons.person, size: s, color: const Color(0xFFD3D3D8)),
          ),
        );
      });
}

class NetImg extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Alignment alignment;
  const NetImg(this.url, {super.key, this.fit = BoxFit.cover, this.alignment = const Alignment(0, -0.45)});
  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        alignment: alignment,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => Container(color: K.placeholder),
        errorWidget: (_, __, ___) => const Silhouette(),
      );
}

/// Foto del profilo (o sagoma se non ha foto).
class PPic extends StatelessWidget {
  final Profile p;
  final int v;
  final Alignment alignment;
  const PPic(this.p, {super.key, this.v = 0, this.alignment = const Alignment(0, -0.45)});
  @override
  Widget build(BuildContext context) {
    final u = p.photo(v);
    return u == null ? const Silhouette() : NetImg(u, alignment: alignment);
  }
}

class Avatar extends StatelessWidget {
  final Profile p;
  final double size;
  final double? radius;
  const Avatar(this.p, {super.key, this.size = 46, this.radius});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size / 2),
        child: SizedBox(width: size, height: size, child: PPic(p)),
      );
}

final Map<int, Uint8List> _b64Cache = {};
Uint8List b64Bytes(String b64) => _b64Cache.putIfAbsent(b64.hashCode, () => base64Decode(b64));

class B64Img extends StatelessWidget {
  final String b64;
  final BoxFit fit;
  const B64Img(this.b64, {super.key, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) =>
      Image.memory(b64Bytes(b64), fit: fit, width: double.infinity, height: double.infinity, gaplessPlayback: true);
}

class OnlineDot extends StatelessWidget {
  final double size;
  const OnlineDot({super.key, this.size = 8});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 5),
        decoration: const BoxDecoration(color: K.online, shape: BoxShape.circle),
      );
}

class CoinsIcon extends StatelessWidget {
  final double size;
  const CoinsIcon({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          Positioned(left: 0, top: 0, child: Icon(Icons.circle, size: size * 0.78, color: const Color(0xFFF2B544))),
          Positioned(right: 0, bottom: 0, child: Icon(Icons.circle, size: size * 0.7, color: const Color(0xFFFFD36B))),
          Positioned(
            right: size * 0.16,
            bottom: size * 0.12,
            child: Text('€', style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w800, color: const Color(0xFFB9831A))),
          ),
        ]),
      );
}

/// Pulsante pieno (verde, indigo, rosa…)
class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color fg;
  final double height;
  final double radius;
  final double fontSize;
  final Widget? icon;
  final bool outline;
  const Btn(this.label, {super.key, this.onTap, this.color = K.green, this.fg = Colors.white, this.height = 56, this.radius = 8, this.fontSize = 18, this.icon, this.outline = false});

  @override
  Widget build(BuildContext context) {
    final txt = Text(label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: outline ? color : fg, letterSpacing: .2));
    final child = icon == null ? txt : Row(mainAxisSize: MainAxisSize.min, children: [icon!, const SizedBox(width: 8), Flexible(child: txt)]);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: outline ? Colors.white : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: outline ? BorderSide(color: color, width: 1.5) : BorderSide.none,
        ),
        elevation: outline ? 0 : 2,
        shadowColor: color.withAlpha(90),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: child))),
      ),
    );
  }
}

class LinkText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final FontWeight weight;
  const LinkText(this.text, {super.key, required this.onTap, this.color = K.navy, this.size = 16, this.weight = FontWeight.w500});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: size, fontWeight: weight, decoration: TextDecoration.underline, decorationColor: color)),
        ),
      );
}

/// Menu fisso in alto (Radar · Chat · Notifiche · Profilo · Crediti)
class TopNav extends StatelessWidget {
  final String active;
  const TopNav({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final un = s.totalUnread;
    Widget b(String k, IconData icon, String label, {Widget? extra}) {
      final on = active == k;
      return Semantics(
        label: label,
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => Nav.tab(k),
          child: Container(
            width: 46,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: on ? Colors.white.withAlpha(230) : Colors.transparent, width: 1.5),
            ),
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Icon(icon, color: Colors.white, size: 25),
              if (extra != null) extra,
            ]),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Container(
      color: K.indigo,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            b('radar', Icons.search, 'Radar'),
            b('chat', Icons.mail_outline, 'Chat',
                extra: un > 0
                    ? Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(color: K.red, borderRadius: BorderRadius.circular(9), border: Border.all(color: K.indigo, width: 1.5)),
                          alignment: Alignment.center,
                          child: Text('$un', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ))
                    : null),
            b('notifiche', Icons.favorite_border, 'Notifiche',
                extra: s.unseenNotif
                    ? Positioned(
                        top: 4,
                        right: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: K.red, shape: BoxShape.circle, border: Border.all(color: K.indigo, width: 1.5)),
                        ))
                    : null),
            b('me', Icons.person, 'Profilo'),
            Semantics(
              label: 'Crediti: ${s.credits}',
              button: true,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: Nav.goRecharge,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.fromLTRB(7, 0, 10, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active == 'crediti' ? K.peri : Colors.transparent, width: 1.5),
                    ),
                    child: Row(children: [
                      const CoinsIcon(size: 20),
                      const SizedBox(width: 6),
                      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('CREDITI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: K.indigo, height: 1)),
                        const SizedBox(height: 2),
                        Text('${s.credits}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: K.berry, height: 1)),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ),
    );
  }
}

class PendingBar extends StatelessWidget {
  const PendingBar({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.pendingCount == 0) return const SizedBox.shrink();
    return InkWell(
      onTap: Nav.goRecharge,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: K.red, width: 1.5), right: BorderSide(color: K.red, width: 1.5), bottom: BorderSide(color: K.red, width: 1.5)),
        ),
        child: const Text('HAI DEI MESSAGGI NON INVIATI!', textAlign: TextAlign.center, style: TextStyle(color: K.red, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

/// Intestazione delle sottopagine (Messaggi, Preferiti, Impostazioni…)
class SubHead extends StatelessWidget {
  final String? backLabel;
  final VoidCallback? onBack;
  final Widget title;
  final Widget? trailing;
  const SubHead({super.key, this.backLabel, this.onBack, required this.title, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(onBack != null ? 12 : 26, 12, 14, 12),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2))]),
        child: Row(children: [
          if (onBack != null)
            InkWell(
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  const Icon(Icons.chevron_left, color: Color(0xFF555555)),
                  Text((backLabel ?? '').toUpperCase(), style: const TextStyle(color: K.navy, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          if (onBack != null) const SizedBox(width: 18),
          Expanded(child: title),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Conto alla rovescia che si aggiorna ogni secondo.
class Countdown extends StatefulWidget {
  final int until;
  final TextStyle? style;
  final Widget Function(String text)? builder;
  final VoidCallback? onEnd;
  const Countdown(this.until, {super.key, this.style, this.builder, this.onEnd});
  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (widget.until - nowMs() <= 0) {
        _t?.cancel();
        widget.onEnd?.call();
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = widget.until - nowMs();
    final txt = ms > 0 ? fmtCd(ms) : 'scaduta';
    return widget.builder != null ? widget.builder!(txt) : Text(txt, style: widget.style);
  }
}

class TrustRow extends StatelessWidget {
  const TrustRow({super.key});
  @override
  Widget build(BuildContext context) => const Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 6,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock, color: Color(0xFF5CA92C), size: 18),
            SizedBox(width: 4),
            Text('Secure\ncheckout', style: TextStyle(fontSize: 9, height: 1.1, color: K.muted)),
          ]),
          Text('VISA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1A1F71))),
          Text('mastercard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEB001B))),
          Text('App Store · Google Play', style: TextStyle(fontSize: 10, color: K.muted)),
        ],
      );
}

class EmptyState extends StatelessWidget {
  final String? title;
  final String text;
  final Widget? action;
  const EmptyState({super.key, this.title, required this.text, this.action});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
        child: Column(children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title!, textAlign: TextAlign.center, style: const TextStyle(color: K.navy, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: K.muted, fontSize: 15, height: 1.5)),
          if (action != null) Padding(padding: const EdgeInsets.only(top: 18), child: action!),
        ]),
      );
}

class OutlinePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const OutlinePill(this.label, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: K.indigo,
          side: const BorderSide(color: K.indigo, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        child: Text(label),
      );
}

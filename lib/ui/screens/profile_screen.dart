import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/profiles.dart';
import '../../nav.dart';
import '../../services/tracking.dart';
import '../../state/app_state.dart';
import '../modals.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  final String id;
  const ProfileScreen({super.key, required this.id});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Tracking.track('view_profile', {'to': widget.id});
  }

  Widget _circle(IconData ic, Color c, VoidCallback onTap, String tip) => Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Tooltip(message: tip, child: SizedBox(width: 42, height: 42, child: Icon(ic, color: c, size: 24))),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = profileOf(widget.id);
    final fav = s.favs[p.id] == true;
    final liked = s.likes[p.id] == true;
    final w = MediaQuery.of(context).size;
    final heroH = min(min(w.width * 1.07, 470.0), w.height * .64);
    final ph = p.photo();

    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 17, color: Color(0xFF888888)), children: [
            TextSpan(text: '$k  ', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7A7A7A))),
            TextSpan(text: v),
          ])),
        );
    Widget h2(String t) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(t, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        );

    return Scaffold(
      body: Stack(children: [
        CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: heroH,
            collapsedHeight: 64,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: false,
            leadingWidth: 60,
            leading: _circle(Icons.arrow_back_ios_new, const Color(0xFF111111), Nav.back, 'Indietro'),
            actions: [_circle(fav ? Icons.star : Icons.star_border, K.pink, () => s.toggleFav(p.id), 'Preferiti'), const SizedBox(width: 8)],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(fit: StackFit.expand, children: [
                GestureDetector(onTap: ph != null ? () => showGallery(context, p.id, 0) : null, child: PPic(p, alignment: const Alignment(0, -0.56))),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x66000000)]),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 104,
                  bottom: 22,
                  child: Text('${p.u}, ${p.age} anni,\n${p.reg}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20, height: 1.25, shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
                ),
                if (ph != null)
                  Positioned(
                    right: 24,
                    bottom: 16,
                    child: Material(
                      color: K.red,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => showGallery(context, p.id, 0),
                        child: SizedBox(
                          width: 66,
                          height: 66,
                          child: Stack(alignment: Alignment.center, children: [
                            const Icon(Icons.photo_camera, color: Colors.white, size: 28),
                            if (p.priv.isNotEmpty)
                              Positioned(
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.lock, size: 10, color: K.red),
                                    Text('${p.priv.length}', style: const TextStyle(color: K.red, fontSize: 11, fontWeight: FontWeight.w800)),
                                  ]),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(34, 18, 34, 140),
            sliver: SliverList.list(children: [
              h2('Chi sono'),
              Text(p.bio, style: const TextStyle(fontSize: 16, height: 1.4, color: K.ink)),
              const SizedBox(height: 10),
              h2('Caratteristiche'),
              kv('Relazione:', p.d['rel']!),
              kv('Altezza:', p.d['alt']!),
              kv('Peso:', p.d['peso']!),
              kv('Carattere:', p.d['car']!),
              h2('Su di me'),
              kv('Corporatura:', p.d['corp']!),
              kv('Titolo di studio:', p.d['stud']!),
              kv('Segno zodiacale', p.d['zod']!),
              kv('Bevitore', p.d['bev']!),
              kv('Fumatore', p.d['fum']!),
              kv('Situazione sentimentale', p.d['sit']!),
            ]),
          ),
        ]),
        // Barra azioni in basso
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, -3))]),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                child: IntrinsicHeight(
                  child: Row(children: [
                    _Act('Messaggio', Icons.send, K.green, () => Nav.push('/chat', p.id)),
                    const VerticalDivider(width: 1.5, thickness: 1.5, color: Color(0xFFD8D8D8)),
                    _Act('Proposta', Icons.mail, K.navy, () => showProposals(context, p.id)),
                    const VerticalDivider(width: 1.5, thickness: 1.5, color: Color(0xFFD8D8D8)),
                    _Act(liked ? 'Ti piace' : 'Mi piace', Icons.favorite, liked ? K.berryD : K.pink, () => s.toggleLike(p.id)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Act extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Act(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 62, height: 62, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 30)),
            const SizedBox(height: 8),
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 13, color: Color(0xFF555555), fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

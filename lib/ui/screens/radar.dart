import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../data/profiles.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../modals.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RadarTab extends StatelessWidget {
  const RadarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final f = s.filters;
    final list = radarList(f);
    final online = onlineStrip(f);
    final showVerify = s.reg && !s.verified && s.welcome == 'done' && !s.askEmail;
    return Column(children: [
      if (showVerify)
        Container(
          color: K.lav,
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          child: Row(children: [
            Expanded(
              child: Text.rich(TextSpan(style: const TextStyle(color: K.indigo, fontSize: 13), children: [
                const TextSpan(text: 'Conferma la tua email e ricevi '),
                TextSpan(text: '${Cfg.giftCredits} crediti', style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' in regalo'),
              ])),
            ),
            TextButton(
              onPressed: () {
                s.askEmail = true;
                s.save();
                showEmailModal(context);
              },
              child: const Text('Conferma', style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline, color: K.indigo)),
            ),
          ]),
        ),
      // Filtri
      Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: K.indigo, width: 1.5))),
        padding: const EdgeInsets.fromLTRB(22, 4, 12, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            const Icon(Icons.search, color: K.muted, size: 22),
            const SizedBox(width: 12),
            for (final (i, label) in [f.g, f.age, f.reg, 'Foto: ${f.foto == 'Sì' ? 'Sì' : 'Tutte'}'].indexed)
              InkWell(
                onTap: () => showFiltersSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: i == 0 ? Colors.transparent : const Color(0xFFCFCFE6), width: 1.5))),
                  child: Text(label, style: const TextStyle(fontSize: 16, color: K.navy, decoration: TextDecoration.underline, decorationColor: K.navy)),
                ),
              ),
          ]),
        ),
      ),
      Expanded(
        child: LayoutBuilder(builder: (context, box) {
          final cardW = (box.maxWidth - 14 * 2 - 18) / 2;
          final cardH = cardW * 2 / 3 + 34 + 54;
          return CustomScrollView(
            key: const PageStorageKey('radar'),
            slivers: [
              if (online.isNotEmpty) SliverToBoxAdapter(child: _OnlineStrip(online)),
              if (list.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 26),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 18, mainAxisExtent: cardH),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ProfileCard(list[i]),
                  ),
                ),
              if (list.length < 6)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: list.isEmpty ? 'Nessun profilo con questi filtri' : null,
                    text: f.g == 'Uomini' ? 'Al momento sono attivi solo profili femminili.' : 'Allarga la ricerca per vedere più persone.',
                    action: OutlinePill('Mostra tutta Italia', onTap: s.widen),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 8)),
            ],
          );
        }),
      ),
    ]);
  }
}

class _OnlineStrip extends StatelessWidget {
  final List<Profile> list;
  const _OnlineStrip(this.list);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const OnlineDot(),
              const Text('Online adesso ', style: TextStyle(fontWeight: FontWeight.w700, color: K.navy, fontSize: 14)),
              Text('${list.length}', style: const TextStyle(color: K.muted, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = list[i];
                return InkWell(
                  onTap: () => Nav.push('/profilo', p.id),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [K.pink, K.peri])),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: Avatar(p, size: 54),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 66,
                      child: Text(p.shortName, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: K.ink2)),
                    ),
                  ]),
                );
              },
            ),
          ),
        ]),
      );
}

class _ProfileCard extends StatelessWidget {
  final Profile p;
  const _ProfileCard(this.p);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final liked = s.likes[p.id] == true;
    void open() => Nav.push('/profilo', p.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: K.shadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        AspectRatio(
          aspectRatio: 3 / 2,
          child: GestureDetector(
            onTap: open,
            child: Stack(fit: StackFit.expand, children: [
              PPic(p, alignment: const Alignment(0, -0.48)),
              if (p.priv.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock, size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text('${p.priv.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: Container(
            color: K.card,
            child: Column(children: [
              InkWell(
                onTap: open,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (p.on) const OnlineDot(),
                    Flexible(
                      child: Text('${p.u}, ${p.age} anni',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, color: Color(0xFF555555))),
                    ),
                  ]),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                child: Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: K.green,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        onPressed: () => Nav.push('/chat', p.id),
                        icon: const Icon(Icons.mail, size: 19),
                        label: const Text('CHATTA'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _LikeButton(liked: liked, onTap: () => s.toggleLike(p.id)),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _LikeButton extends StatefulWidget {
  final bool liked;
  final VoidCallback onTap;
  const _LikeButton({required this.liked, required this.onTap});
  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  double scale = 1;
  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 140),
        child: Material(
          color: widget.liked ? K.berryD : K.berry,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              widget.onTap();
              setState(() => scale = 1.25);
              Future.delayed(const Duration(milliseconds: 160), () {
                if (mounted) setState(() => scale = 1);
              });
            },
            child: const SizedBox(width: 40, height: 40, child: Icon(Icons.favorite, color: Colors.white, size: 20)),
          ),
        ),
      );
}

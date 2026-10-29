import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/profiles.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final vis = [...s.visitors]..sort((a, b) => b.t - a.t);
    final lik = [...s.likers]..sort((a, b) => b.t - a.t);

    void openProfile(String id) {
      s.markNotifSeen();
      Nav.push('/profilo', id);
    }

    Widget h2(IconData? ic, String t, {double top = 0}) => Padding(
          padding: EdgeInsets.fromLTRB(20, top, 20, 12),
          child: Row(children: [
            if (ic != null) ...[Icon(ic, color: K.navy, size: 22), const SizedBox(width: 8)],
            Text(t, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: K.navy)),
          ]),
        );

    Widget newTag() => Positioned(
          top: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: K.red, borderRadius: BorderRadius.circular(4)),
            child: const Text('NUOVO', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
          ),
        );

    return ListView(padding: EdgeInsets.fromLTRB(0, 22, 0, 30 + MediaQuery.of(context).padding.bottom), children: [
      h2(Icons.visibility, 'Chi ti ha visitato'),
      if (vis.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), child: Text('Nessuna visita per ora.', style: TextStyle(color: K.muted)))
      else
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: vis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = profileOf(vis[i].id);
              return InkWell(
                onTap: () => openProfile(p.id),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: vis[i].seen ? Colors.transparent : K.red, width: 2),
                  ),
                  child: Stack(children: [
                    Avatar(p, size: 88, radius: 8),
                    if (!vis[i].seen) newTag(),
                  ]),
                ),
              );
            },
          ),
        ),
      h2(Icons.favorite, 'A chi piaci', top: 28),
      if (lik.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), child: Text('Ancora nessun mi piace.', style: TextStyle(color: K.muted)))
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: .78),
          itemCount: lik.length,
          itemBuilder: (_, i) {
            final p = profileOf(lik[i].id);
            return InkWell(
              onTap: () => openProfile(p.id),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: lik[i].seen ? Colors.transparent : K.red, width: 2),
                  boxShadow: const [BoxShadow(color: K.shadow, blurRadius: 6, offset: Offset(0, 2))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  Expanded(child: Stack(fit: StackFit.expand, children: [PPic(p), if (!lik[i].seen) newTag()])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (p.on) const OnlineDot(size: 7),
                      Flexible(child: Text('${p.u}, ${p.age}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: K.ink2))),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      h2(null, '🔔 Attività recenti', top: 30),
      if (s.pushGranted != true) const _PushCard(),
      if (s.feed.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Text('Qui trovi tutte le notifiche: messaggi, visite, mi piace e foto private.', style: TextStyle(color: K.muted, height: 1.5)),
        )
      else
        for (final f in s.feed.take(40))
          if (profileById(f.pid) != null)
            InkWell(
              onTap: () {
                s.markNotifSeen();
                Nav.openHref(f.href);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(children: [
                  Avatar(profileOf(f.pid), size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(f.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: K.muted, fontSize: 13)),
                    ]),
                  ),
                  Text(ago(f.t), style: const TextStyle(color: K.muted, fontSize: 12)),
                ]),
              ),
            ),
    ]);
  }
}

class _PushCard extends StatelessWidget {
  const _PushCard();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: K.lav, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Text('🔔', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Attiva le notifiche per sapere subito quando qualcuno ti scrive.', style: TextStyle(color: K.indigo, fontSize: 13.5, height: 1.4)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: K.green),
            onPressed: () => app.enablePush(),
            child: const Text('Attiva'),
          ),
        ]),
      );
}

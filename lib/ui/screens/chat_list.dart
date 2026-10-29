import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content.dart';
import '../../data/profiles.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ChatListView extends StatelessWidget {
  final bool favMode;
  const ChatListView({super.key, this.favMode = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    var ids = s.convs.keys.where((id) => s.convs[id]!.msgs.isNotEmpty).toList();
    if (favMode) ids = s.favs.keys.where((id) => s.favs[id] == true).toList();
    ids.sort((a, b) => (s.convs[b]?.t ?? 0) - (s.convs[a]?.t ?? 0));
    ids = ids.where((id) => profileById(id) != null).toList();

    final head = favMode
        ? SubHead(
            backLabel: 'Messaggi',
            onBack: () => Nav.tab('chat'),
            title: const Row(children: [
              Icon(Icons.star_border, color: K.pink, size: 22),
              SizedBox(width: 8),
              Text('PREFERITI', style: TextStyle(color: K.navy, fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          )
        : SubHead(
            title: const Text('MESSAGGI', style: TextStyle(fontSize: 21, color: K.navy, fontWeight: FontWeight.w500)),
            trailing: OutlinedButton.icon(
              onPressed: () => Nav.push('/preferiti'),
              style: OutlinedButton.styleFrom(
                foregroundColor: K.pink,
                side: const BorderSide(color: K.navy, width: 1.5),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.star_border, size: 22),
              label: const Text('PREFERITI'),
            ),
          );

    Widget body;
    if (ids.isEmpty) {
      body = favMode
          ? const EmptyState(title: 'Nessun preferito', text: 'Tocca la stellina in una chat o in un profilo per ritrovarlo qui.')
          : EmptyState(
              title: 'Nessuna conversazione',
              text: 'Scegli un profilo nella Radar e scrivi il primo messaggio.',
              action: OutlinePill('Vai alla Radar', onTap: () => Nav.tab('radar')),
            );
    } else {
      body = ListView.separated(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
        itemCount: ids.length,
        separatorBuilder: (_, __) => const Divider(height: 1.5, thickness: 1.5, color: Color(0xFFE5E5EA)),
        itemBuilder: (_, i) => _Row(ids[i]),
      );
    }

    return Column(children: [
      const PendingBar(),
      head,
      Expanded(child: body),
    ]);
  }
}

class _Row extends StatelessWidget {
  final String id;
  const _Row(this.id);
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = profileOf(id);
    final c = s.convs[id] ?? Conv();
    final last = c.msgs.isEmpty ? null : c.msgs.last;
    var prev = 'Inizia la conversazione';
    if (last != null) {
      final who = last.f == 'me' ? 'Tu: ' : '';
      final body = switch (last.k) {
        'gift' => '🎁 ${kGifts[last.g ?? 0].n}',
        'photo' => '📷 Foto',
        'priv' => '🔒 Ti ha inviato una foto privata',
        'pcom' => '📷 ${last.x ?? ''}',
        _ => last.x ?? '',
      };
      prev = last.s == 'pending' ? 'Messaggio non inviato' : '$who$body';
    }
    return InkWell(
      onTap: () => Nav.push('/chat', id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))]),
            child: Avatar(p, size: 86, radius: 10),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(p.u, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, color: Color(0xFF333333)))),
                  if (last != null)
                    Text(sameDay(last.t, nowMs()) ? fmtTime(last.t) : fmtDate(last.t).substring(0, 5), style: const TextStyle(fontSize: 14, color: K.muted)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Text(prev,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: c.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                          color: last?.s == 'pending' ? K.red : (c.unread > 0 ? const Color(0xFF111111) : const Color(0xFF666666)),
                        )),
                  ),
                  if (c.unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: K.pink, borderRadius: BorderRadius.circular(11)),
                      alignment: Alignment.center,
                      child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

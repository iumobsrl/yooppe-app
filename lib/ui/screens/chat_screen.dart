import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/content.dart';
import '../../data/profiles.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../bridge.dart';
import '../modals.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  final String id;
  const ChatScreen({super.key, required this.id});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with RouteAware {
  final ctl = TextEditingController();
  final focus = FocusNode();
  bool _subscribed = false;

  String get id => widget.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onShow());
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
  void didPopNext() => _onShow();

  void _onShow() {
    if (!mounted) return;
    app.markChatRead(id);
    if (app.recovery && app.pendingCount > 0) {
      app.recovery = false;
      app.save();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) showRecoveryModal(context);
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    ctl.dispose();
    focus.dispose();
    super.dispose();
  }

  void _send() {
    final x = ctl.text.trim();
    if (x.isEmpty) {
      focus.requestFocus();
      return;
    }
    if (!app.canWrite) {
      Nav.goRecharge();
      return;
    }
    ctl.clear();
    app.pushMine(id, Msg(id: '', f: 'me', k: 'text', x: x, t: 0));
  }

  Future<void> _photo() async {
    if (!app.canWrite) {
      Nav.goRecharge();
      return;
    }
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 640, maxHeight: 640, imageQuality: 80);
      if (img == null) return;
      final bytes = await img.readAsBytes();
      app.pushMine(id, Msg(id: '', f: 'me', k: 'photo', x: '', imgB64: base64Encode(bytes), t: 0));
    } catch (_) {
      toast('Non riesco a leggere questa immagine. Prova con un JPG o PNG.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = profileOf(id);
    final c = s.convs[id] ?? Conv();
    final fav = s.favs[id] == true;
    final typing = s.typing.contains(id);
    if (c.unread > 0) WidgetsBinding.instance.addPostFrameCallback((_) => app.markChatRead(id));

    // Elementi della conversazione in ordine cronologico
    final items = <Widget>[];
    if (s.visitors.any((v) => v.id == id)) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.visibility, size: 22, color: K.ink),
          SizedBox(width: 6),
          Text('ha visitato il tuo profilo', style: TextStyle(fontSize: 16, color: K.ink)),
        ]),
      ));
    }
    if (c.msgs.isEmpty) {
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(40, 30, 40, 0),
        child: Column(children: [
          Text.rich(
            TextSpan(style: const TextStyle(color: K.muted, fontSize: 14, height: 1.5), children: [
              const TextSpan(text: 'Scrivi il primo messaggio a '),
              TextSpan(text: p.u, style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '.'),
            ]),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => showProposals(context, id),
            child: const Text('Usa una proposta speciale', style: TextStyle(color: K.indigo, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
        ]),
      ));
    }
    String? prevF;
    int prevT = 0;
    for (final m in c.msgs) {
      if (prevT > 0 && !sameDay(prevT, m.t)) {
        items.add(Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFF4F4F6), borderRadius: BorderRadius.circular(10)),
            child: Text(fmtDate(m.t), style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          ),
        ));
      }
      items.add(_Bubble(m: m, p: p, showAv: prevF != 'her'));
      prevF = m.f;
      prevT = m.t;
    }
    if (typing) items.add(_Typing(p: p, showAv: prevF != 'her'));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // Intestazione
        Container(
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))]),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 74,
              child: Row(children: [
                IconButton(onPressed: Nav.back, icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: Color(0xFF111111)), tooltip: 'Indietro'),
                Expanded(
                  child: InkWell(
                    onTap: () => Nav.push('/profilo', id),
                    child: Row(children: [
                      Avatar(p, size: 46),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.u, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                          Text(
                            typing ? 'sta scrivendo…' : (p.on ? 'disponibile' : 'non in linea'),
                            style: TextStyle(fontSize: 14, color: typing ? K.green : K.muted, fontStyle: typing ? FontStyle.italic : FontStyle.normal),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
                Container(
                  width: 72,
                  height: 50,
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF333333), width: 1.5))),
                  child: IconButton(
                    onPressed: () => s.toggleFav(id),
                    icon: Icon(fav ? Icons.star : Icons.star_border, color: K.pink, size: 38),
                    tooltip: 'Preferiti',
                  ),
                ),
              ]),
            ),
          ),
        ),
        // Messaggi
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
              children: [
                for (final w in items.reversed) Padding(padding: const EdgeInsets.only(top: 14), child: w),
              ],
            ),
          ),
        ),
        // Composer
        Container(
          color: K.bubbleHer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                height: 52,
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1))]),
                child: Row(children: [
                  IconButton(onPressed: () => showGifts(context, id), icon: const Icon(Icons.card_giftcard, color: K.berryD, size: 28), tooltip: 'Regali'),
                  IconButton(onPressed: _photo, icon: const Icon(Icons.photo_camera, color: K.navy, size: 28), tooltip: 'Invia una foto'),
                  if (!s.canWrite)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: K.wine, shape: const StadiumBorder(), padding: EdgeInsets.zero),
                          onPressed: Nav.goRecharge,
                          child: const Text('RICARICA CREDITI', style: TextStyle(fontSize: 15, letterSpacing: .3)),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: TextField(
                        controller: ctl,
                        focusNode: focus,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(fontSize: 16.5),
                        decoration: const InputDecoration(
                          hintText: 'Scrivi un messaggio',
                          counterText: '',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                    Material(
                      color: K.wine,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _send,
                        child: const SizedBox(width: 44, height: 44, child: Icon(Icons.send, color: Colors.white, size: 22)),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Stamp extends StatelessWidget {
  final Msg m;
  final bool mine;
  const _Stamp(this.m, this.mine);
  @override
  Widget build(BuildContext context) {
    final color = mine ? const Color(0xFFE3E4FF) : const Color(0xFF555555);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: mine ? const Color(0x40FFFFFF) : const Color(0x1A000000)))),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
        Text.rich(TextSpan(style: TextStyle(fontSize: 11.5, color: color), children: [
          TextSpan(text: '${fmtDate(m.t)}-'),
          TextSpan(text: fmtTime(m.t), style: TextStyle(fontWeight: mine ? FontWeight.w700 : FontWeight.w400)),
        ])),
        if (mine && m.s != 'pending') ...[
          const SizedBox(width: 5),
          Icon(Icons.done_all, size: 16, color: m.s == 'read' ? const Color(0xFF8DF0FF) : const Color(0xFFA9AAD6)),
        ],
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Msg m;
  final Profile p;
  final bool showAv;
  const _Bubble({required this.m, required this.p, required this.showAv});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final mine = m.f == 'me';
    final pend = m.s == 'pending';
    final maxW = MediaQuery.of(context).size.width * .78;
    final txtStyle = TextStyle(fontSize: 16, height: 1.4, color: mine ? Colors.white : K.ink);

    Widget img(Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 224, height: 262, child: child)),
        );

    final content = <Widget>[];
    switch (m.k) {
      case 'gift':
        final g = kGifts[m.g ?? 0];
        content.add(Center(child: Text(g.e, style: const TextStyle(fontSize: 56))));
        content.add(Text('${mine ? 'Hai inviato' : 'Ti ha inviato'}: ${g.n}', textAlign: TextAlign.center, style: txtStyle.copyWith(fontSize: 14)));
      case 'priv':
        final pp = profileOf(m.imgP ?? p.id);
        final v = m.imgV ?? 0;
        content.add(img(s.isLocked(pp, v)
            ? LockedPhoto(p: pp, v: v, compact: true)
            : GestureDetector(onTap: () => showGallery(context, pp.id, v), child: PPic(pp, v: v))));
        if ((m.x ?? '').isNotEmpty) content.add(Text(m.x!, style: txtStyle));
      case 'photo':
      case 'pcom':
        if (m.imgB64 != null) {
          content.add(img(B64Img(m.imgB64!)));
        } else if (m.imgP != null) {
          content.add(img(PPic(profileOf(m.imgP!), v: m.imgV ?? 0)));
        }
        if ((m.x ?? '').isNotEmpty) content.add(Text(m.x!, style: txtStyle));
      default:
        content.add(Text(m.x ?? '', style: txtStyle));
    }
    content.add(Align(alignment: Alignment.centerRight, child: _Stamp(m, mine)));

    final bubble = Container(
      constraints: BoxConstraints(minWidth: mine ? 120 : 180, maxWidth: maxW - (mine ? 0 : 42)),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: pend ? K.pendBg : (mine ? K.indigo : K.bubbleHer),
        borderRadius: BorderRadius.circular(8),
        border: pend ? Border.all(color: K.red, width: 2) : null,
        boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: content),
    );

    if (mine) {
      return Align(
        alignment: Alignment.centerRight,
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          bubble,
          if (pend)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('MESSAGGIO NON INVIATO', style: TextStyle(color: K.red, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ]),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Opacity(opacity: showAv ? 1 : 0, child: Avatar(p, size: 32)),
        ),
        const SizedBox(width: 10),
        Flexible(child: bubble),
      ]),
    );
  }
}

class _Typing extends StatefulWidget {
  final Profile p;
  final bool showAv;
  const _Typing({required this.p, required this.showAv});
  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Opacity(opacity: widget.showAv ? 1 : 0, child: Avatar(widget.p, size: 32)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: K.bubbleHer, borderRadius: BorderRadius.circular(8)),
            child: AnimatedBuilder(
              animation: c,
              builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(const Color(0xFF999999), const Color(0x40999999), ((c.value + i * .15) % 1 - .5).abs() * 2),
                    ),
                  ),
              ]),
            ),
          ),
        ]),
      );
}

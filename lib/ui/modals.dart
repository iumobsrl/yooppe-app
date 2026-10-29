import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../data/content.dart';
import '../data/profiles.dart';
import '../nav.dart';
import '../services/tracking.dart';
import '../state/app_state.dart';
import '../state/models.dart';
import 'bridge.dart';
import 'theme.dart';
import 'widgets/common.dart';

// ======================================================================
// Struttura comune
// ======================================================================

class ModalCard extends StatelessWidget {
  final String? header;
  final Color headerColor;
  final VoidCallback? onClose;
  final Widget child;
  final EdgeInsets padding;
  const ModalCard({super.key, this.header, this.headerColor = K.peri, this.onClose, required this.child, this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 24)});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (header != null)
            Container(
              width: double.infinity,
              color: headerColor,
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(50, 20, 50, 20),
                  child: Center(
                    child: Text(header!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22, height: 1.25)),
                  ),
                ),
                if (onClose != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white), tooltip: 'Chiudi'),
                  ),
              ]),
            ),
          Flexible(child: SingleChildScrollView(padding: padding, child: child)),
        ]),
      ),
    );
  }
}

Widget _noThanks(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LinkText(label, onTap: onTap, size: 17),
    );

const _txt = TextStyle(fontSize: 16.5, color: Color(0xFF555555), height: 1.5);

// ======================================================================
// Benvenuto, quiz, email
// ======================================================================

/// true = "OTTIENI PROMO ORA", false = "No grazie"
Future<bool?> showWelcomeModal(BuildContext context) {
  const k = kPkWelcome;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: ModalCard(
        header: 'REGALO BONUS\nNUOVO CLIENTE!',
        onClose: () => Navigator.pop(ctx, false),
        child: Column(children: [
          const Text('-60%', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: K.navy, height: 1)),
          const SizedBox(height: 6),
          const Text('DI SCONTO SUL\nPACCHETTO CREDITI', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 18),
          const Text("Ottieni un Supersconto bonus di benvenuto sull'acquisto dei pacchetti crediti", textAlign: TextAlign.center, style: _txt),
          const SizedBox(height: 22),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.center, spacing: 6, children: [
            Text('${k.cr}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const Text('CREDITI +', style: TextStyle(fontSize: 21)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: K.pink, borderRadius: BorderRadius.circular(8)),
              child: Text('${k.b} GRATIS', style: const TextStyle(color: Colors.white, fontSize: 19)),
            ),
          ]),
          const SizedBox(height: 4),
          Text.rich(TextSpan(style: const TextStyle(fontSize: 18, color: K.muted), children: [
            TextSpan(text: '${euroIt(k.p)} '),
            TextSpan(text: euroIt(k.o), style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough)),
          ])),
          if (app.welcomeUntil > nowMs())
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Countdown(app.welcomeUntil,
                  builder: (t) => Text("⏳ L'offerta scade tra $t", style: const TextStyle(color: K.berry, fontWeight: FontWeight.w600, fontSize: 14))),
            ),
          const SizedBox(height: 22),
          Btn('OTTIENI PROMO ORA', onTap: () => Navigator.pop(ctx, true)),
          _noThanks('No, Grazie non mi interessa', () => Navigator.pop(ctx, false)),
        ]),
      ),
    ),
  );
}

Future<void> showQuiz(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: _QuizDialog()),
    );

class _QuizDialog extends StatefulWidget {
  const _QuizDialog();
  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  int step = 0;
  final Map<String, String> a = {};
  bool otherRegion = false;
  String region = kRegions[1];
  QuizResult? result;

  void answer(String v) {
    final q = kQuiz[step];
    if (q.k == 'reg' && v == 'Altra regione') {
      setState(() => otherRegion = true);
      return;
    }
    a[q.k] = v;
    if (step < kQuiz.length - 1) {
      setState(() => step++);
    } else {
      setState(() => result = app.applyQuiz(a));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r != null) {
      return ModalCard(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final p in r.sample)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Avatar(p, size: 58)),
          ]),
          const SizedBox(height: 16),
          Text('Ci sono ${r.n} donne che fanno per te', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: K.navy)),
          const SizedBox(height: 8),
          Text(
            r.widened ? "In ${a['reg']} ce ne sono poche: ti mostriamo anche il resto d'Italia." : 'Le trovi in cima alla tua Radar.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: K.muted, fontSize: 15),
          ),
          const SizedBox(height: 22),
          Btn('VEDI CHI SONO', onTap: () => Navigator.pop(context)),
        ]),
      );
    }
    final q = kQuiz[step];
    Widget body;
    if (otherRegion) {
      body = Column(children: [
        DropdownButtonFormField<String>(
          value: region,
          isExpanded: true,
          items: kRegions.skip(1).map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => region = v ?? region),
        ),
        const SizedBox(height: 14),
        Btn('Continua', color: K.indigo, height: 48, fontSize: 16, onTap: () {
          a['reg'] = region;
          setState(() => result = app.applyQuiz(a));
        }),
      ]);
    } else if (step < 2) {
      body = Column(children: [
        for (final o in q.o)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: _QuizOpt(o, onTap: () => answer(o))),
      ]);
    } else {
      body = GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.2,
        children: [for (final o in q.o) _QuizOpt(o, small: true, onTap: () => answer(o))],
      );
    }
    return ModalCard(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: (step + 1) / 3, minHeight: 6, backgroundColor: K.lav, color: K.peri),
            ),
          ),
          const SizedBox(width: 10),
          Text('${step + 1} di 3', style: const TextStyle(color: K.muted, fontSize: 13)),
        ]),
        const SizedBox(height: 18),
        const Text('TROVA CHI FA PER TE', textAlign: TextAlign.center, style: TextStyle(color: K.peri, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: .5)),
        const SizedBox(height: 6),
        Text(otherRegion ? 'In che regione sei?' : q.t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: K.navy)),
        const SizedBox(height: 18),
        body,
      ]),
    );
  }
}

class _QuizOpt extends StatelessWidget {
  final String label;
  final bool small;
  final VoidCallback onTap;
  const _QuizOpt(this.label, {this.small = false, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCFCFE6), width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: small ? 8 : 14, horizontal: 10),
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: small ? 14 : 16.5, fontWeight: FontWeight.w600, color: K.navy)),
          ),
        ),
      );
}

/// "BENVENUTO! Verifica la tua mail"
Future<void> showEmailModal(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xB8FFFFFF),
    builder: (_) => const PopScope(canPop: false, child: _EmailDialog()),
  );
  if (ok == true) {
    app.verifyEmail();
    showGiftBanner();
  } else {
    app.askEmail = false;
    app.save();
    app.refresh();
  }
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog();
  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  bool change = false;
  String? err;
  late final TextEditingController ctl = TextEditingController(text: app.user['email'] as String? ?? '');

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = app.user['email'] as String? ?? '';
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close, color: Color(0xFF999999)), tooltip: 'Chiudi'),
            ),
            const Text('BENVENUTO!', style: TextStyle(fontSize: 30, color: K.navy, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Icon(Icons.forward_to_inbox, size: 60, color: K.indigo),
            const SizedBox(height: 10),
            const Text('Il tuo Profilo su Yooppe è stato creato con successo, devi solo verificare la tua Mail', textAlign: TextAlign.center, style: _txt),
            const SizedBox(height: 18),
            const Text('Ti abbiamo inviato una mail a:', style: TextStyle(fontSize: 16, color: K.ink2)),
            const SizedBox(height: 4),
            Text(email, textAlign: TextAlign.center, style: const TextStyle(color: K.pink, fontSize: 17)),
            const SizedBox(height: 18),
            Btn('VAI ALLA TUA EMAIL', color: K.indigo, height: 48, onTap: () async {
              final v = await showMailbox(context);
              if (v == true && context.mounted) Navigator.pop(context, true);
            }),
            const SizedBox(height: 10),
            if (!change)
              TextButton(
                onPressed: () => setState(() => change = true),
                child: const Text('Vuoi cambiare indirizzo? Clicca qui', style: TextStyle(color: K.indigo, decoration: TextDecoration.underline)),
              )
            else ...[
              Row(children: [
                Expanded(child: TextField(controller: ctl, keyboardType: TextInputType.emailAddress, autocorrect: false)),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: K.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    onPressed: () {
                      final v = ctl.text.trim();
                      if (!kEmailRe.hasMatch(v)) {
                        setState(() => err = 'Inserisci un indirizzo email valido, ad esempio nome@email.it');
                        return;
                      }
                      app.setUser({'email': v});
                      setState(() {
                        change = false;
                        err = null;
                      });
                      toast('Email di conferma inviata a $v');
                    },
                    child: const Text('Invia'),
                  ),
                ),
              ]),
              if (err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err!, style: const TextStyle(color: K.red, fontSize: 12.5))),
            ],
            const SizedBox(height: 20),
            const Text('IMPORTANTE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF333333))),
            const SizedBox(height: 8),
            const _Bullets([
              'Verifica nella cartella spam per assicurarti che la nostra mail non sia finita lì',
              'Contrassegna il nostro messaggio come “non spam” per ricevere tutti i messaggi delle donne su Yooppe',
              'La nostra mail potrebbe tardare fino a 5 minuti per essere consegnata al tuo indirizzo',
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  const _Bullets(this.items);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('•  ', style: TextStyle(fontSize: 14, color: K.ink2)),
              Expanded(child: Text(i, style: const TextStyle(fontSize: 14, color: K.ink2, height: 1.45))),
            ]),
          ),
      ]);
}

/// Anteprima dimostrativa dell'email di conferma. true = confermato.
Future<bool?> showMailbox(BuildContext context) => showDialog<bool>(
      context: context,
      builder: (ctx) {
        final email = app.user['email'] as String? ?? '';
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFF2F2F5),
                padding: const EdgeInsets.all(14),
                child: Text.rich(TextSpan(style: const TextStyle(fontSize: 13, color: K.muted, height: 1.5), children: [
                  const TextSpan(text: 'Da: '),
                  const TextSpan(text: 'Yooppe', style: TextStyle(color: K.ink, fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' <no-reply@yooppe.com>\nA: '),
                  TextSpan(text: '$email\nOggetto: '),
                  const TextSpan(text: 'Conferma il tuo account Yooppe', style: TextStyle(color: K.ink, fontWeight: FontWeight.w700)),
                ])),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(children: [
                  const Logo(width: 130),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(style: const TextStyle(fontSize: 15, color: K.ink2, height: 1.55), children: [
                      const TextSpan(text: 'Ciao! Manca solo un passaggio: conferma il tuo indirizzo email per attivare il profilo e ricevere '),
                      TextSpan(text: '${Cfg.giftCredits} crediti in regalo', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: '.'),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 260,
                    child: Btn('Conferma il mio account', color: K.pink, height: 48, radius: 24, fontSize: 16, onTap: () => Navigator.pop(ctx, true)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Questa è un'anteprima dimostrativa dell'email.", style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ]),
              ),
            ]),
          ),
        );
      },
    );

// ======================================================================
// Offerte del rate plan
// ======================================================================

/// "ASPETTA! Riattiviamo la Super Promo 2x1". true = accetta
Future<bool?> showExitModal(BuildContext context) {
  Tracking.track('exit_offer_view');
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ModalCard(
      header: 'ASPETTA! 🎁',
      onClose: () => Navigator.pop(ctx, false),
      child: Column(children: [
        const Text('2x1', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: K.navy, height: 1)),
        const SizedBox(height: 4),
        const Text('Riattiviamo per te la\nSUPER PROMO 2x1', textAlign: TextAlign.center, style: TextStyle(color: K.navy, fontWeight: FontWeight.w700, fontSize: 21, height: 1.3)),
        const SizedBox(height: 18),
        Text('Il doppio dei crediti su tutti i pacchetti, solo per i prossimi ${Cfg.exitPromoMin} minuti.', textAlign: TextAlign.center, style: _txt),
        const SizedBox(height: 22),
        Btn('OTTIENI PROMO ORA', onTap: () => Navigator.pop(ctx, true)),
        _noThanks('No, Grazie non mi interessa', () => Navigator.pop(ctx, false)),
      ]),
    ),
  );
}

/// Offerta "prima ricarica" (dopo qualche secondo di inattività sul rate plan)
Future<void> showStarterSheet(BuildContext context) {
  final k = app.starter;
  Tracking.track('starter_offer_view', {'price': k.p, 'ab': app.ab});
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: K.pink, borderRadius: BorderRadius.circular(20)),
            child: const Text('Solo per la prima ricarica', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
          const SizedBox(height: 12),
          const Text('Super Promo 2x1 in formato mini', textAlign: TextAlign.center, style: TextStyle(color: K.navy, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
            Text('${k.cr} + ${k.b} crediti', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(euroIt(k.p), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: K.green)),
            Text(euroIt(k.o), style: const TextStyle(fontSize: 14, color: K.muted, decoration: TextDecoration.lineThrough)),
          ]),
          const SizedBox(height: 12),
          const Text("Il doppio dei crediti come nella Super Promo, a un prezzo d'ingresso. Offerta valida una sola volta.",
              textAlign: TextAlign.center, style: TextStyle(color: K.ink2, fontSize: 14.5, height: 1.45)),
          const SizedBox(height: 18),
          Btn("PRENDI L'OFFERTA", onTap: () {
            Navigator.pop(ctx);
            Nav.push('/checkout', k.id);
          }),
          _noThanks('Più tardi', () => Navigator.pop(ctx)),
        ]),
      ),
    ),
  );
}

/// Al rientro in una chat con messaggi in attesa
Future<void> showRecoveryModal(BuildContext context) => showDialog<void>(
      context: context,
      barrierColor: const Color(0xB8FFFFFF),
      builder: (ctx) => ModalCard(
        header: 'SUPER PROMO 2x1',
        child: Column(children: [
          const Text('2x1', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: K.navy, height: 1)),
          const SizedBox(height: 4),
          const Text('Ricevi fino a\n2000 crediti GRATIS!', textAlign: TextAlign.center, style: TextStyle(color: K.navy, fontWeight: FontWeight.w700, fontSize: 22, height: 1.3)),
          const SizedBox(height: 18),
          const Text('Tutti i pacchetti offrono il Doppio dei Crediti!', textAlign: TextAlign.center, style: _txt),
          const SizedBox(height: 22),
          Btn('OTTIENI PROMO ORA', onTap: () {
            Navigator.pop(ctx);
            app.promo = true;
            app.save();
            Nav.goRecharge();
          }),
          _noThanks('No, Grazie non mi interessa', () => Navigator.pop(ctx)),
        ]),
      ),
    );

/// Simulazione Google Pay / Apple Pay. true = paga
Future<bool?> showWalletSheet(BuildContext context, String wallet, Pkg k) => showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(wallet, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Yooppe · ${k.total} crediti', textAlign: TextAlign.center, style: const TextStyle(color: K.muted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: K.line), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(width: 34, height: 22, decoration: BoxDecoration(color: const Color(0xFF1A1F71), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Visa •••• 6703\n'),
                    TextSpan(text: 'Carta salvata in $wallet', style: const TextStyle(color: K.muted, fontSize: 12)),
                  ])),
                ),
                Text(euro2(k.p), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            Btn('Paga ${euro2(k.p)}', color: Colors.black, height: 52, radius: 26, onTap: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 10),
            const Text('Simulazione: nessun addebito reale.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: K.muted)),
          ]),
        ),
      ),
    );

// ======================================================================
// Notifiche: invito ad attivarle
// ======================================================================

Future<void> showPushAsk(BuildContext context, String reason, Profile who) async {
  Tracking.track('push_soft_ask', {'reason': reason});
  final yes = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ModalCard(
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          Avatar(who, size: 78),
          const Positioned(right: -6, bottom: -4, child: Text('🔔', style: TextStyle(fontSize: 28))),
        ]),
        const SizedBox(height: 14),
        Text(reason == 'reply' ? 'Vuoi sapere subito quando ${who.u} ti risponde?' : 'Attiva le notifiche',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: K.navy)),
        const SizedBox(height: 10),
        const Text(
          'Ti mandiamo una notifica quando qualcuno ti scrive, ti invia una foto privata o visita il tuo profilo. Scegli cosa ricevere da Gestione notifiche.',
          textAlign: TextAlign.center,
          style: TextStyle(color: K.ink2, fontSize: 15, height: 1.45),
        ),
        const SizedBox(height: 18),
        Btn('ATTIVA LE NOTIFICHE', onTap: () => Navigator.pop(ctx, true)),
        _noThanks('Non ora', () => Navigator.pop(ctx, false)),
      ]),
    ),
  );
  if (yes == true) {
    final ok = await app.enablePush();
    toast(ok ? 'Notifiche attivate ✅' : 'Puoi attivarle quando vuoi dalle impostazioni del telefono');
  } else {
    Tracking.track('push_soft_ask', {'result': 'later'});
  }
}

// ======================================================================
// Generici
// ======================================================================

Future<bool> showConfirm(BuildContext context, {required String title, required String text, required String ok, bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title, style: const TextStyle(color: K.navy, fontWeight: FontWeight.w700, fontSize: 19)),
      content: Text(text, style: const TextStyle(color: K.ink2, height: 1.45)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? K.red : K.indigo),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r == true;
}

Future<void> showInfo(BuildContext context, String key) {
  final i = kInfo[key]!;
  return showDialog<void>(
    context: context,
    builder: (ctx) => ModalCard(
      header: i[0],
      onClose: () => Navigator.pop(ctx),
      child: Text(i[1], style: const TextStyle(fontSize: 15, color: K.ink2, height: 1.5)),
    ),
  );
}

// ======================================================================
// Radar: filtri
// ======================================================================

Future<void> showFiltersSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const _FiltersSheet(),
    );

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();
  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late Filters f = app.filters;

  Widget chips(String k, List<String> opts, String cur, void Function(String) set) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in opts)
          ChoiceChip(
            label: Text(o),
            selected: cur == o,
            showCheckmark: false,
            onSelected: (_) => setState(() => set(o)),
            selectedColor: K.indigo,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(color: cur == o ? Colors.white : K.navy, fontWeight: FontWeight.w500),
            side: BorderSide(color: cur == o ? K.indigo : const Color(0xFFCFCFE6), width: 1.5),
            shape: const StadiumBorder(),
          ),
      ]);

  Widget grp(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: K.muted)),
          const SizedBox(height: 8),
          child,
        ]),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Filtro di ricerca', style: TextStyle(color: K.navy, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            grp('Genere', chips('g', ['Donne', 'Uomini'], f.g, (v) => f = f.copyWith(g: v))),
            grp('Età', chips('age', kAges.keys.toList(), f.age, (v) => f = f.copyWith(age: v))),
            grp(
              'Zona',
              DropdownButtonFormField<String>(
                value: f.reg,
                isExpanded: true,
                items: kRegions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => f = f.copyWith(reg: v)),
              ),
            ),
            grp('Foto', chips('foto', ['Sì', 'Tutte'], f.foto, (v) => f = f.copyWith(foto: v))),
            Row(children: [
              Expanded(child: Btn('Annulla', outline: true, color: K.indigo, height: 48, fontSize: 16, onTap: () => Navigator.pop(context))),
              const SizedBox(width: 10),
              Expanded(
                child: Btn('Mostra profili', color: K.indigo, height: 48, fontSize: 16, onTap: () {
                  app.setFilters(f);
                  Navigator.pop(context);
                }),
              ),
            ]),
          ]),
        ),
      );
}

// ======================================================================
// Chat: regali, proposte, commento foto
// ======================================================================

Future<void> showGifts(BuildContext context, String id) => showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('REGALI', style: TextStyle(color: K.navy, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('I regali sono sempre ben apprezzati!', style: TextStyle(color: K.indigo, fontSize: 16)),
              const SizedBox(height: 14),
              Flexible(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 16,
                  childAspectRatio: .95,
                  children: [
                    for (var i = 0; i < kGifts.length; i++)
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          if (!app.sendGift(id, i)) Nav.goRecharge();
                        },
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFBDBDBD)), borderRadius: BorderRadius.circular(8)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                              child: Text(kGifts[i].n.toUpperCase(), maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: K.navy, height: 1.2)),
                            ),
                            Expanded(child: Center(child: Text(kGifts[i].e, style: const TextStyle(fontSize: 46)))),
                            Container(
                              width: double.infinity,
                              color: K.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Text('${kGifts[i].c} crediti', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Il tuo saldo: ${app.credits} crediti', style: const TextStyle(fontSize: 13, color: K.muted)),
            ]),
          ),
        ),
      ),
    );

Future<void> showProposals(BuildContext context, String id) => showDialog<void>(context: context, builder: (_) => _Proposals(id));

class _Proposals extends StatefulWidget {
  final String id;
  const _Proposals(this.id);
  @override
  State<_Proposals> createState() => _ProposalsState();
}

class _ProposalsState extends State<_Proposals> {
  int i = 0;
  void mv(int d) {
    final n = i + d;
    if (n >= 0 && n < kProposals.length) setState(() => i = n);
  }

  Widget ud(IconData ic, int d, bool enabled) => Opacity(
        opacity: enabled ? 1 : .3,
        child: Material(
          color: K.peri,
          shape: const CircleBorder(),
          child: InkWell(customBorder: const CircleBorder(), onTap: enabled ? () => mv(d) : null, child: SizedBox(width: 44, height: 44, child: Icon(ic, color: Colors.white))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pr = kProposals[i];
    return ModalCard(
      header: 'PROPOSTE SPECIALI',
      headerColor: K.navy,
      onClose: () => Navigator.pop(context),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -150) mv(1);
          if (v > 150) mv(-1);
        },
        child: Column(children: [
          ud(Icons.keyboard_arrow_up, -1, i > 0),
          const Divider(height: 24, indent: 20, endIndent: 20),
          Text(pr.t, style: const TextStyle(fontSize: 12, color: K.peri, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 146),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(22, 20, 30, 20),
                decoration: BoxDecoration(color: K.navy, borderRadius: BorderRadius.circular(30)),
                child: Text(pr.x, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 18, height: 1.4)),
              ),
            ),
            Transform.translate(
              offset: const Offset(-16, 0),
              child: Material(
                color: K.wine,
                shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 6)),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.pop(context);
                    final id = widget.id;
                    if (!app.canWrite) {
                      Nav.goRecharge();
                      return;
                    }
                    app.pushMine(id, Msg(id: '', f: 'me', k: 'text', x: pr.x, t: 0));
                    Tracking.track('proposal_sent', {'to': id, 'tone': pr.t});
                    if (!(currentLocation() == 'chat' && currentArg() == id)) Nav.push('/chat', id);
                  },
                  child: const SizedBox(width: 74, height: 74, child: Icon(Icons.send, color: Colors.white, size: 30)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var j = 0; j < kProposals.length; j++)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(shape: BoxShape.circle, color: j == i ? K.peri : const Color(0xFFCFCFE6)),
              ),
          ]),
          const SizedBox(height: 10),
          ud(Icons.keyboard_arrow_down, 1, i < kProposals.length - 1),
        ]),
      ),
    );
  }
}

Future<void> showCommentSheet(BuildContext context, String id, int v) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _CommentSheet(id, v),
    );

class _CommentSheet extends StatefulWidget {
  final String id;
  final int v;
  const _CommentSheet(this.id, this.v);
  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final ctl = TextEditingController(text: 'Che bella che sei!');
  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = profileOf(widget.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Commenta la foto', style: TextStyle(color: K.navy, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 64, height: 76, child: PPic(p, v: widget.v))),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(TextSpan(style: const TextStyle(fontSize: 14, color: K.muted, height: 1.4), children: [
              const TextSpan(text: 'Il commento arriva in chat a '),
              TextSpan(text: p.u, style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' insieme alla foto.'),
            ])),
          ),
        ]),
        const SizedBox(height: 14),
        TextField(controller: ctl, maxLines: 3, maxLength: 300, decoration: const InputDecoration(hintText: 'Scrivi un commento…')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Btn('Annulla', outline: true, color: K.indigo, height: 48, fontSize: 16, onTap: () => Navigator.pop(context))),
          const SizedBox(width: 10),
          Expanded(
            child: Btn('Invia commento', color: K.indigo, height: 48, fontSize: 16, onTap: () {
              final x = ctl.text.trim();
              if (x.isEmpty) return;
              final nav = Navigator.of(context);
              nav.pop(); // foglio
              nav.pop(); // galleria
              if (!app.canWrite) {
                Nav.goRecharge();
                return;
              }
              app.pushMine(widget.id, Msg(id: '', f: 'me', k: 'pcom', x: x, imgP: widget.id, imgV: widget.v, t: 0));
              Tracking.track('photo_comment', {'to': widget.id});
              if (!(currentLocation() == 'chat' && currentArg() == widget.id)) Nav.push('/chat', widget.id);
            }),
          ),
        ]),
      ]),
    );
  }
}

// ======================================================================
// Galleria foto (con foto private da sbloccare)
// ======================================================================

Future<void> showGallery(BuildContext context, String id, int start) => showDialog<void>(
      context: context,
      barrierColor: const Color(0xB8000000),
      builder: (_) => _Gallery(id, start),
    );

class _Gallery extends StatefulWidget {
  final String id;
  final int start;
  const _Gallery(this.id, this.start);
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  late int i = widget.start;
  late final PageController pc = PageController(initialPage: widget.start);

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  void go(int d) {
    final p = profileOf(widget.id);
    final n = i + d;
    if (n < 0 || n >= p.np) return;
    pc.animateToPage(n, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Widget arrow(IconData ic, int d, bool enabled) => Opacity(
        opacity: enabled ? 1 : .35,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(customBorder: const CircleBorder(), onTap: enabled ? () => go(d) : null, child: SizedBox(width: 44, height: 44, child: Icon(ic, color: Colors.black87))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = profileOf(widget.id);
    final locked = s.isLocked(p, i);
    final liked = s.plikes['${p.id}#$i'] == true;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(children: [
              PageView.builder(
                controller: pc,
                itemCount: p.np,
                onPageChanged: (n) => setState(() => i = n),
                itemBuilder: (_, v) => s.isLocked(p, v) ? LockedPhoto(p: p, v: v) : Container(color: const Color(0xFF222222), child: PPic(p, v: v)),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: Text('${i + 1}/${p.np}${p.isPriv(i) ? ' · privata' : ''}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  tooltip: 'Chiudi',
                ),
              ),
              Positioned(left: 8, top: 0, bottom: 0, child: Center(child: arrow(Icons.chevron_left, -1, i > 0))),
              Positioned(right: 8, top: 0, bottom: 0, child: Center(child: arrow(Icons.chevron_right, 1, i < p.np - 1))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: K.green, shape: const StadiumBorder(), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      if (locked) {
                        if (!app.unlock(p.id, i)) {
                          Navigator.pop(context);
                          Nav.goRecharge();
                        }
                      } else {
                        showCommentSheet(context, p.id, i);
                      }
                    },
                    icon: Icon(locked ? Icons.lock : Icons.mail, size: 22),
                    label: Text(locked ? 'SBLOCCA FOTO' : 'COMMENTA'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Material(
                color: liked ? K.berryD : K.pink,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => app.togglePhotoLike(p.id, i),
                  child: const SizedBox(width: 54, height: 54, child: Icon(Icons.favorite, color: Colors.white, size: 28)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Foto privata sfocata con pulsante "Sblocca".
class LockedPhoto extends StatelessWidget {
  final Profile p;
  final int v;
  final bool compact;
  const LockedPhoto({super.key, required this.p, required this.v, this.compact = false});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        ClipRect(
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: PPic(p, v: v)),
        ),
        Container(color: const Color(0x55000000)),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock, color: Colors.white, size: compact ? 30 : 40),
            const SizedBox(height: 6),
            const Text('Foto privata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: K.pink, shape: const StadiumBorder()),
              onPressed: () {
                if (!app.unlock(p.id, v)) Nav.goRecharge();
              },
              child: const Text('Sblocca · ${Cfg.photoUnlock} crediti'),
            ),
          ]),
        ),
      ]);
}

// ======================================================================
// Strumenti demo
// ======================================================================

Future<void> showDemoTools(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        Widget b(String label, VoidCallback f, {bool danger = false}) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Btn(label, outline: true, color: danger ? K.red : K.indigo, height: 46, fontSize: 15, onTap: () {
                Navigator.pop(ctx);
                f();
              }),
            );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .8,
          maxChildSize: .95,
          builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            const Text('Strumenti demo', style: TextStyle(color: K.navy, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Scorciatoie per mostrare i flussi durante la presentazione. Saldo attuale: ${app.credits} crediti.', style: const TextStyle(color: K.ink2)),
            const SizedBox(height: 14),
            b('Azzera i crediti', () => app.demoCredits(0, reset: true)),
            b('Aggiungi 500 crediti', () => app.demoCredits(500)),
            b('Simula un nuovo messaggio', app.demoMsg),
            b('Simula una visita e un mi piace', app.demoVisit),
            b('Ricevi subito il primo messaggio', () {
              Nav.tab('radar');
              app.demoFirst();
            }),
            b('Notifica dal vivo adesso', () {
              Nav.tab('radar');
              Future.delayed(const Duration(milliseconds: 400), app.liveEvent);
            }),
            b("Prova l'offerta di uscita dal rate plan", () {
              app.demoExit();
              Nav.goRecharge();
              toast('Ora premi la freccia indietro del rate plan');
            }),
            b('Prova l\'offerta "prima ricarica"', () {
              app.demoStarter();
              Nav.goRecharge();
              toast('Aspetta ${Cfg.rateplanIdleSec} secondi senza toccare nulla');
            }),
            b('Prova una notifica sul telefono', app.demoTestPush),
            b("Mostra di nuovo l'offerta di benvenuto", () {
              app.demoWelcome();
              Nav.tab('radar');
            }),
            b('Ricomincia la demo da zero', () async {
              final c = navKey.currentContext;
              if (c == null) return;
              if (await showConfirm(c, title: 'Ricominciare la demo?', text: 'Cancella tutti i dati della demo e torna alla schermata iniziale.', ok: 'Ricomincia', danger: true)) {
                await app.deleteProfile();
              }
            }, danger: true),
          ]),
        );
      },
    );

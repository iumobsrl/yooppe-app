import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../data/content.dart';
import '../../data/profiles.dart';
import '../../nav.dart';
import '../../services/tracking.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../modals.dart';
import '../theme.dart';
import '../widgets/common.dart';

// ======================================================================
// Rate plan
// ======================================================================

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});
  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    Tracking.track('view_rateplan', {'mode': app.promoMode ? 'promo' : 'standard'});
    if (app.purchases.isEmpty && !app.starterUsed && !app.starterShown) {
      _idle = Timer(const Duration(seconds: Cfg.rateplanIdleSec), () {
        if (!mounted || currentLocation() != 'crediti' || tracker.popupOnTop) return;
        app.starterShown = true;
        showStarterSheet(context);
      });
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }

  /// Freccia indietro: la prima volta al giorno propone la Super Promo 2x1.
  Future<void> _back() async {
    final today = todayKey();
    if (app.pendingCount == 0 && !app.promo && !app.exitActive && app.exitShown != today) {
      app.exitShown = today;
      app.save();
      final yes = await showExitModal(context);
      if (yes == true) {
        app.activateExitPromo();
        return;
      }
    }
    _leave();
  }

  void _leave() {
    if (app.pendingCount > 0) {
      app.recovery = true;
      app.save();
    }
    _idle?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pend = s.pendingList;
    final promo = s.promoMode;
    final last = pend.isNotEmpty ? profileOf(pend.last.key) : null;

    final banners = <Widget>[
      if (s.exitActive && pend.isEmpty)
        _Banner(
          color: const Color(0xFFFFF4E0),
          border: K.gold,
          child: Row(children: [
            const Text('⏳ ', style: TextStyle(fontSize: 18)),
            const Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: 'Super Promo 2x1', style: TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: ' riattivata per te')]))),
            Countdown(s.exitBonusUntil, builder: (t) => Text('scade tra $t', style: const TextStyle(fontWeight: FontWeight.w700, color: K.berry)), onEnd: s.refresh),
          ]),
        ),
      if (s.welcomeValid)
        InkWell(
          onTap: () => Nav.push('/checkout', kPkWelcome.id),
          child: _Banner(
            color: K.lav,
            border: K.peri,
            child: Row(children: [
              const Expanded(
                child: Text.rich(TextSpan(style: TextStyle(color: K.indigo, height: 1.35), children: [
                  TextSpan(text: '🎁 '),
                  TextSpan(text: 'Offerta di benvenuto -60%', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: '\n700 + 200 crediti a 24,99€'),
                ])),
              ),
              Column(children: [
                const Text('scade tra', style: TextStyle(fontSize: 11, color: K.muted)),
                Countdown(s.welcomeUntil, style: const TextStyle(fontWeight: FontWeight.w800, color: K.berry), onEnd: s.refresh),
              ]),
            ]),
          ),
        ),
    ];

    final pkgs = promo ? kPkPromo : kPkStd;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
            SizedBox(
              height: 56,
              child: Stack(alignment: Alignment.center, children: [
                Positioned(left: 0, child: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_ios_new), tooltip: 'Indietro')),
                if (last != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: K.red, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Hai dei messaggi non inviati!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  )
                else
                  const Logo(width: 150),
              ]),
            ),
            if (last != null) ...[
              const SizedBox(height: 10),
              Center(child: Avatar(last, size: 96)),
              const SizedBox(height: 10),
              const Text('Appena hai crediti a sufficienza, i messaggi verranno inviati automaticamente',
                  textAlign: TextAlign.center, style: TextStyle(color: K.ink2, fontSize: 14.5, height: 1.4)),
            ],
            if (promo)
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text('SUPER PROMO 2x1', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: K.pink)),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 8),
                child: Text('Seleziona un pacchetto e ricarica i crediti per chattare con chi vuoi',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: K.ink2, height: 1.4)),
              ),
            ...banners,
            const SizedBox(height: 6),
            for (var i = 0; i < pkgs.length; i++) ...[
              if (promo && i == 1) const Divider(height: 26),
              _PkTile(pkgs[i], promo: promo),
            ],
            const SizedBox(height: 26),
            const Text('Pagamenti sicuri con:', textAlign: TextAlign.center, style: TextStyle(color: K.muted, fontSize: 13)),
            const SizedBox(height: 8),
            const TrustRow(),
            if (!promo) ...[
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF2D49B))),
                child: Row(children: [
                  const Text('🎁', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: 'Regalo del giorno\n', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: '${Cfg.dailyCredits} crediti gratis, ogni giorno', style: TextStyle(color: K.ink2, fontSize: 13)),
                    ])),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: K.green),
                    onPressed: s.daily == todayKey() ? null : s.claimDaily,
                    child: Text(s.daily == todayKey() ? 'Ritirato' : 'Ritira'),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(style: const TextStyle(color: K.ink2), children: [
                const TextSpan(text: 'Il tuo saldo: '),
                TextSpan(text: '${s.credits} crediti', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color, border;
  final Widget child;
  const _Banner({required this.color, required this.border, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1.5)),
        child: child,
      );
}

class _PkTile extends StatelessWidget {
  final Pkg k;
  final bool promo;
  const _PkTile(this.k, {required this.promo});
  @override
  Widget build(BuildContext context) {
    final tagged = k.tag != null;
    return Padding(
      padding: EdgeInsets.only(top: tagged ? 14 : 6, bottom: 6),
      child: Stack(clipBehavior: Clip.none, children: [
        Material(
          color: Colors.white,
          elevation: tagged ? 3 : 1,
          shadowColor: K.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tagged ? K.pink : const Color(0xFFD5D5E5), width: tagged ? 2 : 1.2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Nav.push('/checkout', k.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(children: [
                Expanded(
                  child: Text.rich(TextSpan(style: const TextStyle(fontSize: 17, color: K.ink), children: [
                    TextSpan(text: '${k.cr}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: K.navy)),
                    const TextSpan(text: ' crediti'),
                  ])),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(euro(k.p), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: K.green)),
                  Text(euro(k.o), style: const TextStyle(fontSize: 12, color: K.muted, decoration: TextDecoration.lineThrough)),
                ]),
                if (promo) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: K.pink, borderRadius: BorderRadius.circular(8)),
                    child: Column(children: [
                      Text('+${k.b}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text('IN REGALO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
        ),
        if (tagged)
          Positioned(
            left: 14,
            top: -11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: K.pink, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.white, size: 13),
                const SizedBox(width: 3),
                Text(k.tag!, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ======================================================================
// Checkout (dimostrativo)
// ======================================================================

bool luhn(String n) {
  var s = 0;
  var alt = false;
  for (var i = n.length - 1; i >= 0; i--) {
    var d = int.parse(n[i]);
    if (alt) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    s += d;
    alt = !alt;
  }
  return s % 10 == 0;
}

class _CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 19) d = d.substring(0, 19);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _ExpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    final t = d.length >= 3 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class CheckoutScreen extends StatefulWidget {
  final String pkId;
  const CheckoutScreen({super.key, required this.pkId});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final n = TextEditingController(), c = TextEditingController(), e = TextEditingController(), v = TextEditingController();
  bool autoR = false;
  List<String> errs = [];
  Set<String> bad = {};
  bool paying = false;

  Pkg get k => findPkg(widget.pkId, app.ab) ?? kPkStd.first;

  @override
  void initState() {
    super.initState();
    Tracking.track('begin_checkout', {'value': k.p, 'currency': 'EUR', 'package': k.id});
  }

  @override
  void dispose() {
    for (final x in [n, c, e, v]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _pay(String method) async {
    if (paying) return;
    paying = true;
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(26),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: K.indigo),
                SizedBox(height: 16),
                Text('Pagamento in corso…'),
              ]),
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    Navigator.of(context).pop();
    app.applyPurchase(k.id, method, autoR);
    Nav.replace('/ok');
  }

  void _submitCard() {
    final er = <String>[];
    final b = <String>{};
    if (n.text.trim().split(RegExp(r'\s+')).length < 2) {
      er.add('Inserisci nome e cognome come sulla carta.');
      b.add('n');
    }
    final digits = c.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || !luhn(digits)) {
      er.add('Il numero della carta non è valido.');
      b.add('c');
    }
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(e.text);
    final mm = m == null ? 0 : int.parse(m.group(1)!);
    final yy = m == null ? 0 : int.parse(m.group(2)!);
    if (m == null || mm < 1 || mm > 12 || !DateTime(2000 + yy, mm + 1, 1).isAfter(DateTime.now())) {
      er.add('La scadenza deve essere nel formato mm/aa e nel futuro.');
      b.add('e');
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(v.text)) {
      er.add('Il CVC ha 3 o 4 cifre.');
      b.add('v');
    }
    setState(() {
      errs = er;
      bad = b;
    });
    if (er.isEmpty) _pay('Carta •••• ${digits.substring(digits.length - 4)}');
  }

  InputDecoration _dec(String hint, String key, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        counterText: '',
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: bad.contains(key) ? K.red : const Color(0xFFCFCFD6), width: bad.contains(key) ? 1.5 : 1)),
      );

  Future<void> _wallet(String w) async {
    final ok = await showWalletSheet(context, w, k);
    if (ok == true) _pay(w);
  }

  @override
  Widget build(BuildContext context) {
    final k = this.k;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final walletBtns = [
      Expanded(child: Btn('G Pay', color: Colors.black, height: 50, radius: 25, onTap: () => _wallet('Google Pay'))),
      const SizedBox(width: 10),
      Expanded(child: Btn('Apple Pay', color: Colors.black, height: 50, radius: 25, onTap: () => _wallet('Apple Pay'))),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 8, 22, 30), children: [
          SizedBox(
            height: 56,
            child: Stack(alignment: Alignment.center, children: [
              Positioned(left: 0, child: IconButton(onPressed: Nav.back, icon: const Icon(Icons.arrow_back_ios_new), tooltip: 'Indietro')),
              const Logo(width: 150),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: K.lav, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${k.cr}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: K.navy)),
                    const TextSpan(text: ' crediti', style: TextStyle(fontSize: 17)),
                  ])),
                  if (k.b > 0) Text('+ ${k.b} in regalo', style: const TextStyle(color: K.pink, fontWeight: FontWeight.w700)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Totale', style: TextStyle(color: K.muted, fontSize: 13)),
                Text(euro2(k.p), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
          TextButton.icon(
            onPressed: () => showInfo(context, 'refund'),
            icon: const Icon(Icons.verified_user, color: Color(0xFF5E9AD8)),
            label: const Text('Garanzia di rimborso', style: TextStyle(color: K.indigo, decoration: TextDecoration.underline)),
          ),
          if (!['w700', 'st50'].contains(k.id))
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: autoR,
              onChanged: (x) => setState(() => autoR = x ?? false),
              title: Text.rich(TextSpan(style: const TextStyle(fontSize: 13.5, height: 1.4), children: [
                const TextSpan(text: 'Ricarica automatica', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' · quando finisci i crediti ricarichiamo questo pacchetto (${euro2(k.p)}). La disattivi quando vuoi da Impostazioni.'),
              ])),
            ),
          const SizedBox(height: 8),
          Row(children: ios ? walletBtns.reversed.toList() : walletBtns),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
          const Text('Carta di credito', style: TextStyle(fontWeight: FontWeight.w700, color: K.ink2)),
          const SizedBox(height: 10),
          TextField(controller: n, textCapitalization: TextCapitalization.words, autofillHints: const [AutofillHints.creditCardName], decoration: _dec('Nome e Cognome', 'n')),
          const SizedBox(height: 10),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [_CardFormatter()],
            autofillHints: const [AutofillHints.creditCardNumber],
            decoration: _dec('Numero della carta', 'c'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: e, keyboardType: TextInputType.number, inputFormatters: [_ExpFormatter()], decoration: _dec('mm/aa', 'e'))),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: v,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('CVC/CVV', 'v', suffix: IconButton(onPressed: () => showInfo(context, 'cvc'), icon: const Icon(Icons.info_outline, size: 20))),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          const Text('Demo: usa la carta di prova 4242 4242 4242 4242', style: TextStyle(fontSize: 12.5, color: K.muted)),
          if (errs.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(errs.join('\n'), style: const TextStyle(color: K.red, fontSize: 13, height: 1.4))),
          const SizedBox(height: 16),
          Btn('Continua', color: K.green, onTap: _submitCard),
          const SizedBox(height: 14),
          const TrustRow(),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, children: [
            const Text('Facendo clic su Continua, accetti i nostri ', style: TextStyle(fontSize: 12, color: K.muted)),
            GestureDetector(onTap: () => showInfo(context, 'terms'), child: const Text("Termini d'uso", style: TextStyle(fontSize: 12, color: K.indigo, decoration: TextDecoration.underline))),
            const Text(' e ', style: TextStyle(fontSize: 12, color: K.muted)),
            GestureDetector(onTap: () => showInfo(context, 'privacy'), child: const Text('Informativa sulla privacy', style: TextStyle(fontSize: 12, color: K.indigo, decoration: TextDecoration.underline))),
          ]),
          const SizedBox(height: 14),
          const Text('Pagamento dimostrativo: nessun addebito reale.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: K.berry, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ======================================================================
// Esito pagamento
// ======================================================================

class OkScreen extends StatelessWidget {
  const OkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lp = s.lastPurchase;
    final toChat = (s.returnTo ?? '').startsWith('chat/');
    void cont() {
      s.returnTo = null;
      s.save();
      Nav.leavePayments();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cont();
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(26, 24, 26, 30), children: [
            const Center(child: Logo(width: 140)),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(color: K.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 46),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Pagamento riuscito', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.navy)),
            const SizedBox(height: 8),
            const Text('Grazie! Abbiamo aggiunto i crediti al tuo account.', textAlign: TextAlign.center, style: TextStyle(color: K.ink2, fontSize: 15.5)),
            if (lp != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: K.lav, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('+${lp.cr + lp.b} crediti', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: K.indigo)),
                  const SizedBox(height: 4),
                  Text('${lp.b > 0 ? '${lp.cr} + ${lp.b} in regalo · ' : ''}pagati ${euro2(lp.p)} con ${lp.m}\nSaldo attuale: ${s.credits} crediti',
                      textAlign: TextAlign.center, style: const TextStyle(color: K.ink2, height: 1.45)),
                ]),
              ),
              if (lp.sent > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(lp.sent == 1 ? 'Il tuo messaggio in attesa è stato inviato.' : 'I tuoi ${lp.sent} messaggi in attesa sono stati inviati.',
                      textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
            const SizedBox(height: 24),
            Btn(toChat ? 'TORNA ALLA CHAT' : 'INIZIA A CHATTARE', onTap: cont),
            if (s.pushGranted != true) ...[
              const SizedBox(height: 18),
              Btn('🔔 Avvisami quando mi rispondono', outline: true, color: K.indigo, height: 48, fontSize: 15, onTap: () => s.enablePush()),
            ],
          ]),
        ),
      ),
    );
  }
}

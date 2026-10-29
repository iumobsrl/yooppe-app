import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/profiles.dart';
import '../../services/tracking.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../modals.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late final TextEditingController em = TextEditingController(text: app.user['email'] as String? ?? '');
  final pw = TextEditingController();
  bool show = false, adult = false;
  String? err;
  late final TapGestureRecognizer _terms = TapGestureRecognizer()..onTap = () => showInfo(context, 'terms');
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()..onTap = () => showInfo(context, 'privacy');

  @override
  void initState() {
    super.initState();
    if (!app.landingLogin) Tracking.track('landing_view', {'teaser': teaserFromAttribution(Tracking.attr)});
  }

  @override
  void dispose() {
    em.dispose();
    pw.dispose();
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  void submit() {
    final login = app.landingLogin;
    final e = em.text.trim();
    if (!kEmailRe.hasMatch(e)) return setState(() => err = 'Inserisci un indirizzo email valido, ad esempio nome@email.it');
    if (pw.text.length < 6) return setState(() => err = 'La password deve avere almeno 6 caratteri.');
    FocusScope.of(context).unfocus();
    if (login) {
      if (!app.login(e)) {
        app.landingLogin = false;
        setState(() => err = 'Non troviamo un account con questa email: registrati in pochi secondi.');
      }
      return;
    }
    if (!adult) return setState(() => err = 'Per entrare devi confermare di avere più di 18 anni e accettare i Termini.');
    app.register(e);
  }

  @override
  Widget build(BuildContext context) {
    final login = context.select<AppState, bool>((s) => s.landingLogin);
    final tp = profileOf(teaserFromAttribution(Tracking.attr));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(padding: const EdgeInsets.fromLTRB(28, 24, 28, 32), children: [
              const Center(child: Logo(width: 178)),
              const SizedBox(height: 18),
              Text.rich(
                const TextSpan(style: TextStyle(fontSize: 15, height: 1.5, color: K.ink2), children: [
                  TextSpan(text: 'CHATTA CON DONNE CHE '),
                  TextSpan(text: 'FANNO IL PRIMO PASSO', style: TextStyle(fontWeight: FontWeight.w700, color: K.ink)),
                ]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              if (!login) _Teaser(tp),
              if (!login) const SizedBox(height: 22),
              Text.rich(
                const TextSpan(style: TextStyle(fontSize: 28, height: 1.25, color: K.ink), children: [
                  TextSpan(text: 'Che il '),
                  TextSpan(text: 'divertimento', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' abbia inizio!💋'),
                ]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              const Divider(color: K.line),
              const SizedBox(height: 14),
              if (login)
                const Text('Bentornato! Inserisci i tuoi dati per entrare.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.6, color: K.ink2))
              else ...[
                const Text(
                  'Ti invieremo una mail che dovrai aprire e cliccare sul link per verificare anche tu il tuo account e interagire con gli altri utenti.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, height: 1.6, color: K.ink2),
                ),
                const SizedBox(height: 14),
                const Text('🚨 Se non trovi la mail guarda nella tua casella di SPAM o POSTA INDESIDERATA 🚨',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.6, color: K.ink2)),
              ],
              const SizedBox(height: 10),
              const Text('Inserisci la tua email:', style: TextStyle(fontSize: 16, color: K.ink2)),
              const SizedBox(height: 8),
              TextField(
                controller: em,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              Text(login ? 'Password:' : 'Inserisci una password sicura:', style: const TextStyle(fontSize: 16, color: K.ink2)),
              const SizedBox(height: 8),
              TextField(
                controller: pw,
                obscureText: !show,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => submit(),
                autofillHints: [login ? AutofillHints.password : AutofillHints.newPassword],
                decoration: InputDecoration(
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => show = !show),
                    child: Text(show ? 'Nascondi' : 'Mostra', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: K.indigo)),
                  ),
                ),
              ),
              if (!login) ...[
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 28, height: 28, child: Checkbox(value: adult, onChanged: (v) => setState(() => adult = v ?? false))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text.rich(TextSpan(style: const TextStyle(fontSize: 13, height: 1.45, color: K.ink2), children: [
                        const TextSpan(text: 'Dichiaro di avere più di 18 anni e accetto i '),
                        TextSpan(text: "Termini d'uso", style: _link, recognizer: _terms),
                        const TextSpan(text: " e l'"),
                        TextSpan(text: 'Informativa sulla privacy', style: _link, recognizer: _privacy),
                        const TextSpan(text: '.'),
                      ])),
                    ),
                  ),
                ]),
              ],
              if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: K.red, fontSize: 12.5))),
              const SizedBox(height: 24),
              SizedBox(
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF0549A), Color(0xFFE2207A)]),
                    boxShadow: const [BoxShadow(color: Color(0x4DED1E79), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(29),
                      onTap: submit,
                      child: Center(child: Text(login ? 'ACCEDI' : 'ENTRA ORA', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(login ? 'Non hai un account? ' : 'Hai già un account? ', style: const TextStyle(fontSize: 13, color: K.muted)),
                InkWell(
                  onTap: () => setState(() {
                    app.landingLogin = !login;
                    err = null;
                    app.refresh();
                  }),
                  child: Text(login ? 'Registrati' : 'Accedi', style: _link.copyWith(fontSize: 13)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

const _link = TextStyle(color: K.indigo, decoration: TextDecoration.underline, fontWeight: FontWeight.w600, decorationColor: K.indigo);

/// "serena_casa ti ha lasciato un messaggio — registrati gratis per leggerlo"
class _Teaser extends StatelessWidget {
  final Profile p;
  const _Teaser(this.p);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: K.line),
          boxShadow: const [BoxShadow(color: K.shadow, blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Avatar(p, size: 58),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(width: 13, height: 13, decoration: BoxDecoration(color: K.online, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '${p.u}, ${p.age} anni ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const TextSpan(text: '· online ora', style: TextStyle(color: K.green, fontSize: 12.5)),
              ])),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: K.bubbleHer, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: const Text('Ciao… sei appena arrivato? Ti ho notato subito 😏 ti va di…', style: TextStyle(fontSize: 13.5)),
                  ),
                  const SizedBox(height: 6),
                  const Row(children: [
                    Icon(Icons.lock, size: 14, color: K.berry),
                    SizedBox(width: 4),
                    Text('Ti ha lasciato un messaggio', style: TextStyle(fontSize: 12.5, color: K.berry, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
              const SizedBox(height: 6),
              const Text('Registrati gratis per leggerlo 👇', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: K.indigo)),
            ]),
          ),
        ]),
      );
}

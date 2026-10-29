import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/content.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../bridge.dart';
import '../modals.dart';
import '../theme.dart';
import '../widgets/common.dart';

List<String> _range(int a, int b, String suf) => [for (var i = a; i <= b; i++) '$i$suf'];

final Map<String, List<String>> _opts = {
  'rel': ['Single', 'Divorziato', 'Separato', 'Vedovo', 'Impegnato'],
  'alt': _range(150, 205, ' cm'),
  'peso': _range(45, 140, ' kg'),
  'corp': ['Snella', 'Normale', 'Atletica', 'Robusta', 'Qualche chilo in più'],
  'stud': ['Licenza media', 'Diploma', 'Laurea', 'Master', 'Dottorato'],
  'zod': kPool['zod']!,
  'bev': ['Mai', 'A volte', 'Spesso'],
  'fum': ['Mai', 'A volte', 'Sì'],
  'sit': ['Single', 'Divorziato', 'Separato', 'Vedovo'],
};

class MeTab extends StatefulWidget {
  const MeTab({super.key});
  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  late final un = TextEditingController(text: app.user['username']?.toString() ?? '');
  late final em = TextEditingController(text: app.user['email']?.toString() ?? '');
  late final age = TextEditingController(text: app.user['age']?.toString() ?? '');
  late final bio = TextEditingController(text: app.user['bio']?.toString() ?? '');
  final Map<String, String> sel = {};
  final Set<String> dirty = {};

  @override
  void initState() {
    super.initState();
    for (final k in _opts.keys) {
      final v = app.user[k]?.toString() ?? '';
      sel[k] = _opts[k]!.contains(v) ? v : _opts[k]!.first;
    }
  }

  @override
  void dispose() {
    un.dispose();
    em.dispose();
    age.dispose();
    bio.dispose();
    super.dispose();
  }

  void mark(String sec) => setState(() => dirty.add(sec));

  void saveSec(String sec) {
    final ch = <String, dynamic>{};
    if (sec == 'dati') {
      final a = int.tryParse(age.text.trim());
      if (a == null || a < 18 || a > 99) return toast("L'età deve essere tra 18 e 99 anni");
      if (!kEmailRe.hasMatch(em.text.trim())) return toast('Inserisci un indirizzo email valido');
      ch.addAll({'username': un.text.trim(), 'email': em.text.trim(), 'age': a});
    } else if (sec == 'bio') {
      ch['bio'] = bio.text.trim();
    } else if (sec == 'car') {
      for (final k in ['rel', 'alt', 'peso']) {
        ch[k] = sel[k];
      }
    } else {
      for (final k in ['corp', 'stud', 'zod', 'bev', 'fum', 'sit']) {
        ch[k] = sel[k];
      }
    }
    app.setUser(ch);
    setState(() => dirty.remove(sec));
    toast('Modifiche salvate');
  }

  Future<void> pickPhoto() async {
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 640, maxHeight: 640, imageQuality: 80);
      if (img == null) return;
      final b = await img.readAsBytes();
      app.setUser({'photo': base64Encode(b)});
      toast('Foto profilo aggiornata');
    } catch (_) {
      toast('Non riesco a leggere questa immagine. Prova con un JPG o PNG.');
    }
  }

  Widget okBtn(String sec) => AnimatedSize(
        duration: const Duration(milliseconds: 160),
        child: dirty.contains(sec)
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: K.green),
                    onPressed: () => saveSec(sec),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Conferma'),
                  ),
                ),
              )
            : const SizedBox(width: double.infinity),
      );

  Widget field(IconData ic, String label, TextEditingController c, String sec, {TextInputType? kb, int? maxLen}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(ic, size: 18, color: K.indigo), const SizedBox(width: 6), Text(label, style: const TextStyle(color: K.indigo, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 6),
          TextField(controller: c, keyboardType: kb, maxLength: maxLen, onChanged: (_) => mark(sec), decoration: const InputDecoration(counterText: '')),
        ]),
      );

  Widget dd(String sec, String k, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 15.5))),
          DropdownButton<String>(
            value: sel[k],
            underline: const SizedBox.shrink(),
            items: _opts[k]!.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) {
              if (v == null) return;
              sel[k] = v;
              mark(sec);
            },
          ),
        ]),
      );

  Widget section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(top: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          const SizedBox(height: 8),
          ...children,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final photo = s.user['photo'] as String?;
    Widget counter(int n, String label, String tab) => Expanded(
          child: InkWell(
            onTap: () => Nav.tab(tab),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(children: [
                Text('$n', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: K.navy)),
                Text(label, style: const TextStyle(fontSize: 13, color: K.muted)),
              ]),
            ),
          ),
        );
    Widget link(String t, VoidCallback f, {Color color = K.navy, bool soft = false}) => InkWell(
          onTap: f,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: K.line))),
            child: Text(t, style: TextStyle(fontSize: 16, color: color, fontWeight: soft ? FontWeight.w400 : FontWeight.w600)),
          ),
        );

    return Column(children: [
      const PendingBar(),
      Expanded(
        child: ListView(padding: EdgeInsets.only(bottom: 30 + MediaQuery.of(context).padding.bottom), children: [
          SizedBox(
            height: 260,
            child: Stack(fit: StackFit.expand, children: [
              photo != null
                  ? B64Img(photo)
                  : Container(color: const Color(0xFFDDDDE3), alignment: Alignment.bottomCenter, child: const Icon(Icons.person, size: 220, color: Color(0xFF1F3B4D))),
              Positioned(
                right: 14,
                bottom: 14,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: K.indigo),
                  onPressed: pickPhoto,
                  icon: const Icon(Icons.add),
                  label: const Text('Cambia foto'),
                ),
              ),
            ]),
          ),
          Container(
            color: K.soft,
            child: Row(children: [
              counter(s.herMsgCount, 'Messaggi', 'chat'),
              counter(s.likers.length, 'Mi piace', 'notifiche'),
              counter(s.visitors.length, 'Visite', 'notifiche'),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              field(Icons.person, 'Username', un, 'dati', maxLen: 24),
              field(Icons.email, 'Email', em, 'dati', kb: TextInputType.emailAddress),
              field(Icons.cake, 'Età', age, 'dati', kb: TextInputType.number),
              okBtn('dati'),
              section('Chi sono', [
                TextField(
                  controller: bio,
                  maxLines: 4,
                  maxLength: 400,
                  onChanged: (_) => mark('bio'),
                  decoration: const InputDecoration(hintText: 'Racconta qualcosa di te'),
                ),
                okBtn('bio'),
              ]),
              section('Caratteristiche', [dd('car', 'rel', 'Relazione:'), dd('car', 'alt', 'Altezza:'), dd('car', 'peso', 'Peso:'), okBtn('car')]),
              section('Su di me', [
                dd('sud', 'corp', 'Corporatura:'),
                dd('sud', 'stud', 'Titolo di studio:'),
                dd('sud', 'zod', 'Segno zodiacale'),
                dd('sud', 'bev', 'Bevitore'),
                dd('sud', 'fum', 'Fumatore'),
                dd('sud', 'sit', 'Situazione sentimentale'),
                okBtn('sud'),
              ]),
              const SizedBox(height: 20),
              link('Impostazioni profilo', () => Nav.push('/me-impostazioni')),
              link('Gestione Notifiche', () => Nav.push('/me-notifiche')),
              link('Supporto', () => Nav.push('/me-supporto')),
              link(s.sub ? 'Disattiva abbonamento' : 'Abbonamento disattivato', () => confirmUnsub(context), soft: true, color: K.muted),
              link('Cancella profilo', () => confirmDelete(context), color: K.red),
              link('Esci', s.logout, soft: true, color: K.muted),
              link('Strumenti demo', () => showDemoTools(context), soft: true, color: K.peri),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

Future<void> confirmUnsub(BuildContext context) async {
  if (!app.sub) return;
  if (await showConfirm(context,
      title: 'Disattivare l’abbonamento?',
      text: 'Non riceverai più rinnovi automatici né offerte riservate. I crediti che hai già restano disponibili.',
      ok: 'Disattiva',
      danger: true)) {
    app.unsubscribe();
    toast('Abbonamento disattivato');
  }
}

Future<void> confirmDelete(BuildContext context) async {
  if (await showConfirm(context,
      title: 'Cancellare il profilo?',
      text: 'Profilo, conversazioni e crediti verranno eliminati in modo definitivo. Non potrai recuperarli.',
      ok: 'Cancella profilo',
      danger: true)) {
    await app.deleteProfile();
    toast('Profilo cancellato');
  }
}

// ---------------------------------------------------------------------------

class _SubPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SubPage({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          TopNav(active: 'me'),
          SubHead(
            backLabel: 'Profilo',
            onBack: Nav.back,
            title: Text(title.toUpperCase(), style: const TextStyle(color: K.navy, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.fromLTRB(22, 8, 22, 30 + MediaQuery.of(context).padding.bottom), children: children),
          ),
        ]),
      );
}

Widget _h2(String t) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: K.navy)),
    );

Widget _toggle(String label, bool on, ValueChanged<bool> f, {String? help}) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: on,
      onChanged: f,
      activeColor: K.green,
      title: Text(label, style: const TextStyle(fontSize: 15.5)),
      subtitle: help != null ? Text(help, style: const TextStyle(fontSize: 12.5, color: K.muted)) : null,
    );

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final pw1 = TextEditingController(), pw2 = TextEditingController();
  @override
  void dispose() {
    pw1.dispose();
    pw2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final auto = s.autoPk == null ? null : findPkg(s.autoPk!, s.ab);
    return _SubPage(title: 'Impostazioni profilo', children: [
      _h2('Account'),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Email', style: TextStyle(fontSize: 15.5)),
            Text(s.user['email']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, color: K.muted)),
          ]),
        ),
        Text(s.verified ? 'Confermata' : 'Da confermare', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.verified ? K.green : K.red)),
      ]),
      if (!s.verified)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Btn("Invia di nuovo l'email di conferma", outline: true, color: K.indigo, height: 46, fontSize: 15, onTap: () {
            s.askEmail = true;
            s.save();
            showEmailModal(context);
          }),
        ),
      _h2('Cambia password'),
      TextField(controller: pw1, obscureText: true, decoration: const InputDecoration(hintText: 'Password attuale')),
      const SizedBox(height: 10),
      TextField(controller: pw2, obscureText: true, decoration: const InputDecoration(hintText: 'Nuova password (almeno 6 caratteri)')),
      const SizedBox(height: 10),
      Btn('Salva password', color: K.indigo, height: 46, fontSize: 15, onTap: () {
        if (pw1.text.isEmpty) return toast('Inserisci la password attuale');
        if (pw2.text.length < 6) return toast('La nuova password deve avere almeno 6 caratteri');
        pw1.clear();
        pw2.clear();
        toast('Password aggiornata');
      }),
      _h2('Privacy'),
      _toggle('Mostrami online', s.privacy['online'] != false, (v) => s.setPref('priv', 'online', v), help: 'Gli altri vedono il pallino verde sul tuo profilo'),
      _toggle('Profilo visibile nella Radar', s.privacy['visible'] != false, (v) => s.setPref('priv', 'visible', v)),
      _h2('Storico acquisti'),
      if (s.purchases.isEmpty)
        const Text('Nessun acquisto ancora.', style: TextStyle(color: K.muted, fontSize: 14.5))
      else
        for (final x in s.purchases)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${x.cr + x.b} crediti', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${fmtDate(x.t)} · ${x.m}', style: const TextStyle(fontSize: 12.5, color: K.muted)),
                ]),
              ),
              Text(euro2(x.p), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
      _h2('Ricarica automatica'),
      if (auto == null)
        const Text('Non attiva. Puoi sceglierla al prossimo acquisto.', style: TextStyle(color: K.muted, fontSize: 14.5))
      else
        _toggle('Ricarica automatica · ${auto.total} crediti a ${euro2(auto.p)}', s.autoOn, (v) {
          s.setPref('auto', 'on', v);
          toast(v ? 'Ricarica automatica attivata' : 'Ricarica automatica disattivata');
        }, help: 'Quando finisci i crediti ricarichiamo lo stesso pacchetto'),
      _h2('Abbonamento e profilo'),
      Text(s.sub ? 'Abbonamento attivo: ricevi offerte e rinnovi' : 'Abbonamento disattivato', style: const TextStyle(fontSize: 14.5)),
      if (s.sub)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Btn('Disattiva abbonamento', outline: true, color: K.indigo, height: 46, fontSize: 15, onTap: () => confirmUnsub(context)),
        ),
      const SizedBox(height: 14),
      Btn('Cancella profilo', outline: true, color: K.red, height: 46, fontSize: 15, onTap: () => confirmDelete(context)),
    ]);
  }
}

class NotifPrefsScreen extends StatelessWidget {
  const NotifPrefsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final n = s.notif;
    void set(String k, bool v) {
      s.setPref('notif', k, v);
      toast('Preferenza salvata');
    }

    return _SubPage(title: 'Gestione notifiche', children: [
      _h2('Notifiche sul telefono'),
      if (s.pushGranted == true)
        const Text('✅ Attive su questo telefono.', style: TextStyle(color: K.green, fontWeight: FontWeight.w600))
      else
        Btn('Attiva le notifiche', height: 48, fontSize: 16, onTap: () async {
          final ok = await s.enablePush();
          toast(ok ? 'Notifiche attivate ✅' : 'Permesso negato: puoi attivarle dalle impostazioni del telefono');
        }),
      if (s.pushGranted == true)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Btn('Invia una notifica di prova', outline: true, color: K.indigo, height: 46, fontSize: 15, onTap: s.demoTestPush),
        ),
      _h2('Avvisami quando'),
      _toggle('Ricevo un nuovo messaggio', n['msg'] != false, (v) => set('msg', v)),
      _toggle('Qualcuno mi mette mi piace', n['like'] != false, (v) => set('like', v)),
      _toggle('Qualcuno visita il mio profilo', n['vis'] != false, (v) => set('vis', v)),
      _h2('Comunicazioni'),
      _toggle('Offerte, promo e regali quotidiani', n['promo'] != false, (v) => set('promo', v)),
      _toggle('Newsletter di Yooppe', n['news'] == true, (v) => set('news', v)),
      const SizedBox(height: 14),
      const Text(
        'Valgono per le email e per le notifiche sul telefono. Le email di servizio (conferma account, ricevute di pagamento) arrivano sempre.',
        style: TextStyle(fontSize: 13, color: K.muted, height: 1.5),
      ),
    ]);
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String topic = 'Pagamenti e crediti';
  final msg = TextEditingController();
  String? err;
  @override
  void dispose() {
    msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SubPage(title: 'Supporto', children: [
        _h2('Domande frequenti'),
        for (final f in kFaq)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            title: Text(f[0], style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: K.ink)),
            children: [Text(f[1], style: const TextStyle(color: K.ink2, height: 1.5))],
          ),
        _h2('Scrivici'),
        DropdownButtonFormField<String>(
          value: topic,
          isExpanded: true,
          items: const ['Pagamenti e crediti', 'Account e profilo', 'Problemi tecnici', 'Segnala un utente', 'Altro']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => topic = v ?? topic),
        ),
        const SizedBox(height: 10),
        TextField(controller: msg, maxLines: 5, decoration: const InputDecoration(hintText: 'Descrivi la tua richiesta')),
        if (err != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err!, style: const TextStyle(color: K.red, fontSize: 12.5))),
        const SizedBox(height: 10),
        Btn('Invia richiesta', color: K.indigo, height: 48, fontSize: 16, onTap: () {
          if (msg.text.trim().length < 10) return setState(() => err = 'Descrivi la richiesta in almeno 10 caratteri.');
          setState(() => err = null);
          msg.clear();
          toast('Richiesta inviata. Ti rispondiamo via email entro 24 ore');
        }),
        const SizedBox(height: 14),
        const Text('Rispondiamo via email entro 24 ore.', style: TextStyle(fontSize: 13, color: K.muted)),
      ]);
}

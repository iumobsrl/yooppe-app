// Contenuti della demo (stessi della web app).

const List<String> kRegions = [
  'Tutta Italia', 'Abruzzo', 'Basilicata', 'Calabria', 'Campania', 'Emilia-Romagna', 'Friuli-Venezia Giulia', 'Lazio',
  'Liguria', 'Lombardia', 'Marche', 'Molise', 'Piemonte', 'Puglia', 'Sardegna', 'Sicilia', 'Toscana',
  'Trentino-Alto Adige', 'Umbria', "Valle d'Aosta", 'Veneto',
];

const Map<String, List<int>> kAges = {
  '18-29': [19, 29],
  '30-39': [30, 39],
  '40-49': [40, 49],
  '50+': [50, 62],
  'Tutte': [21, 60],
};

const List<String> kBios = [
  "Solare e un po' testarda. Amo le cene lunghe, il mare d'inverno e chi sa farmi ridere senza sforzo.",
  'Lavoro tanto e la sera ho voglia di leggerezza: due chiacchiere sincere e vedere dove ci portano.',
  'Figli grandi e finalmente tempo per me. Cerco un uomo gentile che sappia ancora corteggiare.',
  'Mi piacciono i weekend fuori porta, il vino rosso e le persone dirette. Scrivimi se non hai paura delle domande.',
  "Sono curiosa, romantica quanto basta e ballo anche quando non c'è musica.",
  'Ho un sorriso facile e un debole per chi sa ascoltare. Vediamo se mi conquisti con un messaggio.',
  'Infermiera di giorno, cuoca disastrosa di sera. Cerco complicità, rispetto e un po\' di ironia.',
  'Amo la palestra, i viaggi improvvisati e le chiacchierate fino a tardi. Niente perditempo.',
  "Timida all'inizio, poi non mi fermi più. Mi piacciono gli uomini sicuri ma con un lato dolce.",
  'Ho voglia di emozioni nuove e di qualcuno con cui condividere un aperitivo e qualche segreto.',
  'Libera, indipendente e con tanta voglia di flirtare. Il primo passo? Lo faccio io.',
  'Appassionata di cinema e cucina etnica. Se mi porti a mangiare sushi ho già detto sì.',
];

const Map<String, List<String>> kPool = {
  'rel': ['Single', 'Divorziata', 'Separata', 'Single', 'Vedova'],
  'car': ['Solare', 'Riservata', 'Romantica', 'Estroversa', 'Dolce', 'Determinata', 'Sicura di sé'],
  'corp': ['Snella', 'Normale', 'Formosa', 'Atletica', 'Curvy'],
  'stud': ['Diploma', 'Laurea', 'Licenza media', 'Master'],
  'zod': ['Ariete', 'Toro', 'Gemelli', 'Cancro', 'Leone', 'Vergine', 'Bilancia', 'Scorpione', 'Sagittario', 'Capricorno', 'Acquario', 'Pesci'],
  'bev': ['Mai', 'A volte', 'A volte', 'Spesso'],
  'fum': ['Mai', 'Mai', 'A volte', 'Sì'],
  'sit': ['Single', 'Divorziata', 'Separata', 'Vedova'],
};

class BaseProfile {
  final String id;
  final String u;
  final int age;
  final String reg;
  final bool on;
  final bool noph;
  final String? bio;
  const BaseProfile(this.id, this.u, this.age, this.reg, this.on, {this.noph = false, this.bio});
}

const List<BaseProfile> kCore = [
  BaseProfile('c1', 'macomesonobella', 51, 'Lazio', true),
  BaseProfile('c2', 'dolce_aurora', 47, 'Lombardia', true),
  BaseProfile('c3', 'occhineri_rm', 53, 'Lazio', false),
  BaseProfile('c4', 'sole.di.marzo', 44, 'Campania', true),
  BaseProfile('c5', 'lunadimiele', 56, 'Lazio', true),
  BaseProfile('c6', 'vale_sorride', 38, 'Toscana', false),
  BaseProfile('c7', 'rossa_di_sera', 52, 'Veneto', false),
  BaseProfile('c8', 'ariadne71', 55, 'Lazio', false),
  BaseProfile('c9', 'nuvola_rosa', 50, 'Puglia', true),
  BaseProfile('c10', 'cuoreinviaggio', 58, 'Lazio', true, noph: true),
  BaseProfile('c11', 'martina.bianca', 33, 'Piemonte', true),
  BaseProfile('c12', 'elisir_d_amore', 49, 'Sicilia', false),
  BaseProfile('t1', 'serena_casa', 50, 'Lazio', true,
      bio: 'Separata da poco, casa tutta per me e tanta voglia di rimettermi in gioco. Adoro le chiacchierate la sera sul divano… e chi sa farmi sorridere.'),
];

const List<BaseProfile> kFillers = [
  BaseProfile('f1', 'dolce_giulia', 52, 'Lazio', true),
  BaseProfile('f2', 'stella.romana', 51, 'Lazio', false),
  BaseProfile('f3', 'patrizia_sorride', 53, 'Lazio', true),
  BaseProfile('f4', 'gioia70', 54, 'Lazio', false),
  BaseProfile('f5', 'silver_lady', 58, 'Lazio', true),
  BaseProfile('f6', 'rosa_di_maggio', 56, 'Lazio', false),
  BaseProfile('f7', 'lago_di_como', 57, 'Lombardia', true),
  BaseProfile('f8', 'fiorentina_doc', 59, 'Toscana', false),
  BaseProfile('f9', 'monica.blu', 46, 'Lazio', true),
  BaseProfile('f10', 'simona_luce', 43, 'Lazio', false),
  BaseProfile('f11', 'venezia_mia', 48, 'Veneto', true),
  BaseProfile('f12', 'sirena_napoletana', 41, 'Campania', false),
  BaseProfile('f13', 'chiara.milano', 31, 'Lombardia', true),
  BaseProfile('f14', 'fata_bolognese', 29, 'Emilia-Romagna', true),
  BaseProfile('f15', 'ambra_rm', 34, 'Lazio', false),
  BaseProfile('f16', 'perla_del_sud', 33, 'Puglia', true),
];

/// Landing per creatività: parole chiave nel nome dell'annuncio → profilo teaser.
final List<MapEntry<RegExp, String>> kTeaserMap = [
  MapEntry(RegExp(r'matur|milf|over ?50|blond|bionda|charizard', caseSensitive: false), 't1'),
  MapEntry(RegExp(r'brun|mora|dark', caseSensitive: false), 'c3'),
  MapEntry(RegExp(r'ross|red', caseSensitive: false), 'c7'),
  MapEntry(RegExp(r'silver|over ?55|nonn', caseSensitive: false), 'c5'),
];

const Map<String, String> kFirstBy = {
  'Chat piccanti 🔥': "Ciao… ho visto che sei appena arrivato 😏 Io non perdo tempo: ti va di scoprire com'è chiacchierare con me?",
  'Flirt e complicità 😏': 'Ciao! Ti ho notato subito tra i nuovi iscritti 😊 Mi piace chi sa farmi sorridere… ci provi?',
  'Incontri dal vivo 🍷': "Ciao, anche tu cerchi qualcuno con cui vederti davvero? Io sì… prima però voglio conoscerti un po' 😉",
  '': 'Ciao… sei nuovo vero? 😊 Mi piace fare il primo passo. Come ti chiami?',
};

const List<String> kPrivCaptions = [
  'Questa è solo per te… 🙈',
  'Ti va di vedere cosa indosso stasera? 😏',
  'Non la mando a tutti, sai… 💋',
  "Così ti faccio un po' di compagnia 😉",
];

class QuizQ {
  final String k;
  final String t;
  final List<String> o;
  const QuizQ(this.k, this.t, this.o);
}

const List<QuizQ> kQuiz = [
  QuizQ('want', 'Cosa cerchi su Yooppe?', ['Chat piccanti 🔥', 'Flirt e complicità 😏', 'Incontri dal vivo 🍷', 'Vediamo cosa succede 🤷‍♂️']),
  QuizQ('age', 'Che donne ti piacciono?', ['30-40 anni', '40-50 anni', 'Over 50', 'Mi piacciono tutte']),
  QuizQ('reg', 'In che zona sei?', ['Lombardia', 'Lazio', 'Campania', 'Sicilia', 'Veneto', 'Piemonte', 'Puglia', 'Emilia-Romagna', 'Toscana', 'Altra regione']),
];

const Map<String, String> kQuizAge = {
  '30-40 anni': '30-39',
  '40-50 anni': '40-49',
  'Over 50': '50+',
  'Mi piacciono tutte': 'Tutte',
};

const List<String> kFirstMsgs = [
  'Ciao Bellezza! Il mio caffè della mattina è più buono se qualcuno mi scrive 😊 Tu come stai?',
  'Ciao! Ho visto il tuo profilo e mi hai incuriosita. Che fai di bello stasera?',
  'Ehi, ci sei? Mi piacerebbe conoscerti meglio 😉',
  'Buonasera! Sei sempre così misterioso o è solo il profilo? 😄',
  'Ciao, ho una domanda per te: mare o montagna?',
  'Ti ho messo un mi piace, spero non ti dispiaccia 🙈',
];

const List<String> kReplies = [
  'Ciao anche a te e buon pomeriggio, spero tu abbia avuto una bella giornata, come ti chiami?',
  'In realtà vorrei procedere per gradi, conoscere persone nuove e tu?',
  'Mi fai sorridere 😊 raccontami qualcosa di te',
  'Che lavoro fai? Io oggi sono stata in giro tutto il giorno',
  'Mi piace come scrivi… continua 😏',
  'E dimmi, cosa cerchi qui su Yooppe?',
  'Sono appena tornata a casa, mi metto comoda e ti scrivo meglio 😉',
  'Mi piacerebbe un aperitivo, un giorno di questi… tu dove abiti?',
  'Ahah sei simpatico! Anche io adoro le serate tranquille',
  'Mi rispondi solo nei sogni? 😄 Scherzo, dimmi tutto',
];
const List<String> kRGift = ['Che pensiero dolce! Grazie 🥰', 'Mi hai fatto arrossire 😳 grazie del regalo!', 'Adoro le sorprese… sei un tesoro 💕'];
const List<String> kRPhoto = ['Grazie! Quella foto è una delle mie preferite 😊', "Ti piace davvero? Allora più avanti te ne mostro un'altra 😉", 'Sei gentile… mi hai migliorato la giornata'];
const List<String> kRUserPh = ['Carino! Ora ti riconosco 😄', "Che bel sorriso! Mandamene un'altra quando vuoi 😉"];

class Proposal {
  final String t;
  final String x;
  const Proposal(this.t, this.x);
}

const List<Proposal> kProposals = [
  Proposal('Giocoso', 'Cosa ti piacerebbe trovare qui: un flirt leggero o una conoscenza che possa diventare qualcosa di importante?😏'),
  Proposal('Timido', 'Ciao… non sono bravo a rompere il ghiaccio, ma il tuo sorriso mi ha convinto a provarci 😊'),
  Proposal('Romantico', "C'è qualcosa nel tuo sguardo che mi ha fatto fermare. Ti va di raccontarmi chi sei davvero?"),
  Proposal('Diretto', 'Mi piaci e preferisco dirtelo subito: ti va di conoscerci?'),
  Proposal('Affine', 'Ho letto il tuo profilo e ci ho trovato tante cose in comune. Partiamo da quella che preferisci?'),
  Proposal('Concreto', 'Che ne dici di due chiacchiere qui e poi, se ci troviamo, un caffè insieme?'),
  Proposal('Giocoso', 'Scommetto che sai già cosa sto per scriverti… sbaglio? 😜'),
];

class Gift {
  final String n;
  final String e;
  final int c;
  const Gift(this.n, this.e, this.c);
}

const List<Gift> kGifts = [
  Gift('Mazzo di rose', '💐', 100),
  Gift('Orsetto innamorato', '🧸', 80),
  Gift('Scatola di cioccolatini', '🍫', 130),
  Gift('Scatola magica', '💝', 60),
  Gift("Brindisi dell'amore", '🥂', 100),
  Gift('Lettera', '💌', 150),
];

class Pkg {
  final String id;
  final int cr; // crediti
  final double p; // prezzo
  final double o; // prezzo barrato
  final int b; // bonus in regalo
  final String? tag;
  const Pkg(this.id, this.cr, this.p, this.o, {this.b = 0, this.tag});
  int get total => cr + b;
}

const List<Pkg> kPkStd = [
  Pkg('s100', 100, 6, 9),
  Pkg('s700', 700, 49, 69, tag: 'Più scelto'),
  Pkg('s250', 250, 19, 39),
  Pkg('s2000', 2000, 99, 129, tag: 'Più conveniente'),
];
const List<Pkg> kPkPromo = [
  Pkg('p100', 100, 9, 19, b: 100),
  Pkg('p60', 60, 6, 9, b: 60),
  Pkg('p700', 700, 49, 69, b: 700, tag: 'Più scelto'),
  Pkg('p250', 250, 19, 39, b: 250),
  Pkg('p2000', 2000, 99, 129, b: 2000, tag: 'Più conveniente'),
];
const Pkg kPkWelcome = Pkg('w700', 700, 24.99, 49.99, b: 200);

/// Test A/B sul prezzo della "prima ricarica": A = 2,99 · B = 1,99
Pkg starterPkg(String ab) => Pkg('st50', 50, ab == 'B' ? 1.99 : 2.99, 5.99, b: 50);

Pkg? findPkg(String id, String ab) {
  for (final k in [...kPkStd, ...kPkPromo, kPkWelcome, starterPkg(ab)]) {
    if (k.id == id) return k;
  }
  return null;
}

const Map<String, List<String>> kInfo = {
  'refund': [
    'Garanzia di rimborso',
    "Se un pacchetto non ti soddisfa puoi chiedere il rimborso entro 14 giorni dall'acquisto, per i crediti non ancora utilizzati.\n\nScrivi al Supporto indicando la data dell'acquisto: rispondiamo entro 24 ore.",
  ],
  'terms': [
    "Termini d'uso",
    "Testo dimostrativo. Qui andranno i Termini d'uso del servizio Yooppe: requisiti di età (18+), regole di comportamento, funzionamento dei crediti e condizioni di rimborso.",
  ],
  'privacy': [
    'Informativa sulla privacy',
    "Testo dimostrativo. Qui andrà l'informativa sul trattamento dei dati personali e i diritti dell'utente.",
  ],
  'cvc': [
    'Codice CVC/CVV',
    'Sono le 3 cifre stampate sul retro della carta, accanto alla firma. Sulle carte American Express sono 4 cifre sul fronte.',
  ],
};

const List<List<String>> kFaq = [
  ['Come funzionano i crediti?', 'Navigare, guardare i profili e mettere mi piace è gratis. I crediti servono per chattare, mandare regali e sbloccare le foto private.'],
  ['Ho scritto un messaggio ma risulta «non inviato»', 'Succede quando i crediti non bastano. Il messaggio resta in attesa e parte da solo appena ricarichi.'],
  ['Non ho ricevuto l’email di conferma', 'Controlla la cartella spam o posta indesiderata e segna il messaggio come «non spam». Può arrivare fino a 5 minuti dopo. Da Impostazioni profilo puoi inviarla di nuovo.'],
  ['I pagamenti sono sicuri?', 'Sì: i dati della carta passano su un checkout protetto e non vengono salvati nell’app.'],
  ['Come cancello il profilo?', 'Da Profilo → Cancella profilo. La cancellazione è immediata e definitiva.'],
];

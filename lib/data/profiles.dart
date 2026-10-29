import 'content.dart';
import 'photos.dart';

int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

/// Generatore pseudo-casuale deterministico (stesso algoritmo della web app):
/// a parità di id, il profilo ha sempre gli stessi dettagli.
double Function() seededRng(String seed) {
  int h = 2166136261;
  for (final c in seed.codeUnits) {
    h = (h ^ c) & 0xFFFFFFFF;
    h = _imul(h, 16777619);
  }
  return () {
    h = (h + 0x6D2B79F5) & 0xFFFFFFFF;
    int t = h;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296;
  };
}

T pickR<T>(double Function() r, List<T> a) => a[(r() * a.length).floor()];

class Profile {
  final String id;
  final String u;
  final int age;
  final String reg;
  bool on;
  final String g; // 'F' | 'M'
  final bool hasPh;
  final List<String> photos; // pubbliche
  final List<String> priv; // private (da sbloccare)
  final Map<String, String> d; // bio, rel, alt, peso, car, corp, stud, zod, bev, fum, sit

  Profile({
    required this.id,
    required this.u,
    required this.age,
    required this.reg,
    required this.on,
    required this.g,
    required this.hasPh,
    required this.photos,
    required this.priv,
    required this.d,
  });

  int get npub => photos.length;
  List<String> get all => [...photos, ...priv];
  int get np => all.length;
  String get bio => d['bio'] ?? '';
  String get shortName => u.split(RegExp(r'[._]')).first;

  String? photo([int v = 0]) {
    if (!hasPh) return null;
    final a = all;
    if (v >= 0 && v < a.length) return a[v];
    return null;
  }

  bool isPriv(int v) => priv.isNotEmpty && v >= npub;
}

Map<String, String> _details(double Function() r) {
  return {
    'bio': pickR(r, kBios),
    'rel': pickR(r, kPool['rel']!),
    'alt': '${156 + (r() * 20).floor()} cm',
    'peso': '${50 + (r() * 22).floor()} kg',
    'car': pickR(r, kPool['car']!),
    'corp': pickR(r, kPool['corp']!),
    'stud': pickR(r, kPool['stud']!),
    'zod': pickR(r, kPool['zod']!),
    'bev': pickR(r, kPool['bev']!),
    'fum': pickR(r, kPool['fum']!),
    'sit': pickR(r, kPool['sit']!),
  };
}

final Map<String, Profile> _cache = {};

Profile? profileById(String id) {
  final cached = _cache[id];
  if (cached != null) return cached;
  Profile? p;
  final ci = kCore.indexWhere((c) => c.id == id);
  final fi = kFillers.indexWhere((f) => f.id == id);
  if (ci >= 0) {
    final c = kCore[ci];
    final d = _details(seededRng('${id}d'));
    d['bio'] = c.bio ?? kBios[ci % kBios.length];
    p = Profile(
      id: c.id, u: c.u, age: c.age, reg: c.reg, on: c.on, g: 'F', hasPh: !c.noph,
      photos: c.noph ? const [] : (kPhotos[id] ?? const []),
      priv: kPrivPhotos[id] ?? const [],
      d: d,
    );
  } else if (fi >= 0) {
    final f = kFillers[fi];
    final d = _details(seededRng('${id}d'));
    p = Profile(
      id: f.id, u: f.u, age: f.age, reg: f.reg, on: f.on, g: 'F', hasPh: true,
      photos: [kFillPhotos[fi % kFillPhotos.length]],
      priv: kPrivPhotos[id] ?? const [],
      d: d,
    );
  }
  if (p != null) _cache[id] = p;
  return p;
}

Profile profileOf(String id) => profileById(id) ?? profileById('t1')!;

List<Profile> allProfiles() => [
      ...kCore.map((c) => profileOf(c.id)),
      ...kFillers.map((f) => profileOf(f.id)),
    ];

class Filters {
  final String g; // Donne | Uomini
  final String age; // chiave di kAges
  final String reg;
  final String foto; // Sì | Tutte
  const Filters({this.g = 'Donne', this.age = '50+', this.reg = 'Lazio', this.foto = 'Sì'});

  Filters copyWith({String? g, String? age, String? reg, String? foto}) =>
      Filters(g: g ?? this.g, age: age ?? this.age, reg: reg ?? this.reg, foto: foto ?? this.foto);

  Map<String, dynamic> toJson() => {'g': g, 'age': age, 'reg': reg, 'foto': foto};
  factory Filters.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Filters();
    return Filters(
      g: j['g'] as String? ?? 'Donne',
      age: j['age'] as String? ?? '50+',
      reg: j['reg'] as String? ?? 'Lazio',
      foto: j['foto'] as String? ?? 'Sì',
    );
  }
}

bool matchesFilters(Profile p, Filters f) {
  final a = kAges[f.age] ?? kAges['Tutte']!;
  final gOk = f.g == 'Donne' ? p.g == 'F' : p.g == 'M';
  return gOk && p.age >= a[0] && p.age <= a[1] && (f.reg == 'Tutta Italia' || p.reg == f.reg) && (f.foto != 'Sì' || p.hasPh);
}

/// Ordinamento stabile: prima gli online.
List<Profile> radarList(Filters f) {
  final all = allProfiles();
  final idx = <String, int>{for (var i = 0; i < all.length; i++) all[i].id: i};
  final out = all.where((p) => matchesFilters(p, f)).toList();
  out.sort((a, b) {
    final c = (b.on ? 1 : 0) - (a.on ? 1 : 0);
    return c != 0 ? c : idx[a.id]! - idx[b.id]!;
  });
  return out;
}

List<Profile> onlineStrip(Filters f) {
  final g = f.g == 'Uomini' ? 'M' : 'F';
  final all = allProfiles().where((p) => p.on && p.hasPh && p.g == g).toList();
  final idx = <String, int>{for (var i = 0; i < all.length; i++) all[i].id: i};
  all.sort((a, b) {
    final c = (matchesFilters(b, f) ? 1 : 0) - (matchesFilters(a, f) ? 1 : 0);
    return c != 0 ? c : idx[a.id]! - idx[b.id]!;
  });
  return all.take(12).toList();
}

String teaserFromAttribution(Map<String, String> attr) {
  final k = [attr['cr'], attr['v4'], attr['ad_name'], attr['utm_content'], attr['utm_campaign']]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' ');
  for (final e in kTeaserMap) {
    if (e.key.hasMatch(k)) return e.value;
  }
  return 't1';
}

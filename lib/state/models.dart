String pad2(int n) => n.toString().padLeft(2, '0');
int nowMs() => DateTime.now().millisecondsSinceEpoch;
String fmtTime(int t) {
  final d = DateTime.fromMillisecondsSinceEpoch(t);
  return '${pad2(d.hour)}:${pad2(d.minute)}';
}

String fmtDate(int t) {
  final d = DateTime.fromMillisecondsSinceEpoch(t);
  return '${pad2(d.day)}/${pad2(d.month)}/${d.year}';
}

bool sameDay(int a, int b) {
  final x = DateTime.fromMillisecondsSinceEpoch(a), y = DateTime.fromMillisecondsSinceEpoch(b);
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

String todayKey() {
  final d = DateTime.now();
  return '${d.year}-${d.month}-${d.day}';
}

String euro(double v) => v == v.roundToDouble() ? '€${v.toInt()}' : '€${v.toStringAsFixed(2)}';
String euro2(double v) => '€${v.toStringAsFixed(2)}';
String euroIt(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')}€';

String fmtCd(int ms) {
  final t = ms < 0 ? 0 : ms ~/ 1000;
  final h = t ~/ 3600, m = (t % 3600) ~/ 60, x = t % 60;
  return '${h > 0 ? '${pad2(h)}:' : ''}${pad2(m)}:${pad2(x)}';
}

String ago(int t) {
  final m = ((nowMs() - t) / 60000).round();
  if (m < 1) return 'ora';
  if (m < 60) return '$m min';
  if (m < 1440) return '${(m / 60).round()} h';
  return '${(m / 1440).round()} g';
}

final RegExp kEmailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Messaggio in chat.
/// k: text | gift | photo (foto dell'utente) | pcom (commento a una foto di lei) | priv (foto privata di lei)
/// s (solo per i miei): sent | read | pending
class Msg {
  String id;
  String f; // me | her
  String k;
  String? x;
  int t;
  String? s;
  int? g; // indice regalo
  String? imgP; // profilo della foto
  int? imgV; // indice foto
  String? imgB64; // foto inviata dall'utente (jpeg base64)

  Msg({required this.id, required this.f, required this.k, this.x, required this.t, this.s, this.g, this.imgP, this.imgV, this.imgB64});

  Map<String, dynamic> toJson() => {
        'id': id, 'f': f, 'k': k, 't': t,
        if (x != null) 'x': x,
        if (s != null) 's': s,
        if (g != null) 'g': g,
        if (imgP != null) 'imgP': imgP,
        if (imgV != null) 'imgV': imgV,
        if (imgB64 != null) 'imgB64': imgB64,
      };

  factory Msg.fromJson(Map<String, dynamic> j) => Msg(
        id: j['id'] as String? ?? '',
        f: j['f'] as String? ?? 'her',
        k: j['k'] as String? ?? 'text',
        x: j['x'] as String?,
        t: (j['t'] as num?)?.toInt() ?? 0,
        s: j['s'] as String?,
        g: (j['g'] as num?)?.toInt(),
        imgP: j['imgP'] as String?,
        imgV: (j['imgV'] as num?)?.toInt(),
        imgB64: j['imgB64'] as String?,
      );
}

class Conv {
  List<Msg> msgs;
  int unread;
  int t;
  Conv({List<Msg>? msgs, this.unread = 0, int? t})
      : msgs = msgs ?? [],
        t = t ?? nowMs();

  Map<String, dynamic> toJson() => {'msgs': msgs.map((m) => m.toJson()).toList(), 'unread': unread, 't': t};
  factory Conv.fromJson(Map<String, dynamic> j) => Conv(
        msgs: ((j['msgs'] as List?) ?? []).map((e) => Msg.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        unread: (j['unread'] as num?)?.toInt() ?? 0,
        t: (j['t'] as num?)?.toInt() ?? 0,
      );
}

class Visit {
  String id;
  int t;
  bool seen;
  Visit(this.id, this.t, this.seen);
  Map<String, dynamic> toJson() => {'id': id, 't': t, 'seen': seen};
  factory Visit.fromJson(Map<String, dynamic> j) => Visit(j['id'] as String, (j['t'] as num).toInt(), j['seen'] as bool? ?? true);
}

class FeedItem {
  final int t;
  final String pid, title, text, href, cat;
  FeedItem(this.t, this.pid, this.title, this.text, this.href, this.cat);
  Map<String, dynamic> toJson() => {'t': t, 'pid': pid, 'title': title, 'text': text, 'href': href, 'cat': cat};
  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem((j['t'] as num).toInt(), j['pid'] as String,
      j['title'] as String, j['text'] as String, j['href'] as String, j['cat'] as String? ?? 'msg');
}

class Purchase {
  final String id;
  final int cr, b;
  final double p;
  final int t;
  final String m;
  Purchase(this.id, this.cr, this.b, this.p, this.t, this.m);
  Map<String, dynamic> toJson() => {'id': id, 'cr': cr, 'b': b, 'p': p, 't': t, 'm': m};
  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(j['id'] as String, (j['cr'] as num).toInt(),
      (j['b'] as num).toInt(), (j['p'] as num).toDouble(), (j['t'] as num).toInt(), j['m'] as String);
}

class LastPurchase {
  final int cr, b, sent;
  final double p;
  final String m;
  LastPurchase(this.cr, this.b, this.p, this.m, this.sent);
  Map<String, dynamic> toJson() => {'cr': cr, 'b': b, 'p': p, 'm': m, 'sent': sent};
  factory LastPurchase.fromJson(Map<String, dynamic> j) => LastPurchase((j['cr'] as num).toInt(),
      (j['b'] as num).toInt(), (j['p'] as num).toDouble(), j['m'] as String, (j['sent'] as num?)?.toInt() ?? 0);
}

class FirstMsg {
  String id;
  int due;
  bool done;
  int photoAt;
  bool photoDone;
  FirstMsg(this.id, this.due, {this.done = false, this.photoAt = 0, this.photoDone = false});
  Map<String, dynamic> toJson() => {'id': id, 'due': due, 'done': done, 'photoAt': photoAt, 'photoDone': photoDone};
  factory FirstMsg.fromJson(Map<String, dynamic> j) => FirstMsg(j['id'] as String, (j['due'] as num).toInt(),
      done: j['done'] as bool? ?? false, photoAt: (j['photoAt'] as num?)?.toInt() ?? 0, photoDone: j['photoDone'] as bool? ?? false);
}

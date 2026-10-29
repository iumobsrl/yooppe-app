import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/content.dart';
import '../data/profiles.dart';
import '../nav.dart';
import '../services/notifications.dart';
import '../services/tracking.dart';
import '../ui/bridge.dart';
import 'models.dart';

final AppState app = AppState();

typedef QuizResult = ({int n, bool widened, List<Profile> sample});

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  static const _key = 'yooppe_app_v1';
  static const _keyAb = 'yooppe_ab';
  SharedPreferences? _prefs;
  final Random _rand = Random();

  // ---------- Stato persistente ----------
  bool reg = false;
  Map<String, dynamic> user = _defaultUser();
  bool verified = false;
  String welcome = 'todo'; // todo | shown | done
  bool askEmail = false;
  int credits = 0;
  Map<String, bool> likes = {}, favs = {}, plikes = {}, unlocked = {};
  Map<String, Conv> convs = {};
  List<Visit> visitors = [], likers = [];
  Filters filters = const Filters();
  List<Purchase> purchases = [];
  bool recovery = false, promo = false;
  String? daily;
  Map<String, bool> notif = {'msg': true, 'like': true, 'vis': true, 'promo': true, 'news': false};
  Map<String, bool> privacy = {'online': true, 'visible': true};
  bool sub = true;
  LastPurchase? lastPurchase;
  String? returnTo;
  int uid = 1;
  Map<String, String>? quiz;
  String teaser = 't1';
  FirstMsg? firstMsg;
  int welcomeUntil = 0;
  bool welcomeBought = false;
  List<FeedItem> feed = [];
  int pushAskedAt = 0;
  bool? pushGranted;
  int exitBonusUntil = 0;
  String exitShown = '';
  bool starterUsed = false;
  String? autoPk;
  bool autoOn = false;
  bool sentFirst = false;
  int closedAt = 0;
  List<int> closedSteps = [];

  // ---------- Stato di sessione ----------
  String ab = 'A';
  String tab = 'radar';
  bool landingLogin = false;
  bool foreground = true;
  final Set<String> typing = {};
  final Set<String> _typingQ = {};
  int _liveNext = 0, _liveCount = 0;
  bool starterShown = false;
  int busy = 0; // banner/overlay in corso
  void Function(String reason, Profile p)? onPushAsk;
  Timer? _engine, _saveT;

  static Map<String, dynamic> _defaultUser() => {
        'email': '', 'username': '', 'age': 25, 'bio': '', 'rel': 'Single', 'alt': '185 cm', 'peso': '85 kg',
        'corp': 'Snella', 'stud': 'Diploma', 'zod': 'Bilancia', 'bev': 'A volte', 'fum': 'Mai', 'sit': 'Divorziato', 'photo': null,
      };

  // ---------- Persistenza ----------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    ab = _prefs!.getString(_keyAb) ?? (_rand.nextBool() ? 'A' : 'B');
    await _prefs!.setString(_keyAb, ab);
    Tracking.ab = ab;
    final raw = _prefs!.getString(_key);
    Map<String, dynamic> j = {};
    if (raw != null) {
      try {
        j = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    _fromJson(j);
    landingLogin = !reg && (user['email'] as String? ?? '').isNotEmpty;
    final pg = await Notifs.enabled();
    if (pg == true) pushGranted = true;
    if (pg == false && pushGranted == true) pushGranted = false;
    if (closedAt > 0) _onReturn();
    WidgetsBinding.instance.addObserver(this);
    _engine?.cancel();
    _engine = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void save() {
    _saveT?.cancel();
    _saveT = Timer(const Duration(milliseconds: 120), _flushSave);
  }

  void _flushSave() {
    _saveT?.cancel();
    try {
      _prefs?.setString(_key, jsonEncode(_toJson()));
    } catch (_) {}
  }

  static Map<String, bool> _boolMap(dynamic v) =>
      v is Map ? v.map((k, x) => MapEntry(k.toString(), x == true)) : <String, bool>{};
  static Map<String, dynamic> _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  void _fromJson(Map<String, dynamic> j) {
    reg = j['reg'] == true;
    user = {..._defaultUser(), ..._m(j['user'])};
    verified = j['verified'] == true;
    welcome = j['welcome'] as String? ?? 'todo';
    askEmail = j['askEmail'] == true;
    credits = (j['credits'] as num?)?.toInt() ?? 0;
    likes = _boolMap(j['likes']);
    favs = _boolMap(j['favs']);
    plikes = _boolMap(j['plikes']);
    unlocked = _boolMap(j['unlocked']);
    convs = _m(j['convs']).map((k, v) => MapEntry(k, Conv.fromJson(_m(v))));
    visitors = ((j['visitors'] as List?) ?? []).map((e) => Visit.fromJson(_m(e))).toList();
    likers = ((j['likers'] as List?) ?? []).map((e) => Visit.fromJson(_m(e))).toList();
    filters = Filters.fromJson(j['filters'] is Map ? _m(j['filters']) : null);
    purchases = ((j['purchases'] as List?) ?? []).map((e) => Purchase.fromJson(_m(e))).toList();
    recovery = j['recovery'] == true;
    promo = j['promo'] == true;
    daily = j['daily'] as String?;
    notif = {'msg': true, 'like': true, 'vis': true, 'promo': true, 'news': false, ..._boolMap(j['notif'])};
    privacy = {'online': true, 'visible': true, ..._boolMap(j['privacy'])};
    sub = j['sub'] != false;
    lastPurchase = j['lastPurchase'] is Map ? LastPurchase.fromJson(_m(j['lastPurchase'])) : null;
    returnTo = j['returnTo'] as String?;
    uid = (j['uid'] as num?)?.toInt() ?? 1;
    quiz = j['quiz'] is Map ? _m(j['quiz']).map((k, v) => MapEntry(k, v.toString())) : null;
    teaser = j['teaser'] as String? ?? 't1';
    firstMsg = j['firstMsg'] is Map ? FirstMsg.fromJson(_m(j['firstMsg'])) : null;
    welcomeUntil = (j['welcomeUntil'] as num?)?.toInt() ?? 0;
    welcomeBought = j['welcomeBought'] == true;
    feed = ((j['feed'] as List?) ?? []).map((e) => FeedItem.fromJson(_m(e))).toList();
    pushAskedAt = (j['pushAskedAt'] as num?)?.toInt() ?? 0;
    pushGranted = j['pushGranted'] as bool?;
    exitBonusUntil = (j['exitBonusUntil'] as num?)?.toInt() ?? 0;
    exitShown = j['exitShown'] as String? ?? '';
    starterUsed = j['starterUsed'] == true;
    autoPk = j['autoPk'] as String?;
    autoOn = j['autoOn'] == true;
    sentFirst = j['sentFirst'] == true;
    closedAt = (j['closedAt'] as num?)?.toInt() ?? 0;
    closedSteps = ((j['closedSteps'] as List?) ?? []).map((e) => (e as num).toInt()).toList();
  }

  Map<String, dynamic> _toJson() => {
        'reg': reg, 'user': user, 'verified': verified, 'welcome': welcome, 'askEmail': askEmail, 'credits': credits,
        'likes': likes, 'favs': favs, 'plikes': plikes, 'unlocked': unlocked,
        'convs': convs.map((k, v) => MapEntry(k, v.toJson())),
        'visitors': visitors.map((v) => v.toJson()).toList(),
        'likers': likers.map((v) => v.toJson()).toList(),
        'filters': filters.toJson(),
        'purchases': purchases.map((p) => p.toJson()).toList(),
        'recovery': recovery, 'promo': promo, 'daily': daily, 'notif': notif, 'privacy': privacy, 'sub': sub,
        'lastPurchase': lastPurchase?.toJson(), 'returnTo': returnTo, 'uid': uid, 'quiz': quiz, 'teaser': teaser,
        'firstMsg': firstMsg?.toJson(), 'welcomeUntil': welcomeUntil, 'welcomeBought': welcomeBought,
        'feed': feed.map((f) => f.toJson()).toList(),
        'pushAskedAt': pushAskedAt, 'pushGranted': pushGranted, 'exitBonusUntil': exitBonusUntil, 'exitShown': exitShown,
        'starterUsed': starterUsed, 'autoPk': autoPk, 'autoOn': autoOn, 'sentFirst': sentFirst,
        'closedAt': closedAt, 'closedSteps': closedSteps,
      };

  void refresh() => notifyListeners();

  // ---------- Letture ----------
  int get totalUnread => convs.values.fold(0, (a, c) => a + c.unread);
  bool get unseenNotif => visitors.any((v) => !v.seen) || likers.any((v) => !v.seen);
  List<MapEntry<String, Msg>> get pendingList {
    final out = <MapEntry<String, Msg>>[];
    convs.forEach((id, c) {
      for (final m in c.msgs) {
        if (m.s == 'pending') out.add(MapEntry(id, m));
      }
    });
    out.sort((a, b) => a.value.t - b.value.t);
    return out;
  }

  int get pendingCount => pendingList.length;
  bool get canWrite => credits >= Cfg.msgCost || pendingCount == 0;
  bool get exitActive => exitBonusUntil > nowMs();
  bool get welcomeValid => welcomeUntil > nowMs() && !welcomeBought;
  bool get quizDone => quiz != null;
  bool get promoMode => pendingCount > 0 || promo || exitActive;
  Pkg get starter => starterPkg(ab);
  bool get isBusy => tracker.popupOnTop || busy > 0;
  bool isLocked(Profile p, int v) => p.isPriv(v) && unlocked['${p.id}#$v'] != true;
  bool viewingChat(String id) => currentLocation() == 'chat' && currentArg() == id;
  Conv conv(String id) => convs.putIfAbsent(id, () => Conv());
  String nid() => 'm${uid++}';
  int get herMsgCount => convs.values.fold(0, (a, c) => a + c.msgs.where((m) => m.f == 'her').length);

  // ---------- Registrazione / accesso ----------
  void register(String email) {
    final keep = (user['email'] as String? ?? '').toLowerCase() == email.toLowerCase() && convs.isNotEmpty;
    if (!keep) {
      _fromJson({});
      _seed();
      teaser = teaserFromAttribution(Tracking.attr);
      welcomeUntil = nowMs() + Cfg.welcomeHours * 3600000;
      final d = Cfg.firstMsgDelay;
      firstMsg = FirstMsg(teaser, nowMs() + ((d[0] + _rand.nextDouble() * (d[1] - d[0])) * 1000).round());
      _liveNext = 0;
      _liveCount = 0;
      starterShown = false;
    }
    reg = true;
    user['email'] = email;
    if ((user['username'] as String? ?? '').isEmpty) {
      final u = email.split('@').first;
      user['username'] = u.length > 20 ? u.substring(0, 20) : u;
    }
    tab = 'radar';
    save();
    Tracking.track('registration', {'method': 'email', 'teaser': teaser});
    notifyListeners();
  }

  bool login(String email) {
    final e = user['email'] as String? ?? '';
    if (e.isNotEmpty && e.toLowerCase() == email.toLowerCase()) {
      reg = true;
      tab = 'radar';
      save();
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    reg = false;
    landingLogin = true;
    _flushSave();
    Nav.popToRoot();
    notifyListeners();
  }

  Future<void> deleteProfile() async {
    await _prefs?.remove(_key);
    _fromJson({});
    landingLogin = false;
    tab = 'radar';
    Nav.popToRoot();
    notifyListeners();
  }

  void _seed() {
    final now = nowMs();
    const seeds = [['c2', 1], ['c4', 1], ['c11', 1], ['c3', 2], ['c6', 1], ['c9', 1]];
    for (var k = 0; k < seeds.length; k++) {
      final id = seeds[k][0] as String;
      final n = seeds[k][1] as int;
      final t = now - (k + 1) * 4 * 60000;
      final msgs = <Msg>[];
      for (var j = 0; j < n; j++) {
        msgs.add(Msg(id: nid(), f: 'her', k: 'text', x: kFirstMsgs[(k + j) % kFirstMsgs.length], t: t + j * 30000));
      }
      convs[id] = Conv(msgs: msgs, unread: n, t: t + n * 30000);
    }
    const vis = [['c1', 0], ['c5', 0], ['c8', 1], ['c10', 1], ['c7', 1], ['c12', 1]];
    visitors = [for (var k = 0; k < vis.length; k++) Visit(vis[k][0] as String, now - k * 9 * 60000, vis[k][1] == 1)];
    const lik = [['c11', 0], ['c3', 0], ['c6', 1], ['c4', 1], ['c1', 1], ['c5', 1]];
    likers = [for (var k = 0; k < lik.length; k++) Visit(lik[k][0] as String, now - k * 13 * 60000, lik[k][1] == 1)];
  }

  // ---------- Navigazione tra schede ----------
  void setTab(String t) {
    if (tab == 'notifiche' && t != 'notifiche') markNotifSeen(notify: false);
    tab = t;
    notifyListeners();
  }

  void markNotifSeen({bool notify = true}) {
    if (!unseenNotif) return;
    for (final v in visitors) {
      v.seen = true;
    }
    for (final v in likers) {
      v.seen = true;
    }
    save();
    if (notify) notifyListeners();
  }

  void markChatRead(String id) {
    final c = convs[id];
    if (c != null && c.unread > 0) {
      c.unread = 0;
      save();
      notifyListeners();
    }
  }

  // ---------- Mi piace, preferiti ----------
  bool toggleLike(String id) {
    likes[id] = !(likes[id] ?? false);
    save();
    final liked = likes[id]!;
    final p = profileOf(id);
    if (liked) {
      Tracking.track('like', {'to': id});
      toast('Hai messo mi piace a ${p.u}');
      final c = convs[id];
      if ((c == null || c.msgs.isEmpty) && _rand.nextDouble() < 0.6) {
        Timer(const Duration(milliseconds: 4500), () => herWrites(id, 'Ehi, ho visto il tuo mi piace 😊 grazie! Come stai?'));
      }
    }
    notifyListeners();
    return liked;
  }

  void toggleFav(String id) {
    favs[id] = !(favs[id] ?? false);
    save();
    toast(favs[id]! ? 'Aggiunto ai preferiti' : 'Rimosso dai preferiti');
    notifyListeners();
  }

  void togglePhotoLike(String id, int v) {
    final k = '$id#$v';
    plikes[k] = !(plikes[k] ?? false);
    save();
    if (plikes[k]!) {
      toast('Ti piace questa foto');
      Tracking.track('photo_like', {'to': id});
    }
    notifyListeners();
  }

  // ---------- Messaggi ----------
  /// Invia un mio messaggio. Se i crediti non bastano resta "in attesa".
  void pushMine(String id, Msg m, {int cost = Cfg.msgCost}) {
    autoRecharge(cost);
    final c = conv(id);
    m.id = nid();
    m.f = 'me';
    m.t = nowMs();
    if (credits >= cost) {
      credits -= cost;
      m.s = 'sent';
      c.msgs.add(m);
      c.t = m.t;
      Tracking.track('send_message', {'kind': m.k, 'to': id});
      if (!sentFirst) {
        sentFirst = true;
        Tracking.track('first_message', {'to': id});
        Timer(const Duration(milliseconds: 3500), () => maybePushAsk('reply', profileOf(id)));
      }
      _reply(id, m.k);
    } else {
      m.s = 'pending';
      c.msgs.add(m);
      c.t = m.t;
      Tracking.track('message_pending', {'to': id});
      toast('Messaggio in attesa: ricarica i crediti per inviarlo', label: 'Ricarica', onTap: Nav.goRecharge);
    }
    save();
    notifyListeners();
  }

  void _reply(String id, String kind) {
    if (typing.contains(id) || _typingQ.contains(id)) return;
    _typingQ.add(id);
    final r = _rand.nextDouble();
    Timer(const Duration(milliseconds: 900), () {
      typing.add(id);
      notifyListeners();
      Timer(Duration(milliseconds: (1600 + r * 1800).round()), () {
        typing.remove(id);
        _typingQ.remove(id);
        final c = conv(id);
        final pool = kind == 'gift'
            ? kRGift
            : kind == 'pcom'
                ? kRPhoto
                : kind == 'photo'
                    ? kRUserPh
                    : kReplies;
        final herCount = c.msgs.where((m) => m.f == 'her').length;
        final x = identical(pool, kReplies) ? kReplies[herCount % kReplies.length] : pool[(r * pool.length).floor()];
        for (final m in c.msgs) {
          if (m.f == 'me' && m.s == 'sent') m.s = 'read';
        }
        c.msgs.add(Msg(id: nid(), f: 'her', k: 'text', x: x, t: nowMs()));
        c.t = nowMs();
        if (!viewingChat(id)) {
          c.unread++;
          _notifyMsg(id, x);
        }
        save();
        notifyListeners();
        _maybePriv(id);
      });
    });
  }

  void herWrites(String id, String x) {
    final c = conv(id);
    c.msgs.add(Msg(id: nid(), f: 'her', k: 'text', x: x, t: nowMs()));
    c.t = nowMs();
    if (!viewingChat(id)) {
      c.unread++;
      _notifyMsg(id, x);
    }
    save();
    notifyListeners();
  }

  void herPhoto(String id, int v) {
    final c = conv(id);
    c.msgs.add(Msg(id: nid(), f: 'her', k: 'priv', imgP: id, imgV: v, x: kPrivCaptions[v % kPrivCaptions.length], t: nowMs()));
    c.t = nowMs();
    if (!viewingChat(id)) {
      c.unread++;
      final p = profileOf(id);
      _nbanner(p, '${p.u} ti ha inviato una foto privata 🔒', 'Aprila in chat', '/chat/$id', 'msg');
    }
    save();
    notifyListeners();
  }

  int? _nextPriv(String id) {
    final p = profileOf(id);
    final c = conv(id);
    final sent = c.msgs.where((m) => m.k == 'priv').map((m) => m.imgV).toSet();
    for (var i = 0; i < p.priv.length; i++) {
      final v = p.npub + i;
      if (!sent.contains(v)) return v;
    }
    return null;
  }

  void _maybePriv(String id) {
    final p = profileOf(id);
    if (p.priv.isEmpty) return;
    final herN = conv(id).msgs.where((m) => m.f == 'her' && m.k == 'text').length;
    if (herN % 2 != 0) return;
    final v = _nextPriv(id);
    if (v != null) Timer(const Duration(milliseconds: 2600), () => herPhoto(id, v));
  }

  void _notifyMsg(String id, String text) {
    final p = profileOf(id);
    _nbanner(p, '${p.u} ti ha scritto', text, '/chat/$id', 'msg');
  }

  void _logFeed(Profile p, String title, String text, String href, String cat) {
    feed.insert(0, FeedItem(nowMs(), p.id, title, text, href, cat));
    if (feed.length > 60) feed = feed.sublist(0, 60);
  }

  bool _prefOk(String cat) => cat == 'like' ? notif['like'] != false : cat == 'vis' ? notif['vis'] != false : notif['msg'] != false;

  /// Banner in app; con l'app in secondo piano diventa una notifica di sistema.
  void _nbanner(Profile p, String title, String text, String href, String cat) {
    _logFeed(p, title, text, href, cat);
    if (!foreground) {
      if (pushGranted == true && _prefOk(cat)) Notifs.show(title, text, href);
      return;
    }
    if (const ['', 'checkout', 'ok', 'crediti'].contains(currentLocation())) return;
    showBanner(p, title, text, href);
  }

  // ---------- Crediti ----------
  bool autoRecharge(int need) {
    if (autoPk == null || !autoOn || credits >= need) return false;
    final k = findPkg(autoPk!, ab);
    if (k == null) return false;
    credits += k.total;
    purchases.insert(0, Purchase(k.id, k.cr, k.b, k.p, nowMs(), 'Ricarica automatica'));
    Tracking.track('purchase', {'value': k.p, 'currency': 'EUR', 'credits': k.total, 'package': k.id, 'method': 'auto'});
    toast('Ricarica automatica: +${k.total} crediti (${euro2(k.p)})');
    save();
    return true;
  }

  int flushPending() {
    var n = 0;
    final ids = <String>{};
    for (final e in pendingList) {
      if (credits < Cfg.msgCost) break;
      credits -= Cfg.msgCost;
      e.value.s = 'sent';
      e.value.t = nowMs();
      n++;
      ids.add(e.key);
    }
    for (final id in ids) {
      Timer(const Duration(milliseconds: 1500), () => _reply(id, 'text'));
    }
    return n;
  }

  /// false = crediti insufficienti (la UI apre il rate plan)
  bool sendGift(String id, int gi) {
    final g = kGifts[gi];
    autoRecharge(g.c);
    if (credits < g.c) {
      toast('Ti servono ${g.c} crediti per questo regalo');
      return false;
    }
    credits -= g.c;
    final c = conv(id);
    c.msgs.add(Msg(id: nid(), f: 'me', k: 'gift', g: gi, t: nowMs(), s: 'sent'));
    c.t = nowMs();
    Tracking.track('gift_sent', {'to': id, 'gift': g.n, 'credits': g.c});
    save();
    notifyListeners();
    _reply(id, 'gift');
    return true;
  }

  /// false = crediti insufficienti (la UI apre il rate plan)
  bool unlock(String id, int v) {
    final key = '$id#$v';
    if (unlocked[key] == true) return true;
    const cost = Cfg.photoUnlock;
    autoRecharge(cost);
    if (credits < cost) {
      toast('Ti servono $cost crediti per vedere la foto privata');
      Tracking.track('photo_unlock_blocked', {'to': id});
      return false;
    }
    credits -= cost;
    unlocked[key] = true;
    Tracking.track('photo_unlock', {'to': id, 'credits': cost});
    toast('Foto sbloccata 🔓');
    save();
    notifyListeners();
    return true;
  }

  /// Pagamento dimostrativo riuscito.
  void applyPurchase(String pkId, String method, bool auto) {
    final k = findPkg(pkId, ab);
    if (k == null) return;
    credits += k.total;
    purchases.insert(0, Purchase(k.id, k.cr, k.b, k.p, nowMs(), method));
    promo = false;
    recovery = false;
    if (k.id == 'w700') welcomeBought = true;
    if (k.id == 'st50') starterUsed = true;
    exitBonusUntil = 0;
    if (auto) {
      autoPk = k.id;
      autoOn = true;
    }
    final sent = flushPending();
    lastPurchase = LastPurchase(k.cr, k.b, k.p, method, sent);
    Tracking.track('purchase', {
      'value': k.p, 'currency': 'EUR', 'credits': k.total, 'package': k.id, 'method': method,
      'first_purchase': purchases.length == 1, 'auto_recharge': auto,
    });
    save();
    notifyListeners();
  }

  void claimDaily() {
    final today = todayKey();
    if (daily == today) return;
    daily = today;
    credits += Cfg.dailyCredits;
    toast('+${Cfg.dailyCredits} crediti: regalo del giorno ritirato');
    Tracking.track('daily_reward');
    save();
    notifyListeners();
  }

  void activateExitPromo() {
    exitBonusUntil = nowMs() + Cfg.exitPromoMin * 60000;
    Tracking.track('exit_offer_accept');
    save();
    notifyListeners();
    toast('Super Promo 2x1 attiva per ${Cfg.exitPromoMin} minuti');
  }

  // ---------- Onboarding ----------
  void welcomeAnswered() {
    welcome = 'done';
    askEmail = true;
    save();
    notifyListeners();
  }

  QuizResult applyQuiz(Map<String, String> a) {
    final all = allProfiles();
    var f = Filters(g: 'Donne', age: kQuizAge[a['age']] ?? 'Tutte', reg: a['reg'] ?? 'Tutta Italia', foto: 'Tutte');
    var n = all.where((p) => matchesFilters(p, f)).length;
    var widened = false;
    if (n < 6) {
      f = f.copyWith(reg: 'Tutta Italia');
      n = all.where((p) => matchesFilters(p, f)).length;
      widened = true;
    }
    filters = f;
    quiz = Map.of(a);
    save();
    Tracking.track('quiz_completed', {'want': a['want'], 'age': a['age'], 'reg': a['reg']});
    final sample = all.where((p) => matchesFilters(p, f) && p.hasPh).take(4).toList();
    notifyListeners();
    return (n: n, widened: widened, sample: sample);
  }

  void verifyEmail() {
    verified = true;
    askEmail = false;
    credits += Cfg.giftCredits;
    save();
    Tracking.track('email_confirmed');
    notifyListeners();
    Timer(const Duration(seconds: 45), () {
      if (!reg || visitors.any((v) => v.id == 'c9')) return;
      visitors.add(Visit('c9', nowMs(), false));
      save();
      notifyListeners();
      toast('nuvola_rosa ha visitato il tuo profilo', label: 'Vedi', onTap: () => Nav.tab('notifiche'));
    });
  }

  void setFilters(Filters f) {
    filters = f;
    save();
    notifyListeners();
  }

  void widen() => setFilters(const Filters(g: 'Donne', age: 'Tutte', reg: 'Tutta Italia', foto: 'Tutte'));

  // ---------- Profilo utente e impostazioni ----------
  void setUser(Map<String, dynamic> changes) {
    user.addAll(changes);
    save();
    notifyListeners();
  }

  void setPref(String group, String k, bool v) {
    if (group == 'notif') notif[k] = v;
    if (group == 'priv') privacy[k] = v;
    if (group == 'auto') {
      autoOn = v;
      Tracking.track('auto_recharge_toggle', {'on': v});
    }
    save();
    notifyListeners();
  }

  void unsubscribe() {
    sub = false;
    save();
    notifyListeners();
  }

  // ---------- Permesso notifiche ----------
  /// Invito "soft" (nostro pop-up) prima del permesso di sistema.
  void maybePushAsk(String reason, Profile p) {
    if (pushGranted == true) return;
    if (reason != 'settings' && nowMs() - pushAskedAt < Cfg.askAgainDays * 86400000) return;
    if (reason != 'settings' && isBusy) return;
    pushAskedAt = nowMs();
    save();
    onPushAsk?.call(reason, p);
  }

  Future<bool> enablePush() async {
    final ok = await Notifs.request();
    pushGranted = ok;
    Tracking.track('push_permission', {'result': ok ? 'granted' : 'denied'});
    save();
    notifyListeners();
    return ok;
  }

  // ---------- Motore: primo messaggio, foto privata, notifiche dal vivo ----------
  void _tick() {
    if (!reg || !foreground) return;
    final quiet = const ['', 'checkout', 'ok', 'crediti'].contains(currentLocation());
    final fm = firstMsg;
    final now = nowMs();
    if (fm != null && !fm.done) {
      if (now >= fm.due && !isBusy && !quiet) _deliverFirst();
      return;
    }
    if (fm != null && !fm.photoDone && now >= fm.photoAt && !quiet && !isBusy) {
      fm.photoDone = true;
      save();
      final p = profileOf(fm.id);
      if (p.priv.isNotEmpty) herPhoto(fm.id, p.npub);
      return;
    }
    if (welcome == 'done' && quizDone && !quiet && !isBusy && _liveCount < Cfg.liveCap) {
      if (_liveNext == 0) {
        _liveNext = now + Cfg.liveFirst * 1000;
      } else if (now >= _liveNext) {
        liveEvent();
        _liveCount++;
        _liveNext = now + ((Cfg.liveMin + _rand.nextDouble() * (Cfg.liveMax - Cfg.liveMin)) * 1000).round();
      }
    }
  }

  void _deliverFirst() {
    final fm = firstMsg!;
    fm.done = true;
    fm.photoAt = nowMs() + 9000;
    final id = fm.id;
    final x = kFirstBy[quiz?['want'] ?? ''] ?? kFirstBy['']!;
    final c = conv(id);
    c.msgs.add(Msg(id: nid(), f: 'her', k: 'text', x: x, t: nowMs()));
    c.t = nowMs();
    profileOf(id).on = true;
    if (!viewingChat(id)) {
      c.unread++;
      _notifyMsg(id, x);
    }
    save();
    notifyListeners();
    Tracking.track('first_message_received', {'from': id});
  }

  void _bump(List<Visit> list, String id) {
    final i = list.indexWhere((v) => v.id == id);
    if (i >= 0) {
      list[i].t = nowMs();
      list[i].seen = false;
    } else {
      list.add(Visit(id, nowMs(), false));
    }
  }

  void liveEvent() {
    final pool = allProfiles().where((p) => p.hasPh && p.g == 'F').toList();
    final p = pool[_rand.nextInt(pool.length)];
    final r = _rand.nextDouble();
    final href = '/profilo/${p.id}';
    p.on = true;
    final c = convs[p.id];
    if (r < 0.38) {
      _bump(visitors, p.id);
      _nbanner(p, '${p.u} ha visitato il tuo profilo', 'Tocca per vedere chi è', href, 'vis');
    } else if (r < 0.62) {
      _bump(visitors, p.id);
      _nbanner(p, '${p.u} sta guardando le tue foto 👀', 'È online adesso: scrivile', href, 'vis');
    } else if (r < 0.86 || (c != null && c.msgs.isNotEmpty)) {
      _bump(likers, p.id);
      _nbanner(p, 'Piaci a ${p.u} ❤️', 'Ricambia il mi piace', href, 'like');
    } else {
      final x = kFirstMsgs[_rand.nextInt(kFirstMsgs.length)];
      final cc = conv(p.id);
      cc.msgs.add(Msg(id: nid(), f: 'her', k: 'text', x: x, t: nowMs()));
      cc.t = nowMs();
      cc.unread++;
      _notifyMsg(p.id, x);
    }
    Tracking.track('live_event', {'from': p.id});
    save();
    notifyListeners();
  }

  // ---------- App in background / chiusa ----------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!foreground) return;
      foreground = false;
      _scheduleClosed();
      _flushSave();
    } else if (state == AppLifecycleState.resumed) {
      if (foreground) return;
      foreground = true;
      _onReturn();
    }
  }

  String _who(String w) => w == 'teaser' ? teaser : w;

  void _scheduleClosed() {
    if (!reg || pushGranted != true) return;
    closedAt = nowMs();
    closedSteps = [];
    for (var i = 0; i < Cfg.closedSequence.length; i++) {
      final st = Cfg.closedSequence[i];
      final id = _who(st.who);
      final p = profileById(id);
      if (p == null) continue;
      String? title, body, href;
      if (st.kind == 'msg' && notif['msg'] != false) {
        title = '${p.u} ti ha scritto 💌';
        body = st.text ?? 'Nuovo messaggio';
        href = '/chat/$id';
      } else if (st.kind == 'priv' && notif['msg'] != false && _nextPriv(id) != null) {
        title = '${p.u} ti ha inviato una foto privata 🔒';
        body = 'Aprila in chat';
        href = '/chat/$id';
      } else if (st.kind == 'like' && notif['like'] != false) {
        title = 'Piaci a ${p.u} ❤️';
        body = 'Ricambia il mi piace';
        href = '/profilo/$id';
      }
      if (title == null || body == null || href == null) continue;
      Notifs.schedule(900 + i, Duration(seconds: st.after), title, body, href);
      closedSteps.add(i);
    }
    Tracking.track('closed_sequence_scheduled', {'steps': closedSteps.length});
  }

  /// Al rientro: annulla le notifiche non ancora arrivate e mette in app il contenuto di quelle arrivate.
  void _onReturn() {
    if (closedAt == 0) return;
    final elapsed = (nowMs() - closedAt) ~/ 1000;
    for (final i in closedSteps) {
      Notifs.cancel(900 + i);
      if (i >= Cfg.closedSequence.length) continue;
      final st = Cfg.closedSequence[i];
      if (st.after > elapsed) continue;
      final id = _who(st.who);
      final p = profileById(id);
      if (p == null) continue;
      final at = closedAt + st.after * 1000;
      if (st.kind == 'msg') {
        final c = conv(id);
        c.msgs.add(Msg(id: nid(), f: 'her', k: 'text', x: st.text ?? 'Ciao 😊', t: at));
        c.t = at;
        c.unread++;
        _logFeed(p, '${p.u} ti ha scritto 💌', st.text ?? '', '/chat/$id', 'msg');
      } else if (st.kind == 'priv') {
        final v = _nextPriv(id);
        if (v == null) continue;
        final c = conv(id);
        c.msgs.add(Msg(id: nid(), f: 'her', k: 'priv', imgP: id, imgV: v, x: kPrivCaptions[v % kPrivCaptions.length], t: at));
        c.t = at;
        c.unread++;
        _logFeed(p, '${p.u} ti ha inviato una foto privata 🔒', 'Aprila in chat', '/chat/$id', 'msg');
      } else if (st.kind == 'like') {
        _bump(likers, id);
        _logFeed(p, 'Piaci a ${p.u} ❤️', 'Ricambia il mi piace', '/profilo/$id', 'like');
      }
    }
    closedAt = 0;
    closedSteps = [];
    Tracking.track('app_open', {'source': 'return'});
    save();
    notifyListeners();
  }

  // ---------- Strumenti demo ----------
  void demoCredits(int v, {bool reset = false}) {
    credits = reset ? 0 : credits + v;
    final sent = reset ? 0 : flushPending();
    save();
    notifyListeners();
    toast(reset ? 'Crediti azzerati' : '+$v crediti${sent > 0 ? ' · $sent messaggi in attesa inviati' : ''}');
  }

  void demoMsg() {
    const ids = ['c1', 'c5', 'c8', 'c12', 'c7', 'c10'];
    herWrites(ids[_rand.nextInt(ids.length)], kFirstMsgs[_rand.nextInt(kFirstMsgs.length)]);
  }

  void demoVisit() {
    final all = [...kCore, ...kFillers];
    visitors.add(Visit(all[_rand.nextInt(all.length)].id, nowMs(), false));
    likers.add(Visit(kCore[_rand.nextInt(kCore.length)].id, nowMs(), false));
    save();
    notifyListeners();
    toast('Nuova visita e nuovo mi piace', label: 'Vedi', onTap: () => Nav.tab('notifiche'));
  }

  void demoFirst() {
    firstMsg = FirstMsg(teaser, 0);
    save();
    toast('Il primo messaggio arriva tra un attimo');
  }

  void demoExit() {
    exitShown = '';
    exitBonusUntil = 0;
    save();
  }

  void demoStarter() {
    starterShown = false;
    starterUsed = false;
    save();
  }

  void demoWelcome() {
    welcome = 'shown';
    welcomeUntil = nowMs() + Cfg.welcomeHours * 3600000;
    welcomeBought = false;
    save();
    notifyListeners();
  }

  Future<void> demoTestPush() async {
    if (pushGranted != true) {
      final ok = await enablePush();
      if (!ok) {
        toast('Permesso notifiche non concesso');
        return;
      }
    }
    final p = profileOf(teaser);
    await Notifs.schedule(990, const Duration(seconds: 5), '${p.u} ti ha scritto', 'Ciao… ci sei? Ti stavo pensando 😏', '/chat/${p.id}');
    toast("Tra 5 secondi: metti l'app in secondo piano per vederla");
  }
}

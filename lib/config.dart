/// Tutti i valori modificabili dell'app (stessi della sezione CONFIG della web app).
class Cfg {
  static const String appName = 'Yooppe';

  static const int msgCost = 20; // crediti per messaggio / foto / commento / proposta
  static const int giftCredits = 40; // crediti in regalo alla conferma email
  static const int photoUnlock = 30; // crediti per sbloccare una foto privata
  static const List<int> firstMsgDelay = [10, 20]; // secondi prima del primo messaggio
  static const int welcomeHours = 24; // durata offerta di benvenuto
  static const int rateplanIdleSec = 15; // inattività sul rate plan prima dell'offerta "prima ricarica"
  static const int exitPromoMin = 30; // durata Super Promo 2x1 riattivata all'uscita dal rate plan
  static const int dailyCredits = 10;
  static const int askAgainDays = 3; // giorni prima di riproporre l'invito alle notifiche

  // Notifiche "dal vivo" mentre l'app è aperta
  static const int liveFirst = 25;
  static const int liveMin = 35;
  static const int liveMax = 70;
  static const int liveCap = 8;

  /// Notifiche ad app chiusa: partono quando l'utente mette l'app in background.
  /// Quelle non ancora arrivate si annullano se la riapre.
  /// who: 'teaser' = profilo della landing, oppure un id profilo (es. 'c2').
  static const List<ClosedStep> closedSequence = [
    ClosedStep(after: 30, kind: 'msg', who: 'teaser', text: 'Ehi… sei andato via proprio adesso? 😏'),
    ClosedStep(after: 60, kind: 'priv', who: 'teaser'),
    ClosedStep(after: 90, kind: 'like', who: 'c2'),
  ];
}

class ClosedStep {
  final int after;
  final String kind; // msg | priv | like
  final String who;
  final String? text;
  const ClosedStep({required this.after, required this.kind, required this.who, this.text});
}

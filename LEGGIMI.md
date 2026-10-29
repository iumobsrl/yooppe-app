# Yooppe – app Flutter

Porting nativo (Android + iOS) della web app `yooppe-webapp`. È la stessa demo navigabile: profili fittizi, risposte simulate, pagamento dimostrativo. Testi, prezzi, profili, foto Artlist e logica sono quelli della web app.

## Avviarla la prima volta

Serve Flutter 3.24 o successivo (`flutter --version`). Per iPhone serve anche Xcode, per Android Android Studio (o almeno l'SDK Android).

```bash
cd yooppe_app
python3 tool/configura_piattaforme.py   # genera android/ e ios/ e applica permessi e icona
flutter run                             # con un telefono collegato o un simulatore aperto
```

Lo script si può rilanciare quando vuoi. Prima del primo lancio puoi cambiare l'identificativo dell'app (`ORG = 'com.yooppe'`) in cima allo script.

> Il codice è stato scritto e controllato nella sintassi, ma non compilato (l'ambiente in cui è stato preparato non aveva Flutter). Se `flutter run` segnala errori, incollali in Claude Code dalla cartella del progetto: di solito sono correzioni di una riga.

## Dove cambiare le cose

| Cosa | File |
|---|---|
| Costo messaggi, crediti in regalo, tempi del primo messaggio, notifiche dal vivo, sequenza ad app chiusa | `lib/config.dart` |
| Profili, testi, risposte, proposte, regali, pacchetti e prezzi, quiz, FAQ | `lib/data/content.dart` |
| Foto (URL Artlist) | `lib/data/photos.dart` |
| Colori | `lib/ui/theme.dart` |
| Logo e icona | `assets/images/logo.png`, `assets/icon/` (poi `dart run flutter_launcher_icons`) |
| Tracciamento | `lib/services/tracking.dart` |

## Corrispondenza con la web app

| Web app | App |
|---|---|
| `#/` landing con teaser | `ui/screens/landing.dart` |
| `#/radar`, `#/chat`, `#/notifiche`, `#/me` | schede in `ui/screens/home_shell.dart` |
| `#/profilo/:id` + galleria | `ui/screens/profile_screen.dart`, `ui/modals.dart` |
| `#/chat/:id` | `ui/screens/chat_screen.dart` |
| `#/crediti`, `#/checkout/:pk`, `#/ok` | `ui/screens/payments.dart` |
| pop-up (benvenuto, quiz, email, 2x1, prima ricarica…) | `ui/modals.dart` |
| motore (primo messaggio, foto privata, eventi dal vivo) | `state/app_state.dart` |
| `localStorage` | `shared_preferences` |
| Profilo → Strumenti demo | stesso posto, stesse scorciatoie |

## Notifiche

- **App aperta:** banner in alto (tocca per aprire, scorri su per chiudere) e storico in *Attività recenti*.
- **App in background o chiusa:** quando l'utente esce dall'app vengono programmate sul telefono le notifiche di `Cfg.closedSequence` (30 s messaggio, 60 s foto privata, 90 s mi piace). Se rientra prima, quelle non ancora arrivate si annullano. Il contenuto delle notifiche arrivate compare in chat.
- Non servono OneSignal né Cloudflare: è tutto locale. Il permesso viene chiesto dopo il primo messaggio inviato ("Vuoi sapere subito quando ti risponde?"), dalla scheda Notifiche, dopo un pagamento o da Gestione notifiche.
- Su Android le notifiche programmate possono arrivare con qualche secondo o minuto di ritardo se il telefono è in risparmio energetico: è normale.
- Per provarle velocemente: Profilo → Strumenti demo → *Prova una notifica sul telefono*, poi metti l'app in background.

## Cosa resta da fare per una versione vera

- **Pagamenti:** su App Store e Google Play i crediti digitali vanno venduti con In-App Purchase / Google Play Billing (pacchetto `in_app_purchase`). Il checkout con carta e wallet incluso qui è solo dimostrativo.
- **Backend:** registrazione, crediti, conversazioni e risposte degli operatori oggi sono simulati in locale (`state/app_state.dart`). Le funzioni `pushMine`, `applyPurchase`, `verifyEmail`… sono i punti dove chiamare le vostre API.
- **Notifiche da eventi reali** (es. un operatore risponde ad app chiusa): servono push remote (Firebase Cloud Messaging o OneSignal SDK per Flutter). La sequenza locale resta utile come re-engagement.
- **Tracciamento e attribuzione:** collegare Adjust o Meta App Events in `Tracking.sinks` (vedi `main.dart`). I parametri dell'annuncio (che sul web arrivavano dall'URL) in app arrivano da deep link / install referrer: impostali in `Tracking.attr` per avere anche il profilo teaser giusto per creatività.
- **Store:** le app di incontri vengono esaminate con attenzione. Se i profili sono gestiti da operatori o sono fittizi, va dichiarato chiaramente nell'app e nella scheda dello store: è un motivo frequente di rifiuto.

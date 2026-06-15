# Target Point

Target Point je Flutter aplikacija za pracenje pikado meceva. Pocetni ekran je pikado scorer s velikim klikabilnim dartboardom: korisnik odabere polje koje je pogodio, a aplikacija automatski izracuna rezultat i vodi trenutni turn.

## Trenutne funkcije

- Klikabilni dartboard s poljima `single`, `double`, `triple`, `25`, `BULL` i `MISS`.
- X01 nacin igre s pocetnim rezultatom `301`, `501` ili `701`.
- Count up nacin igre.
- Pravila zavrsetka: `Single`, `Double` i `Master`.
- Preset igraci: `Marko`, `Luka`, `Borna`.
- Tri bacanja po turnu.
- Automatski prijelaz na sljedeceg igraca nakon treceg bacanja.
- `Undo`, `Miss` i `Save turn` akcije.
- Bust logika za X01.
- Osnovni prosjek po igracu.
- Korisnicki ili guest profil odvojen od igraca u mecu.
- Player group presets za brzi odabir ekipe.
- Dijeljenje player grupa s pratiteljima.
- Following lista korisnika.
- Google login preko Firebase Auth na Android/iOS platformama.
- Rucni izbor teme: `System`, `Light`, `Dark`.
- Lokalizacija prema jeziku sustava i rucni izbor jezika.
- Podrzani jezici: English, Hrvatski, Deutsch, Espanol, Francais, Italiano, Japanese i Chinese/Mandarin.
- Responsive mobile i desktop layout.
- Automatski light/dark mode prema postavkama sustava.
- Platformske ikone za Android, iOS, macOS, web i Windows.
- Activity hub dostupan iz glavnog pikado ekrana: sportovi, drustvene igre i party natjecanja kao Darts, Table Tennis, Tennis, Football, Billiards, Snooker, Bowling, Badminton, Squash, Basketball, Volleyball, Handball, Golf, Hockey, Baseball, Cricket, Rugby, Foosball, Chess, Catan, Monopoly, Risk, Uno, Poker, Blackjack, Scrabble, Yahtzee, Dominoes, Dixit, Ticket to Ride, Carcassonne, Clue, Trivia, Beer Pong, Padel i Pickleball.
- Korisnik moze napraviti custom aktivnost s vlastitim pravilima i sudionicima.

## Pokretanje

Preduvjet je instaliran Flutter SDK.

```powershell
flutter pub get
flutter run
```

Za web preview:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5454
```

## Provjere

```powershell
flutter analyze
flutter test
```

## Struktura projekta

- `lib/main.dart` - glavna aplikacija, navigacija i responsive shell.
- `lib/models` - modeli i state controller za igru, korisnika, player grupe i povijest.
- `lib/l10n` - lokalizacijski sloj i prijevodi aplikacije.
- `lib/screens` - glavni ekrani aplikacije, ukljucujuci game hub i pikado tok.
- `lib/services` - integracije za auth i cloud spremanje.
- `lib/widgets` - ponovni UI elementi poput dartboarda i dialoga.
- `test/widget_test.dart` - widget testovi za unos pogotka, undo, mobile layout i dark mode.
- `android/app/src/main/res/mipmap-*` - Android launcher ikone.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset` - iOS app ikone.
- `macos/Runner/Assets.xcassets/AppIcon.appiconset` - macOS app ikone.
- `web/icons` i `web/favicon.png` - web i PWA ikone.
- `windows/runner/resources/app_icon.ico` - Windows app ikona.
- `android/app/google-services.json` - Android Firebase config za `com.luksa.targetpoint`.
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config za `com.luksa.targetpoint`.

## Trenutna ogranicenja

- Firebase config je dodan za Android i iOS; web, Windows, macOS i Linux jos nemaju Firebase config.
- Guest podaci se jos ne spremaju nakon zatvaranja aplikacije.
- Player grupe i following imaju lokalni session fallback dok cloud nije spojen.
- Email/password login jos nije implementiran.
- Sve aktivnosti osim Darts su trenutno pripremljeni kao dodatni moduli bez scoring logike.
- Custom aktivnosti se trenutno pamte samo u otvorenoj sesiji aplikacije.
- Dio vrlo specificnih opisa planiranih igara jos koristi fallback tekst dok se ne uvede detaljna scoring logika za svaku igru.

## Sljedeci koraci

- Spojiti Firebase config za web i desktop platforme ako budu potrebne.
- Dodati lokalno trajno spremanje za guest mode.
- Dodati ucitavanje player grupa i following liste iz Realtime Databasea.
- Dodati email/password login.
- Dodati detaljniju statistiku i cloud sync povijesti meceva.
- Dodati scoring pravila za igre iz game huba.
- Spremiti custom aktivnosti i sudionike u Firebase.
- Prosiriti prijevode za sve buduce scoring ekrane kada se pojedine igre implementiraju.

# Game hub

Game hub je Flutter aplikacija za pracenje natjecanja, rezultata i grupa igraca u stvarnom vremenu. Aplikacija trenutno najdetaljnije podrzava pikado, a ukljucuje i sportske, drustvene, kartaske i custom aktivnosti.

## Glavne funkcije

- Pikado scorer s klikabilnom dartboard plocom.
- Rucni unos strelica, npr. `D6`, `T18`, `12`.
- Provjera nevaljanih pikado bodova, tako da se nemoguci hitovi ne priznaju.
- X01 i Count up nacin igre za pikado.
- Pravila izlaza: `Single`, `Double` i `Master`.
- Prikaz preporuke za izlaz kada igrac moze zavrsiti leg.
- Blinkanje ciljanog polja na ploci kada postoji preporuceni izlaz.
- Leaderboard s pobjedama, prosjekom, bacanjima, 180s, 140+, 100+, najboljim krugom i najboljim brojem.
- Povijest meceva i bacanja.
- Sportski i drustveni preseti: stolni tenis, tenis, nogomet, biljar, sah, Catan, kartaske igre, party natjecanja i druge aktivnosti.
- Custom aktivnost koju korisnik moze dodati sam.
- Google login preko Firebase Auth.
- Guest mode za lokalno koristenje bez spremanja u cloud.
- Profil korisnika s imenom i profilnom slikom.
- Tema se automatski prilagodava sustavu, uz rucni izbor svijetle ili tamne teme.
- Jezik se automatski prilagodava sustavu, uz rucni izbor jezika.
- Podrzani jezici: English, Hrvatski, Deutsch, Espanol, Francais, Italiano, Japanese i Chinese/Mandarin.
- Responsive mobile, desktop i web layout.

## Grupe i sinkronizacija

Korisnik moze napraviti ili se pridruziti grupi po sportu/igri. Svaka grupa je odvojena po aktivnosti, tako da se igraci i rezultati ne mijesaju izmedu sportova.

Grupe podrzavaju:

- 3 slova + 3 broja kao kod grupe.
- QR kod za pridruzivanje.
- Kopiranje koda grupe.
- Vise grupa po korisniku.
- Listu grupa sa searchom i filterima: najnovije, popularno i A-Z.
- Detail screen grupe s QR kodom, game mode postavkama i lineupom igraca.
- Realtime sinkronizaciju rezultata preko Firebase Realtime Database.
- Leave za clana grupe.
- Delete group samo za admina grupe.
- Potvrdu prije brisanja grupe.
- Import statistike iz druge grupe.
- Odabir zeli li se statistika nadodati ili zamijeniti trenutnu statistiku.
- Device mode:
  - `Own device` - svaki prijavljeni igrac upisuje samo svoj red.
  - `Shared devices` - bilo koji clan grupe moze upisati red trenutnog igraca.
  - `Admin device` - samo admin upisuje bacanja i bodove za sve.

Admin grupe moze:

- dodavati igrace,
- brisati lokalne/manual igrace,
- mijenjati redoslijed bacanja,
- mijenjati postavke grupe,
- importati statistiku,
- obrisati cijelu grupu.

## Firebase struktura

Glavni realtime zapis grupe:

```text
sessions/{sessionId}
```

Popis grupa koje korisnik vidi:

```text
userSessions/{uid}/{sessionId}
```

Privatni profil korisnika:

```text
users/{uid}/profile
```

Javni profil za prikaz drugim korisnicima:

```text
publicUsers/{uid}
```

Rezervirana imena grupa po sportu:

```text
sportGroupNames/{sportId}/{normalizedName}
```

## Firebase pravila

Realtime Database rules moraju dopustiti:

- prijavljenim korisnicima citanje `sessions`,
- clanovima grupe sinkronizaciju rezultata,
- adminu/owneru brisanje svoje grupe,
- svakom korisniku pisanje samo u svoj `userSessions`,
- svakom korisniku pisanje samo u svoj privatni profil.

Ako admin ne moze obrisati grupu ili clanovi ne vide realtime promjene, prvo provjeri rules za `sessions`.

## Pokretanje lokalno

```powershell
flutter pub get
flutter run
```

## Provjere

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Android App Bundle za Google Play:

```powershell
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Web build za Cloudflare Pages

Web verzija se builda u `build/web`:

```powershell
flutter build web --release
```

Za Cloudflare Pages koristi:

- Build command: `bash tools/cloudflare_build.sh`
- Build output directory: `build/web`

U `web/` su dodani `_headers` i `_redirects`, pa ih Flutter kopira u `build/web` tijekom web builda.

Cloudflare Pages environment variables:

- `FIREBASE_WEB_API_KEY`
- `FIREBASE_WEB_APP_ID`
- `FIREBASE_WEB_MESSAGING_SENDER_ID`
- `FIREBASE_WEB_PROJECT_ID`
- `FIREBASE_WEB_AUTH_DOMAIN`
- `FIREBASE_WEB_STORAGE_BUCKET`
- `FIREBASE_WEB_MEASUREMENT_ID`
- `GOOGLE_WEB_CLIENT_ID`

## Identitet aplikacije

- App name: `Game hub`
- Flutter package name: `game_hub`
- Android package/application ID: `com.luksa.gamehub`
- iOS bundle ID: `com.luksa.gamehub`
- Trenutna verzija: `1.0.5+5`

## Struktura projekta

- `lib/main.dart` - glavna aplikacija, tema, lokalizacija i shell.
- `lib/models` - modeli, game settings i `GameStateController`.
- `lib/screens` - play, scoreboard, settings, history, account i game hub ekrani.
- `lib/services` - Firebase Auth, Google Sign-In i Realtime Database integracija.
- `lib/widgets` - dartboard, avatar i zajednicki UI widgeti.
- `lib/l10n` - prijevodi i runtime fallbackovi.
- `test/widget_test.dart` - widget i model testovi.
- `web/` - web manifest, ikone, headers i redirects.
- `tools/` - pomocne skripte za build/deploy.

## Trenutna ogranicenja

- Email/password login jos nije implementiran.
- Guest podaci su lokalni i ne spremaju se u Firebase.
- Pikado ima najdetaljniju logiku; ostale igre imaju sport-specific evente i leaderboard, ali jos nemaju puna pravila svake igre.
- Neki jezici imaju fallback prijevode dok se ne dovrsi puna rucna lokalizacija.

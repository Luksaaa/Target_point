# Target Point

Target Point je Flutter aplikacija za pracenje natjecateljskih aktivnosti. Pocetni ekran je Darts scorer, a iz aktivnosti se mogu otvoriti i druge igre poput stolnog tenisa, biljara, saha, Catana i custom natjecanja.

## Trenutne funkcije

- Pikado scorer s klikabilnim dartboardom.
- X01 i Count up nacin igre za pikado.
- Pravila zavrsetka: `Single`, `Double` i `Master`.
- Nema hardkodiranih laznih igraca.
- Korisnik moze dodati lokalne igrace u aktivni leaderboard.
- Google login preko Firebase Auth.
- Nakon Google logina korisnik se dodaje u aktivni leaderboard pod svojim profilom.
- Aktivni leaderboard se sinkronizira u Firebase Realtime Database po igri.
- Ostale igre imaju genericki leaderboard s bodovima `-1`, `+1`, `+5` i `Next`.
- Activity hub s presetima za sportove, drustvene igre, kartaske igre i custom natjecanja.
- Korisnik moze napraviti custom aktivnost s pravilima i sudionicima.
- Rucni izbor teme: `System`, `Light`, `Dark`.
- Automatski light/dark mode prema postavkama sustava.
- Lokalizacija prema jeziku sustava i rucni izbor jezika.
- Podrzani jezici: English, Hrvatski, Deutsch, Espanol, Francais, Italiano, Japanese i Chinese/Mandarin.
- Responsive mobile i desktop layout.

## Firebase podaci

Realtime sessioni se spremaju po session ID-u:

```text
sessions/{sessionId}
```

Popis sessiona koje korisnik vidi sprema se pod:

```text
userSessions/{uid}/{sessionId}
```

Privatni korisnicki profil sprema se pod:

```text
users/{uid}/profile
```

Javni profil za pronalazak i povezivanje korisnika sprema se pod:

```text
publicUsers/{uid}
```

## Pokretanje

```powershell
flutter pub get
flutter run
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

Za Google login i Realtime Database na webu dodaj ove Cloudflare Pages environment variables iz Firebase Web app configa:

- `FIREBASE_WEB_API_KEY`
- `FIREBASE_WEB_APP_ID`
- `FIREBASE_WEB_MESSAGING_SENDER_ID`
- `FIREBASE_WEB_PROJECT_ID`
- `FIREBASE_WEB_AUTH_DOMAIN`
- `FIREBASE_WEB_STORAGE_BUCKET`
- `GOOGLE_WEB_CLIENT_ID`

## Provjere

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

## Struktura projekta

- `lib/main.dart` - glavna aplikacija, navigacija i shell.
- `lib/models` - modeli i `GameStateController`.
- `lib/screens` - gameplay, leaderboard, settings, account i activity hub ekrani.
- `lib/services` - Firebase Auth i Realtime Database integracija.
- `lib/widgets` - dartboard i zajednicki widgeti.
- `lib/l10n` - prijevodi.
- `test/widget_test.dart` - widget i model testovi.

## Trenutna ogranicenja

- Email/password login jos nije implementiran.
- Guest podaci se ne spremaju nakon zatvaranja aplikacije.
- Detaljna pravila bodovanja postoje samo za pikado.
- Ostale igre trenutno koriste genericki leaderboard.
- Custom aktivnosti se jos ne spremaju trajno u Firebase.
- Firebase web konfiguracija jos nije dodana, pa web build radi kao aplikacija, ali Google login/realtime sync na webu trazi dodatni Firebase Web app config.
- Nisu svi user-facing tekstovi prevedeni na sve jezike; detalji su u `docs/localization_audit.md`.

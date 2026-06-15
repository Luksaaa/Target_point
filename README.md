# Target Point

Target Point je Flutter aplikacija za pracenje pikado meceva. Glavni ekran koristi veliki klikabilni dartboard: korisnik odabere polje koje je pogodio, a aplikacija automatski izracuna rezultat i vodi trenutni turn.

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
- Google login preko Firebase Auth kada je Firebase konfiguriran.
- Rucni izbor teme: `System`, `Light`, `Dark`.
- Responsive mobile i desktop layout.
- Automatski light/dark mode prema postavkama sustava.
- Platformske ikone za Android, iOS, macOS, web i Windows.

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
- `lib/screens` - glavni ekrani aplikacije.
- `lib/services` - integracije za auth i cloud spremanje.
- `lib/widgets` - ponovni UI elementi poput dartboarda i dialoga.
- `test/widget_test.dart` - widget testovi za unos pogotka, undo, mobile layout i dark mode.
- `android/app/src/main/res/mipmap-*` - Android launcher ikone.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset` - iOS app ikone.
- `macos/Runner/Assets.xcassets/AppIcon.appiconset` - macOS app ikone.
- `web/icons` i `web/favicon.png` - web i PWA ikone.
- `windows/runner/resources/app_icon.ico` - Windows app ikona.

## Trenutna ogranicenja

- Firebase projekt jos mora biti konfiguriran kroz platform-specific config datoteke.
- Guest podaci se jos ne spremaju nakon zatvaranja aplikacije.
- Player grupe i following imaju lokalni session fallback dok cloud nije spojen.
- Email/password login jos nije implementiran.

## Sljedeci koraci

- Spojiti Firebase config datoteke za Android, iOS, web i ostale platforme.
- Dodati lokalno trajno spremanje za guest mode.
- Dodati ucitavanje player grupa i following liste iz Realtime Databasea.
- Dodati email/password login.
- Dodati detaljniju statistiku i cloud sync povijesti meceva.

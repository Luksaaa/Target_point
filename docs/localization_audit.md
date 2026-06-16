# Localization Audit

Status: not complete.

The app already supports these locales in `AppLocalizations.supportedLocales`:

- English
- Croatian
- German
- Spanish
- French
- Italian
- Japanese
- Chinese/Mandarin

However, not every screen and option is currently translated. Several UI labels are still hardcoded in English.

## Hardcoded Areas Found

- `lib/main.dart`
  - navigation labels
  - tooltips
  - new match dialog
- `lib/screens/account_screen.dart`
  - profile form labels
  - login buttons
  - following labels
  - about/version labels
- `lib/screens/history_screen.dart`
  - match history empty state and labels
- `lib/screens/play_screen.dart`
  - save turn dialog
  - darts action buttons
  - generic scoring buttons
  - quick leaderboard labels
- `lib/screens/scoreboard_screen.dart`
  - leaderboard labels
  - darts stat labels
  - throw history labels
- `lib/screens/settings_screen.dart`
  - add player dialog
  - restart dialog
  - game mode labels
  - lineup labels
- `lib/widgets/profile_dialog.dart`
  - profile and stats labels
- `lib/widgets/search_dialog.dart`
  - search hint
  - empty state
  - match recap labels

## Current Conclusion

The app has a localization system, but full translation coverage is not finished. Before release, every user-facing string should be moved into `lib/l10n/app_localizations.dart` and translated for every supported locale.

## Recommended Next Step

Replace hardcoded labels screen by screen, starting with:

1. `main.dart`
2. `play_screen.dart`
3. `scoreboard_screen.dart`
4. `settings_screen.dart`
5. `account_screen.dart`
6. shared dialogs/widgets

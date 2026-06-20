# Game hub Project Prompt

Use this document to understand the Flutter project before making changes. The user communicates in Croatian, but source code, identifiers, labels, and comments should stay in English unless the file is localization or user-facing documentation.

## Product Direction

Game hub is a real-time competitive scoring app. Darts is the most complete game, but the product direction is broader: every sport, board game, card game, party challenge, and custom activity should eventually support groups, live scoring, history, and leaderboards.

The app must not rely on fake default players. A signed-in user is represented by their real Firebase profile. Guest mode is allowed, but guest data is local-only and should not be treated as a real account.

## Current Architecture

- `GameHubApp` owns theme and locale state.
- `RootScreen` starts with Darts and opens the game hub/activity picker.
- `SportMatchScreen` owns one `GameStateController` per opened game.
- `GameStateController` receives `gameId` and `gameName`.
- `GameStateController` owns players, current turn, group state, settings, sport events, history, auth state, and realtime sync.
- `AuthRepository` owns Firebase Auth, Google Sign-In, and Realtime Database reads/writes.
- `AppLocalizations` provides translations and runtime cleanup/fallbacks for text.

## Important Files

- `lib/main.dart` - app shell, theme, locale, root navigation.
- `lib/models/game_state_controller.dart` - core match/group/game state.
- `lib/models/player_score.dart` - player score, turns, stats.
- `lib/models/sport_game.dart` - game presets and activity definitions.
- `lib/models/game_settings.dart` - darts settings and group device mode enums.
- `lib/services/auth_repository.dart` - Firebase Auth and Realtime Database access.
- `lib/screens/play_screen.dart` - gameplay UI for darts and non-darts activities.
- `lib/screens/scoreboard_screen.dart` - leaderboard and stats.
- `lib/screens/settings_screen.dart` - group list, group detail, QR, game settings, lineup.
- `lib/screens/game_hub_screen.dart` - sport/activity selection and custom activities.
- `lib/screens/account_screen.dart` - profile, login, theme, language, social settings.
- `lib/screens/history_screen.dart` - match and throw history.
- `lib/widgets/dartboard.dart` - interactive darts board and checkout highlight.
- `lib/l10n/app_localizations.dart` - translations, sport action/stat labels, cleanup helpers.

## Realtime Model

Realtime groups sync through Firebase Realtime Database:

```text
sessions/{sessionId}
userSessions/{uid}/{sessionId}
users/{uid}/profile
publicUsers/{uid}
sportGroupNames/{sportId}/{normalizedName}
```

`sessions/{sessionId}` is the source of truth for a live group. It includes:

- `id`
- `groupCode`
- `sessionName`
- `gameId`
- `gameName`
- `sportId`
- `sportName`
- `deviceMode`
- `checkoutStrategy`
- `hostUserId`
- `ownerUserId`
- `updatedByUserId`
- `clientUpdatedAt`
- `clientRevision`
- `status`
- `members`
- `settings`
- `players`
- `participants`
- `sportEvents`
- `matchHistory`
- `currentTurn`
- `currentPlayerIndex`
- `matchMessage`

`userSessions/{uid}/{sessionId}` is a per-user index used to show the group list. It is not the group source of truth.

`sportGroupNames/{sportId}/{normalizedName}` prevents duplicate group names per sport.

## Group Rules

- A user can be in multiple groups at the same time.
- Groups are scoped per sport/game; players and scores must not overlap between different sports or different groups.
- Group codes use three letters and three numbers.
- QR join uses the group code/session ID and should route through the same join flow as manual join.
- Group list lives in the Settings tab and opens a separate group detail screen.
- The group detail screen shows QR code, copy code, leave/delete actions, game settings, device mode, and player lineup.
- A member can leave a group.
- Only the group admin/owner can delete a group.
- Deleting a group removes `sessions/{sessionId}`. Active clients watching that session must clear the deleted group locally.
- Do not try to force-delete other users' private `userSessions` unless rules explicitly allow it. Each client should clean its own stale index when it sees the session is deleted.

## Admin Permissions

The group admin can:

- add players,
- remove manual/non-owner players,
- reorder lineup,
- change game settings,
- change device mode,
- import stats from another group,
- delete the group.

The admin should not always be forced to the first lineup position. Throw order is controlled by lineup order.

## Device Modes

`GroupDeviceMode.ownDevice`

- Each signed-in player can enter only their own turn.
- If it is not the user's turn, show a pill/snackbar-style message from the top.

`GroupDeviceMode.sharedDevices`

- Any group member can enter the current player's turn.

`GroupDeviceMode.adminDevice`

- Only the group admin can enter throws and scores for everyone.

## Darts Behavior

Darts uses:

- clickable `Dartboard`,
- manual dart input,
- `DartHit`,
- `GameMode.x01`,
- `GameMode.countUp`,
- `OutRule`,
- `CheckoutStrategy`,
- three-dart turns,
- bust logic,
- winner handling,
- persistent wins,
- match history,
- throw history,
- realtime turn order,
- checkout recommendation,
- checkout target highlight/blink on the dartboard.

Manual dart input rules:

- Accept examples like `D6`, `d6`, `T18`, `t18`, `S20`, `20`, `25`, `50`.
- Convert valid numeric scores to a valid dart label when possible, e.g. `54` becomes `T18`.
- Reject impossible one-dart scores, e.g. `37`.
- Do not accept values that cannot exist on a dartboard.

New match/reset:

- Must reset the current match state.
- Must not erase persistent wins/stat history that should survive between matches.
- Must ask for confirmation before resetting during an active game.

## Non-Darts Games

Other games currently use sport-specific actions and event timelines. They are not full rule engines yet.

Common behavior:

- Show a live leaderboard.
- Record sport events with player, action, score delta, total score, and timestamp.
- Persist events in `sportEvents`.
- Show event history in the History tab, not inside Scores.
- Keep controls readable on mobile; avoid tiny labels in action buttons.

Do not show darts-specific controls for non-darts games.

## Account And Profile

- The top-right avatar represents `currentUser`, not the current player.
- Google login should persist until the user signs out or the app is removed.
- Guest mode should show local-only behavior and should clear cloud/group data.
- Profile photo should use the Firebase/Google photo URL where possible; do not store base64 image data in Realtime Database.
- Profile display name and photo should sync through:
  - `users/{uid}/profile`
  - `publicUsers/{uid}`

## Theme And Localization

- Theme follows system by default.
- User can choose Light or Dark manually.
- Do not show a separate "System" selectable label in UI if the design calls for automatic detection; still preserve system behavior internally.
- Language follows system by default.
- User can choose supported languages manually.
- Every user-facing string should go through `AppLocalizations`.
- If a string appears garbled, add or fix it in `_safeStrings`, `_safeSportActions`, `_safeSportStats`, `_gameNameOverrides`, or `_modeLabelOverrides`.
- Supported locales: `en`, `hr`, `de`, `es`, `fr`, `it`, `ja`, `zh`.

## Design Direction

- The UI should feel clean, modern, and mobile-first.
- Avoid heavy boxes around every section.
- Prefer separators, spacing, and clear hierarchy over stacked bordered cards.
- Keep buttons large enough to read and tap.
- Keep desktop/web centered with a max content width instead of stretching full-screen.
- Use real profile photos when available.
- Use icons that match the feature, especially for theme, language, group actions, and sport actions.

## Firebase Rules Expectations

Rules should allow:

- authenticated users to read `sessions`,
- group members to update their active group,
- group owner/admin to delete their group,
- users to write only their own `userSessions`,
- users to write only their own private profile,
- authenticated users to read `publicUsers`.

If delete group fails with permission denied, check `sessions/{sessionId}` write/delete rules first.

## Build And Test

Run before finishing changes:

```powershell
flutter analyze
flutter test
```

For Android debug build verification:

```powershell
flutter build apk --debug
```

For Google Play:

```powershell
flutter build appbundle --release
```

The app bundle is created at:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Current Identity

- App name: `Game hub`
- Flutter package name: `game_hub`
- Android package/application ID: `com.luksa.gamehub`
- iOS bundle ID: `com.luksa.gamehub`
- Current version: `1.0.5+5`

## Known Limitations

- Email/password login is not implemented.
- Guest data is local-only.
- Darts is the only game with detailed scoring and checkout logic.
- Non-darts games still need full rule engines if exact sport rules become required.
- Some localization coverage may still need manual review on every screen.

# Target Point LLM Orientation Prompt

Use this document to understand the current Flutter project before making changes. The user communicates in Croatian, but source code, class names, widget names, labels, comments, and technical identifiers should stay in English.

## Product Goal

Target Point is a darts scoring app. The main interaction is a large clickable dartboard. The player taps the field they hit, and the app records the throw, calculates the score, handles the turn, and updates the match state.

The app should eventually support:

- Guest usage without login.
- Optional Google/email account login. Google login is now scaffolded through Firebase Auth.
- Local player profiles and recurring player groups.
- Match presets.
- Match history and statistics.
- Local-first storage with later cloud sync.

## Current Project Shape

The app is currently split across:

- `lib/main.dart`
- `lib/models`
- `lib/screens`
- `lib/services`
- `lib/theme`
- `lib/widgets`
- `test/widget_test.dart`

State is currently managed by `GameStateController`, a `ChangeNotifier`. Firebase packages are installed, Android uses `android/app/google-services.json`, and iOS uses `ios/Runner/GoogleService-Info.plist`. Both platform configs are for app id `com.luksa.targetpoint`.

## Current Features

- Clickable dartboard rendered with `CustomPainter`.
- Game hub entry screen with Darts plus planned cards for sports, board games, card games, party games, and custom user-created competitions.
- Users can create a custom activity with a name, description/rules, and participants. Custom activities are local session state for now.
- Hit detection from tap coordinates.
- X01 and Count up game modes.
- Starting score choices: `301`, `501`, `701`.
- Finish rules: `Single`, `Double`, `Master`.
- Preset players: `Marko`, `Luka`, `Borna`.
- Three darts per turn.
- Automatic turn commit after the third dart.
- Manual `Save turn`.
- `Undo` for pending hits.
- `Miss` button.
- X01 bust logic.
- Player average per turn.
- Responsive mobile/desktop layout.
- System light/dark mode.
- Manual theme selection: `System`, `Light`, `Dark`.
- App icons updated across Android, iOS, macOS, web, and Windows.
- User/guest profile separate from match players.
- Player group presets.
- Following list.
- Shared player group state.
- Google login flow with Firebase-ready fallback.

## Important Classes And Responsibilities

### `TargetPointApp`

Root widget. Defines:

- `MaterialApp`
- selected `ThemeMode`
- light theme
- dark theme
- home screen: `DartMatchScreen`

Preserve all three theme choices: `ThemeMode.system`, `ThemeMode.light`, and `ThemeMode.dark`.

### `AuthRepository`

Located at `lib/services/auth_repository.dart`.

Responsibilities:

- Initialize Firebase if platform config exists.
- Initialize Google Sign-In.
- Perform Google login through Firebase Auth.
- Save user profiles to Firebase Realtime Database.
- Save player groups under user nodes.
- Save shared player groups.
- Save following relationships.

Important behavior:

- The app must keep running when Firebase is not configured.
- If Firebase is missing, auth/cloud methods should fail gracefully and leave guest mode active.

### `UserSession`

Located at `lib/models/user_session.dart`.

Represents the app user, not a match player.

Fields:

- `id`
- `displayName`
- `email`
- `avatarColorValue`
- `isGuest`

The top-right profile avatar must use `GameStateController.currentUser`, not `currentPlayer`.

### `PlayerGroupPreset`

Located at `lib/models/user_session.dart`.

Represents a reusable group of players for starting a match.

Fields:

- `id`
- `name`
- `playerNames`
- `ownerUserId`
- `isShared`

Selecting a group replaces the active match lineup and resets the match scores.

### `FollowedUser`

Located at `lib/models/user_session.dart`.

Represents a followed app user.

Used for the sharing model where a user can share player group presets with followers.

### `AppPalette`

Small theme helper used for custom UI colors outside Flutter's default color scheme.

Responsibilities:

- Provide light and dark colors.
- Keep custom widgets readable in both system modes.
- Centralize repeated colors for panels, cards, text, borders, and dartboard colors.

When adding custom UI, prefer `AppPalette.of(context)` instead of hardcoding new colors.

### `GameMode`

Enum for supported game modes:

- `x01` - starts from a score like 501 and counts down to 0.
- `countUp` - starts at 0 and accumulates points.

### `OutRule`

Enum for X01 finish rules:

- `singleOut`
- `doubleOut`
- `masterOut`

### `SegmentBand`

Enum describing which part of the board was hit:

- `miss`
- `single`
- `double`
- `triple`
- `outerBull`
- `bull`

### `DartHit`

Represents one dart throw.

Fields:

- `label` - display label, for example `T20`, `D16`, `S5`, `25`, `BULL`, `MISS`.
- `score` - numeric value of the hit.
- `band` - `SegmentBand`.
- `number` - board number when applicable.

Derived helpers:

- `isMiss`
- `isDouble`

### `PlayerScore`

Represents a player in the current match.

Fields:

- `name`
- `remaining`
- `totalScored`
- `turns`
- `isWinner`

`turns` is a list of turns, where each turn is a list of `DartHit`.

### `GameSettings`

Current match settings:

- `mode`
- `startingScore`
- `outRule`

### `DartMatchScreen`

Main responsive shell screen.

Responsibilities:

- Create and own `GameStateController`.
- Render desktop navigation rail or mobile app bar/bottom navigation.
- Route tabs to `PlayScreen`, `ScoreboardScreen`, `SettingsScreen`, and `HistoryScreen`.
- Open `AccountScreen`.
- Open `SearchDialog`.

Profile avatar rule:

- Header avatar must show `controller.currentUser.initials`.
- It must not change when the active match player changes.

### `GameStateController`

Located at `lib/models/game_state_controller.dart`.

Responsibilities:

- Own user session.
- Own player profile registry.
- Own player group presets.
- Own following list.
- Own active match settings.
- Own active match scores and pending turn.
- Apply scoring, bust, finish, and match archive logic.
- Manage tabs/search.
- Provide Google login actions through `AuthRepository`.

Important methods:

- `signInWithGoogle()`
- `signOut()`
- `updateUserProfile(...)`
- `createPlayerGroup(...)`
- `selectPlayerGroup(...)`
- `sharePlayerGroup(...)`
- `followUser(...)`
- `handleHit(...)`
- `undoLastHit()`
- `addMiss()`
- `commitTurn()`
- `updateSettings(...)`
- `startNewMatch()`

### `PlayScreen`

Located at `lib/screens/play_screen.dart`.

Main gameplay surface with current turn header, dartboard, and turn action buttons.

### `SettingsScreen`

Located at `lib/screens/settings_screen.dart`.

Contains:

- player group preset selector
- create player group dialog
- share selected group action
- game mode/rules
- player lineup management

### `AccountScreen`

Located at `lib/screens/account_screen.dart`.

Contains:

- user/guest profile card
- user profile edit panel
- Google login action
- guest/sign-out state
- following input/list
- shared player groups list
- session stats
- app preferences/about

### `Dartboard`

Gesture wrapper around the painted board.

Responsibilities:

- Read available square size.
- Convert tap location into a `DartHit` using `DartboardGeometry.hitTest`.
- Render `DartboardPainter`.

### `DartboardGeometry`

Pure-ish geometry/scoring helper.

Responsibilities:

- Map tap coordinates to dartboard score.
- Determine board number from angle.
- Determine single/double/triple/bull/miss from distance.

Current dartboard number order:

```text
20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
```

Important ratios:

- outside board: `> 0.98` = `MISS`
- bull: `<= 0.055`
- outer bull: `<= 0.12`
- triple ring: `0.52` to `0.62`
- double ring: `>= 0.84`

### `DartboardPainter`

Draws the board with `Canvas`.

Responsibilities:

- Draw board rings.
- Draw segment colors.
- Draw segment numbers.
- Draw wire lines.
- Draw bull and outer bull.

It receives `AppPalette` so the board border/wire colors can adapt to light/dark mode.

## UI Notes

- The current mobile layout is intentionally compact.
- The dartboard should remain the main visual and interaction surface.
- Avoid oversized marketing sections.
- Prefer tool-like UI focused on playing and scoring.
- Keep buttons and repeated controls stable in size.
- Avoid making nested cards.
- Keep labels in English.

## Testing

Current tests in `test/widget_test.dart` cover:

- recording a center dartboard hit as `BULL`
- undoing a pending hit
- rendering on a narrow mobile viewport
- rendering with system dark theme
- keeping app user profile separate from active match player
- creating/selecting player group presets

Run:

```powershell
flutter analyze
flutter test
```

## Known Limitations

- Firebase config is currently present for Android and iOS only.
- Google login is configured for Android/iOS but still depends on Firebase Console providers and Android SHA fingerprints.
- Realtime Database save/share/follow methods are scaffolded but do not load remote data yet.
- Guest data is still session-local.
- Email/password authentication is not implemented yet.
- Every activity except Darts currently has a planned-game screen only.
- Custom activities are not persisted to Firebase yet.

## Preferred Next Implementation Order

1. Add Realtime Database loading for user profile, player groups, and following.
2. Add local persistent storage for guest mode.
3. Add email/password authentication.
4. Add match history sync.
5. Add Firebase config for web/desktop if those platforms are supported.
6. Expand sharing permissions.
7. Implement scoring engines for the planned games in the game hub.
8. Persist custom activities and participants to Firebase.

Keep each change narrow and preserve working tests.

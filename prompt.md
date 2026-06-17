# Game hub Project Prompt

Use this document to understand the Flutter project before making changes. The user communicates in Croatian, but source code, identifiers, labels, and comments should stay in English.

## Product Direction

Game hub is a real-time competitive scoring app. Darts is the first fully detailed game, but the app also supports many sports, board games, card games, party competitions, and user-created activities.

The application must not rely on fake default players. A match starts without hardcoded players. Users can add local players manually, and a signed-in Firebase user is added to the active leaderboard using their real profile.

## Current Architecture

- `GameHubApp` owns theme and locale state.
- `RootScreen` starts on Darts.
- `SportMatchScreen` owns one `GameStateController` per opened game.
- `GameStateController` receives `gameId` and `gameName`.
- `GameStateController` owns active players, current turn, settings, history, auth state, and realtime sync.
- `AuthRepository` owns Firebase Auth, Google Sign-In, and Realtime Database reads/writes.

## Realtime Model

Active game sessions sync through Firebase Realtime Database:

```text
sessions/{sessionId}
userSessions/{uid}/{sessionId}
users/{uid}/profile
publicUsers/{uid}
```

The saved session includes:

- `id`
- `sessionName`
- `gameId`
- `gameName`
- `sportId`
- `sportName`
- `ownerUserId`
- `settings`
- `players`
- `participants`
- `currentTurn`
- `currentPlayerIndex`
- `matchMessage`
- `status`
- `updatedByUserId`

Players may include a `userId` when they represent a registered Firebase user. Local/manual players have no `userId`.

## Player Rules

- Do not add fake default players.
- Guest mode can add local players manually.
- Google login adds or updates the signed-in user as a player.
- The top-right avatar always represents `currentUser`, not the current player.
- Manual players are names only and are useful for local games.
- Registered players should keep their `userId` in `PlayerScore`.

## Game Behavior

### Darts

Darts uses:

- clickable `Dartboard`
- `DartHit`
- `GameMode.x01`
- `GameMode.countUp`
- `OutRule`
- three-dart turns
- bust logic
- dart statistics: 3-dart average, best turn, 180s, 140+, 100+, best hit number

### Other Games

Other games currently use a generic live leaderboard:

- `+1`
- `+5`
- `-1`
- `Next`

Do not show darts-specific controls for non-darts games.

## Important Files

- `lib/models/game_state_controller.dart`
- `lib/models/player_score.dart`
- `lib/models/sport_game.dart`
- `lib/services/auth_repository.dart`
- `lib/screens/play_screen.dart`
- `lib/screens/scoreboard_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/game_hub_screen.dart`
- `lib/screens/account_screen.dart`
- `lib/widgets/dartboard.dart`

## Testing

Run before finishing changes:

```powershell
flutter analyze
flutter test
```

For Android build verification:

```powershell
flutter build apk --debug
```

## Known Limitations

- Email/password login is not implemented.
- Guest data is session-local.
- Non-darts games use generic scoring until detailed scoring engines are implemented.
- Custom activities are local app state and are not yet persisted to Firebase.

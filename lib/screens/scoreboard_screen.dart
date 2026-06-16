import 'package:flutter/material.dart';

import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
import '../theme/app_palette.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({required this.controller, super.key});

  final GameStateController controller;

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  // Track expanded state of turn logs for each player
  final Map<String, bool> _expandedPlayers = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final players = [...widget.controller.players]
      ..sort((a, b) {
        if (widget.controller.isDartsGame &&
            widget.controller.settings.mode == GameMode.x01) {
          return a.remaining.compareTo(b.remaining);
        }
        return b.totalScored.compareTo(a.totalScored);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            widget.controller.isDartsGame ? 'Darts Leaderboard' : 'Leaderboard',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
        ),
        Expanded(
          child: players.isEmpty
              ? Center(
                  child: Text(
                    'No active players.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final isExpanded = _expandedPlayers[player.name] ?? false;

                    return Card(
                      color: palette.surface,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: player.isWinner
                              ? palette.primary
                              : palette.border,
                          width: player.isWinner ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(player.avatarColorValue),
                              foregroundColor: Colors.white,
                              child: Text(
                                player.name.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  player.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: palette.text,
                                  ),
                                ),
                                if (player.isWinner) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.emoji_events,
                                    color: palette.accent,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              widget.controller.isDartsGame
                                  ? '3-Dart Avg: ${player.average.toStringAsFixed(1)} | Throws: ${player.totalThrows}'
                                  : player.isRegisteredUser
                                  ? 'Registered user'
                                  : 'Local player',
                              style: TextStyle(
                                color: palette.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.controller.isDartsGame
                                      ? '${player.remaining}'
                                      : '${player.totalScored}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: player.isWinner
                                        ? palette.primary
                                        : palette.text,
                                  ),
                                ),
                                Text(
                                  widget.controller.settings.mode ==
                                          GameMode.x01
                                      ? 'LEFT'
                                      : 'POINTS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (widget.controller.isDartsGame)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _MiniStat(
                                      label: '180s',
                                      value: '${player.count180s}',
                                      palette: palette,
                                    ),
                                    _MiniStat(
                                      label: '140+',
                                      value: '${player.count140plus}',
                                      palette: palette,
                                    ),
                                    _MiniStat(
                                      label: '100+',
                                      value: '${player.count100plus}',
                                      palette: palette,
                                    ),
                                    _MiniStat(
                                      label: 'Best Turn',
                                      value: '${player.highestTurnScore}',
                                      palette: palette,
                                    ),
                                    _MiniStat(
                                      label: 'Best No.',
                                      value: player.bestNumber == null
                                          ? '-'
                                          : '${player.bestNumber} (${player.bestNumberHits})',
                                      palette: palette,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (widget.controller.isDartsGame)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _expandedPlayers[player.name] = !isExpanded;
                                });
                              },
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isExpanded
                                          ? 'Hide Throw History'
                                          : 'Show Throw History',
                                      style: TextStyle(
                                        color: palette.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: palette.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (widget.controller.isDartsGame && isExpanded) ...[
                            const Divider(height: 1),
                            Container(
                              color: palette.surfaceMuted.withValues(
                                alpha: 0.5,
                              ),
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: player.turns.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No turns thrown yet.',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: player.turns.length,
                                      itemBuilder: (context, tIdx) {
                                        final turn = player.turns[tIdx];
                                        final turnScore = turn.fold<int>(
                                          0,
                                          (sum, hit) => sum + hit.score,
                                        );
                                        final hitsLabels = turn
                                            .map((hit) => hit.label)
                                            .join(', ');

                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            'Turn ${tIdx + 1}: $hitsLabels',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: palette.text,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: palette.primarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '+$turnScore',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: palette.primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: palette.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

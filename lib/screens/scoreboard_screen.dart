import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
import '../theme/app_palette.dart';
import '../widgets/player_avatar.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({required this.controller, super.key});

  final GameStateController controller;

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
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
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            widget.controller.isDartsGame
                ? l10n.t('scoreboard.dartsTitle')
                : l10n.t('scoreboard.title'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
        ),
        Expanded(
          child: players.isEmpty
              ? Center(
                  child: Text(
                    l10n.t('scoreboard.noPlayers'),
                    style: TextStyle(color: palette.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: player.isWinner
                                ? palette.primary
                                : palette.border.withValues(alpha: 0.45),
                            width: player.isWinner ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            leading: PlayerAvatar(
                              name: player.name,
                              avatarColorValue: player.avatarColorValue,
                              photoUrl: player.photoUrl,
                              radius: 20,
                            ),
                            title: Row(
                              children: [
                                Text(
                                  player.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
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
                                  ? '${l10n.t('scoreboard.threeDartAvg')}: ${player.average.toStringAsFixed(1)} | ${l10n.t('scoreboard.throws')}: ${player.totalThrows}'
                                  : player.isRegisteredUser
                                  ? l10n.t('scoreboard.registeredUser')
                                  : l10n.t('scoreboard.localPlayer'),
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: player.isWinner
                                        ? palette.primary
                                        : palette.text,
                                  ),
                                ),
                                Text(
                                  widget.controller.settings.mode ==
                                          GameMode.x01
                                      ? l10n.t('scoreboard.left')
                                      : l10n.t('scoreboard.points'),
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
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: _MiniStat(
                                        label: l10n.sportStat('wins', 'Wins'),
                                        value: '${player.stats['wins'] ?? 0}',
                                        palette: palette,
                                      ),
                                    ),
                                    Expanded(
                                      child: _MiniStat(
                                        label: '180s',
                                        value: '${player.count180s}',
                                        palette: palette,
                                      ),
                                    ),
                                    Expanded(
                                      child: _MiniStat(
                                        label: '140+',
                                        value: '${player.count140plus}',
                                        palette: palette,
                                      ),
                                    ),
                                    Expanded(
                                      child: _MiniStat(
                                        label: '100+',
                                        value: '${player.count100plus}',
                                        palette: palette,
                                      ),
                                    ),
                                    Expanded(
                                      child: _MiniStat(
                                        label: l10n.t('scoreboard.bestTurn'),
                                        value: '${player.highestTurnScore}',
                                        palette: palette,
                                      ),
                                    ),
                                    Expanded(
                                      child: _MiniStat(
                                        label: l10n.t('scoreboard.bestNumber'),
                                        value: player.bestNumber == null
                                            ? '-'
                                            : '${player.bestNumber} (${player.bestNumberHits})',
                                        palette: palette,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

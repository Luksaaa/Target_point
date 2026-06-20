import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/dart_hit.dart';
import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
import '../models/player_score.dart';
import '../theme/app_palette.dart';
import '../widgets/player_avatar.dart';
import '../widgets/search_dialog.dart'; // To reuse MatchRecapDialog

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.controller, super.key});

  final GameStateController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final history = controller.matchHistory;
    final playersWithTurns = controller.isDartsGame
        ? controller.players.where((player) => player.turns.isNotEmpty).toList()
        : <PlayerScore>[];
    final hasCurrentThrows = playersWithTurns.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            l10n.t('history.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
        ),
        Expanded(
          child: history.isEmpty && !hasCurrentThrows
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 54,
                        color: palette.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.t('history.emptyTitle'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.t('history.emptyDescription'),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: history.length + (hasCurrentThrows ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (hasCurrentThrows && index == 0) {
                      return _CurrentThrowHistory(
                        players: playersWithTurns,
                        palette: palette,
                        theme: theme,
                      );
                    }

                    final historyIndex = index - (hasCurrentThrows ? 1 : 0);
                    final match = history[historyIndex];
                    final dateStr =
                        '${match.date.day}.${match.date.month}.${match.date.year} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';
                    final isX01 = match.settings.mode == GameMode.x01;

                    return Card(
                      color: palette.surface,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: palette.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: palette.primarySoft,
                          foregroundColor: palette.primary,
                          child: const Icon(Icons.emoji_events),
                        ),
                        title: Row(
                          children: [
                            Text(
                              '${l10n.t('history.winner')}: ${match.winnerName}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.emoji_events,
                              color: palette.accent,
                              size: 16,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${isX01 ? "X01 (${match.settings.startingScore})" : l10n.t('settings.countUp')} | $dateStr',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Render mini avatars of participants
                            ...match.finalScores
                                .take(3)
                                .map(
                                  (player) => Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: PlayerAvatar(
                                      name: player.name,
                                      avatarColorValue: player.avatarColorValue,
                                      photoUrl: player.photoUrl,
                                      radius: 10,
                                    ),
                                  ),
                                ),
                            if (match.finalScores.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  '+${match.finalScores.length - 3}',
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: palette.textMuted),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => MatchRecapDialog(
                              match: match,
                              palette: palette,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CurrentThrowHistory extends StatelessWidget {
  const _CurrentThrowHistory({
    required this.players,
    required this.palette,
    required this.theme,
  });

  final List<PlayerScore> players;
  final AppPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.t('history.currentThrows'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final player in players) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlayerAvatar(
                    name: player.name,
                    avatarColorValue: player.avatarColorValue,
                    photoUrl: player.photoUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (
                          var index = 0;
                          index < player.turns.length;
                          index++
                        )
                          _ThrowRow(
                            turnIndex: index,
                            turn: player.turns[index],
                            palette: palette,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: palette.border.withValues(alpha: 0.55)),
          ],
        ],
      ),
    );
  }
}

class _ThrowRow extends StatelessWidget {
  const _ThrowRow({
    required this.turnIndex,
    required this.turn,
    required this.palette,
  });

  final int turnIndex;
  final List<DartHit> turn;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final score = turn.fold<int>(0, (sum, hit) => sum + hit.score);
    final labels = turn.map((hit) => hit.label).join(', ');
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${l10n.t('history.turn')} ${turnIndex + 1}: $labels',
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '+$score',
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

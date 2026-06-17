import 'package:flutter/material.dart';

import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
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
    final history = controller.matchHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Match History',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.text,
            ),
          ),
        ),
        Expanded(
          child: history.isEmpty
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
                        'No matches played yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Play a match to see history and stats!',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final match = history[index];
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
                              'Winner: ${match.winnerName}',
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
                          '${isX01 ? "X01 (${match.settings.startingScore})" : "Count Up"} | $dateStr',
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

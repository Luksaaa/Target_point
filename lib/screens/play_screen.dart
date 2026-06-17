import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_settings.dart';
import '../models/game_state_controller.dart';
import '../models/player_score.dart';
import '../models/sport_game.dart';
import '../theme/app_palette.dart';
import '../widgets/dartboard.dart';
import '../widgets/player_avatar.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    required this.controller,
    required this.isWide,
    required this.game,
    super.key,
  });

  final GameStateController controller;
  final bool isWide;
  final SportGame game;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  GameStateController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final hits = controller.currentTurn;
    final sportActions = sportActionsFor(widget.game.id);

    final actionRow = controller.isDartsGame
        ? Row(
            children: [
              Expanded(
                child: _ActionButton(
                  onPressed: hits.isEmpty || controller.matchFinished
                      ? null
                      : controller.undoLastHit,
                  icon: Icons.undo,
                  label: l10n.t('action.undo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: controller.matchFinished
                      ? null
                      : controller.addMiss,
                  icon: Icons.radio_button_unchecked,
                  label: l10n.t('action.miss'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: hits.isNotEmpty && !controller.matchFinished
                      ? controller.commitTurn
                      : null,
                  icon: Icons.check,
                  label: l10n.t('action.saveTurn'),
                  filled: true,
                ),
              ),
            ],
          )
        : Row(
            children: [
              for (int i = 0; i < sportActions.take(4).length; i++) ...[
                Expanded(
                  child: _ActionButton(
                    onPressed: controller.players.isEmpty
                        ? null
                        : () {
                            final action = sportActions[i];
                            controller.applySportAction(
                              label: action.label,
                              scoreDelta: action.scoreDelta,
                              statKey: action.statKey,
                              statDelta: action.statDelta,
                              endsTurn: action.endsTurn,
                            );
                          },
                    icon: sportActions[i].icon,
                    label: sportActions[i].label,
                    filled: i == 0,
                  ),
                ),
                if (i != sportActions.take(4).length - 1)
                  const SizedBox(width: 10),
              ],
            ],
          );

    final playPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CurrentTurnHeader(controller: controller, palette: palette),
        const SizedBox(height: 14),
        Expanded(
          child: Center(
            child: widget.game.id == 'darts'
                ? AspectRatio(
                    aspectRatio: 1,
                    child: Dartboard(
                      enabled: !controller.matchFinished,
                      onHit: controller.handleHit,
                      currentTurn: hits,
                    ),
                  )
                : _GenericSportPanel(
                    game: widget.game,
                    controller: controller,
                    palette: palette,
                  ),
          ),
        ),
        const SizedBox(height: 14),
        actionRow,
      ],
    );

    if (!widget.isWide) {
      return playPanel;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 6, child: playPanel),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: _QuickScoreboardPanel(
            controller: controller,
            palette: palette,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _CurrentTurnHeader extends StatelessWidget {
  const _CurrentTurnHeader({required this.controller, required this.palette});

  final GameStateController controller;
  final AppPalette palette;

  void _showManualDartDialog(BuildContext context, int index) {
    final existing = index < controller.currentTurn.length
        ? controller.currentTurn[index].score.toString()
        : '';
    final inputController = TextEditingController(text: existing);
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Dart ${index + 1} score'),
        content: TextField(
          controller: inputController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          style: theme.textTheme.titleLarge?.copyWith(
            color: palette.text,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            hintText: '0 - 60',
            filled: true,
            fillColor: palette.surfaceMuted,
          ),
          onSubmitted: (_) => _saveManualDart(context, index, inputController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _saveManualDart(context, index, inputController),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveManualDart(
    BuildContext context,
    int index,
    TextEditingController inputController,
  ) {
    final score = int.tryParse(inputController.text.trim());
    if (score == null) {
      return;
    }
    controller.setManualDartScore(index, score);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = controller.currentPlayer;
    final hits = controller.currentTurn;
    final turnTotal = hits.fold(0, (total, hit) => total + hit.score);
    final isDarts = controller.isDartsGame;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isDarts
                          ? '3-dart avg ${player.average.toStringAsFixed(1)}'
                          : 'Score ${player.totalScored}',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${player.remaining}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isDarts) ...[
            Row(
              children: List.generate(3, (index) {
                final hit = index < hits.length ? hits[index] : null;
                final isActive =
                    index == hits.length && !controller.matchFinished;
                return Expanded(
                  child: GestureDetector(
                    onTap: controller.matchFinished
                        ? null
                        : () => _showManualDartDialog(context, index),
                    child: Container(
                      height: 44,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hit == null
                            ? palette.surfaceMuted
                            : palette.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? palette.primary : palette.border,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        hit?.label ?? 'Dart ${index + 1}',
                        style: TextStyle(
                          color: hit == null
                              ? palette.textMuted
                              : palette.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Text(
                isDarts ? 'Turn total: $turnTotal' : 'Live leaderboard',
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (controller.matchMessage != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.matchMessage!,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GenericSportPanel extends StatelessWidget {
  const _GenericSportPanel({
    required this.game,
    required this.controller,
    required this.palette,
  });

  final SportGame game;
  final GameStateController controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = controller.currentPlayer;
    final stats = player.stats.entries
        .where((entry) => entry.value > 0)
        .take(6)
        .toList();
    final events = controller.sportEvents.take(12).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(game.icon, size: 56, color: game.color),
          const SizedBox(height: 14),
          Text(
            game.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${player.name} · Score ${player.totalScored}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (events.isNotEmpty)
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _SportEventCard(
                    event: event,
                    game: game,
                    controller: controller,
                    palette: palette,
                  );
                },
              ),
            )
          else if (stats.isEmpty)
            Text(
              game.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stat in stats)
                  Chip(
                    label: Text('${_statLabel(stat.key)} ${stat.value}'),
                    backgroundColor: palette.surfaceMuted,
                    side: BorderSide(color: palette.border),
                    labelStyle: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _statLabel(String key) {
    final words = key
        .replaceAllMapped(
          RegExp('[A-Z]'),
          (match) => ' ${match.group(0)!.toLowerCase()}',
        )
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return key;
    }
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _SportEventCard extends StatelessWidget {
  const _SportEventCard({
    required this.event,
    required this.game,
    required this.controller,
    required this.palette,
  });

  final SportEvent event;
  final SportGame game;
  final GameStateController controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final time =
        '${event.createdAt.hour.toString().padLeft(2, '0')}:${event.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: game.color.withValues(alpha: 0.2),
            foregroundColor: game.color,
            radius: 18,
            child: Icon(game.icon, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time · Total ${event.totalScore}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (controller.canManageGroupMembers)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove event',
              onPressed: () => controller.removeSportEvent(event.id),
              icon: Icon(Icons.close, color: palette.textMuted, size: 18),
            ),
        ],
      ),
    );
  }
}

class _QuickScoreboardPanel extends StatelessWidget {
  const _QuickScoreboardPanel({
    required this.controller,
    required this.palette,
    required this.theme,
  });

  final GameStateController controller;
  final AppPalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Players',
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: controller.players.length,
              separatorBuilder: (context, index) =>
                  Divider(color: palette.border),
              itemBuilder: (context, index) {
                final player = controller.players[index];
                final isCurrent = index == controller.currentPlayerIndex;
                return Row(
                  children: [
                    PlayerAvatar(
                      name: player.name,
                      avatarColorValue: player.avatarColorValue,
                      photoUrl: player.photoUrl,
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: TextStyle(
                              color: isCurrent ? palette.primary : palette.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            controller.isDartsGame
                                ? 'Avg ${player.average.toStringAsFixed(1)} / Best ${player.highestTurnScore}'
                                : _sportStatsSummary(player),
                            style: TextStyle(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${player.remaining}',
                      style: TextStyle(
                        color: isCurrent ? palette.primary : palette.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            !controller.isDartsGame
                ? 'LIVE ${controller.gameName.toUpperCase()} LEADERBOARD'
                : controller.settings.mode == GameMode.x01
                ? '${controller.settings.startingScore} / ${controller.settings.outRule.name.replaceAll('Out', '').toUpperCase()} OUT'
                : 'COUNT UP',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _sportStatsSummary(PlayerScore player) {
    final stats = player.stats.entries
        .where((entry) => entry.value > 0)
        .take(2)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' · ');
    if (stats.isEmpty) {
      return 'Score ${player.totalScored}';
    }
    return 'Score ${player.totalScored} · $stats';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, maxLines: 1, softWrap: false),
        ],
      ),
    );

    return filled
        ? FilledButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_settings.dart';
import '../models/game_state_controller.dart';
import '../models/sport_game.dart';
import '../theme/app_palette.dart';
import '../widgets/dartboard.dart';

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

  void _confirmSaveTurn(BuildContext context, AppPalette palette) {
    final hits = controller.currentTurn;
    if (hits.isEmpty || controller.matchFinished) return;

    final turnTotal = hits.fold(0, (sum, hit) => sum + hit.score);
    final hitsText = hits.map((hit) => hit.label).join(' / ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: palette.border),
        ),
        title: const Text('Save turn?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hitsText,
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                'Total: $turnTotal',
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.undoLastHit();
            },
            child: const Text('Redo Last Dart'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              controller.commitTurn();
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final hits = controller.currentTurn;

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
                      ? () => _confirmSaveTurn(context, palette)
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
              Expanded(
                child: _ActionButton(
                  onPressed: controller.players.isEmpty
                      ? null
                      : () => controller.adjustCurrentPlayerScore(-1),
                  icon: Icons.remove,
                  label: '-1',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: controller.players.isEmpty
                      ? null
                      : () => controller.adjustCurrentPlayerScore(1),
                  icon: Icons.add,
                  label: '+1',
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: controller.players.isEmpty
                      ? null
                      : () => controller.adjustCurrentPlayerScore(5),
                  icon: Icons.add_circle_outline,
                  label: '+5',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: controller.players.length < 2
                      ? null
                      : controller.advanceGenericTurn,
                  icon: Icons.skip_next,
                  label: l10n.t('action.next'),
                ),
              ),
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
                : _GenericSportPanel(game: widget.game, palette: palette),
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
              CircleAvatar(
                backgroundColor: Color(player.avatarColorValue),
                foregroundColor: Colors.white,
                radius: 20,
                child: Text(
                  player.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
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
  const _GenericSportPanel({required this.game, required this.palette});

  final SportGame game;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            game.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
            ),
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
                    CircleAvatar(
                      backgroundColor: Color(player.avatarColorValue),
                      foregroundColor: Colors.white,
                      radius: 18,
                      child: Text(
                        player.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
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
                                : 'Score ${player.totalScored}',
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

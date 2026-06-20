import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_settings.dart';
import '../models/game_state_controller.dart';
import '../models/player_score.dart';
import '../models/sport_game.dart';
import '../theme/app_palette.dart';
import '../widgets/dartboard.dart';
import '../widgets/player_avatar.dart';

String _p(BuildContext context, String key) =>
    AppLocalizations.of(context).t(key);

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

  OverlayEntry? _notYourTurnEntry;
  Timer? _notYourTurnTimer;

  void _showNotYourTurnPill() {
    final palette = AppPalette.of(context);
    final playerName = controller.currentPlayer.name;

    _notYourTurnTimer?.cancel();
    _notYourTurnEntry?.remove();
    _notYourTurnEntry = null;

    final overlay = Overlay.of(context);
    final top = MediaQuery.paddingOf(context).top + 12;
    _notYourTurnEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        left: 20,
        right: 20,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -28, end: 0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => Transform.translate(
            offset: Offset(0, offset),
            child: Opacity(
              opacity: (1 - (offset.abs() / 28)).clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.primary),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  _p(
                    context,
                    'play.notYourTurn',
                  ).replaceAll('{name}', playerName),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_notYourTurnEntry!);
    _notYourTurnTimer = Timer(const Duration(milliseconds: 1700), () {
      _notYourTurnEntry?.remove();
      _notYourTurnEntry = null;
    });
  }

  @override
  void dispose() {
    _notYourTurnTimer?.cancel();
    _notYourTurnEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final hits = controller.currentTurn;
    final sportActions = sportActionsFor(widget.game.id);
    final canScore = controller.canScoreCurrentTurn;

    final actionRow = controller.isDartsGame
        ? Row(
            children: [
              Expanded(
                child: _ActionButton(
                  onPressed: hits.isEmpty || !canScore
                      ? (!canScore ? _showNotYourTurnPill : null)
                      : controller.undoLastHit,
                  icon: Icons.undo,
                  label: l10n.t('action.undo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: canScore
                      ? controller.addMiss
                      : _showNotYourTurnPill,
                  icon: Icons.radio_button_unchecked,
                  label: l10n.t('action.miss'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: hits.isNotEmpty && canScore
                      ? controller.commitTurn
                      : (!canScore ? _showNotYourTurnPill : null),
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
                    onPressed: controller.players.isEmpty || !canScore
                        ? (!canScore ? _showNotYourTurnPill : null)
                        : () {
                            final action = sportActions[i];
                            controller.applySportAction(
                              label: action.label,
                              actionId: action.id,
                              scoreDelta: action.scoreDelta,
                              statKey: action.statKey,
                              statDelta: action.statDelta,
                              endsTurn: action.endsTurn,
                            );
                          },
                    icon: sportActions[i].icon,
                    label: l10n.sportAction(
                      sportActions[i].id,
                      sportActions[i].label,
                    ),
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
        _CurrentTurnHeader(
          controller: controller,
          palette: palette,
          onBlockedScoreTap: _showNotYourTurnPill,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: widget.game.id == 'darts'
              ? Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Dartboard(
                      enabled: !controller.matchFinished,
                      onHit: canScore
                          ? controller.handleHit
                          : (_) => _showNotYourTurnPill(),
                      currentTurn: hits,
                      checkoutHint: controller.checkoutHint,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _GenericSportPanel(
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
  const _CurrentTurnHeader({
    required this.controller,
    required this.palette,
    required this.onBlockedScoreTap,
  });

  final GameStateController controller;
  final AppPalette palette;
  final VoidCallback onBlockedScoreTap;

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
        title: Text(
          _p(
            context,
            'play.dartScoreTitle',
          ).replaceAll('{number}', '${index + 1}'),
        ),
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
            child: Text(_p(context, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () => _saveManualDart(context, index, inputController),
            child: Text(_p(context, 'common.save')),
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
    final displayedRemaining =
        isDarts && controller.settings.mode == GameMode.x01
        ? (player.remaining - turnTotal).clamp(0, 999999)
        : player.remaining;
    final checkoutHint = controller.checkoutHint;
    final checkoutTargets = _checkoutTargets(checkoutHint);
    final canScore = controller.canScoreCurrentTurn;
    final statusMessage = !canScore && !controller.matchFinished
        ? 'Waiting for ${player.name}'
        : controller.matchMessage;
    final showCheckoutHint =
        checkoutHint != null && canScore && statusMessage == null;

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
                '$displayedRemaining',
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
                final isActive = index == hits.length && canScore;
                final checkoutIndex = index - hits.length;
                final checkoutTarget =
                    checkoutIndex >= 0 && checkoutIndex < checkoutTargets.length
                    ? checkoutTargets[checkoutIndex]
                    : null;
                return Expanded(
                  child: GestureDetector(
                    onTap: canScore
                        ? () => _showManualDartDialog(context, index)
                        : onBlockedScoreTap,
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
                        hit?.label ?? checkoutTarget ?? 'Dart ${index + 1}',
                        style: TextStyle(
                          color: hit != null || checkoutTarget != null
                              ? palette.primary
                              : palette.textMuted,
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
          SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isDarts
                        ? '${_p(context, 'play.turnTotal')}: $turnTotal'
                        : _p(context, 'play.liveLeaderboard'),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (showCheckoutHint)
                  Text(
                    '${_p(context, 'play.out')}: $checkoutHint',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                if (statusMessage != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      statusMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _checkoutTargets(String? hint) {
    if (hint == null || hint.trim().isEmpty) {
      return const [];
    }
    return hint
        .split('+')
        .map((target) => target.trim())
        .where((target) => target.isNotEmpty)
        .take(3)
        .toList(growable: false);
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
    final l10n = AppLocalizations.of(context);
    final player = controller.currentPlayer;
    final stats = player.stats.entries
        .where((entry) => entry.value > 0)
        .take(6)
        .toList();
    final events = controller.sportEvents.take(12).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _Rule(palette: palette),
          const SizedBox(height: 16),
          Text(
            l10n.gameName(game.id, game.name),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${player.name} - ${l10n.t('common.score')} ${player.totalScored}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _Rule(palette: palette),
          const SizedBox(height: 18),
          if (events.isNotEmpty)
            Column(
              children: [
                for (var index = 0; index < events.length; index++) ...[
                  _SportEventRow(
                    event: events[index],
                    game: game,
                    controller: controller,
                    palette: palette,
                  ),
                  if (index != events.length - 1) _Rule(palette: palette),
                ],
              ],
            )
          else if (stats.isEmpty)
            Text(
              l10n.gameSubtitle(game.id, game.subtitle),
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
                    label: Text(
                      '${l10n.sportStat(stat.key, _statLabel(stat.key))} ${stat.value}',
                    ),
                    backgroundColor: palette.surfaceMuted,
                    side: BorderSide(color: palette.border),
                    labelStyle: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 18),
          _Rule(palette: palette),
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

class _Rule extends StatelessWidget {
  const _Rule({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: palette.border.withValues(alpha: 0.55),
    );
  }
}

class _SportEventRow extends StatelessWidget {
  const _SportEventRow({
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
    final l10n = AppLocalizations.of(context);
    final actionLabel = event.actionId == null
        ? _legacyActionLabel(l10n, event.label)
        : l10n.sportAction(event.actionId!, event.label);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: game.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(game.icon, color: game.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                  '$time - $actionLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${event.totalScore}',
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                l10n.t('common.total'),
                style: TextStyle(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (controller.canManageGroupMembers)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.t('action.removeEvent'),
              onPressed: () => controller.removeSportEvent(event.id),
              icon: Icon(Icons.close, color: palette.textMuted, size: 18),
            ),
        ],
      ),
    );
  }

  String _legacyActionLabel(AppLocalizations l10n, String label) {
    final normalized = label.toLowerCase().replaceAll(' ', '-');
    return l10n.sportAction(normalized, label);
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
    final l10n = AppLocalizations.of(context);
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
            l10n.t('settings.playersLineup'),
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
                                ? '${l10n.t('scoreboard.avg')} ${player.average.toStringAsFixed(1)} / ${l10n.t('scoreboard.bestTurn')} ${player.highestTurnScore}'
                                : _sportStatsSummary(player, l10n),
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

  String _sportStatsSummary(PlayerScore player, AppLocalizations l10n) {
    final stats = player.stats.entries
        .where((entry) => entry.value > 0)
        .take(2)
        .map(
          (entry) => '${l10n.sportStat(entry.key, entry.key)}: ${entry.value}',
        )
        .join(' · ');
    if (stats.isEmpty) {
      return '${l10n.t('common.score')} ${player.totalScored}';
    }
    return '${l10n.t('common.score')} ${player.totalScored} · $stats';
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

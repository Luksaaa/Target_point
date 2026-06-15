import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/sport_game.dart';
import '../theme/app_palette.dart';
import 'coming_soon_game_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({
    required this.themeMode,
    required this.locale,
    required this.customActivities,
    required this.onCreateActivity,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    required this.onOpenDarts,
    super.key,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final List<SportGame> customActivities;
  final void Function({
    required String name,
    required String description,
    required List<String> participants,
  })
  onCreateActivity;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<BuildContext> onOpenDarts;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final games = [...customActivities, ...sportGames];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 16,
                    16,
                    isWide ? 32 : 16,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _HubHeader(
                      themeMode: themeMode,
                      locale: locale,
                      onThemeModeChanged: onThemeModeChanged,
                      onLocaleChanged: onLocaleChanged,
                      onCreateActivity: () =>
                          _showCreateActivityDialog(context, onCreateActivity),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 16,
                    8,
                    isWide ? 32 : 16,
                    24,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final game = games[index];
                      return _GameCard(
                        game: game,
                        onTap: () {
                          if (game.id == 'darts') {
                            onOpenDarts(context);
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ComingSoonGameScreen(game: game),
                            ),
                          );
                        },
                      );
                    }, childCount: games.length),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isWide ? 260 : 190,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 116,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 16,
                    0,
                    isWide ? 32 : 16,
                    32,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.t('hub.note'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCreateActivityDialog(
    BuildContext context,
    void Function({
      required String name,
      required String description,
      required List<String> participants,
    })
    onCreateActivity,
  ) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final participantsController = TextEditingController();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(l10n.t('hub.createActivity')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.t('activity.name'),
                  hintText: l10n.t('activity.nameHint'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.t('activity.rules'),
                  hintText: l10n.t('activity.rulesHint'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: participantsController,
                decoration: InputDecoration(
                  labelText: l10n.t('activity.participants'),
                  hintText: l10n.t('activity.participantsHint'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.t('common.cancel'),
              style: TextStyle(color: palette.textMuted),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
            onPressed: () {
              onCreateActivity(
                name: nameController.text,
                description: descriptionController.text,
                participants: participantsController.text
                    .split(',')
                    .map((participant) => participant.trim())
                    .where((participant) => participant.isNotEmpty)
                    .toList(),
              );
              Navigator.of(dialogContext).pop();
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.t('common.create')),
          ),
        ],
      ),
    );

    // The dialog route can still rebuild during its closing animation.
    // Controllers are intentionally left alive for that short route lifetime.
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({
    required this.themeMode,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    required this.onCreateActivity,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final VoidCallback onCreateActivity;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.adjust, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('app.title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                l10n.t('hub.chooseGame'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: l10n.t('hub.createActivity'),
          onPressed: onCreateActivity,
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<Locale?>(
          tooltip: l10n.t('common.language'),
          icon: Icon(Icons.language, color: palette.text),
          initialValue: locale,
          onSelected: onLocaleChanged,
          itemBuilder: (context) => [
            PopupMenuItem(value: null, child: Text(l10n.t('common.system'))),
            for (final supportedLocale in AppLocalizations.supportedLocales)
              PopupMenuItem(
                value: supportedLocale,
                child: Text(AppLocalizations.languageName(supportedLocale)),
              ),
          ],
        ),
        PopupMenuButton<ThemeMode>(
          tooltip: l10n.t('common.theme'),
          icon: Icon(Icons.brightness_6, color: palette.text),
          initialValue: themeMode,
          onSelected: onThemeModeChanged,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ThemeMode.system,
              child: Text(l10n.t('common.system')),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: Text(l10n.t('common.light')),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Text(l10n.t('common.dark')),
            ),
          ],
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});

  final SportGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isReady = game.status == SportGameStatus.ready;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isReady ? game.color : palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: game.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(game.icon, color: game.color, size: 22),
                  ),
                  const Spacer(),
                  _StatusBadge(isReady: isReady, isCustom: game.isCustom),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.gameName(game.id, game.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final mode in game.modes.take(2))
                      _ModeChip(label: mode, color: game.color),
                    if (game.participants.length > 2)
                      _ModeChip(
                        label: '+${game.participants.length - 2}',
                        color: game.color,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isReady, required this.isCustom});

  final bool isReady;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReady ? palette.primarySoft : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCustom
            ? l10n.t('common.custom')
            : isReady
            ? l10n.t('common.ready')
            : l10n.t('common.soon'),
        style: TextStyle(
          color: isReady ? palette.primary : palette.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

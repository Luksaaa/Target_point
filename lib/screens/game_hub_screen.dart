import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state_controller.dart';
import '../models/sport_game.dart';
import '../models/user_session.dart';
import '../theme/app_palette.dart';
import '../widgets/responsive_content.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({
    required this.themeMode,
    required this.locale,
    required this.customActivities,
    required this.onCreateActivity,
    required this.onDeleteActivity,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    required this.onOpenSport,
    this.controller,
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
  final ValueChanged<String> onDeleteActivity;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<SportGame> onOpenSport;
  final GameStateController? controller;

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  void _followUser(String value) {
    final controller = widget.controller;
    if (controller == null) {
      return;
    }
    controller.followUser(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final games = [...widget.customActivities, ...sportGames];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;

            return ResponsiveContent(
              maxWidth: 1280,
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 16,
                16,
                isWide ? 24 : 16,
                32,
              ),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 8),
                    sliver: SliverToBoxAdapter(
                      child: _HubHeader(
                        themeMode: widget.themeMode,
                        locale: widget.locale,
                        onThemeModeChanged: widget.onThemeModeChanged,
                        onLocaleChanged: widget.onLocaleChanged,
                        onCreateActivity: () =>
                            _showCreateActivityDialog(context),
                      ),
                    ),
                  ),
                  if (widget.controller != null)
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 10),
                      sliver: SliverToBoxAdapter(
                        child: _QuickFollowPanel(
                          controller: widget.controller!,
                          onFollow: () => _showFollowDialog(context),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final game = games[index];
                        return _GameCard(
                          game: game,
                          onDelete: game.isCustom
                              ? () => _confirmDeleteActivity(context, game)
                              : null,
                          onTap: () {
                            widget.onOpenSport(game);
                          },
                        );
                      }, childCount: games.length),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isWide ? 260 : 190,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 138,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCreateActivityDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final participantsController = TextEditingController();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final followers = widget.controller?.following ?? const [];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var showNameError = false;
        var showDescriptionError = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void refresh() => setDialogState(() {});

            void addFollower(String displayName) {
              final current = participantsController.text
                  .split(',')
                  .map((participant) => participant.trim())
                  .where((participant) => participant.isNotEmpty)
                  .toList();
              if (!current.any(
                (participant) =>
                    participant.toLowerCase() == displayName.toLowerCase(),
              )) {
                current.add(displayName);
              }
              participantsController.text = current.join(', ');
              refresh();
            }

            return AlertDialog(
              backgroundColor: palette.surface,
              title: Text(l10n.t('hub.createActivity')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => refresh(),
                      decoration: InputDecoration(
                        labelText: l10n.t('activity.name'),
                        hintText: l10n.t('activity.nameHint'),
                        errorText:
                            showNameError && nameController.text.trim().isEmpty
                            ? l10n.t('activity.nameRequired')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => refresh(),
                      decoration: InputDecoration(
                        labelText: l10n.t('activity.rules'),
                        hintText: l10n.t('activity.rulesHint'),
                        errorText:
                            showDescriptionError &&
                                descriptionController.text.trim().isEmpty
                            ? l10n.t('activity.descriptionRequired')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: participantsController,
                      onChanged: (_) => refresh(),
                      decoration: InputDecoration(
                        labelText: l10n.t('activity.participantsOptional'),
                        hintText: l10n.t('activity.participantsHint'),
                      ),
                    ),
                    if (followers.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.t('activity.followerSuggestions'),
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final follower in followers)
                              ActionChip(
                                label: Text(follower.displayName),
                                avatar: const Icon(Icons.person_add, size: 16),
                                onPressed: () =>
                                    addFollower(follower.displayName),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                  ),
                  onPressed: () {
                    final hasName = nameController.text.trim().isNotEmpty;
                    final hasDescription = descriptionController.text
                        .trim()
                        .isNotEmpty;
                    if (!hasName || !hasDescription) {
                      setDialogState(() {
                        showNameError = true;
                        showDescriptionError = true;
                      });
                      return;
                    }
                    widget.onCreateActivity(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      participants: participantsController.text
                          .split(',')
                          .map((participant) => participant.trim())
                          .where((participant) => participant.isNotEmpty)
                          .toList(),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.t('common.create')),
                ),
              ],
            );
          },
        );
      },
    );

    // Keep these alive through the dialog route closing animation.
  }

  Future<void> _showFollowDialog(BuildContext context) async {
    final followController = TextEditingController();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var results = <FollowedUser>[];
        var isSearching = false;
        var searchSerial = 0;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> search(String value) async {
              searchSerial += 1;
              final serial = searchSerial;
              if (value.trim().length < 2) {
                setDialogState(() {
                  results = const [];
                  isSearching = false;
                });
                return;
              }
              setDialogState(() {
                isSearching = true;
              });
              final matches =
                  await widget.controller?.searchFollowableUsers(value) ??
                  const <FollowedUser>[];
              if (!context.mounted || serial != searchSerial) {
                return;
              }
              setDialogState(() {
                results = matches;
                isSearching = false;
              });
            }

            Future<void> followResult(FollowedUser user) async {
              await widget.controller?.followExistingUser(user);
              if (mounted) {
                setState(() {});
              }
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              backgroundColor: palette.surface,
              title: Text(l10n.t('account.social')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: followController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.t('account.followUser'),
                      ),
                      onChanged: search,
                      onSubmitted: (value) async {
                        if (results.isNotEmpty) {
                          await followResult(results.first);
                          return;
                        }
                        _followUser(value);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: Builder(
                        builder: (context) {
                          if (isSearching) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: palette.primary,
                                ),
                              ),
                            );
                          }
                          if (followController.text.trim().length >= 2 &&
                              results.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                l10n.t('account.noUserResults'),
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: results.length,
                            separatorBuilder: (_, _) =>
                                Divider(color: palette.border),
                            itemBuilder: (context, index) {
                              final user = results[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: palette.primarySoft,
                                  foregroundColor: palette.primary,
                                  child: Text(
                                    user.displayName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  user.displayName,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  user.email ?? user.handle,
                                  style: TextStyle(color: palette.textMuted),
                                ),
                                trailing: Icon(
                                  Icons.person_add_alt_1,
                                  color: palette.primary,
                                ),
                                onTap: () => followResult(user),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.t('common.cancel')),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                  ),
                  onPressed: results.isNotEmpty
                      ? () => followResult(results.first)
                      : null,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.t('common.add')),
                ),
              ],
            );
          },
        );
      },
    );
    // Keep this alive through the dialog route closing animation.
  }

  Future<void> _confirmDeleteActivity(
    BuildContext context,
    SportGame game,
  ) async {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(l10n.t('activity.deleteTitle')),
        content: Text(
          l10n.t('activity.deleteBody').replaceAll('{name}', game.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDeleteActivity(game.id);
      setState(() {});
    }
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
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedThemeMode = themeMode == ThemeMode.system
        ? platformBrightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light
        : themeMode;
    final resolvedLocale = locale ?? Localizations.localeOf(context);
    final selectedLocale =
        AppLocalizations.supportedLocales.any(
          (item) => item.languageCode == resolvedLocale.languageCode,
        )
        ? AppLocalizations.supportedLocales.firstWhere(
            (item) => item.languageCode == resolvedLocale.languageCode,
          )
        : AppLocalizations.supportedLocales.first;

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
          color: palette.surface,
          elevation: 10,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: palette.border),
          ),
          icon: Icon(Icons.translate_rounded, color: palette.text),
          initialValue: selectedLocale,
          onSelected: onLocaleChanged,
          itemBuilder: (context) => [
            for (final supportedLocale in AppLocalizations.supportedLocales)
              PopupMenuItem(
                value: supportedLocale,
                child: _PopupOption(
                  icon: Icons.translate,
                  label: AppLocalizations.languageName(supportedLocale),
                  selected:
                      selectedLocale.languageCode ==
                      supportedLocale.languageCode,
                  palette: palette,
                ),
              ),
          ],
        ),
        PopupMenuButton<ThemeMode>(
          tooltip: l10n.t('common.theme'),
          color: palette.surface,
          elevation: 10,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: palette.border),
          ),
          icon: Icon(Icons.wb_sunny_rounded, color: palette.text),
          initialValue: resolvedThemeMode,
          onSelected: onThemeModeChanged,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ThemeMode.light,
              child: _PopupOption(
                icon: Icons.wb_sunny_outlined,
                label: l10n.t('common.light'),
                selected: resolvedThemeMode == ThemeMode.light,
                palette: palette,
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: _PopupOption(
                icon: Icons.dark_mode_outlined,
                label: l10n.t('common.dark'),
                selected: resolvedThemeMode == ThemeMode.dark,
                palette: palette,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PopupOption extends StatelessWidget {
  const _PopupOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: selected ? palette.primary : palette.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? palette.primary : palette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (selected) Icon(Icons.check, color: palette.primary, size: 18),
      ],
    );
  }
}

class _QuickFollowPanel extends StatelessWidget {
  const _QuickFollowPanel({required this.controller, required this.onFollow});

  final GameStateController controller;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: palette.border.withValues(alpha: 0.45)),
              bottom: BorderSide(color: palette.border.withValues(alpha: 0.45)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.group_outlined, color: palette.primary),
                  const SizedBox(width: 10),
                  Text(
                    l10n.t('account.social'),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onFollow,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.t('account.followUser')),
                ),
              ),
              const SizedBox(height: 10),
              if (controller.following.isEmpty)
                Text(
                  l10n.t('account.noFollowed'),
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final followed in controller.following)
                      Chip(
                        avatar: CircleAvatar(
                          backgroundColor: palette.primarySoft,
                          foregroundColor: palette.primary,
                          child: Text(
                            followed.displayName.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        label: Text(followed.displayName),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap, this.onDelete});

  final SportGame game;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    InkResponse(
                      onTap: onDelete,
                      radius: 18,
                      child: Icon(
                        Icons.delete_outline,
                        color: palette.textMuted,
                        size: 18,
                      ),
                    ),
                  ],
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
                    for (final label
                        in (game.isCustom && game.participants.isNotEmpty
                                ? game.participants
                                : game.modes)
                            .take(2))
                      _ModeChip(
                        label: l10n.modeLabel(label),
                        color: game.color,
                      ),
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

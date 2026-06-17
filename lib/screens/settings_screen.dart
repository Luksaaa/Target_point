import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
import '../models/player_score.dart';
import '../theme/app_palette.dart';
import '../widgets/player_avatar.dart';

enum _GroupSortMode { newest, popular, az }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});

  final GameStateController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _joinSessionController = TextEditingController();
  final TextEditingController _groupSearchController = TextEditingController();
  _GroupSortMode _groupSortMode = _GroupSortMode.newest;
  int _newPlayerColor = 0xFF0F8B6B; // Default emerald

  final List<int> _colorOptions = const [
    0xFF0F8B6B, // Emerald Green
    0xFFC7352F, // Crimson Red
    0xFFF6D77B, // Amber Gold
    0xFF1A6EB4, // Cobalt Blue
    0xFF8E44AD, // Amethyst Purple
    0xFFE67E22, // Pumpkin Orange
  ];

  @override
  void initState() {
    super.initState();
    _groupSearchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _sessionNameController.dispose();
    _joinSessionController.dispose();
    _groupSearchController.dispose();
    super.dispose();
  }

  void _showAddPlayerDialog() {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    _playerNameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: palette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add New Player',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _playerNameController,
                      decoration: InputDecoration(
                        labelText: 'Player Name',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: palette.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: palette.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Avatar Color',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _colorOptions.map((cVal) {
                        final isSelected = cVal == _newPlayerColor;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _newPlayerColor = cVal;
                            });
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(cVal),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: palette.text, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.primary,
                          ),
                          onPressed: () {
                            final name = _playerNameController.text.trim();
                            if (name.isNotEmpty) {
                              widget.controller.addPlayerProfile(
                                name,
                                _newPlayerColor,
                              );
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Add Player'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmSettingsChange(VoidCallback onChange) {
    // If a match is already under way (some throws made), confirm first
    final hasMatchStarted = widget.controller.players.any(
      (p) => p.turns.isNotEmpty,
    );

    if (hasMatchStarted) {
      final palette = AppPalette.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: palette.surface,
          title: const Text('Restart Match?'),
          content: const Text(
            'Changing match settings will reset the current game state and scores. Do you wish to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: palette.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: palette.primary),
              onPressed: () {
                Navigator.of(context).pop();
                onChange();
              },
              child: const Text('Yes, Reset'),
            ),
          ],
        ),
      );
    } else {
      onChange();
    }
  }

  void _confirmRemovePlayer(PlayerScore player) {
    final palette = AppPalette.of(context);
    final isRegisteredGroupMember = player.userId != null;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        title: const Text('Remove player?'),
        content: Text(
          isRegisteredGroupMember
              ? 'Remove ${player.name} from this group and lineup?'
              : 'Remove ${player.name} from this lineup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: palette.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
            onPressed: () {
              Navigator.of(context).pop();
              widget.controller.removeGroupPlayer(player);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Match Setup',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: palette.text,
              ),
            ),
          ),
          _GroupBrowser(
            controller: widget.controller,
            sessionNameController: _sessionNameController,
            joinSessionController: _joinSessionController,
            searchController: _groupSearchController,
            sortMode: _groupSortMode,
            onSortChanged: (mode) => setState(() => _groupSortMode = mode),
            onOpenGroup: _openGroup,
            palette: palette,
          ),
          if (widget.controller.currentUser.isGuest) ...[
            const SizedBox(height: 24),
            Divider(color: palette.border.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Local players',
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _showAddPlayerDialog,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Player'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openGroup(UserGameGroup group) async {
    final loaded = await widget.controller.selectUserGroup(group.sessionId);
    if (!mounted || !loaded) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _GroupDetailScreen(
          controller: widget.controller,
          onAddPlayer: _showAddPlayerDialog,
          onConfirmSettingsChange: _confirmSettingsChange,
          onConfirmRemovePlayer: _confirmRemovePlayer,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }
}

class _GroupBrowser extends StatelessWidget {
  const _GroupBrowser({
    required this.controller,
    required this.sessionNameController,
    required this.joinSessionController,
    required this.searchController,
    required this.sortMode,
    required this.onSortChanged,
    required this.onOpenGroup,
    required this.palette,
  });

  final GameStateController controller;
  final TextEditingController sessionNameController;
  final TextEditingController joinSessionController;
  final TextEditingController searchController;
  final _GroupSortMode sortMode;
  final ValueChanged<_GroupSortMode> onSortChanged;
  final ValueChanged<UserGameGroup> onOpenGroup;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = controller.currentUser.isGuest;
    final groups = _filteredGroups(controller);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.sync_alt, color: palette.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Groups',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.text,
                  ),
                ),
              ),
            ],
          ),
          if (isGuest) ...[
            const SizedBox(height: 8),
            Text(
              'Guest mode is local only. Sign in to sync scores.',
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search groups',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_GroupSortMode>(
              selected: {sortMode},
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _GroupSortMode.newest,
                  label: Text('Newest'),
                ),
                ButtonSegment(
                  value: _GroupSortMode.popular,
                  label: Text('Popular'),
                ),
                ButtonSegment(value: _GroupSortMode.az, label: Text('A-Z')),
              ],
              onSelectionChanged: (selection) {
                onSortChanged(selection.first);
              },
            ),
            const SizedBox(height: 12),
            if (controller.liveMatchMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.liveMatchMessage!,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _showTextActionDialog(
                    context: context,
                    title: 'Create group',
                    hintText: 'Group name',
                    controller: sessionNameController,
                    actionLabel: 'Create',
                    maxLength: 16,
                    onSubmit: controller.createCloudSession,
                  ),
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('Create'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showTextActionDialog(
                    context: context,
                    title: 'Join group',
                    hintText: 'Group code',
                    controller: joinSessionController,
                    actionLabel: 'Join',
                    onSubmit: controller.joinCloudSession,
                  ),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Join'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (groups.isEmpty)
              Text(
                searchController.text.trim().isEmpty
                    ? 'No groups yet. Create or join one.'
                    : 'No groups match your search.',
                style: TextStyle(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: palette.border.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _GroupListTile(
                    group: group,
                    palette: palette,
                    isActive: controller.liveMatchId == group.sessionId,
                    onTap: () => onOpenGroup(group),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  List<UserGameGroup> _filteredGroups(GameStateController controller) {
    final groups = [...controller.userGroups];
    final liveMatchId = controller.liveMatchId;
    final activeSessionId = controller.activeSessionId;
    if (liveMatchId != null &&
        activeSessionId != null &&
        !groups.any((group) => group.sessionId == liveMatchId)) {
      groups.insert(
        0,
        UserGameGroup(
          sessionId: liveMatchId,
          groupCode: activeSessionId,
          sessionName: controller.activeSessionName.isEmpty
              ? activeSessionId
              : controller.activeSessionName,
          role: controller.isLiveHost ? 'owner' : 'participant',
          memberCount: controller.players.length,
        ),
      );
    }
    final query = searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? groups
        : groups
              .where(
                (group) =>
                    group.sessionName.toLowerCase().contains(query) ||
                    group.groupCode.toLowerCase().contains(query),
              )
              .toList();
    switch (sortMode) {
      case _GroupSortMode.newest:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _GroupSortMode.popular:
        filtered.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      case _GroupSortMode.az:
        filtered.sort(
          (a, b) => a.sessionName.toLowerCase().compareTo(
            b.sessionName.toLowerCase(),
          ),
        );
    }
    return filtered;
  }

  void _showTextActionDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    required TextEditingController controller,
    required String actionLabel,
    required Future<void> Function(String value) onSubmit,
    int? maxLength,
  }) {
    controller.clear();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: _SessionTextField(
            controller: controller,
            hintText: hintText,
            palette: palette,
            maxLength: maxLength,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text;
                Navigator.of(context).pop();
                onSubmit(value);
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }
}

class _GroupListTile extends StatelessWidget {
  const _GroupListTile({
    required this.group,
    required this.palette,
    required this.isActive,
    required this.onTap,
  });

  final UserGameGroup group;
  final AppPalette palette;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? palette.primary : palette.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                group.isOwner
                    ? Icons.admin_panel_settings_outlined
                    : Icons.groups_2_outlined,
                color: isActive ? Colors.white : palette.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.sessionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.groupCode} · ${group.isOwner ? "Admin" : "Member"} · ${group.memberCount} players',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _GroupDetailScreen extends StatelessWidget {
  const _GroupDetailScreen({
    required this.controller,
    required this.onAddPlayer,
    required this.onConfirmSettingsChange,
    required this.onConfirmRemovePlayer,
  });

  final GameStateController controller;
  final VoidCallback onAddPlayer;
  final void Function(VoidCallback onChange) onConfirmSettingsChange;
  final void Function(PlayerScore player) onConfirmRemovePlayer;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(controller.activeSessionName),
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final activeSessionId = controller.activeSessionId;
            final theme = Theme.of(context);
            final settings = controller.settings;
            final players = controller.players;

            if (activeSessionId == null) {
              return Center(
                child: Text(
                  'Select a group first.',
                  style: TextStyle(color: palette.textMuted),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActiveGroupDetails(
                    activeSessionId: activeSessionId,
                    palette: palette,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: controller.leaveGroup,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Leave'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (controller.isDartsGame) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: palette.border.withValues(alpha: 0.45),
                          ),
                          bottom: BorderSide(
                            color: palette.border.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            title: 'Game Mode',
                            icon: Icons.videogame_asset,
                            palette: palette,
                          ),
                          SegmentedButton<GameMode>(
                            segments: const [
                              ButtonSegment(
                                value: GameMode.x01,
                                label: Text('X01'),
                              ),
                              ButtonSegment(
                                value: GameMode.countUp,
                                label: Text('Count Up'),
                              ),
                            ],
                            selected: {settings.mode},
                            onSelectionChanged: (selection) {
                              onConfirmSettingsChange(() {
                                controller.updateSettings(
                                  mode: selection.first,
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (settings.mode == GameMode.x01) ...[
                            _SectionTitle(
                              title: 'Starting Score',
                              icon: Icons.score,
                              palette: palette,
                            ),
                            Wrap(
                              spacing: 8,
                              children: controller.scoreOptions.map((score) {
                                final isSelected =
                                    settings.startingScore == score;
                                return ChoiceChip(
                                  label: Text('$score'),
                                  selected: isSelected,
                                  selectedColor: palette.primarySoft,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? palette.primary
                                        : palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (_) {
                                    onConfirmSettingsChange(() {
                                      controller.updateSettings(
                                        startingScore: score,
                                      );
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            _SectionTitle(
                              title: 'Finish Rule',
                              icon: Icons.flag,
                              palette: palette,
                            ),
                            SegmentedButton<OutRule>(
                              segments: const [
                                ButtonSegment(
                                  value: OutRule.singleOut,
                                  label: Text('Single'),
                                ),
                                ButtonSegment(
                                  value: OutRule.doubleOut,
                                  label: Text('Double'),
                                ),
                                ButtonSegment(
                                  value: OutRule.masterOut,
                                  label: Text('Master'),
                                ),
                              ],
                              selected: {settings.outRule},
                              onSelectionChanged: (selection) {
                                onConfirmSettingsChange(() {
                                  controller.updateSettings(
                                    outRule: selection.first,
                                  );
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Text(
                        'Players Lineup',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.text,
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onAddPlayer,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add Player'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: palette.border.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: players.length,
                      onReorder: controller.reorderPlayers,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final isOwner = controller.isGroupOwner(player);
                        final canDelete =
                            player.userId == null ||
                            (controller.canManageGroupMembers && !isOwner);
                        return ListTile(
                          key: ValueKey('${player.userId}-${player.name}'),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: PlayerAvatar(
                            name: player.name,
                            avatarColorValue: player.avatarColorValue,
                            photoUrl: player.photoUrl,
                            radius: 20,
                          ),
                          title: Text(
                            player.name,
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            isOwner ? 'Group admin' : 'Member',
                            style: TextStyle(
                              color: isOwner
                                  ? palette.primary
                                  : palette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: palette.textMuted,
                                ),
                                onPressed: players.length > 1 && canDelete
                                    ? () => onConfirmRemovePlayer(player)
                                    : null,
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_handle,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}

class _ActiveGroupDetails extends StatelessWidget {
  const _ActiveGroupDetails({
    required this.activeSessionId,
    required this.palette,
  });

  final String activeSessionId;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: QrImageView(
              data: activeSessionId,
              version: QrVersions.auto,
              size: 112,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group code',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  activeSessionId,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: activeSessionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTextField extends StatelessWidget {
  const _SessionTextField({
    required this.controller,
    required this.hintText,
    required this.palette,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final AppPalette palette;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 1,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon, required this.palette});

  final String title;
  final IconData? icon;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: palette.textMuted),
            const SizedBox(width: 6),
          ],
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
import '../models/player_score.dart';
import '../theme/app_palette.dart';
import '../widgets/player_avatar.dart';

enum _GroupSortMode { newest, popular, az }

String _s(BuildContext context, String key) =>
    AppLocalizations.of(context).t(key);

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
                      _s(context, 'settings.addNewPlayer'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _playerNameController,
                      decoration: InputDecoration(
                        labelText: _s(context, 'settings.playerName'),
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
                      _s(context, 'settings.avatarColor'),
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
                            _s(context, 'common.cancel'),
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
                          child: Text(_s(context, 'settings.addPlayer')),
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
          title: Text(_s(context, 'settings.restartMatchTitle')),
          content: Text(_s(context, 'settings.restartMatchBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _s(context, 'common.cancel'),
                style: TextStyle(color: palette.textMuted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: palette.primary),
              onPressed: () {
                Navigator.of(context).pop();
                onChange();
              },
              child: Text(_s(context, 'settings.yesReset')),
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
        title: Text(_s(context, 'settings.removePlayerTitle')),
        content: Text(
          isRegisteredGroupMember
              ? 'Remove ${player.name} from this group and lineup?'
              : 'Remove ${player.name} from this lineup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              _s(context, 'common.cancel'),
              style: TextStyle(color: palette.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
            onPressed: () {
              Navigator.of(context).pop();
              widget.controller.removeGroupPlayer(player);
            },
            child: Text(_s(context, 'common.remove')),
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
              label: Text(_s(context, 'settings.addPlayer')),
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

  bool get _canScanQr {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _scanGroupQr(BuildContext context) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const _QrJoinScannerScreen()),
    );
    if (code == null || !context.mounted) {
      return;
    }
    await controller.joinCloudSession(code);
  }

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
                  _s(context, 'settings.groups'),
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
              _s(context, 'settings.guestLocal'),
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
                hintText: _s(context, 'settings.searchGroups'),
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
              segments: [
                ButtonSegment(
                  value: _GroupSortMode.newest,
                  label: Text(_s(context, 'common.newest')),
                ),
                ButtonSegment(
                  value: _GroupSortMode.popular,
                  label: Text(_s(context, 'common.popular')),
                ),
                ButtonSegment(
                  value: _GroupSortMode.az,
                  label: Text(_s(context, 'common.az')),
                ),
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
                    title: _s(context, 'settings.createGroup'),
                    hintText: _s(context, 'settings.groupName'),
                    controller: sessionNameController,
                    actionLabel: _s(context, 'common.create'),
                    maxLength: 16,
                    onSubmit: controller.createCloudSession,
                  ),
                  icon: const Icon(Icons.add_link, size: 18),
                  label: Text(_s(context, 'common.create')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showTextActionDialog(
                    context: context,
                    title: _s(context, 'settings.joinGroup'),
                    hintText: _s(context, 'settings.groupCode'),
                    controller: joinSessionController,
                    actionLabel: _s(context, 'settings.joinGroup'),
                    onSubmit: controller.joinCloudSession,
                  ),
                  icon: const Icon(Icons.login, size: 18),
                  label: Text(_s(context, 'settings.joinGroup')),
                ),
                if (_canScanQr)
                  OutlinedButton.icon(
                    onPressed: () => _scanGroupQr(context),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text(_s(context, 'settings.scanQr')),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (groups.isEmpty)
              Text(
                searchController.text.trim().isEmpty
                    ? _s(context, 'settings.noGroups')
                    : _s(context, 'settings.noGroupMatches'),
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
              child: Text(_s(context, 'common.cancel')),
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
                    '${group.groupCode} - ${group.isOwner ? _s(context, 'settings.groupAdmin') : _s(context, 'settings.member')} - ${group.memberCount}',
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

class _ImportGroupSelection {
  const _ImportGroupSelection({required this.group, required this.mode});

  final UserGameGroup group;
  final GroupImportMode mode;
}

class _ImportModeTile extends StatelessWidget {
  const _ImportModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? palette.primary : palette.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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

  Future<void> _showImportStatsDialog(
    BuildContext context,
    AppPalette palette,
  ) async {
    final groups = controller.userGroups
        .where((group) => group.sessionId != controller.liveMatchId)
        .toList();
    if (groups.isEmpty) {
      return;
    }

    final selection = await showDialog<_ImportGroupSelection>(
      context: context,
      builder: (dialogContext) {
        var mode = GroupImportMode.addToCurrent;
        UserGameGroup? selectedGroup;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.surface,
              title: Text(
                _s(context, 'settings.importStats'),
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: groups.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: palette.border),
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final isSelected =
                              selectedGroup?.sessionId == group.sessionId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.groups,
                              color: isSelected
                                  ? palette.primary
                                  : palette.textMuted,
                            ),
                            title: Text(
                              group.sessionName,
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              group.groupCode,
                              style: TextStyle(color: palette.textMuted),
                            ),
                            onTap: () {
                              setDialogState(() {
                                selectedGroup = group;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ImportModeTile(
                      selected: mode == GroupImportMode.addToCurrent,
                      title: _s(context, 'settings.importAdd'),
                      subtitle: _s(context, 'settings.importAddDescription'),
                      palette: palette,
                      onTap: () {
                        setDialogState(() {
                          mode = GroupImportMode.addToCurrent;
                        });
                      },
                    ),
                    _ImportModeTile(
                      selected: mode == GroupImportMode.useSourceValues,
                      title: _s(context, 'settings.importUseSource'),
                      subtitle: _s(
                        context,
                        'settings.importUseSourceDescription',
                      ),
                      palette: palette,
                      onTap: () {
                        setDialogState(() {
                          mode = GroupImportMode.useSourceValues;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_s(context, 'common.cancel')),
                ),
                FilledButton(
                  onPressed: selectedGroup == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                          _ImportGroupSelection(
                            group: selectedGroup!,
                            mode: mode,
                          ),
                        ),
                  child: Text(_s(context, 'common.import')),
                ),
              ],
            );
          },
        );
      },
    );

    if (selection == null) {
      return;
    }
    await controller.importStatsFromGroup(
      selection.group.sessionId,
      mode: selection.mode,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _s(context, 'settings.importCompleted'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: palette.primary,
      ),
    );
  }

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
                  _s(context, 'settings.selectGroupFirst'),
                  style: TextStyle(color: palette.textMuted),
                ),
              );
            }

            final canManageLineup = controller.canManageLineup;
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
                        label: Text(_s(context, 'settings.leave')),
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
                            title: _s(context, 'settings.gameMode'),
                            icon: Icons.videogame_asset,
                            palette: palette,
                          ),
                          SegmentedButton<GameMode>(
                            segments: [
                              ButtonSegment(
                                value: GameMode.x01,
                                label: Text('X01'),
                              ),
                              ButtonSegment(
                                value: GameMode.countUp,
                                label: Text(_s(context, 'settings.countUp')),
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
                              title: _s(context, 'settings.startingScore'),
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
                              title: _s(context, 'settings.finishRule'),
                              icon: Icons.flag,
                              palette: palette,
                            ),
                            SegmentedButton<OutRule>(
                              segments: [
                                ButtonSegment(
                                  value: OutRule.singleOut,
                                  label: Text(_s(context, 'settings.single')),
                                ),
                                ButtonSegment(
                                  value: OutRule.doubleOut,
                                  label: Text(_s(context, 'settings.double')),
                                ),
                                ButtonSegment(
                                  value: OutRule.masterOut,
                                  label: Text(_s(context, 'settings.master')),
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
                            const SizedBox(height: 16),
                            _SectionTitle(
                              title: _s(context, 'settings.checkoutAdvice'),
                              icon: Icons.psychology_alt,
                              palette: palette,
                            ),
                            SegmentedButton<CheckoutStrategy>(
                              segments: [
                                ButtonSegment(
                                  value: CheckoutStrategy.professional,
                                  label: Text(
                                    _s(context, 'settings.professional'),
                                  ),
                                ),
                                ButtonSegment(
                                  value: CheckoutStrategy.adaptive,
                                  label: Text(_s(context, 'settings.adaptive')),
                                ),
                              ],
                              selected: {controller.checkoutStrategy},
                              onSelectionChanged: (selection) {
                                controller.updateCheckoutStrategy(
                                  selection.first,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _SectionTitle(
                    title: _s(context, 'settings.deviceMode'),
                    icon: Icons.devices,
                    palette: palette,
                  ),
                  Text(
                    _s(context, 'settings.deviceModeDescription'),
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final mode in GroupDeviceMode.values)
                    _DeviceModeTile(
                      mode: mode,
                      selected: controller.deviceMode == mode,
                      enabled: controller.canManageLineup,
                      palette: palette,
                      onTap: () => controller.updateDeviceMode(mode),
                    ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Text(
                        _s(context, 'settings.playersLineup'),
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
                        onPressed: canManageLineup ? onAddPlayer : null,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: Text(_s(context, 'settings.addPlayer')),
                      ),
                      if (controller.canManageLineup &&
                          controller.userGroups.any(
                            (group) =>
                                group.sessionId != controller.liveMatchId,
                          ))
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showImportStatsDialog(context, palette),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(_s(context, 'settings.importStats')),
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
                      buildDefaultDragHandles: false,
                      itemCount: players.length,
                      onReorder: canManageLineup
                          ? controller.reorderPlayers
                          : (_, _) {},
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final isOwner = controller.isGroupOwner(player);
                        final isCurrent =
                            index == controller.currentPlayerIndex;
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
                            [
                              if (isCurrent)
                                _s(context, 'settings.nowThrowing'),
                              isOwner
                                  ? _s(context, 'settings.groupAdmin')
                                  : _s(context, 'settings.member'),
                            ].join(' - '),
                            style: TextStyle(
                              color: isCurrent || isOwner
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
                              if (canManageLineup)
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
          SizedBox(
            width: 128,
            height: 128,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Container(
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
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _s(context, 'settings.groupCode'),
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
                      SnackBar(
                        content: Text(_s(context, 'settings.codeCopied')),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(_s(context, 'settings.copyCode')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrJoinScannerScreen extends StatefulWidget {
  const _QrJoinScannerScreen();

  @override
  State<_QrJoinScannerScreen> createState() => _QrJoinScannerScreenState();
}

class _QrJoinScannerScreenState extends State<_QrJoinScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_s(context, 'settings.scanGroupQr')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) {
                return;
              }
              for (final barcode in capture.barcodes) {
                final code = _groupCodeFromQrValue(barcode.rawValue);
                if (code == null) {
                  continue;
                }
                _handled = true;
                Navigator.of(context).pop(code);
                return;
              }
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: palette.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _s(context, 'settings.scanHint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _groupCodeFromQrValue(String? rawValue) {
  final value = rawValue?.trim().toUpperCase();
  if (value == null || value.isEmpty) {
    return null;
  }
  final match = RegExp(r'([A-Z]{3}[0-9]{3})').firstMatch(value);
  return match?.group(1);
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

class _DeviceModeTile extends StatelessWidget {
  const _DeviceModeTile({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.palette,
    required this.onTap,
  });

  final GroupDeviceMode mode;
  final bool selected;
  final bool enabled;
  final AppPalette palette;
  final VoidCallback onTap;

  String get _title {
    return switch (mode) {
      GroupDeviceMode.ownDevice => 'Own device',
      GroupDeviceMode.sharedDevices => 'Shared devices',
      GroupDeviceMode.adminDevice => 'Admin device',
    };
  }

  String get _description {
    return switch (mode) {
      GroupDeviceMode.ownDevice =>
        'Each signed-in player enters only their own turn.',
      GroupDeviceMode.sharedDevices =>
        'Any group member can enter the current player turn.',
      GroupDeviceMode.adminDevice =>
        'Only the group admin enters throws and scores for everyone.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? palette.primary : palette.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      color: enabled ? palette.text : palette.textMuted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _description,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

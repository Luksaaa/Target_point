import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
import '../models/player_score.dart';
import '../theme/app_palette.dart';
import '../widgets/profile_dialog.dart';

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
  void dispose() {
    _playerNameController.dispose();
    _sessionNameController.dispose();
    _joinSessionController.dispose();
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
    final settings = widget.controller.settings;
    final players = widget.controller.players;

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
          _GroupPanel(
            controller: widget.controller,
            sessionNameController: _sessionNameController,
            joinSessionController: _joinSessionController,
            palette: palette,
          ),
          const SizedBox(height: 16),

          if (widget.controller.isDartsGame) ...[
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
                      ButtonSegment(value: GameMode.x01, label: Text('X01')),
                      ButtonSegment(
                        value: GameMode.countUp,
                        label: Text('Count Up'),
                      ),
                    ],
                    selected: {settings.mode},
                    onSelectionChanged: (selection) {
                      _confirmSettingsChange(() {
                        widget.controller.updateSettings(mode: selection.first);
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
                      children: widget.controller.scoreOptions.map((score) {
                        final isSelected = settings.startingScore == score;
                        return ChoiceChip(
                          label: Text('$score'),
                          selected: isSelected,
                          selectedColor: palette.primarySoft,
                          labelStyle: TextStyle(
                            color: isSelected ? palette.primary : palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            _confirmSettingsChange(() {
                              widget.controller.updateSettings(
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
                        _confirmSettingsChange(() {
                          widget.controller.updateSettings(
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

          // Players List & Management
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showAddPlayerDialog,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text(
                  'Add Player',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: palette.border.withValues(alpha: 0.45)),
              ),
            ),
            child: SizedBox(
              height: 300,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                onReorder: widget.controller.reorderPlayers,
                itemBuilder: (context, index) {
                  final player = players[index];
                  final isOwner = widget.controller.isGroupOwner(player);
                  final canDelete =
                      player.userId == null ||
                      (widget.controller.canManageGroupMembers && !isOwner);

                  return Card(
                    key: ValueKey(player.name),
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: palette.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Color(player.avatarColorValue),
                        foregroundColor: Colors.white,
                        radius: 16,
                        child: Text(player.name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(
                        player.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.text,
                        ),
                      ),
                      subtitle: Text(
                        isOwner ? 'Group admin' : 'Tap to edit stats',
                        style: TextStyle(
                          color: isOwner ? palette.primary : palette.textMuted,
                          fontSize: 11,
                          fontWeight: isOwner
                              ? FontWeight.w900
                              : FontWeight.w600,
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
                                ? () => _confirmRemovePlayer(player)
                                : null,
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Open profile dialog to view details
                        final pIndex = widget.controller.profiles.indexWhere(
                          (p) => p.name == player.name,
                        );
                        if (pIndex != -1) {
                          showDialog(
                            context: context,
                            builder: (context) => ProfileDialog(
                              profile: widget.controller.profiles[pIndex],
                              controller: widget.controller,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _GroupPanel extends StatelessWidget {
  const _GroupPanel({
    required this.controller,
    required this.sessionNameController,
    required this.joinSessionController,
    required this.palette,
  });

  final GameStateController controller;
  final TextEditingController sessionNameController;
  final TextEditingController joinSessionController;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = controller.currentUser.isGuest;
    final activeSessionId = controller.activeSessionId;

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
                  'Group',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.text,
                  ),
                ),
              ),
              if (activeSessionId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Live',
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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
            const SizedBox(height: 8),
            Text(
              activeSessionId == null
                  ? 'Create or join a group to sync this scoreboard.'
                  : controller.activeSessionName,
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (controller.liveMatchMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.liveMatchMessage!,
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
            ],
            if (activeSessionId != null) ...[
              const SizedBox(height: 12),
              Row(
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
                            Clipboard.setData(
                              ClipboardData(text: activeSessionId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Group code copied'),
                              ),
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
            ],
            const SizedBox(height: 12),
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
                if (activeSessionId != null)
                  OutlinedButton.icon(
                    onPressed: controller.leaveGroup,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Leave'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
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

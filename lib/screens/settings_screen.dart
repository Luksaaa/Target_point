import 'package:flutter/material.dart';

import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
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

          if (widget.controller.isDartsGame) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
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
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: SizedBox(
              height: 300,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                onReorder: widget.controller.reorderPlayers,
                itemBuilder: (context, index) {
                  final player = players[index];

                  return Card(
                    key: ValueKey(player.name),
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: palette.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: palette.border),
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
                        'Tap to edit stats',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
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
                            onPressed: players.length > 1
                                ? () => widget.controller.deletePlayer(index)
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

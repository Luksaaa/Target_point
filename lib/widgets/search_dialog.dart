import 'package:flutter/material.dart';

import '../models/game_state_controller.dart';
import '../models/game_settings.dart';
import '../models/match_history.dart';
import '../theme/app_palette.dart';
import 'player_avatar.dart';
import 'profile_dialog.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({required this.controller, super.key});

  final GameStateController controller;

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.searchQuery;
    _searchController.addListener(() {
      widget.controller.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Dialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search players or matches...',
                      hintStyle: TextStyle(color: palette.textMuted),
                      prefixIcon: Icon(Icons.search, color: palette.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: palette.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: palette.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final filteredP = widget.controller.filteredProfiles;
                  final filteredH = widget.controller.filteredHistory;

                  if (filteredP.isEmpty && filteredH.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: palette.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No results found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    children: [
                      if (filteredP.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Text(
                            'Players (${filteredP.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        ...filteredP.map(
                          (profile) => Card(
                            color: palette.surfaceMuted,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: palette.border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(
                                  profile.avatarColorValue,
                                ),
                                foregroundColor: Colors.white,
                                child: Text(
                                  profile.name.substring(0, 1).toUpperCase(),
                                ),
                              ),
                              title: Text(
                                profile.name,
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Avg: ${profile.averageScore.toStringAsFixed(1)} | High: ${profile.highestTurn} | Wins: ${profile.matchesWon}',
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: palette.textMuted,
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (context) => ProfileDialog(
                                    profile: profile,
                                    controller: widget.controller,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (filteredH.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Text(
                            'Match History (${filteredH.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        ...filteredH.map(
                          (match) => Card(
                            color: palette.surfaceMuted,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: palette.border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: palette.primarySoft,
                                foregroundColor: palette.primary,
                                child: const Icon(Icons.emoji_events),
                              ),
                              title: Text(
                                'Winner: ${match.winnerName}',
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${match.settings.mode == GameMode.x01 ? "X01 (${match.settings.startingScore})" : "Count Up"} | ${match.date.day}.${match.date.month}.${match.date.year}',
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: palette.textMuted,
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                // Open match recap directly
                                showDialog(
                                  context: context,
                                  builder: (context) => MatchRecapDialog(
                                    match: match,
                                    palette: palette,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple extension helper for display name
extension GameSettingsX on GameSettings {
  static String modeName(GameMode mode) {
    return mode == GameMode.x01 ? 'X01' : 'Count Up';
  }
}

class MatchRecapDialog extends StatelessWidget {
  const MatchRecapDialog({
    required this.match,
    required this.palette,
    super.key,
  });

  final MatchHistoryEntry match;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isX01 = match.settings.mode == GameMode.x01;
    final modeLabel = isX01
        ? 'X01 (${match.settings.startingScore}) - Finish: ${match.settings.outRule.name.replaceAll('Out', '').toUpperCase()}'
        : 'Count Up';

    return Dialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Recap',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        modeLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: match.finalScores.map((player) {
                    final isWinner = player.name == match.winnerName;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? palette.primarySoft
                            : palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isWinner ? palette.primary : palette.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(
                            name: player.name,
                            avatarColorValue: player.avatarColorValue,
                            photoUrl: player.photoUrl,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      player.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: palette.text,
                                          ),
                                    ),
                                    if (isWinner) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.emoji_events,
                                        color: palette.accent,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Avg: ${player.average.toStringAsFixed(1)} | Throws: ${player.totalThrows}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isX01
                                ? '${player.remaining}'
                                : '${player.totalScored}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isWinner ? palette.primary : palette.text,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Played on ${match.date.day}.${match.date.month}.${match.date.year} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

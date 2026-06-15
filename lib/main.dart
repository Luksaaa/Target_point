import 'package:flutter/material.dart';

import 'models/game_state_controller.dart';
import 'theme/app_palette.dart';
import 'widgets/search_dialog.dart';
import 'screens/play_screen.dart';
import 'screens/scoreboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/account_screen.dart';

void main() {
  runApp(const TargetPointApp());
}

class TargetPointApp extends StatelessWidget {
  const TargetPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Point',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const DartMatchScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F8B6B),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0A0D0C)
          : const Color(0xFFF7F9F8),
      useMaterial3: true,
    );
  }
}

class DartMatchScreen extends StatefulWidget {
  const DartMatchScreen({super.key});

  @override
  State<DartMatchScreen> createState() => _DartMatchScreenState();
}

class _DartMatchScreenState extends State<DartMatchScreen> {
  late final GameStateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameStateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNewMatch() {
    final hasThrows = _controller.players.any((p) => p.turns.isNotEmpty);
    if (hasThrows) {
      final palette = AppPalette.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: palette.surface,
          title: const Text('New Match?'),
          content: const Text('This will reset the current game score. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: palette.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: palette.primary),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _controller.startNewMatch();
                });
              },
              child: const Text('Yes, Reset'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _controller.startNewMatch();
      });
    }
  }

  void _openAccountScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountScreen(controller: _controller),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchDialog(controller: _controller),
    );
  }

  Widget _buildActiveScreen(bool isWide) {
    return switch (_controller.activeTabIndex) {
      0 => PlayScreen(controller: _controller, isWide: isWide),
      1 => ScoreboardScreen(controller: _controller),
      2 => SettingsScreen(controller: _controller),
      3 => HistoryScreen(controller: _controller),
      _ => PlayScreen(controller: _controller, isWide: isWide),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;

            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (isWide) {
                  // Wide/Desktop Layout with Navigation Rail (Sidebar)
                  return Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: palette.border)),
                        ),
                        child: NavigationRail(
                          backgroundColor: palette.surface,
                          selectedIndex: _controller.activeTabIndex,
                          onDestinationSelected: _controller.changeTab,
                          labelType: NavigationRailLabelType.all,
                          leading: Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: palette.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.adjust, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Target Point',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: palette.text,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                          trailing: Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  color: palette.primary,
                                  tooltip: 'Search',
                                  onPressed: _showSearchDialog,
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  color: palette.primary,
                                  tooltip: 'New Match',
                                  onPressed: _handleNewMatch,
                                ),
                                const SizedBox(height: 12),
                                Tooltip(
                                  message: 'Account & Settings',
                                  child: InkWell(
                                    onTap: _openAccountScreen,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: palette.primary, width: 2),
                                        color: Color(_controller.currentPlayer.avatarColorValue),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _controller.currentPlayer.name.substring(0, 1).toUpperCase(),
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
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          destinations: [
                            NavigationRailDestination(
                              icon: const Icon(Icons.play_circle_outline),
                              selectedIcon: Icon(Icons.play_circle, color: palette.primary),
                              label: const Text('Play'),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.bar_chart_outlined),
                              selectedIcon: Icon(Icons.bar_chart, color: palette.primary),
                              label: const Text('Scores'),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.settings_outlined),
                              selectedIcon: Icon(Icons.settings, color: palette.primary),
                              label: const Text('Settings'),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.history_outlined),
                              selectedIcon: Icon(Icons.history, color: palette.primary),
                              label: const Text('History'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _buildActiveScreen(true),
                        ),
                      ),
                    ],
                  );
                }

                // Mobile/Narrow Layout with Top App Bar and Bottom Navigation Bar
                return Scaffold(
                  appBar: AppBar(
                    backgroundColor: palette.surface,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    shape: Border(bottom: BorderSide(color: palette.border)),
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.adjust, color: Colors.white, size: 24),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Point',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          'Darts Scorer',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        color: palette.text,
                        onPressed: _showSearchDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: palette.text,
                        onPressed: _handleNewMatch,
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Account & Settings',
                        child: GestureDetector(
                          onTap: _openAccountScreen,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.primary, width: 2.5),
                              color: Color(_controller.currentPlayer.avatarColorValue),
                            ),
                            child: Center(
                              child: Text(
                                _controller.currentPlayer.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildActiveScreen(false),
                  ),
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: _controller.activeTabIndex,
                    onTap: _controller.changeTab,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: palette.surface,
                    selectedItemColor: palette.primary,
                    unselectedItemColor: palette.textMuted,
                    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.play_circle_outline),
                        activeIcon: Icon(Icons.play_circle),
                        label: 'Play',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.bar_chart_outlined),
                        activeIcon: Icon(Icons.bar_chart),
                        label: 'Scores',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings_outlined),
                        activeIcon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.history_outlined),
                        activeIcon: Icon(Icons.history),
                        label: 'History',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

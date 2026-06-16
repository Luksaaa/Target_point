import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'models/game_state_controller.dart';
import 'theme/app_palette.dart';
import 'screens/play_screen.dart';
import 'screens/scoreboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/account_screen.dart';
import 'screens/game_hub_screen.dart';
import 'models/sport_game.dart';

void main() {
  runApp(const TargetPointApp());
}

class TargetPointApp extends StatefulWidget {
  const TargetPointApp({super.key});

  @override
  State<TargetPointApp> createState() => _TargetPointAppState();
}

class _TargetPointAppState extends State<TargetPointApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Point',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: RootScreen(
        themeMode: _themeMode,
        locale: _locale,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        onLocaleChanged: (locale) => setState(() => _locale = locale),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark
        ? const AppPalette(
            background: Color(0xFF0F1115),
            surface: Color(0xFF171A20),
            surfaceMuted: Color(0xFF20242C),
            primary: Color(0xFF4F8EF7),
            primarySoft: Color(0xFF1D2E47),
            accent: Color(0xFFE3A72F),
            text: Color(0xFFF4F6F8),
            textMuted: Color(0xFF9AA4B2),
            border: Color(0xFF2B313A),
            dartboardDark: Color(0xFF222222),
            dartboardLight: Color(0xFFF2E8CF),
          )
        : const AppPalette(
            background: Color(0xFFF6F7F9),
            surface: Color(0xFFFFFFFF),
            surfaceMuted: Color(0xFFEDEFF3),
            primary: Color(0xFF1D5FAD),
            primarySoft: Color(0xFFDCE8F7),
            accent: Color(0xFFB7791F),
            text: Color(0xFF18202A),
            textMuted: Color(0xFF687386),
            border: Color(0xFFD8DEE7),
            dartboardDark: Color(0xFF222222),
            dartboardLight: Color(0xFFF2E8CF),
          );

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: palette.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      useMaterial3: true,
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({
    required this.themeMode,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final List<SportGame> _customActivities = [];

  void _handleCreateActivity({
    required String name,
    required String description,
    required List<String> participants,
  }) {
    setState(() {
      _customActivities.add(
        SportGame(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          subtitle: description.isNotEmpty
              ? description
              : 'Custom rules activity',
          icon: Icons.sports_kabaddi,
          color: const Color(0xFF1A6EB4),
          modes: [description.isNotEmpty ? description : 'Custom Rules'],
          participants: participants,
          isCustom: true,
          status: SportGameStatus.ready,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SportMatchScreen(
      game: sportGames.first,
      customActivities: _customActivities,
      onCreateActivity: _handleCreateActivity,
      themeMode: widget.themeMode,
      locale: widget.locale,
      onThemeModeChanged: widget.onThemeModeChanged,
      onLocaleChanged: widget.onLocaleChanged,
    );
  }
}

class SportMatchScreen extends StatefulWidget {
  const SportMatchScreen({
    required this.game,
    required this.customActivities,
    required this.onCreateActivity,
    required this.themeMode,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    super.key,
  });

  final SportGame game;
  final List<SportGame> customActivities;
  final void Function({
    required String name,
    required String description,
    required List<String> participants,
  })
  onCreateActivity;
  final ThemeMode themeMode;
  final Locale? locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<SportMatchScreen> createState() => _SportMatchScreenState();
}

class _SportMatchScreenState extends State<SportMatchScreen> {
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
          content: const Text(
            'This will reset the current game score. Are you sure?',
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
        builder: (_) => AccountScreen(
          controller: _controller,
          themeMode: widget.themeMode,
          locale: widget.locale,
          onThemeModeChanged: widget.onThemeModeChanged,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
  }

  void _openActivitiesScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameHubScreen(
          themeMode: widget.themeMode,
          locale: widget.locale,
          customActivities: widget.customActivities,
          onCreateActivity: widget.onCreateActivity,
          onThemeModeChanged: widget.onThemeModeChanged,
          onLocaleChanged: widget.onLocaleChanged,
          onOpenSport: (game) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SportMatchScreen(
                  game: game,
                  customActivities: widget.customActivities,
                  onCreateActivity: widget.onCreateActivity,
                  themeMode: widget.themeMode,
                  locale: widget.locale,
                  onThemeModeChanged: widget.onThemeModeChanged,
                  onLocaleChanged: widget.onLocaleChanged,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveScreen(bool isWide) {
    return switch (_controller.activeTabIndex) {
      0 => PlayScreen(
        controller: _controller,
        isWide: isWide,
        game: widget.game,
      ),
      1 => ScoreboardScreen(controller: _controller),
      2 => SettingsScreen(controller: _controller),
      3 => HistoryScreen(controller: _controller),
      _ => PlayScreen(
        controller: _controller,
        isWide: isWide,
        game: widget.game,
      ),
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
                          border: Border(
                            right: BorderSide(color: palette.border),
                          ),
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
                                child: const Icon(
                                  Icons.adjust,
                                  color: Colors.white,
                                  size: 28,
                                ),
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
                                  icon: const Icon(Icons.apps),
                                  color: palette.primary,
                                  tooltip: 'Activities',
                                  onPressed: _openActivitiesScreen,
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
                                        border: Border.all(
                                          color: palette.primary,
                                          width: 2,
                                        ),
                                        color: Color(
                                          _controller
                                              .currentUser
                                              .avatarColorValue,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _controller.currentUser.initials,
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
                              selectedIcon: Icon(
                                Icons.play_circle,
                                color: palette.primary,
                              ),
                              label: const Text('Play'),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.bar_chart_outlined),
                              selectedIcon: Icon(
                                Icons.bar_chart,
                                color: palette.primary,
                              ),
                              label: const Text('Scores'),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.tune_outlined),
                              selectedIcon: Icon(
                                Icons.tune,
                                color: palette.primary,
                              ),
                              label: const Text('Settings'),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.history_outlined),
                              selectedIcon: Icon(
                                Icons.history,
                                color: palette.primary,
                              ),
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
                        child: const Icon(
                          Icons.adjust,
                          color: Colors.white,
                          size: 24,
                        ),
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
                          widget.game.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.apps),
                        color: palette.text,
                        tooltip: 'Activities',
                        onPressed: _openActivitiesScreen,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: palette.text,
                        tooltip: 'New Match',
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
                              border: Border.all(
                                color: palette.primary,
                                width: 2.5,
                              ),
                              color: Color(
                                _controller.currentUser.avatarColorValue,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _controller.currentUser.initials,
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
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
                        icon: Icon(Icons.tune_outlined),
                        activeIcon: Icon(Icons.tune),
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

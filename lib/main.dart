import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'widgets/responsive_content.dart';

void main() {
  runApp(const GameHubApp());
}

class GameHubApp extends StatefulWidget {
  const GameHubApp({super.key});

  @override
  State<GameHubApp> createState() => _GameHubAppState();
}

class _GameHubAppState extends State<GameHubApp> {
  static const _themePreferenceKey = 'app_theme_mode';
  static const _localePreferenceKey = 'app_locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadAppPreferences();
  }

  Future<void> _loadAppPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString(_themePreferenceKey);
    final savedLocale = preferences.getString(_localePreferenceKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = switch (savedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _locale = savedLocale == null || savedLocale.isEmpty
          ? null
          : Locale(savedLocale);
    });
  }

  Future<void> _handleThemeModeChanged(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final preferences = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await preferences.remove(_themePreferenceKey);
    } else {
      await preferences.setString(_themePreferenceKey, mode.name);
    }
  }

  Future<void> _handleLocaleChanged(Locale? locale) async {
    setState(() => _locale = locale);
    final preferences = await SharedPreferences.getInstance();
    if (locale == null) {
      await preferences.remove(_localePreferenceKey);
    } else {
      await preferences.setString(_localePreferenceKey, locale.languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game hub',
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
      scrollBehavior: const _GameHubScrollBehavior(),
      home: RootScreen(
        themeMode: _themeMode,
        locale: _locale,
        onThemeModeChanged: _handleThemeModeChanged,
        onLocaleChanged: _handleLocaleChanged,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark
        ? const AppPalette(
            background: Color(0xFF0B0D12),
            surface: Color(0xFF151922),
            surfaceMuted: Color(0xFF202634),
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
            background: Color(0xFFF7F8FB),
            surface: Color(0xFFFFFFFF),
            surfaceMuted: Color(0xFFEFF3F8),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.border.withValues(alpha: 0.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      useMaterial3: true,
    );
  }
}

class _GameHubScrollBehavior extends MaterialScrollBehavior {
  const _GameHubScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
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

  void _handleDeleteActivity(String id) {
    setState(() {
      _customActivities.removeWhere((activity) => activity.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SportMatchScreen(
      game: sportGames.first,
      customActivities: _customActivities,
      onCreateActivity: _handleCreateActivity,
      onDeleteActivity: _handleDeleteActivity,
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
    required this.onDeleteActivity,
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
  final ValueChanged<String> onDeleteActivity;
  final ThemeMode themeMode;
  final Locale? locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<SportMatchScreen> createState() => _SportMatchScreenState();
}

class _SportMatchScreenState extends State<SportMatchScreen> {
  late final GameStateController _controller;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _controller = GameStateController(
      gameId: widget.game.id,
      gameName: widget.game.name,
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    _controller.changeTab(index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleNewMatch() {
    if (_controller.hasActiveMatchProgress) {
      final palette = AppPalette.of(context);
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: palette.surface,
          title: Text(l10n.t('match.newTitle')),
          content: Text(l10n.t('match.newDescription')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.t('common.cancel'),
                style: TextStyle(color: palette.textMuted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: palette.primary),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _controller.startNewMatch();
                });
              },
              child: Text(l10n.t('match.resetConfirm')),
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
          onDeleteActivity: widget.onDeleteActivity,
          onThemeModeChanged: widget.onThemeModeChanged,
          onLocaleChanged: widget.onLocaleChanged,
          onOpenSport: (game) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SportMatchScreen(
                  game: game,
                  customActivities: widget.customActivities,
                  onCreateActivity: widget.onCreateActivity,
                  onDeleteActivity: widget.onDeleteActivity,
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

  List<Widget> _buildMobilePages() {
    return [
      ResponsiveContent(
        maxWidth: 980,
        padding: const EdgeInsets.all(16),
        child: PlayScreen(
          controller: _controller,
          isWide: false,
          game: widget.game,
        ),
      ),
      ResponsiveContent(
        maxWidth: 980,
        padding: const EdgeInsets.all(16),
        child: ScoreboardScreen(controller: _controller),
      ),
      ResponsiveContent(
        maxWidth: 980,
        padding: const EdgeInsets.all(16),
        child: SettingsScreen(controller: _controller),
      ),
      ResponsiveContent(
        maxWidth: 980,
        padding: const EdgeInsets.all(16),
        child: HistoryScreen(controller: _controller),
      ),
    ];
  }

  List<Widget> _buildWidePages() {
    return [
      ResponsiveContent(
        maxWidth: 1320,
        padding: const EdgeInsets.all(24),
        child: PlayScreen(
          controller: _controller,
          isWide: true,
          game: widget.game,
        ),
      ),
      ResponsiveContent(
        maxWidth: 1320,
        padding: const EdgeInsets.all(24),
        child: ScoreboardScreen(controller: _controller),
      ),
      ResponsiveContent(
        maxWidth: 1320,
        padding: const EdgeInsets.all(24),
        child: SettingsScreen(controller: _controller),
      ),
      ResponsiveContent(
        maxWidth: 1320,
        padding: const EdgeInsets.all(24),
        child: HistoryScreen(controller: _controller),
      ),
    ];
  }

  Widget _buildAccountAvatar(AppPalette palette, {double size = 38}) {
    final user = _controller.currentUser;
    final photoUrl = user.photoUrl;
    final imageProvider = _imageProviderFromPhotoUrl(photoUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.primary, width: 2),
        color: Color(user.avatarColorValue),
        image: imageProvider == null
            ? null
            : DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
      child: imageProvider == null
          ? Center(
              child: Text(
                user.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.36,
                ),
              ),
            )
          : null,
    );
  }

  ImageProvider? _imageProviderFromPhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    if (photoUrl.startsWith('data:image')) {
      final commaIndex = photoUrl.indexOf(',');
      if (commaIndex == -1) {
        return null;
      }
      return MemoryImage(base64Decode(photoUrl.substring(commaIndex + 1)));
    }
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final localizedGameName = l10n.gameName(widget.game.id, widget.game.name);

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
                          onDestinationSelected: _goToTab,
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
                                l10n.t('app.title'),
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
                                  tooltip: l10n.t('action.activities'),
                                  onPressed: _openActivitiesScreen,
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  color: palette.primary,
                                  tooltip: l10n.t('action.newMatch'),
                                  onPressed: _handleNewMatch,
                                ),
                                const SizedBox(height: 12),
                                Tooltip(
                                  message: l10n.t('action.accountSettings'),
                                  child: InkWell(
                                    onTap: _openAccountScreen,
                                    customBorder: const CircleBorder(),
                                    child: _buildAccountAvatar(palette),
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
                              label: Text(l10n.t('nav.play')),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.bar_chart_outlined),
                              selectedIcon: Icon(
                                Icons.bar_chart,
                                color: palette.primary,
                              ),
                              label: Text(l10n.t('nav.scores')),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.tune_outlined),
                              selectedIcon: Icon(
                                Icons.tune,
                                color: palette.primary,
                              ),
                              label: Text(l10n.t('nav.settings')),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.history_outlined),
                              selectedIcon: Icon(
                                Icons.history,
                                color: palette.primary,
                              ),
                              label: Text(l10n.t('nav.history')),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: _controller.changeTab,
                          children: _buildWidePages(),
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
                          l10n.t('app.title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          localizedGameName,
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
                        tooltip: l10n.t('action.activities'),
                        onPressed: _openActivitiesScreen,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: palette.text,
                        tooltip: l10n.t('action.newMatch'),
                        onPressed: _handleNewMatch,
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: l10n.t('action.accountSettings'),
                        child: GestureDetector(
                          onTap: _openAccountScreen,
                          child: _buildAccountAvatar(palette, size: 36),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  body: PageView(
                    controller: _pageController,
                    onPageChanged: _controller.changeTab,
                    children: _buildMobilePages(),
                  ),
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: _controller.activeTabIndex,
                    onTap: _goToTab,
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
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.play_circle_outline),
                        activeIcon: const Icon(Icons.play_circle),
                        label: l10n.t('nav.play'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.bar_chart_outlined),
                        activeIcon: const Icon(Icons.bar_chart),
                        label: l10n.t('nav.scores'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.tune_outlined),
                        activeIcon: const Icon(Icons.tune),
                        label: l10n.t('nav.settings'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.history_outlined),
                        activeIcon: const Icon(Icons.history),
                        label: l10n.t('nav.history'),
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

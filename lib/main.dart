import 'dart:math' as math;

import 'package:flutter/material.dart';

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
          ? const Color(0xFF080A09)
          : const Color(0xFFF7F3EA),
      useMaterial3: true,
    );
  }
}

class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.dartboardDark,
    required this.dartboardLight,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color primary;
  final Color primarySoft;
  final Color accent;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color dartboardDark;
  final Color dartboardLight;

  static AppPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const AppPalette(
        background: Color(0xFF080A09),
        surface: Color(0xFF121614),
        surfaceMuted: Color(0xFF1A211E),
        primary: Color(0xFF0F8B6B),
        primarySoft: Color(0xFF173D34),
        accent: Color(0xFFF6D77B),
        text: Color(0xFFF4F1EA),
        textMuted: Color(0xFF9C978E),
        border: Color(0xFF2A332F),
        dartboardDark: Color(0xFF26231F),
        dartboardLight: Color(0xFFF5E9D0),
      );
    }

    return const AppPalette(
      background: Color(0xFFF7F3EA),
      surface: Colors.white,
      surfaceMuted: Color(0xFFFAF8F3),
      primary: Color(0xFF123F35),
      primarySoft: Color(0xFFE8F4EF),
      accent: Color(0xFFF6D77B),
      text: Color(0xFF151814),
      textMuted: Color(0xFF716B60),
      border: Color(0xFFE1D9CA),
      dartboardDark: Color(0xFF2D2A25),
      dartboardLight: Color(0xFFF5E9D0),
    );
  }
}

enum GameMode { x01, countUp }

enum OutRule { singleOut, doubleOut, masterOut }

enum SegmentBand { miss, single, double, triple, outerBull, bull }

class DartHit {
  const DartHit({
    required this.label,
    required this.score,
    required this.band,
    this.number,
  });

  final String label;
  final int score;
  final SegmentBand band;
  final int? number;

  bool get isMiss => band == SegmentBand.miss;
  bool get isDouble => band == SegmentBand.double || band == SegmentBand.bull;
}

class PlayerScore {
  const PlayerScore({
    required this.name,
    required this.remaining,
    required this.totalScored,
    required this.turns,
    required this.isWinner,
  });

  final String name;
  final int remaining;
  final int totalScored;
  final List<List<DartHit>> turns;
  final bool isWinner;

  PlayerScore copyWith({
    int? remaining,
    int? totalScored,
    List<List<DartHit>>? turns,
    bool? isWinner,
  }) {
    return PlayerScore(
      name: name,
      remaining: remaining ?? this.remaining,
      totalScored: totalScored ?? this.totalScored,
      turns: turns ?? this.turns,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}

class GameSettings {
  const GameSettings({
    required this.mode,
    required this.startingScore,
    required this.outRule,
  });

  final GameMode mode;
  final int startingScore;
  final OutRule outRule;
}

class DartMatchScreen extends StatefulWidget {
  const DartMatchScreen({super.key});

  @override
  State<DartMatchScreen> createState() => _DartMatchScreenState();
}

class _DartMatchScreenState extends State<DartMatchScreen> {
  static const _presetNames = ['Marko', 'Luka', 'Borna'];
  static const _scoreOptions = [301, 501, 701];

  GameSettings _settings = const GameSettings(
    mode: GameMode.x01,
    startingScore: 501,
    outRule: OutRule.doubleOut,
  );

  late List<PlayerScore> _players = _createPlayers(_settings);
  final List<DartHit> _currentTurn = [];
  int _currentPlayerIndex = 0;
  String? _matchMessage;

  PlayerScore get _currentPlayer => _players[_currentPlayerIndex];
  bool get _matchFinished => _players.any((player) => player.isWinner);

  static List<PlayerScore> _createPlayers(GameSettings settings) {
    return _presetNames
        .map(
          (name) => PlayerScore(
            name: name,
            remaining: settings.mode == GameMode.x01
                ? settings.startingScore
                : 0,
            totalScored: 0,
            turns: const [],
            isWinner: false,
          ),
        )
        .toList();
  }

  void _handleHit(DartHit hit) {
    if (_matchFinished || _currentTurn.length == 3) {
      return;
    }

    setState(() {
      _currentTurn.add(hit);
      _matchMessage = null;
      if (_currentTurn.length == 3) {
        _commitTurn();
      }
    });
  }

  void _undoLastHit() {
    if (_currentTurn.isEmpty || _matchFinished) {
      return;
    }

    setState(() {
      _currentTurn.removeLast();
      _matchMessage = null;
    });
  }

  void _addMiss() {
    _handleHit(const DartHit(label: 'MISS', score: 0, band: SegmentBand.miss));
  }

  void _commitTurn() {
    if (_currentTurn.isEmpty) {
      return;
    }

    final player = _currentPlayer;
    final turnScore = _currentTurn.fold<int>(
      0,
      (total, hit) => total + hit.score,
    );
    final nextTurns = [...player.turns, List<DartHit>.from(_currentTurn)];

    if (_settings.mode == GameMode.countUp) {
      _players[_currentPlayerIndex] = player.copyWith(
        remaining: player.remaining + turnScore,
        totalScored: player.totalScored + turnScore,
        turns: nextTurns,
      );
      _advanceTurn();
      return;
    }

    final nextRemaining = player.remaining - turnScore;
    final finishingHit = _currentTurn.last;
    final hasValidFinish = _isValidFinish(nextRemaining, finishingHit);
    final isBust =
        nextRemaining < 0 ||
        nextRemaining == 1 ||
        (nextRemaining == 0 && !hasValidFinish);

    if (isBust) {
      _players[_currentPlayerIndex] = player.copyWith(turns: nextTurns);
      _matchMessage =
          '${player.name} busts. Score stays at ${player.remaining}.';
      _advanceTurn();
      return;
    }

    _players[_currentPlayerIndex] = player.copyWith(
      remaining: nextRemaining,
      totalScored: player.totalScored + turnScore,
      turns: nextTurns,
      isWinner: nextRemaining == 0,
    );

    _matchMessage = nextRemaining == 0
        ? '${player.name} wins with ${finishingHit.label}.'
        : '${player.name} scored $turnScore.';
    _advanceTurn(keepWinner: nextRemaining == 0);
  }

  bool _isValidFinish(int remaining, DartHit hit) {
    if (remaining != 0) {
      return false;
    }

    return switch (_settings.outRule) {
      OutRule.singleOut => true,
      OutRule.doubleOut => hit.isDouble,
      OutRule.masterOut => hit.isDouble || hit.band == SegmentBand.triple,
    };
  }

  void _advanceTurn({bool keepWinner = false}) {
    _currentTurn.clear();
    if (!keepWinner) {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    }
  }

  void _resetMatch({GameMode? mode, int? startingScore, OutRule? outRule}) {
    setState(() {
      _settings = GameSettings(
        mode: mode ?? _settings.mode,
        startingScore: startingScore ?? _settings.startingScore,
        outRule: outRule ?? _settings.outRule,
      );
      _players = _createPlayers(_settings);
      _currentTurn.clear();
      _currentPlayerIndex = 0;
      _matchMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            final boardPanel = _BoardPanel(
              currentPlayer: _currentPlayer,
              currentTurn: _currentTurn,
              message: _matchMessage,
              onHit: _handleHit,
              onUndo: _undoLastHit,
              onMiss: _addMiss,
              onCommit: () => setState(_commitTurn),
              canCommit: _currentTurn.isNotEmpty && !_matchFinished,
              isFinished: _matchFinished,
            );
            final controlPanel = _ControlPanel(
              settings: _settings,
              players: _players,
              currentPlayerIndex: _currentPlayerIndex,
              scoreOptions: _scoreOptions,
              fillAvailableHeight: isWide,
              showHeader: isWide,
              onModeChanged: (mode) => _resetMatch(mode: mode),
              onScoreChanged: (score) => _resetMatch(startingScore: score),
              onOutRuleChanged: (rule) => _resetMatch(outRule: rule),
              onNewMatch: () => _resetMatch(),
            );

            return Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 6, child: boardPanel),
                        const SizedBox(width: 18),
                        Expanded(flex: 4, child: controlPanel),
                      ],
                    )
                  : ListView(
                      children: [
                        _MobileTopBar(
                          onNewMatch: () => _resetMatch(),
                          currentPlayer: _currentPlayer,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: constraints.maxWidth + 220,
                          child: boardPanel,
                        ),
                        const SizedBox(height: 18),
                        controlPanel,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.onNewMatch, required this.currentPlayer});

  final VoidCallback onNewMatch;
  final PlayerScore currentPlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.adjust, color: Color(0xFFF6D77B), size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target Point',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.text,
                ),
              ),
              Text(
                'Darts scorer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _RoundHeaderButton(
          tooltip: 'Search',
          icon: Icons.search,
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        _RoundHeaderButton(
          tooltip: 'New match',
          icon: Icons.refresh,
          onPressed: onNewMatch,
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Profile',
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.border, width: 2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6D77B), Color(0xFF0F8B6B)],
              ),
            ),
            child: Center(
              child: Text(
                currentPlayer.name.substring(0, 1),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.primarySoft,
          ),
          child: Icon(icon, color: palette.primary, size: 25),
        ),
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({
    required this.currentPlayer,
    required this.currentTurn,
    required this.message,
    required this.onHit,
    required this.onUndo,
    required this.onMiss,
    required this.onCommit,
    required this.canCommit,
    required this.isFinished,
  });

  final PlayerScore currentPlayer;
  final List<DartHit> currentTurn;
  final String? message;
  final ValueChanged<DartHit> onHit;
  final VoidCallback onUndo;
  final VoidCallback onMiss;
  final VoidCallback onCommit;
  final bool canCommit;
  final bool isFinished;

  int get _turnTotal => currentTurn.fold(0, (total, hit) => total + hit.score);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CurrentTurnHeader(
          player: currentPlayer,
          hits: currentTurn,
          turnTotal: _turnTotal,
          message: message,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Dartboard(enabled: !isFinished, onHit: onHit),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: currentTurn.isEmpty || isFinished ? null : onUndo,
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: isFinished ? null : onMiss,
                icon: const Icon(Icons.radio_button_unchecked),
                label: const Text('Miss'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: canCommit ? onCommit : null,
                icon: const Icon(Icons.check),
                label: const Text('Save turn'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentTurnHeader extends StatelessWidget {
  const _CurrentTurnHeader({
    required this.player,
    required this.hits,
    required this.turnTotal,
    required this.message,
  });

  final PlayerScore player;
  final List<DartHit> hits;
  final int turnTotal;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final chips = List.generate(3, (index) {
      final hit = index < hits.length ? hits[index] : null;
      return Expanded(
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hit == null
                ? palette.surface.withValues(alpha: 0.72)
                : palette.primarySoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            hit?.label ?? 'Dart ${index + 1}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: hit == null ? palette.textMuted : palette.primary,
            ),
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${player.remaining}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children:
                chips
                    .expand((chip) => [chip, const SizedBox(width: 8)])
                    .toList()
                  ..removeLast(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Turn total: $turnTotal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message!,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.settings,
    required this.players,
    required this.currentPlayerIndex,
    required this.scoreOptions,
    required this.fillAvailableHeight,
    required this.showHeader,
    required this.onModeChanged,
    required this.onScoreChanged,
    required this.onOutRuleChanged,
    required this.onNewMatch,
  });

  final GameSettings settings;
  final List<PlayerScore> players;
  final int currentPlayerIndex;
  final List<int> scoreOptions;
  final bool fillAvailableHeight;
  final bool showHeader;
  final ValueChanged<GameMode> onModeChanged;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<OutRule> onOutRuleChanged;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Target Point',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onNewMatch,
                  tooltip: 'New match',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _SectionTitle(title: 'Game mode'),
          SegmentedButton<GameMode>(
            segments: const [
              ButtonSegment(value: GameMode.x01, label: Text('X01')),
              ButtonSegment(value: GameMode.countUp, label: Text('Count up')),
            ],
            selected: {settings.mode},
            onSelectionChanged: (selection) => onModeChanged(selection.first),
          ),
          const SizedBox(height: 12),
          _SectionTitle(title: 'Starting score'),
          Wrap(
            spacing: 8,
            children: scoreOptions
                .map(
                  (score) => ChoiceChip(
                    label: Text('$score'),
                    selected: settings.startingScore == score,
                    onSelected: (_) => onScoreChanged(score),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          _SectionTitle(title: 'Finish rule'),
          SegmentedButton<OutRule>(
            segments: const [
              ButtonSegment(value: OutRule.singleOut, label: Text('Single')),
              ButtonSegment(value: OutRule.doubleOut, label: Text('Double')),
              ButtonSegment(value: OutRule.masterOut, label: Text('Master')),
            ],
            selected: {settings.outRule},
            onSelectionChanged: settings.mode == GameMode.x01
                ? (selection) => onOutRuleChanged(selection.first)
                : null,
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: 'Players'),
          ...players.indexed.map((entry) {
            final index = entry.$1;
            final player = entry.$2;
            final isCurrent = index == currentPlayerIndex && !player.isWinner;
            final average = player.turns.isEmpty
                ? 0
                : player.totalScored / player.turns.length;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent ? palette.primarySoft : palette.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent ? palette.primary : palette.border,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: player.isWinner
                        ? palette.accent
                        : palette.primary,
                    foregroundColor: player.isWinner
                        ? const Color(0xFF302A1E)
                        : Colors.white,
                    child: Text(player.name.substring(0, 1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${player.turns.length} turns - avg ${average.toStringAsFixed(1)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${player.remaining}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (fillAvailableHeight)
            const Spacer()
          else
            const SizedBox(height: 16),
          Text(
            'Guest match - local session only',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: palette.textMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class Dartboard extends StatelessWidget {
  const Dartboard({required this.enabled, required this.onHit, super.key});

  final bool enabled;
  final ValueChanged<DartHit> onHit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapDown: enabled
              ? (details) {
                  final hit = DartboardGeometry.hitTest(
                    details.localPosition,
                    Size.square(size),
                  );
                  onHit(hit);
                }
              : null,
          child: CustomPaint(
            size: Size.square(size),
            painter: DartboardPainter(palette: AppPalette.of(context)),
          ),
        );
      },
    );
  }
}

class DartboardGeometry {
  static const segmentNumbers = [
    20,
    1,
    18,
    4,
    13,
    6,
    10,
    15,
    2,
    17,
    3,
    19,
    7,
    16,
    8,
    11,
    14,
    9,
    12,
    5,
  ];

  static DartHit hitTest(Offset position, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distanceRatio = math.sqrt(dx * dx + dy * dy) / radius;

    if (distanceRatio > 0.98) {
      return const DartHit(label: 'MISS', score: 0, band: SegmentBand.miss);
    }

    if (distanceRatio <= 0.055) {
      return const DartHit(label: 'BULL', score: 50, band: SegmentBand.bull);
    }

    if (distanceRatio <= 0.12) {
      return const DartHit(label: '25', score: 25, band: SegmentBand.outerBull);
    }

    final number = numberForPosition(dx, dy);
    final band = bandForDistance(distanceRatio);
    final multiplier = switch (band) {
      SegmentBand.double => 2,
      SegmentBand.triple => 3,
      SegmentBand.single => 1,
      _ => 0,
    };
    final prefix = switch (band) {
      SegmentBand.double => 'D',
      SegmentBand.triple => 'T',
      SegmentBand.single => 'S',
      _ => '',
    };

    return DartHit(
      label: '$prefix$number',
      score: number * multiplier,
      band: band,
      number: number,
    );
  }

  static int numberForPosition(double dx, double dy) {
    final angle = (math.atan2(dy, dx) * 180 / math.pi + 450) % 360;
    final index = ((angle + 9) % 360 / 18).floor();
    return segmentNumbers[index];
  }

  static SegmentBand bandForDistance(double distanceRatio) {
    if (distanceRatio >= 0.84) {
      return SegmentBand.double;
    }
    if (distanceRatio >= 0.52 && distanceRatio <= 0.62) {
      return SegmentBand.triple;
    }
    return SegmentBand.single;
  }
}

class DartboardPainter extends CustomPainter {
  const DartboardPainter({required this.palette});

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final boardRadius = radius * 0.98;
    final segmentSweep = 2 * math.pi / 20;
    final startOffset = -math.pi / 2 - segmentSweep / 2;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final outerPaint = Paint()..color = const Color(0xFF1F1C18);
    canvas.drawCircle(center, boardRadius, outerPaint);

    for (var i = 0; i < 20; i++) {
      final start = startOffset + i * segmentSweep;
      final isEven = i.isEven;

      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.64,
        outerRatio: 0.84,
        start: start,
        sweep: segmentSweep,
        color: isEven ? palette.dartboardLight : palette.dartboardDark,
      );
      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.12,
        outerRatio: 0.52,
        start: start,
        sweep: segmentSweep,
        color: isEven ? palette.dartboardLight : palette.dartboardDark,
      );
      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.52,
        outerRatio: 0.62,
        start: start,
        sweep: segmentSweep,
        color: isEven ? const Color(0xFF0F8B6B) : const Color(0xFFC7352F),
      );
      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.84,
        outerRatio: 0.98,
        start: start,
        sweep: segmentSweep,
        color: isEven ? const Color(0xFFC7352F) : const Color(0xFF0F8B6B),
      );

      final number = DartboardGeometry.segmentNumbers[i];
      final angle = start + segmentSweep / 2;
      final labelOffset = Offset(
        center.dx + math.cos(angle) * radius * 0.91,
        center.dy + math.sin(angle) * radius * 0.91,
      );
      textPainter.text = TextSpan(
        text: '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.07,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        labelOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.006)
      ..color = palette.border;

    for (final ratio in [0.12, 0.52, 0.62, 0.84, 0.98]) {
      canvas.drawCircle(center, radius * ratio, wirePaint);
    }

    for (var i = 0; i < 20; i++) {
      final angle = startOffset + i * segmentSweep;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.12,
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.98,
        wirePaint,
      );
    }

    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()..color = const Color(0xFF0F8B6B),
    );
    canvas.drawCircle(
      center,
      radius * 0.055,
      Paint()..color = const Color(0xFFC7352F),
    );
    canvas.drawCircle(center, radius * 0.12, wirePaint);
    canvas.drawCircle(center, radius * 0.055, wirePaint);
  }

  static void _drawRingSegment(
    Canvas canvas,
    Offset center,
    double radius, {
    required double innerRatio,
    required double outerRatio,
    required double start,
    required double sweep,
    required Color color,
  }) {
    final path = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * outerRatio),
        start,
        sweep,
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * innerRatio),
        start + sweep,
        -sweep,
        false,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant DartboardPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

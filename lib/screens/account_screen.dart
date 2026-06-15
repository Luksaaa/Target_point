import 'package:flutter/material.dart';

import '../models/game_state_controller.dart';
import '../theme/app_palette.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({required this.controller, super.key});

  final GameStateController controller;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const _colorOptions = [
    0xFF0F8B6B, // Emerald Green
    0xFFC7352F, // Crimson Red
    0xFFF6D77B, // Amber Gold
    0xFF1A6EB4, // Cobalt Blue
    0xFF8E44AD, // Amethyst Purple
    0xFFE67E22, // Pumpkin Orange
  ];

  late TextEditingController _nameController;
  late int _selectedColor;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    final cur = widget.controller.currentPlayer;
    final profile = widget.controller.profiles.firstWhere(
      (p) => p.name == cur.name,
      orElse: () => widget.controller.profiles.first,
    );
    _nameController = TextEditingController(text: profile.name);
    _selectedColor = profile.avatarColorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final cur = widget.controller.currentPlayer;
    widget.controller.updatePlayerProfile(cur.name, name, _selectedColor);
    setState(() => _isEditingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final cur = widget.controller.currentPlayer;
        final profiles = widget.controller.profiles;
        final totalMatches = profiles.fold<int>(0, (sum, p) => sum + p.matchesPlayed);
        final totalWins = profiles.fold<int>(0, (sum, p) => sum + p.matchesWon);

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: Border(bottom: BorderSide(color: palette.border)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.of(context).pop(),
              color: palette.text,
            ),
            title: Text(
              'Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: palette.text,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Hero Profile Card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.primary,
                      Color.lerp(palette.primary, Colors.black, 0.25)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(cur.avatarColorValue),
                        border: Border.all(color: Colors.white30, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          cur.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cur.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Guest Session',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                      onPressed: () => setState(() => _isEditingProfile = !_isEditingProfile),
                      tooltip: 'Edit Profile',
                    ),
                  ],
                ),
              ),

              // ── Profile Edit Panel ────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isEditingProfile
                    ? _ProfileEditPanel(
                        nameController: _nameController,
                        selectedColor: _selectedColor,
                        colorOptions: _colorOptions,
                        palette: palette,
                        onColorSelected: (c) => setState(() => _selectedColor = c),
                        onSave: _saveProfile,
                        onCancel: () => setState(() => _isEditingProfile = false),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ── Login / Account Section ──────────────────
              _SectionHeader(title: 'Sign In', palette: palette),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  children: [
                    _LoginOptionTile(
                      icon: Icons.g_mobiledata_rounded,
                      iconColor: const Color(0xFF4285F4),
                      label: 'Continue with Google',
                      palette: palette,
                      onTap: () => _showComingSoon(context, palette),
                    ),
                    Divider(height: 1, color: palette.border),
                    _LoginOptionTile(
                      icon: Icons.email_outlined,
                      iconColor: palette.primary,
                      label: 'Continue with Email',
                      palette: palette,
                      onTap: () => _showComingSoon(context, palette),
                    ),
                    Divider(height: 1, color: palette.border),
                    _LoginOptionTile(
                      icon: Icons.person_outline,
                      iconColor: palette.textMuted,
                      label: 'Continue as Guest',
                      palette: palette,
                      isActive: true,
                      onTap: null, // already a guest
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'Sign in to sync scores, access match history across devices and unlock cloud features.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Session Stats ─────────────────────────────
              _SectionHeader(title: 'Session Stats', palette: palette),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(label: 'Matches', value: '$totalMatches', palette: palette),
                    Container(width: 1, height: 40, color: palette.border),
                    _StatBox(label: 'Wins', value: '$totalWins', palette: palette),
                    Container(width: 1, height: 40, color: palette.border),
                    _StatBox(
                      label: 'History',
                      value: '${widget.controller.matchHistory.length}',
                      palette: palette,
                    ),
                    Container(width: 1, height: 40, color: palette.border),
                    _StatBox(
                      label: 'Players',
                      value: '${widget.controller.profiles.length}',
                      palette: palette,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── App Preferences ────────────────────────────
              _SectionHeader(title: 'App Preferences', palette: palette),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.brightness_auto_outlined, color: palette.primary),
                      title: Text('Theme', style: TextStyle(color: palette.text, fontWeight: FontWeight.bold)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'System',
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        'Follows your device theme',
                        style: TextStyle(color: palette.textMuted, fontSize: 12),
                      ),
                    ),
                    Divider(height: 1, color: palette.border),
                    ListTile(
                      leading: Icon(Icons.storage_outlined, color: palette.primary),
                      title: Text('Storage', style: TextStyle(color: palette.text, fontWeight: FontWeight.bold)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Local only',
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        'Data cleared on app restart',
                        style: TextStyle(color: palette.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── About ─────────────────────────────────────
              _SectionHeader(title: 'About', palette: palette),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline, color: palette.primary),
                      title: Text('Target Point', style: TextStyle(color: palette.text, fontWeight: FontWeight.bold)),
                      trailing: Text(
                        'v1.0.0',
                        style: TextStyle(color: palette.textMuted, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Dart scoring app',
                        style: TextStyle(color: palette.textMuted, fontSize: 12),
                      ),
                    ),
                    Divider(height: 1, color: palette.border),
                    ListTile(
                      leading: Icon(Icons.star_outline, color: palette.accent),
                      title: Text('Rate the App', style: TextStyle(color: palette.text, fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right, color: palette.textMuted),
                      subtitle: Text(
                        'Leave a review on the store',
                        style: TextStyle(color: palette.textMuted, fontSize: 12),
                      ),
                      onTap: () => _showComingSoon(context, palette),
                    ),
                    Divider(height: 1, color: palette.border),
                    ListTile(
                      leading: Icon(Icons.bug_report_outlined, color: palette.textMuted),
                      title: Text('Send Feedback', style: TextStyle(color: palette.text, fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right, color: palette.textMuted),
                      onTap: () => _showComingSoon(context, palette),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: Text(
                  'Guest session · Local storage only',
                  style: TextStyle(color: palette.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, AppPalette palette) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: palette.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.palette});
  final String title;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: palette.textMuted,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LoginOptionTile extends StatelessWidget {
  const _LoginOptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.palette,
    this.isActive = false,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final AppPalette palette;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? palette.primary : palette.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            )
          : Icon(Icons.chevron_right, color: palette.textMuted),
      onTap: onTap,
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.palette});
  final String label;
  final String value;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: palette.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ProfileEditPanel extends StatelessWidget {
  const _ProfileEditPanel({
    required this.nameController,
    required this.selectedColor,
    required this.colorOptions,
    required this.palette,
    required this.onColorSelected,
    required this.onSave,
    required this.onCancel,
  });
  final TextEditingController nameController;
  final int selectedColor;
  final List<int> colorOptions;
  final AppPalette palette;
  final ValueChanged<int> onColorSelected;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Current Player',
            style: TextStyle(
              color: palette.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Player Name',
              labelStyle: TextStyle(color: palette.textMuted),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: palette.primary, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: palette.border),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Avatar Color',
            style: TextStyle(color: palette.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: colorOptions.map((c) {
              final isSelected = c == selectedColor;
              return GestureDetector(
                onTap: () => onColorSelected(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: palette.text, width: 3)
                        : Border.all(color: Colors.transparent, width: 3),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Color(c).withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text('Cancel', style: TextStyle(color: palette.textMuted)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onSave,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

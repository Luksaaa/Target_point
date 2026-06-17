import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state_controller.dart';
import '../theme/app_palette.dart';
import '../widgets/responsive_content.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.controller,
    required this.themeMode,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    super.key,
  });

  final GameStateController controller;
  final ThemeMode themeMode;
  final Locale? locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();
  final _followController = TextEditingController();
  int _selectedColor = 0xFF0F8B6B;

  static const _colorOptions = [
    0xFF0F8B6B,
    0xFFC7352F,
    0xFFF6D77B,
    0xFF1A6EB4,
    0xFF8E44AD,
    0xFFE67E22,
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser;
    _nameController.text = user.displayName;
    _selectedColor = user.avatarColorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _followController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    widget.controller.updateUserProfile(_nameController.text, _selectedColor);
  }

  void _followUser() {
    widget.controller.followUser(_followController.text);
    _followController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final user = widget.controller.currentUser;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.surface,
            scrolledUnderElevation: 0,
            shape: Border(bottom: BorderSide(color: palette.border)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: palette.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.t(
                'account.title',
              ), // You can use a generic "Account" text if this localization key is not perfect.
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: ResponsiveContent(
            maxWidth: 980,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: ListView(
              children: [
                // Profile Section
                _SectionHeader(
                  title: l10n.t('account.profile'),
                  palette: palette,
                ),
                _Panel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(_selectedColor),
                            foregroundColor: Colors.white,
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Profile name',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        children: _colorOptions.map((color) {
                          final isSelected = color == _selectedColor;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(color),
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
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primary,
                        ),
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save profile'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Login / Sign In Section
                _SectionHeader(
                  title: l10n.t('account.login'),
                  palette: palette,
                ),
                _Panel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            user.isGuest ? Icons.person_outline : Icons.person,
                            color: palette.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.isGuest ? 'Guest mode' : 'Signed in',
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email ?? user.displayName,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primary,
                        ),
                        onPressed: widget.controller.isSigningIn
                            ? null
                            : widget.controller.signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: Text(
                          widget.controller.isSigningIn
                              ? 'Signing in...'
                              : 'Continue with Google',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.primary,
                        ),
                        onPressed: user.isGuest
                            ? null
                            : widget.controller.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Use guest mode'),
                      ),
                      if (widget.controller.accountMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.controller.accountMessage!,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // App Settings Section
                _SectionHeader(title: 'App Settings', palette: palette),
                _Panel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.t('common.theme'),
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(l10n.t('common.system')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(l10n.t('common.light')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(l10n.t('common.dark')),
                          ),
                        ],
                        selected: {widget.themeMode},
                        onSelectionChanged: (selection) =>
                            widget.onThemeModeChanged(selection.first),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.t('common.language'),
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Locale?>(
                        initialValue: widget.locale,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<Locale?>(
                            value: null,
                            child: Text(l10n.t('common.system')),
                          ),
                          for (final supportedLocale
                              in AppLocalizations.supportedLocales)
                            DropdownMenuItem<Locale?>(
                              value: supportedLocale,
                              child: Text(
                                AppLocalizations.languageName(supportedLocale),
                              ),
                            ),
                        ],
                        onChanged: widget.onLocaleChanged,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Following Section
                _SectionHeader(
                  title: l10n.t('account.social'),
                  palette: palette,
                ),
                _Panel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _followController,
                              decoration: const InputDecoration(
                                labelText: 'Follow user (handle or name)',
                                isDense: true,
                              ),
                              onSubmitted: (_) => _followUser(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: palette.primary,
                            ),
                            onPressed: _followUser,
                            icon: const Icon(Icons.person_add_alt_1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.controller.following.isEmpty)
                        Text(
                          'No followed users yet.',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        ...widget.controller.following.map(
                          (fUser) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: palette.primarySoft,
                              foregroundColor: palette.primary,
                              child: Text(
                                fUser.displayName.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(
                              fUser.displayName,
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              fUser.handle,
                              style: TextStyle(color: palette.textMuted),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About Section
                _SectionHeader(title: 'About', palette: palette),
                _Panel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.info_outline,
                          color: palette.primary,
                        ),
                        title: Text(
                          'Target Point',
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          'Version 1.0.0',
                          style: TextStyle(color: palette.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.palette});

  final String title;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: palette.textMuted,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.palette, required this.child});

  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

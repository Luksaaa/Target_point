import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state_controller.dart';
import '../models/user_session.dart';
import '../theme/app_palette.dart';
import '../widgets/responsive_content.dart';

String _a(BuildContext context, String key) =>
    AppLocalizations.of(context).t(key);

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
  final _imagePicker = ImagePicker();
  int _selectedColor = 0xFF0F8B6B;
  int _selectedSection = 0;
  String? _lastSyncedUserId;

  @override
  void initState() {
    super.initState();
    _syncProfileFields(widget.controller.currentUser);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _followController.dispose();
    super.dispose();
  }

  void _syncProfileFields(UserSession user) {
    _lastSyncedUserId = user.id;
    _nameController.text = user.displayName;
    _selectedColor = user.avatarColorValue;
  }

  void _saveProfile() {
    widget.controller.updateUserProfile(
      _nameController.text,
      _selectedColor,
      photoUrl: widget.controller.currentUser.photoUrl,
    );
  }

  void _followUser() {
    widget.controller.followUser(_followController.text);
    _followController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final user = widget.controller.currentUser;
        if (_lastSyncedUserId != user.id) {
          _syncProfileFields(user);
        }

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
              _a(context, 'account.title'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: ResponsiveContent(
            maxWidth: 720,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AccountSummary(
                  user: user,
                  selectedColor: _selectedColor,
                  palette: palette,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SectionChip(
                        label: _a(context, 'account.profile'),
                        icon: Icons.person_outline,
                        selected: _selectedSection == 0,
                        onTap: () => setState(() => _selectedSection = 0),
                      ),
                      _SectionChip(
                        label: _a(context, 'account.login'),
                        icon: Icons.login,
                        selected: _selectedSection == 1,
                        onTap: () => setState(() => _selectedSection = 1),
                      ),
                      _SectionChip(
                        label: _a(context, 'account.settings'),
                        icon: Icons.tune,
                        selected: _selectedSection == 2,
                        onTap: () => setState(() => _selectedSection = 2),
                      ),
                      _SectionChip(
                        label: _a(context, 'account.social'),
                        icon: Icons.group_outlined,
                        selected: _selectedSection == 3,
                        onTap: () => setState(() => _selectedSection = 3),
                      ),
                      _SectionChip(
                        label: _a(context, 'common.about'),
                        icon: Icons.info_outline,
                        selected: _selectedSection == 4,
                        onTap: () => setState(() => _selectedSection = 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: ListView(
                      key: ValueKey(_selectedSection),
                      children: [
                        switch (_selectedSection) {
                          0 => _buildProfileSection(user, palette),
                          1 => _buildLoginSection(user, palette),
                          2 => _buildSettingsSection(
                            AppLocalizations.of(context),
                            palette,
                          ),
                          3 => _buildSocialSection(palette),
                          _ => _buildAboutSection(palette),
                        },
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(UserSession user, AppPalette palette) {
    return _Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showPhotoDialog,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _ProfileAvatar(
                      user: user,
                      selectedColor: _selectedColor,
                      radius: 34,
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _a(context, 'profile.name'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            label: Text(_a(context, 'profile.save')),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSection(UserSession user, AppPalette palette) {
    final isSigningIn = widget.controller.isSigningIn;
    return _Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                user.isGuest ? Icons.person_outline : Icons.verified_user,
                color: palette.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.isGuest
                      ? _a(context, 'account.guestMode')
                      : _a(context, 'account.signedIn'),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
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
          if (user.isGuest)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: palette.primary),
              onPressed: isSigningIn
                  ? null
                  : widget.controller.signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: Text(
                isSigningIn
                    ? _a(context, 'account.signingIn')
                    : _a(context, 'account.google'),
              ),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: palette.primary),
              onPressed: widget.controller.signOut,
              icon: const Icon(Icons.logout),
              label: Text(_a(context, 'account.signOut')),
            ),
          if (!user.isGuest) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: widget.controller.signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: Text(_a(context, 'account.switchGoogle')),
            ),
          ],
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
    );
  }

  Widget _buildSettingsSection(AppLocalizations l10n, AppPalette palette) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedThemeMode = widget.themeMode == ThemeMode.system
        ? platformBrightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light
        : widget.themeMode;
    final resolvedLocale = widget.locale ?? Localizations.localeOf(context);
    final selectedLocale =
        AppLocalizations.supportedLocales.any(
          (locale) => locale.languageCode == resolvedLocale.languageCode,
        )
        ? AppLocalizations.supportedLocales.firstWhere(
            (locale) => locale.languageCode == resolvedLocale.languageCode,
          )
        : AppLocalizations.supportedLocales.first;

    return _Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _a(context, 'common.theme'),
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(_a(context, 'common.light')),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(_a(context, 'common.dark')),
              ),
            ],
            selected: {resolvedThemeMode},
            onSelectionChanged: (selection) =>
                widget.onThemeModeChanged(selection.first),
          ),
          const SizedBox(height: 20),
          Text(
            _a(context, 'common.language'),
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Locale?>(
            initialValue: selectedLocale,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: palette.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            items: [
              for (final supportedLocale in AppLocalizations.supportedLocales)
                DropdownMenuItem<Locale?>(
                  value: supportedLocale,
                  child: Text(AppLocalizations.languageName(supportedLocale)),
                ),
            ],
            onChanged: widget.onLocaleChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(AppPalette palette) {
    return _Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _followController,
                  decoration: InputDecoration(
                    labelText: _a(context, 'account.followUser'),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _followUser(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: palette.primary),
                onPressed: _followUser,
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.controller.following.isEmpty)
            Text(
              _a(context, 'account.noFollowed'),
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
                  child: Text(fUser.displayName.substring(0, 1).toUpperCase()),
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
    );
  }

  Widget _buildAboutSection(AppPalette palette) {
    return _Panel(
      palette: palette,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline, color: palette.primary),
        title: Text(
          'Game hub',
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${_a(context, 'common.version')} 1.0.1',
          style: TextStyle(color: palette.textMuted),
        ),
      ),
    );
  }

  void _showPhotoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final palette = AppPalette.of(context);
        return AlertDialog(
          title: Text(_a(context, 'profile.photo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(_a(context, 'profile.chooseGallery')),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(_a(context, 'profile.takePhoto')),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickProfileImage(ImageSource.camera);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.controller.updateUserProfile(
                  _nameController.text,
                  _selectedColor,
                  photoUrl: '',
                );
              },
              child: Text(_a(context, 'common.remove')),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: palette.primary),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_a(context, 'common.cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 78,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    final photoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    widget.controller.updateUserProfile(
      _nameController.text,
      _selectedColor,
      photoUrl: photoUrl,
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({
    required this.user,
    required this.selectedColor,
    required this.palette,
  });

  final UserSession user;
  final int selectedColor;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      palette: palette,
      child: Row(
        children: [
          _ProfileAvatar(user: user, selectedColor: selectedColor, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(
                  user.isGuest ? 'Guest mode' : user.email ?? 'Signed in',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.selectedColor,
    required this.radius,
  });

  final UserSession user;
  final int selectedColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl;
    final imageProvider = _imageProviderFromPhotoUrl(photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(selectedColor),
      foregroundColor: Colors.white,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              user.initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w900,
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
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? palette.primary : palette.textMuted,
        ),
        label: Text(label),
        selected: selected,
        selectedColor: palette.primarySoft,
        labelStyle: TextStyle(
          color: selected ? palette.primary : palette.text,
          fontWeight: FontWeight.w900,
        ),
        onSelected: (_) => onTap(),
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
        border: Border(
          bottom: BorderSide(color: palette.border.withValues(alpha: 0.45)),
        ),
      ),
      child: child,
    );
  }
}

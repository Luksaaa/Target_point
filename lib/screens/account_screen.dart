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
  final _imagePicker = ImagePicker();
  int _selectedColor = 0xFF0F8B6B;
  String? _lastSyncedUserId;

  @override
  void initState() {
    super.initState();
    _syncProfileFields(widget.controller.currentUser);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            maxWidth: 620,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: ListView(
              children: [
                _SettingsSectionLabel(
                  label: _a(context, 'account.title').toUpperCase(),
                  palette: palette,
                ),
                const SizedBox(height: 10),
                _SettingsGroup(
                  palette: palette,
                  children: [
                    _SettingsRow(
                      icon: Icons.person_outline,
                      title: _a(context, 'account.profile'),
                      subtitle: user.displayName,
                      palette: palette,
                      onTap: () => _showSectionSheet(
                        title: _a(context, 'account.profile'),
                        child: _buildProfileSection(user, palette),
                      ),
                    ),
                    _SettingsDivider(palette: palette),
                    _SettingsRow(
                      icon: user.isGuest
                          ? Icons.person_outline
                          : Icons.verified_user_outlined,
                      title: user.isGuest
                          ? _a(context, 'account.guestMode')
                          : _a(context, 'account.signedIn'),
                      subtitle: user.email ?? user.displayName,
                      palette: palette,
                      onTap: () => _showSectionSheet(
                        title: _a(context, 'account.login'),
                        child: _buildLoginSection(user, palette),
                      ),
                    ),
                    _SettingsDivider(palette: palette),
                    _SettingsRow(
                      icon: Icons.group_outlined,
                      title: _a(context, 'account.social'),
                      subtitle:
                          '${widget.controller.following.length} ${_a(context, 'account.followingCount')}',
                      palette: palette,
                      onTap: _openSocialScreen,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SettingsSectionLabel(
                  label: _a(context, 'account.appSettings').toUpperCase(),
                  palette: palette,
                ),
                const SizedBox(height: 10),
                _SettingsGroup(
                  palette: palette,
                  children: [
                    _SettingsRow(
                      icon: Icons.language,
                      title: _a(context, 'common.language'),
                      subtitle: AppLocalizations.languageName(
                        widget.locale ?? Localizations.localeOf(context),
                      ),
                      trailingLabel: _a(context, 'common.change'),
                      palette: palette,
                      onTap: () => _showLanguageSheet(palette),
                    ),
                    _SettingsDivider(palette: palette),
                    _SettingsRow(
                      icon: Icons.wb_sunny_outlined,
                      title: _a(context, 'common.theme'),
                      subtitle: _themeLabel(context),
                      trailingLabel: _a(context, 'common.change'),
                      palette: palette,
                      onTap: () => _showThemeSheet(palette),
                    ),
                    _SettingsDivider(palette: palette),
                    _SettingsRow(
                      icon: Icons.info_outline,
                      title: _a(context, 'common.about'),
                      subtitle: '${_a(context, 'common.version')} 1.0.1',
                      palette: palette,
                      onTap: () => _showSectionSheet(
                        title: _a(context, 'common.about'),
                        child: _buildAboutSection(palette),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSocialScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _SocialScreen(controller: widget.controller),
      ),
    );
  }

  String _themeLabel(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedThemeMode = widget.themeMode == ThemeMode.system
        ? platformBrightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light
        : widget.themeMode;
    return resolvedThemeMode == ThemeMode.dark
        ? _a(context, 'common.dark')
        : _a(context, 'common.light');
  }

  void _showSectionSheet({required String title, required Widget child}) {
    final palette = AppPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.36,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                color: palette.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(AppPalette palette) {
    _showSectionSheet(
      title: _a(context, 'common.language'),
      child: _SettingsGroup(
        palette: palette,
        children: [
          for (final supportedLocale in AppLocalizations.supportedLocales) ...[
            _SettingsRow(
              icon: Icons.translate,
              title: AppLocalizations.languageName(supportedLocale),
              subtitle: supportedLocale.languageCode.toUpperCase(),
              selected:
                  (widget.locale ?? Localizations.localeOf(context))
                      .languageCode ==
                  supportedLocale.languageCode,
              palette: palette,
              onTap: () {
                widget.onLocaleChanged(supportedLocale);
                Navigator.of(context).pop();
              },
            ),
            if (supportedLocale != AppLocalizations.supportedLocales.last)
              _SettingsDivider(palette: palette),
          ],
        ],
      ),
    );
  }

  void _showThemeSheet(AppPalette palette) {
    final current = _themeLabel(context);
    _showSectionSheet(
      title: _a(context, 'common.theme'),
      child: _SettingsGroup(
        palette: palette,
        children: [
          _SettingsRow(
            icon: Icons.wb_sunny_outlined,
            title: _a(context, 'common.light'),
            subtitle: _a(context, 'account.lightThemeHint'),
            selected: current == _a(context, 'common.light'),
            palette: palette,
            onTap: () {
              widget.onThemeModeChanged(ThemeMode.light);
              Navigator.of(context).pop();
            },
          ),
          _SettingsDivider(palette: palette),
          _SettingsRow(
            icon: Icons.dark_mode_outlined,
            title: _a(context, 'common.dark'),
            subtitle: _a(context, 'account.darkThemeHint'),
            selected: current == _a(context, 'common.dark'),
            palette: palette,
            onTap: () {
              widget.onThemeModeChanged(ThemeMode.dark);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(UserSession user, AppPalette palette) {
    return _Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.person_outline,
            title: _a(context, 'account.profile'),
            palette: palette,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showPhotoDialog,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _ProfileAvatar(
                      user: user,
                      selectedColor: _selectedColor,
                      radius: 38,
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showPhotoDialog,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(_a(context, 'profile.photo')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                  ),
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(_a(context, 'profile.save')),
                ),
              ),
            ],
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
          _PanelTitle(
            icon: user.isGuest ? Icons.person_outline : Icons.verified_user,
            title: user.isGuest
                ? _a(context, 'account.guestMode')
                : _a(context, 'account.signedIn'),
            palette: palette,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  user.email ?? user.displayName,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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

  Widget _buildAboutSection(AppPalette palette) {
    return _Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.info_outline,
            title: _a(context, 'common.about'),
            palette: palette,
          ),
          const SizedBox(height: 14),
          Text(
            'Game hub',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_a(context, 'common.version')} 1.0.1',
            style: TextStyle(color: palette.textMuted),
          ),
        ],
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

class _SocialScreen extends StatefulWidget {
  const _SocialScreen({required this.controller});

  final GameStateController controller;

  @override
  State<_SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<_SocialScreen> {
  final _followController = TextEditingController();
  List<FollowedUser> _followResults = const [];
  bool _isSearchingUsers = false;
  int _followSearchSerial = 0;

  @override
  void dispose() {
    _followController.dispose();
    super.dispose();
  }

  void _followUser() {
    if (_followResults.isNotEmpty) {
      _followSelectedUser(_followResults.first);
      return;
    }
    widget.controller.followUser(_followController.text);
    _followController.clear();
    setState(() {
      _followResults = const [];
      _isSearchingUsers = false;
    });
  }

  Future<void> _searchFollowableUsers(String value) async {
    _followSearchSerial += 1;
    final serial = _followSearchSerial;
    if (value.trim().length < 2) {
      setState(() {
        _followResults = const [];
        _isSearchingUsers = false;
      });
      return;
    }

    setState(() {
      _isSearchingUsers = true;
    });
    final results = await widget.controller.searchFollowableUsers(value);
    if (!mounted || serial != _followSearchSerial) {
      return;
    }
    setState(() {
      _followResults = results;
      _isSearchingUsers = false;
    });
  }

  Future<void> _followSelectedUser(FollowedUser user) async {
    await widget.controller.followExistingUser(user);
    _followController.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _followResults = const [];
      _isSearchingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

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
          _a(context, 'account.social'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: palette.text,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return ResponsiveContent(
            maxWidth: 620,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: ListView(
              children: [
                _PanelTitle(
                  icon: Icons.group_outlined,
                  title: _a(context, 'account.social'),
                  palette: palette,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _followController,
                        decoration: InputDecoration(
                          labelText: _a(context, 'account.followUser'),
                          isDense: true,
                        ),
                        onChanged: _searchFollowableUsers,
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
                const SizedBox(height: 18),
                _buildSearchResults(palette),
                const SizedBox(height: 8),
                Divider(color: palette.border),
                const SizedBox(height: 16),
                Text(
                  _a(context, 'account.followingCount'),
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
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
                    (fUser) => _SocialUserTile(user: fUser, palette: palette),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(AppPalette palette) {
    if (_isSearchingUsers) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: palette.primary)),
      );
    }

    if (_followController.text.trim().length >= 2 && _followResults.isEmpty) {
      return Text(
        _a(context, 'account.noUserResults'),
        style: TextStyle(color: palette.textMuted, fontWeight: FontWeight.w700),
      );
    }

    if (_followResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _a(context, 'account.searchResults'),
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        ..._followResults.map(
          (fUser) => _SocialUserTile(
            user: fUser,
            palette: palette,
            trailing: Icon(Icons.person_add_alt_1, color: palette.primary),
            onTap: () => _followSelectedUser(fUser),
          ),
        ),
      ],
    );
  }
}

class _SocialUserTile extends StatelessWidget {
  const _SocialUserTile({
    required this.user,
    required this.palette,
    this.trailing,
    this.onTap,
  });

  final FollowedUser user;
  final AppPalette palette;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: palette.primarySoft,
        foregroundColor: palette.primary,
        child: Text(user.displayName.substring(0, 1).toUpperCase()),
      ),
      title: Text(
        user.displayName,
        style: TextStyle(color: palette.text, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        user.email ?? user.handle,
        style: TextStyle(color: palette.textMuted),
      ),
      trailing: trailing,
      onTap: onTap,
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

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: palette.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label, required this.palette});

  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: palette.textMuted,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, required this.palette});

  final List<Widget> children;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 92),
      child: Container(height: 1, color: palette.border.withValues(alpha: 0.8)),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
    this.trailingLabel,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppPalette palette;
  final VoidCallback onTap;
  final String? trailingLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: palette.primary, size: 25),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (trailingLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailingLabel!,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              )
            else if (selected)
              Icon(Icons.check_circle, color: palette.primary)
            else
              Icon(Icons.chevron_right, color: palette.textMuted),
          ],
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
        border: Border(
          bottom: BorderSide(color: palette.border.withValues(alpha: 0.45)),
        ),
      ),
      child: child,
    );
  }
}

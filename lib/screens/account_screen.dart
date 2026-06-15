import 'package:flutter/material.dart';

import '../models/game_state_controller.dart';
import '../theme/app_palette.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.controller,
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final GameStateController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

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

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final user = widget.controller.currentUser;

        return DefaultTabController(
          length: 4,
          child: Scaffold(
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
                'Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              bottom: TabBar(
                isScrollable: true,
                labelColor: palette.primary,
                unselectedLabelColor: palette.textMuted,
                indicatorColor: palette.primary,
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Login'),
                  Tab(text: 'Groups'),
                  Tab(text: 'Social'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ProfileTab(
                  userInitials: user.initials,
                  nameController: _nameController,
                  selectedColor: _selectedColor,
                  colorOptions: _colorOptions,
                  palette: palette,
                  themeMode: widget.themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                  onColorSelected: (color) =>
                      setState(() => _selectedColor = color),
                  onSave: _saveProfile,
                ),
                _LoginTab(controller: widget.controller, palette: palette),
                _GroupsTab(controller: widget.controller, palette: palette),
                _SocialTab(
                  controller: widget.controller,
                  followController: _followController,
                  palette: palette,
                  onFollow: _followUser,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.userInitials,
    required this.nameController,
    required this.selectedColor,
    required this.colorOptions,
    required this.palette,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onColorSelected,
    required this.onSave,
  });

  final String userInitials;
  final TextEditingController nameController;
  final int selectedColor;
  final List<int> colorOptions;
  final AppPalette palette;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<int> onColorSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(selectedColor),
                    foregroundColor: Colors.white,
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: nameController,
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
                children: colorOptions.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => onColorSelected(color),
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
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelTitle(title: 'Theme', palette: palette),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) =>
                    onThemeModeChanged(selection.first),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginTab extends StatelessWidget {
  const _LoginTab({required this.controller, required this.palette});

  final GameStateController controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelTitle(
                title: user.isGuest ? 'Guest mode' : 'Signed in',
                palette: palette,
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
                onPressed: controller.isSigningIn
                    ? null
                    : controller.signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: Text(
                  controller.isSigningIn
                      ? 'Signing in...'
                      : 'Continue with Google',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: user.isGuest ? null : controller.signOut,
                icon: const Icon(Icons.person_outline),
                label: const Text('Use guest mode'),
              ),
              if (controller.accountMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.accountMessage!,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({required this.controller, required this.palette});

  final GameStateController controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: controller.playerGroups.map((group) {
        final isSelected = group.id == controller.selectedPlayerGroupId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Panel(
            palette: palette,
            highlighted: isSelected,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                group.isShared ? Icons.public : Icons.group,
                color: isSelected ? palette.primary : palette.textMuted,
              ),
              title: Text(
                group.name,
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                group.playerNames.join(', '),
                style: TextStyle(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: TextButton(
                onPressed: () => controller.sharePlayerGroup(group.id),
                child: Text(group.isShared ? 'Shared' : 'Share'),
              ),
              onTap: () => controller.selectPlayerGroup(group.id),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SocialTab extends StatelessWidget {
  const _SocialTab({
    required this.controller,
    required this.followController,
    required this.palette,
    required this.onFollow,
  });

  final GameStateController controller;
  final TextEditingController followController;
  final AppPalette palette;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          palette: palette,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: followController,
                  decoration: const InputDecoration(
                    labelText: 'User handle or name',
                  ),
                  onSubmitted: (_) => onFollow(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onFollow,
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (controller.following.isEmpty)
          _Panel(
            palette: palette,
            child: Text(
              'No followed users yet.',
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          ...controller.following.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Panel(
                palette: palette,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: palette.primarySoft,
                    foregroundColor: palette.primary,
                    child: Text(user.displayName.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(
                    user.displayName,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    user.handle,
                    style: TextStyle(color: palette.textMuted),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.palette,
    required this.child,
    this.highlighted = false,
  });

  final AppPalette palette;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? palette.primarySoft : palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? palette.primary : palette.border,
        ),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.palette});

  final String title;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: palette.text,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    );
  }
}

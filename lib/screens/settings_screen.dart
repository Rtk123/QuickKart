import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

/// Settings: Theme (light/dark/system), Notifications, aur Language.
/// Teeno preferences turant apply hoti hain aur device par save rehti hain.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    final t = settings.t;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(t.appearance),
          _Card(
            child: Column(
              children: [
                _ChoiceTile(
                  icon: Icons.light_mode_outlined,
                  label: t.themeLight,
                  selected: settings.themeMode == ThemeMode.light,
                  onTap: () => settings.setThemeMode(ThemeMode.light),
                ),
                _ChoiceTile(
                  icon: Icons.dark_mode_outlined,
                  label: t.themeDark,
                  selected: settings.themeMode == ThemeMode.dark,
                  onTap: () => settings.setThemeMode(ThemeMode.dark),
                ),
                _ChoiceTile(
                  icon: Icons.brightness_auto_outlined,
                  label: t.themeSystem,
                  selected: settings.themeMode == ThemeMode.system,
                  onTap: () => settings.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          _SectionHeader(t.notifications),
          _Card(
            child: SwitchListTile(
              value: settings.notificationsEnabled,
              onChanged: settings.setNotificationsEnabled,
              secondary: Icon(
                settings.notificationsEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(t.orderUpdates),
              subtitle: Text(
                t.orderUpdatesDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          _SectionHeader(t.language),
          _Card(
            child: Column(
              children: [
                for (final lang in AppLang.values)
                  _ChoiceTile(
                    icon: Icons.translate,
                    label: lang.label,
                    selected: lang == settings.language,
                    onTap: () => settings.setLanguage(lang),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.languageDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SectionHeader(t.account),
          _Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(t.signedInAs),
                  subtitle: Text(
                    AuthService.currentUser?.email ?? t.notSignedIn,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text(
                    t.logout,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () async {
                    await AuthService.signOut();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Radio-jaisa selectable tile. Jaan-bujhkar `RadioListTile` use nahi kiya —
/// uska `groupValue`/`onChanged` naye Flutter mein deprecated hai, aur uska
/// replacement (`RadioGroup`) Flutter 3.32+ maangta hai, jabki pubspec.yaml
/// abhi SDK >=3.3.0 support karta hai.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        size: 20,
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dpad/dpad.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/focus_effect.dart';
import 'parental_lock_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _languages = [
    ('de', 'Deutsch'), ('tr', 'Türkçe'), ('en', 'English'),
    ('ru', '???????'), ('ar', '???????'), ('pl', 'Polski'),
    ('es', 'Español'), ('fr', 'Français'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = theme.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          DpadFocusable(
            effect: StreamiaFocus.card, // Klammern entfernt
            onSelect: () => theme.toggleTheme(),
            child: ListTile(
              title: const Text('Dark / Light Mode'),
              trailing: Switch(value: isDark, onChanged: (_) => theme.toggleTheme()),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Sprache', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._languages.map((lang) => DpadFocusable(
            effect: StreamiaFocus.card, // Klammern entfernt
            onSelect: () => locale.setLocale(lang.$1),
            child: ListTile(
              title: Text(lang.$2),
              trailing: locale.locale.languageCode == lang.$1
                  ? const Icon(Icons.check, color: Colors.green) : null,
            ),
          )),
          const Divider(),
          DpadFocusable(
            effect: StreamiaFocus.card, // Klammern entfernt
            onSelect: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ParentalLockScreen())),
            child: const ListTile(
              title: Text('Kindersperre'),
              trailing: Icon(Icons.lock_outline),
            ),
          ),
          DpadFocusable(
            effect: StreamiaFocus.card, // Klammern entfernt
            onSelect: () async {
              await auth.logout();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const ListTile(
              title: Text('Abmelden'),
              trailing: Icon(Icons.logout),
            ),
          ),
        ],
      ),
    );
  }
}

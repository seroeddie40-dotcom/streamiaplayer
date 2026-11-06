import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/language_selection_screen.dart';
import 'screens/dashboard_screen.dart';

class StreamiaApp extends StatelessWidget {
  const StreamiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'Streamia Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _resolveHome(localeProvider),
    );
  }

  Widget _resolveHome(LocaleProvider locale) {
    // Wenn die Sprache noch nicht gewählt wurde -> Sprachauswahl
    if (!locale.hasSelectedLanguage) {
      return const LanguageSelectionScreen();
    }
    // Wenn die Sprache schon gewählt ist -> Direkt ins Dashboard
    // (Hier kannst du später die Playlist-Abfrage oder den Login einbauen)
    return const DashboardScreen();
  }
}

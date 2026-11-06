import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/content_provider.dart';
import 'screens/language_selection_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';

class StreamiaApp extends StatelessWidget {
  const StreamiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final contentProvider = context.watch<ContentProvider>();

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
      home: _resolveHome(localeProvider, contentProvider),
    );
  }

  Widget _resolveHome(LocaleProvider locale, ContentProvider content) {
    // 1. Sprache noch nicht gewählt -> Sprachauswahl
    if (!locale.hasSelectedLanguage) {
      return const LanguageSelectionScreen();
    }
    
    // 2. Sprache gewählt, aber keine Playlist geladen -> Setup Screen
    if (!content.isLoaded) {
      return const SetupScreen();
    }
    
    // 3. Alles bereit -> Dashboard
    return const DashboardScreen();
  }
}

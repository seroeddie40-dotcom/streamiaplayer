import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/content_provider.dart';
import 'core/storage/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final prefsService = PrefsService(prefs);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefsService)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefsService)),
        ChangeNotifierProvider(create: (_) => AuthProvider(prefsService)),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
      ],
      child: const StreamiaApp(),
    ),
  );
}

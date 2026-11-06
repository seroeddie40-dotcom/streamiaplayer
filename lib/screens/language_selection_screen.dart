import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../core/theme/app_theme.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  static const _languages = [
    ('de', 'Deutsch'), ('tr', 'Türkçe'), ('en', 'English'),
    ('ru', 'Русский'), ('ar', 'العربية'), ('pl', 'Polski'),
    ('es', 'Español'), ('fr', 'Français'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.accentGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 64, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Select Language / Sprache wählen',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16, 
                runSpacing: 16,
                children: _languages.map((lang) {
                  return InkWell(
                    onTap: () {
                      context.read<LocaleProvider>().setLocale(lang.$1);
                    },
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        lang.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 20, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

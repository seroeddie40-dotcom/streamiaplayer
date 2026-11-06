import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dpad/dpad.dart';
import '../providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/focus_effects.dart';
import 'live_tv_screen.dart';
import 'vod_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';
import 'paywall_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, isDark),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 1.6,
                  children: [
                    _DashboardTile(icon: Icons.live_tv, label: 'Live TV',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveTvScreen()))),
                    _DashboardTile(icon: Icons.movie, label: 'VOD',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VodScreen()))),
                    _DashboardTile(icon: Icons.video_library, label: 'Series',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SeriesScreen()))),
                    _DashboardTile(icon: Icons.grid_view, label: 'Multi-Screen', onTap: () {}),
                    _DashboardTile(icon: Icons.replay, label: 'Catch-Up', onTap: () {}),
                    _DashboardTile(icon: Icons.search, label: 'Master Search', onTap: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.accentGradient),
            child: const Center(
              child: Text('S', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Streamia Player', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Spacer(),
          DpadFocusable(
            effects: StreamiaFocus.card,
            onSelect: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(8)),
              child: const Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          DpadFocusable(
            effects: StreamiaFocus.card,
            onSelect: () => context.read<ThemeProvider>().toggleTheme(),
            child: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 28),
          ),
          const SizedBox(width: 16),
          DpadFocusable(
            effects: StreamiaFocus.card,
            onSelect: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: const Icon(Icons.settings, size: 28),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashboardTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DpadFocusable(
      effects: StreamiaFocus.card,
      onSelect: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.electricBlue.withOpacity(0.15), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.electricBlue),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

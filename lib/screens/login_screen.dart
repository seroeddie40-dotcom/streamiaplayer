import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dpad/dpad.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/focus_effects.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pairingUrl = 'https://streamia.app/pair?mac=${Uri.encodeComponent(auth.macAddress)}';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(data: pairingUrl, version: QrVersions.auto, size: 240),
                ),
                const SizedBox(height: 16),
                const Text('Scan with your phone to pair',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
            const SizedBox(width: 64),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Streamia Player',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Enter your MAC address or scan the QR code',
                    style: TextStyle(color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.electricBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your MAC Address', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(auth.macAddress,
                          style: const TextStyle(
                            color: AppTheme.electricBlue, fontSize: 24,
                            fontWeight: FontWeight.bold, fontFamily: 'monospace',
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                DpadFocusable(
                  autofocus: true,
                  effects: [StreamiaFocus.card],
                  onSelect: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('CONTINUE',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/focus_effects.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPeriod = 1;
  int _selectedTier = 0;

  @override
  Widget build(BuildContext context) {
    final periods = ['Monatlich', 'Jährlich', 'Lebenslang'];
    final tiers = [('1 Gerät', '\$4.99'), ('3 Geräte', '\$9.99'), ('5 Geräte', '\$14.99')];

    return Scaffold(
      appBar: AppBar(title: const Text('Auf Pro upgraden')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('Wählen Sie Ihren Tarif',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(periods.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DpadFocusable(
                  effects: [StreamiaFocus.card],
                  onSelect: () => setState(() => _selectedPeriod = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == i ? AppTheme.electricBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.electricBlue),
                    ),
                    child: Text(periods[i], style: TextStyle(
                        color: _selectedPeriod == i ? Colors.white : null,
                        fontWeight: FontWeight.w600)),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: List.generate(tiers.length, (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DpadFocusable(
                      effects: [StreamiaFocus.card],
                      onSelect: () => setState(() => _selectedTier = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTier == i ? AppTheme.electricBlue.withOpacity(0.15) : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedTier == i ? AppTheme.electricBlue : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tiers[i].$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(tiers[i].$2, style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.electricBlue)),
                            const SizedBox(height: 8),
                            Text(periods[_selectedPeriod]),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 32),
            DpadFocusable(
              effects: [StreamiaFocus.card],
              onSelect: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zahlungsintegration folgt')),
                );
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(12)),
                child: const Text('ABONNIEREN', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

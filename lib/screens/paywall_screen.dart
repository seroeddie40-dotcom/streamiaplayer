import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPeriod = 1; // 0=Monatlich, 1=Jährlich, 2=Lebenslang
  int _selectedTier = 1;   // 0=1 Gerät, 1=3 Geräte, 2=5 Geräte

  // Preise definieren
  final List<List<double>> _prices = [
    [4.99, 9.99, 14.99],    // Monatlich (1, 3, 5 Geräte)
    [39.99, 79.99, 119.99], // Jährlich (1, 3, 5 Geräte)
    [149.99, 249.99, 349.99], // Lebenslang (1, 3, 5 Geräte)
  ];

  String _getPriceString() {
    double price = _prices[_selectedPeriod][_selectedTier];
    String suffix = _selectedPeriod == 0 ? '/Monat' : (_selectedPeriod == 1 ? '/Jahr' : ' einmalig');
    return '${price.toStringAsFixed(2)} € $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final periods = ['Monatlich', 'Jährlich', 'Lebenslang'];
    final tiers = ['1 Gerät', '3 Geräte', '5 Geräte'];

    return Scaffold(
      appBar: AppBar(title: const Text('Auf Pro upgraden')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('Wählen Sie Ihren Tarif',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Schalten Sie alle Funktionen frei, inkl. Multi-Screen und Downloads.',
                style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            
            // Perioden-Auswahl
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(periods.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedPeriod = i),
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
            
            // Geräte-Auswahl (Pakete)
            Expanded(
              child: Row(
                children: List.generate(tiers.length, (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTier = i),
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
                            Icon(
                              Icons.devices, 
                              size: 40, 
                              color: _selectedTier == i ? AppTheme.electricBlue : Colors.grey
                            ),
                            const SizedBox(height: 16),
                            Text(tiers[i], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              '${_prices[_selectedPeriod][i].toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold, 
                                color: _selectedTier == i ? AppTheme.electricBlue : null
                              )
                            ),
                            if (i == 1) 
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Beliebt', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 32),
            
            // Zusammenfassung und Button
            Text(
              'Gesamtpreis: ${_getPriceString()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Zahlung für ${tiers[_selectedTier]} gestartet: ${_getPriceString()}')),
                );
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(12)),
                child: const Text('JETZT ABONNIEREN', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sichere Zahlung über PayPal / Kreditkarte', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

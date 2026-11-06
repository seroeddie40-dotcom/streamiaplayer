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
  Widget build(BuildContext

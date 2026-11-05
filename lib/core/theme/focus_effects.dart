import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'app_theme.dart';

class StreamiaFocus {
  // In der neuen dpad-Version heißen die Parameter anders.
  // Wir definieren hier eine Liste von Effekten, die das dpad-Paket versteht.
  static List<DpadEffect> get card => [
    DpadScaleEffect(scale: 1.05),
    DpadGlowEffect(
      color: AppTheme.electricBlue,
      blurRadius: 24,
      spreadRadius: 2,
    ),
    DpadBorderEffect(color: AppTheme.electricBlue, width: 2.5),
  ];
}

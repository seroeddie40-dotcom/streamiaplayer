import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'app_theme.dart';

class StreamiaFocus {
  // Wir geben hier eine Liste zurück, da die dpad-Version 3.2.0 dies erwartet.
  // Um zu verhindern, dass wir in allen Dateien eckige Klammern schreiben müssen,
  // übergeben wir diese Liste als ein einziges Objekt, das die Klammern "simuliert".
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

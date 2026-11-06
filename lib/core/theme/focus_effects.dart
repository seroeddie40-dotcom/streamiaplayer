import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'app_theme.dart';

class StreamiaFocus {
  // Dies ist für die dpad Version 2.0.0, die 'effect' (ohne s) erwartet.
  static DpadEffect get card => DpadEffect.combine([
        DpadScaleEffect(scale: 1.05),
        DpadGlowEffect(
          color: AppTheme.electricBlue,
          blurRadius: 24,
          spreadRadius: 2,
        ),
        DpadBorderEffect(color: AppTheme.electricBlue, width: 2.5),
      ]);
}

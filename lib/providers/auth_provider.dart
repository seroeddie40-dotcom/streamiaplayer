import 'dart:math';
import 'package:flutter/material.dart';
import '../core/storage/prefs_service.dart';

class AuthProvider extends ChangeNotifier {
  final PrefsService _prefs;
  String? _macAddress;

  AuthProvider(this._prefs) {
    _macAddress = _prefs.macAddress;
    if (_macAddress == null) {
      _macAddress = _generateMac();
      _prefs.setMacAddress(_macAddress!);
    }
  }

  String get macAddress => _macAddress!;
  bool get isLoggedIn => _prefs.macAddress != null;

  String _generateMac() {
    final rand = Random();
    final bytes = List.generate(6, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }

  Future<void> login() async => notifyListeners();

  Future<void> logout() async {
    await _prefs.clear();
    _macAddress = null;
    notifyListeners();
  }
}

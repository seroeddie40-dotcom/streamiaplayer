import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series.dart';

class ContentProvider extends ChangeNotifier {
  List<Channel> _channels = [];
  List<VodItem> _vodItems = [];
  List<Series> _series = [];
  bool _isLoaded = false;
  
  // Das hier hat gefehlt:
  final List<Channel> _recentHistory = [];

  List<Channel> get channels => _channels;
  List<VodItem> get vodItems => _vodItems;
  List<Series> get series => _series;
  bool get isLoaded => _isLoaded;
  List<Channel> get recentHistory => List.unmodifiable(_recentHistory);

  void setChannels(List<Channel> list) { _channels = list; notifyListeners(); }
  void setVod(List<VodItem> list) { _vodItems = list; notifyListeners(); }
  void setSeries(List<Series> list) { _series = list; notifyListeners(); }

  void setLoaded(bool value) {
    _isLoaded = value;
    notifyListeners();
  }

  void addToHistory(Channel channel) {
    _recentHistory.removeWhere((c) => c.id == channel.id);
    _recentHistory.insert(0, channel);
    if (_recentHistory.length > 10) _recentHistory.removeLast();
    notifyListeners();
  }
}

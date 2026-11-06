import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series.dart';

class ContentProvider extends ChangeNotifier {
  List<Channel> _channels = [];
  List<VodItem> _vodItems = [];
  List<Series> _series = [];
  bool _isLoaded = false;

  List<Channel> get channels => _channels;
  List<VodItem> get vodItems => _vodItems;
  List<Series> get series => _series;
  bool get isLoaded => _isLoaded;

  void setChannels(List<Channel> list) { _channels = list; notifyListeners(); }
  void setVod(List<VodItem> list) { _vodItems = list; notifyListeners(); }
  void setSeries(List<Series> list) { _series = list; notifyListeners(); }

  void setLoaded(bool value) {
    _isLoaded = value;
    notifyListeners();
  }

  void addToHistory(Channel channel) {
    // Wird später für den Verlauf genutzt
  }
}

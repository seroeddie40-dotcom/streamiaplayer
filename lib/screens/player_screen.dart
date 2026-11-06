import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/channel.dart';
import '../models/series.dart';
import '../providers/content_provider.dart';
import '../services/recording_service.dart';

class PlayerScreen extends StatefulWidget {
  final Channel? channel;
  final String? streamUrl;
  final String? title;
  final List<Episode>? episodes;
  final int? initialEpisodeIndex;
  final Series? series;
  final bool isLive;

  const PlayerScreen({
    super.key, this.channel, this.streamUrl, this.title,
    this.episodes, this.initialEpisodeIndex, this.series, this.isLive = false,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  StreamSubscription? _posSub, _durSub, _playSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _showControls = true;
  bool _showHistory = false;
  bool _showDrawer = false;
  bool _recording = false;
  Timer? _hideTimer;
  int _currentEpisode = 0;

  String? get _currentUrl {
    if (widget.episodes != null && widget.episodes!.isNotEmpty) {
      return widget.episodes![_currentEpisode].streamUrl;
    }
    return widget.streamUrl ?? widget.channel?.streamUrl;
  }

  String get _currentTitle {
    if (widget.episodes != null && widget.episodes!.isNotEmpty) {
      return widget.episodes![_currentEpisode].title;
    }
    return widget.title ?? widget.channel?.name ?? 'Stream';
  }

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _currentEpisode = widget.initialEpisodeIndex ?? 0;
    _posSub = _player.stream.position.listen((p) { if (mounted) setState(() => _position = p); });
    _durSub = _player.stream.duration.listen((d) { if (mounted) setState(() => _duration = d); });
    _playSub = _player.stream.playing.listen((p) { if (mounted) setState(() => _playing = p); });
    _loadStream();
    _startHideTimer();
    if (widget.channel != null) {
      WidgetsBinding.instance.addPost

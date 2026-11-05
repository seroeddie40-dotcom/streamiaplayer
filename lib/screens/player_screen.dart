import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:dpad/dpad.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/focus_effects.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ContentProvider>().addToHistory(widget.channel!);
      });
    }
  }

  Future<void> _loadStream() async {
    final url = _currentUrl;
    if (url == null) return;
    try { await _player.open(Media(url)); } catch (_) {}
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _posSub?.cancel(); _durSub?.cancel(); _playSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_showDrawer) { setState(() => _showDrawer = false); return; }
        if (_showHistory) { setState(() => _showHistory = false); return; }
        if (_showControls) { setState(() => _showControls = false); return; }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() => _showControls = !_showControls);
            if (_showControls) _startHideTimer();
          },
          child: Stack(
            children: [
              Center(child: Video(controller: _videoController)),
              if (_showControls) _buildControls(),
              if (_showHistory) _buildHistorySidebar(),
              if (_showDrawer && widget.episodes != null) _buildEpisodesDrawer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.transparent, Colors.black87],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  DpadFocusable(
                    effect: StreamiaFocus.card,
                    onSelect: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(_currentTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (widget.isLive)
                    DpadFocusable(
                      effect: StreamiaFocus.card,
                      onSelect: _toggleRecording,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _recording ? Colors.red : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(_recording ? Icons.stop : Icons.fiber_manual_record,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(_recording ? 'Aufnahme stoppen' : 'Aufnehmen',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.episodes != null)
                  DpadFocusable(
                    effect: StreamiaFocus.card,
                    onSelect: () { if (_currentEpisode > 0) { setState(() => _currentEpisode--); _loadStream(); } },
                    child: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                  ),
                if (widget.episodes != null) const SizedBox(width: 32),
                DpadFocusable(
                  effect: StreamiaFocus.card,
                  onSelect: () => _playing ? _player.pause() : _player.play(),
                  child: Icon(_playing ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white, size: 72),
                ),
                if (widget.episodes != null) const SizedBox(width: 32),
                if (widget.episodes != null)
                  DpadFocusable(
                    effect: StreamiaFocus.card,
                    onSelect: () {
                      if (widget.episodes != null && _currentEpisode < widget.episodes!.length - 1) {
                        setState(() => _currentEpisode++);
                        _loadStream();
                      }
                    },
                    child: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                  ),
              ],
            ),
            if (!widget.isLive) _buildProgressBar(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.episodes != null)
                    DpadFocusable(
                      effect: StreamiaFocus.card,
                      onSelect: () => setState(() => _showDrawer = true),
                      child: _pill('Folgen', Icons.list),
                    ),
                  const SizedBox(width: 12),
                  DpadFocusable(
                    effect: StreamiaFocus.card,
                    onSelect: () => setState(() => _showHistory = !_showHistory),
                    child: _pill('Verlauf', Icons.history),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final max = _duration.inMilliseconds.toDouble();
    final val = _position.inMilliseconds.toDouble().clamp(0, max);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(_fmt(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.electricBlue,
                thumbColor: AppTheme.electricBlue,
                inactiveTrackColor: Colors.white24,
              ),
              child: Slider(
                value: max > 0 ? val : 0,
                max: max > 0 ? max : 1,
                onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(_fmt(_duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistorySidebar() {
    final history = context.watch<ContentProvider>().recentHistory;
    return Positioned(
      right: 0, top: 0, bottom: 0,
      child: Container(
        width: 360,
        color: Colors.black.withOpacity(0.85),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Zuletzt gesehen',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  DpadFocusable(
                    effect: StreamiaFocus.card,
                    onSelect: () => setState(() => _showHistory = false),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, i) {
                  final ch = history[i];
                  return DpadFocusable(
                    effect: StreamiaFocus.card,
                    onSelect: () {
                      setState(() => _showHistory = false);
                      _player.open(Media(ch.streamUrl));
                    },
                    child: ListTile(
                      leading: ch.logoUrl != null
                          ? Image.network(ch.logoUrl!, width: 40, height: 40,
                              errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white))
                          : const Icon(Icons.tv, color: Colors.white),
                      title: Text(ch.name, style: const TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesDrawer() {
    return Positioned(
      left: 0, top: 0, bottom: 0,
      child: Container(
        width: 360,
        color: Colors.black.withOpacity(0.9),
        child: ListView.builder(
          itemCount: widget.episodes!.length,
          itemBuilder: (context, i) {
            final ep = widget.episodes![i];
            return DpadFocusable(
              effect: StreamiaFocus.card,
              onSelect: () {
                setState(() { _currentEpisode = i; _showDrawer = false; });
                _loadStream();
              },
              child: ListTile(
                selected: i == _currentEpisode,
                leading: Text('${ep.number}', style: const TextStyle(color: Colors.white)),
                title: Text(ep.title, style: const TextStyle(color: Colors.white)),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await RecordingService.stop();
      setState(() => _recording = false);
    } else {
      final ok = await RecordingService.start(widget.channel?.name ?? 'rec');
      if (mounted) setState(() => _recording = ok);
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

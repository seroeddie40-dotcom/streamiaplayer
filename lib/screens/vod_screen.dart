import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dpad/dpad.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/focus_effects.dart';
import '../providers/content_provider.dart';
import '../models/vod_item.dart';
import '../services/download_service.dart';
import 'player_screen.dart';

class VodScreen extends StatelessWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ContentProvider>().vodItems;
    return Scaffold(
      appBar: AppBar(title: const Text('Filme')),
      body: items.isEmpty
          ? const Center(child: Text('Keine Filme vorhanden'))
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.6,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _VodTile(item: items[i]),
            ),
    );
  }
}

class _VodTile extends StatefulWidget {
  final VodItem item;
  const _VodTile({required this.item});

  @override
  State<_VodTile> createState() => _VodTileState();
}

class _VodTileState extends State<_VodTile> {
  double _progress = 0;
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await DownloadService.download(
        url: widget.item.streamUrl,
        filename: '${widget.item.title.replaceAll(RegExp(r"[^A-Za-z0-9]"), "_")}.mp4',
        onProgress: (r, t) { if (t > 0 && mounted) setState(() => _progress = r / t); },
      );
    } catch (_) {}
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DpadFocusable(
      effects: StreamiaFocus.card, // Klammern entfernt
      onSelect: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PlayerScreen(
            streamUrl: widget.item.streamUrl,
            title: widget.item.title,
          ))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.item.posterUrl != null
                      ? CachedNetworkImage(imageUrl: widget.item.posterUrl!, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.movie, size: 48))
                      : const Icon(Icons.movie, size: 48),
                  Positioned(
                    right: 8, top: 8,
                    child: DpadFocusable(
                      effects: StreamiaFocus.card, // Klammern entfernt
                      onSelect: _download,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: Icon(_downloading ? Icons.downloading : Icons.download, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  if (_downloading && _progress > 0)
                    Positioned(left: 0, right: 0, bottom: 0,
                      child: LinearProgressIndicator(value: _progress, backgroundColor: Colors.black45, color: AppTheme.electricBlue)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(widget.item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

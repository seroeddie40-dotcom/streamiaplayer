importimport 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dpad/dpad.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/focus_effects.dart';
import '../providers/content_provider.dart';
import '../models/channel.dart';
import 'player_screen.dart';

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final channels = context.watch<ContentProvider>().channels;
    return Scaffold(
      appBar: AppBar(title: const Text('Live TV')),
      body: channels.isEmpty
          ? const Center(child: Text('Keine Sender vorhanden'))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.6,
                ),
                itemCount: channels.length,
                itemBuilder: (context, i) => _ChannelTile(channel: channels[i]),
              ),
            ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DpadFocusable(
      effects: StreamiaFocus.card,
      onSelect: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel, isLive: true))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.electricBlue.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: channel.logoUrl != null
                    ? CachedNetworkImage(imageUrl: channel.logoUrl!, fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(Icons.tv, size: 40))
                    : const Icon(Icons.tv, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(channel.name, textAlign: TextAlign.center, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

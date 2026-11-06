import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../providers/content_provider.dart';
import '../models/series.dart';
import '../services/download_service.dart';
import 'player_screen.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<ContentProvider>().series;
    return Scaffold(
      appBar: AppBar(title: const Text('Serien')),
      body: list.isEmpty
          ? const Center(child: Text('Keine Serien vorhanden'))
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.6,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) => _SeriesTile(series: list[i]),
            ),
    );
  }
}

class _SeriesTile extends StatelessWidget {
  final Series series;
  const _SeriesTile({required this.series});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: series))),
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
              child: series.posterUrl != null
                  ? CachedNetworkImage(imageUrl: series.posterUrl!, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.video_library, size: 48))
                  : const Icon(Icons.video_library, size: 48),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(series.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class SeriesDetailScreen extends StatelessWidget {
  final Series series;
  const SeriesDetailScreen({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(series.title)),
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (series.posterUrl != null)
                    AspectRatio(aspectRatio: 2 / 3,
                        child: ClipRRect(borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(imageUrl: series.posterUrl!, fit: BoxFit.cover))),
                  const SizedBox(height: 16),
                  if (series.plot != null)
                    Text(series.plot!, maxLines: 8, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: series.seasons.length,
              itemBuilder: (context, i) => _SeasonSection(series: series, season: series.seasons[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonSection extends StatelessWidget {
  final Series series;
  final Season season;
  const _SeasonSection({required this.series, required this.season});

  Future<void> _downloadSeason(BuildContext context) async {
    for (final ep in season.episodes) {
      try {
        await DownloadService.download(
          url: ep.streamUrl,
          filename: '${series.title}_S${season.number}E${ep.number}.mp4',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('Staffel ${season.number}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              InkWell(
                onTap: () => _downloadSeason(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.electricBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 6),
                      Text('Staffel herunterladen'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ...season.episodes.map((ep) => InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PlayerScreen(
                episodes: season.episodes,
                initialEpisodeIndex: season.episodes.indexOf(ep),
                title: '${series.title} - ${ep.title}',
                series: series,
              ))),
          child: ListTile(
            leading: CircleAvatar(child: Text('${ep.number}')),
            title: Text(ep.title),
            trailing: InkWell(
              onTap: () async {
                try {
                  await DownloadService.download(
                    url: ep.streamUrl,
                    filename: '${series.title}_S${season.number}E${ep.number}.mp4',
                  );
                } catch (_) {}
              },
              child: const Icon(Icons.download),
            ),
          ),
        )),
      ],
    );
  }
}

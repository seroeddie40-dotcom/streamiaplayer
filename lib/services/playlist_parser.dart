import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series.dart';
import '../providers/content_provider.dart';

class PlaylistParser {
  static Future<void> parseAndLoad(String urlOrContent, ContentProvider content) async {
    String contentText = urlOrContent;
    
    if (urlOrContent.startsWith('http')) {
      final response = await http.get(Uri.parse(urlOrContent));
      if (response.statusCode == 200) {
        contentText = response.body;
      } else {
        throw Exception('Fehler beim Herunterladen der Playlist');
      }
    }

    final lines = contentText.split('\n');
    final channels = <Channel>[];
    final vodItems = <VodItem>[];
    final seriesMap = <String, Series>{};

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentUrl;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('#EXTINF:')) {
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        currentName = nameMatch?.group(1)?.trim();

        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        currentLogo = logoMatch?.group(1);

        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        currentGroup = groupMatch?.group(1);
        
      } else if (line.startsWith('http') && currentName != null) {
        currentUrl = line;
        
        final isMovie = currentUrl.endsWith('.mp4') || currentUrl.endsWith('.mkv') || currentUrl.endsWith('.avi');
        
        if (isMovie) {
          vodItems.add(VodItem(
            id: 'vod_${vodItems.length}',
            title: currentName,
            posterUrl: currentLogo,
            streamUrl: currentUrl,
          ));
        } else if (currentGroup != null && (currentGroup.toLowerCase().contains('serie') || currentGroup.toLowerCase().contains('series'))) {
          final seriesTitle = currentGroup; 
          
          final epNumber = seriesMap[seriesTitle]?.seasons.first.episodes.length ?? 0;
          final newEpisode = Episode(
            id: 'ep_${seriesTitle}_$epNumber',
            title: currentName,
            number: epNumber + 1,
            streamUrl: currentUrl,
          );

          if (seriesMap.containsKey(seriesTitle)) {
            seriesMap[seriesTitle]!.seasons.first.episodes.add(newEpisode);
          } else {
            seriesMap[seriesTitle] = Series(
              id: 'ser_${seriesMap.length}',
              title: seriesTitle,
              posterUrl: currentLogo,
              seasons: [Season(number: 1, episodes: [newEpisode])],
            );
          }
        } else {
          channels.add(Channel(
            id: 'ch_${channels.length}',
            name: currentName,
            streamUrl: currentUrl,
            logoUrl: currentLogo,
            category: currentGroup,
          ));
        }
        
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentUrl = null;
      }
    }

    content.setChannels(channels);
    content.setVod(vodItems);
    content.setSeries(seriesMap.values.toList());
  }
}

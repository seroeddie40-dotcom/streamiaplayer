import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/series.dart';

class PlaylistParser {
  static Future<void> parseAndLoad(String urlOrContent, ContentProvider content) async {
    String content = urlOrContent;
    
    // Wenn es eine URL ist, laden wir den Inhalt herunter
    if (urlOrContent.startsWith('http')) {
      final response = await http.get(Uri.parse(urlOrContent));
      if (response.statusCode == 200) {
        content = response.body;
      } else {
        throw Exception('Fehler beim Herunterladen der Playlist');
      }
    }

    final lines = content.split('\n');
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
        // Metadaten auslesen
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        currentName = nameMatch?.group(1)?.trim();

        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        currentLogo = logoMatch?.group(1);

        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        currentGroup = groupMatch?.group(1);
        
      } else if (line.startsWith('http') && currentName != null) {
        currentUrl = line;
        
        // Logik zum Sortieren: Ist es ein Film, eine Serie oder Live-TV?
        final isMovie = currentUrl.endsWith('.mp4') || currentUrl.endsWith('.mkv') || currentUrl.endsWith('.avi');
        
        if (isMovie) {
          // VOD Film
          vodItems.add(VodItem(
            id: 'vod_${vodItems.length}',
            title: currentName,
            posterUrl: currentLogo,
            streamUrl: currentUrl,
          ));
        } else if (currentGroup != null && (currentGroup.toLowerCase().contains('serie') || currentGroup.toLowerCase().contains('series'))) {
          // Serie
          final seriesTitle = currentGroup; // Nutze den Gruppen-Namen als Serientitel
          
          // Erstelle eine Episode
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
          // Live TV Sender
          channels.add(Channel(
            id: 'ch_${channels.length}',
            name: currentName,
            streamUrl: currentUrl,
            logoUrl: currentLogo,
            category: currentGroup,
          ));
        }
        
        // Reset für nächste Zeile
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentUrl = null;
      }
    }

    // Daten in den Provider laden
    content.setChannels(channels);
    content.setVod(vodItems);
    content.setSeries(seriesMap.values.toList());
  }
}

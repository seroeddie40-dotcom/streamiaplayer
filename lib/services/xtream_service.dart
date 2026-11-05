import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/vod_item.dart';

class XtreamService {
  final String baseUrl;
  final String username;
  final String password;

  XtreamService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Future<List<Channel>> getLiveStreams({int? categoryId}) async {
    final url = Uri.parse(
      '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams'
      '${categoryId != null ? '&category_id=$categoryId' : ''}',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Xtream API error');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) {
      final streamId = json['stream_id'].toString();
      return Channel(
        id: streamId,
        name: json['name'] ?? 'Unknown',
        streamUrl: '$baseUrl/live/$username/$password/$streamId.ts',
        logoUrl: json['stream_icon'],
        category: json['category_name'],
        epgChannelId: json['epg_channel_id'],
      );
    }).toList();
  }

  Future<List<VodItem>> getVodStreams({int? categoryId}) async {
    final url = Uri.parse(
      '$baseUrl/player_api.php?username=$username&password=$password&action=get_vod_streams'
      '${categoryId != null ? '&category_id=$categoryId' : ''}',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Xtream API error');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) {
      final streamId = json['stream_id'].toString();
      final ext = json['container_extension'] ?? 'mp4';
      return VodItem(
        id: streamId,
        title: json['name'] ?? 'Unknown',
        plot: json['plot'],
        posterUrl: json['stream_icon'],
        streamUrl: '$baseUrl/movie/$username/$password/$streamId.$ext',
      );
    }).toList();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class TvServer {
  static HttpServer? _server;
  static Function(String m3u, String epg)? onDataReceived;

  static Future<String?> start(Function(String m3u, String epg) callback) async {
    onDataReceived = callback;
    final router = Router();

    // Diese Seite sieht der Nutzer auf seinem Handy
    router.get('/', (Request request) {
      return Response.ok(
        '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Streamia TV Setup</title>
          <style>
            body { font-family: sans-serif; background: #0A0E1A; color: white; padding: 20px; }
            input, textarea { width: 100%; padding: 12px; margin: 8px 0; box-sizing: border-box; border-radius: 8px; border: none; }
            button { width: 100%; padding: 15px; background: #00B4FF; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: bold; margin-top: 20px; }
            h1 { color: #00B4FF; }
          </style>
        </head>
        <body>
          <h1>Streamia Player</h1>
          <p>Gib hier deine Playlist-Daten ein. Sie werden direkt an deinen TV gesendet.</p>
          <form action="/upload" method="POST">
            <label>M3U URL (oder füge M3U-Text ein)</label>
            <textarea name="m3u" rows="4" placeholder="http://example.com/playlist.m3u"></textarea>
            
            <label>EPG URL (Optional)</label>
            <input type="text" name="epg" placeholder="http://example.com/epg.xml">
            
            <button type="submit">An TV senden</button>
          </form>
        </body>
        </html>
        ''',
        headers: {'content-type': 'text/html'},
      );
    });

    // Diese Route empfängt die Daten vom Handy
    router.post('/upload', (Request request) async {
      final body = await request.readAsString();
      final params = Uri.splitQueryString(body);
      final m3u = params['m3u'] ?? '';
      final epg = params['epg'] ?? '';

      if (onDataReceived != null) {
        onDataReceived!(m3u, epg);
      }

      return Response.ok(
        '<html><body style="background:#0A0E1A;color:white;text-align:center;padding-top:50px;"><h1>Erfolgreich gesendet!</h1><p>Du kannst dieses Fenster jetzt schließen.</p></body></html>',
        headers: {'content-type': 'text/html'},
      );
    });

    try {
      _server = await shelf_io.serve(router.call, InternetAddress.anyIPv4, 8080);
      return _server!.address.address;
    } catch (e) {
      return null;
    }
  }

  static void stop() {
    _server?.close(force: true);
    _server = null;
  }
}

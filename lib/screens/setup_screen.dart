import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../services/playlist_parser.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final TextEditingController _m3uController = TextEditingController();
  final TextEditingController _epgController = TextEditingController();
  final TextEditingController _xtreamServerController = TextEditingController();
  final TextEditingController _xtreamUserController = TextEditingController();
  final TextEditingController _xtreamPassController = TextEditingController();

  bool _isLoading = false;
  String? _qrLink;
  String? _qrBlobId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _createQrSession();
  }

  Future<void> _createQrSession() async {
    try {
      final response = await http.post(
        Uri.parse('https://jsonblob.com/api/jsonBlob'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'m3u': '', 'epg': ''}),
      );
      if (response.statusCode == 201) {
        final blobId = response.headers['location']?.split('/').last;
        setState(() {
          _qrBlobId = blobId;
          _qrLink = 'https://jsonblob.com/$blobId';
        });
      }
    } catch (e) {
      debugPrint('QR-Erstellung fehlgeschlagen: $e');
    }
  }

  Future<void> _checkForRemoteInput() async {
    if (_qrBlobId == null) return;
    try {
      final response = await http.get(Uri.parse('https://jsonblob.com/api/jsonBlob/$_qrBlobId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['m3u'] != null && data['m3u'].isNotEmpty) {
          _processPlaylist(data['m3u']);
          setState(() => _qrLink = null);
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Prüfen: $e');
    }
  }

  Future<void> _pickFile(bool isM3u) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: isM3u ? ['m3u', 'm3u8'] : ['xml', 'gz'],
      );
      if (result != null && result.files.single.path != null) {
        final content = await File(result.files.single.path!).readAsString();
        setState(() {
          if (isM3u) {
            _m3uController.text = content;
          } else {
            _epgController.text = content;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _processPlaylist(String input) async {
    setState(() => _isLoading = true);
    try {
      final contentProvider = context.read<ContentProvider>();
      await PlaylistParser.parseAndLoad(input, contentProvider);
      contentProvider.setLoaded(true);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _m3uController.dispose();
    _epgController.dispose();
    _xtreamServerController.dispose();
    _xtreamUserController.dispose();
    _xtreamPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist einrichten'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (_qrLink != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.darkSurface,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: QrImageView(data: _qrLink!, size: 80),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Handy-Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Scanne den QR-Code, um die Daten bequem per Handy einzugeben.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text('MAC: ${auth.macAddress}', style: const TextStyle(fontFamily: 'monospace', color: AppTheme.electricBlue)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _checkForRemoteInput,
                              child: const Text('Daten vom Handy abrufen'),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.electricBlue,
                labelColor: AppTheme.electricBlue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'M3U / EPG'),
                  Tab(text: 'Xtream Codes'),
                ],
              ),
              
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildM3uTab(),
                    _buildXtreamTab(),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_tabController.index == 0 && _m3uController.text.isNotEmpty) {
                        _processPlaylist(_m3uController.text);
                      } else if (_tabController.index == 1 && _xtreamServerController.text.isNotEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xtream wird geladen...')));
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte Daten eingeben')));
                      }
                    },
                    child: const Text('Speichern & Starten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildM3uTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('M3U Playlist URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _m3uController,
            decoration: const InputDecoration(
              hintText: 'http://example.com/playlist.m3u',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          const Text('EPG (XMLTV) URL (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _epgController,
            decoration: const InputDecoration(
              hintText: 'http://example.com/epg.xml',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('ODER', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFile(true),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('M3U vom Handy'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFile(false),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('EPG vom Handy'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('USB-Stick durchsuchen (benötigt Android TV) ...')));
              },
              icon: const Icon(Icons.usb),
              label: const Text('Von USB-Stick laden (TV)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXtreamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _xtreamServerController,
            decoration: const InputDecoration(labelText: 'Server URL', hintText: 'http://server.com:8080', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamUserController,
            decoration: const InputDecoration(labelText: 'Benutzername', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamPassController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Passwort', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}

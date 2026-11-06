import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pairingUrl = 'https://streamia.app/pair?mac=${Uri.encodeComponent(auth.macAddress)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist einrichten'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // QR-Code Bereich
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.darkSurface,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.white,
                      child: QrImageView(data: pairingUrl, size: 80),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Schnelles Setup per Handy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Scanne den Code mit deinem Handy, um die Playlist bequem einzugeben.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('MAC: ${auth.macAddress}', style: const TextStyle(fontFamily: 'monospace', color: AppTheme.electricBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tabs
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
              
              // Tab-Inhalte
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildM3uTab(),
                    _buildXtreamTab(),
                  ],
                ),
              ),
              
              // Speichern Button
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
                         // Hier später Xtream-Logik einbauen
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xtream wird geladen...')));
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Handy-Speicher öffnen...')));
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Vom Handy laden'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('USB-Stick durchsuchen...')));
                  },
                  icon: const Icon(Icons.usb),
                  label: const Text('Von USB laden'),
                ),
              ),
            ],
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

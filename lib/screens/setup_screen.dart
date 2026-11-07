import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../services/playlist_parser.dart';
import '../services/tv_server.dart';
import '../core/localization/app_localizations.dart';
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
  String? _ipAddress;
  String? _qrLink;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initServer();
  }

  Future<void> _initServer() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    
    // Startet den lokalen Webserver auf dem TV
    final serverIp = await TvServer.start((m3u, epg) {
      if (mounted) {
        setState(() {
          _m3uController.text = m3u;
          if (epg.isNotEmpty) _epgController.text = epg;
        });
        // Wechselt automatisch zum M3U Tab und startet den Ladevorgang
        _tabController.animateTo(1);
        _processPlaylist(m3u);
      }
    });

    setState(() {
      _ipAddress = serverIp ?? ip ?? '127.0.0.1';
      _qrLink = 'http://$_ipAddress:8080';
    });
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
    if (input.isEmpty) return;
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
    TvServer.stop();
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
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('setup_title')),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.electricBlue,
          labelColor: AppTheme.electricBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'QR-Setup'),
            Tab(text: 'M3U / EPG'),
            Tab(text: 'Xtream Codes'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildQrTab(auth, l10n),
              _buildM3uTab(l10n),
              _buildXtreamTab(l10n),
            ],
          ),
    );
  }

  Widget _buildQrTab(AuthProvider auth, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Setup per Handy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Scanne den QR-Code mit deiner Handy-Kamera. Es öffnet sich eine Seite, auf der du deine M3U eingeben kannst.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          if (_qrLink != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _qrLink!,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            )
          else
            const CircularProgressIndicator(),

          const SizedBox(height: 32),
          
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.wifi, color: AppTheme.electricBlue),
                    title: const Text('Lokale IP'),
                    subtitle: Text(_ipAddress ?? 'Lade...', style: const TextStyle(fontFamily: 'monospace')),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.devices, color: AppTheme.electricBlue),
                    title: const Text('MAC-Adresse'),
                    subtitle: Text(auth.macAddress, style: const TextStyle(fontFamily: 'monospace')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildM3uTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('m3u_url'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _m3uController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'http://example.com/playlist.m3u',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.t('epg_url'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFile(true),
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.t('btn_m3u_phone'), textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFile(false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(l10n.t('btn_epg_phone'), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_m3uController.text.isNotEmpty) {
                  _processPlaylist(_m3uController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte M3U Daten eingeben oder hochladen')));
                }
              },
              child: Text(l10n.t('btn_start'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXtreamTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _xtreamServerController,
            decoration: InputDecoration(labelText: l10n.t('xtream_server'), hintText: 'http://server.com:8080', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamUserController,
            decoration: InputDecoration(labelText: l10n.t('xtream_user'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamPassController,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.t('xtream_pass'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xtream wird geladen...')));
              },
              child: Text(l10n.t('btn_start'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

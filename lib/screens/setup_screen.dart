import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../services/playlist_parser.dart';
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
  String? _macAddress;

  @override
  void initState() {
    super.initState();
    // 3 Tabs: QR, M3U/EPG, Xtream
    _tabController = TabController(length: 3, vsync: this);
    _getNetworkInfo();
  }

  Future<void> _getNetworkInfo() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    final auth = context.read<AuthProvider>();
    setState(() {
      _ipAddress = ip ?? '127.0.0.1';
      _macAddress = auth.macAddress;
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
    // Die Daten, die im QR-Code stecken. 
    // Wenn du später eine Handy-App baust, liest diese diesen String.
    final qrData = 'streamia://pair?mac=${auth.macAddress}&ip=$_ipAddress';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Scanne diesen Code mit deinem Handy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Öffne die Streamia App auf deinem Handy, um die Playlist zu übertragen.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Der echte QR-Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Info-Karten
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.wifi, color: AppTheme.electricBlue),
                    title: const Text('IP-Adresse'),
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
          
          const SizedBox(height: 32),
          const Text(
            'Alternativ kannst du die Playlist direkt am TV eingeben:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricBlue),
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Manuell eingeben (M3U)', style: TextStyle(color: Colors.white)),
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
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.t('or'), style: const TextStyle(color: Colors.grey)),
              ),
              const Expanded(child: Divider()),
            ],
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('USB-Stick durchsuchen...')));
              },
              icon: const Icon(Icons.usb),
              label: Text(l10n.t('btn_usb')),
            ),
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

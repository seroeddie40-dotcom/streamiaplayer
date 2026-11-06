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
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('setup_title')),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.electricBlue,
                labelColor: AppTheme.electricBlue,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: l10n.t('tab_m3u')),
                  Tab(text: l10n.t('tab_xtream')),
                ],
              ),
              
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildM3uTab(l10n, auth),
                    _buildXtreamTab(l10n),
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
                    child: Text(l10n.t('btn_start'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildM3uTab(AppLocalizations l10n, AuthProvider auth) {
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
                  label: Text(l10n.t('btn_m3u_phone')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickFile(false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(l10n.t('btn_epg_phone')),
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
          
          if (_qrLink != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.electricBlue.withOpacity(0.3)),
              ),
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
                        Text(l10n.t('qr_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(l10n.t('qr_desc'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _checkForRemoteInput,
                          child: Text(l10n.t('qr_btn')),
                        )
                      ],
                    ),
                  ),
                ],
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
        ],
      ),
    );
  }
}

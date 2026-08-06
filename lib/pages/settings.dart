import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../theme/nipah_theme.dart';
import '../widgets/nipah_loader.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSection = 'general';
  String _language = 'English';
  String _videoQuality = 'Auto';
  String _defaultPlayer = 'In-app Player';
  bool _autoRotate = true;
  bool _nsfwFilter = false;
  String _themeColor = 'Gold';
  String _themeName = 'Dark';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await getSettings();
    if (mounted) {
      setState(() {
        _language = s['language'] ?? 'English';
        _videoQuality = s['videoQuality'] ?? 'Auto';
        _defaultPlayer = s['player'] ?? 'In-app Player';
        _autoRotate = s['autoRotate'] ?? true;
        _nsfwFilter = s['nsfwFilter'] ?? false;
        _themeColor = s['themeColor'] ?? 'Gold';
        _themeName = s['theme'] ?? 'Dark';
        _loaded = true;
      });
    }
  }

  Future<void> _save(String key, dynamic value) async {
    await saveSetting(key, value);
    if (key == 'themeColor') {
      NipahColors.setAccent(value as String);
      if (mounted) setState(() {});
    } else if (key == 'theme') {
      NipahColors.setTheme(value as String);
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: NipahLoader(size: 32)),
    );
    final update = await checkForUpdate();
    if (!mounted) return;
    Navigator.pop(context);

    if (update == null) {
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: NipahColors.surface,
        shape: const RoundedRectangleBorder(),
        title: Text('No Update', style: NipahTheme.heading(size: 18)),
        content: Text('Could not check for updates. Check your internet connection.',
          style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
          child: Text('OK', style: NipahTheme.body(color: NipahColors.gold)))],
      ));
      return;
    }

    final latestVersion = update['version'] ?? '';
    final hasUpdate = latestVersion.isNotEmpty && latestVersion != currentVersion;
    showDialog(context: context, builder: (_) => _UpdateDialog(
      hasUpdate: hasUpdate,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseName: update['name'] ?? '',
      releaseNotes: update['body'] ?? '',
      apkUrl: update['apkUrl'],
      apkSize: update['apkSize'],
    ));
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync(recursive: true);
      int count = 0;
      for (final file in files) {
        try {
          await file.delete();
          count++;
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cleared $count cache files'),
          backgroundColor: NipahColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: NipahColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(backgroundColor: NipahColors.bg, body: const Center(child: NipahLoader(size: 28)));
    }

    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Settings', style: NipahTheme.heading(size: 28)),
                  const Spacer(),
                  Text('v1.2.1', style: NipahTheme.label(size: 10, color: NipahColors.textDim)),
                ],
              ),
            ),
            _buildSectionTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildSectionContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTabs() {
    final sections = [
      {'id': 'general', 'icon': Icons.settings_outlined, 'label': 'General'},
      {'id': 'player', 'icon': Icons.play_circle_outline, 'label': 'Player'},
      {'id': 'data', 'icon': Icons.storage_outlined, 'label': 'Data'},
      {'id': 'about', 'icon': Icons.info_outline, 'label': 'About'},
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: NipahColors.lineSoft))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final s = sections[index];
          final isSelected = _selectedSection == s['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedSection = s['id'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isSelected ? NipahColors.gold : Colors.transparent, width: 2)),
              ),
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, size: 16, color: isSelected ? NipahColors.gold : NipahColors.textDim),
                  const SizedBox(width: 6),
                  Text(s['label'] as String, style: NipahTheme.label(size: 10, color: isSelected ? NipahColors.gold : NipahColors.textDim)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 'general': return _buildGeneralSection();
      case 'player': return _buildPlayerSection();
      case 'data': return _buildDataSection();
      case 'about': return _buildAboutSection();
      default: return _buildGeneralSection();
    }
  }

  // ── GENERAL ──────────────────────────────────────────────────────
  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HIGHLIGHT: Check for Update
        _buildUpdateCard(),
        const SizedBox(height: 16),
        _sectionTitle('APPEARANCE'),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.language, title: 'Language',
          child: _buildDropdown(value: _language, items: ['English', 'Espa\u00f1ol', 'Portugu\u00eas'],
            onChanged: (v) { setState(() => _language = v ?? 'English'); _save('language', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.palette, title: 'Theme'),
        _buildThemeGrid(),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.color_lens, title: 'Accent Color'),
        _buildAccentColorGrid(),
        const SizedBox(height: 16),
        _sectionTitle('CONTENT'),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.filter_list, title: 'Show NSFW Content',
          subtitle: 'Show adult-rated anime',
          trailing: _buildToggle(value: _nsfwFilter, onChanged: (v) { setState(() => _nsfwFilter = v); _save('nsfwFilter', v); })),
      ],
    );
  }

  Widget _buildUpdateCard() {
    return GestureDetector(
      onTap: _checkForUpdate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [NipahColors.accent.main, NipahColors.accent.strong],
          ),
          border: Border.all(color: NipahColors.accent.strong),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: NipahColors.bg.withValues(alpha: 0.3)),
              child: Icon(Icons.system_update, color: NipahColors.bg, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check for Update', style: NipahTheme.heading(size: 16, color: NipahColors.bg)),
                  const SizedBox(height: 2),
                  Text('Tap to check latest version', style: NipahTheme.body(size: 11, color: NipahColors.bg.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: NipahColors.bg, size: 20),
          ],
        ),
      ),
    );
  }

  // ── PLAYER ──────────────────────────────────────────────────────
  Widget _buildPlayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('PLAYBACK'),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.screen_rotation, title: 'Auto Rotate',
          subtitle: 'Rotate to landscape during playback',
          trailing: _buildToggle(value: _autoRotate, onChanged: (v) { setState(() => _autoRotate = v); _save('autoRotate', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.high_quality, title: 'Video Quality',
          subtitle: 'Preferred stream quality',
          child: _buildDropdown(value: _videoQuality, items: ['Auto', '1080p', '720p', '480p', '360p'],
            onChanged: (v) { setState(() => _videoQuality = v ?? 'Auto'); _save('videoQuality', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.play_circle, title: 'Preferred Player',
          subtitle: 'Choose video player',
          child: _buildDropdown(value: _defaultPlayer, items: ['In-app Player', 'External Player'],
            onChanged: (v) { setState(() => _defaultPlayer = v ?? 'In-app Player'); _save('player', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.info_outline, title: 'Player Engine',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: NipahColors.success.withValues(alpha: 0.1), border: Border.all(color: NipahColors.success)),
            child: Text('MediaKit', style: NipahTheme.label(size: 9, color: NipahColors.success)),
          )),
      ],
    );
  }

  // ── DATA ──────────────────────────────────────────────────────
  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('STORAGE'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _clearCache,
          child: _settingRow(icon: Icons.cleaning_services, title: 'Clear Cache',
            subtitle: 'Remove temporary files',
            trailing: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 20)),
        ),
        Divider(color: NipahColors.lineSoft),
        GestureDetector(
          onTap: () => _showClearHistoryDialog(),
          child: _settingRow(icon: Icons.history, title: 'Clear Watch History',
            subtitle: 'Remove all watched episodes',
            trailing: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 20)),
        ),
        Divider(color: NipahColors.lineSoft),
        GestureDetector(
          onTap: () => _showClearDataDialog(),
          child: _settingRow(icon: Icons.delete_forever, title: 'Clear All Data',
            subtitle: 'Remove library, history, and settings',
            iconColor: NipahColors.danger,
            trailing: Icon(Icons.chevron_right, color: NipahColors.danger, size: 20)),
        ),
      ],
    );
  }

  // ── ABOUT ──────────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('APP'),
        const SizedBox(height: 12),
        _buildAppInfoCard(),
        const SizedBox(height: 16),
        _sectionTitle('LINKS'),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.code, title: 'Source Code',
          trailing: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 20),
        ),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.bug_report, title: 'Report Issue',
          trailing: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 20),
        ),
        const SizedBox(height: 16),
        _sectionTitle('LIBRARIES'),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.movie, title: 'MediaKit', subtitle: 'Video player engine'),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.wifi, title: 'AniList API', subtitle: 'Anime data source'),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.storage, title: 'Shared Preferences', subtitle: 'Local storage'),
      ],
    );
  }

  // ── SHARED WIDGETS ──────────────────────────────────────────────
  Widget _sectionTitle(String text) => Text(text, style: NipahTheme.label(size: 11));

  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NipahTheme.sectionCardDecoration,
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [NipahColors.gold, NipahColors.goldStrong])),
            child: Icon(Icons.movie_filter, color: NipahColors.bg, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AnimoBox', style: NipahTheme.heading(size: 18)),
                const SizedBox(height: 2),
                Text('Version 1.2.1', style: NipahTheme.body(size: 12, color: NipahColors.textDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({required IconData icon, required String title, String? subtitle, Widget? child, Widget? trailing, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? NipahColors.textDim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NipahTheme.body(size: 14, weight: FontWeight.w500, color: NipahColors.text)),
                if (subtitle != null) Text(subtitle, style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
              ],
            ),
          ),
          if (child != null) child,
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildThemeGrid() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 8),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: appThemes.map((t) {
          final isSelected = _themeName == t.name;
          return GestureDetector(
            onTap: () { setState(() => _themeName = t.name); _save('theme', t.name); },
            child: Container(
              width: 72, height: 56,
              decoration: BoxDecoration(color: t.surface, border: Border.all(
                color: isSelected ? NipahColors.gold : t.cardBorder, width: isSelected ? 2 : 1)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.name, style: TextStyle(color: t.text, fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 6, height: 6, color: t.bg),
                    const SizedBox(width: 2),
                    Container(width: 6, height: 6, color: t.surface2),
                    const SizedBox(width: 2),
                    Container(width: 6, height: 6, color: t.text),
                  ]),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccentColorGrid() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 8),
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: accentPalette.map((accent) {
          final isSelected = _themeColor == accent.name;
          return GestureDetector(
            onTap: () { setState(() => _themeColor = accent.name); _save('themeColor', accent.name); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: accent.main, border: Border.all(
                color: isSelected ? NipahColors.text : Colors.transparent, width: 2)),
              child: isSelected ? Icon(Icons.check, color: NipahColors.bg, size: 18) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: NipahColors.surface2, border: Border.all(color: NipahColors.lineSoft)),
      child: DropdownButton<String>(
        value: value, isDense: true, isExpanded: false,
        dropdownColor: NipahColors.surface, underline: const SizedBox(),
        style: NipahTheme.label(size: 10, color: NipahColors.text),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggle({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 40, height: 22,
        decoration: BoxDecoration(
          color: value ? NipahColors.gold : NipahColors.surface2,
          border: Border.all(color: value ? NipahColors.gold : NipahColors.lineSoft)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 3), color: value ? NipahColors.bg : NipahColors.textDim),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: NipahColors.surface, shape: const RoundedRectangleBorder(),
      title: Text('Clear Watch History', style: NipahTheme.heading(size: 18)),
      content: Text('Remove all watched episodes?', style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: NipahTheme.body(color: NipahColors.textDim))),
        TextButton(onPressed: () async { await clearHistory(); if (context.mounted) Navigator.pop(context); },
          child: Text('Clear', style: NipahTheme.body(color: NipahColors.danger))),
      ],
    ));
  }

  void _showClearDataDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: NipahColors.surface, shape: const RoundedRectangleBorder(),
      title: Text('Clear All Data', style: NipahTheme.heading(size: 18)),
      content: Text('This will permanently remove library, history, and settings.', style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: NipahTheme.body(color: NipahColors.textDim))),
        TextButton(onPressed: () async { await clearAllData(); if (context.mounted) Navigator.pop(context); },
          child: Text('Clear All', style: NipahTheme.body(color: NipahColors.danger))),
      ],
    ));
  }
}

class _UpdateDialog extends StatefulWidget {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String? apkUrl;
  final int? apkSize;

  const _UpdateDialog({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    this.apkUrl,
    this.apkSize,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  bool _installing = false;
  double _progress = 0;
  String _filePath = '';

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _downloadApk() async {
    if (widget.apkUrl == null) return;
    setState(() { _downloading = true; _progress = 0; });
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('No storage');
      _filePath = '${dir.path}/AnimoBox-${widget.latestVersion}.apk';
      final file = File(_filePath);
      final request = http.Request('GET', Uri.parse(widget.apkUrl!));
      final response = await http.Client().send(request);
      final contentLength = response.contentLength ?? 0;
      int received = 0;
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() => _progress = received / contentLength);
        }
      }
      await sink.close();
      if (mounted) {
        setState(() { _downloading = false; _installing = true; _progress = 1; });
        await _installApk();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e'), backgroundColor: NipahColors.danger));
      }
    }
  }

  Future<void> _installApk() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        await launchUrl(Uri.file(_filePath), mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        setState(() => _installing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Opening installer...'),
          backgroundColor: NipahColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _installing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Install failed: $e'),
          backgroundColor: NipahColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NipahColors.surface,
      shape: const RoundedRectangleBorder(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.hasUpdate ? Icons.system_update : Icons.check_circle_outline,
            color: widget.hasUpdate ? NipahColors.gold : NipahColors.success, size: 48),
          const SizedBox(height: 16),
          Text(widget.hasUpdate ? 'Update Available' : 'You\'re Up to Date', style: NipahTheme.heading(size: 20)),
          const SizedBox(height: 8),
          Text(widget.hasUpdate ? 'v${widget.currentVersion} \u2192 v${widget.latestVersion}' : 'Version ${widget.currentVersion}',
            style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
          if (widget.apkSize != null) ...[
            const SizedBox(height: 4),
            Text(_formatSize(widget.apkSize), style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
          ],
          if (widget.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('Release Notes:', style: NipahTheme.label(size: 10, color: NipahColors.textDim))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: NipahColors.surface2, border: Border.all(color: NipahColors.lineSoft)),
              child: SingleChildScrollView(child: Text(widget.releaseNotes, style: NipahTheme.body(size: 12, color: NipahColors.textSoft))),
            ),
          ],
          if (_downloading || _installing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null,
              backgroundColor: NipahColors.surface2, valueColor: AlwaysStoppedAnimation<Color>(NipahColors.gold), minHeight: 4),
            const SizedBox(height: 8),
            Text(
              _installing ? 'Opening installer...' : '${(_progress * 100).toStringAsFixed(0)}%',
              style: NipahTheme.body(size: 11, color: NipahColors.textDim),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: (_downloading || _installing) ? null : () => Navigator.pop(context),
          child: Text(widget.hasUpdate ? 'Later' : 'OK', style: NipahTheme.body(color: NipahColors.textDim))),
        if (widget.hasUpdate && widget.apkUrl != null)
          TextButton(
            onPressed: (_downloading || _installing) ? null : _downloadApk,
            child: Text(
              _installing ? 'Installing...' : _downloading ? 'Downloading...' : 'Download & Install',
              style: NipahTheme.label(size: 11, color: NipahColors.gold)),
          ),
      ],
    );
  }
}

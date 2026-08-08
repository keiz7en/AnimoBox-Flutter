import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../api.dart';
import '../drama_api.dart';
import '../models.dart';
import '../theme/nipah_theme.dart';
import '../widgets/nipah_loader.dart';
import 'settings.dart';

class DramaWatchPage extends StatefulWidget {
  final String title;
  final int episode;
  final int mediaId;
  final List<DramaEpisode> episodes;
  final String coverImage;

  const DramaWatchPage({
    super.key,
    required this.title,
    required this.episode,
    required this.mediaId,
    required this.episodes,
    this.coverImage = '',
  });

  @override
  State<DramaWatchPage> createState() => _DramaWatchPageState();
}

class _DramaWatchPageState extends State<DramaWatchPage> {
  late final Player _player;
  late final VideoController _videoController;

  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isPlaying = false;
  int _currentEpisode = 1;
  Timer? _hideTimer;
  Timer? _positionSaveTimer;
  bool _historySaved = false;
  Duration _savedPosition = Duration.zero;
  bool _showResumeDialog = false;
  Duration _lastSavedPosition = Duration.zero;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<StreamSource> _sources = [];
  int _selectedSourceIndex = 0;
  int _selectedLinkIndex = 0;
  int _trySourceIndex = 0;
  int _tryLinkIndex = 0;
  bool _isRetrying = false;
  String _lastFailedUrl = '';
  bool _vlcChecked = false;
  bool _vlcInstalled = false;

  String get _positionKey => '${widget.mediaId}_drama_ep${_currentEpisode}';

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode;
    _player = Player();
    _videoController = VideoController(_player);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _applyAutoRotate();

    _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _player.stream.position.listen((position) {
      if (mounted) {
        setState(() => _position = position);
        if (_isPlaying && position.inSeconds > 2) {
          _lastSavedPosition = position;
          if (position.inSeconds % 5 == 0) {
            final dur = _player.state.duration;
            if (dur.inSeconds > 5) savePlaybackPosition(_positionKey, position, dur);
          }
        }
      }
    });
    _player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.stream.completed.listen((c) {
      if (c && mounted) clearPlaybackPosition(_positionKey);
    });
    _player.stream.error.listen((error) {
      if (mounted && error.isNotEmpty && !_isRetrying) {
        _isRetrying = true;
        debugPrint('DramaWatch: MediaKit error: $error');
        _trySourceIndex++;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _isRetrying = false;
            _tryNextSource();
          }
        });
      }
    });

    _init();
  }

  Future<void> _init() async {
    await _checkVlc();
    await _loadSavedPosition();
    _loadStream();
  }

  Future<void> _checkVlc() async {
    try {
      _vlcInstalled = await canLaunchUrl(Uri.parse('vlc://test'));
    } catch (_) {
      _vlcInstalled = false;
    }
    _vlcChecked = true;
  }

  Future<void> _applyAutoRotate() async {
    final settings = await getSettings();
    final autoRotate = settings['autoRotate'] ?? true;
    if (autoRotate) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _positionSaveTimer?.cancel();
    _saveCurrentPosition();
    _player.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadSavedPosition() async {
    final saved = await getPlaybackPosition(_positionKey);
    if (saved != null && mounted) {
      final posMs = saved['position'] as int? ?? 0;
      final durMs = saved['duration'] as int? ?? 0;
      if (posMs > 0 && durMs > 0) {
        final pos = Duration(milliseconds: posMs);
        final dur = Duration(milliseconds: durMs);
        if (dur.inSeconds > 5 && pos.inSeconds > 2) {
          setState(() {
            _savedPosition = pos;
            _showResumeDialog = true;
          });
        }
      }
    }
  }

  void _saveCurrentPosition() {
    final pos = _player.state.position;
    final dur = _player.state.duration;
    final savePos = pos.inSeconds > 2 ? pos : _lastSavedPosition;
    if (savePos.inSeconds > 2 && dur.inSeconds > 5) {
      savePlaybackPosition(_positionKey, savePos, dur);
    }
  }

  void _startPositionSaveTimer() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isPlaying) _saveCurrentPosition();
    });
  }

  void _resumeFromPosition() {
    setState(() => _showResumeDialog = false);
    final target = _savedPosition;
    _savedPosition = Duration.zero;
    _startPositionSaveTimer();
    _player.play();
    if (target.inSeconds > 0) {
      StreamSubscription? sub;
      sub = _player.stream.position.listen((_) {
        if (mounted) {
          _player.seek(target);
          sub?.cancel();
        }
      });
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) sub?.cancel();
      });
    }
  }

  void _startFromBeginning() {
    clearPlaybackPosition(_positionKey);
    setState(() => _showResumeDialog = false);
    _player.play();
    _startPositionSaveTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isPlaying) setState(() => _showControls = false);
      });
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  void _showControlsBriefly() {
    setState(() => _showControls = true);
    _resetHideTimer();
  }

  void _togglePlayPause() {
    _player.playOrPause();
    _showControlsBriefly();
  }

  void _seekForward() {
    final newPos = _position + const Duration(seconds: 10);
    _player.seek(newPos);
    _showControlsBriefly();
  }

  void _seekBackward() {
    final newPos = _position - const Duration(seconds: 10);
    final safe = newPos < Duration.zero ? Duration.zero : newPos;
    _player.seek(safe);
    _showControlsBriefly();
  }

  int _findEpisodeLink(StreamSource source) {
    for (int i = 0; i < source.links.length; i++) {
      if (source.links[i].quality.contains('$_currentEpisode')) return i;
    }
    return 0;
  }

  Future<void> _loadStream() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _historySaved = false;
    });

    try {
      final sources = await getDramaStreamSources(widget.mediaId, _currentEpisode);
      if (mounted) setState(() => _sources = sources);

      if (sources.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _hasError = true;
            _errorMessage = 'No sources found. CDN servers may be offline.';
          });
        }
        return;
      }

      _trySourceIndex = 0;
      _tryLinkIndex = _findEpisodeLink(sources.first);
      _selectedSourceIndex = 0;
      _selectedLinkIndex = _tryLinkIndex;

      _tryNextSource();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'Failed to load stream: $e';
        });
      }
    }
  }

  void _tryNextSource() {
    if (_trySourceIndex >= _sources.length) {
      if (mounted) {
        final lastUrl = _sources.isNotEmpty &&
            _tryLinkIndex >= 0 &&
            _tryLinkIndex < _sources.last.links.length
            ? _sources.last.links[_tryLinkIndex].url
            : '';
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _lastFailedUrl = lastUrl;
          _errorMessage = 'All servers unavailable. The streaming CDN may be down.';
        });
        if (lastUrl.isNotEmpty && _vlcInstalled) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _openInExternalPlayer();
          });
        }
      }
      return;
    }
    final source = _sources[_trySourceIndex];
    _tryLinkIndex = _findEpisodeLink(source);
    if (_tryLinkIndex >= source.links.length) {
      _trySourceIndex++;
      _tryNextSource();
      return;
    }
    _selectedSourceIndex = _trySourceIndex;
    _selectedLinkIndex = _tryLinkIndex;
    _initializeMediaKit(source.links[_tryLinkIndex].url);
  }

  Future<void> _initializeMediaKit(String url) async {
    if (url.isEmpty) {
      _trySourceIndex++;
      _tryNextSource();
      return;
    }
    try {
      await _player.stop();
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      };
      if (url.contains('.m3u8')) {
        headers['Referer'] = 'https://kissasian.dev/';
      }
      await _player.open(Media(url, httpHeaders: headers));

      if (_showResumeDialog) {
        await _player.pause();
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _isPlaying = false;
            _showControls = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _isPlaying = true;
            _showControls = true;
          });
        }
        _startPositionSaveTimer();
      }
      _resetHideTimer();
      _saveWatchHistory();
    } catch (e) {
      debugPrint('DramaWatch: MediaKit failed $url - $e');
      _trySourceIndex++;
      _tryNextSource();
    }
  }

  void _saveWatchHistory() {
    if (_historySaved) return;
    _historySaved = true;
    saveToHistory({
      'animeTitle': widget.title,
      'episode': _currentEpisode,
      'anilistId': widget.mediaId,
      'coverImage': widget.coverImage,
      'server': '',
      'watchedAt': DateTime.now().millisecondsSinceEpoch,
      'isDrama': true,
    });
  }

  void _changeEpisode(int delta) {
    final newEp = _currentEpisode + delta;
    if (newEp < 1 || newEp > widget.episodes.length) return;
    _saveCurrentPosition();
    setState(() => _currentEpisode = newEp);
    _loadStream();
  }

  Future<void> _openInExternalPlayer() async {
    if (_lastFailedUrl.isEmpty) return;
    if (_vlcInstalled) {
      final vlcUri = Uri.parse('vlc://${_lastFailedUrl}');
      if (await canLaunchUrl(vlcUri)) {
        await launchUrl(vlcUri);
        return;
      }
    }
    final genericUri = Uri.parse(_lastFailedUrl);
    if (await canLaunchUrl(genericUri)) {
      await launchUrl(genericUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openVlcPlayStore() async {
    final storeUri = Uri.parse('market://details?id=org.videolan.vlc');
    if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri);
    } else {
      final webUri = Uri.parse('https://play.google.com/store/apps/details?id=org.videolan.vlc');
      await launchUrl(webUri);
    }
  }

  void _switchServer(int sourceIndex) {
    if (sourceIndex < 0 || sourceIndex >= _sources.length) return;
    _selectedSourceIndex = sourceIndex;
    _selectedLinkIndex = _findEpisodeLink(_sources[sourceIndex]);
    final url = _sources[sourceIndex].links[_selectedLinkIndex].url;
    _initializeMediaKit(url);
  }

  void _showServerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: NipahColors.surface,
          border: Border(top: BorderSide(color: NipahColors.accent.main.withValues(alpha: 0.3))),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(margin: const EdgeInsets.only(top: 8), width: 32, height: 4, decoration: BoxDecoration(color: NipahColors.textDim, borderRadius: BorderRadius.circular(2))),
              Padding(padding: const EdgeInsets.all(16), child: Text(L10n.t('selectServer'), style: NipahTheme.heading(size: 16))),
              ...List.generate(_sources.length, (i) {
                final s = _sources[i];
                final isSelected = i == _selectedSourceIndex;
                return ListTile(
                  title: Text(s.server, style: NipahTheme.body(size: 14, color: isSelected ? NipahColors.gold : NipahColors.text)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: NipahColors.gold, size: 20) : null,
                  onTap: () { Navigator.pop(ctx); _switchServer(i); },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Video(controller: _videoController, controls: NoVideoControls),
            ),
          ),

          if (_isInitializing)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NipahLoader(size: 28),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

          if (_hasError)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, color: NipahColors.danger, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage, style: NipahTheme.body(size: 14, color: NipahColors.textDim), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        if (_lastFailedUrl.isNotEmpty && _vlcInstalled)
                          GestureDetector(
                            onTap: _openInExternalPlayer,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: NipahTheme.goldButtonDecoration,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.open_in_new, color: NipahColors.bg, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Open in VLC', style: NipahTheme.label(size: 12, color: NipahColors.bg)),
                                ],
                              ),
                            ),
                          ),
                        if (_lastFailedUrl.isNotEmpty && _vlcInstalled) const SizedBox(height: 12),
                        if (_lastFailedUrl.isNotEmpty && !_vlcInstalled)
                          GestureDetector(
                            onTap: _openVlcPlayStore,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: NipahTheme.goldButtonDecoration,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download, color: NipahColors.bg, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Install VLC to play', style: NipahTheme.label(size: 12, color: NipahColors.bg)),
                                ],
                              ),
                            ),
                          ),
                        if (_lastFailedUrl.isNotEmpty && !_vlcInstalled) const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _loadStream,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(border: Border.all(color: NipahColors.lineSoft)),
                            child: Text(L10n.t('retryAll'), style: NipahTheme.label(size: 12, color: NipahColors.textDim)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_showResumeDialog) _buildResumeDialog(),

          if (!_isInitializing && !_hasError && !_showResumeDialog)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(ignoring: !_showControls, child: _buildOverlayControls()),
            ),
        ],
      ),
    );
  }

  Widget _buildResumeDialog() {
    final pos = _savedPosition;
    final h = pos.inHours;
    final m = (pos.inMinutes.remainder(60)).toString().padLeft(2, '0');
    final s = (pos.inSeconds.remainder(60)).toString().padLeft(2, '0');
    final timeStr = h > 0 ? '$h:$m:$s' : '$m:$s';
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: NipahColors.surface, border: Border.all(color: NipahColors.lineSoft)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, color: NipahColors.gold, size: 48),
              const SizedBox(height: 16),
              Text('${L10n.t('resumeFrom')} $timeStr?', style: NipahTheme.heading(size: 20)),
              const SizedBox(height: 8),
              Text('Episode $_currentEpisode', style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _startFromBeginning,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: NipahColors.lineSoft), color: NipahColors.surface2),
                      child: Text(L10n.t('startOver'), style: NipahTheme.label(size: 11, color: NipahColors.textDim)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _resumeFromPosition,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [NipahColors.gold, NipahColors.goldStrong])),
                      child: Text(L10n.t('resume'), style: NipahTheme.label(size: 11, color: NipahColors.bg)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayControls() {
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xc8000000), Colors.transparent])),
            child: Row(
              children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.arrow_back, color: NipahColors.text, size: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title, style: NipahTheme.heading(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Episode $_currentEpisode', style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _seekBackward,
                child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: Icon(Icons.replay_10, color: Colors.white, size: 32)),
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [NipahColors.gold, NipahColors.goldStrong]),
                    boxShadow: [BoxShadow(color: NipahColors.gold.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)],
                  ),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: NipahColors.bg, size: 36),
                ),
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: _seekForward,
                child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: Icon(Icons.forward_10, color: Colors.white, size: 32)),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xc8000000), Colors.transparent])),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: NipahColors.gold, inactiveTrackColor: NipahColors.surface,
                    thumbColor: NipahColors.gold, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3, overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0 ? _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()) : 0.0,
                    max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (value) {
                      _player.seek(Duration(milliseconds: value.toInt()));
                      _showControlsBriefly();
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
                    Row(
                      children: [
                        if (_sources.length > 1)
                          GestureDetector(
                            onTap: _showServerSelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(border: Border.all(color: NipahColors.accent.main.withValues(alpha: 0.4)), color: NipahColors.accent.main.withValues(alpha: 0.1)),
                              child: Text(_sources[_selectedSourceIndex].server, style: NipahTheme.label(size: 9, color: NipahColors.gold)),
                            ),
                          ),
                        if (_sources.length > 1) const SizedBox(width: 12),
                        if (_currentEpisode > 1)
                          GestureDetector(onTap: () => _changeEpisode(-1), child: Icon(Icons.skip_previous, color: Colors.white, size: 24)),
                        if (_currentEpisode < widget.episodes.length) ...[
                          const SizedBox(width: 16),
                          GestureDetector(onTap: () => _changeEpisode(1), child: Icon(Icons.skip_next, color: Colors.white, size: 24)),
                        ],
                      ],
                    ),
                    Text(_formatDuration(_duration), style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

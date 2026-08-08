import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../api.dart';
import '../models.dart';
import '../theme/nipah_theme.dart';
import '../widgets/nipah_loader.dart';
import 'settings.dart';

class WatchPage extends StatefulWidget {
  final String animeTitle;
  final int episode;
  final int anilistId;
  final Anime? anime;

  const WatchPage({
    super.key,
    required this.animeTitle,
    required this.episode,
    this.anilistId = 0,
    this.anime,
  });

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  late final Player _player;
  late final VideoController _videoController;
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isPlaying = false;
  List<StreamSource> _sources = [];
  int _selectedSourceIndex = 0;
  int _selectedLinkIndex = 0;
  int _currentEpisode = 1;
  Timer? _hideTimer;
  Timer? _positionSaveTimer;
  bool _historySaved = false;
  Duration _savedPosition = Duration.zero;
  bool _showResumeDialog = false;
  String _preferredQuality = 'Auto';
  int _trySourceIndex = 0;
  int _tryLinkIndex = 0;
  bool _isRetrying = false;
  String _lastFailedUrl = '';
  Timer? _loadingTimer;
  int _loadingSeconds = 0;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  String get _positionKey => '${widget.anilistId}_ep$_currentEpisode';

  Duration _lastSavedPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode;
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 1024 * 1024 * 8,
      ),
    );
    _videoController = VideoController(_player);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _applyAutoRotate();

    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
        if (playing) {
          _resetHideTimer();
        } else {
          _hideTimer?.cancel();
          setState(() => _showControls = true);
          _saveCurrentPosition();
        }
      }
    });

    _player.stream.position.listen((position) {
      if (mounted) {
        setState(() => _position = position);
        if (_isPlaying && position.inSeconds > 2) {
          _lastSavedPosition = position;
          if (position.inSeconds % 5 == 0) {
            final dur = _player.state.duration;
            if (dur.inSeconds > 5) {
              savePlaybackPosition(_positionKey, position, dur);
            }
          }
        }
      }
    });

    _player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.stream.completed.listen((completed) {
      if (completed && mounted) {
        clearPlaybackPosition(_positionKey);
      }
    });

    _player.stream.error.listen((error) {
      if (mounted && error.isNotEmpty && !_isRetrying) {
        _isRetrying = true;
        debugPrint('WatchPage: Player error: $error - trying next source');
        _trySourceIndex++;
        Future.delayed(const Duration(milliseconds: 150), () {
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
    final settings = await getSettings();
    _preferredQuality = settings['videoQuality'] ?? 'Auto';
    await _loadSavedPosition();
    _loadStream();
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
    _loadingTimer?.cancel();
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

  void _startLoadingTimer() {
    _loadingSeconds = 0;
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _loadingSeconds++);
      } else {
        t.cancel();
      }
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  void _resumeFromPosition() {
    setState(() {
      _showResumeDialog = false;
    });
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
    setState(() {
      _showResumeDialog = false;
    });
    _player.play();
    _startPositionSaveTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
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

  Map<String, String> _getHeadersForSource(StreamSource source) {
    final headers = <String, String>{
      'User-Agent': _defaultUA,
    };

    if (source.server.contains('AniKoto')) {
      headers['Referer'] = 'https://anikototv.to/';
    } else if (source.server.contains('AnimeHeaven')) {
      headers['Referer'] = 'https://animeheaven.me/';
    } else if (source.server.contains('Vidplay')) {
      headers['Referer'] = 'https://vidsrc.cc/';
    } else {
      headers['Referer'] = 'https://anikototv.to/';
    }

    return headers;
  }

  Future<void> _loadStream() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _historySaved = false;
    });

    final titleVariants = widget.anime?.allTitles;

    try {
      final sources = await getStreamURL(
        widget.animeTitle,
        widget.anilistId,
        _currentEpisode,
        titleVariants: titleVariants,
      );
      if (mounted) {
        setState(() => _sources = sources);
      }

      if (sources.isEmpty || (sources.length == 1 && sources.first.server == 'Unavailable')) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = sources.isNotEmpty ? sources.first.links.first.quality : 'No streaming sources found.';
        });
        return;
      }

      _trySourceIndex = 0;
      _tryLinkIndex = _selectBestLink(sources.first);
      _selectedSourceIndex = 0;
      _selectedLinkIndex = _tryLinkIndex;
      _tryNextSource();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'Failed to load stream: $e';
      });
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
          _errorMessage = 'All servers unavailable. Try again later.';
        });
      }
      return;
    }
    final source = _sources[_trySourceIndex];
    _tryLinkIndex = _selectBestLink(source);
    if (_tryLinkIndex >= source.links.length) {
      _trySourceIndex++;
      _tryNextSource();
      return;
    }
    _selectedSourceIndex = _trySourceIndex;
    _selectedLinkIndex = _tryLinkIndex;
    _initializePlayer(source.links[_tryLinkIndex].url, source);
  }

  Future<void> _initializePlayer(String url, StreamSource source) async {
    if (url.isEmpty) {
      _trySourceIndex++;
      _tryNextSource();
      return;
    }

    try {
      await _player.stop();
      _startLoadingTimer();
      final headers = _getHeadersForSource(source);
      await _player.open(
        Media(url, httpHeaders: headers),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Timeout');
      });

      if (_showResumeDialog) {
        _stopLoadingTimer();
        await _player.pause();
        setState(() {
          _isInitializing = false;
          _isPlaying = false;
          _showControls = true;
        });
      } else {
        _stopLoadingTimer();
        setState(() {
          _isInitializing = false;
          _isPlaying = true;
          _showControls = true;
        });
        _startPositionSaveTimer();
      }
      _resetHideTimer();
      _saveWatchHistory();
    } catch (e) {
      _stopLoadingTimer();
      debugPrint('WatchPage: Failed to open $url - $e');
      _trySourceIndex++;
      _tryNextSource();
    }
  }

  void _saveWatchHistory() {
    if (_historySaved) return;
    _historySaved = true;
    saveToHistory({
      'animeTitle': widget.animeTitle,
      'episode': _currentEpisode,
      'anilistId': widget.anilistId,
      'coverImage': widget.anime?.coverImage ?? '',
      'server': _sources.isNotEmpty ? _sources[_selectedSourceIndex].server : '',
      'watchedAt': DateTime.now().millisecondsSinceEpoch,
    });
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

  void _showServerSheet() {
    _showControlsBriefly();
    showModalBottomSheet(
      context: context,
      backgroundColor: NipahColors.surface,
      shape: const RoundedRectangleBorder(),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: NipahColors.surface,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    color: NipahColors.textDim,
                  ),
                  Text(L10n.t('selectServer'), style: NipahTheme.heading(size: 18)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _sources.length,
                      itemBuilder: (context, sourceIndex) {
                        final source = _sources[sourceIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(color: NipahColors.lineSoft),
                      ),
                    ),
                                    child: Text(
                                      _getSourceShortName(source.server),
                                      style: NipahTheme.label(
                                        size: 10,
                                        color: _getSourceColor(source.server),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    source.type.toUpperCase(),
                                    style: NipahTheme.label(size: 10, color: NipahColors.textDim),
                                  ),
                                ],
                              ),
                            ),
                            ...List.generate(source.links.length, (linkIndex) {
                              final link = source.links[linkIndex];
                              final isSelected = sourceIndex == _selectedSourceIndex && linkIndex == _selectedLinkIndex;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [NipahColors.gold, NipahColors.goldStrong],
                                            )
                                          : null,
                                      color: isSelected ? null : NipahColors.surface2,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      link.quality,
                                      style: NipahTheme.label(
                                        size: 9,
                                        color: isSelected ? NipahColors.bg : NipahColors.textDim,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    link.quality == 'sub' ? 'Sub' : link.quality == 'dub' ? 'Dub' : link.quality,
                                    style: NipahTheme.body(
                                      size: 14,
                                      color: isSelected ? NipahColors.gold : NipahColors.text,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(Icons.play_circle, color: NipahColors.gold, size: 20)
                                      : null,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    setState(() {
                                      _selectedSourceIndex = sourceIndex;
                                      _selectedLinkIndex = linkIndex;
                                      _isInitializing = true;
                                      _hasError = false;
                                    });
                                    _trySourceIndex = sourceIndex;
                                    _tryLinkIndex = linkIndex;
                                    _initializePlayer(link.url, source);
                                  },
                                ),
                              );
                            }),
                            Divider(color: NipahColors.lineSoft, height: 1),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getSourceColor(String server) {
    final hash = server.hashCode.abs();
    final colors = [NipahColors.gold, NipahColors.success, NipahColors.goldStrong, NipahColors.danger];
    return colors[hash % colors.length];
  }

  String _getSourceShortName(String server) {
    final hash = server.hashCode.abs();
    final num = (hash % 9000) + 1000;
    return 'SRV $num';
  }

  void _changeEpisode(int delta) {
    final newEp = _currentEpisode + delta;
    if (newEp < 1) return;
    setState(() => _currentEpisode = newEp);
    _loadStream();
  }

  Future<void> _openInExternalPlayer() async {
    if (_lastFailedUrl.isEmpty) return;
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: _lastFailedUrl,
        type: 'video/*',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (_) {
      try {
        await launchUrl(
          Uri.parse(_lastFailedUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }
  }

  int _selectBestLink(StreamSource source) {
    if (source.links.isEmpty) return 0;
    if (_preferredQuality == 'Auto') return 0;
    for (int i = 0; i < source.links.length; i++) {
      final q = source.links[i].quality.toLowerCase();
      if (q.contains(_preferredQuality.toLowerCase().replaceAll('p', ''))) {
        return i;
      }
    }
    return 0;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = duration.inHours;
    final m = twoDigits(duration.inMinutes.remainder(60));
    final s = twoDigits(duration.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Center(child: _buildVideoPlayer()),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: _buildOverlayControls(),
                  ),
                ),
              ],
            ),
          ),
          if (_showResumeDialog) _buildResumeDialog(),
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
          decoration: BoxDecoration(
            color: NipahColors.surface,
            border: Border.all(color: NipahColors.lineSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, color: NipahColors.gold, size: 48),
              const SizedBox(height: 16),
              Text('${L10n.t('resumeFrom')} $timeStr?', style: NipahTheme.heading(size: 20)),
              const SizedBox(height: 8),
              Text(
                'Episode $_currentEpisode',
                style: NipahTheme.body(size: 13, color: NipahColors.textDim),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _startFromBeginning,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: NipahColors.lineSoft),
                        color: NipahColors.surface2,
                      ),
                      child: Text(L10n.t('startOver'), style: NipahTheme.label(size: 11, color: NipahColors.textDim)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _resumeFromPosition,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [NipahColors.gold, NipahColors.goldStrong],
                        ),
                      ),
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

  Widget _buildVideoPlayer() {
    if (_isInitializing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const NipahLoader(size: 36),
          const SizedBox(height: 16),
          Text(
            '${L10n.t('loading')} ${L10n.t('episode')} $_currentEpisode...',
            style: NipahTheme.body(color: NipahColors.textSoft),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading... ${_loadingSeconds}s  •  Server ${_trySourceIndex + 1}',
            style: NipahTheme.body(size: 12, color: NipahColors.textDim),
          ),
        ],
      );
    }
    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: NipahColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: NipahTheme.body(color: NipahColors.textSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              L10n.t('allFailed'),
              style: NipahTheme.body(size: 12, color: NipahColors.textDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_lastFailedUrl.isNotEmpty)
              GestureDetector(
                onTap: _openInExternalPlayer,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: NipahTheme.goldButtonDecoration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new, color: NipahColors.bg, size: 16),
                      const SizedBox(width: 8),
                      Text('Open in Video Player', style: NipahTheme.label(size: 11, color: NipahColors.bg)),
                    ],
                  ),
                ),
              ),
            if (_lastFailedUrl.isNotEmpty) const SizedBox(height: 12),
            GestureDetector(
              onTap: _loadStream,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: NipahColors.lineSoft),
                ),
                child: Text(L10n.t('retryAll'), style: NipahTheme.label(size: 11, color: NipahColors.textDim)),
              ),
            ),
          ],
        ),
      );
    }
    return Video(
      controller: _videoController,
      controls: NoVideoControls,
    );
  }

  Widget _buildOverlayControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildTopBar(),
          const Spacer(),
          _buildCenterControls(),
          const Spacer(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.animeTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                '${L10n.t('episode')} $_currentEpisode',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_sources.isNotEmpty && _sources.first.server != 'Unavailable')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: NipahColors.gold),
                  ),
                  color: const Color(0x1ad7a35a),
                ),
                child: Text(
                  _getSourceShortName(_sources[_selectedSourceIndex].server),
                  style: NipahTheme.label(size: 9, color: NipahColors.gold),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.dns, color: Colors.white),
              onPressed: _showServerSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return GestureDetector(
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
            onPressed: _seekBackward,
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [NipahColors.gold, NipahColors.goldStrong],
                ),
                boxShadow: [
                  BoxShadow(
                    color: NipahColors.gold.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: NipahColors.bg,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
            onPressed: _seekForward,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: NipahColors.gold,
                  inactiveTrackColor: NipahColors.surface,
                  thumbColor: NipahColors.gold,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 3,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble())
                      : 0.0,
                  max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                  onChanged: (value) {
                    final seekTo = Duration(milliseconds: value.toInt());
                    _player.seek(seekTo);
                    _showControlsBriefly();
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          color: _currentEpisode > 1 ? Colors.white : Colors.grey,
                          size: 28,
                        ),
                        onPressed: _currentEpisode > 1 ? () => _changeEpisode(-1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                        onPressed: () => _changeEpisode(1),
                      ),
                    ],
                  ),
                  Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const String _defaultUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

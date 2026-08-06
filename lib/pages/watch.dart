import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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

  String get _positionKey => '${widget.anilistId}_ep${widget.episode}';

  Duration _lastSavedPosition = Duration.zero;

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
      if (mounted && _isPlaying && position.inSeconds > 2) {
        _lastSavedPosition = position;
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed && mounted) {
        clearPlaybackPosition(_positionKey);
      }
    });

    _init();
  }

  Future<void> _init() async {
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
    setState(() {
      _showResumeDialog = false;
    });
    final target = _savedPosition;
    _savedPosition = Duration.zero;
    _startPositionSaveTimer();
    _player.play();
    if (target.inSeconds > 0) {
      StreamSubscription? sub;
      sub = _player.stream.buffering.listen((buffering) {
        if (!buffering && mounted && target.inSeconds > 0) {
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

      _selectedSourceIndex = 0;
      _selectedLinkIndex = 0;
      await _initializePlayer(sources.first.links.first.url, sources.first);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'Failed to load stream: $e';
      });
    }
  }

  Future<void> _initializePlayer(String url, StreamSource source) async {
    if (url.isEmpty) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'This source is not available.';
      });
      return;
    }

    try {
      await _player.stop();
      final headers = _getHeadersForSource(source);
      await _player.open(
        Media(url, httpHeaders: headers),
      );

      if (_showResumeDialog) {
        await _player.pause();
        setState(() {
          _isInitializing = false;
          _isPlaying = false;
          _showControls = true;
        });
      } else {
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
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
      });
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
    final pos = _player.state.position;
    _player.seek(pos + const Duration(seconds: 10));
    _showControlsBriefly();
  }

  void _seekBackward() {
    final pos = _player.state.position;
    final newPos = pos - const Duration(seconds: 10);
    _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
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
                                    await _initializePlayer(link.url, source);
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
            L10n.t('trying'),
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
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadStream,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [NipahColors.gold, NipahColors.goldStrong],
                  ),
                ),
                child: Text(L10n.t('retryAll'), style: NipahTheme.label(size: 11, color: NipahColors.bg)),
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
                  color: Color(0x1ad7a35a),
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
    final position = _player.state.position;
    final duration = _player.state.duration;

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
                  value: duration.inMilliseconds > 0
                      ? position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble())
                      : 0.0,
                  max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                  onChanged: (value) {
                    _player.seek(Duration(milliseconds: value.toInt()));
                    _showControlsBriefly();
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                  Text(_formatDuration(duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
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

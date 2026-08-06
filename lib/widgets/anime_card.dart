import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models.dart';
import '../theme/nipah_theme.dart';
import '../pages/anime_detail.dart';
import 'nipah_loader.dart';

class AnimeCard extends StatefulWidget {
  final Anime anime;
  final int? rank;
  final bool isNew;

  const AnimeCard({
    super.key,
    required this.anime,
    this.rank,
    this.isNew = false,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool _isHovered = false;
  Timer? _airTimer;
  String _airCountdown = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    if (widget.anime.airingAt != null && widget.anime.airingAt! > 0) {
      _airTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateCountdown());
    }
  }

  @override
  void dispose() {
    _airTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;
    final airAt = widget.anime.airingAt;
    if (airAt == null || airAt <= 0) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = airAt - now;
    if (diff <= 0) {
      setState(() => _airCountdown = 'Airing now');
      return;
    }
    final d = diff ~/ 86400;
    final h = (diff % 86400) ~/ 3600;
    final m = (diff % 3600) ~/ 60;
    String text;
    if (d > 0) {
      text = '${d}d ${h}h';
    } else if (h > 0) {
      text = '${h}h ${m}m';
    } else {
      text = '${m}m';
    }
    setState(() => _airCountdown = text);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: NipahTheme.animSlow,
              pageBuilder: (_, __, ___) => AnimeDetailPage(anime: widget.anime),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        },
        child: AnimatedContainer(
          duration: NipahTheme.animMedium,
          curve: const Cubic(0.22, 1, 0.36, 1),
          transform: _isHovered
              ? (Matrix4.identity()..translateByDouble(0.0, -4.0, 0.0, 1.0)..scaleByDouble(1.02, 1.02, 1.0, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: NipahColors.surface,
            border: Border.fromBorderSide(
              BorderSide(color: NipahColors.cardBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'poster_${widget.anime.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.anime.coverImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: NipahColors.surface2,
                          child: const Center(
                            child: NipahLoader(size: 20),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: NipahColors.surface2,
                          child: Icon(Icons.movie, color: NipahColors.textDim, size: 32),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x4d000000),
                              Color(0xb3000000),
                            ],
                            stops: [0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (widget.rank != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [NipahColors.gold, NipahColors.goldStrong],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${widget.rank}',
                            style: TextStyle(
                              color: NipahColors.bg,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (widget.isNew)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: NipahColors.gold,
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              color: NipahColors.bg,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.08,
                            ),
                          ),
                        ),
                      ),
                    if (_airCountdown.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: widget.isNew ? 42 : 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _airCountdown == 'Airing now' ? NipahColors.success : NipahColors.gold,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 8, color: NipahColors.bg),
                              const SizedBox(width: 3),
                              Text(
                                _airCountdown == 'Airing now' ? 'NOW' : _airCountdown,
                                style: TextStyle(
                                  color: NipahColors.bg,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.anime.episodes > 0)
                      Positioned(
                        top: 6,
                        left: widget.isNew ? 42 : 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(color: NipahColors.line),
                            ),
                            color: Color(0x1ad7a35a),
                          ),
                          child: Text(
                            '${widget.anime.episodes} eps',
                              style: TextStyle(
                              color: NipahColors.goldStrong,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.08,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xcc000000)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.anime.displayTitle,
                              style: TextStyle(
                                color: NipahColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.anime.score > 0) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, color: NipahColors.gold, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.anime.score.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: NipahColors.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

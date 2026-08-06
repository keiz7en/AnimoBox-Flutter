import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';
import '../models.dart';
import '../theme/nipah_theme.dart';
import 'watch.dart';

class AnimeDetailPage extends StatefulWidget {
  final Anime anime;
  const AnimeDetailPage({super.key, required this.anime});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  bool _isExpanded = false;
  bool _isInLibrary = false;
  String _libraryStatus = 'Watching';

  @override
  void initState() {
    super.initState();
    _checkLibrary();
  }

  Future<void> _checkLibrary() async {
    final inLib = await isInLibrary(widget.anime.id);
    if (mounted) setState(() => _isInLibrary = inLib);
  }

  void _showStatusPicker() {
    final statuses = ['Watching', 'Completed', 'On Hold', 'Dropped', 'Plan to Watch'];
    showModalBottomSheet(
      context: context,
      backgroundColor: NipahColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, color: NipahColors.textDim),
              const SizedBox(height: 16),
              Text('Add to Library', style: NipahTheme.heading(size: 18)),
              const SizedBox(height: 16),
              ...statuses.map((status) {
                return ListTile(
                  leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                  title: Text(status, style: NipahTheme.body(color: NipahColors.text)),
                  trailing: _libraryStatus == status
                      ? Icon(Icons.check, color: NipahColors.gold)
                      : null,
                  onTap: () async {
                    setState(() => _libraryStatus = status);
                    await addToLibrary(widget.anime, status: status);
                    setState(() => _isInLibrary = true);
                    if (mounted) Navigator.pop(context);
                  },
                );
              }),
              if (_isInLibrary)
                ListTile(
                  leading: Icon(Icons.delete, color: NipahColors.danger),
                  title: Text('Remove from Library', style: NipahTheme.body(color: NipahColors.danger)),
                  onTap: () async {
                    await removeFromLibrary(widget.anime.id);
                    setState(() => _isInLibrary = false);
                    if (mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Watching': return Icons.play_circle;
      case 'Completed': return Icons.check_circle;
      case 'On Hold': return Icons.pause_circle;
      case 'Dropped': return Icons.cancel;
      case 'Plan to Watch': return Icons.schedule;
      default: return Icons.movie;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Watching': return NipahColors.gold;
      case 'Completed': return NipahColors.success;
      case 'On Hold': return NipahColors.goldStrong;
      case 'Dropped': return NipahColors.danger;
      case 'Plan to Watch': return const Color(0xFF40C4FF);
      default: return NipahColors.textDim;
    }
  }

  int _getEpisodeCount(Anime anime) {
    if (anime.episodes > 0) return anime.episodes;
    if (anime.nextAiringEpisode != null && anime.nextAiringEpisode! > 1) return anime.nextAiringEpisode! + 10;
    if (anime.status == 'RELEASING') return 25;
    return 25;
  }

  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    final bannerUrl = anime.bannerImage.isNotEmpty ? anime.bannerImage : anime.coverImage;

    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                color: const Color(0x8c06070a),
                child: Icon(Icons.arrow_back, color: NipahColors.text),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                color: const Color(0x8c06070a),
                child: IconButton(
                  icon: Icon(
                    _isInLibrary ? Icons.bookmark : Icons.bookmark_border,
                    color: _isInLibrary ? NipahColors.gold : NipahColors.text,
                  ),
                  onPressed: _showStatusPicker,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'anime_${anime.id}',
                    child: CachedNetworkImage(
                      imageUrl: bannerUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: NipahColors.surface,
                        child: Icon(Icons.movie, color: NipahColors.textDim, size: 48),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x2608080a), Color(0xc108080a), NipahColors.bg],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Color(0xfa08080a), Color(0x3808080a), Color(0x1008080a), Color(0x4208080a), Color(0xf908080a)],
                          stops: [0.0, 0.24, 0.54, 0.78, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Hero(
                          tag: 'poster_${anime.id}',
                          child: Container(
                            width: 100, height: 145,
                            decoration: BoxDecoration(
                              boxShadow: const [BoxShadow(color: Color(0x52000000), blurRadius: 44, offset: Offset(0, 24))],
                              image: DecorationImage(image: CachedNetworkImageProvider(anime.coverImage), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(anime.displayTitle, style: NipahTheme.heading(size: 22, height: 0.96), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (anime.romajiTitle != anime.displayTitle && anime.romajiTitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(anime.romajiTitle, style: NipahTheme.body(size: 12, color: NipahColors.textSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBadges(anime),
                  const SizedBox(height: 14),
                  _buildGenreChips(anime),
                  const SizedBox(height: 14),
                  _buildInfoCard(anime),
                  const SizedBox(height: 14),
                  _buildSynopsis(anime),
                  const SizedBox(height: 18),
                  _buildEpisodeSection(anime),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(Anime anime) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        if (anime.format.isNotEmpty) _nipahBadge(text: anime.format.toUpperCase()),
        if (anime.status.isNotEmpty) _nipahBadge(text: anime.status.replaceAll('_', ' '), color: NipahColors.success),
        if (anime.score > 0) _nipahBadge(text: '${anime.score.toStringAsFixed(1)}%', color: NipahColors.gold),
        if (anime.episodes > 0) _nipahBadge(text: '${anime.episodes} eps'),
        if (anime.duration > 0) _nipahBadge(text: '${anime.duration}m'),
      ],
    );
  }

  Widget _nipahBadge({required String text, Color? color}) {
    final badgeColor = color ?? NipahColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
        color: badgeColor.withValues(alpha: 0.12),
      ),
      child: Text(text, style: NipahTheme.label(size: 10, color: badgeColor.withValues(alpha: 0.96))),
    );
  }

  Widget _buildGenreChips(Anime anime) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: anime.genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: NipahColors.chipBg,
            border: Border.fromBorderSide(BorderSide(color: NipahColors.lineSoft)),
          ),
          child: Text(genre, style: NipahTheme.body(size: 12, color: NipahColors.textSoft)),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard(Anime anime) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: NipahTheme.sectionCardDecoration,
      child: Column(
        children: [
          if (anime.season.isNotEmpty) _infoRow('Season', anime.season),
          if (anime.episodes > 0) _infoRow('Episodes', '${anime.episodes}'),
          if (anime.duration > 0) _infoRow('Duration', '${anime.duration} min'),
          if (anime.status.isNotEmpty) _infoRow('Status', anime.status),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
          Text(value, style: NipahTheme.body(size: 14, weight: FontWeight.w600, color: NipahColors.text)),
        ],
      ),
    );
  }

  Widget _buildSynopsis(Anime anime) {
    if (anime.description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synopsis', style: NipahTheme.label(size: 11)),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(anime.description, style: NipahTheme.body(size: 14, height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
          secondChild: Text(anime.description, style: NipahTheme.body(size: 14, height: 1.5)),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: NipahTheme.animMedium,
        ),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(_isExpanded ? 'Show Less' : 'Read More', style: NipahTheme.label(size: 12, letterSpacing: 0.04)),
        ),
      ],
    );
  }

  Widget _buildEpisodeSection(Anime anime) {
    final epCount = _getEpisodeCount(anime);
    int airedCount;
    if (anime.episodes > 0) {
      airedCount = anime.episodes;
    } else if (anime.nextAiringEpisode != null && anime.nextAiringEpisode! > 1) {
      airedCount = anime.nextAiringEpisode! + 10;
    } else {
      airedCount = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(airedCount > 0 ? 'Episodes ($airedCount aired)' : 'Episodes', style: NipahTheme.label(size: 11)),
            if (anime.nextAiringEpisode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: NipahColors.line)),
                  color: Color(0x1ad7a35a),
                ),
                child: Text('EP ${anime.nextAiringEpisode} NEXT', style: NipahTheme.label(size: 10, color: NipahColors.goldStrong)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (epCount <= 30) _buildEpisodeList(anime, epCount) else _buildEpisodeGrid(anime, epCount),
      ],
    );
  }

  Widget _buildEpisodeList(Anime anime, int epCount) {
    return Column(
      children: List.generate(epCount, (index) {
        final epNum = index + 1;
        final isNext = anime.nextAiringEpisode != null && epNum == anime.nextAiringEpisode;
        final isAired = anime.nextAiringEpisode == null || epNum < anime.nextAiringEpisode!;

        return GestureDetector(
          onTap: isNext ? null : () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => WatchPage(animeTitle: anime.searchTitle, episode: epNum, anilistId: anime.id, anime: anime),
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isNext ? NipahColors.gold.withValues(alpha: 0.12) : NipahColors.surface,
              border: Border(bottom: BorderSide(color: NipahColors.lineSoft)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isNext ? NipahColors.gold : isAired ? NipahColors.surface2 : NipahColors.surface3,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$epNum',
                    style: TextStyle(
                      color: isNext ? NipahColors.bg : isAired ? NipahColors.text : NipahColors.textDim,
                      fontSize: 12, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Episode $epNum', style: NipahTheme.body(size: 13, weight: FontWeight.w600, color: isAired ? NipahColors.text : NipahColors.textDim)),
                      const SizedBox(height: 2),
                      Text(
                        isNext ? 'Upcoming' : isAired ? 'Ready to play' : 'Not yet aired',
                        style: NipahTheme.body(size: 11, color: isNext ? NipahColors.gold : NipahColors.textDim),
                      ),
                    ],
                  ),
                ),
                if (!isNext && isAired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [NipahColors.goldGradientStart, NipahColors.goldGradientEnd]),
                    ),
                    child: Text('PLAY', style: NipahTheme.label(size: 10, color: NipahColors.bg, letterSpacing: 0.06)),
                  ),
                if (isNext)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(border: Border.fromBorderSide(BorderSide(color: NipahColors.gold))),
                    child: Text('UPCOMING', style: NipahTheme.label(size: 9, color: NipahColors.gold)),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEpisodeGrid(Anime anime, int epCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: epCount,
      itemBuilder: (context, index) {
        final epNum = index + 1;
        final isNext = anime.nextAiringEpisode != null && epNum == anime.nextAiringEpisode;
        final isAired = anime.nextAiringEpisode == null || epNum < anime.nextAiringEpisode!;

        return GestureDetector(
          onTap: isNext ? null : () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => WatchPage(animeTitle: anime.searchTitle, episode: epNum, anilistId: anime.id, anime: anime),
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              color: isNext ? NipahColors.gold : !isAired ? NipahColors.surface : NipahColors.surface2,
              border: isNext ? null : Border.fromBorderSide(BorderSide(color: NipahColors.lineSoft)),
            ),
            alignment: Alignment.center,
            child: Text('$epNum', style: TextStyle(
              color: isNext ? NipahColors.bg : !isAired ? NipahColors.textDim : NipahColors.text,
              fontSize: 12, fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
            )),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../drama_api.dart';
import '../models.dart';
import '../theme/nipah_theme.dart';
import '../widgets/nipah_loader.dart';
import 'drama_watch.dart';

class DramaDetailPage extends StatefulWidget {
  final Drama drama;
  const DramaDetailPage({super.key, required this.drama});

  @override
  State<DramaDetailPage> createState() => _DramaDetailPageState();
}

class _DramaDetailPageState extends State<DramaDetailPage> {
  DramaEpisodeData? _episodeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final epData = await getDramaEpisodes(widget.drama.id);
    if (mounted) {
      setState(() {
        _episodeData = epData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drama = widget.drama;

    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: NipahColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: drama.backdrop.isNotEmpty ? drama.backdrop : drama.poster,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: NipahColors.surface),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xf708090b)],
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (drama.poster.isNotEmpty)
                        Container(
                          width: 80,
                          height: 120,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(drama.poster),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(drama.title, style: NipahTheme.heading(size: 22)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (drama.country.isNotEmpty)
                                  _InfoChip(label: drama.country),
                                if (drama.status.isNotEmpty)
                                  _InfoChip(label: drama.status),
                                if (drama.rating > 0)
                                  _InfoChip(label: '${drama.rating}'),
                                if (drama.year.isNotEmpty)
                                  _InfoChip(label: drama.year),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (drama.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(drama.description, style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
                  ],
                  if (drama.genres.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: drama.genres.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: NipahColors.lineSoft),
                        ),
                        child: Text(g, style: NipahTheme.label(size: 10, color: NipahColors.gold)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: NipahLoader(size: 28))
                  else if (_episodeData != null && _episodeData!.episodes.isNotEmpty)
                    _buildEpisodeList()
                  else
                    Center(
                      child: Text('No episodes available', style: NipahTheme.body(size: 14, color: NipahColors.textDim)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeList() {
    final episodes = _episodeData!.episodes;
    final useGrid = episodes.length > 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Episodes (${episodes.length})', style: NipahTheme.heading(size: 16)),
        const SizedBox(height: 12),
        if (useGrid)
          _buildGrid(episodes)
        else
          _buildList(episodes),
      ],
    );
  }

  Widget _buildGrid(List<DramaEpisode> episodes) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 600 ? 8 : (width > 400 ? 6 : 5);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final ep = episodes[index];
        return GestureDetector(
          onTap: () => _playEpisode(ep.number),
          child: Container(
            decoration: BoxDecoration(
              color: NipahColors.surface2,
              border: Border.all(color: NipahColors.lineSoft),
            ),
            child: Center(
              child: Text(
                '${ep.number}',
                style: NipahTheme.heading(size: 16, color: NipahColors.gold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<DramaEpisode> episodes) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: episodes.length,
      separatorBuilder: (_, __) => Container(height: 1, color: NipahColors.lineSoft),
      itemBuilder: (context, index) {
        final ep = episodes[index];
        return GestureDetector(
          onTap: () => _playEpisode(ep.number),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            color: NipahColors.surface,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [NipahColors.gold, NipahColors.goldStrong],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${ep.number}',
                      style: NipahTheme.label(size: 11, color: NipahColors.bg),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Episode ${ep.number}',
                    style: NipahTheme.body(size: 14, color: NipahColors.text),
                  ),
                ),
                Icon(Icons.play_circle_outline, color: NipahColors.gold, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playEpisode(int number) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DramaWatchPage(
          title: widget.drama.title,
          episode: number,
          mediaId: widget.drama.id,
          episodes: _episodeData!.episodes,
          coverImage: widget.drama.poster,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: NipahColors.lineSoft),
      ),
      child: Text(label, style: NipahTheme.label(size: 9, color: NipahColors.textDim)),
    );
  }
}

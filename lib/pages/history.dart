import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';
import '../theme/nipah_theme.dart';
import '../widgets/nipah_loader.dart';
import 'anime_detail.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAnime(int animeId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: NipahLoader(size: 32)),
    );
    final details = await getAnimeDetailsById(animeId.toString());
    if (mounted) Navigator.pop(context);
    if (details != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AnimeDetailPage(anime: details)));
    }
  }

  String _timeAgo(int millis) {
    final diff = DateTime.now().millisecondsSinceEpoch - millis;
    if (diff < 60000) return 'Just now';
    if (diff < 3600000) return '${(diff / 60000).floor()}m ago';
    if (diff < 86400000) return '${(diff / 3600000).floor()}h ago';
    if (diff < 604800000) return '${(diff / 86400000).floor()}d ago';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _history.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Watch History', style: NipahTheme.heading(size: 28)),
          const Spacer(),
          if (_history.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: NipahColors.gold),
                ),
                color: Color(0x1ad7a35a),
              ),
              child: Text(
                '${_history.length} episodes',
                style: NipahTheme.label(size: 10, color: NipahColors.goldStrong),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: NipahLoader(size: 28),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: NipahColors.textDim),
          const SizedBox(height: 16),
          Text(
            'No watch history yet',
            style: NipahTheme.body(size: 14, color: NipahColors.textDim),
          ),
          const SizedBox(height: 8),
          Text(
            'Start watching anime to build your history',
            style: NipahTheme.body(size: 12, color: NipahColors.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return _NipahHistoryItem(
          item: item,
          timeAgo: _timeAgo(item['watchedAt'] ?? 0),
          onTap: () => _navigateToAnime(item['anilistId'] ?? 0),
          onDelete: () async {
            await removeFromHistory(index);
            _loadHistory();
          },
        );
      },
    );
  }
}

class _NipahHistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NipahHistoryItem({
    required this.item,
    required this.timeAgo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('history_${item['animeTitle']}_${item['episode']}_$timeAgo'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: NipahColors.danger,
        ),
        child: Icon(Icons.delete, color: NipahColors.text),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: NipahTheme.cardDecoration,
          child: Row(
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item['coverImage'] ?? '',
                    width: 70,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 70,
                      height: 100,
                      color: NipahColors.surface,
                      child: Icon(Icons.movie, color: NipahColors.textDim),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: NipahColors.bg,
                      child: Text(
                        'EP ${item['episode'] ?? '?'}',
                        style: NipahTheme.label(size: 9, color: NipahColors.gold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['animeTitle'] ?? '',
                      style: NipahTheme.body(size: 14, weight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Episode ${item['episode'] ?? '?'}',
                      style: NipahTheme.body(size: 12, color: NipahColors.textDim),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: NipahColors.textDim),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: NipahTheme.body(size: 11, color: NipahColors.textDim),
                        ),
                        if (item['server'] != null && item['server'].toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.fromBorderSide(
                                BorderSide(color: NipahColors.lineSoft),
                              ),
                            ),
                            child: Text(
                              item['server'],
                              style: NipahTheme.label(size: 9, color: NipahColors.gold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 24),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

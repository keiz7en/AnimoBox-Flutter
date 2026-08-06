import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';
import '../theme/nipah_theme.dart';
import '../widgets/nipah_loader.dart';
import 'anime_detail.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _library = [];
  Map<String, int> _counts = {};
  bool _isLoading = true;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    final library = await getLibrary();
    final counts = await getLibraryCounts();
    if (mounted) {
      setState(() {
        _library = library;
        _counts = counts;
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load anime details', style: NipahTheme.body(size: 13)),
          backgroundColor: NipahColors.surface,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredLibrary {
    if (_selectedStatus == 'All') return _library;
    return _library.where((item) => item['status'] == _selectedStatus).toList();
  }

  void _showStatusPicker(Map<String, dynamic> item) {
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
              Container(
                width: 40,
                height: 4,
                color: NipahColors.textDim,
              ),
              const SizedBox(height: 16),
              Text('Change Status', style: NipahTheme.heading(size: 18)),
              const SizedBox(height: 16),
              ...statuses.map((status) {
                final isSelected = item['status'] == status;
                return ListTile(
                  leading: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                  title: Text(status, style: NipahTheme.body(
                    color: isSelected ? NipahColors.gold : NipahColors.text,
                  )),
                  trailing: isSelected ? Icon(Icons.check, color: NipahColors.gold) : null,
                  onTap: () async {
                    await updateLibraryStatus(item['id'], status);
                    setState(() => item['status'] = status);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadLibrary();
                    }
                  },
                );
              }),
              ListTile(
                leading: Icon(Icons.delete, color: NipahColors.danger),
                title: Text('Remove from Library', style: NipahTheme.body(color: NipahColors.danger)),
                onTap: () async {
                  await removeFromLibrary(item['id']);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadLibrary();
                  }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusTabs(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredLibrary.isEmpty
                      ? _buildEmptyState()
                      : _buildLibraryList(),
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
          Text('My Library', style: NipahTheme.heading(size: 28)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: NipahColors.gold),
              ),
              color: Color(0x1ad7a35a),
            ),
            child: Text(
              '${_library.length} anime',
              style: NipahTheme.label(size: 10, color: NipahColors.goldStrong),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    final statuses = ['All', 'Watching', 'Completed', 'On Hold', 'Dropped', 'Plan to Watch'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;
          final count = status == 'All' ? _library.length : (_counts[status] ?? 0);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [NipahColors.gold, NipahColors.goldStrong])
                      : null,
                  color: isSelected ? null : NipahColors.surface,
                  border: isSelected
                      ? null
                      : Border.fromBorderSide(
                          BorderSide(color: NipahColors.lineSoft),
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status,
                      style: NipahTheme.label(
                        size: 10,
                        color: isSelected ? NipahColors.bg : NipahColors.textDim,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? NipahColors.bg.withValues(alpha: 0.2)
                              : NipahColors.lineSoft,
                        ),
                        child: Text(
                          '$count',
                          style: NipahTheme.label(
                            size: 9,
                            color: isSelected ? NipahColors.bg : NipahColors.textDim,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: NipahLoader(size: 28),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: NipahColors.textDim),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == 'All'
                ? 'Your library is empty'
                : 'No anime in this category',
            style: NipahTheme.body(size: 14, color: NipahColors.textDim),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse and add anime to your library',
            style: NipahTheme.body(size: 12, color: NipahColors.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _filteredLibrary.length,
      itemBuilder: (context, index) {
        final item = _filteredLibrary[index];
        return _NipahLibraryItem(
          item: item,
          onTap: () => _navigateToAnime(item['id']),
          onStatusChange: () => _showStatusPicker(item),
          onDelete: () async {
            await removeFromLibrary(item['id']);
            _loadLibrary();
          },
          getStatusColor: _getStatusColor,
          getStatusIcon: _getStatusIcon,
        );
      },
    );
  }
}

class _NipahLibraryItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onStatusChange;
  final VoidCallback onDelete;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;

  const _NipahLibraryItem({
    required this.item,
    required this.onTap,
    required this.onStatusChange,
    required this.onDelete,
    required this.getStatusColor,
    required this.getStatusIcon,
  });

  @override
  State<_NipahLibraryItem> createState() => _NipahLibraryItemState();
}

class _NipahLibraryItemState extends State<_NipahLibraryItem> {
  @override
  Widget build(BuildContext context) {
    final status = widget.item['status'] ?? 'Watching';
    return Dismissible(
      key: Key('${widget.item['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
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
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: NipahTheme.cardDecoration,
          child: Row(
            children: [
              CachedNetworkImage(
                imageUrl: widget.item['coverImage'] ?? '',
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item['title'] ?? '',
                      style: NipahTheme.body(size: 14, weight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onStatusChange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.getStatusColor(status).withValues(alpha: 0.18),
                          border: Border.all(
                            color: widget.getStatusColor(status).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.getStatusIcon(status), size: 12, color: widget.getStatusColor(status)),
                            const SizedBox(width: 4),
                            Text(status, style: NipahTheme.label(
                              size: 10,
                              color: widget.getStatusColor(status),
                            )),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down, size: 14, color: widget.getStatusColor(status)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 24),
                onPressed: widget.onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

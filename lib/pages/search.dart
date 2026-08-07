import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';
import '../drama_api.dart';
import '../models.dart';
import '../theme/nipah_theme.dart';
import '../widgets/anime_card.dart';
import 'drama_detail.dart';
import 'settings.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Anime> _searchResults = [];
  List<Anime> _topAnime = [];
  List<Anime> _scheduleAnime = [];
  List<String> _genres = [];
  bool _isSearching = false;
  bool _isLoadingTop = false;
  bool _isLoadingSchedule = false;
  bool _isLoadingGenres = false;
  int _searchPage = 1;
  int _topPage = 1;
  String _topSort = 'SCORE_DESC';
  bool _hasMoreSearch = true;
  bool _hasMoreTop = true;
  String _appMode = 'anime';
  List<Drama> _dramaResults = [];

  final _quickSearches = ['Naruto', 'One Piece', 'Attack on Titan', 'Demon Slayer', 'Jujutsu Kaisen', 'Chainsaw Man'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_tabController.index == 0 && _hasMoreSearch && !_isSearching) {
        _loadMoreSearch();
      } else if (_tabController.index == 1 && _hasMoreTop && !_isLoadingTop) {
        _loadMoreTop();
      }
    }
  }

  void _onTabChanged() {
    if (_tabController.index == 2 && _scheduleAnime.isEmpty && !_isLoadingSchedule) {
      _loadSchedule();
    }
  }

  Future<void> _loadInitialData() async {
    final mode = await getAppMode();
    setState(() {
      _appMode = mode;
      _isLoadingGenres = true;
      _isLoadingTop = true;
    });
    final genres = await getGenreList();
    final top = await getTopAnime(page: _topPage);
    if (mounted) {
      setState(() {
        _genres = genres;
        _topAnime = top;
        _isLoadingGenres = false;
        _isLoadingTop = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
      _dramaResults = [];
      _searchPage = 1;
      _hasMoreSearch = true;
    });
    if (_appMode == 'drama') {
      final results = await searchDramas(query);
      if (mounted) {
        setState(() {
          _dramaResults = results;
          _isSearching = false;
          _hasMoreSearch = false;
        });
      }
    } else {
      final results = await searchAnime(query, page: _searchPage);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasMoreSearch = results.length >= 50;
        });
      }
    }
  }

  Future<void> _loadMoreSearch() async {
    _searchPage++;
    final results = await searchAnime(_searchController.text, page: _searchPage);
    if (mounted) {
      setState(() {
        _searchResults.addAll(results);
        _hasMoreSearch = results.length >= 50;
      });
    }
  }

  Future<void> _loadMoreTop() async {
    _topPage++;
    setState(() => _isLoadingTop = true);
    final results = await getTopAnime(page: _topPage, sort: _topSort);
    if (mounted) {
      setState(() {
        _topAnime.addAll(results);
        _hasMoreTop = results.length >= 50;
        _isLoadingTop = false;
      });
    }
  }

  void _changeTopSort(String sort) {
    setState(() {
      _topSort = sort;
      _topAnime = [];
      _topPage = 1;
      _hasMoreTop = true;
    });
    _loadMoreTop();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoadingSchedule = true);
    final schedule = await getAiringSchedule();
    if (mounted) {
      setState(() {
        _scheduleAnime = schedule;
        _isLoadingSchedule = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchResults(),
                  _buildTopAnime(),
                  _buildSchedule(),
                  _buildGenreGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        style: NipahTheme.body(size: 14),
        decoration: InputDecoration(
          hintText: L10n.t('search'),
          hintStyle: NipahTheme.body(size: 13, color: NipahColors.textDim),
          prefixIcon: Icon(Icons.search, color: NipahColors.textDim),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: NipahColors.textDim),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                )
              : null,
          filled: true,
          fillColor: NipahColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: NipahColors.lineSoft),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: NipahColors.lineSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: NipahColors.gold, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty) _performSearch(value);
        },
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NipahColors.lineSoft),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: NipahColors.gold,
        labelColor: NipahColors.gold,
        unselectedLabelColor: NipahColors.textDim,
        labelStyle: NipahTheme.label(size: 11),
        unselectedLabelStyle: NipahTheme.label(size: 11),
        tabs: [
          Tab(text: L10n.t('search').toUpperCase()),
          Tab(text: L10n.t('top').toUpperCase()),
          Tab(text: L10n.t('schedule').toUpperCase()),
          Tab(text: L10n.t('genres').toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return _buildShimmerGrid();
    }
    if (_appMode == 'drama') {
      return _buildDramaSearchResults();
    }
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: NipahColors.textDim),
            const SizedBox(height: 16),
            Text(L10n.t('noHistoryYet'), style: NipahTheme.body(color: NipahColors.textDim)),
          ],
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(L10n.t('quickSearch'), style: NipahTheme.label(size: 11)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickSearches.map((query) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NipahColors.chipBg,
                      border: Border.fromBorderSide(
                        BorderSide(color: NipahColors.lineSoft),
                      ),
                    ),
                    child: Text(query, style: NipahTheme.body(size: 12, color: NipahColors.textSoft)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => AnimeCard(anime: _searchResults[index]),
    );
  }

  Widget _buildDramaSearchResults() {
    if (_dramaResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: NipahColors.textDim),
            const SizedBox(height: 16),
            Text('No dramas found', style: NipahTheme.body(color: NipahColors.textDim)),
          ],
        ),
      );
    }
    if (_dramaResults.isEmpty) {
      final dramaQuickSearches = ['Crash Landing', 'Squid Game', 'Boys Over Flowers', 'Goblin', 'Descendants of the Sun', 'Vincenzo'];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Quick Search', style: NipahTheme.label(size: 11)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dramaQuickSearches.map((query) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NipahColors.chipBg,
                      border: Border.fromBorderSide(
                        BorderSide(color: NipahColors.lineSoft),
                      ),
                    ),
                    child: Text(query, style: NipahTheme.body(size: 12, color: NipahColors.textSoft)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _dramaResults.length,
      itemBuilder: (context, index) {
        final drama = _dramaResults[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DramaDetailPage(drama: drama)),
            );
          },
          child: Container(
            decoration: NipahTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: drama.poster.isNotEmpty ? drama.poster : drama.backdrop,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: NipahColors.surface,
                          child: Icon(Icons.tv, color: NipahColors.textDim),
                        ),
                      ),
                      if (drama.episodes > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: NipahColors.bg,
                            child: Text(
                              'EP ${drama.episodes}',
                              style: NipahTheme.label(size: 9, color: NipahColors.gold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    drama.title,
                    style: NipahTheme.body(size: 11, weight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAnime() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _sortChip('Popular', 'POPULARITY_DESC'),
                _sortChip('Top Rated', 'SCORE_DESC'),
                _sortChip('Trending', 'TRENDING_DESC'),
                _sortChip('Newest', 'START_DATE_DESC'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoadingTop && _topAnime.isEmpty
              ? _buildShimmerGrid()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _topAnime.length,
                  itemBuilder: (context, index) => AnimeCard(
                    anime: _topAnime[index],
                    rank: index + 1,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _sortChip(String label, String sort) {
    final isSelected = _topSort == sort;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _changeTopSort(sort),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? NipahColors.gold.withValues(alpha: 0.18) : NipahColors.surface,
            border: Border.all(
              color: isSelected ? NipahColors.gold : NipahColors.lineSoft,
            ),
          ),
          child: Text(
            label,
            style: NipahTheme.label(
              size: 10,
              color: isSelected ? NipahColors.gold : NipahColors.textDim,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchedule() {
    if (_isLoadingSchedule) return _buildShimmerGrid();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _scheduleAnime.length,
      itemBuilder: (context, index) => AnimeCard(anime: _scheduleAnime[index]),
    );
  }

  Widget _buildGenreGrid() {
    if (_isLoadingGenres) return _buildShimmerGrid();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _genres.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _searchController.text = _genres[index];
            _performSearch(_genres[index]);
            _tabController.animateTo(0);
          },
          child: Container(
            decoration: BoxDecoration(
              color: NipahColors.surface,
              border: Border.fromBorderSide(
                BorderSide(color: NipahColors.lineSoft),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _genres[index],
              style: NipahTheme.body(size: 12, color: NipahColors.textSoft),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return _NipahShimmerCard(delay: index * 100);
      },
    );
  }
}

class _NipahShimmerCard extends StatefulWidget {
  final int delay;
  const _NipahShimmerCard({this.delay = 0});

  @override
  State<_NipahShimmerCard> createState() => _NipahShimmerCardState();
}

class _NipahShimmerCardState extends State<_NipahShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Color.lerp(NipahColors.surface, NipahColors.surface2, _animation.value),
          ),
        );
      },
    );
  }
}

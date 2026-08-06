import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';
import '../models.dart';
import '../theme/nipah_theme.dart';
import '../widgets/anime_card.dart';
import 'anime_detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, List<Anime>> _tabData = {};
  final Map<int, bool> _tabLoading = {};
  final Map<int, bool> _tabLoaded = {};

  // Hero carousel
  List<Anime> _heroAnime = [];
  int _heroIndex = 0;
  Timer? _heroTimer;
  late final PageController _heroPageController;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadTab(_tabController.index);
    });
    _loadTab(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int index) async {
    if (_tabLoaded[index] == true) return;
    setState(() => _tabLoading[index] = true);
    try {
      List<Anime> data;
      switch (index) {
        case 0:
          data = await getAiringSchedule();
          break;
        case 1:
          data = await getTopAnime();
          break;
        case 2:
          data = await getRecentEpisodes();
          break;
        default:
          data = [];
      }
      if (mounted) {
        setState(() {
          _tabData[index] = data;
          _tabLoading[index] = false;
          _tabLoaded[index] = true;
          if (index == 0 && data.isNotEmpty && _heroAnime.isEmpty) {
            _heroAnime = data.take(5).toList();
            _startHeroTimer();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tabLoading[index] = false;
          _tabLoaded[index] = true;
        });
      }
    }
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && _heroAnime.isNotEmpty) {
        final next = (_heroIndex + 1) % _heroAnime.length;
        _heroPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onHeroPageChanged(int index) {
    setState(() => _heroIndex = index);
  }

  Future<void> _onRefresh() async {
    _tabLoaded.clear();
    _heroAnime = [];
    _heroIndex = 0;
    await _loadTab(_tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: NipahColors.gold,
          backgroundColor: NipahColors.surface,
          child: CustomScrollView(
            slivers: [
              if (_tabController.index == 0) ...[
                SliverToBoxAdapter(child: _buildHeroSection()),
              ],
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverToBoxAdapter(child: _buildSectionHeader()),
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(0),
                    _buildTabContent(1),
                    _buildTabContent(2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    if (_heroAnime.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 420,
      width: double.infinity,
      child: PageView.builder(
        controller: _heroPageController,
        itemCount: _heroAnime.length,
        onPageChanged: _onHeroPageChanged,
        itemBuilder: (context, index) {
          return _buildHeroItem(_heroAnime[index]);
        },
      ),
    );
  }

  Widget _buildHeroItem(Anime anime) {
    final titleLen = anime.displayTitle.length;

    return SizedBox(
      height: 420,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: anime.bannerImage.isNotEmpty ? anime.bannerImage : anime.coverImage,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              color: NipahColors.surface,
              child: Icon(Icons.movie, color: NipahColors.textDim, size: 64),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Color(0xfc06070a),
                    Color(0x7008090b),
                    Color(0x1f08090b),
                    Color(0xd108090b),
                    Color(0xfa06070a),
                  ],
                  stops: [0.0, 0.24, 0.54, 0.78, 1.0],
                ),
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
                    Color(0x1f050609),
                    Color(0x0f050609),
                    Color(0x2308090b),
                    Color(0xae08090b),
                    Color(0xf708090b),
                  ],
                  stops: [0.0, 0.12, 0.30, 0.74, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (anime.coverImage.isNotEmpty)
                  Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x52000000),
                          blurRadius: 44,
                          offset: Offset(0, 24),
                        ),
                      ],
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(anime.coverImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (anime.genres.isNotEmpty)
                            _HeroChip(text: anime.genres.first),
                          if (anime.format.isNotEmpty)
                            _HeroChip(text: anime.format),
                          if (anime.score > 0)
                            _HeroChip(text: '${anime.score.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        anime.displayTitle,
                        style: NipahTheme.heading(
                          size: titleLen > 28 ? 24 : titleLen > 18 ? 28 : 34,
                          height: 0.94,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnimeDetailPage(anime: anime),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: NipahTheme.goldButtonDecoration,
                          child: Text(
                            'WATCH NOW',
                            style: NipahTheme.label(
                              size: 12,
                              color: NipahColors.bg,
                              letterSpacing: 0.04,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (anime.description.isNotEmpty)
                        Text(
                          anime.description,
                          style: NipahTheme.body(size: 13, color: const Color(0xd1f3efe8)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_heroAnime.length > 1)
            Positioned(
              left: 16,
              bottom: 28,
              child: Row(
                children: List.generate(_heroAnime.length, (i) {
                  return Container(
                    width: i == _heroIndex ? 24 : 12,
                    height: 4,
                    margin: const EdgeInsets.only(right: 8),
                    color: i == _heroIndex
                        ? NipahColors.gold
                        : const Color(0x42ffffff),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: NipahColors.lineSoft)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: NipahColors.gold,
        indicatorWeight: 2,
        labelColor: NipahColors.goldStrong,
        unselectedLabelColor: NipahColors.textDim,
        labelStyle: NipahTheme.label(size: 12, letterSpacing: 0.12),
        unselectedLabelStyle: NipahTheme.label(
          size: 12,
          color: NipahColors.textDim,
          letterSpacing: 0.12,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: const [
          Tab(text: 'SCHEDULE'),
          Tab(text: 'TOP'),
          Tab(text: 'LATEST'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    final labels = ['Airing Schedule', 'Top Rated', 'Recently Updated'];
    final sublabels = [
      'Currently airing anime',
      'Highest rated anime series',
      'Freshly updated anime episodes',
    ];
    final idx = _tabController.index;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labels[idx], style: NipahTheme.label(size: 11)),
          const SizedBox(height: 2),
          Text(sublabels[idx], style: NipahTheme.body(size: 12, color: NipahColors.textDim)),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index) {
    final isLoading = _tabLoading[index] ?? true;
    final data = _tabData[index] ?? [];

    if (isLoading) return _buildShimmerGrid();

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter, size: 56, color: NipahColors.textDim),
            const SizedBox(height: 12),
            Text('No anime found', style: NipahTheme.body(size: 15, color: NipahColors.textDim)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() => _tabLoaded[index] = false);
                _loadTab(index);
              },
              child: Text('Retry', style: NipahTheme.label(size: 12)),
            ),
          ],
        ),
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
      itemCount: data.length,
      itemBuilder: (context, index2) {
        return AnimeCard(
          anime: data[index2],
          rank: _tabController.index == 1 ? index2 + 1 : null,
          isNew: _tabController.index == 0 && index2 < 5,
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
      itemCount: 12,
      itemBuilder: (context, index) => _NipahShimmer(delay: index * 80),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  const _HeroChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: NipahTheme.body(
        size: 11,
        weight: FontWeight.w700,
        color: NipahColors.textSoft,
      ),
    );
  }
}

class _NipahShimmer extends StatefulWidget {
  final int delay;
  const _NipahShimmer({this.delay = 0});

  @override
  State<_NipahShimmer> createState() => _NipahShimmerState();
}

class _NipahShimmerState extends State<_NipahShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.04, end: 0.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
            color: Color.lerp(
              NipahColors.surface2,
              NipahColors.surface3,
              _animation.value,
            ),
          ),
        );
      },
    );
  }
}

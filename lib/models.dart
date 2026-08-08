class Anime {
  final int id;
  final String title;
  final String englishTitle;
  final String romajiTitle;
  final String coverImage;
  final String bannerImage;
  final String description;
  final String format;
  final String status;
  final int episodes;
  final int duration;
  final double score;
  final List<String> genres;
  final String season;
  final int? nextAiringEpisode;
  final int? airingAt;
  final int? airingInterval;
  final bool isAdult;
  final List<String> synonyms;

  Anime({
    required this.id,
    required this.title,
    this.englishTitle = '',
    this.romajiTitle = '',
    required this.coverImage,
    this.bannerImage = '',
    this.description = '',
    this.format = '',
    this.status = '',
    this.episodes = 0,
    this.duration = 0,
    this.score = 0,
    this.genres = const [],
    this.season = '',
    this.nextAiringEpisode,
    this.airingAt,
    this.airingInterval,
    this.isAdult = false,
    this.synonyms = const [],
  });

  factory Anime.fromAniList(Map<String, dynamic> json) {
    final titleObj = json['title'] ?? {};
    final coverObj = json['coverImage'] ?? {};
    final bannerObj = json['bannerImage'] ?? {};

    int? nextEp;
    int? airAt;
    int? interval;

    final nextAiring = json['nextAiringEpisode'];
    if (nextAiring is Map<String, dynamic>) {
      nextEp = nextAiring['episode'] as int?;
      airAt = nextAiring['airingAt'] as int?;
    }

    return Anime(
      id: json['id'] ?? 0,
      title: titleObj['native'] ?? titleObj['romaji'] ?? '',
      englishTitle: titleObj['english'] ?? '',
      romajiTitle: titleObj['romaji'] ?? '',
      coverImage: coverObj['large'] ?? coverObj['medium'] ?? '',
      bannerImage: bannerObj is String ? bannerObj : (bannerObj['large'] ?? ''),
      description: (json['description'] ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
      format: (json['format'] ?? '').toString().replaceAll('_', ' '),
      status: json['status'] ?? '',
      episodes: json['episodes'] ?? 0,
      duration: json['duration'] ?? 0,
      score: (json['averageScore'] ?? 0).toDouble(),
      genres: List<String>.from(json['genres'] ?? []),
      season: json['season'] ?? '',
      nextAiringEpisode: nextEp,
      airingAt: airAt,
      airingInterval: interval,
      isAdult: json['isAdult'] ?? false,
      synonyms: List<String>.from(json['synonyms'] ?? []),
    );
  }

  String get displayTitle {
    if (englishTitle.isNotEmpty) return englishTitle;
    if (romajiTitle.isNotEmpty) return romajiTitle;
    return title;
  }

  String get searchTitle {
    if (englishTitle.isNotEmpty) return englishTitle;
    return romajiTitle.isNotEmpty ? romajiTitle : title;
  }

  List<String> get allTitles {
    final titles = <String>{};
    if (englishTitle.isNotEmpty) titles.add(englishTitle);
    if (romajiTitle.isNotEmpty) titles.add(romajiTitle);
    if (title.isNotEmpty) titles.add(title);
    titles.addAll(synonyms);
    return titles.toList();
  }
}

class Episode {
  final int number;
  final String title;
  final String? thumbnail;
  final String? description;
  final int? airingAt;

  Episode({
    required this.number,
    this.title = '',
    this.thumbnail,
    this.description,
    this.airingAt,
  });
}

class StreamServer {
  final String name;
  final String? subUrl;
  final String? dubUrl;

  StreamServer({required this.name, this.subUrl, this.dubUrl});
}

class StreamLink {
  final String url;
  final String quality;

  StreamLink({required this.url, this.quality = 'auto'});
}

class StreamSource {
  final String server;
  final String type;
  final List<StreamLink> links;

  StreamSource({required this.server, required this.type, required this.links});
}

class SearchResult {
  final String id;
  final String title;
  final String source;

  SearchResult({required this.id, required this.title, required this.source});
}

class Drama {
  final int id;
  final String title;
  final String slug;
  final String poster;
  final String backdrop;
  final int episodes;
  final String country;
  final String status;
  final double rating;
  final List<String> genres;
  final String description;
  final String duration;
  final String year;
  final int serverEpisodesCount;
  final int createdAt;

  Drama({
    required this.id,
    required this.title,
    this.slug = '',
    this.poster = '',
    this.backdrop = '',
    this.episodes = 0,
    this.country = '',
    this.status = '',
    this.rating = 0,
    this.genres = const [],
    this.description = '',
    this.duration = '',
    this.year = '',
    this.serverEpisodesCount = 0,
    this.createdAt = 0,
  });

  bool get isHollywood {
    final c = country.toLowerCase();
    return c.contains('united states') || c.contains('united kingdom') ||
        c.contains('american') || c.contains('usa') || c.contains('uk');
  }

  bool get isOngoing {
    if (status.toLowerCase() == 'ongoing') return true;
    final epCount = serverEpisodesCount > 0 ? serverEpisodesCount : episodes;
    if (epCount <= 1) return false;
    if (createdAt <= 0) return epCount > 1;
    final now = DateTime.now().millisecondsSinceEpoch;
    const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    return (now - createdAt) < thirtyDaysMs;
  }

  factory Drama.fromKissAsian(Map<String, dynamic> json) {
    return Drama(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      poster: json['poster'] ?? '',
      backdrop: json['backdrop'] ?? '',
      episodes: json['episodes'] ?? json['serverEpisodesCount'] ?? 0,
      country: json['country'] ?? '',
      status: json['status'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      genres: List<String>.from(json['genres'] ?? []),
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      year: json['year'] ?? '',
      serverEpisodesCount: json['serverEpisodesCount'] ?? 0,
      createdAt: json['createdAt'] ?? 0,
    );
  }

  String get displayTitle => title;
  String get imageUrl => poster.isNotEmpty ? poster : backdrop;
}

class DramaDetail extends Drama {
  @override
  final int serverEpisodesCount;

  DramaDetail({
    required super.id,
    required super.title,
    super.slug,
    super.poster,
    super.backdrop,
    super.episodes,
    super.country,
    super.status,
    super.rating,
    super.genres,
    super.description,
    super.duration,
    super.year,
    this.serverEpisodesCount = 0,
  });

  factory DramaDetail.fromKissAsian(Map<String, dynamic> json) {
    return DramaDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      poster: json['poster'] ?? '',
      backdrop: json['backdrop'] ?? '',
      episodes: json['episodes'] ?? 0,
      country: json['country'] ?? '',
      status: json['status'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      genres: List<String>.from(json['genres'] ?? []),
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      year: json['year'] ?? '',
      serverEpisodesCount: json['serverEpisodesCount'] ?? 0,
    );
  }
}

class DramaEpisodeData {
  final List<DramaEpisode> episodes;
  final List<DramaServer> servers;

  DramaEpisodeData({required this.episodes, required this.servers});

  factory DramaEpisodeData.fromJson(Map<String, dynamic> json) {
    final eps = (json['episodes'] as List? ?? []).map((e) => DramaEpisode.fromJson(e)).toList();
    final srvs = (json['servers'] as List? ?? []).map((s) => DramaServer.fromJson(s)).toList();
    return DramaEpisodeData(episodes: eps, servers: srvs);
  }
}

class DramaEpisode {
  final int id;
  final int number;
  final String title;
  final String duration;
  final String thumbnail;
  final String airDate;
  final String videoUrl;

  DramaEpisode({
    required this.id,
    required this.number,
    this.title = '',
    this.duration = '',
    this.thumbnail = '',
    this.airDate = '',
    this.videoUrl = '',
  });

  factory DramaEpisode.fromJson(Map<String, dynamic> json) {
    return DramaEpisode(
      id: json['id'] ?? 0,
      number: json['number'] ?? 0,
      title: json['title'] ?? '',
      duration: json['duration'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      airDate: json['airDate'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
    );
  }
}

class DramaServer {
  final String name;
  final List<DramaServerEpisode> episodes;

  DramaServer({required this.name, required this.episodes});

  factory DramaServer.fromJson(Map<String, dynamic> json) {
    final eps = (json['episodes'] as List? ?? []).map((e) => DramaServerEpisode.fromJson(e)).toList();
    return DramaServer(name: json['name'] ?? 'Server', episodes: eps);
  }
}

class DramaServerEpisode {
  final int id;
  final String url;
  final bool locked;
  final int number;

  DramaServerEpisode({
    required this.id,
    this.url = '',
    this.locked = false,
    required this.number,
  });

  factory DramaServerEpisode.fromJson(Map<String, dynamic> json) {
    return DramaServerEpisode(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      locked: json['locked'] ?? false,
      number: json['number'] ?? 0,
    );
  }
}

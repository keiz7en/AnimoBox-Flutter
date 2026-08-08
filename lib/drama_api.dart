import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

const String _kissBase = 'https://kissasian.dev';
const String _defaultUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

Map<String, String> _headers() => {
  'User-Agent': _defaultUA,
  'Accept': 'application/json, text/html, */*',
  'Referer': _kissBase,
};

String _parseVideoUrl(String raw) {
  if (raw.isEmpty) return raw;
  final parts = raw.split('|');
  final clean = parts.first.trim();
  if (clean != raw) debugPrint('DramaAPI: Parsed URL: $clean (from: $raw)');
  return clean;
}

bool _isDeadCdn(String url) {
  return url.isEmpty;
}

Future<List<Drama>> searchDramas(String query) async {
  try {
    final url = '$_kissBase/api/search?q=${Uri.encodeComponent(query)}';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data.map<Drama>((j) => Drama.fromKissAsian(j)).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getRecentDramas() async {
  try {
    final queries = ['2026', 'love', 'show', 'movie', 'thai'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) dramas.add(d);
      }
    }
    dramas.sort((a, b) => b.yearValue.compareTo(a.yearValue));
    return dramas.take(40).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getPopularDramas() async {
  try {
    final queries = [
      'ongoing', 'airing', '2026', '2025', 'love', 'show', 'movie',
      'korean', 'japanese', 'chinese', 'thai', 'filipino',
      'action', 'thriller', 'romance', 'comedy', 'drama',
    ];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final ongoing = <Drama>[];
    final completed = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) {
          if (d.isOngoing) {
            ongoing.add(d);
          } else {
            completed.add(d);
          }
        }
      }
    }
    // Sort ongoing by year desc (newest first), then by episode count
    ongoing.sort((a, b) {
      final ya = a.yearValue;
      final yb = b.yearValue;
      if (ya != yb) return yb.compareTo(ya);
      return b.serverEpisodesCount.compareTo(a.serverEpisodesCount);
    });
    completed.sort((a, b) => b.yearValue.compareTo(a.yearValue));
    return [...ongoing, ...completed].take(60).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getNewDramas() async {
  try {
    final queries = [
      '2026', '2025', '2024', 'chinese', 'korean', 'japanese',
      'thai', 'filipino', 'action', 'comedy', 'romance', 'thriller',
    ];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) dramas.add(d);
      }
    }
    final currentYear = DateTime.now().year;
    dramas.sort((a, b) {
      final ya = a.yearValue;
      final yb = b.yearValue;
      final aIsNew = ya >= currentYear;
      final bIsNew = yb >= currentYear;
      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;
      return yb.compareTo(ya);
    });
    return dramas.take(60).toList();
  } catch (_) {
    return [];
  }
}

Future<DramaEpisodeData?> getDramaEpisodes(int mediaId) async {
  try {
    final url = '$_kissBase/api/sources?id=$mediaId';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    return DramaEpisodeData.fromJson(data);
  } catch (_) {
    return null;
  }
}

Future<String?> getDramaVideoUrl(int mediaId, int episodeNumber) async {
  try {
    final url = '$_kissBase/api/sources?id=$mediaId&ep=$episodeNumber';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);

    final servers = data['servers'] as List?;
    if (servers != null) {
      for (final server in servers) {
        final episodes = server['episodes'] as List?;
        if (episodes == null || episodes.isEmpty) continue;
        for (final ep in episodes) {
          if (ep['number'] == episodeNumber) {
            final videoUrl = _parseVideoUrl(ep['url']?.toString() ?? '');
            if (videoUrl.isNotEmpty && !_isDeadCdn(videoUrl)) return videoUrl;
          }
        }
      }
    }

    final topEpisodes = data['episodes'] as List?;
    if (topEpisodes != null) {
      for (final ep in topEpisodes) {
        if (ep['number'] == episodeNumber) {
          final videoUrl = _parseVideoUrl(ep['videoUrl']?.toString() ?? '');
          if (videoUrl.isNotEmpty && !_isDeadCdn(videoUrl)) return videoUrl;
        }
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<List<StreamSource>> getDramaStreamSources(int mediaId, int episodeNumber) async {
  try {
    final url = '$_kissBase/api/sources?id=$mediaId&ep=$episodeNumber';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    final sources = <StreamSource>[];

    // Add named servers first (they may have different CDN URLs)
    final servers = data['servers'] as List?;
    if (servers != null) {
      for (final server in servers) {
        final name = server['name'] ?? 'Server';
        final episodes = server['episodes'] as List?;
        if (episodes == null || episodes.isEmpty) continue;
        final links = <StreamLink>[];
        for (final ep in episodes) {
          if (ep['locked'] == true) continue;
          final videoUrl = _parseVideoUrl(ep['url']?.toString() ?? '');
          final epNum = ep['number'] ?? episodeNumber;
          if (videoUrl.isNotEmpty && !_isDeadCdn(videoUrl)) {
            links.add(StreamLink(url: videoUrl, quality: 'Ep $epNum'));
          }
        }
        if (links.isNotEmpty) {
          sources.add(StreamSource(server: name, type: 'drama', links: links));
        }
      }
    }

    // Add top-level episodes as fallback
    final topEpisodes = data['episodes'] as List?;
    if (topEpisodes != null && topEpisodes.isNotEmpty) {
      final links = <StreamLink>[];
      for (final ep in topEpisodes) {
        final videoUrl = _parseVideoUrl(ep['videoUrl']?.toString() ?? '');
        final epNum = ep['number'] ?? episodeNumber;
        if (videoUrl.isNotEmpty && !_isDeadCdn(videoUrl)) {
          links.add(StreamLink(url: videoUrl, quality: 'Ep $epNum'));
        }
      }
      if (links.isNotEmpty) {
        sources.add(StreamSource(server: 'Auto', type: 'drama', links: links));
      }
    }
    return sources;
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getDramasByCountry(String country) async {
  try {
    final queries = <String>[];
    if (country == 'Japanese') {
      queries.addAll(['japanese', 'japan', 'tokyo', 'japanese love', 'japanese school', 'anime', '2026', '2025']);
    } else if (country == 'Korean') {
      queries.addAll(['korean', 'korea', 'korean drama', 'korean love', 'korean 2025', 'korean 2026', 'kdrama']);
    } else if (country == 'Chinese') {
      queries.addAll(['chinese', 'china', 'chinese drama', 'chinese love', 'chinese 2025', 'chinese 2026', 'cdrama']);
    } else if (country == 'Thai') {
      queries.addAll(['thai', 'thailand', 'thai drama', 'thai love', 'thai 2025', 'thai 2026']);
    } else if (country == 'Filipino') {
      queries.addAll(['filipino', 'philippines', 'pinoy', 'filipino drama', 'filipino 2025']);
    } else if (country == 'English') {
      queries.addAll(['english', 'english drama', 'hollywood', 'english 2025', 'american', 'usa']);
    } else {
      queries.addAll([country, '$country drama', '$country 2024', '$country 2025', '$country 2026', '$country love', '$country action']);
    }
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final ongoing = <Drama>[];
    final completed = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) {
          final dCountry = d.country.toLowerCase();
          final matchCountry = country.toLowerCase();
          if (dCountry.contains(matchCountry) || matchCountry.contains(dCountry) ||
              (country == 'Japanese' && dCountry == 'japan') ||
              (country == 'Korean' && dCountry == 'south korea') ||
              (country == 'Chinese' && (dCountry == 'china' || dCountry == 'hong kong' || dCountry == 'taiwan'))) {
            if (d.isOngoing) {
              ongoing.add(d);
            } else {
              completed.add(d);
            }
          }
        }
      }
    }
    if (ongoing.isEmpty && completed.isEmpty) {
      for (final list in results) {
        for (final d in list) {
          if (seen.add(d.id)) {
            if (d.isOngoing) {
              ongoing.add(d);
            } else {
              completed.add(d);
            }
          }
        }
      }
    }
    ongoing.sort((a, b) {
      final ya = a.yearValue;
      final yb = b.yearValue;
      if (ya != yb) return yb.compareTo(ya);
      return b.serverEpisodesCount.compareTo(a.serverEpisodesCount);
    });
    completed.sort((a, b) => b.yearValue.compareTo(a.yearValue));
    return [...ongoing, ...completed].take(60).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getAiringDramasByCountry(String country) async {
  try {
    final queries = [country, '$country ongoing', '$country airing', '$country 2026', '$country 2025'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id) && d.isOngoing) dramas.add(d);
      }
    }
    dramas.sort((a, b) => b.yearValue.compareTo(a.yearValue));
    return dramas.take(40).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getHollywoodDramas() async {
  try {
    final queries = [
      '2026', '2025', '2024', 'american', 'usa', 'hollywood',
      'action', 'horror', 'adventure', 'crime', 'thriller', 'mystery',
      'movie', 'hbo', 'dc', 'comedy', 'romance', 'war', 'drama',
      'sport', 'superhero', 'animation', 'scifi', 'fantasy',
    ];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id) && d.isHollywood) dramas.add(d);
      }
    }
    dramas.sort((a, b) {
      final ya = a.yearValue;
      final yb = b.yearValue;
      if (ya != yb) return yb.compareTo(ya);
      return b.serverEpisodesCount.compareTo(a.serverEpisodesCount);
    });
    return dramas.take(60).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getPopularHollywood() async {
  try {
    final queries = [
      '2026', '2025', 'american', 'usa', 'hollywood',
      'action', 'adventure', 'crime', 'movie', 'hbo', 'dc',
      'horror', 'thriller', 'romance', 'comedy', 'sport',
    ];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final ongoing = <Drama>[];
    final completed = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id) && d.isHollywood) {
          if (d.isOngoing) {
            ongoing.add(d);
          } else {
            completed.add(d);
          }
        }
      }
    }
    ongoing.sort((a, b) {
      final ya = a.yearValue;
      final yb = b.yearValue;
      if (ya != yb) return yb.compareTo(ya);
      return b.serverEpisodesCount.compareTo(a.serverEpisodesCount);
    });
    completed.sort((a, b) => b.yearValue.compareTo(a.yearValue));
    return [...ongoing, ...completed].take(60).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getNewHollywood() async {
  try {
    final queries = [
      '2026', '2025', 'american', 'usa', 'hollywood',
      'action', 'horror', 'adventure', 'crime', 'thriller',
      'movie', 'comedy', 'romance', 'mystery', 'dc', 'hbo',
    ];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id) && d.isHollywood) dramas.add(d);
      }
    }
    final currentYear = DateTime.now().year;
    dramas.sort((a, b) {
      final ya = a.yearValue;
      final yb = b.yearValue;
      final aIsNew = ya >= currentYear;
      final bIsNew = yb >= currentYear;
      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;
      return yb.compareTo(ya);
    });
    return dramas.take(60).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getAiringHollywood() async {
  try {
    final queries = [
      '2026', 'american ongoing', 'hollywood ongoing', 'usa ongoing',
      'hbo', 'series', 'season',
    ];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id) && d.isHollywood && d.isOngoing) dramas.add(d);
      }
    }
    dramas.sort((a, b) => b.yearValue.compareTo(a.yearValue));
    return dramas.take(40).toList();
  } catch (_) {
    return [];
  }
}

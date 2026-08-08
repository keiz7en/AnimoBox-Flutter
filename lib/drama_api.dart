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
  if (url.isEmpty) return true;
  final lower = url.toLowerCase();
  return lower.contains('dsaqtqpt.pro') || lower.contains('cloudokyo.cloud');
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
    return dramas.take(40).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getPopularDramas() async {
  try {
    final queries = ['love', 'show', 'movie', 'korean', 'japanese'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final ongoing = <Drama>[];
    final completed = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) {
          if (d.status.toLowerCase() == 'ongoing') {
            ongoing.add(d);
          } else {
            completed.add(d);
          }
        }
      }
    }
    return [...ongoing, ...completed].take(40).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getNewDramas() async {
  try {
    final queries = ['chinese', 'hollywood', 'family', 'action', 'comedy'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) dramas.add(d);
      }
    }
    return dramas.take(40).toList();
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
    final queries = [country, '$country drama', '$country 2024', '$country 2025', '$country love'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final ongoing = <Drama>[];
    final completed = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) {
          if (d.status.toLowerCase() == 'ongoing') {
            ongoing.add(d);
          } else {
            completed.add(d);
          }
        }
      }
    }
    return [...ongoing, ...completed].take(50).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getAiringDramasByCountry(String country) async {
  try {
    final queries = [country, '$country ongoing', '$country airing'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <int>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id) && d.status.toLowerCase() != 'completed') dramas.add(d);
      }
    }
    return dramas.take(30).toList();
  } catch (_) {
    return [];
  }
}

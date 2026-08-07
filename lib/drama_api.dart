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

String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is num) return v.toString();
  return null;
}

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is String) {
    final parsed = int.tryParse(v);
    if (parsed != null) return parsed;
  }
  return fallback;
}

Future<List<Drama>> searchDramas(String query) async {
  if (query.trim().isEmpty) return [];
  try {
    final url = '$_kissBase/api/search?q=${Uri.encodeComponent(query)}';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data.map<Drama>((j) => Drama.fromKissAsian(j)).toList();
  } catch (e) {
    debugPrint('DramaAPI: searchDramas failed for "$query": $e');
    return [];
  }
}

Future<List<Drama>> getRecentDramas() async {
  try {
    final queries = ['2026', 'love', 'show', 'movie', 'thai'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <String>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        final key = '${d.id}_${d.title}';
        if (seen.add(key)) dramas.add(d);
      }
    }
    return dramas.take(40).toList();
  } catch (e) {
    debugPrint('DramaAPI: getRecentDramas failed: $e');
    return [];
  }
}

Future<List<Drama>> getPopularDramas() async {
  try {
    final queries = ['love', 'show', 'movie', 'korean', 'japanese'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <String>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        final key = '${d.id}_${d.title}';
        if (seen.add(key)) dramas.add(d);
      }
    }
    return dramas.take(40).toList();
  } catch (e) {
    debugPrint('DramaAPI: getPopularDramas failed: $e');
    return [];
  }
}

Future<List<Drama>> getAiringDramas() async {
  try {
    final queries = ['2026', 'ongoing', 'airing', 'new', 'latest'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <String>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        final key = '${d.id}_${d.title}';
        if (seen.add(key)) dramas.add(d);
      }
    }
    return dramas.take(40).toList();
  } catch (e) {
    debugPrint('DramaAPI: getAiringDramas failed: $e');
    return [];
  }
}

Future<List<Drama>> getNewDramas() async {
  try {
    final queries = ['chinese', 'hollywood', 'family', 'action', 'comedy'];
    final futures = queries.map((q) => searchDramas(q)).toList();
    final results = await Future.wait(futures);
    final seen = <String>{};
    final dramas = <Drama>[];
    for (final list in results) {
      for (final d in list) {
        final key = '${d.id}_${d.title}';
        if (seen.add(key)) dramas.add(d);
      }
    }
    return dramas.take(40).toList();
  } catch (e) {
    debugPrint('DramaAPI: getNewDramas failed: $e');
    return [];
  }
}

Future<List<Drama>> getDramasByCountry(String country) async {
  try {
    return await searchDramas(country);
  } catch (e) {
    debugPrint('DramaAPI: getDramasByCountry failed for $country: $e');
    return [];
  }
}

Future<DramaEpisodeData?> getDramaEpisodes(int mediaId) async {
  try {
    final url = '$_kissBase/api/sources?id=$mediaId';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      debugPrint('DramaAPI: getDramaEpisodes HTTP ${res.statusCode} for id=$mediaId');
      return null;
    }
    final data = jsonDecode(res.body);
    if (data is! Map) {
      debugPrint('DramaAPI: getDramaEpisodes unexpected response type: ${data.runtimeType}');
      return null;
    }
    return DramaEpisodeData.fromJson(Map<String, dynamic>.from(data));
  } catch (e) {
    debugPrint('DramaAPI: getDramaEpisodes failed for id=$mediaId: $e');
    return null;
  }
}

Future<String?> getDramaVideoUrl(int mediaId, int episodeNumber) async {
  try {
    final url = '$_kissBase/api/sources?id=$mediaId&ep=$episodeNumber';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data is! Map) return null;

    final topEpisodes = data['episodes'] as List?;
    if (topEpisodes != null) {
      for (final ep in topEpisodes) {
        if (ep is! Map) continue;
        final epNum = _asInt(ep['number']);
        if (epNum == episodeNumber) {
          final videoUrl = _asString(ep['videoUrl']);
          if (videoUrl != null && videoUrl.isNotEmpty) return _parseVideoUrl(videoUrl);
        }
      }
    }

    final servers = data['servers'] as List?;
    if (servers == null || servers.isEmpty) return null;
    for (final server in servers) {
      if (server is! Map) continue;
      final episodes = server['episodes'] as List?;
      if (episodes == null || episodes.isEmpty) continue;
      for (final ep in episodes) {
        if (ep is! Map) continue;
        final epNum = _asInt(ep['number']);
        if (epNum == episodeNumber) {
          final videoUrl = _asString(ep['url']);
          if (videoUrl != null && videoUrl.isNotEmpty) return _parseVideoUrl(videoUrl);
        }
      }
    }
    return null;
  } catch (e) {
    debugPrint('DramaAPI: getDramaVideoUrl failed: $e');
    return null;
  }
}

Future<List<StreamSource>> getDramaStreamSources(int mediaId, int episodeNumber) async {
  try {
    final url = '$_kissBase/api/sources?id=$mediaId&ep=$episodeNumber';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! Map) return [];
    final sources = <StreamSource>[];

    final topEpisodes = data['episodes'] as List?;
    if (topEpisodes != null && topEpisodes.isNotEmpty) {
      final links = <StreamLink>[];
      for (final ep in topEpisodes) {
        if (ep is! Map) continue;
        final videoUrl = _asString(ep['videoUrl']);
        final epNum = _asInt(ep['number'], episodeNumber);
        if (videoUrl != null && videoUrl.isNotEmpty) {
          links.add(StreamLink(url: _parseVideoUrl(videoUrl), quality: 'Ep $epNum'));
        }
      }
      if (links.isNotEmpty) {
        sources.add(StreamSource(server: 'Auto', type: 'drama', links: links));
      }
    }

    final servers = data['servers'] as List?;
    if (servers != null) {
      for (final server in servers) {
        if (server is! Map) continue;
        final name = _asString(server['name']) ?? 'Server';
        final episodes = server['episodes'] as List?;
        if (episodes == null || episodes.isEmpty) continue;
        final links = <StreamLink>[];
        for (final ep in episodes) {
          if (ep is! Map) continue;
          final videoUrl = _asString(ep['url']);
          final epNum = _asInt(ep['number'], episodeNumber);
          if (videoUrl != null && videoUrl.isNotEmpty) {
            links.add(StreamLink(url: _parseVideoUrl(videoUrl), quality: 'Ep $epNum'));
          }
        }
        if (links.isNotEmpty) {
          sources.add(StreamSource(server: name, type: 'drama', links: links));
        }
      }
    }
    return sources;
  } catch (e) {
    debugPrint('DramaAPI: getDramaStreamSources failed: $e');
    return [];
  }
}

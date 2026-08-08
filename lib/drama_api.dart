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
  // Format can be: "url|lang|subtitleUrl" or just "url"
  final parts = raw.split('|');
  final clean = parts.first.trim();
  if (clean != raw) debugPrint('DramaAPI: Parsed URL: $clean (from: $raw)');
  return clean;
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

    // Try top-level episodes first (has videoUrl)
    final topEpisodes = data['episodes'] as List?;
    if (topEpisodes != null) {
      for (final ep in topEpisodes) {
        if (ep['number'] == episodeNumber) {
          final videoUrl = ep['videoUrl'] as String?;
          if (videoUrl != null && videoUrl.isNotEmpty) return _parseVideoUrl(videoUrl);
        }
      }
    }

    // Fallback to servers
    final servers = data['servers'] as List?;
    if (servers == null || servers.isEmpty) return null;
    for (final server in servers) {
      final episodes = server['episodes'] as List?;
      if (episodes == null || episodes.isEmpty) continue;
      for (final ep in episodes) {
        if (ep['number'] == episodeNumber) {
          final videoUrl = ep['url'] as String?;
          if (videoUrl != null && videoUrl.isNotEmpty) return _parseVideoUrl(videoUrl);
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

    // Add top-level episodes as "Auto" server
    final topEpisodes = data['episodes'] as List?;
    if (topEpisodes != null && topEpisodes.isNotEmpty) {
      final links = <StreamLink>[];
      for (final ep in topEpisodes) {
        final videoUrl = ep['videoUrl'] as String?;
        final epNum = ep['number'] ?? episodeNumber;
        if (videoUrl != null && videoUrl.isNotEmpty) {
          links.add(StreamLink(url: _parseVideoUrl(videoUrl), quality: 'Ep $epNum'));
        }
      }
      if (links.isNotEmpty) {
        sources.add(StreamSource(server: 'Auto', type: 'drama', links: links));
      }
    }

    // Add named servers
    final servers = data['servers'] as List?;
    if (servers != null) {
      for (final server in servers) {
        final name = server['name'] ?? 'Server';
        final episodes = server['episodes'] as List?;
        if (episodes == null || episodes.isEmpty) continue;
        final links = <StreamLink>[];
        for (final ep in episodes) {
          final videoUrl = ep['url'] as String?;
          final epNum = ep['number'] ?? episodeNumber;
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
  } catch (_) {
    return [];
  }
}

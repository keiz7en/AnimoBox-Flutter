import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

const String _kissBase = 'https://kissasian.dev';
const String _defaultUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

Map<String, String> _headers() => {
  'User-Agent': _defaultUA,
  'Accept': 'application/json, text/html, */*',
  'Referer': _kissBase,
};

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
    final queries = ['2026 korean drama', '2026 chinese drama', '2026 thai drama'];
    final results = <Drama>[];
    for (final q in queries) {
      final dramas = await searchDramas(q);
      for (final d in dramas) {
        if (!results.any((r) => r.id == d.id)) results.add(d);
      }
      if (results.length >= 20) break;
    }
    return results.take(20).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getPopularDramas() async {
  try {
    final queries = ['korean drama', 'crash landing', 'squid game', 'boys over flowers'];
    final results = <Drama>[];
    for (final q in queries) {
      final dramas = await searchDramas(q);
      for (final d in dramas) {
        if (!results.any((r) => r.id == d.id)) results.add(d);
      }
      if (results.length >= 20) break;
    }
    return results.take(20).toList();
  } catch (_) {
    return [];
  }
}

Future<List<Drama>> getNewDramas() async {
  try {
    final queries = ['2025 drama', '2026 drama ongoing'];
    final results = <Drama>[];
    for (final q in queries) {
      final dramas = await searchDramas(q);
      for (final d in dramas) {
        if (!results.any((r) => r.id == d.id)) results.add(d);
      }
      if (results.length >= 20) break;
    }
    return results.take(20).toList();
  } catch (_) {
    return [];
  }
}

Future<DramaDetail?> getDramaDetail(String slug) async {
  try {
    final url = '$_kissBase/tv-series/$slug';
    final res = await http.get(Uri.parse(url), headers: _headers()).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    return _parseDramaPage(res.body, slug);
  } catch (_) {
    return null;
  }
}

DramaDetail? _parseDramaPage(String html, String slug) {
  try {
    final titleMatch = RegExp(r'"title"\s*:\s*"([^"]+)"').firstMatch(html);
    final posterMatch = RegExp(r'"poster"\s*:\s*"([^"]+)"').firstMatch(html);
    final backdropMatch = RegExp(r'"backdrop"\s*:\s*"([^"]+)"').firstMatch(html);
    final descMatch = RegExp(r'"description"\s*:\s*"([^"]+)"').firstMatch(html);
    final episodesMatch = RegExp(r'"episodes"\s*:\s*(\d+)').firstMatch(html);
    final statusMatch = RegExp(r'"status"\s*:\s*"([^"]+)"').firstMatch(html);
    final ratingMatch = RegExp(r'"rating"\s*:\s*([\d.]+)').firstMatch(html);
    final countryMatch = RegExp(r'"country"\s*:\s*"([^"]+)"').firstMatch(html);
    final durationMatch = RegExp(r'"duration"\s*:\s*"([^"]+)"').firstMatch(html);
    final yearMatch = RegExp(r'"year"\s*:\s*"([^"]+)"').firstMatch(html);
    final idMatch = RegExp(r'"id"\s*:\s*(\d+)').firstMatch(html);
    final genresMatch = RegExp(r'"genres"\s*:\s*\[([^\]]*)\]').firstMatch(html);
    final serverEpMatch = RegExp(r'"serverEpisodesCount"\s*:\s*(\d+)').firstMatch(html);

    final genresRaw = genresMatch?.group(1) ?? '';
    final genres = genresRaw.split(',').map((g) => g.trim().replaceAll('"', '')).where((g) => g.isNotEmpty).toList();

    final epCount = int.tryParse(episodesMatch?.group(1) ?? serverEpMatch?.group(1) ?? '0') ?? 0;

    return DramaDetail(
      id: int.tryParse(idMatch?.group(1) ?? '0') ?? slug.hashCode,
      title: titleMatch?.group(1) ?? '',
      slug: slug,
      poster: posterMatch?.group(1) ?? '',
      backdrop: backdropMatch?.group(1) ?? '',
      description: descMatch?.group(1) ?? '',
      episodes: epCount,
      status: statusMatch?.group(1) ?? '',
      rating: double.tryParse(ratingMatch?.group(1) ?? '0') ?? 0,
      country: countryMatch?.group(1) ?? '',
      duration: durationMatch?.group(1) ?? '',
      year: yearMatch?.group(1) ?? '',
      genres: genres,
    );
  } catch (_) {
    return null;
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
    if (servers == null || servers.isEmpty) return null;
    final firstServer = servers[0];
    final episodes = firstServer['episodes'] as List?;
    if (episodes == null || episodes.isEmpty) return null;
    final ep = episodes.firstWhere(
      (e) => e['number'] == episodeNumber,
      orElse: () => episodes[0],
    );
    return ep['url'] as String?;
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
    final servers = data['servers'] as List?;
    if (servers == null || servers.isEmpty) return [];
    final sources = <StreamSource>[];
    for (final server in servers) {
      final name = server['name'] ?? 'Server';
      final episodes = server['episodes'] as List?;
      if (episodes == null) continue;
      final links = <StreamLink>[];
      for (final ep in episodes) {
        final videoUrl = ep['url'] as String?;
        final epNum = ep['number'] ?? episodeNumber;
        if (videoUrl != null && videoUrl.isNotEmpty) {
          links.add(StreamLink(
            url: videoUrl,
            quality: 'Ep $epNum',
          ));
        }
      }
      if (links.isNotEmpty) {
        sources.add(StreamSource(
          server: name,
          type: 'drama',
          links: links,
        ));
      }
    }
    return sources;
  } catch (_) {
    return [];
  }
}

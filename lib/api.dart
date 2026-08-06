import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

const String _anilistUrl = 'https://graphql.anilist.co';
const String _animeheavenBase = 'https://animeheaven.me';
const String _anikotoBase = 'https://anikototv.to';

const String _defaultUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
const String _xhrHeader = 'XMLHttpRequest';

Map<String, String> _anilistHeaders() => {'Content-Type': 'application/json', 'Accept': 'application/json'};

Map<String, String> _siteHeaders(String referer) => {
  'User-Agent': _defaultUA,
  'X-Requested-With': _xhrHeader,
  'Referer': referer,
};

const String _mediaFields = '''
  id
  title { romaji english native }
  coverImage { large medium }
  bannerImage
  description(asHtml: false)
  format
  status
  episodes
  duration
  averageScore
  genres
  season
  seasonYear
  isAdult
  synonyms
  nextAiringEpisode { episode airingAt }
''';

Future<List<Anime>> _fetchAniList({
  int page = 1,
  int perPage = 50,
  List<String>? sort,
  String? status,
  String? search,
}) async {
  try {
    final variables = <String, dynamic>{
      'page': page,
      'perPage': perPage,
    };
    if (sort != null) variables['sort'] = sort;
    if (status != null) variables['status'] = status;
    if (search != null) variables['search'] = search;

    const query = '''
      query (\$page: Int, \$perPage: Int, \$sort: [MediaSort], \$status: MediaStatus, \$search: String) {
        Page(page: \$page, perPage: \$perPage) {
          media(search: \$search, sort: \$sort, status: \$status, type: ANIME, isAdult: false) {
            $_mediaFields
          }
          pageInfo { hasNextPage }
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(_anilistUrl),
      headers: _anilistHeaders(),
      body: jsonEncode({'query': query, 'variables': variables}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    if (data['errors'] != null) return [];

    final mediaList = data['data']?['Page']?['media'];
    if (mediaList == null || mediaList is! List) return [];

    return mediaList.map<Anime>((m) => Anime.fromAniList(m)).where((a) => !a.isAdult).toList();
  } catch (e) {
    return [];
  }
}

Future<List<Anime>> getRecentEpisodes({int page = 1}) async {
  final list = await _fetchAniList(page: page, perPage: 50, sort: ['UPDATED_AT_DESC'], status: 'RELEASING');
  return _filterNSFW(list);
}

Future<List<Anime>> getTopAnime({int page = 1, String sort = 'SCORE_DESC'}) async {
  final list = await _fetchAniList(page: page, perPage: 50, sort: [sort]);
  return _filterNSFW(list);
}

Future<List<Anime>> searchAnime(String query, {int page = 1}) async {
  if (query.trim().isEmpty) return [];
  final list = await _fetchAniList(page: page, perPage: 50, search: query.trim());
  return _filterNSFW(list);
}

Future<List<Anime>> getAiringSchedule() async {
  final list = await _fetchAniList(sort: ['POPULARITY_DESC'], status: 'RELEASING');
  return _filterNSFW(list);
}

Future<List<Anime>> getFinishedAnime({int page = 1}) async {
  final list = await _fetchAniList(page: page, sort: ['END_DATE_DESC'], status: 'FINISHED');
  return _filterNSFW(list);
}

Future<List<Anime>> getUpcomingAnime({int page = 1}) async {
  final list = await _fetchAniList(page: page, sort: ['START_DATE_DESC'], status: 'NOT_YET_RELEASED');
  return _filterNSFW(list);
}

Future<List<Anime>> getNewFinishedAnime({int page = 1}) async {
  final list = await _fetchAniList(page: page, sort: ['POPULARITY_DESC'], status: 'FINISHED');
  return _filterNSFW(list);
}

Future<List<Anime>> _filterNSFW(List<Anime> list) async {
  final settings = await getSettings();
  final showNSFW = settings['nsfwFilter'] ?? false;
  if (showNSFW) return list;
  return list.where((a) => !a.isAdult).toList();
}

Future<List<String>> getGenreList() async {
  try {
    final response = await http.post(
      Uri.parse(_anilistUrl),
      headers: _anilistHeaders(),
      body: jsonEncode({'query': '{ GenreCollection }', 'variables': {}}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    return List<String>.from(data['data']?['GenreCollection'] ?? []);
  } catch (_) {
    return [];
  }
}

Future<Anime?> getAnimeDetailsById(String id) async {
  try {
    final response = await http.post(
      Uri.parse(_anilistUrl),
      headers: _anilistHeaders(),
      body: jsonEncode({
        'query': '''
          query (\$id: Int) {
            Media(id: \$id, type: ANIME) {
              $_mediaFields
              mediaListEntry { progress }
              startDate { year month day }
              endDate { year month day }
              characters(sort: ROLE, perPage: 8) { edges { node { name { full } } role } }
            }
          }
        ''',
        'variables': {'id': int.tryParse(id) ?? 0},
      }),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    final media = data['data']?['Media'];
    if (media == null) return null;
    return Anime.fromAniList(media);
  } catch (_) {
    return null;
  }
}

// ── AnimeHeaven streaming ──

Future<List<SearchResult>> searchAnimeHeaven(String query) async {
  try {
    final url = '$_animeheavenBase/search.php?s=${Uri.encodeComponent(query)}';
    final response = await http.get(Uri.parse(url), headers: _siteHeaders('$_animeheavenBase/')).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];
    final results = <SearchResult>[];
    final seen = <String>{};
    final regex = RegExp(r'anime\.php\?([a-z0-9]+)');
    final titleRegex = RegExp(r'anime\.php\?([a-z0-9]+)[^>]*>([^<]+)</a>');
    for (final match in titleRegex.allMatches(response.body)) {
      final id = match.group(1)!;
      if (seen.add(id)) {
        results.add(SearchResult(id: id, title: match.group(2)!.trim(), source: 'AnimeHeaven'));
      }
    }
    if (results.isEmpty) {
      for (final match in regex.allMatches(response.body)) {
        final id = match.group(1)!;
        if (seen.add(id)) {
          results.add(SearchResult(id: id, title: query, source: 'AnimeHeaven'));
        }
      }
    }
    return results;
  } catch (_) {
    return [];
  }
}

Future<String?> _getAnimeHeavenVideo(String animeId, int episode) async {
  try {
    final epPageResp = await http.get(
      Uri.parse('$_animeheavenBase/anime.php?$animeId'),
      headers: _siteHeaders('$_animeheavenBase/'),
    ).timeout(const Duration(seconds: 8));
    if (epPageResp.statusCode != 200) return null;
    final html = epPageResp.body;

    String? hash;

    final allGates = RegExp(r'gatea\("([a-f0-9]{32})"\)').allMatches(html).toList();
    if (allGates.isEmpty) return null;

    final epNumRegex = RegExp(r'Episode</div><div[^>]*>\s*(\d+)\s*</div>');

    for (final g in allGates) {
      final start = g.start;
      final chunk = html.substring(start, start + 400 < html.length ? start + 400 : html.length);
      final epMatch = epNumRegex.firstMatch(chunk);
      if (epMatch != null) {
        final epNum = int.tryParse(epMatch.group(1) ?? '') ?? 0;
        if (epNum == episode) {
          hash = g.group(1);
          break;
        }
      }
    }

    if (hash == null) {
      for (final g in allGates) {
        final start = g.start;
        final chunk = html.substring(start, start + 400 < html.length ? start + 400 : html.length);
        final epMatch = epNumRegex.firstMatch(chunk);
        if (epMatch != null) {
          final epNum = int.tryParse(epMatch.group(1) ?? '') ?? 0;
          if (epNum <= episode) {
            hash = g.group(1);
            break;
          }
        }
      }
    }

    if (hash == null) return null;

    final gateResp = await http.get(
      Uri.parse('$_animeheavenBase/gate.php'),
      headers: {
        ..._siteHeaders('$_animeheavenBase/anime.php?$animeId'),
        'Cookie': 'key=$hash',
      },
    ).timeout(const Duration(seconds: 8));
    if (gateResp.statusCode != 200) return null;

    final srcMatch = RegExp(r"src='(https?://[^']+video\.mp4\?[^']+)'").firstMatch(gateResp.body);
    if (srcMatch != null) return srcMatch.group(1);

    final srcMatch2 = RegExp(r'src="(https?://[^"]+video\.mp4\?[^"]+)"').firstMatch(gateResp.body);
    if (srcMatch2 != null) return srcMatch2.group(1);

    final body = gateResp.body;
    final idx = body.indexOf('.mp4?');
    if (idx > 0) {
      int start = idx;
      while (start > 0 && body[start - 1] != '"' && body[start - 1] != '\'' && body[start - 1] != ' ' && body[start - 1] != '(') {
        start--;
      }
      int end = idx + 4;
      while (end < body.length && body[end] != '"' && body[end] != '\'' && body[end] != ' ' && body[end] != ')') {
        end++;
      }
      final candidate = body.substring(start, end);
      if (candidate.startsWith('http')) return candidate;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<StreamSource?> tryAnimeHeaven(String title, int episode) async {
  try {
    final searchResults = await searchAnimeHeaven(title);
    if (searchResults.isEmpty) return null;

    for (final result in searchResults) {
      final url = await _getAnimeHeavenVideo(result.id, episode);
      if (url != null) {
        return StreamSource(
          server: 'AnimeHeaven',
          type: url.contains('.m3u8') ? 'hls' : 'mp4',
          links: [StreamLink(url: url, quality: 'auto')],
        );
      }
    }
  } catch (_) {}
  return null;
}

// ── AniKoto streaming ──

Future<List<SearchResult>> searchAnikoto(String query) async {
  try {
    final response = await http.get(
      Uri.parse('$_anikotoBase/filter?keyword=${Uri.encodeComponent(query)}'),
      headers: _siteHeaders('$_anikotoBase/'),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];
    final results = <SearchResult>[];
    for (final match in RegExp(r'data-tip="(\d+)"').allMatches(response.body)) {
      results.add(SearchResult(id: match.group(1)!, title: query, source: 'AniKoto'));
    }
    return results;
  } catch (_) {
    return [];
  }
}

Future<String?> _getAnikotoEpisodeData(String animeId, int episode) async {
  try {
    final response = await http.get(
      Uri.parse('$_anikotoBase/ajax/episode/list/$animeId'),
      headers: _siteHeaders('$_anikotoBase/'),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    String html = '';
    try {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody is Map) {
        final result = jsonBody['result'];
        if (result is String) {
          html = result;
        } else if (result is Map) {
          html = result['html'] ?? '';
        }
      }
    } catch (_) {
      html = response.body;
    }
    if (html.isEmpty) return null;

    final regex = RegExp(r'data-num="(\d+)"[^>]*data-slug="([^"]+)"[^>]*data-mal="(\d+)"[^>]*data-timestamp="(\d+)"');
    for (final match in regex.allMatches(html)) {
      final num = int.tryParse(match.group(1) ?? '') ?? 0;
      if (num == episode) {
        return '${match.group(3)}/${match.group(2)}/${match.group(4)}';
      }
    }

    final regex2 = RegExp(r'data-num=\\"(\d+)\\"[^>]*data-slug=\\"([^\\]+)\\"[^>]*data-mal=\\"(\d+)\\"[^>]*data-timestamp=\\"(\d+)\\"');
    for (final match in regex2.allMatches(html)) {
      final num = int.tryParse(match.group(1) ?? '') ?? 0;
      if (num == episode) {
        return '${match.group(3)}/${match.group(2)}/${match.group(4)}';
      }
    }

    return null;
  } catch (_) {
    return null;
  }
}

Future<String?> resolveAnikotoStreamUrl(String encUrl) async {
  try {
    final response = await http.get(
      Uri.parse('$_anikotoBase/ajax/server?get=${Uri.encodeComponent(encUrl)}'),
      headers: _siteHeaders('$_anikotoBase/'),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    String playerUrl = '';
    try {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody is Map) {
        final result = jsonBody['result'];
        if (result is String) {
          playerUrl = result;
        } else if (result is Map) {
          playerUrl = result['url']?.toString() ?? '';
        }
      }
    } catch (_) {}

    if (playerUrl.isEmpty) return null;

    final hashMatch = RegExp(r'#([^#]+)#').firstMatch(playerUrl);
    if (hashMatch == null) return null;
    final decoded = utf8.decode(base64Decode(hashMatch.group(1)!));
    if (decoded.contains('http')) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}

Future<List<StreamSource>> tryAnikoto(String title, int episode) async {
  final sources = <StreamSource>[];
  try {
    final results = await searchAnikoto(title);
    for (final result in results) {
      final epData = await _getAnikotoEpisodeData(result.id, episode);
      if (epData == null) continue;
      final parts = epData.split('/');
      if (parts.length != 3) continue;

      final mapperResp = await http.get(
        Uri.parse('https://mapper.nekostream.site/api/mal/${parts[0]}/${parts[1]}/${parts[2]}'),
        headers: _siteHeaders('$_anikotoBase/'),
      ).timeout(const Duration(seconds: 8));
      if (mapperResp.statusCode != 200) continue;

      final mapperData = jsonDecode(mapperResp.body);
      if (mapperData is! Map<String, dynamic>) continue;

      for (final entry in mapperData.entries) {
        if (entry.key == 'status') continue;
        final sourceData = entry.value;
        if (sourceData is! Map<String, dynamic>) continue;
        final sourceName = entry.key;

        for (final typeKey in ['sub', 'dub']) {
          final typeData = sourceData[typeKey];
          if (typeData is! Map<String, dynamic>) continue;

          String? encUrl;

          if (typeData['url'] != null) {
            encUrl = typeData['url'].toString();
          } else if (typeData['download'] is Map) {
            final downloadData = typeData['download'] as Map<String, dynamic>;
            for (final dlEntry in downloadData.entries) {
              if (dlEntry.value is String && dlEntry.value.toString().isNotEmpty) {
                encUrl = dlEntry.value.toString();
                break;
              }
            }
          }

          if (encUrl == null || encUrl.isEmpty) continue;

          if (encUrl.contains('pahe.nekostream.site')) {
            final resolved = await _resolvePaheUrl(encUrl);
            if (resolved != null && resolved.isNotEmpty) {
              final isHls = resolved.contains('.m3u8');
              sources.add(StreamSource(
                server: 'AniKoto $sourceName',
                type: isHls ? 'hls' : 'mp4',
                links: [StreamLink(url: resolved, quality: typeKey)],
              ));
            }
          } else {
            final resolved = await resolveAnikotoStreamUrl(encUrl);
            if (resolved != null && resolved.isNotEmpty) {
              final isHls = resolved.contains('.m3u8');
              sources.add(StreamSource(
                server: 'AniKoto $sourceName',
                type: isHls ? 'hls' : 'mp4',
                links: [StreamLink(url: resolved, quality: typeKey)],
              ));
            }
          }
        }
      }
      if (sources.isNotEmpty) break;
    }
  } catch (_) {}
  return sources;
}

Future<String?> _resolvePaheUrl(String paheUrl) async {
  try {
    final resp = await http.get(
      Uri.parse(paheUrl),
      headers: {
        'User-Agent': _defaultUA,
        'Referer': '$_anikotoBase/',
      },
    ).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final body = resp.body;
    final workerMatch = RegExp(r'"(https?://[^"]*download992[^"]*workers\.dev/[^"]*)"').firstMatch(body);
    if (workerMatch == null) return null;

    final workerUrl = workerMatch.group(1)!;
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(workerUrl));
      request.headers.addAll({
        'User-Agent': _defaultUA,
        'Referer': '$_anikotoBase/',
        'Origin': '$_anikotoBase',
      });
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 15));
      final workerResp = await http.Response.fromStream(streamedResponse);

      if (streamedResponse.statusCode == 302 || streamedResponse.statusCode == 301) {
        final location = streamedResponse.headers['location'];
        if (location != null && location.contains('.m3u8')) {
          return location;
        }
      }

      final m3u8Match = RegExp(r'(https?://[^"<> ]+\.m3u8[^"<> ]*)').firstMatch(workerResp.body);
      if (m3u8Match != null) return m3u8Match.group(1);

      final mp4Match = RegExp(r'(https?://[^"<> ]+\.mp4[^"<> ]*)').firstMatch(workerResp.body);
      if (mp4Match != null) return mp4Match.group(1);

      final kwikMatch = RegExp(r'(https?://kwik\.cx/[^"<> ]+)').firstMatch(workerResp.body);
      if (kwikMatch != null) {
        final kwikUrl = kwikMatch.group(1)!;
        final kwikResp = await http.get(
          Uri.parse(kwikUrl),
          headers: {
            'User-Agent': _defaultUA,
            'Referer': 'https://proud-dew-d754.download992.workers.dev/',
          },
        ).timeout(const Duration(seconds: 8));
        final kwikBody = kwikResp.body;
        final streamMatch = RegExp(r'(https?://[^"<> ]+\.m3u8[^"<> ]*)').firstMatch(kwikBody);
        if (streamMatch != null) return streamMatch.group(1);
        final kwikMp4 = RegExp(r'(https?://[^"<> ]+\.mp4[^"<> ]*)').firstMatch(kwikBody);
        if (kwikMp4 != null) return kwikMp4.group(1);
      }
    } finally {
      client.close();
    }

    return null;
  } catch (_) {
    return null;
  }
}

// ── Unified stream resolution with all title variants ──

Future<List<StreamSource>> getStreamURL(String animeTitle, int anilistId, int episode, {List<String>? titleVariants}) async {
  final titlesToTry = <String>[animeTitle];
  if (titleVariants != null) {
    for (final t in titleVariants) {
      if (!titlesToTry.contains(t) && t.isNotEmpty) {
        titlesToTry.add(t);
      }
    }
  }

  Future<List<StreamSource>> fetchAnimeHeaven() async {
    for (final t in titlesToTry) {
      final result = await tryAnimeHeaven(t, episode);
      if (result != null) return [result];
    }
    return <StreamSource>[];
  }

  Future<List<StreamSource>> fetchAnikoto() async {
    for (final t in titlesToTry) {
      final result = await tryAnikoto(t, episode);
      if (result.isNotEmpty) return result;
    }
    return <StreamSource>[];
  }

  final ahFuture = fetchAnimeHeaven();
  final akFuture = fetchAnikoto();

  List<StreamSource> allSources;

  try {
    allSources = await Future.any([ahFuture, akFuture]);
  } catch (_) {
    allSources = <StreamSource>[];
  }

  if (allSources.isEmpty) {
    try {
      allSources = await Future.any([ahFuture, akFuture]);
    } catch (_) {
      allSources = <StreamSource>[];
    }
  }

  if (allSources.isEmpty) {
    allSources = [
      StreamSource(
        server: 'Unavailable',
        type: 'info',
        links: [StreamLink(url: '', quality: 'No streaming sources found')],
      ),
    ];
  }

  return allSources;
}

// ── Library persistence ──

Future<List<Map<String, dynamic>>> getLibrary() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('library');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  } catch (_) {
    return [];
  }
}

Future<void> saveLibrary(List<Map<String, dynamic>> library) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('library', jsonEncode(library));
  } catch (_) {}
}

Future<void> addToLibrary(Anime anime, {String status = 'Watching'}) async {
  final library = await getLibrary();
  library.removeWhere((item) => item['id'] == anime.id);
  library.insert(0, {
    'id': anime.id,
    'title': anime.displayTitle,
    'coverImage': anime.coverImage,
    'status': status,
    'addedAt': DateTime.now().millisecondsSinceEpoch,
  });
  await saveLibrary(library);
}

Future<void> removeFromLibrary(int animeId) async {
  final library = await getLibrary();
  library.removeWhere((item) => item['id'] == animeId);
  await saveLibrary(library);
}

Future<void> updateLibraryStatus(int animeId, String newStatus) async {
  final library = await getLibrary();
  for (final item in library) {
    if (item['id'] == animeId) {
      item['status'] = newStatus;
      break;
    }
  }
  await saveLibrary(library);
}

Future<bool> isInLibrary(int animeId) async {
  final library = await getLibrary();
  return library.any((item) => item['id'] == animeId);
}

Future<Map<String, int>> getLibraryCounts() async {
  final library = await getLibrary();
  final counts = <String, int>{'All': library.length};
  for (final item in library) {
    final status = item['status'] ?? 'Watching';
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

// ── History ──

Future<List<Map<String, dynamic>>> getHistory() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('history');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  } catch (_) {
    return [];
  }
}

Future<void> saveToHistory(Map<String, dynamic> item) async {
  final history = await getHistory();
  history.removeWhere((h) =>
      h['animeTitle'] == item['animeTitle'] && h['episode'] == item['episode']);
  history.insert(0, item);
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history', jsonEncode(history));
  } catch (_) {}
}

Future<void> removeFromHistory(int index) async {
  final history = await getHistory();
  if (index >= 0 && index < history.length) {
    history.removeAt(index);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('history', jsonEncode(history));
    } catch (_) {}
  }
}

Future<void> clearHistory() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
  } catch (_) {}
}

Future<void> clearAllData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('library');
    await prefs.remove('history');
    await prefs.remove('playback_positions');
  } catch (_) {}
}

// ── Playback position tracking ──────────────────────────────────────
Future<void> savePlaybackPosition(String key, Duration position, Duration duration) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('playback_positions') ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(data));
    map[key] = {
      'position': position.inMilliseconds,
      'duration': duration.inMilliseconds,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString('playback_positions', jsonEncode(map));
  } catch (_) {}
}

Future<Map<String, dynamic>?> getPlaybackPosition(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('playback_positions');
    if (data == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(data));
    return map[key];
  } catch (_) {
    return null;
  }
}

Future<void> clearPlaybackPosition(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('playback_positions');
    if (data == null) return;
    final map = Map<String, dynamic>.from(jsonDecode(data));
    map.remove(key);
    await prefs.setString('playback_positions', jsonEncode(map));
  } catch (_) {}
}

// ── Settings persistence ──────────────────────────────────────────────
const Map<String, dynamic> defaultSettings = {
  'language': 'English',
  'videoQuality': 'Auto',
  'player': 'In-app Player',
  'autoRotate': true,
  'nsfwFilter': false,
  'themeColor': 'Gold',
  'theme': 'Dark',
};

Future<Map<String, dynamic>> getSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('settings');
    if (data != null) {
      final map = Map<String, dynamic>.from(jsonDecode(data));
      for (final key in defaultSettings.keys) {
        map.putIfAbsent(key, () => defaultSettings[key]);
      }
      return map;
    }
  } catch (_) {}
  return Map<String, dynamic>.from(defaultSettings);
}

Future<void> saveSetting(String key, dynamic value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final settings = await getSettings();
    settings[key] = value;
    await prefs.setString('settings', jsonEncode(settings));
  } catch (_) {}
}

// ── Update checker ──────────────────────────────────────────────────
const String _githubRepo = 'keiz7en/AnimoBox-Flutter';

Future<Map<String, dynamic>?> checkForUpdate() async {
  try {
    final url = Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest');
    final res = await http.get(url, headers: {'Accept': 'application/vnd.github.v3+json'});
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final tagName = data['tag_name'] ?? '';
    final version = tagName.replaceFirst('v', '').trim();
    String? apkUrl;
    int? apkSize;
    final assets = data['assets'] as List? ?? [];
    for (final asset in assets) {
      if (asset['name'].toString().endsWith('.apk')) {
        apkUrl = asset['browser_download_url'];
        apkSize = asset['size'] as int?;
        break;
      }
    }
    return {
      'version': version,
      'name': data['name'] ?? '',
      'body': data['body'] ?? '',
      'apkUrl': apkUrl,
      'apkSize': apkSize,
      'publishedAt': data['published_at'] ?? '',
    };
  } catch (_) {
    return null;
  }
}

bool needsForceUpdate(String currentVersion, String latestVersion) {
  try {
    final cur = currentVersion.split('+').first.split('.').map(int.parse).toList();
    final lat = latestVersion.split('+').first.split('.').map(int.parse).toList();
    if (cur.length < 3 || lat.length < 3) return false;
    return lat[0] > cur[0];
  } catch (_) {
    return false;
  }
}

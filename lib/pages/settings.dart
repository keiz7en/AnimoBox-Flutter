import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';
import '../api.dart';
import '../theme/nipah_theme.dart';
import '../widgets/nipah_loader.dart';

const Map<String, Map<String, String>> translations = {
  'English': {
    'settings': 'Settings',
    'general': 'General',
    'player': 'Player',
    'data': 'Data',
    'about': 'About',
    'checkUpdate': 'Check for Update',
    'tapToCheck': 'Tap to check latest version',
    'appearance': 'APPEARANCE',
    'language': 'Language',
    'theme': 'Theme',
    'accentColor': 'Accent Color',
    'content': 'CONTENT',
    'nsfwFilter': 'Show NSFW Content',
    'nsfwSubtitle': 'Show adult-rated anime',
    'playback': 'PLAYBACK',
    'autoRotate': 'Auto Rotate',
    'autoRotateSub': 'Rotate to landscape during playback',
    'videoQuality': 'Video Quality',
    'videoQualitySub': 'Preferred stream quality',
    'preferredPlayer': 'Preferred Player',
    'preferredPlayerSub': 'Choose video player',
    'playerEngine': 'Player Engine',
    'storage': 'STORAGE',
    'clearCache': 'Clear Cache',
    'clearCacheSub': 'Remove temporary files',
    'clearHistory': 'Clear Watch History',
    'clearHistorySub': 'Remove all watched episodes',
    'clearAllData': 'Clear All Data',
    'clearAllDataSub': 'Remove library, history, and settings',
    'links': 'LINKS',
    'sourceCode': 'Source Code',
    'reportIssue': 'Report Issue',
    'libraries': 'LIBRARIES',
    'appInfo': 'APP',
    'updateAvailable': 'Update Available',
    'upToDate': "You're Up to Date",
    'releaseNotes': 'Release Notes:',
    'downloadInstall': 'Download & Install',
    'downloading': 'Downloading...',
    'installing': 'Opening installer...',
    'install': 'Install',
    'later': 'Later',
    'ok': 'OK',
    'cancel': 'Cancel',
    'resumeFrom': 'Resume from?',
    'startOver': 'Start Over',
    'resume': 'Resume',
    'episode': 'Episode',
    'schedule': 'Schedule',
    'top': 'Top',
    'latest': 'Latest',
    'watchNow': 'Watch Now',
    'loading': 'Loading...',
    'synopsis': 'Synopsis',
    'episodes': 'Episodes',
    'play': 'Play',
    'addToLibrary': 'Add to Library',
    'removeFromLibrary': 'Remove from Library',
    'search': 'Search',
    'genres': 'Genres',
    'quickSearch': 'Quick Search',
    'library': 'Library',
    'all': 'All',
    'watching': 'Watching',
    'completed': 'Completed',
    'onHold': 'On Hold',
    'dropped': 'Dropped',
    'planToWatch': 'Plan to Watch',
    'changeStatus': 'Change Status',
    'noAnimeYet': 'No anime in your library yet',
    'addAnimeHint': 'Tap the bookmark icon on any anime to add it',
    'watchHistory': 'Watch History',
    'episodesCount': 'episodes',
    'noHistoryYet': 'No watch history yet',
    'startWatching': 'Start watching anime to build your history',
    'selectServer': 'Select Server',
    'retryAll': 'Retry All Sources',
    'allFailed': 'All streaming servers failed',
    'loadingEpisode': 'Loading Episode',
    'trying': 'Trying AnimeHeaven, AniKoto...',
    'justNow': 'Just now',
    'noUpdate': 'No Update',
    'couldNotCheck': 'Could not check for updates. Check your internet connection.',
    'newVersion': 'New version available',
    'currentVersion': 'Current version',
    'couldNotLoad': 'Could not load anime details',
    'confirmClearHistory': 'Clear all watch history?',
    'confirmClearData': 'This will remove all library, history, and settings.',
  },
  'Español': {
    'settings': 'Configuración',
    'general': 'General',
    'player': 'Reproductor',
    'data': 'Datos',
    'about': 'Acerca de',
    'checkUpdate': 'Buscar Actualización',
    'tapToCheck': 'Toca para verificar la última versión',
    'appearance': 'APARIENCIA',
    'language': 'Idioma',
    'theme': 'Tema',
    'accentColor': 'Color de Acento',
    'content': 'CONTENIDO',
    'nsfwFilter': 'Mostrar Contenido NSFW',
    'nsfwSubtitle': 'Mostrar anime para adultos',
    'playback': 'REPRODUCCIÓN',
    'autoRotate': 'Rotación Automática',
    'autoRotateSub': 'Rotar a horizontal durante la reproducción',
    'videoQuality': 'Calidad de Video',
    'videoQualitySub': 'Calidad de transmisión preferida',
    'preferredPlayer': 'Reproductor Preferido',
    'preferredPlayerSub': 'Elegir reproductor de video',
    'playerEngine': 'Motor del Reproductor',
    'storage': 'ALMACENAMIENTO',
    'clearCache': 'Limpiar Caché',
    'clearCacheSub': 'Eliminar archivos temporales',
    'clearHistory': 'Limpiar Historial',
    'clearHistorySub': 'Eliminar todos los episodios vistos',
    'clearAllData': 'Limpiar Todos los Datos',
    'clearAllDataSub': 'Eliminar biblioteca, historial y configuración',
    'links': 'ENLACES',
    'sourceCode': 'Código Fuente',
    'reportIssue': 'Reportar Problema',
    'libraries': 'BIBLIOTECAS',
    'appInfo': 'APP',
    'updateAvailable': 'Actualización Disponible',
    'upToDate': 'Estás al Día',
    'releaseNotes': 'Notas de la Versión:',
    'downloadInstall': 'Descargar e Instalar',
    'downloading': 'Descargando...',
    'installing': 'Abriendo instalador...',
    'install': 'Instalar',
    'later': 'Después',
    'ok': 'OK',
    'cancel': 'Cancelar',
    'resumeFrom': '¿Reanudar desde?',
    'startOver': 'Empezar de Nuevo',
    'resume': 'Reanudar',
    'episode': 'Episodio',
    'schedule': 'Horario',
    'top': 'Top',
    'latest': 'Último',
    'watchNow': 'Ver Ahora',
    'loading': 'Cargando...',
    'synopsis': 'Sinopsis',
    'episodes': 'Episodios',
    'play': 'Reproducir',
    'addToLibrary': 'Agregar a Biblioteca',
    'removeFromLibrary': 'Quitar de Biblioteca',
    'search': 'Buscar',
    'genres': 'Géneros',
    'quickSearch': 'Búsqueda Rápida',
    'library': 'Biblioteca',
    'all': 'Todos',
    'watching': 'Viendo',
    'completed': 'Completado',
    'onHold': 'En Pausa',
    'dropped': 'Abandonado',
    'planToWatch': 'Plan a Ver',
    'changeStatus': 'Cambiar Estado',
    'noAnimeYet': 'No hay anime en tu biblioteca',
    'addAnimeHint': 'Toca el icono de marcador para agregar anime',
    'watchHistory': 'Historial',
    'episodesCount': 'episodios',
    'noHistoryYet': 'Sin historial todavía',
    'startWatching': 'Empieza a ver anime',
    'selectServer': 'Seleccionar Servidor',
    'retryAll': 'Reintentar Todo',
    'allFailed': 'Todos los servidores fallaron',
    'loadingEpisode': 'Cargando Episodio',
    'trying': 'Probando AnimeHeaven, AniKoto...',
    'justNow': 'Ahora',
    'noUpdate': 'Sin Actualización',
    'couldNotCheck': 'No se pudo verificar. Revisa tu conexión.',
    'newVersion': 'Nueva versión disponible',
    'currentVersion': 'Versión actual',
    'couldNotLoad': 'No se pudieron cargar los detalles',
    'confirmClearHistory': '¿Limpiar todo el historial?',
    'confirmClearData': 'Esto eliminará biblioteca, historial y ajustes.',
  },
  'Português': {
    'settings': 'Configurações',
    'general': 'Geral',
    'player': 'Reprodutor',
    'data': 'Dados',
    'about': 'Sobre',
    'checkUpdate': 'Verificar Atualização',
    'tapToCheck': 'Toque para verificar a versão mais recente',
    'appearance': 'APARÊNCIA',
    'language': 'Idioma',
    'theme': 'Tema',
    'accentColor': 'Cor de Destaque',
    'content': 'CONTEÚDO',
    'nsfwFilter': 'Mostrar Conteúdo NSFW',
    'nsfwSubtitle': 'Mostrar anime para adultos',
    'playback': 'REPRODUÇÃO',
    'autoRotate': 'Rotação Automática',
    'autoRotateSub': 'Girar para paisagem durante a reprodução',
    'videoQuality': 'Qualidade de Vídeo',
    'videoQualitySub': 'Qualidade de transmissão preferida',
    'preferredPlayer': 'Reprodutor Preferido',
    'preferredPlayerSub': 'Escolher reprodutor de vídeo',
    'playerEngine': 'Motor do Reprodutor',
    'storage': 'ARMAZENAMENTO',
    'clearCache': 'Limpar Cache',
    'clearCacheSub': 'Remover arquivos temporários',
    'clearHistory': 'Limpar Histórico',
    'clearHistorySub': 'Remover todos os episódios assistidos',
    'clearAllData': 'Limpar Todos os Dados',
    'clearAllDataSub': 'Remover biblioteca, histórico e configurações',
    'links': 'LINKS',
    'sourceCode': 'Código Fonte',
    'reportIssue': 'Reportar Problema',
    'libraries': 'BIBLIOTECAS',
    'appInfo': 'APP',
    'updateAvailable': 'Atualização Disponível',
    'upToDate': 'Você está Atualizado',
    'releaseNotes': 'Notas da Versão:',
    'downloadInstall': 'Baixar e Instalar',
    'downloading': 'Baixando...',
    'installing': 'Abrindo instalador...',
    'install': 'Instalar',
    'later': 'Depois',
    'ok': 'OK',
    'cancel': 'Cancelar',
    'resumeFrom': 'Retomar de?',
    'startOver': 'Começar de Novo',
    'resume': 'Retomar',
    'episode': 'Episódio',
    'schedule': 'Horário',
    'top': 'Top',
    'latest': 'Mais Recente',
    'watchNow': 'Assistir Agora',
    'loading': 'Carregando...',
    'synopsis': 'Sinopse',
    'episodes': 'Episódios',
    'play': 'Reproduzir',
    'addToLibrary': 'Adicionar à Biblioteca',
    'removeFromLibrary': 'Remover da Biblioteca',
    'search': 'Pesquisar',
    'genres': 'Gêneros',
    'quickSearch': 'Busca Rápida',
    'library': 'Biblioteca',
    'all': 'Todos',
    'watching': 'Assistindo',
    'completed': 'Concluído',
    'onHold': 'Em Pausa',
    'dropped': 'Abandonado',
    'planToWatch': 'Planejo Assistir',
    'changeStatus': 'Alterar Status',
    'noAnimeYet': 'Nenhum anime na sua biblioteca',
    'addAnimeHint': 'Toque no ícone de favorito para adicionar',
    'watchHistory': 'Histórico',
    'episodesCount': 'episódios',
    'noHistoryYet': 'Sem histórico ainda',
    'startWatching': 'Comece a assistir anime',
    'selectServer': 'Selecionar Servidor',
    'retryAll': 'Tentar Todos',
    'allFailed': 'Todos os servidores falharam',
    'loadingEpisode': 'Carregando Episódio',
    'trying': 'Tentando AnimeHeaven, AniKoto...',
    'justNow': 'Agora',
    'noUpdate': 'Sem Atualização',
    'couldNotCheck': 'Não foi possível verificar. Verifique sua conexão.',
    'newVersion': 'Nova versão disponível',
    'currentVersion': 'Versão atual',
    'couldNotLoad': 'Não foi possível carregar detalhes',
    'confirmClearHistory': 'Limpar todo o histórico?',
    'confirmClearData': 'Isso removerá biblioteca, histórico e configurações.',
  },
  '日本語': {
    'settings': '設定',
    'general': '一般',
    'player': 'プレーヤー',
    'data': 'データ',
    'about': 'アプリについて',
    'checkUpdate': 'アップデートを確認',
    'tapToCheck': '最新バージョンを確認する',
    'appearance': '外観',
    'language': '言語',
    'theme': 'テーマ',
    'accentColor': 'アクセントカラー',
    'content': 'コンテンツ',
    'nsfwFilter': 'NSFWコンテンツを表示',
    'nsfwSubtitle': '成人向けアニメを表示',
    'playback': '再生',
    'autoRotate': '自動回転',
    'autoRotateSub': '再生中に横画面に回転',
    'videoQuality': '画質',
    'videoQualitySub': '推奨ストリーム品質',
    'preferredPlayer': '推奨プレーヤー',
    'preferredPlayerSub': 'ビデオプレーヤーを選択',
    'playerEngine': 'プレーヤーエンジン',
    'storage': 'ストレージ',
    'clearCache': 'キャッシュをクリア',
    'clearCacheSub': '一時ファイルを削除',
    'clearHistory': '視聴履歴をクリア',
    'clearHistorySub': '視聴したエピソードをすべて削除',
    'clearAllData': 'すべてのデータをクリア',
    'clearAllDataSub': 'ライブラリ、履歴、設定を削除',
    'links': 'リンク',
    'sourceCode': 'ソースコード',
    'reportIssue': '問題を報告',
    'libraries': 'ライブラリ',
    'appInfo': 'アプリ',
    'updateAvailable': 'アップデートあり',
    'upToDate': '最新です',
    'releaseNotes': 'リリースノート:',
    'downloadInstall': 'ダウンロードしてインストール',
    'downloading': 'ダウンロード中...',
    'installing': 'インストーラーを開いています...',
    'install': 'インストール',
    'later': '後で',
    'ok': 'OK',
    'cancel': 'キャンセル',
    'resumeFrom': 'ここから再開?',
    'startOver': '最初から',
    'resume': '再開',
    'episode': 'エピソード',
    'schedule': 'スケジュール',
    'top': 'トップ',
    'latest': '最新',
    'watchNow': '今すぐ見る',
    'loading': '読み込み中...',
    'synopsis': 'あらすじ',
    'episodes': 'エピソード',
    'play': '再生',
    'addToLibrary': 'ライブラリに追加',
    'removeFromLibrary': 'ライブラリから削除',
    'search': '検索',
    'genres': 'ジャンル',
    'quickSearch': 'クイック検索',
    'library': 'ライブラリ',
    'all': 'すべて',
    'watching': '視聴中',
    'completed': '完了',
    'onHold': '保留',
    'dropped': '中断',
    'planToWatch': '見る予定',
    'changeStatus': 'ステータス変更',
    'noAnimeYet': 'ライブラリにアニメがありません',
    'addAnimeHint': 'ブックマークアイコンをタップして追加',
    'watchHistory': '視聴履歴',
    'episodesCount': 'エピソード',
    'noHistoryYet': '履歴がありません',
    'startWatching': 'アニメの視聴を開始しましょう',
    'selectServer': 'サーバーを選択',
    'retryAll': 'すべて再試行',
    'allFailed': 'すべてのサーバーが失敗しました',
    'loadingEpisode': 'エピソードを読み込み中',
    'trying': 'AnimeHeaven, AniKotoを試行中...',
    'justNow': 'たった今',
    'noUpdate': '更新なし',
    'couldNotCheck': '確認できませんでした。ネット接続を確認してください。',
    'newVersion': '新しいバージョンがあります',
    'currentVersion': '現在のバージョン',
    'couldNotLoad': '詳細を読み込めませんでした',
    'confirmClearHistory': 'すべての履歴をクリアしますか？',
    'confirmClearData': 'ライブラリ、履歴、設定がすべて削除されます。',
  },
  '中文': {
    'settings': '设置',
    'general': '通用',
    'player': '播放器',
    'data': '数据',
    'about': '关于',
    'checkUpdate': '检查更新',
    'tapToCheck': '点击检查最新版本',
    'appearance': '外观',
    'language': '语言',
    'theme': '主题',
    'accentColor': '强调色',
    'content': '内容',
    'nsfwFilter': '显示NSFW内容',
    'nsfwSubtitle': '显示成人动漫',
    'playback': '播放',
    'autoRotate': '自动旋转',
    'autoRotateSub': '播放时自动横屏',
    'videoQuality': '视频质量',
    'videoQualitySub': '首选流媒体质量',
    'preferredPlayer': '首选播放器',
    'preferredPlayerSub': '选择视频播放器',
    'playerEngine': '播放器引擎',
    'storage': '存储',
    'clearCache': '清除缓存',
    'clearCacheSub': '删除临时文件',
    'clearHistory': '清除观看历史',
    'clearHistorySub': '删除所有观看记录',
    'clearAllData': '清除所有数据',
    'clearAllDataSub': '删除库、历史和设置',
    'links': '链接',
    'sourceCode': '源代码',
    'reportIssue': '报告问题',
    'libraries': '库',
    'appInfo': '应用',
    'updateAvailable': '有更新',
    'upToDate': '已是最新',
    'releaseNotes': '更新说明:',
    'downloadInstall': '下载并安装',
    'downloading': '下载中...',
    'installing': '打开安装程序...',
    'install': '安装',
    'later': '稍后',
    'ok': '确定',
    'cancel': '取消',
    'resumeFrom': '从这里继续?',
    'startOver': '从头开始',
    'resume': '继续',
    'episode': '集',
    'schedule': '时间表',
    'top': '排行',
    'latest': '最新',
    'watchNow': '立即观看',
    'loading': '加载中...',
    'synopsis': '简介',
    'episodes': '集数',
    'play': '播放',
    'addToLibrary': '添加到库',
    'removeFromLibrary': '从库中移除',
    'search': '搜索',
    'genres': '类型',
    'quickSearch': '快速搜索',
    'library': '库',
    'all': '全部',
    'watching': '观看中',
    'completed': '已完成',
    'onHold': '暂停',
    'dropped': '弃剧',
    'planToWatch': '计划观看',
    'changeStatus': '更改状态',
    'noAnimeYet': '库中还没有动漫',
    'addAnimeHint': '点击书签图标添加动漫',
    'watchHistory': '观看历史',
    'episodesCount': '集',
    'noHistoryYet': '暂无观看历史',
    'startWatching': '开始观看动漫吧',
    'selectServer': '选择服务器',
    'retryAll': '重试全部',
    'allFailed': '所有服务器均失败',
    'loadingEpisode': '正在加载第',
    'trying': '正在尝试 AnimeHeaven, AniKoto...',
    'justNow': '刚刚',
    'noUpdate': '没有更新',
    'couldNotCheck': '无法检查更新，请检查网络连接。',
    'newVersion': '有新版本可用',
    'currentVersion': '当前版本',
    'couldNotLoad': '无法加载详情',
    'confirmClearHistory': '清除所有观看历史？',
    'confirmClearData': '将删除所有库、历史和设置。',
  },
};

class L10n {
  static String _lang = 'English';
  static void setLang(String lang) => _lang = lang;
  static String t(String key) => translations[_lang]?[key] ?? translations['English']![key] ?? key;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSection = 'general';
  String _language = 'English';
  String _videoQuality = 'Auto';
  String _defaultPlayer = 'In-app Player';
  bool _autoRotate = true;
  bool _nsfwFilter = false;
  String _themeColor = 'Gold';
  String _themeName = 'Dark';
  String _appVersion = '1.2.4';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    final s = await getSettings();
    if (mounted) {
      setState(() {
        _language = s['language'] ?? 'English';
        _videoQuality = s['videoQuality'] ?? 'Auto';
        _defaultPlayer = s['player'] ?? 'In-app Player';
        _autoRotate = s['autoRotate'] ?? true;
        _nsfwFilter = s['nsfwFilter'] ?? false;
        _themeColor = s['themeColor'] ?? 'Gold';
        _themeName = s['theme'] ?? 'Dark';
        _loaded = true;
      });
      L10n.setLang(_language);
    }
  }

  Future<void> _save(String key, dynamic value) async {
    await saveSetting(key, value);
    if (key == 'themeColor') {
      NipahColors.setAccent(value as String);
      if (mounted) setState(() {});
    } else if (key == 'theme') {
      NipahColors.setTheme(value as String);
      if (mounted) setState(() {});
    } else if (key == 'language') {
      L10n.setLang(value as String);
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkForUpdate() async {
    final currentVersion = _appVersion;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: NipahLoader(size: 32)),
    );
    final update = await checkForUpdate();
    if (!mounted) return;
    Navigator.pop(context);

    if (update == null) {
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: NipahColors.surface,
        shape: const RoundedRectangleBorder(),
        title: Text('No Update', style: NipahTheme.heading(size: 18)),
        content: Text('Could not check for updates. Check your internet connection.',
          style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
          child: Text('OK', style: NipahTheme.body(color: NipahColors.gold)))],
      ));
      return;
    }

    final latestVersion = update['version'] ?? '';
    final hasUpdate = latestVersion.isNotEmpty && latestVersion != currentVersion;
    showDialog(context: context, builder: (_) => _UpdateDialog(
      hasUpdate: hasUpdate,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseName: update['name'] ?? '',
      releaseNotes: update['body'] ?? '',
      apkUrl: update['apkUrl'],
      apkSize: update['apkSize'],
    ));
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync(recursive: true);
      int count = 0;
      for (final file in files) {
        try { await file.delete(); count++; } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cleared $count cache files'),
          backgroundColor: NipahColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: NipahColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(backgroundColor: NipahColors.bg, body: const Center(child: NipahLoader(size: 28)));
    }

    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(L10n.t('settings'), style: NipahTheme.heading(size: 28)),
                  const Spacer(),
                  Text('v$_appVersion', style: NipahTheme.label(size: 10, color: NipahColors.textDim)),
                ],
              ),
            ),
            _buildSectionTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildSectionContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTabs() {
    final sections = [
      {'id': 'general', 'icon': Icons.settings_outlined, 'label': L10n.t('general')},
      {'id': 'player', 'icon': Icons.play_circle_outline, 'label': L10n.t('player')},
      {'id': 'data', 'icon': Icons.storage_outlined, 'label': L10n.t('data')},
      {'id': 'about', 'icon': Icons.info_outline, 'label': L10n.t('about')},
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: NipahColors.lineSoft))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final s = sections[index];
          final isSelected = _selectedSection == s['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedSection = s['id'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isSelected ? NipahColors.gold : Colors.transparent, width: 2)),
              ),
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, size: 16, color: isSelected ? NipahColors.gold : NipahColors.textDim),
                  const SizedBox(width: 6),
                  Text(s['label'] as String, style: NipahTheme.label(size: 10, color: isSelected ? NipahColors.gold : NipahColors.textDim)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 'general': return _buildGeneralSection();
      case 'player': return _buildPlayerSection();
      case 'data': return _buildDataSection();
      case 'about': return _buildAboutSection();
      default: return _buildGeneralSection();
    }
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUpdateCard(),
        const SizedBox(height: 16),
        _sectionTitle(L10n.t('appearance')),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.language, title: L10n.t('language'),
          child: _buildDropdown(value: _language, items: ['English', 'Español', 'Português', '日本語', '中文'],
            onChanged: (v) { setState(() => _language = v ?? 'English'); _save('language', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.palette, title: L10n.t('theme')),
        _buildThemeGrid(),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.color_lens, title: L10n.t('accentColor')),
        _buildAccentColorGrid(),
        const SizedBox(height: 16),
        _sectionTitle(L10n.t('content')),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.filter_list, title: L10n.t('nsfwFilter'),
          subtitle: L10n.t('nsfwSubtitle'),
          trailing: _buildToggle(value: _nsfwFilter, onChanged: (v) { setState(() => _nsfwFilter = v); _save('nsfwFilter', v); })),
      ],
    );
  }

  Widget _buildUpdateCard() {
    return GestureDetector(
      onTap: _checkForUpdate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [NipahColors.accent.main, NipahColors.accent.strong]),
          border: Border.all(color: NipahColors.accent.strong),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: NipahColors.bg.withValues(alpha: 0.3)),
              child: Icon(Icons.system_update, color: NipahColors.bg, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.t('checkUpdate'), style: NipahTheme.heading(size: 16, color: NipahColors.bg)),
                  const SizedBox(height: 2),
                  Text(L10n.t('tapToCheck'), style: NipahTheme.body(size: 11, color: NipahColors.bg.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: NipahColors.bg, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(L10n.t('playback')),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.screen_rotation, title: L10n.t('autoRotate'),
          subtitle: L10n.t('autoRotateSub'),
          trailing: _buildToggle(value: _autoRotate, onChanged: (v) { setState(() => _autoRotate = v); _save('autoRotate', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.high_quality, title: L10n.t('videoQuality'),
          subtitle: L10n.t('videoQualitySub'),
          child: _buildDropdown(value: _videoQuality, items: ['Auto', '1080p', '720p', '480p', '360p'],
            onChanged: (v) { setState(() => _videoQuality = v ?? 'Auto'); _save('videoQuality', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.play_circle, title: L10n.t('preferredPlayer'),
          subtitle: L10n.t('preferredPlayerSub'),
          child: _buildDropdown(value: _defaultPlayer, items: ['In-app Player', 'External Player'],
            onChanged: (v) { setState(() => _defaultPlayer = v ?? 'In-app Player'); _save('player', v); })),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.info_outline, title: L10n.t('playerEngine'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: NipahColors.success.withValues(alpha: 0.1), border: Border.all(color: NipahColors.success)),
            child: Text('MediaKit', style: NipahTheme.label(size: 9, color: NipahColors.success)),
          )),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(L10n.t('storage')),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _clearCache,
          child: _settingRow(icon: Icons.cleaning_services, title: L10n.t('clearCache'),
            subtitle: L10n.t('clearCacheSub'),
            trailing: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 20)),
        ),
        Divider(color: NipahColors.lineSoft),
        GestureDetector(
          onTap: () => _showClearHistoryDialog(),
          child: _settingRow(icon: Icons.history, title: L10n.t('clearHistory'),
            subtitle: L10n.t('clearHistorySub'),
            trailing: Icon(Icons.chevron_right, color: NipahColors.textDim, size: 20)),
        ),
        Divider(color: NipahColors.lineSoft),
        GestureDetector(
          onTap: () => _showClearDataDialog(),
          child: _settingRow(icon: Icons.delete_forever, title: L10n.t('clearAllData'),
            subtitle: L10n.t('clearAllDataSub'),
            iconColor: NipahColors.danger,
            trailing: Icon(Icons.chevron_right, color: NipahColors.danger, size: 20)),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(L10n.t('appInfo')),
        const SizedBox(height: 12),
        _buildAppInfoCard(),
        const SizedBox(height: 16),
        _sectionTitle(L10n.t('libraries')),
        const SizedBox(height: 8),
        _settingRow(icon: Icons.movie, title: 'MediaKit', subtitle: 'Video player engine'),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.wifi, title: 'AniList API', subtitle: 'Anime data source'),
        Divider(color: NipahColors.lineSoft),
        _settingRow(icon: Icons.storage, title: 'Shared Preferences', subtitle: 'Local storage'),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: NipahTheme.label(size: 11));

  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NipahTheme.sectionCardDecoration,
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [NipahColors.gold, NipahColors.goldStrong])),
            child: Icon(Icons.movie_filter, color: NipahColors.bg, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AnimoBox', style: NipahTheme.heading(size: 18)),
                const SizedBox(height: 2),
                Text('Version $_appVersion', style: NipahTheme.body(size: 12, color: NipahColors.textDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({required IconData icon, required String title, String? subtitle, Widget? child, Widget? trailing, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? NipahColors.textDim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NipahTheme.body(size: 14, weight: FontWeight.w500, color: NipahColors.text)),
                if (subtitle != null) Text(subtitle, style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
              ],
            ),
          ),
          if (child != null) child,
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildThemeGrid() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 8),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: appThemes.map((t) {
          final isSelected = _themeName == t.name;
          return GestureDetector(
            onTap: () { setState(() => _themeName = t.name); _save('theme', t.name); },
            child: Container(
              width: 72, height: 56,
              decoration: BoxDecoration(color: t.surface, border: Border.all(
                color: isSelected ? NipahColors.gold : t.cardBorder, width: isSelected ? 2 : 1)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.name, style: TextStyle(color: t.text, fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 6, height: 6, color: t.bg),
                    const SizedBox(width: 2),
                    Container(width: 6, height: 6, color: t.surface2),
                    const SizedBox(width: 2),
                    Container(width: 6, height: 6, color: t.text),
                  ]),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccentColorGrid() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 8),
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: accentPalette.map((accent) {
          final isSelected = _themeColor == accent.name;
          return GestureDetector(
            onTap: () { setState(() => _themeColor = accent.name); _save('themeColor', accent.name); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: accent.main, border: Border.all(
                color: isSelected ? NipahColors.text : Colors.transparent, width: 2)),
              child: isSelected ? Icon(Icons.check, color: NipahColors.bg, size: 18) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: NipahColors.surface2, border: Border.all(color: NipahColors.lineSoft)),
      child: DropdownButton<String>(
        value: value, isDense: true, isExpanded: false,
        dropdownColor: NipahColors.surface, underline: const SizedBox(),
        style: NipahTheme.label(size: 10, color: NipahColors.text),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggle({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 40, height: 22,
        decoration: BoxDecoration(
          color: value ? NipahColors.gold : NipahColors.surface2,
          border: Border.all(color: value ? NipahColors.gold : NipahColors.lineSoft)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 3), color: value ? NipahColors.bg : NipahColors.textDim),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: NipahColors.surface, shape: const RoundedRectangleBorder(),
      title: Text(L10n.t('clearHistory'), style: NipahTheme.heading(size: 18)),
      content: Text(L10n.t('clearHistorySub'), style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.t('cancel'), style: NipahTheme.body(color: NipahColors.textDim))),
        TextButton(onPressed: () async { await clearHistory(); if (context.mounted) Navigator.pop(context); },
          child: Text('Clear', style: NipahTheme.body(color: NipahColors.danger))),
      ],
    ));
  }

  void _showClearDataDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: NipahColors.surface, shape: const RoundedRectangleBorder(),
      title: Text(L10n.t('clearAllData'), style: NipahTheme.heading(size: 18)),
      content: Text(L10n.t('clearAllDataSub'), style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.t('cancel'), style: NipahTheme.body(color: NipahColors.textDim))),
        TextButton(onPressed: () async { await clearAllData(); if (context.mounted) Navigator.pop(context); },
          child: Text('Clear All', style: NipahTheme.body(color: NipahColors.danger))),
      ],
    ));
  }
}

class _UpdateDialog extends StatefulWidget {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String? apkUrl;
  final int? apkSize;

  const _UpdateDialog({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    this.apkUrl,
    this.apkSize,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  bool _installing = false;
  bool _downloadDone = false;
  double _progress = 0;
  String _filePath = '';

  @override
  void initState() {
    super.initState();
    if (widget.hasUpdate && widget.apkUrl != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _downloadApk();
      });
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _downloadApk() async {
    if (widget.apkUrl == null) return;
    setState(() { _downloading = true; _progress = 0; });
    try {
      String dirPath;
      try {
        final dir = await getExternalStorageDirectory();
        dirPath = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
      } catch (_) {
        dirPath = (await getApplicationDocumentsDirectory()).path;
      }
      _filePath = '$dirPath/AnimoBox-${widget.latestVersion}.apk';
      final file = File(_filePath);
      final request = http.Request('GET', Uri.parse(widget.apkUrl!));
      final response = await http.Client().send(request);
      final contentLength = response.contentLength ?? 0;
      int received = 0;
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() => _progress = received / contentLength);
        }
      }
      await sink.close();
      if (mounted) {
        setState(() { _downloading = false; _downloadDone = true; _progress = 1; });
        await _installApk();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e'), backgroundColor: NipahColors.danger));
      }
    }
  }

  Future<void> _installApk() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final result = await OpenFile.open(_filePath);
        if (mounted) {
          setState(() => _installing = false);
          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Could not open installer: ${result.message}'),
              backgroundColor: NipahColors.danger,
            ));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _installing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Install failed: $e'),
          backgroundColor: NipahColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NipahColors.surface,
      shape: const RoundedRectangleBorder(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.hasUpdate ? Icons.system_update : Icons.check_circle_outline,
            color: widget.hasUpdate ? NipahColors.gold : NipahColors.success, size: 48),
          const SizedBox(height: 16),
          Text(widget.hasUpdate ? L10n.t('updateAvailable') : L10n.t('upToDate'), style: NipahTheme.heading(size: 20)),
          const SizedBox(height: 8),
          Text(widget.hasUpdate ? 'v${widget.currentVersion} \u2192 v${widget.latestVersion}' : 'Version ${widget.currentVersion}',
            style: NipahTheme.body(size: 13, color: NipahColors.textDim)),
          if (widget.apkSize != null) ...[
            const SizedBox(height: 4),
            Text(_formatSize(widget.apkSize), style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
          ],
          if (widget.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text(L10n.t('releaseNotes'), style: NipahTheme.label(size: 10, color: NipahColors.textDim))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: NipahColors.surface2, border: Border.all(color: NipahColors.lineSoft)),
              child: SingleChildScrollView(child: Text(widget.releaseNotes, style: NipahTheme.body(size: 12, color: NipahColors.textSoft))),
            ),
          ],
          if (_downloading || _installing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null,
              backgroundColor: NipahColors.surface2, valueColor: AlwaysStoppedAnimation<Color>(NipahColors.gold), minHeight: 4),
            const SizedBox(height: 8),
            Text(_installing ? L10n.t('installing') : '${(_progress * 100).toStringAsFixed(0)}%',
              style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: (_downloading || _installing) ? null : () => Navigator.pop(context),
          child: Text(widget.hasUpdate ? L10n.t('later') : L10n.t('ok'), style: NipahTheme.body(color: NipahColors.textDim))),
        if (widget.hasUpdate && widget.apkUrl != null)
          TextButton(
            onPressed: (_downloading || _installing) ? null : (_downloadDone ? _installApk : _downloadApk),
            child: Text(
              _installing ? L10n.t('installing') : _downloading ? L10n.t('downloading') : _downloadDone ? L10n.t('install') : L10n.t('downloadInstall'),
              style: NipahTheme.label(size: 11, color: NipahColors.gold)),
          ),
      ],
    );
  }
}

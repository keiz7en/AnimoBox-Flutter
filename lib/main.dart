import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'api.dart';
import 'theme/nipah_theme.dart';
import 'pages/home.dart';
import 'pages/search.dart';
import 'pages/library.dart';
import 'pages/history.dart';
import 'pages/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final settings = await getSettings();
  NipahColors.setTheme(settings['theme'] ?? 'Dark');
  NipahColors.setAccent(settings['themeColor'] ?? 'Gold');
  L10n.setLang(settings['language'] ?? 'English');

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NipahColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const AnimoBoxApp());
}

class AnimoBoxApp extends StatelessWidget {
  const AnimoBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimoBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: NipahColors.bg,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).copyWith(
          headlineLarge: NipahTheme.heading(size: 32),
          headlineMedium: NipahTheme.heading(size: 24),
          titleLarge: NipahTheme.heading(size: 20, letterSpacing: -0.04),
          titleMedium: NipahTheme.body(size: 16, weight: FontWeight.w600),
          bodyLarge: NipahTheme.body(size: 16),
          bodyMedium: NipahTheme.body(size: 14),
          bodySmall: NipahTheme.body(size: 12, color: NipahColors.textDim),
          labelLarge: NipahTheme.body(size: 13, weight: FontWeight.w700),
        ),
        colorScheme: ColorScheme.dark(
          primary: NipahColors.gold,
          secondary: NipahColors.goldStrong,
          surface: NipahColors.surface,
          error: NipahColors.danger,
          onPrimary: NipahColors.bg,
          onSecondary: NipahColors.bg,
          onSurface: NipahColors.text,
        ),
        cardTheme: CardThemeData(
          color: NipahColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: NipahColors.cardBorder),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: NipahColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: NipahTheme.heading(size: 20),
        ),
        dividerTheme: DividerThemeData(
          color: NipahColors.rowDivider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: NipahColors.surface,
          contentTextStyle: NipahTheme.body(color: NipahColors.text),
          shape: const RoundedRectangleBorder(),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: NipahColors.surface,
          shape: const RoundedRectangleBorder(),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: NipahColors.surface,
          shape: const RoundedRectangleBorder(),
          modalBarrierColor: Colors.black54,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;
      try {
        final info = await PackageInfo.fromPlatform();
        final update = await checkForUpdate();
        if (update != null && mounted) {
          final latest = update['version'] ?? '';
          if (needsForceUpdate(info.version, latest)) {
            if (!mounted) return;
            _showForceUpdateDialog(update);
            return;
          }
        }
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showForceUpdateDialog(Map<String, dynamic> update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ForceUpdateDialog(apkUrl: update['apkUrl'], latestVersion: update['version'] ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NipahColors.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [NipahColors.gold, NipahColors.goldStrong],
                        ),
                      ),
                      child: Icon(Icons.movie_filter, color: NipahColors.bg, size: 42),
                    ),
                    const SizedBox(height: 20),
                    Text('AnimoBox', style: NipahTheme.heading(size: 26)),
                    const SizedBox(height: 6),
                    Text('ANIME STREAMING', style: NipahTheme.label(size: 10, color: NipahColors.textDim)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ForceUpdateDialog extends StatefulWidget {
  final String? apkUrl;
  final String latestVersion;
  const _ForceUpdateDialog({this.apkUrl, required this.latestVersion});

  @override
  State<_ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<_ForceUpdateDialog> {
  bool _downloading = false;
  bool _downloadDone = false;
  double _progress = 0;
  String _filePath = '';

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
        _installApk();
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
        await OpenFile.open(_filePath);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: NipahColors.surface,
        shape: const RoundedRectangleBorder(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.system_update, color: NipahColors.gold, size: 48),
            const SizedBox(height: 16),
            Text(L10n.t('forceUpdate'), style: NipahTheme.heading(size: 20)),
            const SizedBox(height: 8),
            Text(L10n.t('forceUpdateMsg'), style: NipahTheme.body(size: 13, color: NipahColors.textDim), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('v${widget.latestVersion}', style: NipahTheme.label(size: 11, color: NipahColors.gold)),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null,
                backgroundColor: NipahColors.surface2, valueColor: AlwaysStoppedAnimation<Color>(NipahColors.gold), minHeight: 4),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toStringAsFixed(0)}%', style: NipahTheme.body(size: 11, color: NipahColors.textDim)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _downloading ? null : (_downloadDone ? _installApk : _downloadApk),
            child: Text(
              _downloadDone ? L10n.t('install') : _downloading ? L10n.t('downloading') : L10n.t('downloadInstall'),
              style: NipahTheme.label(size: 11, color: NipahColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final _pages = const [
    HomePage(),
    SearchPage(),
    LibraryPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  final _icons = const [
    Icons.home_outlined,
    Icons.search,
    Icons.library_books_outlined,
    Icons.history_outlined,
    Icons.settings_outlined,
  ];
  final _selectedIcons = const [
    Icons.home,
    Icons.search,
    Icons.library_books,
    Icons.history,
    Icons.settings,
  ];
  final _labels = const ['Home', 'Search', 'Library', 'History', 'Settings'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NipahColors.surface,
          border: Border(
            top: BorderSide(color: NipahColors.lineSoft, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(5, (i) {
                final isSelected = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentIndex = i);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? _selectedIcons[i] : _icons[i],
                              key: ValueKey('$i-$isSelected'),
                              size: 22,
                              color: isSelected ? NipahColors.gold : NipahColors.textDim,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: NipahTheme.label(
                              size: 10,
                              color: isSelected ? NipahColors.gold : NipahColors.textDim,
                            ),
                            child: Text(_labels[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

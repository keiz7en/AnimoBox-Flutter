import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
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

    Future.delayed(const Duration(milliseconds: 1000), () {
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
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
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
                      _pageController.jumpToPage(i);
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

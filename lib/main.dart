import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'pages/home_page.dart';
import 'pages/add_book_page.dart';
import 'pages/my_books_page.dart';
import 'pages/currently_reading_page.dart';
import 'pages/settings_page.dart';
import 'pages/ai_exam_page.dart';
import 'services/notification_service.dart';

// Liquid Glass Color Schemes inspired by iOS 26 Tahoe
final ColorScheme liquidLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF007AFF), // iOS Blue
  onPrimary: Colors.white,
  secondary: Color(0xFF5856D6), // iOS Purple
  onSecondary: Colors.white,
  tertiary: Color(0xFF00C7BE), // iOS Teal
  onTertiary: Colors.white,
  error: Color(0xFFFF3B30), // iOS Red
  onError: Colors.white,
  background: Color(0xFFF2F2F7), // iOS Light Background
  onBackground: Color(0xFF1D1D1F),
  surface: Color(0xFFFFFFFF).withOpacity(0.7), // Translucent white
  onSurface: Color(0xFF1D1D1F),
  surfaceVariant: Color(0xFFFFFFFF).withOpacity(0.5),
  onSurfaceVariant: Color(0xFF1D1D1F),
  outline: Color(0xFF8E8E93),
  shadow: Color(0xFF000000).withOpacity(0.1),
);

final ColorScheme liquidDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF0A84FF), // iOS Blue Dark
  onPrimary: Colors.white,
  secondary: Color(0xFF5E5CE6), // iOS Purple Dark
  onSecondary: Colors.white,
  tertiary: Color(0xFF64D2FF), // iOS Teal Dark
  onTertiary: Colors.black,
  error: Color(0xFFFF453A), // iOS Red Dark
  onError: Colors.white,
  background: Color(0xFF000000), // Pure black background
  onBackground: Color(0xFFFFFFFF),
  surface: Color(0xFF1C1C1E).withOpacity(0.7), // Translucent dark
  onSurface: Color(0xFFFFFFFF),
  surfaceVariant: Color(0xFF2C2C2E).withOpacity(0.5),
  onSurfaceVariant: Color(0xFFFFFFFF),
  outline: Color(0xFF8E8E93),
  shadow: Color(0xFF000000).withOpacity(0.3),
);

// Theme mode notifier for global theme switching
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeModeNotifier.addListener(_onThemeModeChanged);
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_onThemeModeChanged);
    super.dispose();
  }

  void _onThemeModeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextChapter',
      theme: ThemeData(
        colorScheme: liquidLightColorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: liquidLightColorScheme.onBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: liquidLightColorScheme.onBackground,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: liquidLightColorScheme.primary.withOpacity(0.8),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: liquidLightColorScheme.primary,
            side: BorderSide(
                color: liquidLightColorScheme.primary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: liquidLightColorScheme.primary.withOpacity(0.9),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: liquidLightColorScheme.primary,
          unselectedItemColor: liquidLightColorScheme.outline,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        colorScheme: liquidDarkColorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: liquidDarkColorScheme.onBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            color: liquidDarkColorScheme.onBackground,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: liquidDarkColorScheme.primary.withOpacity(0.8),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: liquidDarkColorScheme.primary,
            side: BorderSide(
                color: liquidDarkColorScheme.primary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: liquidDarkColorScheme.primary.withOpacity(0.9),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: liquidDarkColorScheme.primary,
          unselectedItemColor: liquidDarkColorScheme.outline,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      themeMode: themeModeNotifier.value,
      home: const LiquidGlassWrapper(child: MainNavigation()),
    );
  }
}

// Liquid Glass Wrapper with gradient background
class LiquidGlassWrapper extends StatelessWidget {
  final Widget child;

  const LiquidGlassWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF1A1A1A),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.5, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF2F2F7),
                  Color(0xFFE5E5EA),
                  Color(0xFFF2F2F7),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
      ),
      child: child,
    );
  }
}

// Glass Card Component
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 10,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.15);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: Offset(0, 12),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.8),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur * 2, sigmaY: blur * 2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.02),
                        Colors.white.withOpacity(0.06),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.25),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
            ),
            padding: padding ?? EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _navigateToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  static List<Widget> _getPages(_MainNavigationState state) => [
        HomePage(), // Index 0 - Home
        MyBooksPage(), // Index 1 - Meine Bücher
        AddBookPage(
            onNavigateBack: state._navigateToHome), // Index 2 - Hinzufügen
        AIExamPage(), // Index 3 - KI
        SettingsPage(), // Index 4 - Einstellungen
      ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < 5) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages(this);
    return Scaffold(
      extendBody: true,
      body: _selectedIndex < pages.length ? pages[_selectedIndex] : pages[0],
      bottomNavigationBar: _buildGlassBottomNavBar(context),
    );
  }

  Widget _buildGlassBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.08),
            blurRadius: 35,
            offset: Offset(0, 15),
            spreadRadius: -10,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.9),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.03),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.outline,
              currentIndex: _selectedIndex.clamp(0, 4),
              onTap: _onItemTapped,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded),
                  label: 'Meine Bücher',
                ),
                BottomNavigationBarItem(
                    icon: Icon(Icons.add_rounded), label: 'Hinzufügen'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.school_rounded), label: 'KI'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Einstellungen',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

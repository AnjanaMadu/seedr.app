import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/seedr.dart';
import 'service/logging_service.dart';
import 'service/settings_service.dart';
import 'ui/login_screen.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoggingService()),
        ChangeNotifierProvider(create: (_) => SettingsService(prefs)),
        ProxyProvider2<LoggingService, SettingsService, Seedr>(
          update: (_, logger, settings, __) {
            final seedr = Seedr(logger: logger);
            seedr.onTokenRefresh = (access, refresh) {
              settings.setTokens(access, refresh);
            };
            if (settings.token != null) {
              seedr.token = settings.token;
            }
            if (settings.refreshToken != null) {
              seedr.rft = settings.refreshToken;
            }
            return seedr;
          },
        ),
      ],
      child: const SeedrApp(),
    ),
  );
}

class SeedrApp extends StatelessWidget {
  const SeedrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return MaterialApp(
      title: 'Seedr Android',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: settings.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorSchemeSeed: Colors.deepPurple,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(baseTheme.textTheme),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}

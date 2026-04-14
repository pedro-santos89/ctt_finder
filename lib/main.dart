/// CTT Finder — Main application entry point.
///
/// This file bootstraps the Flutter application, configures the global theme
/// (custom CTT fonts, Material 3 colour scheme) and wraps the widget tree
/// with [AppLocalizations] so that every descendant can access the current
/// locale and switch between Portuguese and English at runtime.
///
/// Developed by Anima Rasa Prod.
library;

import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'services/app_localizations.dart';

/// Application entry point.
void main() {
  runApp(const CttFinderApp());
}

/// Root widget of the CTT Finder application.
///
/// Uses a [StatefulWidget] to hold the current [Locale] so the entire
/// widget tree rebuilds whenever the user toggles the language.
class CttFinderApp extends StatefulWidget {
  const CttFinderApp({super.key});

  @override
  State<CttFinderApp> createState() => _CttFinderAppState();
}

class _CttFinderAppState extends State<CttFinderApp> {
  /// Currently active locale — defaults to Portuguese.
  Locale _locale = const Locale('pt');

  /// Callback passed down via [AppLocalizations] so any widget can
  /// request a language change.
  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return AppLocalizations(
      locale: _locale,
      onLocaleChanged: _setLocale,
      child: MaterialApp(
        title: 'CTT Finder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'ActoCTT-Medium',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD32F2F),
            primary: const Color(0xFFD32F2F),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}

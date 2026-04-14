/// Welcome / landing screen.
///
/// Displays the CTT Finder branding (logo, title, subtitle),
/// a language-toggle button and a call-to-action that navigates to
/// [MapScreen] with the filter sheet pre-opened.
library;

import 'package:flutter/material.dart';
import '../services/app_localizations.dart';
import 'map_screen.dart';

/// Full-screen welcome page with a red gradient background.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD32F2F),
              Color(0xFFB71C1C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Language button top-right
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _LanguageButton(l: l),
                ),
              ),

              const Spacer(flex: 2),

              // App icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_post_office,
                    size: 56,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App title
              const Text(
                'CTT Finder',
                style: TextStyle(
                  fontFamily: 'ActoCTT-Bold',
                  fontSize: 48,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  l.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Main button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const MapScreen(openFilters: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      l.welcomeButton,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Creator signature
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Anima Rasa Prod. 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact language-toggle button ("EN" / "PT").
///
/// Placed in the top-right corner of the welcome screen.
class _LanguageButton extends StatelessWidget {
  final AppLocalizations l;

  const _LanguageButton({required this.l});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final newLocale =
              l.isPt ? const Locale('en') : const Locale('pt');
          l.onLocaleChanged(newLocale);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                l.isPt ? 'EN' : 'PT',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

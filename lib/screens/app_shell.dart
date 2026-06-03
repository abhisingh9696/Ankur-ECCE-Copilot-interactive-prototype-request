import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/translations.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'record_screen.dart';
import 'result_screen.dart';
import 'referral_screen.dart';
import 'add_child_screen.dart';
import '../widgets/crypto_sandbox.dart';
import '../widgets/pitch_slides.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 768;

            if (isWide) {
              return _buildWideLayout(context);
            }
            return _buildMobileLayout(context);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Status bar
            _buildStatusBar(context, provider),
            // Main content based on screen
            Expanded(
              child: _buildCurrentScreen(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            // Phone emulator panel
            Expanded(
              flex: 5,
              child: Container(
                color: const Color(0xFF1E293B),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 390,
                      maxHeight: 760,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: const Color(0xFF334155), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: Column(
                        children: [
                          // Status bar space
                          Container(
                            height: 32,
                            color: const Color(0xFF0284C7),
                            child: Center(
                              child: Container(
                                width: 140,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          _buildStatusBar(context, provider),
                          Expanded(
                            child: _buildCurrentScreen(provider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Dashboard panel
            Expanded(
              flex: 6,
              child: Container(
                color: const Color(0xFF0F172A),
                child: provider.showSandbox
                    ? CryptoSandbox(
                        logs: provider.cryptoLogs,
                        language: provider.language,
                        onToggle: provider.toggleSandbox,
                      )
                    : PitchSlides(
                        language: provider.language,
                        onToggle: provider.toggleSandbox,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBar(BuildContext context, AppProvider provider) {
    final lang = provider.language;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t('appName', lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  t('centre', lang),
                  style: const TextStyle(
                    color: Color(0xFFBAE6FD),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Language selector
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(
                lang == 'hi'
                    ? 'हि'
                    : lang == 'ta'
                        ? 'த'
                        : lang == 'gu'
                            ? 'ગુ'
                            : 'EN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              provider.setLanguage(value);
            },
            itemBuilder: (context) => supportedLanguages.map((l) {
              return PopupMenuItem<String>(
                value: l['code'],
                child: Row(
                  children: [
                    Text(
                      l['native']!,
                      style: TextStyle(
                        color: provider.language == l['code']
                            ? const Color(0xFF38BDF8)
                            : Colors.white,
                        fontWeight: provider.language == l['code']
                            ? FontWeight.w800
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l['name']!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          // Outbox count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_sync, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${provider.outboxCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen(AppProvider provider) {
    switch (provider.currentScreen) {
      case 'home':
        return const HomeScreen();
      case 'profile':
        if (provider.selectedChild == null) return const HomeScreen();
        return const ProfileScreen();
      case 'record':
        return const RecordScreen();
      case 'result':
        return const ResultScreen();
      case 'referral':
        return const ReferralScreen();
      case 'add_child':
        return const AddChildScreen();
      default:
        return const HomeScreen();
    }
  }
}

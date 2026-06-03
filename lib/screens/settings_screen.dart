import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/translations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.language;

        return Container(
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => provider.goBack(),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back_ios,
                                size: 16, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              t('home', lang),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        t('settings', lang),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ═══ Language Section ═══
                      _sectionHeader(t('selectLanguage', lang)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: supportedLanguages.map((l) {
                            final isSelected = provider.language == l['code'];
                            return InkWell(
                              onTap: () => provider.setLanguage(l['code']!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: l != supportedLanguages.last
                                      ? Border(
                                          bottom: BorderSide(
                                              color: Colors.grey[100]!))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE0F2FE)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          l['native']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? const Color(0xFF0284C7)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${l['name']} (${l['native']})',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle,
                                          color: Color(0xFF0284C7), size: 20),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ═══ Sync Status Section ═══
                      _sectionHeader(t('syncDashboard', lang)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _syncRow(
                              icon: Icons.cloud_outlined,
                              label: t('pendingSync', lang),
                              value: '${provider.outboxCount}',
                              valueColor: provider.outboxCount > 0
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF059669),
                            ),
                            const Divider(height: 20),
                            _syncRow(
                              icon: Icons.visibility_outlined,
                              label: t('totalObservations', lang),
                              value: '${_totalObservations(provider)}',
                              valueColor: const Color(0xFF475569),
                            ),
                            const Divider(height: 20),
                            _syncRow(
                              icon: Icons.people_outline,
                              label: t('childrenCount', lang),
                              value: '${provider.children.length}',
                              valueColor: const Color(0xFF475569),
                            ),
                            const Divider(height: 20),
                            _syncRow(
                              icon: Icons.info_outline,
                              label: t('versionInfo', lang),
                              value: 'v1.0.0-prototype',
                              valueColor: Colors.grey[400]!,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sync Now button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _performSync(context, provider, lang),
                          icon: const Icon(Icons.sync, size: 18),
                          label: Text(
                            t('syncNow', lang),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ═══ Model Status Section ═══
                      _sectionHeader(t('modelStatus', lang)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _modelRow(
                              icon: Icons.mic,
                              label: t('asrModel', lang),
                              value: 'Deepgram Nova-2 (REST)',
                              status: t('online', lang),
                              statusColor: const Color(0xFF059669),
                            ),
                            const Divider(height: 20),
                            _modelRow(
                              icon: Icons.wifi_off,
                              label: t('offlineModel', lang),
                              value: t('simulationFallback', lang),
                              status: t('ready', lang),
                              statusColor: const Color(0xFF0284C7),
                            ),
                            const Divider(height: 20),
                            _modelRow(
                              icon: Icons.psychology,
                              label: t('domainModel', lang),
                              value: t('keywordClassifier', lang),
                              status: t('active', lang),
                              statusColor: const Color(0xFF059669),
                            ),
                            const Divider(height: 20),
                            _modelRow(
                              icon: Icons.record_voice_over,
                              label: t('ttsModel', lang),
                              value: 'Flutter TTS',
                              status: t('ready', lang),
                              statusColor: const Color(0xFF0284C7),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ═══ Privacy Section ═══
                      _sectionHeader(t('privacySection', lang)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => provider.navigateTo('consent'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.privacy_tip_outlined,
                                        color: Color(0xFF475569), size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        t('viewPrivacyPolicy', lang),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: Color(0xFF94A3B8), size: 20),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => provider.exportData(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    const Icon(Icons.file_download_outlined,
                                        color: Color(0xFF475569), size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        t('exportCSV', lang),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: Color(0xFF94A3B8), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _totalObservations(AppProvider provider) {
    int count = 0;
    for (final child in provider.children) {
      count += child.observations.length;
    }
    return count;
  }

  Future<void> _performSync(
      BuildContext context, AppProvider provider, String lang) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('syncing', lang)),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    provider.syncNow();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('syncingComplete', lang)),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _syncRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _modelRow({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

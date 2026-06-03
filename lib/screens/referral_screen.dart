import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/translations.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final child = provider.selectedChild;
        if (child == null) return const SizedBox.shrink();
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
                              t('devProfile', lang),
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

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.description_outlined,
                                color: Color(0xFFDC2626), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RBSK Referral Document',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Referral document card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ref code header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${t('refCode', lang)}: RBSK-2026-X8',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Text(
                                    t('statusPending', lang),
                                    style: const TextStyle(
                                      color: Color(0xFFD97706),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Pseudonymized ID section
                            _buildField(
                              t('pseudoId', lang),
                              child.pseudoId,
                              isCode: true,
                            ),
                            const SizedBox(height: 14),

                            // Demographics
                            _buildField(
                              t('demographics', lang),
                              '${child.gender} \u2022 ${child.age}',
                            ),
                            const SizedBox(height: 14),

                            // Justification
                            _buildField(
                              t('justification', lang),
                              provider.generateReferralReason(),
                              highlight: true,
                            ),
                            const SizedBox(height: 14),

                            // Recipient
                            _buildField(
                              t('recipient', lang),
                              t('recipientName', lang),
                            ),
                            const Divider(height: 24),

                            // Encryption note
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFBAE6FD)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.shield,
                                      size: 16, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t('encryptionNote', lang),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF0369A1),
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
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

              // Share button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => provider.completeReferral(),
                      icon: const Icon(Icons.share, size: 18),
                      label: Text(
                        t('shareReferral', lang),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(String label, String value,
      {bool isCode = false, bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCode ? FontWeight.w800 : FontWeight.w600,
              color: highlight
                  ? const Color(0xFF991B1B)
                  : const Color(0xFF1E293B),
              fontFamily: isCode ? 'monospace' : null,
              fontStyle: highlight ? FontStyle.italic : null,
              letterSpacing: isCode ? 1 : 0,
            ),
          ),
        ),
      ],
    );
  }
}

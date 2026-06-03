import 'package:flutter/material.dart';
import '../services/translations.dart';

class PitchSlides extends StatelessWidget {
  final String language;
  final VoidCallback onToggle;

  const PitchSlides({
    super.key,
    required this.language,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final lang = language;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('pitchDashboard', lang),
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('pitchTitle', lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.code,
                          color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        t('showSandbox', lang),
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Slide 1: The Crisis
          _buildSlide(
            icon: Icons.warning_rounded,
            iconColor: const Color(0xFFEF4444),
            title: t('crisisTitle', lang),
            body: [
              _buildParagraph(t('crisisDesc', lang)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      t('neuroRisk', lang),
                      t('neuroRiskValue', lang),
                      t('neuroRiskDesc', lang),
                      const Color(0xFF991B1B),
                      const Color(0xFFFEF2F2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      t('heckmanTitle', lang),
                      t('heckmanValue', lang),
                      t('heckmanDesc', lang),
                      const Color(0xFF0284C7),
                      const Color(0xFFF0F9FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slide 2: The Solution
          _buildSlide(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF10B981),
            title: t('solutionTitle', lang),
            body: [
              _buildParagraph(t('solutionDesc', lang)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPillCard(
                      t('offline100', lang),
                      t('offline100desc', lang),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPillCard(
                      t('zeroAudio', lang),
                      t('zeroAudiodesc', lang),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPillCard(
                      t('lowCost', lang),
                      t('lowCostdesc', lang),
                      highlight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slide 3: Hardware
          _buildSlide(
            icon: Icons.memory,
            iconColor: const Color(0xFF0284C7),
            title: t('hardwareTitle', lang),
            body: [
              _buildParagraph(t('hardwareDesc', lang)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    _buildSpec('TFLite Model', '<15 MB'),
                    _buildSpec('Inference', '<10 ms'),
                    _buildSpec('RAM Usage', '~3 MB'),
                    _buildSpec('Cost', '₹0.01/obs'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slide 4: Architecture
          _buildSlide(
            icon: Icons.account_tree,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Pipeline Architecture',
            body: [
              _buildPipelineStep('01', 'Push-to-Talk Voice Capture', '+ Noise Suppression + AGC'),
              _buildPipelineStep('02', 'Silero VAD Segmentation', 'Voice Activity Detection on-device'),
              _buildPipelineStep('03', 'Vosk Streaming ASR', 'Hindi/English/Tamil/Gujarati'),  
              _buildPipelineStep('04', 'TFLite Domain Classifier', '6 NCF-FS domains, multi-label'),
              _buildPipelineStep('05', 'Jadui Pitara Activity Lookup', 'Index retrieval, not generation'),
              _buildPipelineStep('06', 'AES-256-GCM Encryption', 'Field-level encryption → SQLite'),
            ],
          ),

          const SizedBox(height: 32),
          // Footer
          Center(
            child: Text(
              'Ankur v3 · SahAIforShiksha 2026',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> body,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...body,
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 12,
        height: 1.6,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String desc, Color color,
      Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillCard(String title, String desc, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
            : const Color(0xFF020617).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
              : const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: highlight ? const Color(0xFF38BDF8) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              color: highlight ? const Color(0xFF7DD3FC) : const Color(0xFF94A3B8),
              fontSize: 8,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpec(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep(String num, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

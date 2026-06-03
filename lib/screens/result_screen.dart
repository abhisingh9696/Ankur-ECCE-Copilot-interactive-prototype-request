import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/app_provider.dart';
import '../services/translations.dart';
import '../services/classifier_service.dart';
import '../models/child_model.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  bool _isTtsReady = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(0.9);
      await _tts.setPitch(1.0);
      _isTtsReady = true;
    } catch (_) {}
  }

  @override
  void dispose() {
    _textController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text, String lang) async {
    if (!_isTtsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TTS not available on this platform')),
      );
      return;
    }
    try {
      final ttsLang = {
        'en': 'en-US',
        'hi': 'hi-IN',
        'ta': 'ta-IN',
        'gu': 'gu-IN',
      }[lang] ?? 'en-US';

      await _tts.setLanguage(ttsLang);
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.language;

        // Sync text controller
        if (_textController.text.isEmpty && provider.transcript.isNotEmpty) {
          _textController.text = provider.transcript;
        }

        final primaryDomain = provider.tags.isNotEmpty ? provider.tags.first : 'language';
        final activity = ActivityService.getActivity(primaryDomain, lang);
        final domainLabels = _domainLabels(lang);

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
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t('obsSaved', lang),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Transcript section
                      _buildSectionLabel(t('transcript', lang)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _textController,
                              onChanged: (v) => provider.updateTranscript(v),
                              maxLines: 4,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                t('editManual', lang),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tagged domains
                      _buildSectionLabel(t('aiTagged', lang)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFA7F3D0), width: 1.5),
                            ),
                            child: Text(
                              domainLabels[tag] ?? tag,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Jadui Pitara Activity
                      _buildSectionLabel(t('jaduiPitara', lang)),
                      const SizedBox(height: 8),
                      if (activity != null)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFC7D2FE), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.toys,
                                      color: Color(0xFF4F46E5),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      activity['name']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF312E81),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                activity['desc']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4338CA),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _speak(
                                    '${activity['name']}. ${activity['desc']}',
                                    lang,
                                  ),
                                  icon: const Icon(Icons.volume_up, size: 16),
                                  label: Text(
                                    t('readAloud', lang),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4F46E5),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Color(0xFFC7D2FE)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
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

              // Save button
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
                    child: ElevatedButton(
                      onPressed: () => provider.saveObservation(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        t('saveToProfile', lang),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
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

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Map<String, String> _domainLabels(String lang) {
    return {
      'physical': ncfDomains[0].label(lang),
      'socio': ncfDomains[1].label(lang),
      'cognitive': ncfDomains[2].label(lang),
      'language': ncfDomains[3].label(lang),
      'aesthetic': ncfDomains[4].label(lang),
      'habits': ncfDomains[5].label(lang),
    };
  }
}

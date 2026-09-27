import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/translations.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  String _liveTranscript = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _registerJsCallbacks();
  }

  // ─── Register JS→Dart callbacks (mirrors React's direct update pattern) ──

  void _registerJsCallbacks() {
    // Use a post-frame callback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();

      js.context['_ankurReceiveTranscript'] =
          js.allowInterop((String text) {
        _liveTranscript = text;
        if (mounted) setState(() {});
      });

      js.context['_ankurSpeechEnded'] =
          js.allowInterop((String finalText) {
        if (!mounted) return;
        _pulseController.stop();
        if (mounted) setState(() {});
        provider.stopRecording(finalText);
      });

      js.context['_ankurSpeechFallback'] = js.allowInterop(() {
        if (!mounted) return;
        final lang = provider.language;
        provider.setSimulatedVoice(true);
        if (mounted) setState(() {});
        js.context.callMethod('AnkurSpeechSimulate', [lang]);
      });

      js.context['_ankurSpeechError'] = js.allowInterop((String error) {
        if (!mounted) return;
        _pulseController.stop();
        if (mounted) setState(() {});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mic error: $error'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });

      js.context['_ankurSpeechNeedKey'] = js.allowInterop(() {
        if (!mounted) return;
        _promptForDeepgramKey(restartAfterSave: true);
      });
    });
  }

  // ─── Deepgram key prompt ──────────────────────────

  Future<void> _promptForDeepgramKey({bool restartAfterSave = false}) async {
    final controller = TextEditingController();
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deepgram API key needed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice transcription needs your Deepgram API key. '
              'It is stored only in this browser (localStorage) and is '
              'never committed or sent to any server other than Deepgram.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Paste your Deepgram API key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save & continue'),
          ),
        ],
      ),
    );

    if (saved != null && saved.isNotEmpty) {
      js.context.callMethod('AnkurSetDeepgramKey', [saved]);
      if (restartAfterSave && mounted) {
        final provider = context.read<AppProvider>();
        _startMic(provider);
      }
    }
  }

  // ─── Start mic (key is expected to be present) ─────

  void _startMic(AppProvider provider) {
    provider.onMicStarted();
    _liveTranscript = '';
    _pulseController.repeat(reverse: true);
    final langCode = {
      'en': 'en-IN',
      'hi': 'hi-IN',
      'ta': 'ta-IN',
      'gu': 'gu-IN',
    }[provider.language] ??
        'en-IN';
    js.context.callMethod('AnkurRecordStart', [langCode]);
    setState(() {});
  }

  @override
  void dispose() {
    _cleanupCallbacks();
    _pulseController.dispose();
    super.dispose();
  }

  void _cleanupCallbacks() {
    try { js.context.callMethod('AnkurRecordAbort', []); } catch (_) {}
    try { js.context.callMethod('AnkurSpeechCancelSim', []); } catch (_) {}
    try { js.context['_ankurReceiveTranscript'] = null; } catch (_) {}
    try { js.context['_ankurSpeechEnded'] = null; } catch (_) {}
    try { js.context['_ankurSpeechFallback'] = null; } catch (_) {}
    try { js.context['_ankurSpeechError'] = null; } catch (_) {}
    try { js.context['_ankurSpeechNeedKey'] = null; } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.language;
        final child = provider.selectedChild;

        return Container(
          color: const Color(0xFF0F172A),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          js.context.callMethod('AnkurRecordAbort', []);
                          js.context.callMethod('AnkurSpeechCancelSim', []);
                          _pulseController.stop();
                          provider.cancelRecording();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.isRecording
                                  ? t('recording', lang)
                                  : 'Ready to Record',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              child?.name ?? t('readyToSpeak', lang),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Transcript display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: provider.isRecording
                                ? const Color(0xFF38BDF8).withValues(
                                    alpha: 0.3 +
                                        _pulseController.value * 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: _liveTranscript.isEmpty &&
                                provider.transcript.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      provider.isRecording
                                          ? t('listening', lang)
                                          : t('tapMic', lang),
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w300,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                child: Text(
                                  _liveTranscript.isNotEmpty
                                      ? _liveTranscript
                                      : provider.transcript,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    height: 1.7,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      );
                    },
                  ),
                ),

                const Spacer(),

                // Recording indicator dots
                if (provider.isRecording)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedDot(0),
                        _buildAnimatedDot(200),
                        _buildAnimatedDot(400),
                      ],
                    ),
                  ),

                // Mic button
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (provider.isRecording)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return Container(
                                  width: 96 + _pulseController.value * 24,
                                  height: 96 + _pulseController.value * 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFEF4444)
                                        .withValues(
                                            alpha: 0.2 -
                                                _pulseController.value * 0.1),
                                  ),
                                );
                              },
                            ),
                          GestureDetector(
                            onTap: () {
                              if (provider.isRecording) {
                                // STOP recording
                                _pulseController.stop();
                                // Graceful stop — Deepgram delivers final result via callback
                                js.context.callMethod('AnkurRecordStop', []);
                              } else {
                                // START recording via real mic.
                                // Ask for the Deepgram key first if not configured.
                                final hasKey =
                                    js.context.callMethod('AnkurHasDeepgramKey', []) == true;
                                if (!hasKey) {
                                  _promptForDeepgramKey(restartAfterSave: true);
                                } else {
                                  _startMic(provider);
                                }
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: provider.isRecording
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF0EA5E9),
                                boxShadow: [
                                  BoxShadow(
                                    color: (provider.isRecording
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF0EA5E9))
                                        .withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                provider.isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          provider.isRecording
                              ? t('tapStop', lang)
                              : t('speakNaturally', lang),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDot(int delayMs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: value),
            ),
          );
        },
      ),
    );
  }
}



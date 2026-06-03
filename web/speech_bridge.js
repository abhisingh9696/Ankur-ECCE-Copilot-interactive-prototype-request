// Ankur Voice Copilot - Deepgram Speech Bridge v4
// Uses Deepgram WebSocket API for real-time speech-to-text.
// getUserMedia → MediaRecorder → Deepgram WS → live transcript callbacks.

(function() {
  'use strict';

  // ─── Configuration ──────────────────────────────────
  const DEEPGRAM_KEY = '[REVOKED]';
  const DEEPGRAM_WS  = 'wss://api.deepgram.com/v1/listen';

  let stream        = null;   // getUserMedia stream
  let mediaRecorder = null;   // MediaRecorder
  let ws            = null;   // Deepgram WebSocket
  let simTimer      = null;   // simulation interval
  let fullFinal     = '';     // accumulated final transcript
  let interimText   = '';     // current interim transcript

  // ─── Public state ───────────────────────────────────
  window.AnkurSpeech = {
    isListening: false,
    isSimulating: false,
    transcript: '',
    tags: []
  };

  // ─── Check support ──────────────────────────────────
  window.AnkurCheckSupport = function() {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  };

  // ─── Map BCP-47 → Deepgram language code ────────────
  function dgLang(bcp) {
    return {
      'en-IN': 'en-IN',
      'hi-IN': 'hi',
      'ta-IN': 'ta',
      'gu-IN': 'gu'
    }[bcp] || 'en-IN';
  }

  // ─── Clean up all resources ─────────────────────────
  function cleanup() {
    if (ws) {
      try { ws.onmessage = null; ws.onerror = null; ws.onclose = null; ws.close(); } catch(e) {}
      ws = null;
    }
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
      try { mediaRecorder.onstop = null; mediaRecorder.ondataavailable = null; mediaRecorder.stop(); } catch(e) {}
      mediaRecorder = null;
    }
    if (stream) {
      stream.getTracks().forEach(function(t) { t.stop(); });
      stream = null;
    }
    fullFinal = '';
    interimText = '';
  }

  // ─── Start real microphone via Deepgram ─────────────
  window.AnkurRecordStart = function(lang) {
    cleanup();
    fullFinal = '';
    interimText = '';
    window.AnkurSpeech.transcript = '';
    window.AnkurSpeech.isListening = true;
    window.AnkurSpeech.isSimulating = false;

    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      console.warn('[Ankur] getUserMedia not available');
      if (window._ankurSpeechFallback) window._ankurSpeechFallback();
      return false;
    }

    navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: true, sampleRate: 48000 }
    }).then(function(micStream) {
      stream = micStream;

      // Pick best supported mime type
      var mime = 'audio/webm';
      if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
        mime = 'audio/webm;codecs=opus';
      } else if (MediaRecorder.isTypeSupported('audio/webm;codecs=vorbis')) {
        mime = 'audio/webm;codecs=vorbis';
      }

      mediaRecorder = new MediaRecorder(micStream, { mimeType: mime });

      // Deepgram WebSocket (token in URL for browser compatibility)
      var url = DEEPGRAM_WS +
        '?encoding=opus' +
        '&sample_rate=48000' +
        '&channels=1' +
        '&language=' + dgLang(lang) +
        '&punctuate=true' +
        '&interim_results=true' +
        '&smart_format=true' +
        '&utterance_end_ms=1500' +
        '&endpointing=200';

      ws = new WebSocket(url, ['token', DEEPGRAM_KEY]);

      ws.onopen = function() {
        console.log('[Ankur] Deepgram WS connected. Lang:', dgLang(lang));
        mediaRecorder.start(250); // emit audio blob every 250ms
      };

      ws.onmessage = function(event) {
        try {
          var data = JSON.parse(event.data);
          var channel = data.channel;
          if (!channel || !channel.alternatives || !channel.alternatives.length) return;

          var alt = channel.alternatives[0];
          var text = alt.transcript || '';

          if (data.is_final && text) {
            fullFinal += ' ' + text;
            fullFinal = fullFinal.trim();
            interimText = '';
          } else {
            interimText = text;
          }

          var display = fullFinal;
          if (interimText) display = display ? (display + ' ' + interimText) : interimText;
          window.AnkurSpeech.transcript = display;

          if (window._ankurReceiveTranscript) {
            window._ankurReceiveTranscript(display);
          }
        } catch(e) {
          console.warn('[Ankur] Parse error:', e);
        }
      };

      ws.onerror = function(err) {
        console.error('[Ankur] Deepgram WS error:', err);
        cleanup();
        window.AnkurSpeech.isListening = false;
        if (window._ankurSpeechFallback) {
          window._ankurSpeechFallback();
        }
      };

      ws.onclose = function(ev) {
        console.log('[Ankur] Deepgram WS closed:', ev.code, ev.reason);
        // If stream stopped already, ignore
      };

      // Audio data → send to Deepgram
      mediaRecorder.ondataavailable = function(event) {
        if (event.data && event.data.size > 0 && ws && ws.readyState === WebSocket.OPEN) {
          ws.send(event.data);
        }
      };

      mediaRecorder.onstop = function() {
        console.log('[Ankur] MediaRecorder stopped. Final transcript length:', fullFinal.length);
        // Close WS gracefully — it will send final results
        if (ws && ws.readyState === WebSocket.OPEN) {
          // Send a CloseStream message to Deepgram
          try { ws.send(JSON.stringify({ type: 'CloseStream' })); } catch(e) {}
          setTimeout(function() {
            if (ws) { try { ws.close(); } catch(e) {} ws = null; }
          }, 500);
        }
      };

    }).catch(function(err) {
      console.error('[Ankur] getUserMedia error:', err.name, err.message);
      cleanup();
      window.AnkurSpeech.isListening = false;

      if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
        // User explicitly denied — fall back to simulation
        if (window._ankurSpeechFallback) window._ankurSpeechFallback();
      } else if (err.name === 'NotFoundError') {
        // No microphone — fall back
        if (window._ankurSpeechFallback) window._ankurSpeechFallback();
      } else {
        if (window._ankurSpeechError) window._ankurSpeechError(err.message || err.name);
      }
    });

    return true;
  };

  // ─── Stop recording gracefully ──────────────────────
  window.AnkurRecordStop = function() {
    window.AnkurSpeech.isListening = false;

    if (mediaRecorder && mediaRecorder.state === 'recording') {
      // onstop handler will deliver final transcript
      var onStop = function() {
        mediaRecorder = null;
        // Deliver final result
        var final = fullFinal || window.AnkurSpeech.transcript;
        window.AnkurSpeech.transcript = final;
        if (window._ankurSpeechEnded) {
          window._ankurSpeechEnded(final);
        }
        // Cleanup stream & ws
        if (stream) { stream.getTracks().forEach(function(t) { t.stop(); }); stream = null; }
        if (ws) { try { ws.close(); } catch(e) {} ws = null; }
      };
      mediaRecorder.onstop = onStop;
      try { mediaRecorder.stop(); } catch(e) {
        // Already stopped — deliver what we have
        onStop();
      }
    } else {
      // No active recorder — deliver whatever was captured
      var final = fullFinal || window.AnkurSpeech.transcript;
      if (window._ankurSpeechEnded) {
        window._ankurSpeechEnded(final);
      }
      cleanup();
    }
  };

  // ─── Abort recording (discard) ──────────────────────
  window.AnkurRecordAbort = function() {
    window.AnkurSpeech.isListening = false;
    cleanup();
    window.AnkurSpeech.transcript = '';
  };

  // ─── Simulation fallback (word-by-word at 300ms) ────
  window.AnkurSpeechSimulate = function(lang) {
    window.AnkurRecordAbort();
    window.AnkurSpeech.isListening = true;
    window.AnkurSpeech.isSimulating = true;
    window.AnkurSpeech.transcript = '';

    var payloads = {
      en: "Munni successfully matched all primary color blocks today and washed her hands independently before eating her midday meal.",
      hi: "आज मुन्नी ने सभी रंगों के ब्लॉक्स को सफलतापूर्वक अलग किया और दोपहर का भोजन करने से पहले अपने हाथ खुद अच्छी तरह धोए।",
      ta: "முன்னி இன்று அனைத்து வண்ண கட்டைகளையும் சரியாக பொருத்தினார், மதிய உணவிற்கு முன் கைகளை சுயமாக கழுவினார்.",
      gu: "આજે મુન્નીએ બધા જ રંગીન બ્લોક્સને સફળતાપૂર્વક અલગ કર્યા અને બપોરનું ભોજન લેતા પહેલા પોતાના હાથ જાતે સાફ કર્યા."
    };

    var fullText = payloads[lang] || payloads.en;
    var words = fullText.split(' ');
    var wordIdx = 0;

    if (simTimer) clearInterval(simTimer);

    simTimer = setInterval(function() {
      wordIdx++;
      var current = words.slice(0, wordIdx).join(' ');
      window.AnkurSpeech.transcript = current;

      if (window._ankurReceiveTranscript) {
        window._ankurReceiveTranscript(current);
      }

      if (wordIdx >= words.length) {
        clearInterval(simTimer);
        simTimer = null;
        setTimeout(function() {
          window.AnkurSpeech.isListening = false;
          window.AnkurSpeech.isSimulating = false;
          if (window._ankurSpeechEnded) {
            window._ankurSpeechEnded(fullText);
          }
        }, 1200);
      }
    }, 300);
  };

  // ─── Cancel simulation ──────────────────────────────
  window.AnkurSpeechCancelSim = function() {
    if (simTimer) { clearInterval(simTimer); simTimer = null; }
    window.AnkurSpeech.isListening = false;
    window.AnkurSpeech.isSimulating = false;
  };

  console.log('[Ankur] Deepgram bridge v4 loaded. getUserMedia:', window.AnkurCheckSupport());
})();

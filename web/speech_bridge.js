// Ankur Voice Copilot - Deepgram Speech Bridge v5
// Uses Deepgram REST API (not WebSocket) — works through any proxy.
// getUserMedia → MediaRecorder → record to Blob → POST to Deepgram → transcript.
// Falls back to word-by-word simulation if mic denied or unavailable.

(function() {
  'use strict';

  const DEEPGRAM_KEY = '[REVOKED]';
  const DEEPGRAM_URL  = 'https://api.deepgram.com/v1/listen';

  let stream        = null;
  let mediaRecorder = null;
  let audioChunks   = [];
  let simTimer      = null;
  let isRecording   = false;

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

  // ─── Clean up mic resources ─────────────────────────
  function cleanupMic() {
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
      try { mediaRecorder.stop(); } catch(e) {}
      mediaRecorder = null;
    }
    if (stream) {
      stream.getTracks().forEach(function(t) { t.stop(); });
      stream = null;
    }
    audioChunks = [];
    isRecording = false;
    window.AnkurSpeech.isListening = false;
  }

  // ─── Start recording mic to local buffer ────────────
  window.AnkurRecordStart = function(lang) {
    cleanupMic();
    window.AnkurSpeech.transcript = '';
    window.AnkurSpeech.isListening = true;
    window.AnkurSpeech.isSimulating = false;
    audioChunks = [];
    isRecording = true;
    // Store language for later use in API call
    window._ankurLang = lang || 'en-IN';

    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      console.warn('[Ankur] getUserMedia not available');
      window.AnkurSpeech.isListening = false;
      if (window._ankurSpeechFallback) window._ankurSpeechFallback();
      return false;
    }

    console.log('[Ankur] Requesting microphone...');

    navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: true, sampleRate: 48000 }
    }).then(function(micStream) {
      stream = micStream;
      console.log('[Ankur] Microphone acquired. Starting recording...');

      // Pick best mime type
      var mime = 'audio/webm';
      if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
        mime = 'audio/webm;codecs=opus';
      }

      mediaRecorder = new MediaRecorder(micStream, { mimeType: mime });

      mediaRecorder.ondataavailable = function(event) {
        if (event.data && event.data.size > 0) {
          audioChunks.push(event.data);
        }
      };

      mediaRecorder.onstop = function() {
        console.log('[Ankur] Recording stopped. Chunks:', audioChunks.length);
        // Don't process here — AnkurRecordStop handles it
      };

      mediaRecorder.start(500); // collect audio every 500ms
      console.log('[Ankur] MediaRecorder started with mime:', mime);

      // Send a live-feedback pulse to Dart so the user sees "Listening..."
      if (window._ankurReceiveTranscript) {
        window._ankurReceiveTranscript('');
      }

    }).catch(function(err) {
      console.error('[Ankur] getUserMedia error:', err.name, err.message);
      cleanupMic();
      if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
        if (window._ankurSpeechFallback) window._ankurSpeechFallback();
      } else if (err.name === 'NotFoundError') {
        if (window._ankurSpeechFallback) window._ankurSpeechFallback();
      } else {
        if (window._ankurSpeechError) window._ankurSpeechError(err.message || err.name);
      }
    });

    return true;
  };

  // ─── Stop recording and send to Deepgram ─────────────
  window.AnkurRecordStop = function() {
    console.log('[Ankur] Stop requested. Chunks collected:', audioChunks.length);
    window.AnkurSpeech.isListening = false;
    isRecording = false;

    var deliverResult = function(text) {
      window.AnkurSpeech.transcript = text;
      cleanupMic();
      if (text && window._ankurSpeechEnded) {
        window._ankurSpeechEnded(text);
      } else if (window._ankurSpeechEnded) {
        window._ankurSpeechEnded('');
      }
    };

    var sendToDeepgram = function(blob) {
      if (!blob || blob.size < 100) {
        console.warn('[Ankur] Audio too small, skipping Deepgram. Size:', blob ? blob.size : 0);
        deliverResult('');
        return;
      }

      // Determine mimetype for Deepgram based on what we recorded
      var contentType = blob.type || 'audio/webm';

      console.log('[Ankur] Sending to Deepgram REST API... Size:', blob.size, 'Type:', contentType);
      var langCode = dgLang(window._ankurLang || 'en-IN');
      var url = DEEPGRAM_URL +
        '?model=nova-2&language=' + langCode +
        '&punctuate=true&smart_format=true&utterances=true';

      fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': 'Token ' + DEEPGRAM_KEY,
          'Content-Type': contentType
        },
        body: blob
      }).then(function(response) {
        console.log('[Ankur] Deepgram response status:', response.status);
        if (!response.ok) {
          return response.text().then(function(txt) {
            console.error('[Ankur] Deepgram error:', response.status, txt);
            throw new Error('Deepgram HTTP ' + response.status);
          });
        }
        return response.json();
      }).then(function(data) {
        console.log('[Ankur] Deepgram response:', JSON.stringify(data).substring(0, 200));
        var channel = data.results && data.results.channels && data.results.channels[0];
        var alt = channel && channel.alternatives && channel.alternatives[0];
        var text = (alt && alt.transcript) || '';
        console.log('[Ankur] Transcript:', text);
        deliverResult(text.trim());
      }).catch(function(err) {
        console.error('[Ankur] Deepgram fetch failed:', err.message);
        // Fall back to simulation on error
        if (window._ankurSpeechFallback) window._ankurSpeechFallback();
        cleanupMic();
      });
    };

    if (mediaRecorder && mediaRecorder.state === 'recording') {
      // onstop handler processes the blob
      var origOnStop = mediaRecorder.onstop;
      mediaRecorder.onstop = function() {
        var blob = new Blob(audioChunks, { type: mediaRecorder ? mediaRecorder.mimeType : 'audio/webm' });
        // Clean stream
        if (stream) { stream.getTracks().forEach(function(t) { t.stop(); }); stream = null; }
        mediaRecorder = null;
        sendToDeepgram(blob);
      };
      try { mediaRecorder.stop(); } catch(e) {
        // Already stopped
        var blob = new Blob(audioChunks, { type: 'audio/webm' });
        sendToDeepgram(blob);
      }
    } else {
      // No active recorder — use what we have
      if (audioChunks.length > 0) {
        var blob = new Blob(audioChunks, { type: 'audio/webm' });
        sendToDeepgram(blob);
      } else {
        deliverResult('');
      }
    }
  };

  // ─── Abort recording (discard) ──────────────────────
  window.AnkurRecordAbort = function() {
    cleanupMic();
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

  console.log('[Ankur] Deepgram REST bridge v5 loaded. getUserMedia:', window.AnkurCheckSupport());
})();

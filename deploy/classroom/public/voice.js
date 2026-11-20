let microphone = null;
let reading = null;
const recordingLimit = 17_000;
const silenceLimit = 1_200;

export function stopVoice() {
  const mic = microphone;
  microphone = null;
  mic?.cancel();
  if (!reading) return;
  const playback = reading;
  reading = null;
  playback.reset();
  window.speechSynthesis.cancel();
}

export function supportsVoiceOutput() {
  return !!window.speechSynthesis && !!window.SpeechSynthesisUtterance;
}

function canRecord() {
  return !!navigator.mediaDevices?.getUserMedia && !!window.MediaRecorder;
}

function closeCapture(capture) {
  clearInterval(capture.monitor);
  clearTimeout(capture.limit);
  capture.stream?.getTracks().forEach(track => track.stop());
  if (capture.context && capture.context.state !== 'closed') void capture.context.close().catch(() => {});
}

function detectVoice(capture, finish, noSpeech, status) {
  const Context = window.AudioContext || window.webkitAudioContext;
  const started = performance.now();
  capture.limit = setTimeout(finish, recordingLimit);
  if (!Context) return;
  try {
    capture.context = new Context();
    const analyser = capture.context.createAnalyser();
    analyser.fftSize = 1024;
    capture.context.createMediaStreamSource(capture.stream).connect(analyser);
    void capture.context.resume().catch(() => {});
    const samples = new Float32Array(analyser.fftSize);
    let lastVoice = 0;
    capture.monitor = setInterval(() => {
      if (capture.context.state !== 'running') return;
      const now = performance.now();
      analyser.getFloatTimeDomainData(samples);
      const power = samples.reduce((sum, value) => sum + value * value, 0) / samples.length;
      if (power >= .025 ** 2) {
        if (!lastVoice) status('Ses algılandı.');
        lastVoice = now;
      } else if (lastVoice && now - lastVoice >= silenceLimit) {
        finish();
      } else if (!lastVoice && now - started > 8_000) {
        noSpeech();
      }
    }, 90);
  } catch {
    // The microphone button stays usable without a Web Audio analyser.
  }
}

function chooseMime() {
  return ['audio/webm;codecs=opus', 'audio/mp4', 'audio/ogg;codecs=opus']
    .find(type => MediaRecorder.isTypeSupported(type));
}

function listenInBrowser(Recognition, finish, reset, status) {
  const recognition = new Recognition();
  recognition.lang = 'tr-TR';
  recognition.interimResults = false;
  const current = {
    finish: () => recognition.stop(),
    cancel() {
      recognition.abort();
      reset();
    },
  };
  microphone = current;
  recognition.addEventListener('result', event => {
    if (microphone !== current) return;
    const text = Array.from(event.results, result => result[0].transcript).join(' ').trim();
    reset();
    if (text) finish(text);
  });
  recognition.addEventListener('end', () => {
    if (microphone === current) reset();
  });
  recognition.addEventListener('error', event => {
    if (microphone !== current) return;
    reset();
    if (event.error !== 'aborted') status('Ses tanıma kullanılamadı. Yazarak devam edebilirsiniz.');
  });
  try {
    recognition.start();
  } catch {
    reset();
    status('Mikrofon başlatılamadı.');
  }
}

async function listenWithRecorder(onText, reset, status, onState, button) {
  const parts = [];
  const controller = new AbortController();
  const capture = {
    finish,
    cancel() {
      controller.abort();
      if (capture.recorder?.state === 'recording') capture.recorder.stop();
      closeCapture(capture);
      reset();
    },
  };
  microphone = capture;

  function finish() {
    if (capture.recorder?.state !== 'recording') return;
    clearInterval(capture.monitor);
    clearTimeout(capture.limit);
    capture.recorder.stop();
    button.disabled = true;
    status('Söylediklerin yazıya çevriliyor…');
    onState?.('transcribing');
  }

  try {
    capture.stream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
    });
    if (microphone !== capture) {
      closeCapture(capture);
      return;
    }
    const mimeType = chooseMime();
    const recorder = mimeType ? new MediaRecorder(capture.stream, { mimeType, audioBitsPerSecond: 32000 }) : new MediaRecorder(capture.stream);
    capture.recorder = recorder;
    recorder.addEventListener('dataavailable', event => { if (event.data.size) parts.push(event.data); });
    recorder.addEventListener('error', () => {
      if (microphone !== capture) return;
      capture.cancel();
      status('Mikrofon kaydı kesildi.');
    });
    recorder.addEventListener('stop', async () => {
      closeCapture(capture);
      if (microphone !== capture) return;
      try {
        const type = recorder.mimeType || parts[0]?.type || 'audio/webm';
        const clip = new Blob(parts, { type });
        if (!clip.size) throw new Error('empty_audio');
        const result = await fetch('/api/transcribe', {
          method: 'POST', headers: { 'Content-Type': type }, body: clip,
          signal: AbortSignal.any([controller.signal, AbortSignal.timeout(15_000)]),
        });
        if (!result.ok) throw new Error('transcription_unavailable');
        const { text } = await result.json();
        if (microphone !== capture) return;
        reset();
        if (typeof text === 'string' && text.trim()) onText(text);
        else status('Bir cümle duyamadım. Mikrofona daha yakın konuşup tekrar deneyin.');
      } catch {
        if (microphone !== capture) return;
        reset();
        status('Sesi yazıya çeviremedim. Tekrar deneyebilir veya yazabilirsiniz.');
      }
    });
    recorder.start();
    onState?.('listening');
    status('Dinliyorum. İstersen konuşman bitince düğmeye tekrar bas.');
    detectVoice(capture, finish, () => {
      capture.cancel();
      status('Ses algılanmadı. Mikrofonu tekrar açabilirsiniz.');
    }, status);
  } catch {
    if (microphone !== capture) return;
    closeCapture(capture);
    reset();
    status('Mikrofon açılamadı. Tarayıcı izinlerini kontrol edin.');
  }
}

export function bindDictation(button, field, status, { onState, onTranscript } = {}) {
  const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!button || (!canRecord() && !Recognition)) return;
  button.hidden = false;
  const reset = () => {
    microphone = null;
    button.disabled = false;
    button.textContent = 'Mikrofon';
    button.setAttribute('aria-pressed', 'false');
    onState?.('idle');
  };
  const onText = text => {
    if (field.disabled || !field.isConnected) return;
    field.value = [field.value.trim(), text.trim()].filter(Boolean).join(' ').slice(0, field.maxLength);
    if (onTranscript) onTranscript(field.value);
    else {
      field.focus();
      status('Yanıtınızı kontrol edip gönderebilirsiniz.');
    }
  };
  button.addEventListener('click', () => {
    if (microphone) {
      if (!microphone.recorder && canRecord()) stopVoice();
      else microphone.finish();
      return;
    }
    stopVoice();
    button.textContent = 'Kaydı bitir';
    button.setAttribute('aria-pressed', 'true');
    onState?.('listening');
    status('Mikrofon açılıyor…');
    if (canRecord()) void listenWithRecorder(onText, reset, status, onState, button);
    else {
      listenInBrowser(Recognition, onText, reset, status);
      if (microphone) status('Dinliyorum…');
    }
  });
}

export function bindReading(button, getText, status, onSpeaking, onMouth) {
  if (!button || !supportsVoiceOutput()) return;
  button.hidden = false;
  const speak = (text = getText()) => {
    if (!text) return;
    stopVoice();
    const synthesis = window.speechSynthesis;
    const voice = synthesis.getVoices().find(item => /^tr(?:-|$)/i.test(item.lang));
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'tr-TR';
    utterance.rate = 0.94;
    if (voice) utterance.voice = voice;
    let medium;
    let close;
    const reset = () => {
      clearTimeout(medium);
      clearTimeout(close);
      button.textContent = 'Sesli oku';
      onMouth?.('closed');
      onSpeaking?.(false);
    };
    const complete = () => {
      if (reading?.utterance !== utterance) return;
      reading = null;
      reset();
    };
    utterance.addEventListener('start', () => {
      if (reading?.utterance === utterance) {
        onSpeaking?.(true);
        onMouth?.('auto');
      }
    });
    utterance.addEventListener('boundary', event => {
      if (reading?.utterance !== utterance || event.name === 'sentence') return;
      clearTimeout(medium);
      clearTimeout(close);
      onMouth?.('open');
      medium = setTimeout(() => onMouth?.('mid'), 85);
      close = setTimeout(() => onMouth?.('closed'), 165);
    });
    utterance.addEventListener('end', complete);
    utterance.addEventListener('error', event => {
      if (reading?.utterance !== utterance) return;
      complete();
      if (!['canceled', 'interrupted'].includes(event.error)) status('Bu cihazda sesli okuma başlatılamadı.');
    });
    reading = { button, utterance, reset };
    button.textContent = 'Okumayı durdur';
    try {
      synthesis.speak(utterance);
    } catch {
      complete();
      status('Bu cihazda sesli okuma başlatılamadı.');
    }
  };
  button.addEventListener('click', () => {
    if (reading?.button === button) stopVoice();
    else speak();
  });
  return speak;
}

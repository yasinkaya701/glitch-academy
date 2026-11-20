let listening = null;
let reading = null;

export function stopVoice() {
  const current = listening;
  listening = null;
  current?.abort();
  if (reading) {
    reading.reset();
    reading = null;
    window.speechSynthesis.cancel();
  }
}

export function bindDictation(button, field, status) {
  const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!button || !Recognition) return;
  button.hidden = false;
  button.addEventListener('click', () => {
    if (listening) {
      listening.stop();
      return;
    }
    const recognition = new Recognition();
    recognition.lang = 'tr-TR';
    recognition.interimResults = false;
    const reset = () => {
      if (listening === recognition) listening = null;
      button.textContent = 'Sesle yaz';
      button.setAttribute('aria-pressed', 'false');
    };
    recognition.addEventListener('result', event => {
      if (listening !== recognition || field.disabled || !field.isConnected) return;
      const words = [...event.results].map(result => result[0].transcript).join(' ').trim();
      if (!words) return;
      field.value = [field.value.trim(), words].filter(Boolean).join(' ').slice(0, field.maxLength);
      field.focus();
      status('Metni kontrol edip gönderebilirsiniz.');
    });
    recognition.addEventListener('end', reset);
    recognition.addEventListener('error', event => {
      if (listening === recognition && event.error !== 'aborted') status('Ses tanıma kullanılamadı. Yazarak devam edebilirsiniz.');
      reset();
    });
    try {
      stopVoice();
      listening = recognition;
      recognition.start();
      button.textContent = 'Dinlemeyi bitir';
      button.setAttribute('aria-pressed', 'true');
      status('Dinliyorum…');
    } catch {
      reset();
      status('Mikrofon başlatılamadı. Yazarak devam edebilirsiniz.');
    }
  });
}

export function bindReading(button, getText, status) {
  if (!button || !window.speechSynthesis || !window.SpeechSynthesisUtterance) return;
  button.hidden = false;
  button.addEventListener('click', () => {
    const wasReading = reading?.button === button;
    stopVoice();
    if (wasReading) return;
    const text = getText();
    if (!text) return;
    const synthesis = window.speechSynthesis;
    const voice = synthesis.getVoices().find(item => /^tr(?:-|$)/i.test(item.lang));
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'tr-TR';
    utterance.rate = 0.92;
    if (voice) utterance.voice = voice;
    const reset = () => { button.textContent = 'Sesli oku'; };
    const complete = () => {
      if (reading?.utterance !== utterance) return;
      reading = null;
      reset();
    };
    utterance.addEventListener('end', complete);
    utterance.addEventListener('error', event => {
      if (reading?.utterance !== utterance) return;
      complete();
      if (!['canceled', 'interrupted'].includes(event.error)) status('Bu cihazda sesli okuma başlatılamadı.');
    });
    reading = { button, utterance, reset };
    button.textContent = 'Okumayı durdur';
    synthesis.speak(utterance);
  });
}

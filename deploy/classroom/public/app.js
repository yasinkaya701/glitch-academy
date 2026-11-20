import { subjects, findLesson, figureChoices, originalCast } from './lessons.js';
import { stageAsset, stageMarkup, setStageState, setStageMouth } from './stage.js';
import { startGame, remaining, begin, pause, lock, review, normalized } from './game.js';
import { bindDictation, bindReading, stopVoice, supportsVoiceOutput } from './voice.js';

const routes = {
  '/felsefe': { title: 'Fikir Meydanı', key: 'philosophy', primary: ['felsefeyi-tanima', 'socrates'] },
  '/tarih': { title: 'Zaman Arşivi', key: 'history', primary: ['milli-mucadele', 'ataturk'] },
  '/cografya': { title: 'Coğrafya Atlası', key: 'geography', primary: ['cografya-harita-ve-konum'] },
};
const route = location.pathname.replace(/\/$/, '') || '/';
const subject = routes[route];
const app = document.querySelector('#app');
const rules = document.querySelector('#rules');
document.querySelector('#rules-open').addEventListener('click', () => rules.showModal());

const rooms = new Map();
const selection = new URLSearchParams(location.search);
const requested = findLesson(selection.get('unit'), selection.get('figure') || '');
let unit = subject && (requested?.subject === subject.key ? requested : findLesson(...subject.primary));
let match = null;
let timer;
let observeMicrophone;
let voiceReplies = false;
let voicePreferenceSet = false;
let setup = { teams: ['Takım 1', 'Takım 2'], questionSeconds: 45, memorySeconds: 30 };

const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, char => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
})[char]);

function mount(markup, focus) {
  clearInterval(timer);
  observeMicrophone?.disconnect();
  stopVoice();
  app.innerHTML = markup;
  if (focus) app.querySelector('h1')?.focus({ preventScroll: true });
}

function renderHome() {
  const cards = [
    ['/felsefe', 'Felsefe', 'Düşünürlerin fikirlerini kendi örneklerinle tartış.', 'socrates'],
    ['/tarih', 'Tarih', 'Figürlere dönemlerini, kararlarını ve olayların sırasını sor.', 'ataturk'],
    ['/cografya', 'Coğrafya', 'Harita, iklim ve yerleşme üzerine atlas rehberleriyle konuş.', ''],
  ];
  app.classList.add('landing');
  mount(`<section class="intro landing-intro"><h1>Sahneyi seç, konuş.</h1>
    <p>Bir derse gir, figüre sesinle soru sor ya da iki takımla yarış.</p></section>
    <div class="subjects entry-grid">${cards.map(([href, name, text, figure]) => `<a class="entry-card" href="${href}">
      <div class="entry-art ${figure ? '' : 'entry-atlas'}"><img class="entry-setting" src="${figure ? stageAsset(figure, 'setting') : '/stage/geography/atlas.webp'}" alt="">
      ${figure ? `<img class="entry-actor" src="${stageAsset(figure, 'idle')}" alt="">` : ''}</div>
      <div class="entry-content"><h2>${name}</h2><p>${text}</p><span>Sahneyi aç →</span></div>
    </a>`).join('')}</div>`);
}

function greeting() {
  if (subject.key === 'geography') return `Ben ${unit.person.name}. Haritadan başlayalım. Yerleri, yönleri ya da yaşadığınız çevreyi bana sorabilirsiniz.`;
  return subject.key === 'history'
    ? `Ben ${unit.person.name}. Dönemime dair neyi merak ediyorsunuz? Olayların sırasından ya da o günlerde insanların nasıl yaşadığından başlayabiliriz.`
    : `Ben ${unit.person.name}. Düşüncelerimden birini konuşalım. İsterseniz ortaya bir fikir atın, birlikte sınayalım.`;
}

function createRoom() {
  return { log: [], turns: [], memory: [], controller: null, status: '', stageState: 'idle' };
}

function roomKey(lesson) {
  return `${lesson.id}/${lesson.figureId}`;
}

function freeRoom() {
  const key = roomKey(unit);
  if (!rooms.has(key)) {
    const room = createRoom();
    room.log.push({ role: 'assistant', label: unit.person.name, text: greeting() });
    rooms.set(key, room);
  }
  return rooms.get(key);
}

function activeRoom() {
  return match?.room ?? freeRoom();
}

function unitOptions() {
  const lessons = subjects[subject.key];
  const grades = [...new Set(lessons.map(item => item.grade))];
  return grades.map(grade => `<optgroup label="${grade === 12 && subject.key === 'history' ? '12. sınıf / İnkılap Tarihi' : `${grade}. sınıf`}">${lessons.filter(item => item.grade === grade).map(item =>
    `<option value="${escapeHtml(item.id)}" ${item.id === unit.id ? 'selected' : ''}>${escapeHtml(item.title)}</option>`,
  ).join('')}</optgroup>`).join('');
}

function figureSelector() {
  const choices = figureChoices(unit.id);
  if (choices.length < 2) return '';
  return `<label class="field figure-select">Ünitedeki figür<select id="figure-select">${choices.map(item =>
    `<option value="${escapeHtml(item.figureId)}" ${item.figureId === unit.figureId ? 'selected' : ''}>${escapeHtml(item.person.name)}</option>`,
  ).join('')}</select></label>`;
}

function castDialog() {
  return `<dialog id="cast-dialog" class="cast-dialog" aria-labelledby="cast-title">
    <div class="dialog-head"><h2 id="cast-title">Yanlış Dünya figürleri</h2><form method="dialog"><button class="quiet" type="submit">Kapat</button></form></div>
    <div class="cast-grid">${originalCast(subject.key).map(lesson => `<button class="cast-person ${lesson.figureId === unit.figureId ? 'current' : ''}" type="button"
      data-figure="${escapeHtml(lesson.figureId)}" data-unit="${escapeHtml(lesson.id)}">
      <img src="${stageAsset(lesson.figureId, 'thumb')}" alt="" loading="lazy"><strong>${escapeHtml(lesson.person.name)}</strong>
    </button>`).join('')}</div>
  </dialog>`;
}

function setupDialog() {
  const options = (values, selected) => values.map(value =>
    `<option ${value === selected ? 'selected' : ''}>${value}</option>`,
  ).join('');
  return `<dialog id="match-setup" aria-labelledby="match-title">
    <div class="dialog-head"><h2 id="match-title">Takım yarışması</h2><form method="dialog"><button class="quiet" type="submit">Kapat</button></form></div>
    <form id="match-form" class="stack">
      <p>${escapeHtml(unit.person.name)} iki takıma sırayla soru sorar ve yanıtlarına karşılık verir.</p>
      <div class="split-fields">
        <label class="field">Birinci takım<input name="team-a" maxlength="24" value="${escapeHtml(setup.teams[0])}"></label>
        <label class="field">İkinci takım<input name="team-b" maxlength="24" value="${escapeHtml(setup.teams[1])}"></label>
      </div>
      <div class="split-fields">
        <label class="field">Soru süresi (sn)<select name="question-time">${options([30, 45, 60, 90], setup.questionSeconds)}</select></label>
        <label class="field">Hafıza süresi (sn)<select name="memory-time">${options([20, 30, 45, 60], setup.memorySeconds)}</select></label>
      </div>
      <div><button class="primary" type="submit">Yarışmayı başlat</button></div>
    </form>
  </dialog>`;
}

function contextPanel(room) {
  const { person } = unit;
  const timeline = person.timeline?.length ? `<details class="timeline-box"><summary>Zaman çizelgesi</summary>
    <ol class="timeline">${person.timeline.map(([date, event]) => `<li><strong>${escapeHtml(date)}</strong> · ${escapeHtml(event)}</li>`).join('')}</ol>
    <button class="chip timeline-question" type="button">Bu üç olayı sıraya koyup aralarındaki ilişkiyi anlatır mısın?</button>
  </details>` : '';
  return `<section class="panel stack room-context">
    <h3>${room.memory.length ? 'Hatırladıklarım' : 'Bir soru seç'}</h3>
    ${room.memory.length ? `<ul class="timeline">${room.memory.map(note => `<li>${escapeHtml(note)}</li>`).join('')}</ul><h3>Konuşmaya devam et</h3>` : ''}
    <div class="prompt-list">${person.prompts.map(prompt => `<button class="chip" type="button">${escapeHtml(prompt)}</button>`).join('')}</div>
    ${timeline}
  </section>`;
}

function matchPanel() {
  const game = match.game;
  return `<section class="panel stack room-context">
    <div><h3>Puan durumu</h3><ol class="score-list">${game.teams.map((team, index) =>
      `<li ${(match.pending?.team ?? game.team) === index ? 'class="current" aria-current="step"' : ''}><span>${escapeHtml(team)}</span><strong>${game.scores[index]}</strong></li>`,
    ).join('')}</ol></div>
    <div><h3>Hafızam · ${game.memory.length >= 2 ? 'tamamlandı' : `${game.memory.length}/2`}</h3>
      ${game.memory.length ? `<ul class="timeline">${game.memory.map(note => `<li>${escapeHtml(note)}</li>`).join('')}</ul>` :
        '<p class="note">Hatırlattığınız yeni bilgiler burada birikir.</p>'}</div>
  </section>`;
}

function voiceControls({ dictation = true } = {}) {
  return `${dictation ? '<button class="quiet secondary-action" id="dictate" type="button" aria-pressed="false" hidden>Mikrofon</button>' : ''}
    <button class="quiet secondary-action read-button" id="read-aloud" type="button" hidden>Sesli oku</button>
    ${supportsVoiceOutput() ? `<label class="voice-switch"><input id="voice-replies" type="checkbox" ${voiceReplies ? 'checked' : ''}> Sesli yanıt</label>` : ''}`;
}

function freeControls() {
  return `<form class="stack composer" id="chat-form">
    <label class="field"><span>Sorunuz</span><textarea name="message" maxlength="500" required rows="2" placeholder="Konuşmak için mikrofonu aç ya da yaz…"></textarea></label>
    <div class="row"><button class="primary" id="send-chat">Gönder</button>${voiceControls()}
    <button class="quiet secondary-action" id="stop-chat" type="button" hidden>Yanıtı durdur</button></div>
  </form>`;
}

function matchControls() {
  const { game, pending } = match;
  if (pending?.state === 'loading') return '<p class="note">Yanıtı inceliyorum…</p>';
  if (pending?.state === 'failed') {
    return `<div class="row"><button class="primary" id="retry-stage" type="button">Yeniden dene</button>
      <button class="quiet" id="continue-unscored" type="button">Puansız geç</button></div>`;
  }
  if (pending?.state === 'ready') {
    const action = game.phase === 'results' ? 'Sonucu gör' : game.phase === 'memory' ? 'Hafıza turuna geç' : 'İkinci takıma geç';
    return `<div class="row"><button class="primary" id="next-stage" type="button">${action}</button>${voiceControls({ dictation: false })}</div>`;
  }
  if (game.phase === 'results') {
    const [a, b] = game.scores;
    const result = game.unscored ? 'Değerlendirme eksik' : a === b ? 'Beraberlik' : `${game.teams[a > b ? 0 : 1]} kazandı`;
    return `<div class="match-result stack"><div><h3>${escapeHtml(result)}</h3>
      <p class="note">${game.unscored ? 'Bağlantı kesintisi nedeniyle puanlanamayan tur var.' : 'İki takım da turlarını tamamladı.'}</p></div>
      <div class="row"><button class="primary" id="continue-chat" type="button">Sohbete devam et</button>${voiceControls({ dictation: false })}</div></div>`;
  }
  const isQuestion = game.phase === 'question';
  return `<form class="stack composer" id="stage-form">
    <div class="clock-row"><span class="meta">${isQuestion ? 'Soru turu' : 'Hafıza turu'} · ${escapeHtml(game.teams[game.team])}</span>
      <div class="row"><span class="clock" id="timer" role="timer" aria-label="Kalan süre"></span>
      <button class="quiet secondary-action" id="clock-toggle" type="button">Duraklat</button></div></div>
    ${isQuestion ?
      '<label class="field">Takımın yanıtı<textarea name="answer" maxlength="650" rows="2" placeholder="Yanıtını ve gerekçeni söyle ya da yaz."></textarea></label>' :
      '<label class="field">Birinci ek bilgi<input name="note-a" maxlength="200" placeholder="Önceki cevaplardan farklı bir bilgi"></label><label class="field">İkinci ek bilgi<input name="note-b" maxlength="200" placeholder="İsteğe bağlı"></label>'}
    <div class="row"><button class="primary" id="submit-stage" type="submit">${isQuestion ? 'Yanıtla' : 'Hafızaya gönder'}</button>
    ${voiceControls({ dictation: isQuestion })}<button class="quiet secondary-action" id="skip-stage" type="button">Turu geç</button></div>
  </form>`;
}

function renderRoom({ focus = false } = {}) {
  const room = activeRoom();
  const { person } = unit;
  const hasCast = subject.key !== 'geography';
  const scene = stageMarkup(unit, match?.pending?.state === 'loading' ? 'thinking' : room.stageState, match?.game.memory.length ?? room.memory.length, escapeHtml);
  app.classList.add('room-screen');
  mount(`<section class="room-heading">
      <div><p class="room-mode">${subject.title} / ${match ? 'Takım yarışması' : 'Serbest sohbet'}</p>
      <h1 tabindex="-1">${escapeHtml(person.name)}</h1><p class="subtle">${escapeHtml(person.role)}</p></div>
      <div class="room-actions">
        ${match
          ? '<button class="quiet secondary-action" id="leave-match" type="button">Yarışmadan çık</button>'
          : `<label class="field">YKS ünitesi<select id="unit-select">${unitOptions()}</select></label>
          ${figureSelector()}<div class="row">${hasCast ? '<button class="quiet secondary-action" id="open-cast" type="button">Figürler</button>' : ''}
          <button class="quiet" id="open-match" type="button">Takım yarışması</button></div>`}
      </div>
    </section>
    <div class="chat-grid stage-layout ${scene ? 'has-scene' : ''}">
      ${scene}
      <section class="panel stack conversation ${match ? 'match-conversation' : ''}" aria-label="${escapeHtml(person.name)} ile sohbet">
        <p class="note conversation-note">Eğitim amaçlı canlandırma</p>
        <div class="messages" id="messages" role="log" aria-label="Sohbet mesajları"></div>
        ${match ? matchControls() : freeControls()}
        <p class="note status" id="chat-status" role="status">${escapeHtml(room.status || (match ? '' : 'Kişisel bilgi yazmayın.'))}</p>
      </section>
      ${match ? matchPanel() : contextPanel(room)}
    </div>
    ${match ? '' : setupDialog() + (hasCast ? castDialog() : '')}`, focus);
  const messages = app.querySelector('#messages');
  for (const entry of room.log.slice(-60)) drawBubble(messages, entry);
  messages.scrollTop = messages.scrollHeight;
  room.speak = bindReading(app.querySelector('#read-aloud'), () => room.log.findLast(entry => entry.role === 'assistant' && entry.text)?.text,
    status => showStatus(room, status), speaking => showStage(room, speaking ? 'speaking' : 'idle'), mouth => {
      if (activeRoom() === room) setStageMouth(mouth);
    });
  app.querySelector('#voice-replies')?.addEventListener('change', event => {
    voicePreferenceSet = true;
    voiceReplies = event.target.checked;
    if (!voiceReplies) stopVoice();
  });
  if (match) bindMatch();
  else bindFree(room);
  bindStageMicrophone();
}

function bindStageMicrophone() {
  const control = app.querySelector('#dictate');
  const stage = app.querySelector('#stage-mic');
  if (!stage || !control || control.hidden) return;
  stage.hidden = false;
  app.querySelector('.conversation').classList.add('stage-mic-wired');
  const sync = () => {
    stage.textContent = control.textContent;
    stage.disabled = control.disabled;
    stage.setAttribute('aria-pressed', control.getAttribute('aria-pressed'));
  };
  stage.addEventListener('click', () => control.click());
  observeMicrophone = new MutationObserver(sync);
  observeMicrophone.observe(control, { attributes: true, attributeFilter: ['aria-pressed', 'disabled'], childList: true });
  sync();
}

function drawBubble(messages, entry) {
  const bubble = document.createElement('article');
  bubble.className = `message ${entry.role}`;
  const name = document.createElement('small');
  const body = document.createElement('p');
  name.textContent = entry.label;
  body.textContent = entry.text;
  bubble.append(name, body);
  messages.append(bubble);
  return { body, name, messages };
}

function append(room, role, label, text = '') {
  const entry = { role, label, text };
  room.log.push(entry);
  const nodes = drawBubble(app.querySelector('#messages'), entry);
  nodes.messages.scrollTop = nodes.messages.scrollHeight;
  return { entry, ...nodes };
}

function showStatus(room, status) {
  room.status = status;
  if (activeRoom() === room) app.querySelector('#chat-status').textContent = status;
}

function showStage(room, state) {
  room.stageState = state;
  if (activeRoom() === room) setStageState(state);
}

function switchLesson(room, next, focusTarget) {
  room.controller?.abort();
  unit = next;
  const url = new URL(location.href);
  url.searchParams.set('unit', unit.id);
  if (unit.figureId) url.searchParams.set('figure', unit.figureId);
  else url.searchParams.delete('figure');
  window.history.replaceState(null, '', url);
  renderRoom({ focus: !focusTarget });
  if (focusTarget) app.querySelector(focusTarget)?.focus();
}

function bindFree(room) {
  const selector = app.querySelector('#unit-select');
  selector.addEventListener('change', event => {
    const choices = figureChoices(event.target.value);
    switchLesson(room, choices.find(item => item.figureId) ?? choices[0], '#unit-select');
  });
  app.querySelector('#figure-select')?.addEventListener('change', event => {
    switchLesson(room, findLesson(unit.id, event.target.value), '#figure-select');
  });
  const cast = app.querySelector('#cast-dialog');
  app.querySelector('#open-cast')?.addEventListener('click', () => cast.showModal());
  for (const button of cast?.querySelectorAll('.cast-person') ?? []) {
    button.addEventListener('click', () => {
      cast.close();
      switchLesson(room, findLesson(button.dataset.unit, button.dataset.figure));
    });
  }
  const form = app.querySelector('#chat-form');
  const field = form.elements.message;
  const sendFromField = () => {
    const message = field.value.trim();
    if (message && !room.controller) {
      field.value = '';
      void sendChat(room, message);
    }
  };
  bindDictation(app.querySelector('#dictate'), field, status => showStatus(room, status), {
    onState: state => showStage(room, state),
    onTranscript: () => {
      const checkbox = app.querySelector('#voice-replies');
      if (checkbox && !voicePreferenceSet) voiceReplies = checkbox.checked = true;
      sendFromField();
    },
  });
  form.addEventListener('submit', event => {
    event.preventDefault();
    sendFromField();
  });
  app.querySelectorAll('.chip').forEach(button => button.addEventListener('click', () => {
    field.value = button.textContent;
    field.focus();
  }));
  app.querySelector('#stop-chat').addEventListener('click', () => room.controller?.abort());
  const dialog = app.querySelector('#match-setup');
  app.querySelector('#open-match').addEventListener('click', () => dialog.showModal());
  app.querySelector('#match-form').addEventListener('submit', event => {
    event.preventDefault();
    const data = new FormData(event.target);
    setup = {
      teams: ['a', 'b'].map((letter, index) => data.get(`team-${letter}`).trim() || `Takım ${index + 1}`),
      questionSeconds: Number(data.get('question-time')),
      memorySeconds: Number(data.get('memory-time')),
    };
    if (normalized(setup.teams[0]) === normalized(setup.teams[1])) {
      setup.teams = setup.teams.map((name, index) => `${name.slice(0, 21)} ${index + 1}`);
    }
    dialog.close();
    room.controller?.abort();
    match = { game: startGame(setup), room: createRoom(), pending: null, previousAnswers: ['', ''] };
    nextStage();
  });
}

function nextStage() {
  const { game, room } = match;
  match.pending = null;
  room.status = '';
  room.stageState = 'idle';
  if (game.phase === 'results') {
    room.log.push({ role: 'assistant', label: unit.person.name, text: game.memory.length >= 2
      ? 'Hafızamdaki parçaları bir araya getirdiniz. Şimdi hatırlattıklarınızdan birini alıp üzerine konuşabiliriz.'
      : 'Bazı parçalar hâlâ eksik. Yine de birlikte döneme veya düşüncelerime dair bir soruyu inceleyebiliriz.' });
  } else {
    const question = unit.questions[game.team][0];
    room.log.push({ role: 'assistant', label: unit.person.name, text: game.phase === 'question'
      ? `${game.teams[game.team]}, sorum size. ${question}`
      : 'Şimdi hafızamı yoklayalım. Benimle, fikirlerimle ya da dönemimle ilgili iki yeni bilgi hatırlatabilir misiniz?' });
    begin(game);
  }
  renderRoom();
  if (voiceReplies) room.speak?.();
}

function bindMatch() {
  const { game, room, pending } = match;
  app.querySelector('#leave-match').addEventListener('click', () => {
    if (game.phase !== 'results' && !confirm('Bu yarışmadan çıkmak istiyor musunuz?')) return;
    room.controller?.abort();
    match = null;
    renderRoom({ focus: true });
  });
  if (pending) {
    app.querySelector('#next-stage')?.addEventListener('click', nextStage);
    app.querySelector('#retry-stage')?.addEventListener('click', () => evaluateMatch(match));
    app.querySelector('#continue-unscored')?.addEventListener('click', () => finishStage(match, null, false));
    return;
  }
  if (game.phase === 'results') {
    app.querySelector('#continue-chat').addEventListener('click', () => {
      const previous = freeRoom();
      room.memory = [...new Set([...game.memory, ...previous.memory])].slice(0, 4);
      room.turns = previous.turns;
      room.log = [...previous.log, ...room.log];
      rooms.set(roomKey(unit), room);
      match = null;
      renderRoom({ focus: true });
      app.querySelector('[name=message]').focus();
    });
    return;
  }

  const form = app.querySelector('#stage-form');
  const inputs = [...form.querySelectorAll('input, textarea')];
  const label = app.querySelector('#timer');
  const toggle = app.querySelector('#clock-toggle');
  const send = app.querySelector('#submit-stage');
  const dictate = app.querySelector('#dictate');
  if (dictate) bindDictation(dictate, inputs[0], status => showStatus(room, status), { onState: state => showStage(room, state) });
  const submit = (skip = false) => {
    const current = match;
    if (game.locked) return;
    stopVoice();
    lock(game, skip ? [] : inputs.map(input => input.value));
    const entries = game.draft.filter(Boolean);
    current.pending = { team: game.team, state: 'loading' };
    if (!entries.length) {
      finishStage(current, { score: 0, accepted: [], reply: 'Bu tur boş geçti. Bir sonraki turda yeniden deneyelim.' }, true);
      return;
    }
    room.log.push({ role: 'user', label: game.teams[game.team], text: entries.join('\n') });
    evaluateMatch(current);
  };
  const tick = () => {
    const ms = remaining(game);
    const seconds = Math.ceil(ms / 1000);
    label.textContent = `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
    label.classList.toggle('ending', seconds <= 10);
    if (game.deadline !== null && ms <= 0) submit();
  };
  toggle.addEventListener('click', () => {
    const paused = game.deadline === null;
    if (paused) begin(game);
    else { stopVoice(); pause(game); }
    toggle.textContent = paused ? 'Duraklat' : 'Sürdür';
    for (const input of inputs) input.disabled = !paused;
    send.disabled = !paused;
    if (dictate) dictate.disabled = !paused;
    tick();
  });
  form.addEventListener('submit', event => {
    event.preventDefault();
    if (game.deadline !== null && inputs.some(input => input.value.trim())) submit();
  });
  app.querySelector('#skip-stage').addEventListener('click', () => submit(true));
  timer = setInterval(tick, 180);
  tick();
}

function finishStage(current, assessment, evaluated, source) {
  const { game, room, pending } = current;
  const phase = game.phase;
  const startScore = game.scores[game.team];
  const memoriesBefore = game.memory.length;
  if (phase === 'question') current.previousAnswers[game.team] = game.draft[0] || '';
  const facts = phase === 'memory' ? (assessment?.accepted ?? []).map(index => game.draft[index]).filter(Boolean) : [];
  review(game, { score: assessment?.score, facts, evaluated });
  const delta = game.scores[pending.team] - startScore;
  room.stageState = game.memory.length > memoriesBefore ? 'recalled' : 'idle';
  pending.state = 'ready';
  room.log.push({
    role: assessment ? 'assistant' : 'system',
    label: assessment ? unit.person.name : 'Tur bilgisi',
    text: assessment?.reply || 'Bu tur bağlantı nedeniyle puanlanamadı.',
  });
  room.status = evaluated ? `+${delta} puan${source ? ' · ' + providerName(source) : ''}` : '';
  renderRoom();
  app.querySelector('#next-stage')?.focus({ preventScroll: true });
  if (voiceReplies && assessment?.reply) room.speak?.(assessment.reply);
}

async function readEvents(payload, signal, onEvent) {
  const response = await fetch('/api/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    signal,
  });
  if (!response.ok || !response.body) throw new Error('chat_unavailable');
  const reader = response.body.pipeThrough(new TextDecoderStream()).getReader();
  let buffer = '';
  const deliver = line => { if (line.trim()) onEvent(JSON.parse(line)); };
  try {
    while (true) {
      const next = await reader.read();
      if (next.done) break;
      const lines = (buffer + next.value).split('\n');
      buffer = lines.pop();
      for (const line of lines) deliver(line);
    }
    deliver(buffer);
  } finally {
    reader.releaseLock();
  }
}

const providerName = source => source === 'luna' ? 'GPT‑6 Luna' : 'Gemma 4';

async function evaluateMatch(current) {
  const { game, room, pending, previousAnswers } = current;
  if (room.controller) return;
  const controller = new AbortController();
  room.controller = controller;
  pending.state = 'loading';
  room.status = '';
  room.stageState = 'thinking';
  renderRoom();
  const timeout = setTimeout(() => controller.abort(), 17_500);
  let verdict, source, complete = false;
  try {
    await readEvents({ kind: 'evaluate', unitId: unit.id, figureId: unit.figureId, phase: game.phase, team: game.team,
      answers: game.draft, memory: game.memory, previousAnswer: previousAnswers[game.team] }, controller.signal, event => {
      source ||= event.source;
      verdict ||= event.assessment;
      complete ||= !!event.done;
    });
    if (!complete || !verdict || !Array.isArray(verdict.accepted) || typeof verdict.reply !== 'string') throw new Error('missing_assessment');
    if (match === current) finishStage(current, verdict, true, source);
  } catch {
    if (match !== current) return;
    pending.state = 'failed';
    room.stageState = 'idle';
    room.status = 'Değerlendirme bağlantısı kurulamadı.';
    renderRoom();
  } finally {
    clearTimeout(timeout);
    room.controller = null;
  }
}

function discussionCard(message) {
  const { person } = unit;
  if (person.timeline?.length && /kronoloji|sıra|önce|sonra|ne zaman/i.test(message)) {
    return `${person.timeline.map(([date, event]) => `${date} · ${event}`).join('\n')}\nSizce bu olaylar arasında nasıl bir bağlantı var?`;
  }
  return `${person.facts[0]}\n${person.prompts[0]}`;
}

async function sendChat(room, message) {
  stopVoice();
  const controller = new AbortController();
  room.controller = controller;
  const send = app.querySelector('#send-chat');
  const stop = app.querySelector('#stop-chat');
  const dictate = app.querySelector('#dictate');
  append(room, 'user', 'Sınıf', message);
  const reply = append(room, 'assistant', unit.person.name);
  const card = discussionCard(message);
  let source, complete = false, timedOut = false, receivedReply = false;
  send.disabled = true;
  if (dictate) dictate.disabled = true;
  stop.hidden = false;
  showStatus(room, 'Figür düşünüyor…');
  showStage(room, 'thinking');
  const timeout = setTimeout(() => { timedOut = true; controller.abort(); }, 17_500);
  try {
    await readEvents({ unitId: unit.id, figureId: unit.figureId, message, memory: room.memory, history: room.turns.slice(-4) }, controller.signal, event => {
      source ||= event.source;
      complete ||= !!event.done;
      if (event.delta) {
        reply.entry.text += event.delta;
        reply.body.textContent = reply.entry.text;
        reply.messages.scrollTop = reply.messages.scrollHeight;
        showStatus(room, 'Yanıt geliyor…');
        showStage(room, 'typing');
      }
    });
    if (!complete || !reply.entry.text.trim()) throw new Error('chat_incomplete');
    receivedReply = true;
    room.turns.push({ role: 'user', content: message }, { role: 'assistant', content: reply.entry.text.trim().slice(0, 1000) });
    showStatus(room, `Canlı yanıt · ${providerName(source)}`);
  } catch {
    if (controller.signal.aborted && !timedOut) showStatus(room, 'Yanıt durduruldu.');
    else if (reply.entry.text.trim()) showStatus(room, 'Yanıt kesildi. Soruyu yeniden gönderebilirsiniz.');
    else {
      reply.entry.role = 'system';
      reply.body.parentElement.className = 'message system';
      reply.name.textContent = reply.entry.label = 'Hazır tartışma kartı';
      reply.body.textContent = reply.entry.text = card;
      reply.messages.scrollTop = reply.messages.scrollHeight;
      showStatus(room, 'Canlı bağlantı kurulamadı.');
    }
  } finally {
    clearTimeout(timeout);
    room.controller = null;
    showStage(room, 'idle');
    if (activeRoom() === room) {
      app.querySelector('#send-chat').disabled = false;
      app.querySelector('#stop-chat').hidden = true;
      const mic = app.querySelector('#dictate');
      if (mic) mic.disabled = false;
      if (voiceReplies && receivedReply) room.speak?.(reply.entry.text);
    }
  }
}

window.render_game_to_text = () => JSON.stringify({
  route, view: subject ? (match ? 'match' : 'chat') : 'home', unit: unit?.id, figure: unit?.figureId,
  phase: match?.game.phase, team: match?.game.team, scores: match?.game.scores,
  memory: subject ? (match?.game.memory ?? activeRoom().memory) : [],
  pending: match?.pending?.state, chatTurns: subject ? activeRoom().turns.length : 0,
});

if (subject) {
  document.title = `${subject.title} · Yanlış Dünya`;
  document.querySelector(`nav a[href="${route}"]`)?.setAttribute('aria-current', 'page');
  renderRoom();
} else renderHome();

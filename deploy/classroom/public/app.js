import { philosophy } from './philosophy.js';
import { history } from './history.js';
import { startGame, remaining, begin, pause, lock, review, normalized } from './game.js';
import { bindDictation, bindReading, stopVoice } from './voice.js';

const routes = {
  '/felsefe': { name: 'Felsefe', title: 'Fikir Meydanı', units: philosophy },
  '/tarih': { name: 'Tarih', title: 'Zaman Arşivi', units: history },
};
const route = location.pathname.replace(/\/$/, '') || '/';
const subject = routes[route];
const app = document.querySelector('#app');
const rules = document.querySelector('#rules');
document.querySelector('#rules-open').addEventListener('click', () => rules.showModal());

const rooms = new Map();
let unit = subject?.units[0];
let match = null;
let timer;
let setup = { teams: ['Takım 1', 'Takım 2'], questionSeconds: 45, memorySeconds: 30 };

const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, char => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
})[char]);

function mount(markup, focus) {
  clearInterval(timer);
  stopVoice();
  app.innerHTML = markup;
  if (focus) app.querySelector('h1')?.focus({ preventScroll: true });
}

function renderHome() {
  app.classList.add('landing');
  mount(`<section class="intro"><h1>Sınıf Sohbetleri</h1>
    <p>Bir düşünürle fikrini tartış ya da tarihî bir figüre dönemini sor.</p></section>
    <div class="subjects">
      <a class="subject" href="/felsefe"><small>Felsefe</small><h2>Fikir Meydanı</h2>
        <p>Sokrates, Platon ve diğer düşünürlerle konuş.</p><span>Felsefede sohbete gir →</span></a>
      <a class="subject history" href="/tarih"><small>Tarih</small><h2>Zaman Arşivi</h2>
        <p>Halide Edib, Evliya Çelebi ve diğer figürlere kendi dönemlerini sor.</p><span>Tarihte sohbete gir →</span></a>
    </div>`);
}

function greeting() {
  return route === '/tarih'
    ? `Ben ${unit.person.name}. Dönemime dair neyi merak ediyorsunuz? Olayların sırasından ya da o günlerde insanların nasıl yaşadığından başlayabiliriz.`
    : `Ben ${unit.person.name}. Düşüncelerimden birini konuşalım. İsterseniz ortaya bir fikir atın, birlikte sınayalım.`;
}

function createRoom() {
  return { log: [], turns: [], memory: [], controller: null, status: '' };
}

function freeRoom() {
  if (!rooms.has(unit.id)) {
    const room = createRoom();
    room.log.push({ role: 'assistant', label: unit.person.name, text: greeting() });
    rooms.set(unit.id, room);
  }
  return rooms.get(unit.id);
}

function activeRoom() {
  return match?.room ?? freeRoom();
}

function unitOptions() {
  const grades = [...new Set(subject.units.map(item => item.grade))];
  return grades.map(grade => `<optgroup label="${grade === 12 ? '12. sınıf / İnkılap Tarihi' : `${grade}. sınıf`}">${subject.units.filter(item => item.grade === grade).map(item =>
    `<option value="${escapeHtml(item.id)}" ${item.id === unit.id ? 'selected' : ''}>${escapeHtml(item.title)}</option>`,
  ).join('')}</optgroup>`).join('');
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
  return `<aside class="panel stack room-context">
    <h3>${room.memory.length ? 'Hatırladıklarım' : 'Bir soru seç'}</h3>
    ${room.memory.length ? `<ul class="timeline">${room.memory.map(note => `<li>${escapeHtml(note)}</li>`).join('')}</ul><h3>Konuşmaya devam et</h3>` : ''}
    <div class="prompt-list">${person.prompts.map(prompt => `<button class="chip" type="button">${escapeHtml(prompt)}</button>`).join('')}</div>
    ${timeline}
  </aside>`;
}

function matchPanel() {
  const game = match.game;
  return `<aside class="panel stack room-context">
    <div><h3>Puan durumu</h3><ol class="score-list">${game.teams.map((team, index) =>
      `<li ${(match.pending?.team ?? game.team) === index ? 'class="current" aria-current="step"' : ''}><span>${escapeHtml(team)}</span><strong>${game.scores[index]}</strong></li>`,
    ).join('')}</ol></div>
    <div><h3>Hafızam · ${game.memory.length >= 2 ? 'tamamlandı' : `${game.memory.length}/2`}</h3>
      ${game.memory.length ? `<ul class="timeline">${game.memory.map(note => `<li>${escapeHtml(note)}</li>`).join('')}</ul>` :
        '<p class="note">Hatırlattığınız yeni bilgiler burada birikir.</p>'}</div>
  </aside>`;
}

function voiceControls({ dictation = true } = {}) {
  return `${dictation ? '<button class="quiet secondary-action" id="dictate" type="button" aria-pressed="false" hidden>Sesle yaz</button>' : ''}
    <button class="quiet secondary-action read-button" id="read-aloud" type="button" hidden>Sesli oku</button>`;
}

function freeControls() {
  return `<form class="stack composer" id="chat-form">
    <label class="field"><span>Sorunuz</span><textarea name="message" maxlength="500" required rows="2" placeholder="Figüre bir şey sor…"></textarea></label>
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
  mount(`<section class="room-heading">
      <div><p class="room-mode">${subject.title} / ${match ? 'Takım yarışması' : 'Serbest sohbet'}</p>
      <h1 tabindex="-1">${escapeHtml(person.name)}</h1><p class="subtle">${escapeHtml(person.role)}</p></div>
      <div class="room-actions">
        ${match
          ? '<button class="quiet secondary-action" id="leave-match" type="button">Yarışmadan çık</button>'
          : `<label class="field">YKS ünitesi<select id="unit-select">${unitOptions()}</select></label>
          <button class="quiet" id="open-match" type="button">Takım yarışması</button>`}
      </div>
    </section>
    <div class="chat-grid">
      <section class="panel stack conversation ${match ? 'match-conversation' : ''}" aria-label="${escapeHtml(person.name)} ile sohbet">
        <p class="note conversation-note">Eğitim amaçlı canlandırma</p>
        <div class="messages" id="messages" role="log" aria-label="Sohbet mesajları"></div>
        ${match ? matchControls() : freeControls()}
        <p class="note status" id="chat-status" role="status">${escapeHtml(room.status || (match ? '' : 'Kişisel bilgi yazmayın.'))}</p>
      </section>
      ${match ? matchPanel() : contextPanel(room)}
    </div>
    ${match ? '' : setupDialog()}`, focus);
  const messages = app.querySelector('#messages');
  for (const entry of room.log.slice(-60)) drawBubble(messages, entry);
  messages.scrollTop = messages.scrollHeight;
  bindReading(app.querySelector('#read-aloud'), () => room.log.findLast(entry => entry.role === 'assistant' && entry.text)?.text, status => showStatus(room, status));
  if (match) bindMatch();
  else bindFree(room);
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

function bindFree(room) {
  const selector = app.querySelector('#unit-select');
  selector.addEventListener('change', event => {
    room.controller?.abort();
    unit = subject.units.find(item => item.id === event.target.value);
    renderRoom();
    app.querySelector('#unit-select').focus();
  });
  const form = app.querySelector('#chat-form');
  const field = form.elements.message;
  bindDictation(app.querySelector('#dictate'), field, status => showStatus(room, status));
  form.addEventListener('submit', event => {
    event.preventDefault();
    const message = field.value.trim();
    if (message && !room.controller) {
      field.value = '';
      sendChat(room, message);
    }
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
      rooms.set(unit.id, room);
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
  if (dictate) bindDictation(dictate, inputs[0], status => showStatus(room, status));
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
  if (phase === 'question') current.previousAnswers[game.team] = game.draft[0] || '';
  const facts = phase === 'memory' ? (assessment?.accepted ?? []).map(index => game.draft[index]).filter(Boolean) : [];
  review(game, { score: assessment?.score, facts, evaluated });
  const delta = game.scores[pending.team] - startScore;
  pending.state = 'ready';
  room.log.push({
    role: assessment ? 'assistant' : 'system',
    label: assessment ? unit.person.name : 'Tur bilgisi',
    text: assessment?.reply || 'Bu tur bağlantı nedeniyle puanlanamadı.',
  });
  room.status = evaluated ? `+${delta} puan${source ? ' · ' + providerName(source) : ''}` : '';
  renderRoom();
  app.querySelector('#next-stage')?.focus({ preventScroll: true });
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
  renderRoom();
  const timeout = setTimeout(() => controller.abort(), 17_500);
  let verdict, source, complete = false;
  try {
    await readEvents({ kind: 'evaluate', unitId: unit.id, phase: game.phase, team: game.team,
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
  append(room, 'user', 'Sınıf', message);
  const reply = append(room, 'assistant', unit.person.name);
  const card = discussionCard(message);
  let source, complete = false, timedOut = false;
  send.disabled = true;
  stop.hidden = false;
  showStatus(room, 'Figür düşünüyor…');
  const timeout = setTimeout(() => { timedOut = true; controller.abort(); }, 17_500);
  try {
    await readEvents({ unitId: unit.id, message, memory: room.memory, history: room.turns.slice(-4) }, controller.signal, event => {
      source ||= event.source;
      complete ||= !!event.done;
      if (event.delta) {
        reply.entry.text += event.delta;
        reply.body.textContent = reply.entry.text;
        reply.messages.scrollTop = reply.messages.scrollHeight;
        showStatus(room, 'Yanıt geliyor…');
      }
    });
    if (!complete || !reply.entry.text.trim()) throw new Error('chat_incomplete');
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
    if (activeRoom() === room) {
      app.querySelector('#send-chat').disabled = false;
      app.querySelector('#stop-chat').hidden = true;
    }
  }
}

window.render_game_to_text = () => JSON.stringify({
  route, view: subject ? (match ? 'match' : 'chat') : 'home', unit: unit?.id,
  phase: match?.game.phase, team: match?.game.team, scores: match?.game.scores,
  memory: subject ? (match?.game.memory ?? activeRoom().memory) : [],
  pending: match?.pending?.state, chatTurns: subject ? activeRoom().turns.length : 0,
});

if (subject) {
  document.title = `${subject.title} · Yanlış Dünya`;
  document.querySelector(`nav a[href="${route}"]`)?.setAttribute('aria-current', 'page');
  renderRoom();
} else renderHome();

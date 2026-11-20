import { philosophy } from './philosophy.js';
import { history } from './history.js';
import { startGame, remaining, begin, pause, extend, lock, review, normalized } from './game.js';

const routes = {
  '/felsefe': { name: 'Felsefe', title: 'Fikir Meydanı', units: philosophy, detail: 'Bir düşünürün görüşlerini örneklerle sınayın.' },
  '/tarih': { name: 'Tarih', title: 'Zaman Arşivi', units: history, detail: 'Olayları sıralayın, dönemin insanları üzerinden yorumlayın.' },
};
const route = location.pathname.replace(/\/$/, '') || '/';
const subject = routes[route];
const app = document.querySelector('#app');
const rules = document.querySelector('#rules');
const rulesButton = document.querySelector('#rules-open');
rulesButton.addEventListener('click', () => rules.showModal());

let unit = subject?.units[0];
let setup = { teams: ['Takım 1', 'Takım 2'], questionSeconds: 45, memorySeconds: 30 };
let game = null;
let chat = null;
let view = 'home';
let timerHandle;

const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, char => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
})[char]);

function mount(markup, { focus = true } = {}) {
  clearInterval(timerHandle);
  app.innerHTML = markup;
  if (focus) app.querySelector('h1')?.focus({ preventScroll: true });
  window.scrollTo(0, 0);
}

function titleSection(title, subtitle, action = '', meta = '') {
  return `<div class="heading-row"><div><h1 tabindex="-1">${escapeHtml(title)}</h1>${subtitle ? `<p class="subtle">${escapeHtml(subtitle)}</p>` : ''}${meta ? `<p class="meta">${escapeHtml(meta)}</p>` : ''}</div>${action}</div>`;
}

function renderHome() {
  app.classList.add('landing');
  mount(`<section class="intro"><h1 tabindex="-1">Sınıf Sohbetleri</h1>
    <p>İki takımla yarışın, bir figürün hafızasını tamamlayın ve onunla konuşun.</p></section>
    <div class="subjects">
      <a class="subject" href="/felsefe"><small>Felsefe</small><h2>Fikir Meydanı</h2>
        <p>Düşünürlerle konuş, örnekler üret ve fikirlerini gerekçelendir.</p><span>Felsefeyi aç →</span></a>
      <a class="subject history" href="/tarih"><small>Tarih</small><h2>Zaman Arşivi</h2>
        <p>Olayları sıraya koy, tarihî figürlerle kendi dönemleri üzerine konuş.</p><span>Tarihi aç →</span></a>
    </div>`, { focus: false });
}

function unitOptions() {
  const grades = [...new Set(subject.units.map(item => item.grade))];
  return grades.map(grade => `<optgroup label="${grade === 12 ? '12. sınıf / İnkılap Tarihi' : `${grade}. sınıf`}">${subject.units.filter(item => item.grade === grade).map(item =>
    `<option value="${escapeHtml(item.id)}" ${item.id === unit.id ? 'selected' : ''}>${escapeHtml(item.title)}</option>`,
  ).join('')}</optgroup>`).join('');
}

function showUnitPreview() {
  app.querySelector('#unit-preview').innerHTML = `<h3>${escapeHtml(unit.person.name)}</h3>
    <p>${escapeHtml(unit.person.role)}</p><p>${escapeHtml(unit.focus)}</p>`;
}

function renderSetup({ focus = true } = {}) {
  view = 'setup';
  game = null;
  chat?.controller?.abort();
  chat = null;
  mount(`<section class="intro"><h1 tabindex="-1">${subject.title}</h1><p>${subject.detail}</p></section>
    <div class="setup-grid">
      <form class="panel stack" id="setup-form">
        <h2>Üniteyi seç</h2>
        <label class="field">MEB 2026 YKS çalışma ünitesi<select name="unit">${unitOptions()}</select></label>
        <div class="person-preview" id="unit-preview" aria-live="polite"></div>
        <div class="split-fields">
          <label class="field">Birinci takım<input name="team-a" maxlength="24" value="${escapeHtml(setup.teams[0])}"></label>
          <label class="field">İkinci takım<input name="team-b" maxlength="24" value="${escapeHtml(setup.teams[1])}"></label>
        </div>
        <div class="split-fields">
          <label class="field">Soru süresi (sn)<select name="question-time">${[30, 45, 60, 90].map(value => `<option ${value === setup.questionSeconds ? 'selected' : ''}>${value}</option>`).join('')}</select></label>
          <label class="field">Hafıza süresi (sn)<select name="memory-time">${[20, 30, 45, 60].map(value => `<option ${value === setup.memorySeconds ? 'selected' : ''}>${value}</option>`).join('')}</select></label>
        </div>
        <div class="row">
          <button class="primary" type="submit">Yarışmayı başlat</button>
          <button class="quiet" id="free-mode" type="button">Serbest sohbet</button>
        </div>
      </form>
      <aside class="panel">
        <h2>Nasıl oynanır?</h2>
        <ol class="quick-rules">
          <li>Figür sıradaki takıma bir soru sorar. Sözlü tartışın, yanıtı birlikte yazın.</li>
          <li>Öğretmen cevabı değerlendirir. Ardından takım iki ek bilgi yazabilir.</li>
          <li>İki farklı bilgi doğrulandığında figürün hafızası tamamlanır. İki takım da oynayınca sonuç açıklanır.</li>
        </ol>
        <button class="quiet secondary-action" id="more-rules" type="button">Puanlamayı ve örnekleri gör</button>
      </aside>
    </div>`, { focus });
  showUnitPreview();
  const form = app.querySelector('#setup-form');
  const readSetup = () => {
    const data = new FormData(form);
    setup = {
      teams: ['a', 'b'].map((letter, index) => data.get(`team-${letter}`).trim() || `Takım ${index + 1}`),
      questionSeconds: Number(data.get('question-time')),
      memorySeconds: Number(data.get('memory-time')),
    };
    if (normalized(setup.teams[0]) === normalized(setup.teams[1])) {
      setup.teams = setup.teams.map((name, index) => `${name.slice(0, 21)} ${index + 1}`);
    }
  };
  form.elements.unit.addEventListener('change', event => {
    unit = subject.units.find(item => item.id === event.target.value);
    showUnitPreview();
  });
  form.addEventListener('submit', event => {
    event.preventDefault();
    readSetup();
    game = startGame(setup);
    renderGame();
  });
  app.querySelector('#free-mode').addEventListener('click', () => {
    readSetup();
    openChat([]);
  });
  app.querySelector('#more-rules').addEventListener('click', () => rules.showModal());
}

function scores() {
  return `<section class="panel"><h3>Puan durumu</h3><ol class="score-list">${game.teams.map((team, index) =>
    `<li ${game.team === index ? 'class="current" aria-current="step"' : ''}><span>${escapeHtml(team)}</span><strong>${game.scores[index]}</strong></li>`,
  ).join('')}</ol></section>`;
}

function memoryPanel() {
  return `<section class="panel memory-panel"><h3>Hafıza · ${game.memory.length >= 2 ? 'tamamlandı' : `${game.memory.length}/2`}</h3>
    ${game.memory.length ? `<ul>${game.memory.map(note => `<li>${escapeHtml(note)}</li>`).join('')}</ul>` :
    '<p class="note">Doğrulanan bilgiler burada birikir.</p>'}</section>`;
}

function renderGame() {
  if (game.phase === 'results') return renderResults();
  view = 'game';
  const isQuestion = game.phase === 'question';
  const [question, expected] = unit.questions[game.team];
  const controls = game.locked ? '' : `<div class="clock-row">
    <span class="clock" id="timer" role="timer" aria-label="Kalan süre"></span>
    <div class="row"><button class="quiet" id="clock-toggle" type="button">Süreyi başlat</button>
    <button class="quiet secondary-action" id="extend" type="button">+15 sn</button></div>
  </div>`;
  const stage = isQuestion ? 'Soru turu' : 'Hafıza turu';
  const body = game.locked ? reviewMarkup(isQuestion, expected) : `<form class="stack" id="stage-form">
    ${isQuestion
      ? '<label class="field">Takımın yanıtı<textarea name="answer" maxlength="650" placeholder="Tartıştıktan sonra yanıtı ve gerekçeyi yazın." disabled></textarea></label>'
      : '<label class="field">Birinci ek bilgi<input name="note-a" maxlength="200" placeholder="Bir kavram, eser, olay veya tarih" disabled></label><label class="field">İkinci ek bilgi<input name="note-b" maxlength="200" placeholder="İsteğe bağlı, farklı bir bilgi" disabled></label>'}
    <div class="row"><button type="submit" class="primary" id="submit-stage" disabled>Değerlendirmeye geç</button>
    <button type="button" class="quiet secondary-action" id="skip-stage">Turu geç</button></div>
  </form>`;
  mount(`${titleSection(stage, `Sıra: ${game.teams[game.team]}`, '<button class="quiet secondary-action" type="button" id="leave-game">Oturumu kapat</button>', unit.title)}
    <div class="play-grid">
      <section class="panel stack">
        ${controls}
        ${isQuestion ? `<p class="meta">${escapeHtml(unit.person.name)} soruyor</p><p class="game-prompt game-quote">${escapeHtml(question)}</p>` :
          `<p class="game-prompt">${escapeHtml(unit.person.name)} için iki yeni bilgi yazın.</p><p class="note">Doğru ve yeni her bilgi 5 puan. Soru yanıtını veya tahtadaki bir bilgiyi tekrar etmeyin.</p>`}
        ${body}
      </section>
      <aside>${scores()}${memoryPanel()}</aside>
    </div>`);
  app.querySelector('#leave-game').addEventListener('click', () => {
    if (confirm('Bu yarışmanın sonuçları silinecek. Oturumu kapatmak istiyor musunuz?')) renderSetup();
  });
  if (game.locked) {
    const form = app.querySelector('#review-form');
    form.addEventListener('submit', event => {
      event.preventDefault();
      const checkedFacts = [...form.querySelectorAll('input:checked')].map(input => game.draft[Number(input.value)]);
      review(game, { score: Number(event.submitter?.value ?? 0), facts: checkedFacts });
      renderGame();
    });
    return;
  }
  const form = app.querySelector('#stage-form');
  const inputs = [...form.querySelectorAll('input, textarea')];
  const clock = app.querySelector('#timer');
  const toggle = app.querySelector('#clock-toggle');
  const submit = app.querySelector('#submit-stage');
  const close = (skip = false) => {
    lock(game, skip ? [] : inputs.map(input => input.value));
    renderGame();
  };
  function tick() {
    const ms = remaining(game);
    const seconds = Math.ceil(ms / 1000);
    clock.textContent = `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
    clock.classList.toggle('ending', seconds <= 10);
    if (game.deadline !== null && ms <= 0) close();
  }
  function clockControls() {
    const running = game.deadline !== null;
    toggle.textContent = running ? 'Duraklat' : game.timer < (isQuestion ? game.questionSeconds : game.memorySeconds) * 1000 ? 'Devam et' : 'Süreyi başlat';
    for (const input of inputs) input.disabled = !running;
    submit.disabled = !running;
    tick();
  }
  toggle.addEventListener('click', () => {
    if (game.deadline !== null && remaining(game) <= 0) return close();
    if (game.deadline === null) {
      begin(game);
      clockControls();
      inputs[0].focus();
    } else {
      pause(game);
      clockControls();
    }
  });
  app.querySelector('#extend').addEventListener('click', () => {
    if (game.deadline !== null && remaining(game) <= 0) return close();
    extend(game);
    tick();
  });
  form.addEventListener('submit', event => {
    event.preventDefault();
    if (game.deadline !== null) close();
  });
  app.querySelector('#skip-stage').addEventListener('click', () => close(true));
  clockControls();
  timerHandle = setInterval(tick, 180);
}

function reviewMarkup(isQuestion, expected) {
  if (isQuestion) {
    return `<form class="stack" id="review-form">
      <p class="answer"><strong>Takımın yanıtı.</strong> ${escapeHtml(game.draft[0] || 'Yanıt verilmedi.')}</p>
      <p class="rubric"><strong>Beklenen.</strong> ${escapeHtml(expected)}</p>
      <div class="row">
        <button class="quiet" value="0">0 · Boş veya hatalı</button>
        <button class="quiet" value="5" ${!game.draft[0] ? 'disabled' : ''}>5 · Ana fikir</button>
        <button class="primary" value="10" ${!game.draft[0] ? 'disabled' : ''}>10 · Doğru ve gerekçeli</button>
      </div>
    </form>`;
  }
  const known = new Set(game.memory.map(normalized));
  const newNotes = game.draft.map((note, index) => {
    const key = normalized(note);
    if (!key) return '';
    const duplicate = known.has(key);
    return `<label><input type="checkbox" value="${index}" ${duplicate ? 'disabled' : ''}>
      <span class="answer">${escapeHtml(note)}${duplicate ? ' (tekrar)' : ''}</span></label>`;
  }).join('');
  return `<form id="review-form" class="stack">
    <p>Doğru ve yeni bilgileri işaretleyin. Anlamca aynı olanları bir kez kabul edin.</p>
    ${newNotes ? `<fieldset><legend>Onaylanacak bilgiler</legend>${newNotes}</fieldset>` : '<p class="note">Ek bilgi yazılmadı.</p>'}
    <details><summary>Öğretmen için örnek bilgiler</summary><ul>${unit.person.facts.map(fact => `<li>${escapeHtml(fact)}</li>`).join('')}</ul></details>
    <div><button class="primary" type="submit">${game.team === 0 ? 'İkinci takıma geç' : 'Sonucu göster'}</button></div>
  </form>`;
}

function renderResults() {
  view = 'results';
  const [a, b] = game.scores;
  const unlocked = game.memory.length >= 2;
  const result = a === b ? 'Beraberlik' : `${game.teams[a > b ? 0 : 1]} kazandı`;
  mount(`${titleSection(result, unit.title)}
    <div class="play-grid">
      <section class="panel stack">
        <h2>${unlocked ? 'Hafıza tamamlandı' : 'Hafıza henüz tamamlanmadı'}</h2>
        <p>${unlocked ? `${escapeHtml(unit.person.name)} artık kendini hatırlıyor. Sohbete geçerseniz onayladığınız bilgiler figüre bağlam olarak iletilir.` :
          'Sohbeti yarışmadan açmak için iki farklı bilgi gerekir. Serbest modu ünite ekranından her zaman açabilirsiniz.'}</p>
        <div class="row">
          ${unlocked ? '<button id="unlocked-chat" class="primary">Figürle konuş</button>' : ''}
          <button id="new-game" class="quiet">${unlocked ? 'Yeni oturum' : 'Ünite ekranına dön'}</button>
        </div>
      </section>
      <aside>${scores()}${memoryPanel()}</aside>
    </div>`);
  app.querySelector('#unlocked-chat')?.addEventListener('click', () => openChat([...game.memory]));
  app.querySelector('#new-game').addEventListener('click', () => renderSetup());
}

function openChat(memory) {
  view = 'chat';
  chat = { memory, turns: [], controller: null };
  const { person } = unit;
  const timeline = person.timeline?.length ? `<section class="stack"><h3>Zaman çizelgesi</h3>
    <ol class="timeline">${person.timeline.map(([date, event]) => `<li><strong>${escapeHtml(date)}</strong> — ${escapeHtml(event)}</li>`).join('')}</ol>
    <button class="chip" type="button">Bu üç olayı sıraya koyup aralarındaki ilişkiyi açıklar mısın?</button>
  </section>` : '';
  mount(`${titleSection(person.name, person.role, `<button class="quiet secondary-action" type="button" id="leave-chat">${game ? 'Sonuca dön' : 'Üniteye dön'}</button>`, unit.title)}
    <div class="chat-grid">
      <section class="panel stack">
        <p class="note">Serbest sohbet / Eğitim amaçlı canlandırma</p>
        <div class="messages" id="messages" role="log" aria-label="Sohbet mesajları"></div>
        <form class="stack" id="chat-form">
          <label class="field">Sınıfın sorusu<textarea name="message" maxlength="500" required rows="2" placeholder="Sorunuzu buraya yazın."></textarea></label>
          <div class="row"><button class="primary" id="send-chat">Gönder</button><button class="quiet secondary-action" id="stop-chat" type="button" hidden>Yanıtı durdur</button></div>
        </form>
        <p class="note status" id="chat-status" role="status">Kişisel bilgi yazmayın.</p>
      </section>
      <aside class="panel stack">
        ${timeline}
        <h3>Sohbete başlamak için</h3>
        <div class="prompt-list">${person.prompts.map(prompt => `<button class="chip" type="button">${escapeHtml(prompt)}</button>`).join('')}</div>
      </aside>
    </div>`);
  addBubble('assistant', 'Canlandırma', `Ben ${person.name}. ${memory.length ? 'Hafızam şimdi yerinde.' : 'Kendimi ve dönemimi hatırlıyorum.'} ${timeline ? 'Olayların sırasını ve insanlara etkisini birlikte düşünelim.' : 'Görüşlerimi hangi örnekle sınamak istersiniz?'}`);
  const form = app.querySelector('#chat-form');
  form.addEventListener('submit', event => {
    event.preventDefault();
    const message = form.elements.message.value.trim();
    if (message && !chat.controller) {
      form.elements.message.value = '';
      sendChat(message);
    }
  });
  app.querySelectorAll('.chip').forEach(button => button.addEventListener('click', () => {
    form.elements.message.value = button.textContent;
    form.elements.message.focus();
  }));
  app.querySelector('#stop-chat').addEventListener('click', () => chat?.controller?.abort());
  app.querySelector('#leave-chat').addEventListener('click', () => {
    chat.controller?.abort();
    chat = null;
    if (game) renderResults();
    else renderSetup();
  });
}

function addBubble(role, label, text = '') {
  const messages = app.querySelector('#messages');
  const bubble = document.createElement('article');
  const name = document.createElement('small');
  const body = document.createElement('p');
  bubble.className = `message ${role}`;
  name.textContent = label;
  body.textContent = text;
  bubble.append(name, body);
  messages.append(bubble);
  messages.scrollTop = messages.scrollHeight;
  return { bubble, name, body, messages };
}

function discussionCard(message) {
  const { person } = unit;
  if (person.timeline?.length && /kronoloji|sıra|önce|sonra|ne zaman/i.test(message)) {
    return `${person.timeline.map(([date, event]) => `${date} — ${event}`).join('\n')}\nSizce bu olaylar arasında nasıl bir bağlantı var?`;
  }
  return `${person.facts[0]}\nTartışma sorusu. ${person.prompts[0]}`;
}

function parseChatLines(buffer, onLine) {
  const lines = buffer.split('\n');
  const incomplete = lines.pop();
  for (const line of lines) if (line.trim()) onLine(JSON.parse(line));
  return incomplete;
}

async function sendChat(message) {
  const session = chat;
  const controller = new AbortController();
  session.controller = controller;
  const status = app.querySelector('#chat-status');
  const send = app.querySelector('#send-chat');
  const stop = app.querySelector('#stop-chat');
  addBubble('user', 'Sınıf', message);
  const reply = addBubble('assistant', 'Yanıt hazırlanıyor');
  let answer = '';
  let completed = false;
  let timedOut = false;
  send.disabled = true;
  stop.hidden = false;
  status.textContent = 'Figür düşünüyor…';
  const timeout = setTimeout(() => { timedOut = true; controller.abort(); }, 17_500);
  const onLine = event => {
    if (event.source) reply.name.textContent = event.source === 'luna' ? 'GPT-6 Luna' : 'Yedek model';
    if (event.delta) {
      answer += event.delta;
      reply.body.textContent = answer;
      reply.messages.scrollTop = reply.messages.scrollHeight;
      status.textContent = 'Yanıt geliyor…';
    }
    if (event.done) completed = true;
  };
  try {
    const response = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ unitId: unit.id, message, memory: session.memory, history: session.turns.slice(-4) }),
      signal: controller.signal,
    });
    if (!response.ok || !response.body) throw new Error('chat_unavailable');
    const reader = response.body.pipeThrough(new TextDecoderStream()).getReader();
    let buffer = '';
    try {
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        buffer = parseChatLines(buffer + value, onLine);
      }
      if (buffer.trim()) onLine(JSON.parse(buffer));
    } finally {
      reader.releaseLock();
    }
    if (!completed || !answer.trim()) throw new Error('chat_incomplete');
    session.turns.push({ role: 'user', content: message }, { role: 'assistant', content: answer.trim().slice(0, 1000) });
    status.textContent = 'Yanıt tamamlandı.';
  } catch {
    if (chat !== session) return;
    if (controller.signal.aborted && !timedOut) {
      reply.name.textContent = 'Yanıt durduruldu';
      status.textContent = 'Yeni bir soru gönderebilirsiniz.';
    } else if (answer.trim()) {
      status.textContent = 'Bağlantı kesildi. Soruyu yeniden gönderebilirsiniz.';
    } else {
      reply.name.textContent = 'Hazır tartışma kartı';
      reply.body.textContent = discussionCard(message);
      reply.messages.scrollTop = reply.messages.scrollHeight;
      status.textContent = 'Canlı sohbet şu an yanıt veremedi. Kartla tartışmaya devam edebilirsiniz.';
    }
  } finally {
    clearTimeout(timeout);
    if (chat === session) {
      session.controller = null;
      stop.hidden = true;
      send.disabled = false;
    }
  }
}

window.render_game_to_text = () => JSON.stringify({
  route, view, unit: unit?.id, phase: game?.phase, team: game?.team,
  scores: game?.scores, memory: game?.memory, seconds: game ? Math.ceil(remaining(game) / 1000) : null,
  isReview: game?.locked, chatTurns: chat?.turns.length,
});

if (subject) {
  document.title = `${subject.title} · Yanlış Dünya`;
  document.querySelector(`nav a[href="${route}"]`)?.setAttribute('aria-current', 'page');
  renderSetup({ focus: false });
} else {
  renderHome();
}

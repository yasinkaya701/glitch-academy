const settings = {
  socrates: 'Atina Agorası',
  plato: 'Akademia',
  aristotle: 'Lykeion',
  epicurus: 'Epiküros’un Bahçesi',
  kindi: 'Bağdat',
  farabi: 'Saray bahçesi',
  ibn_sina: 'İbn Sînâ’nın çalışma odası',
  ibn_rushd: 'Kurtuba',
  mete_han: 'Bozkır',
  alparslan: 'Malazgirt Ovası',
  fatih: 'Topkapı Divanı',
  kanuni: 'Süleymaniye terası',
  mimar_sinan: 'Selimiye atölyesi',
  ataturk: 'Birinci Meclis, Ankara',
};
const geoSettings = { atlas: 'Dünya atlası', climate: 'İklim ve hava', cities: 'Nüfus ve yerleşme', relief: 'Yer şekilleri ve afetler' };
const messages = {
  idle: 'Sohbete hazır',
  listening: 'Seni dinliyor',
  transcribing: 'Konuşma yazıya çevriliyor',
  thinking: 'Düşünüyor',
  typing: 'Yanıt yazıyor',
  speaking: 'Konuşuyor',
  recalled: 'Hafızası güçlendi',
};

export function stageAsset(id, file) {
  return `/stage/${id}/${file}.webp`;
}

export function stageMarkup(unit, state, memories, escapeHtml) {
  const { figureId, person, subject } = unit;
  const microphone = '<button class="quiet stage-mic" id="stage-mic" type="button" aria-pressed="false" hidden>Mikrofon</button>';
  const status = `<span class="stage-status" id="stage-status">${messages[state] ?? messages.idle}</span>`;
  if (subject === 'geography') {
    return `<figure class="character-stage geography-stage" id="character-stage" data-state="${state}">
      <img class="stage-setting" src="/stage/geography/atlas.webp" alt="Dünya’nın uydu görüntülerinden birleştirilmiş haritası" fetchpriority="high">
      ${microphone}
      <figcaption><div><strong>${escapeHtml(geoSettings[unit.scene] ?? geoSettings.atlas)}</strong> ${status}</div><a href="https://svs.gsfc.nasa.gov/2915/" target="_blank" rel="noopener">NASA/GSFC SVS</a></figcaption>
    </figure>`;
  }
  if (!figureId) return '';
  const frames = subject === 'philosophy' ? ['thinking', 'talk-mid', 'talk-open'] : ['talk-mid', 'talk-open'];
  const expression = frames.map(frame =>
    `<img class="layer layer-${frame}" src="${stageAsset(figureId, frame)}" alt="" aria-hidden="true">`,
  ).join('');
  return `<figure class="character-stage" id="character-stage" data-state="${state}" data-mouth="closed">
    <img class="stage-setting" src="${stageAsset(figureId, 'setting')}" alt="" fetchpriority="high">
    <div class="stage-ring ${memories >= 2 ? 'remembered' : ''}" aria-hidden="true"></div>
    <div class="stage-actor">
      <img class="actor-base" src="${stageAsset(figureId, 'idle')}" alt="${escapeHtml(person.name)} temsili karakteri" fetchpriority="high">
      ${expression}
    </div>
    ${microphone}
    <figcaption><div><strong>${escapeHtml(settings[figureId])}</strong> ${status}</div><span>Temsilî sahne</span></figcaption>
  </figure>`;
}

export function setStageState(state) {
  const stage = document.querySelector('#character-stage');
  if (!stage) return;
  stage.dataset.state = state;
  document.querySelector('#stage-status').textContent = messages[state] ?? messages.idle;
}

export function setStageMouth(mouth) {
  const stage = document.querySelector('#character-stage');
  if (stage) stage.dataset.mouth = mouth;
}

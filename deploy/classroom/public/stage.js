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

export function stageAsset(id, file) {
  return `/stage/${id}/${file}.webp`;
}

export function stageMarkup(unit, state, memories, escapeHtml) {
  const { figureId, person, subject } = unit;
  if (!figureId) return '';
  const expression = subject === 'philosophy' ? [
    ['thinking', 'thinking'],
    ['talk-mid', 'talk-mid'],
    ['talk-open', 'talk-open'],
  ].map(([frame, name]) =>
    `<img class="layer layer-${frame}" src="${stageAsset(figureId, name)}" alt="" aria-hidden="true">`,
  ).join('') : '';
  return `<figure class="character-stage" id="character-stage" data-state="${state}">
    <img class="stage-setting" src="${stageAsset(figureId, 'setting')}" alt="" fetchpriority="high">
    <div class="stage-ring ${memories >= 2 ? 'remembered' : ''}" aria-hidden="true"></div>
    <div class="stage-actor">
      <img class="actor-base" src="${stageAsset(figureId, 'idle')}" alt="${escapeHtml(person.name)} temsili karakteri" fetchpriority="high">
      ${expression}
    </div>
    <figcaption><span>${escapeHtml(settings[figureId])}</span><span>Temsilî sahne</span></figcaption>
  </figure>`;
}

export function setStageState(state) {
  const stage = document.querySelector('#character-stage');
  if (stage) stage.dataset.state = state;
}

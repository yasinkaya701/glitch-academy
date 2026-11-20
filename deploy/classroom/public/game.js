export function startGame({ teams, questionSeconds, memorySeconds }) {
  return {
    teams, questionSeconds, memorySeconds, team: 0, scores: [0, 0],
    memory: [], unscored: 0, phase: 'question', timer: questionSeconds * 1000,
    deadline: null, locked: false, draft: [],
  };
}

export function remaining(game, now = Date.now()) {
  return game.deadline === null ? game.timer : Math.max(0, game.deadline - now);
}

export function begin(game, now = Date.now()) {
  if (!game.locked && game.deadline === null) game.deadline = now + game.timer;
}

export function pause(game, now = Date.now()) {
  game.timer = remaining(game, now);
  game.deadline = null;
}

export function extend(game, now = Date.now()) {
  if (game.locked) return;
  const running = game.deadline !== null;
  game.timer = remaining(game, now) + 15_000;
  game.deadline = running ? now + game.timer : null;
}

export function lock(game, draft) {
  if (game.locked || game.phase === 'results') return;
  pause(game);
  game.locked = true;
  game.draft = draft.map(value => value.trim());
}

export function normalized(value) {
  return value.toLocaleLowerCase('tr').replaceAll('ı', 'i')
    .normalize('NFD').replace(/\p{M}/gu, '').replace(/[^a-z0-9]+/g, ' ').trim();
}

export function review(game, { score, facts = [], evaluated = true }) {
  if (!game.locked) return;
  if (!evaluated && game.draft.some(Boolean)) game.unscored += 1;
  if (game.phase === 'question') {
    game.scores[game.team] += evaluated && game.draft[0] && [5, 10].includes(score) ? score : 0;
    game.phase = 'memory';
    game.timer = game.memorySeconds * 1000;
  } else if (game.phase === 'memory') {
    const known = new Set(game.memory.map(normalized));
    for (const fact of game.draft.slice(0, 2)) {
      const key = normalized(fact);
      if (evaluated && key && facts.includes(fact) && !known.has(key)) {
        game.memory.push(fact);
        known.add(key);
        game.scores[game.team] += 5;
      }
    }
    game.team += 1;
    game.phase = game.team === 2 ? 'results' : 'question';
    game.timer = game.phase === 'results' ? 0 : game.questionSeconds * 1000;
  }
  game.locked = false;
  game.draft = [];
}

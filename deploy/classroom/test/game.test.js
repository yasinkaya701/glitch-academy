import test from 'node:test';
import assert from 'node:assert/strict';
import { startGame, begin, remaining, pause, extend, lock, review } from '../public/game.js';

const options = { teams: ['Mor', 'Yeşil'], questionSeconds: 45, memorySeconds: 30 };
const grade = (game, score, facts = []) => review(game, { score, facts });

test('two equal turns use independent deadlines and pause, then collect classroom memories', () => {
  const game = startGame(options);
  begin(game, 1_000);
  assert.equal(remaining(game, 2_000), 44_000);
  pause(game, 11_000);
  assert.equal(remaining(game, 99_000), 35_000);
  begin(game, 100_000);
  extend(game, 110_000);
  assert.equal(remaining(game, 110_000), 40_000);
  lock(game, ['Yanıt A']);
  grade(game, 10);
  assert.equal(game.phase, 'memory');
  assert.equal(game.team, 0);
  begin(game, 200_000);
  assert.equal(remaining(game, 201_000), 29_000);
  lock(game, ['Mağara alegorisi', 'Akademia']);
  grade(game, 0, ['Mağara alegorisi']);
  assert.equal(game.phase, 'question');
  assert.equal(game.team, 1);
  assert.equal(game.timer, 45_000);
  assert.equal(game.deadline, null);
  lock(game, ['Yanıt B']);
  grade(game, 5);
  lock(game, ['Akademia', 'MAĞARA ALEGORİSİ.']);
  grade(game, 0, ['Akademia', 'MAĞARA ALEGORİSİ.']);
  assert.equal(game.phase, 'results');
  assert.deepEqual(game.scores, [15, 10]);
  assert.deepEqual(game.memory, ['Mağara alegorisi', 'Akademia']);
  assert.equal(game.memory.length >= 2, true);
});

test('a skipped answer and unchecked draft add no points and double review is ignored', () => {
  const game = startGame(options);
  lock(game, ['']);
  grade(game, 10);
  grade(game, 10);
  lock(game, ['Kabul edilmemiş bilgi']);
  grade(game, 0, ['Dışarıdan eklenen bilgi']);
  assert.deepEqual(game.scores, [0, 0]);
  assert.equal(game.team, 1);
});

test('a provider outage advances without awarding points and marks the result incomplete', () => {
  const game = startGame(options);
  lock(game, ['Yanıt gönderildi']);
  review(game, { score: 10, evaluated: false });
  assert.equal(game.phase, 'memory');
  assert.equal(game.unscored, 1);
  assert.deepEqual(game.scores, [0, 0]);
  lock(game, ['Hatırlanan bilgi']);
  review(game, { facts: ['Hatırlanan bilgi'], evaluated: false });
  assert.equal(game.unscored, 2);
  assert.deepEqual(game.memory, []);
});

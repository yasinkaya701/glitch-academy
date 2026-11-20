import test from 'node:test';
import assert from 'node:assert/strict';
import { stat } from 'node:fs/promises';
import { originalFigures } from '../public/original-figures.js';
import { findLesson, figureChoices } from '../public/lessons.js';

test('all original cast members retain their own visual assets and working lesson profiles', async () => {
  assert.equal(originalFigures.philosophy.length, 8);
  assert.equal(originalFigures.history.length, 6);
  for (const [subject, cast] of Object.entries(originalFigures)) {
    for (const { id, unitId } of cast) {
      const lesson = findLesson(unitId, id);
      assert.equal(lesson?.figureId, id);
      assert.equal(lesson?.subject, subject);
      assert.equal(lesson?.questions.length, 2);
      assert.ok(figureChoices(unitId).some(variant => variant.figureId === id));
      for (const file of ['idle', 'setting', 'thumb']) {
        assert.ok((await stat(new URL(`../public/stage/${id}/${file}.webp`, import.meta.url))).size > 1000);
      }
    }
  }
});

test('rejects a figure from an unrelated unit', () => {
  assert.equal(findLesson('felsefeyi-tanima', 'ataturk'), null);
  assert.equal(findLesson('felsefeyi-tanima', ['socrates']), null);
  assert.equal(findLesson('milli-mucadele').person.name, 'Halide Edib Adıvar');
  assert.match(findLesson('milli-mucadele', 'ataturk').person.name, /Atatürk/);
});

test('alternate history figures supply their own chronology and assessment rubric', () => {
  for (const id of ['ataturk', 'fatih', 'mimar_sinan']) {
    const entry = originalFigures.history.find(item => item.id === id);
    const lesson = findLesson(entry.unitId, id);
    const defaultLesson = findLesson(entry.unitId);
    assert.notEqual(lesson.person.name, defaultLesson.person.name);
    assert.notDeepEqual(lesson.questions, defaultLesson.questions);
    assert.equal(lesson.person.timeline.length, 3);
  }
});

import { philosophy } from './philosophy.js';
import { history } from './history.js';
import { originalFigures } from './original-figures.js';

export const subjects = { philosophy, history };
const byUnit = new Map();
for (const [subject, lessons] of Object.entries(subjects)) {
  for (const unit of lessons) byUnit.set(unit.id, { ...unit, subject });
}

export function figureChoices(unitId) {
  const unit = byUnit.get(unitId);
  if (!unit) return [];
  const cast = originalFigures[unit.subject].filter(figure => figure.unitId === unitId);
  const original = cast.find(figure => !figure.person);
  return [
    { ...unit, figureId: original?.id ?? '' },
    ...cast.filter(figure => figure.person).map(figure => ({
      ...unit, figureId: figure.id, person: figure.person, questions: figure.questions,
      focus: figure.focus ?? unit.focus,
    })),
  ];
}

export function findLesson(unitId, figureId = '') {
  if (typeof figureId !== 'string') return null;
  const choices = figureChoices(unitId);
  return (figureId ? choices.find(unit => unit.figureId === figureId) : choices[0]) ?? null;
}

export function originalCast(subject) {
  return originalFigures[subject].map(({ id, unitId }) => findLesson(unitId, id));
}

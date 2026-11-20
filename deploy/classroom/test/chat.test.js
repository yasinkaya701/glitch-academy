import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/worker.js';
import { history } from '../public/history.js';
import { philosophy } from '../public/philosophy.js';

const baseUrl = 'https://sinif.example';
const question = { unitId: 'felsefeyi-tanima', message: 'Sence cesaret nedir?', memory: ['Erdemi sorgular.'], history: [] };
function post(body = question, origin = baseUrl) {
  return new Request(baseUrl + '/api/chat', {
    method: 'POST', headers: { origin, 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

test('all reference units have playable question/rubric pairs and figure prompts', () => {
  assert.equal(philosophy.length, 9);
  assert.equal(history.length, 26);
  const ids = new Set([...philosophy, ...history].map(unit => unit.id));
  assert.equal(ids.size, 35);
  for (const unit of [...philosophy, ...history]) {
    assert.equal(unit.person.prompts.length, 3, unit.id);
    assert.equal(unit.questions.length, 2, unit.id);
    for (const [question, rubric] of unit.questions) {
      assert.ok(question.length > 15, unit.id);
      assert.ok(rubric.length > 15 && rubric !== question, unit.id);
    }
  }
});

test('sends curated character and new memory to Luna, streams only text and identifies provider', async () => {
  const stream = new TextEncoder().encode('event: response.output_text.delta\r\ndata: {"type":"response.output_text.delta","delta":"Cesaret, korkuya rağmen"}\r\n\r\ndata: {"type":"response.output_text.delta","delta":" davranmayı da içerir."}\r\n\r\ndata: {"type":"response.completed"}\r\n\r\n');
  const env = { AI: { run: async (model, input) => {
    assert.equal(model, 'openai/gpt-6-luna');
    assert.equal(input.stream, true);
    assert.equal(input.store, false);
    assert.match(input.instructions, /Sokrates/);
    assert.match(input.input.at(-1).content, /Sence cesaret nedir/);
    assert.match(input.input.at(-1).content, /Erdemi sorgular/);
    return new ReadableStream({ start(controller) {
      controller.enqueue(stream.subarray(0, 118));
      controller.enqueue(stream.subarray(118));
      controller.close();
    } });
  } } };
  const response = await worker.fetch(post(), env);
  assert.equal(response.status, 200);
  const lines = (await response.text()).trim().split('\n').map(line => JSON.parse(line));
  assert.deepEqual(lines, [
    { source: 'luna' },
    { delta: 'Cesaret, korkuya rağmen' },
    { delta: ' davranmayı da içerir.' },
    { done: true },
  ]);
});

test('labels the alternate model when Luna fails', async () => {
  const env = { AI: { run: async model => {
    if (model === 'openai/gpt-6-luna') throw Error('unavailable');
    return { response: 'Bir örnek düşünelim.' };
  } } };
  const response = await worker.fetch(post(), env);
  const lines = (await response.text()).trim().split('\n').map(line => JSON.parse(line));
  assert.deepEqual(lines, [{ source: 'backup' }, { delta: 'Bir örnek düşünelim.' }, { done: true }]);
});

test('blocks unmatched origins and malformed or oversize prompts without calling the model', async () => {
  const env = { AI: { run: () => assert.fail('invalid request reached provider') } };
  assert.equal((await worker.fetch(post(question, 'https://other.example'), env)).status, 403);
  assert.equal((await worker.fetch(post({ ...question, history: [null] }), env)).status, 400);
  assert.equal((await worker.fetch(post({ ...question, message: 'a'.repeat(501) }), env)).status, 400);
});

test('honors the edge rate limit before invoking inference', async () => {
  const env = { CHAT_LIMIT: { limit: async () => ({ success: false }) }, AI: { run: () => assert.fail('rate-limited') } };
  assert.equal((await worker.fetch(post(), env)).status, 429);
});

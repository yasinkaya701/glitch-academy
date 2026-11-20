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

function evaluationPost(body, origin = baseUrl) {
  return post({
    kind: 'evaluate', unitId: 'felsefeyi-tanima', phase: 'question', team: 0,
    answers: ['Çoğunluk yanılıyor olabilir; neden doğru sayılıyor?'], memory: [],
    previousAnswer: '', ...body,
  }, origin);
}

function ndjson(response) {
  return response.text().then(text => text.trim().split('\n').map(line => JSON.parse(line)));
}

test('automatically evaluates a question and returns typed character feedback', async () => {
  const env = {
    LUNA_PAUSED: '1',
    AI: { run: async (model, input) => {
      assert.equal(model, '@cf/google/gemma-4-26b-a4b-it');
      assert.equal(input.stream, true);
      assert.doesNotMatch(input.messages[0].content, /Çoğunluk yanılıyor olabilir/);
      assert.match(input.messages[1].content, /Çoğunluk yanılıyor olabilir/);
      assert.match(input.messages[0].content, /Çoğunluğun görüşü ile doğruluk arasını sorgulayan/);
      return { response: JSON.stringify({ score: 10, accepted: [], reply: 'Sokratik bir ayrım kurdunuz.' }) };
    } },
  };
  const response = await worker.fetch(evaluationPost({}), env);
  assert.equal(response.status, 200);
  assert.deepEqual(await ndjson(response), [
    { source: 'backup' },
    { assessment: { score: 10, accepted: [], reply: 'Sokratik bir ayrım kurdunuz.' } },
    { done: true },
  ]);
});

test('uses Luna first and validates its streamed assessment before returning it', async () => {
  const encoder = new TextEncoder();
  const payload = JSON.stringify({ score: 5, accepted: [], reply: 'Ana fikri yakaladınız.' });
  const sse = encoder.encode(`event: response.output_text.delta\ndata: ${JSON.stringify({ type: 'response.output_text.delta', delta: payload })}\n\nevent: response.completed\ndata: {"type":"response.completed"}\n\n`);
  const env = { AI: { run: async (model, input) => {
    assert.equal(model, 'openai/gpt-6-luna');
    assert.equal(input.stream, true);
    assert.match(input.instructions, /Turnuva modunda/);
    return new ReadableStream({ start(controller) { controller.enqueue(sse); controller.close(); } });
  } } };
  const events = await ndjson(await worker.fetch(evaluationPost({}), env));
  assert.deepEqual(events, [
    { source: 'luna' },
    { assessment: { score: 5, accepted: [], reply: 'Ana fikri yakaladınız.' } },
    { done: true },
  ]);
});

test('rejects accepted memory that duplicates known notes or the previous answer', async () => {
  const env = {
    LUNA_PAUSED: '1',
    AI: { run: async () => ({ response: JSON.stringify({ score: 5, accepted: [0], reply: 'Yeni bir bilgi.' }) }) },
  };
  const response = await worker.fetch(evaluationPost({
    phase: 'memory', answers: ['Erdemi sorgular.'], memory: ['Erdemi sorgular.'], previousAnswer: '',
  }), env);
  const events = await ndjson(response);
  assert.deepEqual(events, [{ error: 'evaluation_unavailable' }]);
  assert.equal(events.some(event => event.assessment), false);
});

test('rejects normalized duplicates of the previous question answer', async () => {
  const env = {
    LUNA_PAUSED: '1',
    AI: { run: async () => ({ response: JSON.stringify({ score: 5, accepted: [0], reply: 'Yeni bir bilgi.' }) }) },
  };
  const events = await ndjson(await worker.fetch(evaluationPost({
    phase: 'memory', answers: ['ERDEMİ SORGULAR'], memory: [], previousAnswer: 'Erdemi sorgular.',
  }), env));
  assert.deepEqual(events, [{ error: 'evaluation_unavailable' }]);
});

test('never fabricates an evaluation when both providers fail', async () => {
  const env = { LUNA_PAUSED: '1', AI: { run: async () => { throw Error('unavailable'); } } };
  const events = await ndjson(await worker.fetch(evaluationPost({}), env));
  assert.deepEqual(events, [{ error: 'evaluation_unavailable' }]);
  assert.equal(events.some(event => event.assessment), false);
});

test('does not award points for a blank question response', async () => {
  const env = {
    LUNA_PAUSED: '1',
    AI: { run: async () => ({ response: JSON.stringify({ score: 10, accepted: [], reply: 'İyi yanıt.' }) }) },
  };
  const events = await ndjson(await worker.fetch(evaluationPost({ answers: ['  '] }), env));
  assert.deepEqual(events, [{ error: 'evaluation_unavailable' }]);
});

test('relays the same typed evaluation through the Cloudflare fallback worker', async () => {
  const originalFetch = globalThis.fetch;
  let forwarded;
  globalThis.fetch = async (url, init) => {
    forwarded = JSON.parse(init.body);
    return worker.fetch(new Request(String(url), init), {
      LUNA_PAUSED: '1',
      AI: { run: async () => ({ response: JSON.stringify({ score: 5, accepted: [], reply: 'Ana fikri yakaladınız.' }) }) },
    });
  };
  try {
    const requestBody = {
      kind: 'evaluate', unitId: 'felsefeyi-tanima', phase: 'question', team: 1,
      answers: ['Bir örnek düşünelim.'], memory: [], previousAnswer: '',
    };
    const events = await ndjson(await worker.fetch(evaluationPost(requestBody), {
      LUNA_PAUSED: '1', BACKUP_ORIGIN: 'https://backup.example',
    }));
    assert.deepEqual(forwarded, requestBody);
    assert.deepEqual(events, [
      { source: 'backup' },
      { assessment: { score: 5, accepted: [], reply: 'Ana fikri yakaladınız.' } },
      { done: true },
    ]);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('normalizes exact echoed memory facts to their original answer positions', async () => {
  const facts = ['Sokrates’in kendi yazılı eseri yoktur.', 'Platon onu diyaloglarında anlatır.'];
  const env = {
    LUNA_PAUSED: '1',
    AI: { run: async () => ({ response: JSON.stringify({ score: 10, accepted: facts, reply: 'İki bilgiyi de hatırladım.' }) }) },
  };
  const events = await ndjson(await worker.fetch(evaluationPost({ phase: 'memory', answers: facts }), env));
  assert.deepEqual(events, [
    { source: 'backup' },
    { assessment: { score: 10, accepted: [0, 1], reply: 'İki bilgiyi de hatırladım.' } },
    { done: true },
  ]);
});

import test from 'node:test';
import assert from 'node:assert/strict';
import { transcribeRequest } from '../src/transcribe.js';

const base = 'https://class.example';
function request(type = 'audio/webm', origin = base, bytes = new Uint8Array([9, 7, 3])) {
  return new Request(base + '/api/transcribe', {
    method: 'POST', headers: { Origin: origin, 'Content-Type': type }, body: bytes,
  });
}

test('transcribes a Turkish microphone clip with the voice activity filter', async () => {
  const result = await transcribeRequest(request(), { AI: { run: async (model, params) => {
    assert.equal(model, '@cf/openai/whisper-large-v3-turbo');
    assert.equal(params.audio, 'CQcD');
    assert.equal(params.language, 'tr');
    assert.equal(params.vad_filter, true);
    return { text: ' Haritayı nasıl okurum? ' };
  } } });
  assert.deepEqual(await result.json(), { text: 'Haritayı nasıl okurum?' });
});

test('rejects unsupported file types, unknown site origins and oversized clips before model inference', async () => {
  const env = { AI: { run: () => assert.fail('invalid microphone request reached model') } };
  assert.equal((await transcribeRequest(request('application/json'), env)).status, 415);
  assert.equal((await transcribeRequest(request('audio/ogg', 'https://other.example'), env)).status, 403);
  assert.equal((await transcribeRequest(request('audio/webm', base, new Uint8Array(1_500_001)), env)).status, 413);
});

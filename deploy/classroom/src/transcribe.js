const audioLimit = 1_500_000;
const types = /^audio\/(?:webm|mp4|ogg|wav|mpeg|x-wav|aac)(?:;|$)/i;
const headers = { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' };

function json(data, status = 200) {
  return Response.json(data, { status, headers });
}

async function readClip(request) {
  if (!request.body || Number(request.headers.get('Content-Length')) > audioLimit) return null;
  const reader = request.body.getReader();
  const chunks = [];
  let length = 0;
  try {
    while (true) {
      const part = await reader.read();
      if (part.done) break;
      length += part.value.byteLength;
      if (length > audioLimit) {
        await reader.cancel();
        return null;
      }
      chunks.push(part.value);
    }
    return new Blob(chunks);
  } finally {
    reader.releaseLock();
  }
}

function encodeBase64(bytes) {
  let binary = '';
  for (let i = 0; i < bytes.length; i += 16_384) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 16_384));
  }
  return btoa(binary);
}

export async function transcribeRequest(request, env) {
  if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
  if (request.headers.get('Origin') !== new URL(request.url).origin) return json({ error: 'forbidden' }, 403);
  const type = request.headers.get('Content-Type') || '';
  if (!types.test(type)) return json({ error: 'audio_type' }, 415);
  try {
    if (env.CHAT_LIMIT) {
      const key = request.headers.get('CF-Connecting-IP') || request.headers.get('x-vercel-forwarded-for') || 'unknown';
      const { success } = await env.CHAT_LIMIT.limit({ key });
      if (!success) return json({ error: 'too_many_requests' }, 429);
    }
    const clip = await readClip(request);
    if (!clip) return json({ error: 'audio_limit' }, 413);
    if (!clip.size) return json({ error: 'empty_audio' }, 400);
    if (!env.AI) {
      const url = new URL('/api/transcribe', env.BACKUP_ORIGIN);
      const upstream = await fetch(url, {
        method: 'POST', headers: { 'Content-Type': type, Origin: url.origin },
        body: clip, signal: AbortSignal.any([request.signal, AbortSignal.timeout(13_000)]),
      });
      return new Response(upstream.body, {
        status: upstream.status, headers: { ...headers, 'Content-Type': 'application/json; charset=utf-8' },
      });
    }
    const bytes = new Uint8Array(await clip.arrayBuffer());
    const result = await env.AI.run('@cf/openai/whisper-large-v3-turbo', {
      audio: encodeBase64(bytes), language: 'tr', task: 'transcribe',
      vad_filter: true, condition_on_previous_text: false,
    });
    const text = typeof result?.text === 'string' ? result.text.trim().slice(0, 650) : '';
    return json({ text });
  } catch {
    return json({ error: 'transcription_unavailable' }, 503);
  }
}

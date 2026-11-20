import classroom from '../src/worker.js';

const requests = new Map();
const perMinute = 18;
let windowReset = 0;

const chatLimit = {
  async limit({ key }) {
    const now = Date.now();
    if (now >= windowReset) {
      requests.clear();
      windowReset = now + 60_000;
    }
    if (requests.size >= 4_096 && !requests.has(key)) return { success: false };
    const count = (requests.get(key) ?? 0) + 1;
    requests.set(key, count);
    return { success: count <= perMinute };
  },
};

export default {
  fetch(request) {
    return classroom.fetch(request, {
      GATEWAY_TOKEN: process.env.AI_GATEWAY_API_KEY || request.headers.get('x-vercel-oidc-token'),
      OPENAI_API_KEY: process.env.OPENAI_API_KEY,
      CHAT_LIMIT: chatLimit,
      BACKUP_ORIGIN: process.env.BACKUP_ORIGIN || 'https://yanlis-dunya-sinif-sohbetleri.lexicon-survivors-leaderboard.workers.dev',
    });
  },
};

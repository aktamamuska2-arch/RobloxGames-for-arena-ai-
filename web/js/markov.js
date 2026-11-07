/* =========================================================================
   markov.js — generator teks rantai Markov untuk obrolan bot.

   Ide: bot TIDAK membalas pesan tertentu (tidak menargetkan pemain). Mereka
   hanya "mengoceh" kalimat acak hasil rantai Markov yang dilatih dari:
     - korpus awal (kalimat ala Roblox/chat game di config.CHAT_LINES),
     - setiap pesan yang diketik pemain di chat.

   Jadi makin banyak pemain mengetik, makin banyak kosakata yang dipakai bot,
   tetapi bot tetap tidak menjawab siapa pun secara spesifik.
   ========================================================================= */

import { CHAT_LINES } from './config.js';

const FALLBACKS = [
  'gg semua', 'main lagi yuk', 'map ini keren', 'ada yang mau duel?',
  'beli gear dulu ah', 'hati-hati lava', 'combo tiga kali sakit lho',
];

/** Pecah teks jadi token sederhana (huruf/angka kecil, tanpa tanda baca). */
function tokenize(text) {
  return String(text || '')
    .toLowerCase()
    .replace(/[^a-z0-9\u00c0-\u024f' ]+/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length > 0 && w.length <= 16)
    .slice(0, 32);
}

function pickWeighted(map, rng) {
  let total = 0;
  for (const c of map.values()) total += c;
  let r = rng() * total;
  for (const [word, count] of map) {
    r -= count;
    if (r <= 0) return word;
  }
  return map.keys().next().value;
}

/** Rantai Markov tingkat-`order` (order 1 = per kata, 2 = per pasangan kata). */
export class MarkovChain {
  constructor(order = 2) {
    this.order = order;
    this.next = new Map();     // key -> Map(kata berikut -> jumlah)
    this.starts = [];          // key yang pernah mengawali kalimat
  }

  learn(text) {
    const words = tokenize(text);
    if (words.length < this.order + 1) return 0;
    for (let i = 0; i + this.order < words.length; i++) {
      const key = words.slice(i, i + this.order).join(' ');
      const following = words[i + this.order];
      let bucket = this.next.get(key);
      if (!bucket) {
        bucket = new Map();
        this.next.set(key, bucket);
      }
      bucket.set(following, (bucket.get(following) || 0) + 1);
    }
    this.starts.push(words.slice(0, this.order).join(' '));
    return words.length;
  }

  /** Hasilkan kalimat acak; '' kalau rantai masih kosong. */
  generate({ maxWords = 12, rng = Math.random } = {}) {
    if (!this.starts.length) return '';
    let key = this.starts[Math.floor(rng() * this.starts.length)];
    const out = key.split(' ');
    for (let i = 0; i < maxWords; i++) {
      const bucket = this.next.get(key);
      if (!bucket || !bucket.size) break;

      // hindari pengulangan kata yang sama bertubi-tubi ("hati hati hati hati")
      const last = out[out.length - 1];
      let pool = bucket;
      if (bucket.size > 1 && bucket.has(last)) {
        pool = new Map(bucket);
        pool.delete(last);
      }
      const word = pickWeighted(pool, rng);
      // jangan pernah mengulang kata yang sama dua kali berturut-turut
      if (word === last) break;
      out.push(word);
      key = out.slice(-this.order).join(' ');

      // hentikan siklus A-B-A-B yang tidak menghasilkan kalimat baru
      if (out.length >= 6) {
        const a = out.slice(-3).join(' ');
        const b = out.slice(-6, -3).join(' ');
        if (a === b) break;
      }
    }
    return out.join(' ');
  }

  get size() {
    return this.next.size;
  }
}

export const Chatter = {
  chain1: new MarkovChain(1),
  chain2: new MarkovChain(2),
  learned: 0,
  seeded: false,

  /** Latih dari korpus awal (CHAT_LINES di config.js). */
  seed() {
    if (this.seeded) return;
    this.seeded = true;
    const lines = Object.values(CHAT_LINES).flat();
    const extra = [
      'halo semua ada yang mau duel',
      'aku baru beli katana di shop',
      'map ini keren banget',
      'ayo push ke tengah arena',
      'jangan lupa block kalau aku serang',
      'koin ku sudah banyak',
      'siapa yang mau satu lawan satu di tengah',
      'lava itu bahaya hati hati',
      'respawn dulu ya',
      'combo tiga kali bikin knockback besar',
      'aku suka map sky islands',
      'jangan jatuh ke void',
      'main lagi yuk seru',
      'awas di sampingmu',
      'dash itu bisa menghindar',
      'gg semua semoga menang',
    ];
    for (const line of [...lines, ...extra]) this.feed(line);
  },

  feed(text) {
    const ok1 = this.chain1.learn(text);
    this.chain2.learn(text);
    if (ok1) this.learned++;
  },

  /** Belajar dari pesan pemain. */
  learn(text) {
    this.seed();
    const clean = String(text || '').trim();
    if (clean.length < 3 || clean.startsWith('/')) return;
    this.feed(clean);
  },

  /** Kalimat acak — tanpa menargetkan siapa pun. */
  generate(maxWords = 12) {
    this.seed();
    let text = '';
    if (this.chain2.size > 8 && Math.random() < 0.65) {
      text = this.chain2.generate({ maxWords });
    }
    if (!text) text = this.chain1.generate({ maxWords });
    if (!text) return FALLBACKS[Math.floor(Math.random() * FALLBACKS.length)];
    return this.polish(text);
  },

  polish(text) {
    let s = String(text).trim().replace(/\s+/g, ' ');
    if (!s) return FALLBACKS[0];
    s = s[0].toUpperCase() + s.slice(1);
    if (s.length > 68) s = `${s.slice(0, 65).trimEnd()}…`;
    if (!/[.!?…]$/.test(s) && Math.random() < 0.45) s += Math.random() < 0.5 ? '.' : '!';
    return s;
  },

  get vocabulary() {
    this.seed();
    return this.chain1.size + this.chain2.size;
  },
};

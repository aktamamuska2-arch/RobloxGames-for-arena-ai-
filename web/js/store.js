/* =========================================================================
   store.js — penyimpanan progres (koin, gear, statistik, settings).
   Memakai localStorage; semua akses dibungkus try/catch supaya aman saat
   mode private / storage diblokir.
   ========================================================================= */

import { SAVE_KEY, DEFAULT_SETTINGS, SHOP } from './config.js';

function blank() {
  return {
    version: 2,
    coins: 120,
    items: {},              // { sword: 2, speed: 1, ... }
    stats: { kills: 0, deaths: 0, rounds: 0, bestStreak: 0, wins: 0 },
    settings: { ...DEFAULT_SETTINGS },
    name: '',
    createdAt: Date.now(),
  };
}

export const Store = {
  data: blank(),

  load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') {
          this.data = {
            ...blank(),
            ...parsed,
            stats: { ...blank().stats, ...(parsed.stats || {}) },
            settings: { ...DEFAULT_SETTINGS, ...(parsed.settings || {}) },
            items: { ...(parsed.items || {}) },
          };
        }
      }
    } catch (err) {
      console.warn('[store] gagal load save:', err);
    }
    return this.data;
  },

  save() {
    try {
      localStorage.setItem(SAVE_KEY, JSON.stringify(this.data));
    } catch (err) {
      /* storage penuh / diblokir — abaikan */
    }
  },

  reset() {
    const name = this.data.name;
    this.data = blank();
    this.data.name = name;
    this.save();
  },

  /* ------------------------------ koin ------------------------------ */
  get coins() { return this.data.coins; },
  addCoins(n) {
    this.data.coins = Math.max(0, Math.round(this.data.coins + n));
    this.save();
    return this.data.coins;
  },
  spend(n) {
    if (this.data.coins < n) return false;
    this.data.coins -= n;
    this.save();
    return true;
  },

  /* ------------------------------ gear ------------------------------ */
  level(id) { return this.data.items[id] || 0; },
  item(id) { return SHOP.find((s) => s.id === id); },
  price(id) {
    const def = this.item(id);
    if (!def) return Infinity;
    const lvl = this.level(id);
    return lvl >= def.maxLevel ? Infinity : def.prices[lvl];
  },
  buy(id) {
    const def = this.item(id);
    if (!def) return { ok: false, reason: 'unknown' };
    const lvl = this.level(id);
    if (lvl >= def.maxLevel) return { ok: false, reason: 'max' };
    const price = def.prices[lvl];
    if (!this.spend(price)) return { ok: false, reason: 'coins' };
    this.data.items[id] = lvl + 1;
    this.save();
    return { ok: true, level: lvl + 1 };
  },
  refundAll() {
    let total = 0;
    for (const [id, lvl] of Object.entries(this.data.items)) {
      const def = this.item(id);
      if (!def) continue;
      for (let i = 0; i < lvl; i++) total += def.prices[i] || 0;
    }
    this.data.items = {};
    this.data.coins += Math.round(total * 0.75); // refund 75%
    this.save();
    return Math.round(total * 0.75);
  },

  /* --------------------------- statistik --------------------------- */
  get stats() { return this.data.stats; },
  bumpStat(key, n = 1) {
    this.data.stats[key] = (this.data.stats[key] || 0) + n;
    this.save();
  },

  /* ---------------------------- settings --------------------------- */
  get settings() { return this.data.settings; },
  setSetting(key, value) {
    this.data.settings[key] = value;
    this.save();
  },

  get name() { return this.data.name; },
  setName(name) {
    this.data.name = String(name || '').slice(0, 18);
    this.save();
  },
};

/* Stat turunan dari gear — dipakai Player & UI. */
export function gearStats(store) {
  const lv = (id) => store.level(id);
  return {
    lightMul: 1 + 0.18 * lv('sword'),
    heavyMul: 1 + 0.22 * lv('axe'),
    speedBonus: 2 * lv('speed'),
    maxHealthBonus: 20 * lv('health'),
    damageReduction: Math.min(0.6, 0.09 * lv('armor')),
    dashCdMul: 1 - 0.14 * lv('dash'),
    lifesteal: 1.6 * lv('vampire'),
    staminaBonus: 25 * lv('sprint'),
    hasSword: lv('sword') > 0,
    hasAxe: lv('axe') > 0,
    hasCoil: lv('speed') > 0,
  };
}

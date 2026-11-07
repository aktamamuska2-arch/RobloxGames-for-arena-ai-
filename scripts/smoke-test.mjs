/* =========================================================================
   smoke-test.mjs — uji "headless" untuk logika game tanpa browser/GPU.
   Menyediakan stub DOM + canvas 2D, lalu:
     1. membangun keempat map dan memeriksa collider/spawn,
     2. membuat dua Fighter + Avatar dan memastikan combat & kill jalan,
     3. menjalankan AI bot beberapa detik untuk menangkap error runtime.
   Jalankan: node scripts/smoke-test.mjs
   ========================================================================= */

import assert from 'node:assert';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

await import('./vendor-link.mjs');

/* ------------------------------ DOM stubs ------------------------------ */
function fakeCtx() {
  const grad = { addColorStop() {} };
  const noop = () => {};
  return new Proxy({
    canvas: null,
    createRadialGradient: () => grad,
    createLinearGradient: () => grad,
    measureText: () => ({ width: 42 }),
    getImageData: () => ({ data: new Uint8ClampedArray(4) }),
  }, {
    get(target, prop) {
      if (prop in target) return target[prop];
      return noop;
    },
    set(target, prop, value) { target[prop] = value; return true; },
  });
}

function fakeCanvas(w = 256, h = 256) {
  const c = {
    width: w, height: h,
    style: {},
    getContext: () => fakeCtx(),
    addEventListener() {},
    removeEventListener() {},
    toDataURL: () => 'data:image/png;base64,',
  };
  return c;
}

const listeners = {};
globalThis.document = {
  createElement(tag) {
    if (tag === 'canvas') return fakeCanvas();
    return { style: {}, classList: { add() {}, remove() {}, toggle() {}, contains: () => false }, appendChild() {}, addEventListener() {} };
  },
  addEventListener(t, fn) { (listeners[t] ||= []).push(fn); },
  removeEventListener() {},
  querySelector: () => null,
  querySelectorAll: () => [],
  body: { appendChild() {} },
  pointerLockElement: null,
  exitPointerLock() {},
};

globalThis.window = {
  innerWidth: 1280,
  innerHeight: 720,
  devicePixelRatio: 1,
  addEventListener() {},
  removeEventListener() {},
  matchMedia: () => ({ matches: false }),
  requestAnimationFrame: (fn) => setTimeout(() => fn(performance.now()), 0),
  localStorage: undefined,
};

const mem = new Map();
globalThis.localStorage = {
  getItem: (k) => (mem.has(k) ? mem.get(k) : null),
  setItem: (k, v) => mem.set(k, String(v)),
  removeItem: (k) => mem.delete(k),
};

globalThis.performance = globalThis.performance || { now: () => Date.now() };
globalThis.requestAnimationFrame = globalThis.window.requestAnimationFrame;

/* ----------------------------- modules ----------------------------- */
const THREE = await import('three');
const { createArena, MAP_INFO } = await import('../web/js/maps.js');
const { Fighter } = await import('../web/js/entities.js');
const { Player } = await import('../web/js/player.js');
const { Bot } = await import('../web/js/bots.js');
const { tryAttack, updateCombat, applyDamage, updateFx, spawnBurst } = await import('../web/js/combat.js');
const { dangerDpsAt, groundBelow, stepEntity } = await import('../web/js/physics.js');
const { gearStats } = await import('../web/js/store.js');

let failures = 0;
function check(name, fn) {
  try {
    fn();
    console.log(`  ok   ${name}`);
  } catch (err) {
    failures++;
    console.error(`  FAIL ${name}`);
    console.error(err);
  }
}

/* ------------------------------- tests ------------------------------- */
console.log('\n[1] peta');
for (let i = 0; i < MAP_INFO.length; i++) {
  check(`map ${i} (${MAP_INFO[i].name})`, () => {
    const arena = createArena(i);
    assert.ok(arena.colliders.length > 5, 'collider kurang');
    assert.ok(arena.spawns.length >= 4, 'spawn kurang');
    assert.ok(arena.spawns.every((s) => Number.isFinite(s.x) && Number.isFinite(s.y)), 'spawn NaN');
    // setiap spawn harus punya tanah di bawahnya
    for (const s of arena.spawns) {
      const top = groundBelow(arena.colliders, s.x, s.z, s.y + 2, 1.2, 3);
      assert.ok(top > -Infinity, `spawn (${s.x},${s.z}) tanpa tanah`);
    }
    arena.update(0.016, 1);
    arena.dispose();
  });
}

console.log('\n[2] fighter + combat');
const arena = createArena(0);
const fakeGame = {
  arena,
  entities: [],
  fx: [],
  fxGroup: new THREE.Group(),
  time: 0,
  stats: { kills: 0, deaths: 0 },
  world: { shake() {} },
  ui: {
    damageNumber() {},
    addChat() {},
    toast() {},
    refreshHealth() {},
    refreshLeaderboard() {},
    hurt() {},
    crosshairHit() {},
    deathCam() {},
    respawnCam() {},
  },
  addCoins() {},
  player: null,
};

const gear = gearStats({ level: () => 0 });
const a = new Fighter({ name: 'A', isPlayer: true, gear });
const b = new Fighter({ name: 'B', gear });
fakeGame.entities = [a, b];
fakeGame.player = a;
a.teleport(0, 2, 0, 0);
b.teleport(0, 2, 4, Math.PI);

check('avatar dibuat & punya group', () => {
  assert.ok(a.avatar.group.children.length > 3);
  assert.ok(a.maxHealth === 100);
});

check('attack mengenai target di depan', () => {
  a.yaw = 0;
  a.attackCd = 0;
  assert.ok(tryAttack(fakeGame, a, 'light'));
  // jalankan beberapa frame supaya window hitbox aktif
  for (let i = 0; i < 20; i++) updateCombat(fakeGame, 0.016);
  assert.ok(b.health < b.maxHealth, `HP target tidak turun (${b.health})`);
});

check('serangan tidak mengenai target di belakang', () => {
  b.setHealth(b.maxHealth);
  b.iframes = 0;
  a.attackCd = 0;
  a.comboIndex = 0;
  a.yaw = Math.PI; // menghadap ke belakang
  tryAttack(fakeGame, a, 'light');
  for (let i = 0; i < 20; i++) updateCombat(fakeGame, 0.016);
  assert.equal(b.health, b.maxHealth);
});

check('damage mematikan target & menjadwalkan respawn', () => {
  applyDamage(fakeGame, b, 999, a, { crit: true });
  assert.equal(b.alive, false);
  assert.ok(b.respawnT > 0);
  assert.equal(a.stats.kills, 1);
  // majukan waktu sampai respawn
  for (let i = 0; i < 400; i++) updateCombat(fakeGame, 0.02);
  assert.equal(b.alive, true);
  assert.equal(b.health, b.maxHealth);
});

check('block mengurangi damage', () => {
  b.setHealth(b.maxHealth);
  b.iframes = 0;
  b.blocking = true;
  b.yaw = Math.atan2(a.pos.x - b.pos.x, a.pos.z - b.pos.z);
  applyDamage(fakeGame, b, 20, a, {});
  assert.ok(b.maxHealth - b.health < 10, `block tidak mengurangi (${b.maxHealth - b.health})`);
});

console.log('\n[3] physics');
check('karakter jatuh lalu mendarat di lantai', () => {
  const f = new Fighter({ name: 'C', gear });
  const sp = arena.spawns[0];
  f.teleport(sp.x, sp.y + 14, sp.z, 0);
  const frame = 0.016;
  for (let i = 0; i < 240; i++) stepEntity(arena.colliders, f, frame);
  assert.ok(Math.abs(f.pos.y - sp.y) < 0.5, `y tidak mendarat di spawn: ${f.pos.y} vs ${sp.y}`);
  assert.ok(f.onGround);
});

check('karakter tidak menembus dinding', () => {
  const f = new Fighter({ name: 'D', gear });
  const sp = arena.spawns[1];
  f.teleport(sp.x, sp.y + 0.2, sp.z, 0);
  f.vel.set(0, 0, -60);
  for (let i = 0; i < 200; i++) stepEntity(arena.colliders, f, 0.016);
  assert.ok(Math.abs(f.pos.z) < 76, `keluar dari arena: ${f.pos.z}`);
});

console.log('\n[4] AI');
check('bot bergerak mendekati target', () => {
  const bot = new Bot({ name: 'BotX', gear });
  bot.arenaLimit = arena.size * 0.55;
  bot.pickTarget = () => { bot.target = a; };   // isolasi: fokus ke satu target
  fakeGame.combatEnabled = true;
  fakeGame.entities.push(bot);
  // area terbuka di luar platform tengah, jarak 18 stud (langsung chase)
  a.alive = true; a.health = a.maxHealth; a.blocking = false; a.iframes = 0;
  a.teleport(30, 1, 30, 0);
  bot.teleport(12, 1, 30, 0);
  const d0 = Math.hypot(a.pos.x - bot.pos.x, a.pos.z - bot.pos.z);
  let moved = 0;
  for (let i = 0; i < 300; i++) {
    fakeGame.time += 0.016;
    bot.update(fakeGame, 0.016);
    updateCombat(fakeGame, 0.016);
    moved = Math.max(moved, Math.hypot(bot.vel.x, bot.vel.z));
  }
  const d1 = Math.hypot(a.pos.x - bot.pos.x, a.pos.z - bot.pos.z);
  assert.ok(moved > 1, 'bot tidak bergerak');
  assert.ok(d1 < d0 - 3, `bot tidak mendekat: ${d0.toFixed(1)} → ${d1.toFixed(1)}`);
  assert.ok(Number.isFinite(bot.pos.y), 'posisi bot NaN');
});

check('bot menyerang & memberi damage', () => {
  const bot = new Bot({ name: 'BotY', gear });
  bot.arenaLimit = arena.size * 0.55;
  bot.pickTarget = () => { bot.target = a; };
  fakeGame.combatEnabled = true;
  fakeGame.entities.push(bot);
  a.alive = true; a.health = a.maxHealth; a.iframes = 0;
  a.teleport(30, 1, 30, 0);
  bot.teleport(30, 1, 34, 0);      // 4 stud di depan player
  a.health = a.maxHealth;
  a.blocking = false;
  a.iframes = 0;
  const hp0 = a.health;
  for (let i = 0; i < 300; i++) {
    fakeGame.time += 0.016;
    bot.update(fakeGame, 0.016);
    updateCombat(fakeGame, 0.016);
    if (a.health < hp0) break;
  }
  assert.ok(a.health < hp0, `bot tidak menyerang (hp ${a.health}/${hp0})`);
});

console.log('\n[4b] player input');
check('player bergerak sesuai input & kamera', () => {
  const keys = { KeyW: true };
  const fakeInput = {
    enabled: true, isTouch: true, mouseDX: 0, mouseDY: 0, wheel: 0,
    keys, sprinting: false, jumpPressed: false, dashPressed: false,
    attackPressed: false, heavyPressed: false, blockHeld: false,
    moveVector: () => ({ forward: keys.KeyW ? 1 : 0, right: 0 }),
    requestLock() {}, exitLock() {},
  };
  const p = new Player({ name: 'P', input: fakeInput, gear });
  fakeGame.player = p;
  fakeGame.entities.push(p);
  const sp = arena.spawns[0];
  p.teleport(sp.x, sp.y + 0.2, sp.z, 0);
  p.camYaw = Math.PI;      // kamera menghadap +Z → W maju ke +Z
  const z0 = p.pos.z;
  for (let i = 0; i < 90; i++) p.update(fakeGame, 0.016);
  assert.ok(p.pos.z > z0 + 2, `player tidak maju (${z0} -> ${p.pos.z})`);
  assert.ok(Number.isFinite(p.pos.y));
});

check('player lompat', () => {
  const p = fakeGame.player;
  const y0 = p.pos.y;
  p.input.jumpPressed = true;
  p.update(fakeGame, 0.016);
  p.update(fakeGame, 0.016);
  assert.ok(p.pos.y > y0 + 0.2, `tidak melompat (${y0} -> ${p.pos.y})`);
  p.input.jumpPressed = false;
});

check('player attack memicu damage ke bot', () => {
  const p = fakeGame.player;
  const bot = fakeGame.entities.find((e) => e.isBot);
  bot.alive = true;
  bot.health = bot.maxHealth;
  bot.iframes = 0;
  bot.teleport(p.pos.x, p.pos.y, p.pos.z + 4, 0);
  p.yaw = 0;
  p.camYaw = Math.PI;
  p.attackCd = 0;
  p.attacking = null;
  p.input.attackPressed = true;
  p.update(fakeGame, 0.016);
  p.input.attackPressed = false;
  for (let i = 0; i < 25; i++) { p.update(fakeGame, 0.016); updateCombat(fakeGame, 0.016); }
  assert.ok(bot.health < bot.maxHealth, 'attack player tidak mengenai bot');
});

console.log('\n[5] lava & void');
check('zona bahaya terdeteksi', () => {
  const lavaArena = createArena(3);
  const pool = lavaArena.danger[0];
  assert.ok(pool, 'tidak ada zona lava');
  const cx = (pool.x0 + pool.x1) / 2;
  const cz = (pool.z0 + pool.z1) / 2;
  assert.ok(dangerDpsAt(lavaArena.danger, cx, pool.y1, cz) > 0);
});

console.log('\n[6] fx');
check('partikel dibuat & dibersihkan', () => {
  fakeGame.fx.length = 0;
  spawnBurst(fakeGame, new THREE.Vector3(0, 3, 0), '#fff', 6, 8);
  assert.equal(fakeGame.fx.length, 6);
  for (let i = 0; i < 120; i++) updateFx(fakeGame, 0.05);
  assert.equal(fakeGame.fx.length, 0);
});

console.log(failures ? `\n${failures} test gagal` : '\nSemua smoke test lulus ✅');
process.exit(failures ? 1 : 0);

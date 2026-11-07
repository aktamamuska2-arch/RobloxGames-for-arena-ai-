/* =========================================================================
   browser-sim.mjs — menjalankan GAME UTUH (index.html + main.js) di dalam
   jsdom dengan WebGL palsu, lalu memainkannya beberapa ribu frame.

   Tujuan: menangkap error runtime yang tidak terlihat oleh smoke-test
   (yang hanya menguji modul terpisah): boot, UI wiring, round flow,
   respawn, ganti map, shop, pause, dan chat.

   Jalankan: node scripts/browser-sim.mjs
   ========================================================================= */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { JSDOM } from 'jsdom';

await import('./vendor-link.mjs');

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/* ------------------------------ assertions ------------------------------ */
let fails = 0;
let passes = 0;
function ok(label, cond, extra = '') {
  if (cond) { passes++; console.log(`  ok   ${label}`); }
  else { fails++; console.log(`  FAIL ${label}${extra ? ` — ${extra}` : ''}`); }
}
function section(name) { console.log(`\n[${name}]`); }

/* ------------------------------ fake WebGL ------------------------------ */
function makeFakeWebGL2() {
  const consts = new Map();
  let nextConst = 0x9000;
  const methods = {
    VERSION: 0x1F02,
    VENDOR: 0x1F00,
    RENDERER: 0x1F01,
    SHADING_LANGUAGE_VERSION: 0x8B8C,
    SCISSOR_BOX: 0x0C10,
    VIEWPORT: 0x0BA2,
    ALIASED_LINE_WIDTH_RANGE: 0x846E,
    ALIASED_POINT_SIZE_RANGE: 0x846D,
    COMPRESSED_TEXTURE_FORMATS: 0x86A3,
    MAX_TEXTURE_SIZE: 0x0D33,
    MAX_CUBE_MAP_TEXTURE_SIZE: 0x851C,
    MAX_TEXTURE_IMAGE_UNITS: 0x8872,
    MAX_VERTEX_TEXTURE_IMAGE_UNITS: 0x8B4C,
    MAX_COMBINED_TEXTURE_IMAGE_UNITS: 0x8B4D,
    MAX_VERTEX_ATTRIBS: 0x8869,
    MAX_VERTEX_UNIFORM_VECTORS: 0x8DFB,
    MAX_VARYING_VECTORS: 0x8DFC,
    MAX_FRAGMENT_UNIFORM_VECTORS: 0x8DFD,
    MAX_SAMPLES: 0x8D57,
    MAX_RENDERBUFFER_SIZE: 0x84E8,
    MAX_3D_TEXTURE_SIZE: 0x8073,
    MAX_ARRAY_TEXTURE_LAYERS: 0x88FF,
    MAX_DRAW_BUFFERS: 0x8824,
    MAX_COLOR_ATTACHMENTS: 0x8CDF,
    MAX_UNIFORM_BUFFER_BINDINGS: 0x8A2F,
    MAX_UNIFORM_BLOCK_SIZE: 0x8A30,
    MAX_TEXTURE_MAX_ANISOTROPY_EXT: 0x84FF,
    FRAMEBUFFER_COMPLETE: 0x8CD5,
    LINK_STATUS: 0x8B82,
    COMPILE_STATUS: 0x8B81,
    ACTIVE_UNIFORMS: 0x8B86,
    ACTIVE_ATTRIBUTES: 0x8B89,
    UNPACK_FLIP_Y_WEBGL: 0x9240,
    UNPACK_PREMULTIPLY_ALPHA_WEBGL: 0x9241,
    UNPACK_COLORSPACE_CONVERSION_WEBGL: 0x9243,
    BROWSER_DEFAULT_WEBGL: 0x9244,
    TEXTURE_2D: 0x0DE1,
    TEXTURE0: 0x84C0,
    RGBA: 0x1908,
    UNSIGNED_BYTE: 0x1401,
    FLOAT: 0x1406,
    TRIANGLES: 0x0004,
    DEPTH_TEST: 0x0B71,
    BLEND: 0x0BE2,
    CULL_FACE: 0x0B44,
    COLOR_BUFFER_BIT: 0x4000,
    DEPTH_BUFFER_BIT: 0x0100,
    STENCIL_BUFFER_BIT: 0x0400,
    ARRAY_BUFFER: 0x8892,
    ELEMENT_ARRAY_BUFFER: 0x8893,
    STATIC_DRAW: 0x88E4,
    DYNAMIC_DRAW: 0x88E8,
    NO_ERROR: 0,
  };

  const target = {
    ...methods,
    canvas: null,
    isFakeGL: true,
    getExtension: () => null,
    getSupportedExtensions: () => [],
    getParameter(p) {
      if (process.env.SIM_DEBUG_GL) console.log('getParameter', '0x' + Number(p).toString(16));
      switch (p) {
        case 0x1F00: return 'Fake Vendor';
        case 0x1F01: return 'Fake Renderer';
        case 0x1F02: return 'WebGL 2.0 (fake)';
        case 0x8B8C: return 'WebGL GLSL ES 3.00 (fake)';
        case 0x0C10:
        case 0x0BA2: return new Int32Array([0, 0, 1280, 720]);
        case 0x846D:
        case 0x846E: return new Float32Array([1, 1]);
        case 0x86A3: return new Uint32Array([]);
        case 0x8872: case 0x8B4C: case 0x8B4D: case 0x8869:
        case 0x8DFB: case 0x8DFC: case 0x8DFD:
        case 0x8D57: case 0x8824: case 0x8CDF: case 0x88FF:
        case 0x8A2F: return 16;
        case 0x8A30: return 65536;
        case 0x84FF: return 16;
        default: return 4096;
      }
    },
    getShaderPrecisionFormat: () => ({ rangeMin: 127, rangeMax: 127, precision: 23 }),
    getProgramParameter: (prog, p) => (p === 0x8B82 ? true : 0),
    getShaderParameter: () => true,
    getProgramInfoLog: () => '',
    getShaderInfoLog: () => '',
    getError: () => 0,
    getUniformLocation: () => ({ fake: true }),
    getAttribLocation: () => 0,
    getActiveUniform: () => ({ name: 'u', size: 1, type: 0x1406 }),
    getActiveAttrib: () => ({ name: 'a', size: 1, type: 0x1406 }),
    createShader: () => ({}),
    createProgram: () => ({}),
    createBuffer: () => ({}),
    createTexture: () => ({}),
    createFramebuffer: () => ({}),
    createRenderbuffer: () => ({}),
    createVertexArray: () => ({}),
    createQuery: () => ({}),
    createSampler: () => ({}),
    createTransformFeedback: () => ({}),
    checkFramebufferStatus: () => 0x8CD5,
    isContextLost: () => false,
    getContextAttributes: () => ({ alpha: true, antialias: true, depth: true, stencil: true }),
    getUniformBlockIndex: () => 0,
    getActiveUniformBlockParameter: () => 0,
    getActiveUniforms: () => [],
    readPixels: () => {},
    pixelStorei: () => {},
  };

  const proxy = new Proxy(target, {
    get(t, prop) {
      if (prop in t) return t[prop];
      if (typeof prop === 'string' && /^[A-Z][A-Z0-9_]*$/.test(prop)) {
        if (!consts.has(prop)) consts.set(prop, nextConst++);
        return consts.get(prop);
      }
      if (typeof prop === 'string') {
        if (consts.has(`__fn_${prop}`) === false) consts.set(`__fn_${prop}`, true);
        const noop = () => undefined;
        t[prop] = noop;
        return noop;
      }
      return undefined;
    },
  });
  return proxy;
}

/* ------------------------------- environment ---------------------------- */
const html = fs.readFileSync(path.join(ROOT, 'web/index.html'), 'utf8');
const dom = new JSDOM(html, { url: 'http://localhost:8080/', pretendToBeVisual: true });
const { window } = dom;

const errors = [];
window.addEventListener('error', (e) => errors.push(e.error || e.message));

const drawLog = [];
function fake2d() {
  const grad = { addColorStop() {} };
  const noop = () => {};
  const rec = {
    fillRect: (...a) => drawLog.push({ op: 'fillRect', args: a }),
    fillText: (...a) => drawLog.push({ op: 'fillText', args: a }),
  };
  return new Proxy({
    canvas: null,
    createRadialGradient: () => grad,
    createLinearGradient: () => grad,
    createPattern: () => ({}),
    measureText: () => ({ width: 42 }),
    getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    putImageData: noop,
    fillRect: rec.fillRect,
    fillText: rec.fillText,
  }, {
    get(t, p) { return p in t ? t[p] : noop; },
    set(t, p, v) {
      if (p === 'fillStyle' || p === 'strokeStyle') drawLog.push({ op: p, value: v });
      t[p] = v; return true;
    },
  });
}

let glCalls = 0;
window.HTMLCanvasElement.prototype.getContext = function getContext(kind) {
  if (kind === '2d') return fake2d();
  if (kind === 'webgl2' || kind === 'webgl' || kind === 'experimental-webgl') {
    glCalls++;
    if (!this.__gl) this.__gl = makeFakeWebGL2();
    this.__gl.canvas = this;
    return this.__gl;
  }
  return null;
};

window.WebGL2RenderingContext = class WebGL2RenderingContext {};

/* salin global yang dipakai modul */
for (const key of [
  'document', 'navigator', 'location', 'HTMLElement', 'HTMLCanvasElement',
  'Element', 'Node', 'Event', 'MouseEvent', 'KeyboardEvent', 'WheelEvent', 'TouchEvent',
  'CustomEvent', 'Image', 'ImageData', 'DOMParser', 'WebGL2RenderingContext',
]) {
  if (!(key in window)) continue;
  try {
    Object.defineProperty(globalThis, key, { value: window[key], configurable: true, writable: true });
  } catch { /* getter-only di Node 22: pakai versi yang sudah ada */ }
}
globalThis.window = window;
globalThis.self = window;
globalThis.matchMedia = window.matchMedia?.bind(window) || (() => ({ matches: false, addEventListener() {} }));
window.matchMedia = window.matchMedia || (() => ({ matches: false, addEventListener() {} }));

const rafQueue = [];
window.requestAnimationFrame = (fn) => { rafQueue.push(fn); return rafQueue.length; };
globalThis.requestAnimationFrame = window.requestAnimationFrame;
window.cancelAnimationFrame = () => {};
globalThis.cancelAnimationFrame = () => {};

const mem = new Map();
const ls = {
  getItem: (k) => (mem.has(k) ? mem.get(k) : null),
  setItem: (k, v) => mem.set(k, String(v)),
  removeItem: (k) => mem.delete(k),
  clear: () => mem.clear(),
  key: (i) => [...mem.keys()][i] ?? null,
  get length() { return mem.size; },
};
Object.defineProperty(window, 'localStorage', { value: ls, configurable: true });
Object.defineProperty(globalThis, 'localStorage', { value: ls, configurable: true });

globalThis.devicePixelRatio = 1;
window.devicePixelRatio = 1;

/* AudioContext stub */
class FakeParam {
  constructor(v = 0) { this.value = v; }
  setValueAtTime() { return this; }
  linearRampToValueAtTime() { return this; }
  exponentialRampToValueAtTime() { return this; }
  cancelScheduledValues() { return this; }
}
class FakeNode {
  constructor() { this.gain = new FakeParam(1); this.frequency = new FakeParam(440); this.Q = new FakeParam(1); }
  connect(n) { return n; }
  disconnect() {}
  start() {}
  stop() {}
}
class FakeAudioContext {
  constructor() { this.currentTime = 0; this.sampleRate = 44100; this.state = 'running'; this.destination = new FakeNode(); }
  createGain() { return new FakeNode(); }
  createOscillator() { const o = new FakeNode(); o.frequency = new FakeParam(440); return o; }
  createBiquadFilter() { const f = new FakeNode(); f.frequency = new FakeParam(1000); f.Q = new FakeParam(1); return f; }
  createBuffer(ch, len) { return { getChannelData: () => new Float32Array(len) }; }
  createBufferSource() { const s = new FakeNode(); s.loop = false; s.buffer = null; return s; }
  resume() { this.state = 'running'; return Promise.resolve(); }
}
window.AudioContext = FakeAudioContext;
globalThis.AudioContext = FakeAudioContext;

/* pointer lock stub */
window.document.pointerLockElement = null;
window.document.exitPointerLock = () => { window.document.pointerLockElement = null; };
window.HTMLCanvasElement.prototype.requestPointerLock = function () {
  window.document.pointerLockElement = this;
  window.document.dispatchEvent(new window.Event('pointerlockchange'));
  return Promise.resolve();
};

/* RNG deterministik supaya hasil tes stabil */
let seed = 1337;
Math.random = () => {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 4294967296;
};

/* clock stabil */
let now = 0;
const realPerfNow = window.performance.now.bind(window.performance);
window.performance.now = () => now;
globalThis.performance = window.performance;

/* ------------------------------- jalankan ------------------------------- */
section('boot');
const mainPath = path.join(ROOT, 'web/js/main.js');
await import(`file://${mainPath}`);
const game = window.__GAME || globalThis.__GAME;
ok('Game tercipta', !!game, 'window.__GAME tidak ada');
if (!game) {
  console.log('\nBoot gagal. Error:', errors.map(String));
  process.exit(1);
}
ok('WebGL context dipanggil', glCalls > 0);
ok('layar fatal tidak tampil', document.getElementById('fatal').classList.contains('hidden'));
ok('arena awal dibuat', !!game.arena && game.arena.colliders.length > 10, `colliders=${game.arena?.colliders.length}`);
ok('player + 7 bot', game.entities.length === 8, `entities=${game.entities.length}`);
ok('avatar player ada di scene', !!game.player.avatar.group.parent);

/* senjata tidak boleh menusuk lantai */
const THREE_NS = await import('three');
game.player.avatar.group.updateMatrixWorld(true);
const swordBox = new THREE_NS.Box3().setFromObject(game.player.avatar.sword);
ok('senjata dipegang di atas lantai',
  Number.isFinite(swordBox.min.y) && swordBox.min.y > game.player.pos.y - 1.2,
  `min.y=${swordBox.min.y?.toFixed(2)} feet=${game.player.pos.y.toFixed(2)}`);

/* wajah harus digambar dengan latar warna kulit (bukan transparan → hitam) */
const { makeFaceTexture } = await import('../web/js/textures.js');
makeFaceTexture('#abcdef');
ok('wajah punya latar warna kulit',
  drawLog.some((c) => c.op === 'fillStyle' && c.value === '#abcdef'),
  'fillStyle kulit tidak pernah dipakai');
ok('state awal = menu', game.state === 'menu');
ok('HUD tersembunyi di menu', document.getElementById('hud').classList.contains('hidden'));

/* jalankan render beberapa frame di menu */
now += 16;
for (let i = 0; i < 5; i++) {
  const cbs = rafQueue.splice(0);
  for (const cb of cbs) cb(now);
  now += 16;
}
ok('loop menu berjalan tanpa error', errors.length === 0, errors.join(' | '));

/* ------------------------------- mulai main ----------------------------- */
section('PLAY');
document.getElementById('name-input').value = 'Tester';
document.getElementById('btn-play').click();
ok('state = playing setelah PLAY', game.state === 'playing', game.state);
ok('menu tersembunyi', document.getElementById('screen-menu').classList.contains('hidden'));
ok('HUD tampil', !document.getElementById('hud').classList.contains('hidden'));
ok('nama player dari input', game.player.name === 'Tester', game.player.name);

/* helper frame */
function frames(n, dt = 1 / 60) {
  for (let i = 0; i < n; i++) {
    now += dt * 1000;
    game.update(dt);
  }
}
function stepRaf(times = 3) {
  for (let i = 0; i < times; i++) {
    now += 16;
    const cbs = rafQueue.splice(0);
    for (const cb of cbs) cb(now);
  }
}

frames(30);
ok('intermission berjalan', game.phase === 'intermission', game.phase);
ok('banner round terlihat saat main', !document.getElementById('round-banner').classList.contains('hidden'),
  'round-banner masih hidden (bug UI)');
ok('leaderboard tampil', !document.getElementById('leaderboard').classList.contains('hidden'));

/* habiskan intermission */
frames(60 * 21);
ok('fase jadi round', game.phase === 'round', game.phase);

/* gerak: cari arah yang tidak terhalang dinding (deterministik, bukan untung-untungan) */
let bestMove = 0;
for (const key of ['KeyW', 'KeyS', 'KeyA', 'KeyD']) {
  const sp = game.arena.spawns[0];
  game.player.teleport(sp.x, sp.y + 0.4, sp.z, 0);
  game.player.alive = true;
  game.player.health = game.player.maxHealth;
  game.player.camYaw = Math.atan2(sp.x, sp.z);   // kamera di belakang, maju ke tengah map
  game.player.camPitch = -0.2;
  frames(6);
  const from = game.player.pos.clone();
  game.input.keys[key] = true;
  frames(45);
  game.input.keys[key] = false;
  bestMove = Math.max(bestMove, game.player.pos.distanceTo(from));
}
ok('player bisa bergerak (minimal satu arah)', bestMove > 1.5, `jarak terbaik=${bestMove.toFixed(2)}`);
const yBefore = game.player.pos.y;
game.input.jumpPressed = true;
frames(1);
game.input.jumpPressed = false;
frames(8);
ok('player lompat', game.player.pos.y > yBefore + 0.3, `y ${yBefore.toFixed(2)} → ${game.player.pos.y.toFixed(2)}`);

/* serang: isolasi satu bot di depan player supaya hasilnya pasti */
for (const b of game.bots.slice(1)) { b.alive = false; b.respawnT = 999; b.pos.set(0, -400, 0); }
const bot = game.bots[0];
bot.alive = true; bot.respawnT = 0; bot.blocking = false; bot.iframes = 0;
bot.attacking = null; bot.attackCd = 0; bot.health = bot.maxHealth;
const sp0 = game.arena.spawns[0];
game.player.teleport(sp0.x, sp0.y + 0.4, sp0.z, 0);
game.player.alive = true; game.player.health = game.player.maxHealth;
game.player.blocking = false; game.player.attacking = null; game.player.attackCd = 0; game.player.iframes = 0;
// kamera di belakang karakter (menghadap +Z) supaya arah hadap tidak berubah saat update
game.player.camYaw = Math.PI;
frames(2);
bot.pos.set(
  game.player.pos.x + Math.sin(game.player.yaw) * 3,
  game.player.pos.y,
  game.player.pos.z + Math.cos(game.player.yaw) * 3,
);
const hp0 = bot.health;
game.input.attackPressed = true;
frames(1);
game.input.attackPressed = false;
frames(16);
if (process.env.SIM_DEBUG_ATTACK) {
  console.log('DEBUG attack', {
    alive: game.player.alive, cd: game.player.attackCd, blocking: game.player.blocking,
    attacking: !!game.player.attacking, combatEnabled: game.combatEnabled,
    dist: Math.hypot(bot.pos.x - game.player.pos.x, bot.pos.z - game.player.pos.z).toFixed(2),
    dy: (bot.pos.y - game.player.pos.y).toFixed(2),
    yaw: game.player.yaw.toFixed(2), botAlive: bot.alive, botIframes: bot.iframes.toFixed(2),
    playerIframes: game.player.iframes.toFixed(2),
  });
}
ok('serangan player melukai bot', bot.health < hp0, `hp ${hp0} → ${bot.health}`);
ok('damage number muncul saat hit', document.querySelectorAll('#damage-layer .dmg').length > 0);

/* hidupkan lagi bot untuk uji AI */
for (const b of game.bots.slice(1)) { b.alive = true; b.respawnT = 0; b.health = b.maxHealth; b.avatar.setDead(false); }

/* semua angka harus finite (NaN = layar hitam di browser) */
let badPos = null;
for (const e of game.entities) {
  if (![e.pos.x, e.pos.y, e.pos.z, e.vel.x, e.vel.y, e.vel.z, e.yaw].every(Number.isFinite)) badPos = e.name;
}
ok('posisi/velocity semua entitas finite', !badPos, `NaN pada ${badPos}`);
const cp = game.world.camera.position;
ok('posisi kamera finite', [cp.x, cp.y, cp.z].every(Number.isFinite), `${cp.x},${cp.y},${cp.z}`);
ok('avatar mengikuti posisi entitas', Math.abs(game.player.avatar.group.position.y - game.player.pos.y) < 0.01);
ok('tidak ada mesh dengan posisi NaN', game.scene.children.every((c) => Number.isFinite(c.position.x)) );

/* bot AI bergerak */
const bpos = game.bots[1].pos.clone();
frames(240);
let moved = false;
for (const b of game.bots) if (b.pos.distanceTo(bpos) > 0.5) moved = true;
ok('bot AI bergerak', moved);

/* toast muncul */
ok('toast muncul', document.querySelectorAll('#toasts .toast').length > 0);

/* health bar HUD berubah */
const hpPct = (game.player.health / game.player.maxHealth) * 100;
const hpWidth = parseFloat(document.getElementById('hp-fill').style.width || 'NaN');
ok('HUD health sesuai HP player', Math.abs(hpWidth - hpPct) < 0.6, `width=${hpWidth} vs ${hpPct.toFixed(1)}`);

/* intermission = aman (tidak ada damage) */
section('intermission aman');
game.player.health = game.player.maxHealth;
const botAtk = game.bots[0];
botAtk.pos.copy(game.player.pos);
botAtk.pos.x += 2;
botAtk.target = game.player;
const hpSafe = game.player.health;
game.combatEnabled = false;
botAtk.attackThink = 0;
botAtk.attacking = null;
botAtk.attackCd = 0;
frames(120);
ok('tidak ada damage saat combatEnabled=false', game.player.health >= hpSafe - 0 || game.player.health === hpSafe,
  `hp ${hpSafe} → ${game.player.health}`);
game.combatEnabled = true;

/* bunuh player → respawn */
section('kematian & respawn');
const before = game.player.stats.deaths;
game.player.health = 1;
game.player.iframes = 0;
game.player.blocking = false;
game.player.pos.y = -999;
frames(2);
ok('player mati saat jatuh', !game.player.alive || game.player.stats.deaths > before);
frames(60 * 5);
ok('player respawn otomatis', game.player.alive, 'player tidak respawn');

/* ganti map manual via command */
section('chat & shop');
game.command('/map lava');
ok('command /map mengganti arena', game.arena.name === 'Lava Foundry', game.arena.name);
game.command('/help');
game.command('/coins');
game.command('/stats');
ok('chat log terisi', document.getElementById('chat-log').children.length >= 2);

/* shop: buka, beli, tutup */
game.addCoins(500, '', true);
const lvlBefore = game.player.gear.lightMul;
document.getElementById('btn-shop').click();
ok('shop terbuka', !document.getElementById('screen-shop').classList.contains('hidden'));
ok('game dijeda saat shop', game.paused === true);
const card = document.querySelector('#shop-grid .shop-card[data-id="sword"] button');
ok('kartu shop dirender', !!card);
card?.click();
ok('beli katana menaikkan damage', game.player.gear.lightMul > lvlBefore,
  `lightMul ${lvlBefore} → ${game.player.gear.lightMul}`);
document.getElementById('btn-shop-close').click();
ok('shop tertutup & resume', game.paused === false && document.getElementById('screen-shop').classList.contains('hidden'));

/* pause & settings */
document.getElementById('btn-menu').click();
ok('pause terbuka', !document.getElementById('screen-pause').classList.contains('hidden'));
document.getElementById('btn-resume').click();
ok('resume menutup pause', document.getElementById('screen-pause').classList.contains('hidden'));

/* selesaikan round sampai results */
section('round selesai');
frames(Math.ceil(120 * 60) + 120);
ok('masuk layar results', game.state === 'results', game.state);
ok('tabel results terisi', document.querySelectorAll('#results-table .board-row').length >= 8,
  `rows=${document.querySelectorAll('#results-table .board-row').length}`);
ok('winner terisi', document.getElementById('results-winner').textContent.trim().length > 0);
/* Esc di layar hasil tidak boleh membuka pause / membuat game nyangkut */
document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Escape', code: 'Escape', bubbles: true }));
window.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Escape', code: 'Escape', bubbles: true }));
ok('Esc di results tidak membuka pause', document.getElementById('screen-pause').classList.contains('hidden'));
ok('state tetap results', game.state === 'results', game.state);

document.getElementById('btn-results-continue').click();
ok('lanjut ke intermission berikutnya', game.state === 'playing' && game.roundNumber === 2,
  `state=${game.state} round=${game.roundNumber}`);

/* mainkan round ke-2 sebentar */
frames(60 * 25);
ok('round 2 berjalan', game.phase === 'round', game.phase);
stepRaf(3);
ok('loop rAF tetap hidup', rafQueue.length > 0);

/* kamera tidak boleh nyangkut di dalam karakter */
section('kamera');
const camDist = game.world.camera.position.distanceTo(
  new (await import('three')).Vector3(game.player.pos.x, game.player.pos.y + 4, game.player.pos.z)
);
ok('jarak kamera wajar (tidak menembus karakter)', camDist > 2.5, `dist=${camDist.toFixed(2)}`);
ok('kamera di dalam batas map', Math.abs(game.world.camera.position.x) < 250);

/* pengaturan: ganti kualitas & volume tidak error */
game.world.setQuality('low');
game.world.setQuality('high');
ok('ganti kualitas grafis aman', true);

/* ---------------- stabilitas: beberapa round berturut-turut ---------------- */
section('stabilitas multi-round');
const { ROUND } = await import('../web/js/config.js');
const sceneBase = game.scene.children.length;
ROUND.intermission = 4;
ROUND.duration = 12;
game.state = 'playing';
game.paused = false;
let roundsPlayed = 0;
for (let r = 0; r < 4; r++) {
  frames(60 * 4 + 30);
  if (game.phase === 'round') roundsPlayed++;
  frames(60 * 13);
  if (game.state === 'results') {
    roundsPlayed++;
    document.getElementById('btn-results-continue').click();
  }
}
const sceneNow = game.scene.children.length;
ok('beberapa round tambahan berjalan', roundsPlayed >= 4, `rounds=${roundsPlayed}`);
ok('jumlah objek scene tidak bocor', Math.abs(sceneNow - sceneBase) <= 4, `${sceneBase} → ${sceneNow}`);
ok('partikel tidak menumpuk', game.fx.length < 60, `fx=${game.fx.length}`);
ok('entitas tetap 8', game.entities.length === 8, `entities=${game.entities.length}`);
const bigGroups = game.scene.children.filter((c) => c.type === 'Group' && c.children.length > 30);
ok('hanya satu arena di scene (arena lama dibuang)', bigGroups.length === 1, `bigGroups=${bigGroups.length}`);
ok('arena aktif ada di scene', game.scene.children.includes(game.arena.group));
const nan = game.entities.some((e) => !Number.isFinite(e.pos.x) || !Number.isFinite(e.pos.y));
ok('tidak ada NaN setelah 4 round', !nan);
ok('tidak ada error setelah 4 round', errors.length === 0, errors.slice(0, 2).join(' | '));

/* ---------------- keluar ke menu lalu main lagi ---------------- */
section('quit ke menu → main lagi');
game.quitToMenu();
ok('state = menu', game.state === 'menu');
ok('menu tampil lagi', !document.getElementById('screen-menu').classList.contains('hidden'));
document.getElementById('btn-play').click();
ok('bisa mulai lagi', game.state === 'playing');
ok('roundNumber kembali 1', game.roundNumber === 1, `round=${game.roundNumber}`);
frames(60 * 6);
ok('berjalan tanpa error setelah restart', errors.length === 0, errors.slice(0, 2).join(' | '));

/* ---------------- shop: max level & refund ---------------- */
section('shop lanjutan');
game.addCoins(5000, '', true);
for (let i = 0; i < 5; i++) document.querySelector('#shop-grid .shop-card[data-id="sword"] button')?.click();
ok('level item dibatasi maxLevel', game.player.gear.lightMul <= 1 + 0.18 * 3 + 0.0001,
  `lightMul=${game.player.gear.lightMul.toFixed(2)}`);
const coinsBeforeRefund = game.player ? (await import('../web/js/store.js')).Store.coins : 0;
document.getElementById('btn-shop-reset')?.click();
const { Store: StoreRef } = await import('../web/js/store.js');
ok('reset gear mengembalikan koin', StoreRef.coins > coinsBeforeRefund, `${coinsBeforeRefund} → ${StoreRef.coins}`);
ok('gear kembali normal setelah reset', game.player.gear.lightMul === 1, `lightMul=${game.player.gear.lightMul}`);
document.getElementById('btn-shop-close').click();

/* cek tidak ada error JS sama sekali */
section('hasil');
ok('tidak ada error JS selama simulasi', errors.length === 0, errors.slice(0, 3).join(' | '));
ok('layar fatal tidak pernah tampil', document.getElementById('fatal').classList.contains('hidden'),
  document.getElementById('fatal').textContent.slice(0, 120));

console.log(`\n${passes} lulus, ${fails} gagal`);
if (fails) {
  console.log('\nDaftar error:', errors);
  process.exit(1);
}
console.log('Simulasi browser lulus ✅');

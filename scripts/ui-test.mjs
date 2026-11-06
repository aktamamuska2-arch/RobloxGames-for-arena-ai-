/* =========================================================================
   ui-test.mjs — uji lapisan UI memakai jsdom: memastikan semua id/selector
   yang dipakai ui.js benar-benar ada di index.html, lalu memicu tombol dan
   memeriksa DOM berubah tanpa error.
   Jalankan: node scripts/ui-test.mjs   (butuh `npm i -D jsdom`)
   ========================================================================= */

import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert';
import { fileURLToPath } from 'node:url';
import { JSDOM } from 'jsdom';
await import('./vendor-link.mjs');

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const html = fs.readFileSync(path.join(root, 'web', 'index.html'), 'utf8');

const dom = new JSDOM(html, { url: 'http://localhost:8080/', pretendToBeVisual: true });
const { window } = dom;

globalThis.window = window;
globalThis.document = window.document;
try { Object.defineProperty(globalThis, 'navigator', { value: window.navigator, configurable: true }); } catch {}
globalThis.HTMLElement = window.HTMLElement;
globalThis.localStorage = window.localStorage;
window.matchMedia = window.matchMedia || (() => ({ matches: false, addListener() {}, removeListener() {} }));

/* jsdom tanpa paket `canvas` → getContext('2d') mengembalikan null.
   UI tidak memakai canvas, tapi Audio/three bisa menyentuhnya. */
window.HTMLCanvasElement.prototype.getContext = function () { return null; };

const THREE = await import('three');
const { UI } = await import('../web/js/ui.js');
const { Store } = await import('../web/js/store.js');

Store.load();
Store.data.coins = 5000;
Store.save();

const calls = [];
const fakePlayer = {
  name: 'Tester', health: 80, maxHealth: 120, stamina: 55, maxStamina: 100,
  sprinting: false, killstreak: 3, attacking: null, attackCd: 0.2,
  stats: { kills: 2, deaths: 1 }, pos: new THREE.Vector3(0, 0, 0),
  avatar: { colors: { shirt: '#00b06f' } },
  setHealth(h) { this.health = h; },
};

const game = {
  state: 'menu', paused: false, roundName: 'Round 1',
  input: { isTouch: false, enabled: true, bindJoystick() {}, trigger() {}, exitLock() {}, requestLock() {} },
  world: {
    camera: new THREE.PerspectiveCamera(70, 16 / 9, 0.1, 1000),
    sens: 1, shakeEnabled: true,
    setFov() { calls.push('fov'); },
    setQuality(q) { calls.push(`quality:${q}`); },
    shake() {},
  },
  player: fakePlayer,
  entities: [fakePlayer],
  start() { calls.push('start'); this.state = 'playing'; },
  openShop() { calls.push('openShop'); this.paused = true; },
  closeOverlay(n) { calls.push(`close:${n}`); this.paused = false; },
  setPaused(v) { calls.push(`paused:${v}`); this.paused = v; },
  togglePause() { calls.push('togglePause'); },
  quitToMenu() { calls.push('quit'); },
  applyGear() { calls.push('applyGear'); },
  command(c) { calls.push(`cmd:${c}`); },
  say(t) { calls.push(`say:${t}`); },
  continueFromResults() { calls.push('continue'); },
};

let failures = 0;
function check(name, fn) {
  try { fn(); console.log(`  ok   ${name}`); }
  catch (err) { failures++; console.error(`  FAIL ${name}\n${err.stack || err}`); }
}

console.log('\n[1] konstruksi UI');
let ui;
check('UI dibuat tanpa error', () => {
  ui = new UI(game);
  assert.ok(ui.el.hud, 'hud tidak ditemukan');
  assert.ok(ui.el.shopGrid.children.length > 0, 'shop kosong');
});

console.log('\n[2] interaksi');
check('klik PLAY memanggil game.start', () => {
  document.getElementById('name-input').value = 'Budi';
  document.getElementById('btn-play').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  assert.ok(calls.includes('start'));
  assert.equal(Store.name, 'Budi');
});

check('buka shop & beli item', () => {
  const before = Store.coins;
  const card = ui.el.shopGrid.querySelector('.shop-card');
  const id = card.dataset.id;
  card.querySelector('button').dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
  assert.ok(Store.level(id) === 1, 'level item tidak naik');
  assert.ok(Store.coins < before, 'koin tidak berkurang');
  assert.ok(calls.includes('applyGear'));
});

check('toast & chat muncul', () => {
  const before = ui.el.toasts.children.length;
  ui.toast('halo', 'gold');
  assert.equal(ui.el.toasts.children.length, before + 1);
  const beforeChat = ui.el.chatLog.children.length;
  ui.addChat('Bot1: gg');
  assert.equal(ui.el.chatLog.children.length, beforeChat + 1);
  assert.match(ui.el.chatLog.textContent, /Bot1/);
});

check('damage number diproyeksikan', () => {
  game.world.camera.position.set(0, 10, 20);
  game.world.camera.lookAt(0, 0, 0);
  game.world.camera.updateMatrixWorld();
  ui.damageNumber(new THREE.Vector3(0, 3, 0), '17', 'crit');
  assert.equal(ui.el.dmgLayer.children.length, 1);
});

check('refreshHealth memperbarui bar', () => {
  ui.refreshHealth();
  assert.match(ui.el.hpText.textContent, /80 \/ 120/);
  assert.ok(Math.abs(parseFloat(ui.el.hpFill.style.width) - (80 / 120) * 100) < 0.01);
});

check('leaderboard dirender', () => {
  ui.toggleLeaderboard(true);
  assert.ok(!ui.el.board.classList.contains('hidden'));
  assert.ok(ui.el.boardRows.children.length >= 1);
});

check('round info & cooldown', () => {
  ui.setRoundInfo('Neon Grid', 'Round 2', 95, false);
  assert.equal(ui.el.roundTimer.textContent, '1:35');
  assert.equal(ui.el.roundMap.textContent, 'Neon Grid');
});

check('hasil round dirender', () => {
  ui.showResults([
    { name: 'A', color: '#fff', kills: 5, deaths: 1, coins: 70, me: true },
    { name: 'B', color: '#f00', kills: 2, deaths: 4, coins: 0, me: false },
  ], 'Brick Arena', 'A');
  assert.ok(!ui.el.results.classList.contains('hidden'));
  assert.match(ui.el.resultsWinner.textContent, /A/);
});

check('settings slider menyimpan nilai', () => {
  const el = document.getElementById('set-vol');
  el.value = '0.3';
  el.dispatchEvent(new window.Event('input', { bubbles: true }));
  assert.equal(Number(Store.settings.volume), 0.3);
  assert.match(document.getElementById('val-vol').textContent, /0\.30/);
});

check('chat submit lewat UI', () => {
  ui.openChat('');
  ui.el.chatInput.value = '/help';
  ui.submitChat();
  assert.ok(calls.some((c) => c.startsWith('cmd:/help')), 'command tidak terkirim');
});

check('semua selector penting ada', () => {
  const ids = [
    'hud', 'topbar', 'round-banner', 'hp-fill', 'hp-text', 'stamina-fill',
    'chat-log', 'chat-input', 'leaderboard', 'board-rows', 'toasts', 'damage-layer',
    'crosshair', 'cooldown-ring', 'screen-menu', 'screen-shop', 'screen-pause',
    'screen-settings', 'screen-howto', 'screen-results', 'screen-loading',
    'btn-play', 'btn-menu-shop', 'btn-menu-howto', 'btn-menu-settings',
    'btn-menu', 'btn-chat', 'btn-shop', 'btn-board', 'btn-settings',
    'btn-resume', 'btn-pause-shop', 'btn-pause-settings', 'btn-pause-howto',
    'btn-pause-menu', 'btn-shop-close', 'btn-shop-reset', 'shop-grid',
    'btn-results-continue', 'mobile-ui', 'stick', 'stick-knob',
    'set-sens', 'set-vol', 'set-fov', 'set-quality', 'set-shake', 'set-music', 'set-mobile',
  ];
  const missing = ids.filter((id) => !document.getElementById(id));
  assert.deepEqual(missing, [], `id hilang: ${missing.join(', ')}`);
});

console.log(failures ? `\n${failures} test UI gagal` : '\nSemua test UI lulus ✅');
process.exit(failures ? 1 : 0);

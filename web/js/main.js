/* =========================================================================
   main.js — orkestrasi game: state machine round, spawn entity,
   map randomizer, input UI, chat command, dan game loop.
   ========================================================================= */

import * as THREE from 'three';
import {
  PHYS, COMBAT, ROUND, PALETTE, BOT_NAMES, CAMERA,
} from './config.js';
import { Store, gearStats } from './store.js';
import { World } from './scene.js';
import { createArena, MAP_INFO, arenaCount } from './maps.js';
import { Player } from './player.js';
import { Bot } from './bots.js';
import { Audio } from './audio.js';
import { UI } from './ui.js';
import { Input } from './input.js';
import { updateCombat, updateFx, respawn as respawnFighter, killFighter } from './combat.js';
import { separateEntities } from './physics.js';
import { Chatter } from './markov.js';

class Game {
  constructor() {
    Store.load();

    this.canvas = document.getElementById('game');
    this.world = new World(this.canvas);
    this.scene = this.world.scene;
    this.world.shakeEnabled = Store.settings.shake !== false;
    this.world.sens = Store.settings.sensitivity || 1;
    this.world.setFov(Store.settings.fov || CAMERA.fov);

    this.input = new Input(this.canvas);
    this.input.attach();

    this.entities = [];
    this.player = null;
    this.bots = [];
    this.arena = null;
    this.fx = [];
    this.fxGroup = new THREE.Group();
    this.scene.add(this.fxGroup);
    this.time = 0;
    this.state = 'menu';             // menu | playing | results
    this.paused = false;
    this.phase = 'intermission';     // intermission | round | results
    this.phaseT = 0;
    this.roundNumber = 1;
    this.roundName = 'Intermission';
    this.roundResults = null;
    this.combatEnabled = false;      // hanya true selama fase round
    this.stats = { kills: 0, deaths: 0, coinsEarned: 0 };
    this.roundCoins = new Map();
    this.clock = new THREE.Clock();

    this.ui = new UI(this);
    Audio.setVolume(Store.settings.volume ?? 0.6);
    this.applySettings();

    this.bindGlobalKeys();
    this.bindWindow();

    // pre-build arena supaya menu punya background 3D
    this.loadArena(Math.floor(Math.random() * arenaCount()), true);
    this.spawnEntities(true);

    this.ui.hide('loading');
    this.ui.show('menu');
    this.ui.hide('hud');
    this.ui.updateMobileVisibility(Store.settings.forceMobile);

    // animasi kamera menu
    this.menuCamAngle = 0;
    this.wasLocked = false;

    requestAnimationFrame(() => this.loop());
  }

  /* ============================== setup ============================== */
  applySettings() {
    const s = Store.settings;
    Audio.setVolume(s.volume ?? 0.6);
    this.world.sens = s.sensitivity ?? 1;
    this.world.setFov(s.fov ?? CAMERA.fov);
    this.world.setQuality(s.quality || 'high');
    this.world.shakeEnabled = s.shake !== false;
    if (s.music) {
      Audio.unlock();
      Audio.setMusic(true);
    }
  }

  bindWindow() {
    document.addEventListener('visibilitychange', () => {
      if (document.hidden && this.state === 'playing' && !this.paused) this.setPaused(true);
    });
    this.canvas.addEventListener('click', () => {
      if (this.state === 'playing' && !this.paused && !this.ui.isOverlayOpen() && !this.ui.chatOpen) {
        this.input.requestLock();
      }
    });
    window.addEventListener('resize', () => this.ui.updateMobileVisibility(Store.settings.forceMobile));
  }

  bindGlobalKeys() {
    this.input.listeners.key.push((code, ev) => {
      // saat mengetik di chat, jangan proses hotkey
      if (this.ui.chatOpen) return;

      if (code === 'Escape') {
        ev.preventDefault();
        // di layar hasil round, Esc tidak membuka pause (bisa membuat game nyangkut)
        if (this.state === 'results') return;
        if (this.ui.isOverlayOpen() && !this.paused) {
          // tutup overlay yang terbuka (settings/howto/shop)
          const shopOpen = !this.ui.el.shop.classList.contains('hidden');
          if (shopOpen) this.closeShop();
          else if (!this.ui.el.settings.classList.contains('hidden')) this.ui.hide('settings');
          else if (!this.ui.el.howto.classList.contains('hidden')) this.ui.hide('howto');
          else if (!this.ui.el.results.classList.contains('hidden')) return;
          return;
        }
        this.togglePause();
        return;
      }

      if (this.state !== 'playing') return;

      if (code === 'Tab') {
        ev.preventDefault();
        this.ui.toggleLeaderboard();
      }
      if (code === 'KeyB') this.ui.openShop();
      if (code === 'Enter' || code === 'NumpadEnter') {
        ev.preventDefault();
        this.ui.openChat();
      }
      if (code === 'Slash') {
        ev.preventDefault();
        this.ui.openChat('/');
      }
      if (code === 'KeyM') {
        const on = !Store.settings.music;
        Store.setSetting('music', on);
        Audio.setMusic(on);
        this.ui.syncSettings();
        this.ui.toast(`Musik ${on ? 'on' : 'off'}`);
      }
      if (code === 'KeyH') this.ui.toggleLeaderboard(false);
    });

    window.addEventListener('keydown', (e) => {
      if (e.key === '/' && !this.ui.chatOpen && this.state === 'playing' && !this.ui.isOverlayOpen()) {
        e.preventDefault();
        this.ui.openChat('/');
      }
    });
  }

  /* ============================== entity ============================== */
  spawnEntities(silent = false) {
    // bersihkan
    for (const e of this.entities) {
      this.scene.remove(e.avatar.group);
      e.dispose();
    }
    this.entities = [];
    this.bots = [];

    const name = Store.name || randomName();
    const player = new Player({
      name,
      input: this.input,
      look: {
        skin: PALETTE.skin[0], shirt: PALETTE.shirt[2],
        pants: PALETTE.pants[0], hair: PALETTE.hair[0],
      },
      gear: gearStats(Store),
    });
    this.player = player;
    this.entities.push(player);
    this.scene.add(player.avatar.group);

    const botCount = Store.settings.botCount || 7;
    const used = new Set();
    for (let i = 0; i < botCount; i++) {
      let n = '';
      for (let tries = 0; tries < BOT_NAMES.length + 4; tries++) {
        const cand = BOT_NAMES[Math.floor(Math.random() * BOT_NAMES.length)];
        if (!used.has(cand)) { n = cand; break; }
      }
      if (!n) n = `Guest ${1000 + i}`;   // jangan pernah loop tanpa akhir
      used.add(n);
      const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
      const bot = new Bot({
        name: n,
        look: { skin: pick(PALETTE.skin), shirt: pick(PALETTE.shirt), pants: pick(PALETTE.pants), hair: pick(PALETTE.hair) },
        gear: {
          lightMul: 1 + this.roundNumber * 0.04,
          heavyMul: 1 + this.roundNumber * 0.03,
          hasSword: Math.random() < 0.55,
          hasAxe: Math.random() < 0.18,
          speedBonus: Math.random() < 0.25 ? 2 : 0,
        },
      });
      bot.arenaLimit = this.arena ? this.arena.size * 0.55 : 55;
      this.entities.push(bot);
      this.bots.push(bot);
      this.scene.add(bot.avatar.group);
    }

    // posisi awal: usahakan tiap karakter dapat spawn yang berjauhan
    const taken = [];
    for (const e of this.entities) {
      let sp = null;
      for (let tries = 0; tries < 12; tries++) {
        const cand = this.arena?.randomSpawn() || { x: 0, y: 3, z: 0 };
        const far = taken.every((t) => Math.hypot(t.x - cand.x, t.z - cand.z) > 9);
        sp = cand;
        if (far) break;
      }
      taken.push(sp);
      e.teleport(sp.x, sp.y + 0.4, sp.z, Math.random() * Math.PI * 2);
      e.pickWander?.();
    }
    if (!silent) this.ui.refreshLeaderboard();
    this.ui.refreshHealth();
    this.ui.el.playerName.textContent = player.name;
  }

  applyGear() {
    if (!this.player) return;
    this.player.gear = gearStats(Store);
    this.player.applyGear();
    this.player.setHealth(this.player.maxHealth);
    this.ui.refreshHealth();
  }

  /* ============================== arena ============================== */
  loadArena(index, silent = false) {
    if (this.arena) {
      this.scene.remove(this.arena.group);
      this.arena.dispose();
    }
    let pick = index;
    if (pick === null && this.arena) {
      // randomizer: jangan memilih map yang sama dua kali berturut-turut
      const current = this.arena.name;
      for (let tries = 0; tries < 8; tries++) {
        const cand = Math.floor(Math.random() * arenaCount());
        if (MAP_INFO[cand].name !== current) { pick = cand; break; }
      }
    }
    this.arena = createArena(pick);
    this.scene.add(this.arena.group);
    for (const b of this.bots) b.arenaLimit = this.arena.size * 0.55;
    this.world.applyTheme(this.arena.theme);
    this.world.setColliders(this.arena.colliders);
    this.arena.update(0, 0);

    for (const f of this.fx) this.fxGroup.remove(f.mesh);
    this.fx.length = 0;

    if (silent) return;
    this.ui.toast(`Map: ${this.arena.name}`, 'gold');
    this.ui.addChat(`Map dimuat: ${this.arena.name}`, 'sys');
  }

  /* ============================== round flow ============================== */
  start() {
    Audio.unlock();
    this.state = 'playing';
    this.paused = false;
    this.ui.hideAllScreens();
    this.ui.show('hud');
    this.ui.updateMobileVisibility(Store.settings.forceMobile);
    this.ui.el.nameInput.blur();
    this.canvas.focus?.();

    const wantedName = Store.name || this.player?.name || 'Player';
    if (this.player && wantedName !== this.player.name) {
      this.player.name = wantedName;
      this.player.avatar.setLabel(wantedName, '#8ff7c2');
    }

    this.roundNumber = 1;
    this.startIntermission(true);
    this.ui.toggleLeaderboard(true);
    this.ui.addChat(`Selamat datang, ${this.player?.name || 'player'}!`, 'good');
    this.ui.addChat('Ketik /help untuk daftar command.', 'sys');
    this.input.enabled = true;
    this.input.requestLock();
    Audio.roundStart();
  }

  startIntermission(first = false) {
    this.phase = 'intermission';
    this.phaseT = ROUND.intermission;
    this.roundName = 'Intermission';
    this.combatEnabled = false;
    this.loadArena(null);
    this.resetRoundStats();
    for (const e of this.entities) {
      e.health = e.maxHealth;
      e.alive = true;
      e.avatar.setDead(false);
      respawnFighter(this, e);
      e.iframes = Math.max(e.iframes, 1.5);   // jeda aman setelah spawn
    }
    this.ui.addChat(`Round ${this.roundNumber} siap dimulai di ${this.arena.name}.`, 'sys');
    if (!first) this.ui.toast(`Intermission — belanja dulu! (B)`, '');
  }

  resetRoundStats() {
    for (const e of this.entities) {
      e.stats.kills = 0;
      e.stats.deaths = 0;
      e.killstreak = 0;
    }
    this.roundCoins.clear();
    this.stats.kills = 0;
    this.stats.deaths = 0;
    Store.bumpStat('rounds');
    this.ui.refreshLeaderboard();
  }

  startRound() {
    this.phase = 'round';
    this.phaseT = ROUND.duration;
    this.roundName = `Round ${this.roundNumber}`;
    this.combatEnabled = true;

    // semua karakter respawn di titik acak saat round mulai (seperti Roblox)
    for (const e of this.entities) {
      e.alive = true;
      e.avatar.setDead(false);
      e.health = e.maxHealth;
      respawnFighter(this, e);
    }

    // kesulitan bot naik perlahan tiap round
    const lv = Math.max(0, this.roundNumber - 1);
    for (const b of this.bots) {
      b.gear.lightMul = 1 + lv * 0.045;
      b.gear.heavyMul = 1 + lv * 0.035;
    }

    this.ui.addChat(`ROUND ${this.roundNumber} DIMULAI!`, 'good');
    this.ui.toast('Fight!', 'gold');
    Audio.roundStart();
    this.ui.refreshLeaderboard();
  }

  endRound() {
    this.phase = 'results';
    this.phaseT = ROUND.results;
    this.combatEnabled = false;
    for (const e of this.entities) e.attacking = null;
    Audio.roundEnd();

    const rows = [...this.entities].map((e) => {
      const bonus = e.stats.kills * ROUND.killCoins + (e.isPlayer ? ROUND.joinCoins : 0);
      return {
        name: e.name,
        color: e.avatar?.colors?.shirt || '#888',
        kills: e.stats.kills,
        deaths: e.stats.deaths,
        coins: e.isPlayer ? bonus : e.stats.kills * ROUND.killCoins,
        me: e.isPlayer,
        entity: e,
      };
    }).sort((a, b) => b.kills - a.kills || a.deaths - b.deaths);

    if (!rows.length) { this.continueFromResults(); return; }
    const top = rows[0];
    const tied = rows.filter((r) => r.kills === top.kills);
    const winner = tied.length === 1 ? top.name : null;

    // hadiah: bonus ikut round + bonus menang + koin KO
    let reward = ROUND.joinCoins;
    if (winner && top.me) {
      reward += ROUND.winCoins;
      Store.bumpStat('wins');
    }
    reward += (this.player?.stats.kills || 0) * ROUND.killCoins;
    const meRow = rows.find((r) => r.me);
    if (meRow) meRow.coins = reward;
    if (reward > 0) this.addCoins(reward, 'round bonus', true);

    this.roundResults = { rows, mapName: this.arena.name, winner };
    this.ui.showResults(rows, this.arena.name, winner);
    this.ui.refreshMenuStats();
    this.state = 'results';
    this.input.exitLock();
    Store.save();
  }

  continueFromResults() {
    this.ui.hide('results');
    this.state = 'playing';
    this.roundNumber++;
    this.startIntermission(false);
    if (!this.input.isTouch) this.input.requestLock();
  }

  /* ============================== pause ============================== */
  setPaused(on, silent = false) {
    if (this.state === 'menu' || this.state === 'results') return;
    this.paused = !!on;
    if (this.paused) {
      if (!silent) this.ui.show('pause');
      this.input.exitLock();
      this.input.enabled = false;
    } else {
      this.ui.hide('pause');
      this.ui.hide('shop');
      this.ui.hide('settings');
      this.ui.hide('howto');
      this.input.enabled = true;
      this.canvas.focus?.();
      if (this.state === 'playing' && !this.input.isTouch) this.input.requestLock();
    }
  }

  /** Buka overlay (shop/settings/howto) sambil menjeda gameplay. */
  openOverlay(name) {
    this.overlayReturnPause = this.paused && !this.ui.el.pause.classList.contains('hidden');
    if (this.overlayReturnPause) this.ui.hide('pause');
    this.ui.show(name);
    if (name === 'shop') this.ui.buildShop();
    this.setPaused(true, true);
    Audio.ui();
  }

  closeOverlay(name) {
    this.ui.hide(name);
    if (!this.paused) return;
    if (this.overlayReturnPause) {
      this.ui.show('pause');
    } else {
      this.setPaused(false);
    }
  }

  openShop() { this.openOverlay('shop'); }

  onPlayerKill(victim) {
    Store.bumpStat('kills');
    this.ui.refreshMenuStats();
  }

  onPlayerDeath(attacker) {
    Store.bumpStat('deaths');
    this.ui.refreshMenuStats();
  }

  togglePause() {
    if (this.state === 'menu' || this.state === 'results') return;
    this.setPaused(!this.paused);
  }

  quitToMenu() {
    this.state = 'menu';
    this.paused = false;
    this.input.exitLock();
    this.input.enabled = false;
    this.ui.hideAllScreens();
    this.ui.hide('hud');
    this.ui.show('menu');
    this.ui.syncSettings();
    this.ui.refreshMenuStats();
    this.ui.refreshCoins();
    Store.save();
  }

  closeShop() {
    this.closeOverlay('shop');
  }

  /* ============================== coins ============================== */
  addCoins(n, reason = '', silent = false) {
    Store.addCoins(n);
    this.stats.coinsEarned += n;
    this.ui.refreshCoins();
    if (!silent) Audio.coin();
    if (reason && !silent) this.ui.addChat(`+${n} coins · ${reason}`, 'good');
  }

  /* ============================== chat ============================== */
  say(text) {
    const name = this.player?.name || 'Player';
    this.ui.addChat(`${name}: ${text}`);
    // bot "belajar" kosakata dari pemain (Markov chain), lalu memakainya acak
    Chatter.learn(text);
  }

  command(raw) {
    const [cmd, ...args] = raw.slice(1).split(/\s+/);
    const arg = args.join(' ');
    const p = this.player;
    switch ((cmd || '').toLowerCase()) {
      case 'help':
        this.ui.addChat('/help /heal /coins /map [nama] /kill /stats /resetgear /music — command tersedia', 'sys');
        break;
      case 'heal':
        if (p) { p.setHealth(p.maxHealth); p.stamina = p.maxStamina; Audio.heal(); this.ui.toast('Healed', 'good'); }
        break;
      case 'coins':
        this.ui.addChat(`Coins: ${Store.coins}`, 'sys');
        break;
      case 'map': {
        const idx = MAP_INFO.findIndex((m) => m.name.toLowerCase().includes(arg.toLowerCase()));
        if (idx >= 0) {
          this.loadArena(idx);
          this.ui.toast(`Map diganti: ${MAP_INFO[idx].name}`, 'gold');
          for (const e of this.entities) respawnFighter(this, e);
        } else {
          this.ui.addChat(`Map tersedia: ${MAP_INFO.map((m) => m.name).join(', ')}`, 'sys');
        }
        break;
      }
      case 'kill':
        if (p) killFighter(this, p, null);
        break;
      case 'stats':
        this.ui.addChat(`Kills ${Store.stats.kills} · Deaths ${Store.stats.deaths} · Rounds ${Store.stats.rounds} · Wins ${Store.stats.wins}`, 'sys');
        break;
      case 'resetgear': {
        const refund = Store.refundAll();
        this.applyGear();
        this.ui.buildShop();
        this.ui.toast(`Gear direset (+${refund} coins)`, 'gold');
        break;
      }
      case 'music': {
        const on = !Store.settings.music;
        Store.setSetting('music', on);
        Audio.setMusic(on);
        this.ui.syncSettings();
        this.ui.toast(`Musik ${on ? 'on' : 'off'}`);
        break;
      }
      case 'clear':
        this.ui.el.chatLog.innerHTML = '';
        break;
      default:
        this.ui.addChat(`Command tidak dikenal: /${cmd}. Coba /help`, 'warn');
    }
  }

  /* ============================== loop ============================== */
  loop() {
    const dt = Math.min(0.05, this.clock.getDelta());
    try {
      this.update(dt);
    } catch (err) {
      console.error(err);
      this.fatal(err);
      return;
    }
    requestAnimationFrame(() => this.loop());
  }

  update(dt) {
    const active = this.state === 'playing' && !this.paused;
    this.time += active ? dt : dt * 0.25;

    /* ------------------------------ phase ------------------------------ */
    if (this.state === 'playing') {
      if (active) {
        if (this.phase === 'intermission') {
          this.phaseT -= dt;
          if (this.phaseT <= 0) this.startRound();
        } else if (this.phase === 'round') {
          this.phaseT -= dt;
          if (this.phaseT <= 0) this.endRound();
        }
      }
      const label = this.phase === 'round' ? `Round ${this.roundNumber}` : this.phase === 'intermission' ? 'Intermission' : 'Results';
      this.ui.setRoundInfo(this.arena.name, label, this.phaseT, this.phase === 'round' && this.phaseT < 15);
    }

    /* ------------------------------ entities ------------------------------ */
    if (active && this.player) {
      this.player.update(this, dt);
      for (const bot of this.bots) bot.update(this, dt);
      updateCombat(this, dt);
      separateEntities(this.entities, dt, this.arena.colliders);
      updateFx(this, dt);
      this.arena.update(dt, this.time);

      // redam nametag yang terlalu dekat dengan kamera
      const camPos = this.world.camera.position;
      for (const e of this.entities) {
        e.avatar.updateNameplate(Math.hypot(
          e.pos.x - camPos.x, e.pos.y + 4 - camPos.y, e.pos.z - camPos.z
        ));
      }

      // == kamera third-person mengikuti pemain =============================
      // WAJIB: tanpa panggilan ini kamera membeku di posisi terakhir (bug v1.0.0)
      this.world.updateCamera(this.player.pos, dt);
    } else if (this.state === 'menu') {
      // kamera sinematik di menu
      this.menuCamAngle += dt * 0.06;
      const a = this.menuCamAngle;
      this.world.camYaw = a;
      this.world.camPitch = -0.12 + Math.sin(a * 1.7) * 0.05;
      this.world.camDist = 30;
      const focus = new THREE.Vector3(0, 6, 0);
      this.world.updateCamera(focus, dt);
      for (const e of this.entities) e.avatar.update(dt, { speed: 0, onGround: true, vy: 0 });
      this.arena?.update(dt, this.time);
    } else {
      // pause / results: dunia dibekukan, kamera tetap mengikuti player
      this.world.updateCamera(this.player ? this.player.pos : new THREE.Vector3(0, 3, 0), dt);
    }

    /* -------------------------------- UI -------------------------------- */
    this.ui.update(dt);
    this.input.endFrame();

    this.world.render();
  }

  fatal(err) {
    const box = this.ui.el.fatal;
    box.classList.remove('hidden');
    box.innerHTML = `
      <div class="box">
        <h2>Game berhenti</h2>
        <p>Terjadi error di loop utama. Coba refresh halaman.</p>
        <p><code>${String(err && err.message ? err.message : err)}</code></p>
      </div>`;
  }
}

function randomName() {
  const a = ['Blox', 'Noob', 'Rift', 'Pixel', 'Neon', 'Sword', 'Dark', 'Lava', 'Sky', 'Brick'];
  const b = ['Master', 'Slayer', 'Knight', 'Hunter', 'Fighter', 'Boi', 'King', 'Pro'];
  return `${a[Math.floor(Math.random() * a.length)]}${b[Math.floor(Math.random() * b.length)]}${Math.floor(Math.random() * 99)}`;
}

/* ------------------------------- bootstrap ------------------------------- */
function boot() {
  try {
    const game = new Game();
    window.__GAME = game;      // memudahkan debugging dari console
  } catch (err) {
    console.error(err);
    const fatal = document.getElementById('fatal');
    fatal.classList.remove('hidden');
    fatal.innerHTML = `
      <div class="box">
        <h2>Tidak bisa start</h2>
        <p>Browser ini mungkin tidak mendukung WebGL2 atau modul ES.</p>
        <p><code>${String(err && err.message ? err.message : err)}</code></p>
        <p>Buka lewat server lokal (bukan file://), mis. <code>npm start</code>.</p>
      </div>`;
  }
}

window.addEventListener('error', (e) => {
  console.error('[global error]', e.error || e.message);
});

boot();

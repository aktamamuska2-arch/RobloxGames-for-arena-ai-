/* =========================================================================
   ui.js — seluruh lapisan HTML: HUD Roblox-style, chat, shop, leaderboard,
   menu, pause, settings, notifikasi, dan damage numbers.
   ========================================================================= */

import * as THREE from 'three';
import { Store, gearStats } from './store.js';
import { SHOP } from './config.js';
import { Audio } from './audio.js';

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => [...document.querySelectorAll(sel)];

const SCREENS = ['menu', 'shop', 'pause', 'settings', 'howto', 'results', 'loading'];

export class UI {
  constructor(game) {
    this.game = game;
    this.el = {
      hud: $('#hud'),
      menu: $('#screen-menu'),
      shop: $('#screen-shop'),
      pause: $('#screen-pause'),
      settings: $('#screen-settings'),
      howto: $('#screen-howto'),
      results: $('#screen-results'),
      loading: $('#screen-loading'),
      fatal: $('#fatal'),
      hpFill: $('#hp-fill'),
      hpText: $('#hp-text'),
      stamina: $('#stamina-fill'),
      playerName: $('#player-name'),
      killstreak: $('#killstreak'),
      coinVal: $('#coin-val'),
      shopCoins: $('#shop-coins'),
      chatLog: $('#chat-log'),
      chatRow: $('#chat-input-row'),
      chatInput: $('#chat-input'),
      board: $('#leaderboard'),
      boardRows: $('#board-rows'),
      boardSub: $('#board-sub'),
      toasts: $('#toasts'),
      dmgLayer: $('#damage-layer'),
      leaderboardVisible: false,
      roundBanner: $('#round-banner'),
      roundLabel: $('#round-label'),
      roundTimer: $('#round-timer'),
      roundMap: $('#round-map'),
      crosshair: $('#crosshair'),
      cooldown: $('#cooldown-ring'),
      cooldownFill: $('#cooldown-fill'),
      vignette: $('#hurt-vignette'),
      hitFlash: $('#hit-flash'),
      mobile: $('#mobile-ui'),
      shopGrid: $('#shop-grid'),
      nameInput: $('#name-input'),
      combatHint: $('#combat-hint'),
      lockHint: $('#lock-hint'),
      resultsTable: $('#results-table'),
      resultsWinner: $('#results-winner'),
      resultsMap: $('#results-map'),
    };
    this.chatOpen = false;
    this.chatLines = [];
    this.pending = [];
    this.damageEls = [];
    this.vignetteT = 0;
    this.cooldownT = 0;

    this.bind();
    this.buildShop();
    this.syncSettings();
    this.refreshCoins();
    this.refreshMenuStats();
  }

  /* ============================== helpers ============================== */
  show(id) {
    const el = this.el[id];
    if (el) el.classList.remove('hidden');
  }
  hide(id) {
    const el = this.el[id];
    if (el) el.classList.add('hidden');
  }
  hideAllScreens() {
    SCREENS.forEach((s) => this.hide(s));
  }

  isOverlayOpen() {
    return SCREENS.some((s) => s !== 'loading' && this.el[s] && !this.el[s].classList.contains('hidden'));
  }

  toast(text, type = '') {
    const div = document.createElement('div');
    div.className = `toast ${type}`.trim();
    div.innerHTML = `<span class="ico"></span><span>${escapeHtml(text)}</span>`;
    this.el.toasts.appendChild(div);
    setTimeout(() => {
      div.classList.add('out');
      setTimeout(() => div.remove(), 320);
    }, 2600);
    while (this.el.toasts.children.length > 4) this.el.toasts.firstChild.remove();
  }

  addChat(text, cls = '') {
    const div = document.createElement('div');
    div.className = `chat-line ${cls}`.trim();
    div.innerHTML = escapeHtml(text).replace(/^([A-Za-z0-9_ ]+):/, '<b>$1:</b>');
    this.el.chatLog.appendChild(div);
    while (this.el.chatLog.children.length > 8) this.el.chatLog.firstChild.remove();
    setTimeout(() => {
      div.classList.add('fade');
      setTimeout(() => div.remove(), 900);
    }, 15000);
  }

  /* ============================== HUD ============================== */
  refreshHealth() {
    const p = this.game.player;
    if (!p) return;
    const pct = p.maxHealth > 0 ? (p.health / p.maxHealth) * 100 : 0;
    this.el.hpFill.style.width = `${pct}%`;
    this.el.hpFill.classList.toggle('low', pct <= 30);
    this.el.hpText.textContent = `${Math.max(0, Math.round(p.health))} / ${Math.round(p.maxHealth)}`;
    this.el.stamina.style.width = `${(p.stamina / p.maxStamina) * 100}%`;
    this.el.stamina.style.opacity = p.sprinting ? '1' : '0.65';
    this.el.playerName.textContent = p.name;
    this.el.killstreak.textContent = p.killstreak >= 2 ? `${p.killstreak}x streak` : '';
    this.el.cooldown.classList.toggle('hidden', !p.attacking && p.attackCd <= 0);
    const cdTotal = p.attacking?.spec?.cooldown || 0.5;
    const cdPct = p.attackCd > 0 ? (1 - p.attackCd / cdTotal) * 100 : 100;
    this.el.cooldownFill.style.width = `${Math.max(0, Math.min(100, cdPct))}%`;
  }

  refreshCoins() {
    this.el.coinVal.textContent = Store.coins;
    this.el.shopCoins.textContent = Store.coins;
  }

  refreshMenuStats() {
    $('#stat-kills').textContent = Store.stats.kills;
    $('#stat-deaths').textContent = Store.stats.deaths;
    $('#stat-coins').textContent = Store.coins;
    $('#stat-rounds').textContent = Store.stats.rounds;
  }

  refreshLeaderboard() {
    const game = this.game;
    if (!game.player) return;
    const rows = [...game.entities]
      .sort((a, b) => (b.stats.kills - a.stats.kills) || (a.stats.deaths - b.stats.deaths))
      .slice(0, 12);
    this.el.boardRows.innerHTML = rows.map((e, i) => `
      <div class="board-row ${e.isPlayer ? 'me' : ''}">
        <span>${i + 1}</span>
        <span class="nm"><i class="swatch" style="background:${e.avatar?.colors?.shirt || '#888'}"></i>${escapeHtml(e.name)}</span>
        <span class="ko">${e.stats.kills}</span>
        <span class="dt">${e.stats.deaths}</span>
      </div>`).join('');
    this.el.boardSub.textContent = game.roundName || 'Round';
  }

  toggleLeaderboard(force) {
    const visible = force !== undefined ? force : !this.el.leaderboardVisible;
    this.el.leaderboardVisible = visible;
    this.el.board.classList.toggle('hidden', !visible);
    if (visible) this.refreshLeaderboard();
  }

  setRoundInfo(mapName, label, seconds, urgent) {
    this.el.roundMap.textContent = mapName;
    this.el.roundLabel.textContent = label;
    const m = Math.floor(Math.max(0, seconds) / 60);
    const s = Math.floor(Math.max(0, seconds) % 60);
    this.el.roundTimer.textContent = `${m}:${String(s).padStart(2, '0')}`;
    this.el.roundBanner.classList.toggle('urgent', !!urgent);
  }

  crosshairHit() {
    this.el.crosshair.classList.add('hit');
    clearTimeout(this._chHit);
    this._chHit = setTimeout(() => this.el.crosshair.classList.remove('hit'), 120);
  }

  hurt(ratio) {
    this.vignetteT = Math.min(0.85, 0.25 + ratio * 0.9);
    this.el.vignette.style.opacity = this.vignetteT.toFixed(2);
  }

  damageNumber(worldPos, text, cls = '') {
    if (!this.game.world || !worldPos) return;
    const v = worldPos.clone().project(this.game.world.camera);
    if (v.z > 1) return;
    const x = (v.x * 0.5 + 0.5) * window.innerWidth;
    const y = (-v.y * 0.5 + 0.5) * window.innerHeight;
    if (x < -100 || y < -100 || x > window.innerWidth + 100 || y > window.innerHeight + 100) return;
    const el = document.createElement('div');
    el.className = `dmg ${cls}`.trim();
    el.textContent = text;
    el.style.left = `${x + (Math.random() - 0.5) * 26}px`;
    el.style.top = `${y}px`;
    this.el.dmgLayer.appendChild(el);
    setTimeout(() => el.remove(), 950);
  }

  /* ============================== chat ============================== */
  openChat(prefill = '') {
    this.chatOpen = true;
    this.el.chatRow.classList.remove('hidden');
    this.el.chatInput.value = prefill;
    this.el.chatInput.focus();
    this.game.input.enabled = false;
    this.game.input.exitLock();
  }

  closeChat() {
    this.chatOpen = false;
    this.el.chatRow.classList.add('hidden');
    this.el.chatInput.value = '';
    this.el.chatInput.blur();
    this.game.input.enabled = true;
    if (this.game.state === 'playing') this.game.input.requestLock();
  }

  submitChat() {
    const text = this.el.chatInput.value.trim();
    this.closeChat();
    if (!text) return;
    if (text.startsWith('/')) this.game.command(text);
    else this.game.say(text);
  }

  /* ============================== shop ============================== */
  buildShop() {
    this.el.shopGrid.innerHTML = SHOP.map((item) => {
      const lvl = Store.level(item.id);
      const price = Store.price(item.id);
      const maxed = lvl >= item.maxLevel;
      return `
        <div class="shop-card ${maxed ? 'maxed' : ''}" data-id="${item.id}">
          <div class="swatch" style="background:${item.color}"></div>
          <div class="lvl">${item.tag} · Lv ${lvl}/${item.maxLevel}</div>
          <h3>${item.name}</h3>
          <p>${item.desc}<br><span style="color:#8bd7b0">${item.effect}</span></p>
          <div class="price">${maxed ? 'MAX' : `🪙 ${price}`}</div>
          <button class="btn ${maxed ? 'owned' : 'btn-primary'}" ${maxed ? 'disabled' : ''}>
            ${maxed ? 'Owned' : lvl > 0 ? 'Upgrade' : 'Buy'}
          </button>
        </div>`;
    }).join('');

    this.el.shopGrid.querySelectorAll('.shop-card').forEach((card) => {
      card.querySelector('button')?.addEventListener('click', () => {
        const id = card.dataset.id;
        const res = Store.buy(id);
        if (res.ok) {
          Audio.buy();
          this.toast(`${Store.item(id).name} → Lv ${res.level}`, 'gold');
          this.game.applyGear();
        } else if (res.reason === 'coins') {
          Audio.deny();
          this.toast('Coin belum cukup', 'bad');
        } else {
          Audio.deny();
        }
        this.buildShop();
        this.refreshCoins();
      });
    });
    this.refreshCoins();
  }

  openShop() {
    this.game.openShop();
  }

  /* ============================== results ============================== */
  showResults(rows, mapName, winnerName) {
    this.el.resultsMap.textContent = mapName;
    this.el.resultsWinner.innerHTML = winnerName
      ? `${escapeHtml(winnerName)}<small>TOP FRAGGER</small>`
      : `Seri<small>TIDAK ADA PEMENANG</small>`;
    this.el.resultsTable.innerHTML = `
      <div class="board-row head"><span>#</span><span>Player</span><span>KO</span><span>Death</span><span>Coins</span></div>
      ${rows.map((r, i) => `
        <div class="board-row ${r.me ? 'me' : ''}">
          <span>${i + 1}</span>
          <span class="nm"><i class="swatch" style="background:${r.color}"></i>${escapeHtml(r.name)}</span>
          <span class="ko">${r.kills}</span>
          <span class="dt">${r.deaths}</span>
          <span class="reward">+${r.coins}</span>
        </div>`).join('')}`;
    this.show('results');
    this.refreshMenuStats();
  }

  /* ============================== settings ============================== */
  syncSettings() {
    const s = Store.settings;
    const set = (id, val) => { const el = $(id); if (el) el.value = val; };
    set('#set-sens', s.sensitivity);
    set('#set-vol', s.volume);
    set('#set-fov', s.fov);
    set('#set-quality', s.quality);
    $('#val-sens').textContent = Number(s.sensitivity).toFixed(2);
    $('#val-vol').textContent = Number(s.volume).toFixed(2);
    $('#val-fov').textContent = s.fov;
    $('#set-shake').checked = !!s.shake;
    $('#set-music').checked = !!s.music;
    $('#set-mobile').checked = !!s.forceMobile;
    this.el.nameInput.value = s.name || Store.name || '';
  }

  /* ============================== binding ============================== */
  bind() {
    const g = this.game;

    /* start menu */
    $('#btn-play').addEventListener('click', () => {
      Audio.unlock();
      Audio.ui();
      const name = this.el.nameInput.value.trim();
      if (name) Store.setName(name);
      g.start();
    });
    this.el.nameInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') $('#btn-play').click();
    });
    $('#btn-menu-shop').addEventListener('click', () => this.openShop());
    $('#btn-menu-howto').addEventListener('click', () => g.openOverlay('howto'));
    $('#btn-menu-settings').addEventListener('click', () => g.openOverlay('settings'));

    /* top bar */
    $('#btn-menu')?.addEventListener('click', () => g.togglePause());
    $('#btn-chat')?.addEventListener('click', () => this.openChat());
    $('#btn-shop')?.addEventListener('click', () => this.openShop());
    $('#btn-board')?.addEventListener('click', () => this.toggleLeaderboard());
    $('#btn-settings')?.addEventListener('click', () => g.openOverlay('settings'));

    /* pause */
    $('#btn-resume')?.addEventListener('click', () => g.setPaused(false));
    $('#btn-pause-shop')?.addEventListener('click', () => this.openShop());
    $('#btn-pause-settings')?.addEventListener('click', () => g.openOverlay('settings'));
    $('#btn-pause-howto')?.addEventListener('click', () => g.openOverlay('howto'));
    $('#btn-pause-menu')?.addEventListener('click', () => g.quitToMenu());

    /* shop */
    $('#btn-shop-close')?.addEventListener('click', () => g.closeOverlay('shop'));
    $('#btn-shop-reset')?.addEventListener('click', () => {
      const refund = Store.refundAll();
      this.toast(`Gear direset, +${refund} coins`, 'gold');
      this.buildShop();
      this.refreshCoins();
      g.applyGear();
      g.player?.setHealth(g.player.maxHealth);
    });

    /* results */
    $('#btn-results-continue')?.addEventListener('click', () => g.continueFromResults());

    /* close buttons */
    $$('[data-close]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const which = btn.dataset.close;
        Audio.ui();
        if (which === 'shop' || which === 'settings' || which === 'howto') g.closeOverlay(which);
        else this.hide(which);
      });
    });

    /* settings inputs */
    const bindSetting = (sel, key, fmt = (v) => v, after) => {
      const el = $(sel);
      el?.addEventListener('input', () => {
        const raw = el.type === 'checkbox' ? el.checked : el.value;
        const val = el.type === 'range' ? Number(raw) : raw;
        Store.setSetting(key, val);
        if (fmt) {
          const label = $(sel.replace('set-', 'val-'));
          if (label) label.textContent = fmt(val);
        }
        after?.(val);
      });
    };
    bindSetting('#set-sens', 'sensitivity', (v) => Number(v).toFixed(2), (v) => { g.world.sens = v; });
    bindSetting('#set-vol', 'volume', (v) => Number(v).toFixed(2), (v) => Audio.setVolume(v));
    bindSetting('#set-fov', 'fov', (v) => String(v), (v) => g.world.setFov(Number(v)));
    bindSetting('#set-quality', 'quality', null, (v) => g.world.setQuality(v));
    bindSetting('#set-shake', 'shake', null, (v) => { g.world.shakeEnabled = !!v; });
    bindSetting('#set-music', 'music', null, (v) => Audio.setMusic(!!v));
    bindSetting('#set-mobile', 'forceMobile', null, (v) => this.updateMobileVisibility(!!v));

    /* chat input */
    this.el.chatInput.addEventListener('keydown', (e) => {
      e.stopPropagation();
      if (e.key === 'Enter') this.submitChat();
      if (e.key === 'Escape') this.closeChat();
    });

    /* mobile buttons */
    $$('#mobile-buttons .mb').forEach((btn) => {
      const act = btn.dataset.act;
      btn.addEventListener('touchstart', (e) => { e.preventDefault(); g.input.trigger(act); Audio.unlock(); }, { passive: false });
      btn.addEventListener('mousedown', (e) => { e.preventDefault(); g.input.trigger(act); });
    });
    g.input.bindJoystick($('#stick'), $('#stick-knob'));
  }

  updateMobileVisibility(force) {
    const show = force || this.game.input.isTouch;
    this.el.mobile.classList.toggle('hidden', !show);
  }

  /* ============================== per-frame ============================== */
  update(dt) {
    if (this.vignetteT > 0) {
      this.vignetteT = Math.max(0, this.vignetteT - dt * 1.6);
      if (this.vignetteT <= 0) this.el.vignette.style.opacity = '0';
    }
    if (this.game.player) this.refreshHealth();
    // health bar sudah diperbarui setiap frame, leaderboard cukup periodik
    this._boardT = (this._boardT || 0) + dt;
    if (this._boardT > 0.6 && this.el.leaderboardVisible) {
      this._boardT = 0;
      this.refreshLeaderboard();
    }
    this.el.combatHint.style.opacity = this.game.state === 'playing' && !this.chatOpen ? '1' : '0';

    // hint saat pointer belum terkunci (drag-look fallback)
    const inp = this.game.input;
    const showLockHint = this.game.state === 'playing' && !this.game.paused && !this.chatOpen
      && !inp.isTouch && !inp.locked;
    if (this.el.lockHint) this.el.lockHint.classList.toggle('hidden', !showLockHint);
  }
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

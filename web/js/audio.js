/* =========================================================================
   audio.js — semua suara dibuat procedural dengan WebAudio.
   Tidak ada aset Roblox yang dipakai (aset audio Roblox proprietary),
   jadi SFX disintesis: swing, hit, jump, koin, UI, dsb.
   ========================================================================= */

export class AudioSys {
  constructor() {
    this.ctx = null;
    this.master = null;
    this.musicGain = null;
    this.volume = 0.6;
    this.musicOn = false;
    this.musicTimer = null;
    this.musicStep = 0;
    this._noise = null;
    this._unlocked = false;
    this._pendingMusic = false;
    this._wantMusic = false;
  }

  /** Harus dipanggil dari gesture user pertama (klik/keydown). */
  init() {
    if (this.ctx) return;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    this.ctx = new AC();
    this.master = this.ctx.createGain();
    this.master.gain.value = this.volume;
    this.master.connect(this.ctx.destination);

    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = 0.0;
    this.musicGain.connect(this.master);

    this._noise = this._makeNoise(1.2);
  }

  unlock() {
    this.init();
    if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume();
    this._unlocked = true;
    // musik yang diminta sebelum gesture user baru bisa dibunyikan sekarang
    if (this._pendingMusic && this._wantMusic) {
      this._pendingMusic = false;
      this._startMusic();
    }
  }

  setVolume(v) {
    this.volume = Math.max(0, Math.min(1, v));
    if (this.master) this.master.gain.value = this.volume;
  }

  get t() { return this.ctx ? this.ctx.currentTime : 0; }

  _makeNoise(seconds) {
    const len = Math.floor(this.ctx.sampleRate * seconds);
    const buf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    return buf;
  }

  _env(gainNode, t0, attack, decay, peak = 1) {
    const g = gainNode.gain;
    g.cancelScheduledValues(t0);
    g.setValueAtTime(0.0001, t0);
    g.exponentialRampToValueAtTime(Math.max(0.0002, peak), t0 + attack);
    g.exponentialRampToValueAtTime(0.0001, t0 + attack + decay);
  }

  tone({ freq = 440, to = null, dur = 0.2, type = 'sine', gain = 0.3, delay = 0, attack = 0.005 }) {
    if (!this.ctx) return;
    const t0 = this.t + delay;
    const osc = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t0);
    if (to) osc.frequency.exponentialRampToValueAtTime(Math.max(20, to), t0 + dur);
    this._env(g, t0, attack, dur, gain);
    osc.connect(g).connect(this.master);
    osc.start(t0);
    osc.stop(t0 + attack + dur + 0.05);
  }

  noise({ dur = 0.2, gain = 0.25, type = 'bandpass', freq = 1200, to = null, q = 1, delay = 0 }) {
    if (!this.ctx) return;
    const t0 = this.t + delay;
    const src = this.ctx.createBufferSource();
    src.buffer = this._noise;
    src.loop = true;
    const filter = this.ctx.createBiquadFilter();
    filter.type = type;
    filter.frequency.setValueAtTime(freq, t0);
    filter.Q.value = q;
    if (to) filter.frequency.exponentialRampToValueAtTime(Math.max(60, to), t0 + dur);
    const g = this.ctx.createGain();
    this._env(g, t0, 0.004, dur, gain);
    src.connect(filter).connect(g).connect(this.master);
    src.start(t0);
    src.stop(t0 + dur + 0.1);
  }

  /* ------------------------------ SFX ------------------------------ */
  swing() {
    this.noise({ dur: 0.16, gain: 0.16, type: 'bandpass', freq: 1800, to: 420, q: 1.2 });
  }
  slash() {
    this.noise({ dur: 0.12, gain: 0.2, type: 'highpass', freq: 900, to: 2600, q: 0.8 });
    this.tone({ freq: 520, to: 180, dur: 0.12, type: 'triangle', gain: 0.1 });
  }
  hit(crit = false) {
    this.noise({ dur: 0.1, gain: 0.24, type: 'lowpass', freq: 900, to: 200, q: 0.7 });
    this.tone({ freq: crit ? 190 : 150, to: 60, dur: 0.16, type: 'square', gain: crit ? 0.22 : 0.14 });
  }
  heavyHit() {
    this.tone({ freq: 110, to: 40, dur: 0.35, type: 'sawtooth', gain: 0.24 });
    this.noise({ dur: 0.28, gain: 0.26, type: 'lowpass', freq: 1200, to: 120, q: 0.6 });
  }
  block() {
    this.tone({ freq: 820, to: 620, dur: 0.09, type: 'square', gain: 0.1 });
    this.noise({ dur: 0.09, gain: 0.1, type: 'bandpass', freq: 2600, q: 3 });
  }
  jump() {
    this.tone({ freq: 330, to: 620, dur: 0.14, type: 'triangle', gain: 0.09 });
  }
  land() {
    this.noise({ dur: 0.12, gain: 0.14, type: 'lowpass', freq: 500, to: 120 });
  }
  dash() {
    this.noise({ dur: 0.22, gain: 0.16, type: 'bandpass', freq: 700, to: 2400, q: 0.9 });
  }
  coin() {
    this.tone({ freq: 880, dur: 0.09, type: 'square', gain: 0.09 });
    this.tone({ freq: 1320, dur: 0.12, type: 'square', gain: 0.08, delay: 0.07 });
  }
  ui() {
    this.tone({ freq: 520, dur: 0.05, type: 'square', gain: 0.05 });
  }
  buy() {
    this.tone({ freq: 660, dur: 0.08, type: 'triangle', gain: 0.1 });
    this.tone({ freq: 990, dur: 0.1, type: 'triangle', gain: 0.09, delay: 0.07 });
    this.tone({ freq: 1320, dur: 0.14, type: 'triangle', gain: 0.08, delay: 0.14 });
  }
  deny() {
    this.tone({ freq: 200, to: 140, dur: 0.14, type: 'square', gain: 0.08 });
  }
  death() {
    this.tone({ freq: 400, to: 60, dur: 0.7, type: 'sawtooth', gain: 0.16 });
    this.noise({ dur: 0.5, gain: 0.12, type: 'lowpass', freq: 900, to: 100 });
  }
  kill() {
    this.tone({ freq: 660, dur: 0.1, type: 'square', gain: 0.1 });
    this.tone({ freq: 990, dur: 0.16, type: 'square', gain: 0.1, delay: 0.08 });
  }
  heal() {
    this.tone({ freq: 520, to: 880, dur: 0.24, type: 'sine', gain: 0.09 });
  }
  roundStart() {
    [523.25, 659.25, 783.99, 1046.5].forEach((f, i) =>
      this.tone({ freq: f, dur: 0.5, type: 'triangle', gain: 0.1, delay: i * 0.09 })
    );
  }
  roundEnd() {
    [783.99, 659.25, 523.25, 392].forEach((f, i) =>
      this.tone({ freq: f, dur: 0.6, type: 'triangle', gain: 0.1, delay: i * 0.12 })
    );
  }

  /* ----------------------------- musik ----------------------------- */
  setMusic(on) {
    this.musicOn = !!on;
    this._wantMusic = !!on;
    if (!this.ctx) {
      this._pendingMusic = !!on;   // tunggu gesture user
      return;
    }
    this.musicGain.gain.cancelScheduledValues(this.t);
    this.musicGain.gain.linearRampToValueAtTime(on ? 0.5 : 0.0, this.t + 0.8);
    if (on) {
      if (this.ctx.state === 'suspended') this._pendingMusic = true;
      else this._startMusic();
    } else {
      this._stopMusic();
    }
  }

  _startMusic() {
    if (this.musicTimer) return;
    this.musicStep = 0;
    const pattern = [0, 3, 7, 10, 7, 3, 5, 3];
    const root = 110; // A2
    const tick = () => {
      if (!this.musicOn || !this.ctx) return;
      const semi = pattern[this.musicStep % pattern.length];
      const f = root * Math.pow(2, semi / 12);
      const t0 = this.t;
      // bass
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = f;
      g.gain.setValueAtTime(0.0001, t0);
      g.gain.exponentialRampToValueAtTime(0.16, t0 + 0.06);
      g.gain.exponentialRampToValueAtTime(0.0001, t0 + 1.5);
      osc.connect(g).connect(this.musicGain);
      osc.start(t0); osc.stop(t0 + 1.6);
      // pad tiap 4 langkah
      if (this.musicStep % 4 === 0) {
        [1, 1.5, 2.25].forEach((mul, i) => {
          const o2 = this.ctx.createOscillator();
          const g2 = this.ctx.createGain();
          o2.type = 'triangle';
          o2.frequency.value = f * mul;
          g2.gain.setValueAtTime(0.0001, t0);
          g2.gain.exponentialRampToValueAtTime(0.035 - i * 0.008, t0 + 0.8);
          g2.gain.exponentialRampToValueAtTime(0.0001, t0 + 3.2);
          o2.connect(g2).connect(this.musicGain);
          o2.start(t0); o2.stop(t0 + 3.3);
        });
      }
      this.musicStep++;
    };
    tick();
    this.musicTimer = setInterval(tick, 950);
  }

  _stopMusic() {
    if (this.musicTimer) clearInterval(this.musicTimer);
    this.musicTimer = null;
  }
}

export const Audio = new AudioSys();

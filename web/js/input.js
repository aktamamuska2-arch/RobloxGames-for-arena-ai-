/* =========================================================================
   input.js — keyboard, mouse (pointer lock), wheel, dan joystick mobile.
   Menyimpan state yang dibaca loop game, plus callback untuk tombol UI.
   ========================================================================= */

export class Input {
  constructor(canvas) {
    this.canvas = canvas;
    this.enabled = true;          // false saat chat/menu terbuka

    this.keys = Object.create(null);
    this.mouseDX = 0;
    this.mouseDY = 0;
    this.wheel = 0;
    this.attackPressed = false;
    this.attackHeld = false;
    this.heavyPressed = false;
    this.blockHeld = false;
    this.dashPressed = false;
    this.jumpPressed = false;
    this.locked = false;
    this.isTouch = matchMedia('(pointer: coarse)').matches;

    this.joystick = { x: 0, y: 0, active: false };
    this.press = null;              // status tekan mouse (untuk fallback drag-look)
    this.lockUnavailable = false;
    this.lookTouch = { dx: 0, dy: 0 };

    this.listeners = { key: [], lock: [] };
  }

  attach() {
    window.addEventListener('keydown', (e) => {
      if (e.target && ['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) return;
      const k = e.code;
      if (!this.keys[k]) {
        // edge triggers
        if (k === 'Space') this.jumpPressed = true;
        if (k === 'KeyQ') this.dashPressed = true;
      }
      this.keys[k] = true;
      if (['Space', 'Tab', 'F1'].includes(k)) e.preventDefault();
      this.listeners.key.forEach((fn) => fn(k, e));
    });

    window.addEventListener('keyup', (e) => {
      this.keys[e.code] = false;
    });

    window.addEventListener('blur', () => {
      this.keys = Object.create(null);
      this.attackHeld = false;
      this.blockHeld = false;
    });

    /* ------------------------------ mouse ------------------------------ */
    this.canvas.addEventListener('mousedown', (e) => {
      if (!this.enabled) return;
      this.press = {
        button: e.button,
        lastX: e.clientX,
        lastY: e.clientY,
        moved: 0,
        t: performance.now(),
      };
      // Kalau pointer terkunci, klik langsung = serangan (perilaku normal).
      if (this.locked) {
        if (e.button === 0) { this.attackPressed = true; this.attackHeld = true; }
        if (e.button === 2) this.heavyPressed = true;
      }
    });

    window.addEventListener('mouseup', (e) => {
      const p = this.press;
      this.press = null;
      if (e.button === 0) this.attackHeld = false;
      if (!this.enabled || !p) return;
      // Tanpa pointer lock: klik singkat (bukan drag) = serangan.
      if (!this.locked && p.button === e.button && p.moved < 9 && performance.now() - p.t < 450) {
        if (e.button === 0) { this.attackPressed = true; this.attackHeld = true; }
        if (e.button === 2) this.heavyPressed = true;
      }
    });
    this.canvas.addEventListener('contextmenu', (e) => e.preventDefault());

    document.addEventListener('mousemove', (e) => {
      if (this.locked) {
        this.mouseDX += e.movementX || 0;
        this.mouseDY += e.movementY || 0;
        return;
      }
      // Fallback: seret mouse untuk memutar kamera saat pointer lock tidak aktif
      // (mis. game di-embed di iframe yang memblokir pointer lock).
      if (!this.press || !this.enabled) return;
      const dx = e.clientX - this.press.lastX;
      const dy = e.clientY - this.press.lastY;
      this.press.lastX = e.clientX;
      this.press.lastY = e.clientY;
      this.press.moved += Math.hypot(dx, dy);
      if (this.press.moved > 3) {
        this.mouseDX += dx * 1.7;
        this.mouseDY += dy * 1.7;
      }
    });

    this.canvas.addEventListener('wheel', (e) => {
      if (!this.enabled) return;
      this.wheel += Math.sign(e.deltaY);
      e.preventDefault();
    }, { passive: false });

    document.addEventListener('pointerlockchange', () => {
      this.locked = document.pointerLockElement === this.canvas;
      this.listeners.lock.forEach((fn) => fn(this.locked));
    });
    document.addEventListener('pointerlockerror', () => {
      this.lockUnavailable = true;
      this.locked = false;
      this.listeners.lock.forEach((fn) => fn(false));
    });

    window.addEventListener('keydown', (e) => {
      if (e.code === 'KeyF' && this.enabled) this.blockHeld = true;
    });
    window.addEventListener('keyup', (e) => {
      if (e.code === 'KeyF') this.blockHeld = false;
    });

    /* --------------------------- touch look --------------------------- */
    this.canvas.addEventListener('touchstart', (e) => {
      if (!this.enabled || e.touches.length < 1) return;
      const t = e.touches[0];
      this._lookId = t.identifier;
      this._lastTouch = { x: t.clientX, y: t.clientY };
    }, { passive: true });
    this.canvas.addEventListener('touchmove', (e) => {
      if (!this.enabled) return;
      for (const t of e.touches) {
        if (t.identifier === this._lookId && this._lastTouch) {
          this.mouseDX += (t.clientX - this._lastTouch.x) * 1.25;
          this.mouseDY += (t.clientY - this._lastTouch.y) * 1.25;
          this._lastTouch = { x: t.clientX, y: t.clientY };
        }
      }
    }, { passive: true });
    this.canvas.addEventListener('touchend', () => { this._lookId = null; this._lastTouch = null; });
  }

  /** Pasang joystick virtual (dipanggil UI). */
  bindJoystick(stickEl, knobEl) {
    let activeId = null;
    const reset = () => {
      activeId = null;
      this.joystick.x = 0;
      this.joystick.y = 0;
      this.joystick.active = false;
      knobEl.style.transform = 'translate(0px, 0px)';
      stickEl.classList.remove('active');
    };
    const move = (e) => {
      const touch = [...e.touches].find((t) => t.identifier === activeId);
      if (!touch) return;
      const r = stickEl.getBoundingClientRect();
      const cx = r.left + r.width / 2;
      const cy = r.top + r.height / 2;
      let dx = touch.clientX - cx;
      let dy = touch.clientY - cy;
      const max = r.width * 0.38;
      const len = Math.hypot(dx, dy);
      if (len > max) { dx = (dx / len) * max; dy = (dy / len) * max; }
      this.joystick.x = dx / max;
      this.joystick.y = dy / max;
      this.joystick.active = true;
      knobEl.style.transform = `translate(${dx}px, ${dy}px)`;
      e.preventDefault();
    };
    stickEl.addEventListener('touchstart', (e) => {
      activeId = e.touches[0].identifier;
      stickEl.classList.add('active');
      move(e);
    }, { passive: false });
    stickEl.addEventListener('touchmove', move, { passive: false });
    stickEl.addEventListener('touchend', reset);
    stickEl.addEventListener('touchcancel', reset);

    // fallback mouse (untuk test di desktop)
    let mouseDown = false;
    const mouseMove = (e) => {
      if (!mouseDown) return;
      const r = stickEl.getBoundingClientRect();
      let dx = e.clientX - (r.left + r.width / 2);
      let dy = e.clientY - (r.top + r.height / 2);
      const max = r.width * 0.38;
      const len = Math.hypot(dx, dy);
      if (len > max) { dx = (dx / len) * max; dy = (dy / len) * max; }
      this.joystick.x = dx / max;
      this.joystick.y = dy / max;
      this.joystick.active = true;
      knobEl.style.transform = `translate(${dx}px, ${dy}px)`;
    };
    stickEl.addEventListener('mousedown', (e) => { mouseDown = true; mouseMove(e); });
    window.addEventListener('mousemove', mouseMove);
    window.addEventListener('mouseup', () => { if (mouseDown) { mouseDown = false; reset(); } });
  }

  /** Aksi tombol mobile. */
  trigger(action) {
    switch (action) {
      case 'attack': this.attackPressed = true; this.attackHeld = true; break;
      case 'heavy': this.heavyPressed = true; break;
      case 'jump': this.jumpPressed = true; break;
      case 'dash': this.dashPressed = true; break;
      case 'block': this.blockHeld = !this.blockHeld; break;
      default: break;
    }
  }

  requestLock() {
    if (this.isTouch || this.lockUnavailable) return;
    try {
      const p = this.canvas.requestPointerLock?.();
      if (p && typeof p.catch === 'function') p.catch(() => { this.lockUnavailable = true; });
    } catch {
      this.lockUnavailable = true;
    }
  }

  exitLock() {
    if (document.pointerLockElement) document.exitPointerLock?.();
  }

  /** Ambil input gerak (maju/kanan) ternormalisasi. */
  moveVector() {
    let f = 0, r = 0;
    if (this.keys.KeyW || this.keys.ArrowUp) f += 1;
    if (this.keys.KeyS || this.keys.ArrowDown) f -= 1;
    if (this.keys.KeyD || this.keys.ArrowRight) r += 1;
    if (this.keys.KeyA || this.keys.ArrowLeft) r -= 1;
    if (this.joystick.active) {
      f += -this.joystick.y;
      r += this.joystick.x;
    }
    const len = Math.hypot(f, r);
    if (len > 1) { f /= len; r /= len; }
    return { forward: f, right: r };
  }

  get sprinting() { return !!(this.keys.ShiftLeft || this.keys.ShiftRight); }

  /** Dipanggil di akhir frame untuk reset edge-trigger. */
  endFrame() {
    this.attackPressed = false;
    this.heavyPressed = false;
    this.dashPressed = false;
    this.jumpPressed = false;
    this.mouseDX = 0;
    this.mouseDY = 0;
    this.wheel = 0;
  }
}

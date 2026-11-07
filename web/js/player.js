/* =========================================================================
   player.js — karakter yang dikendalikan user.
   Facing mengikuti kamera (gaya shift-lock), gerak relatif kamera,
   sprint/stamina, jump, dash, block, dan serangan.
   ========================================================================= */

import * as THREE from 'three';
import { PHYS, COMBAT, CAMERA } from './config.js';
import { Fighter } from './entities.js';
import { stepEntity, dangerDpsAt, cameraRelative } from './physics.js';
import { tryAttack, tryDash, setBlocking, killFighter, applyDamage } from './combat.js';
import { Audio } from './audio.js';

const moveDir = new THREE.Vector2();
const dashDir = new THREE.Vector3();

export class Player extends Fighter {
  constructor(opts = {}) {
    super({ ...opts, isPlayer: true });
    this.input = opts.input;
    this.camYaw = Math.PI;
    this.camPitch = -0.2;
    this.camDist = CAMERA.distance;
    this.damageTickT = 0;
    this.landT = 0;
    this.coyote = 0;
    this.jumpBuf = 0;
    this.moving = false;
    this.sprinting = false;
    this.locked = false;
  }

  updateCameraLook(world, dt) {
    const sens = world.sens ?? 1;
    const dx = this.input.mouseDX;
    const dy = this.input.mouseDY;
    this.camYaw -= dx * 0.0024 * sens;
    this.camPitch -= dy * 0.0019 * sens;
    this.camPitch = Math.max(CAMERA.pitchMin, Math.min(CAMERA.pitchMax, this.camPitch));
    this.camDist += this.input.wheel * 1.6;
    this.camDist = Math.max(CAMERA.minDistance, Math.min(CAMERA.maxDistance, this.camDist));

    world.camYaw = this.camYaw;
    world.camPitch = this.camPitch;
    world.camDist = this.camDist;
  }

  update(game, dt) {
    const world = game.world;
    const input = this.input;

    if (!this.alive) {
      this.avatar.update(dt, { speed: 0, onGround: true, vy: 0 });
      return;
    }

    this.updateCameraLook(world, dt);

    /* --------------------------- arah gerak --------------------------- */
    const mv = input.moveVector();
    cameraRelative(mv, this.camYaw, moveDir);
    const moving = moveDir.lengthSq() > 0.0001;
    this.moving = moving;

    // hadap mengikuti kamera (shift-lock ala Roblox PvP)
    const targetYaw = Math.atan2(-Math.sin(this.camYaw), -Math.cos(this.camYaw));
    let dy = targetYaw - this.yaw;
    while (dy > Math.PI) dy -= Math.PI * 2;
    while (dy < -Math.PI) dy += Math.PI * 2;
    this.yaw += dy * Math.min(1, dt * 18);
    this.avatar.setYaw(this.yaw);

    /* ----------------------------- speed ----------------------------- */
    const base = PHYS.walkSpeed + this.speedBonus;
    const wantSprint = input.sprinting && moving && mv.forward > 0.2 && this.stamina > 1;
    this.sprinting = wantSprint;
    let speed = wantSprint ? PHYS.sprintSpeed + this.speedBonus : base;

    if (this.blocking) speed = Math.min(speed, COMBAT.blockSpeed);
    if (this.attacking) speed *= this.attacking.kind === 'heavy' ? 0.32 : 0.62;
    if (!this.onGround) speed *= 1;

    /* ------------------------------ dash ----------------------------- */
    if (input.dashPressed && !this.blocking) {
      const d = moving ? moveDir : { x: -Math.sin(this.camYaw), y: -Math.cos(this.camYaw) };
      tryDash(game, this, d.x, d.y);
    }

    const dashing = this.dashT > 0;
    if (!dashing) {
      const accel = this.onGround ? 16 : 16 * PHYS.airControl;
      const k = 1 - Math.exp(-accel * dt);
      this.vel.x += (moveDir.x * speed - this.vel.x) * k;
      this.vel.z += (moveDir.y * speed - this.vel.z) * k;

      // friction saat tidak ada input
      if (!moving && this.onGround) {
        const f = Math.exp(-PHYS.friction * dt);
        this.vel.x *= f;
        this.vel.z *= f;
      }
    }

    /* ------------------------------ jump ----------------------------- */
    // coyote time & jump buffer supaya lompat terasa responsif
    this.coyote = this.onGround ? PHYS.coyoteTime : Math.max(0, this.coyote - dt);
    this.jumpBuf = input.jumpPressed ? PHYS.jumpBuffer : Math.max(0, this.jumpBuf - dt);

    if (this.jumpBuf > 0 && this.coyote > 0 && !this.blocking && !this.attacking) {
      if (this.onGround) {
        this.wantsJump = true;
      } else {
        // baru saja meninggalkan tepi → masih boleh lompat (coyote)
        this.vel.y = PHYS.jumpPower;
        this.onGround = false;
        Audio.jump();
      }
      this.jumpBuf = 0;
      this.coyote = 0;
    }

    /* ---------------------------- combat ----------------------------- */
    if (input.blockHeld && !this.attacking) {
      if (!this.blocking) setBlocking(game, this, true);
    } else if (this.blocking) {
      setBlocking(game, this, false);
    }

    if (input.attackPressed && !this.blocking) tryAttack(game, this, 'light');
    if (input.heavyPressed && !this.blocking) tryAttack(game, this, 'heavy');

    /* ----------------------------- fisika ---------------------------- */
    const events = stepEntity(game.arena.colliders, this, dt);
    if (events.jumped) Audio.jump();
    if (events.landed) {
      if (this.vel.y < -30) {
        Audio.land();
        game.world.shake(0.08);
      }
    }

    /* -------------------------- zona bahaya -------------------------- */
    const dps = dangerDpsAt(game.arena.danger, this.pos.x, this.pos.y, this.pos.z);
    if (dps > 0) {
      this.damageTickT -= dt;
      if (this.damageTickT <= 0) {
        this.damageTickT = 0.5;
        applyDamage(game, this, dps * 0.5, null, { knockback: 0 });
        game.ui?.toast('Lava! Panas!', 'bad');
      }
    } else {
      this.damageTickT = 0;
    }

    /* --------------------------- jatuh dari map --------------------- */
    if (this.pos.y < game.arena.killY) {
      killFighter(game, this, this.lastHitBy && game.time - this.lastHitTime < 6 ? this.lastHitBy : null);
    }

    /* ---------------------------- avatar ---------------------------- */
    const horizontalSpeed = Math.hypot(this.vel.x, this.vel.z);
    this.updateAvatar(dt, horizontalSpeed);
  }
}

export { dashDir };

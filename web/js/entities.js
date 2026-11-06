/* =========================================================================
   entities.js — kelas dasar "Fighter" yang dipakai player maupun bot:
   status, gear, combat cooldown, stamina, respawn.
   ========================================================================= */

import * as THREE from 'three';
import { PHYS, COMBAT } from './config.js';
import { Avatar } from './avatar.js';

export const DEFAULT_GEAR = {
  lightMul: 1, heavyMul: 1, speedBonus: 0, maxHealthBonus: 0,
  damageReduction: 0, dashCdMul: 1, lifesteal: 0, staminaBonus: 0,
  hasSword: false, hasAxe: false, hasCoil: false,
};

let nextId = 1;

export class Fighter {
  constructor(opts = {}) {
    this.id = nextId++;
    this.name = opts.name || 'Player';
    this.isPlayer = !!opts.isPlayer;
    this.isBot = !!opts.isBot;

    this.look = opts.look || {};
    this.avatar = new Avatar({
      name: this.name,
      isPlayer: this.isPlayer,
      weapon: opts.weapon || 'none',
      ...this.look,
    });

    this.pos = new THREE.Vector3(0, 2, 0);
    this.vel = new THREE.Vector3();
    this.radius = PHYS.radius;
    this.height = PHYS.height;
    this.onGround = true;
    this.wantsJump = false;
    this.yaw = 0;

    this.alive = true;
    this.maxHealth = 100;
    this.health = 100;
    this.respawnT = 0;

    this.gear = { ...DEFAULT_GEAR, ...(opts.gear || {}) };
    this.applyGear();

    this.stats = { kills: 0, deaths: 0 };
    this.killstreak = 0;
    this.bestStreak = 0;
    this.dealt = 0;
    this.taken = 0;

    /* state combat */
    this.attackCd = 0;
    this.attacking = null;           // { kind, t, hitSet, spec }
    this.comboIndex = 0;
    this.comboTimer = 0;
    this.blocking = false;
    this.iframes = 0;
    this.hitCd = 0;                  // jeda kecil anti multi-hit

    /* stamina & dash */
    this.maxStamina = COMBAT.stamina.max;
    this.stamina = this.maxStamina;
    this.dashT = 0;
    this.dashCd = 0;
    this.dashDir = new THREE.Vector3();

    this.lastHitBy = null;
    this.lastHitTime = -99;
    this.spawnPos = new THREE.Vector3();
    this.deadTime = 0;
  }

  applyGear() {
    const g = this.gear;
    this.maxHealth = 100 + (g.maxHealthBonus || 0);
    this.maxStamina = COMBAT.stamina.max + (g.staminaBonus || 0);
    this.speedBonus = g.speedBonus || 0;
    this.avatar.setWeapon(g.hasAxe ? 'axe' : g.hasSword ? 'sword' : 'none');
    if (this.health > this.maxHealth) this.health = this.maxHealth;
    this.avatar.setHealth(this.health, this.maxHealth);
  }

  setWeaponForAttack() {
    // kapak hanya muncul saat heavy attack, pedang saat light
    if (this.gear.hasAxe && this.gear.hasSword) {
      this.avatar.setWeapon(this.attacking && this.attacking.kind === 'heavy' ? 'axe' : 'sword');
    } else if (this.gear.hasAxe) {
      this.avatar.setWeapon('axe');
    } else if (this.gear.hasSword) {
      this.avatar.setWeapon('sword');
    } else {
      this.avatar.setWeapon('none');
    }
  }

  get eyeY() { return this.pos.y + 4.8; }
  get chestY() { return this.pos.y + 3.2; }
  get center() { return new THREE.Vector3(this.pos.x, this.pos.y + 2.6, this.pos.z); }

  teleport(x, y, z, yaw = 0) {
    this.pos.set(x, y, z);
    this.vel.set(0, 0, 0);
    this.yaw = yaw;
    this.spawnPos.copy(this.pos);
    this.avatar.setPosition(x, y, z);
    this.avatar.setYaw(yaw);
    this.onGround = true;
  }

  faceYaw(yaw) {
    this.yaw = yaw;
    this.avatar.setYaw(yaw);
  }

  /** Vektor arah hadap (XZ). */
  forward(out = new THREE.Vector3()) {
    return out.set(Math.sin(this.yaw), 0, Math.cos(this.yaw));
  }

  heal(n) {
    if (!this.alive) return 0;
    const before = this.health;
    this.health = Math.min(this.maxHealth, this.health + n);
    this.avatar.setHealth(this.health, this.maxHealth);
    return this.health - before;
  }

  setHealth(hp) {
    this.health = Math.max(0, Math.min(this.maxHealth, hp));
    this.avatar.setHealth(this.health, this.maxHealth);
  }

  updateTimers(dt) {
    this.attackCd = Math.max(0, this.attackCd - dt);
    this.iframes = Math.max(0, this.iframes - dt);
    this.hitCd = Math.max(0, this.hitCd - dt);
    this.dashCd = Math.max(0, this.dashCd - dt);
    this.comboTimer = Math.max(0, this.comboTimer - dt);
    if (this.comboTimer === 0) this.comboIndex = 0;

    if (this.dashT > 0) this.dashT = Math.max(0, this.dashT - dt);

    // stamina
    const sprinting = !!(this.sprinting && this.moving);
    if (sprinting) {
      this.stamina = Math.max(0, this.stamina - COMBAT.stamina.sprintDrain * dt);
    } else {
      this.stamina = Math.min(this.maxStamina, this.stamina + COMBAT.stamina.regen * dt);
    }
    if (this.stamina <= 1) this.sprinting = false;
  }

  updateAvatar(dt, speed) {
    this.avatar.setPosition(this.pos.x, this.pos.y, this.pos.z);
    this.avatar.setYaw(this.yaw);
    this.avatar.update(dt, {
      speed,
      onGround: this.onGround,
      vy: this.vel.y,
    });
    this.avatar.setHealth(this.health, this.maxHealth);
  }

  dispose() {
    this.avatar.dispose();
  }
}

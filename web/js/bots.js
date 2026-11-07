/* =========================================================================
   bots.js — NPC fighter dengan AI sederhana (chase / attack / retreat /
   wander), termasuk reaksi block, dash, lompat, dan chat ala Roblox.
   ========================================================================= */

import * as THREE from 'three';
import { PHYS } from './config.js';
import { Chatter } from './markov.js';
import { Fighter } from './entities.js';
import { stepEntity, dangerDpsAt, groundBelow } from './physics.js';
import { tryAttack, tryDash, setBlocking, applyDamage, killFighter } from './combat.js';

const tmpDir = new THREE.Vector3();

const PERSONALITIES = [
  { name: 'agresif', aggression: 0.95, blockChance: 0.18, dashChance: 0.28, reaction: 0.22, speedMul: 1.03 },
  { name: 'seimbang', aggression: 0.7, blockChance: 0.32, dashChance: 0.16, reaction: 0.34, speedMul: 1.0 },
  { name: 'defensif', aggression: 0.5, blockChance: 0.5, dashChance: 0.1, reaction: 0.45, speedMul: 0.97 },
  { name: 'liar', aggression: 0.85, blockChance: 0.12, dashChance: 0.4, reaction: 0.3, speedMul: 1.06 },
];

export class Bot extends Fighter {
  constructor(opts = {}) {
    super({ ...opts, isBot: true });
    this.personality = PERSONALITIES[Math.floor(Math.random() * PERSONALITIES.length)];
    this.state = 'wander';
    this.stateT = 0;
    this.target = null;
    this.attackThink = Math.random() * 0.85;
    this.blockThink = 0;
    this.wanderPoint = new THREE.Vector3();
    this.stuckT = 0;
    this.avoidT = 0;
    this.avoidDir = new THREE.Vector3();
    this.chatT = 18 + Math.random() * 32;
    this.skill = 0.55 + Math.random() * 0.4;
    // sebagian bot lebih tertarik ke player, sebagian lebih suka lawan sesama bot
    this.playerBias = 3 + Math.random() * 12;
    this.arenaLimit = 55;          // di-set main.js saat spawn (setengah ukuran map)
    this.name = opts.name || 'Bot';
    this.moving = false;
    this.sprinting = Math.random() > 0.6;
    this.pickWander();
  }

  pickWander() {
    const sp = this.spawnPos;
    const lim = this.arenaLimit;
    // batasi titik wander di dalam arena, kalau tidak bot menekan dinding terus
    this.wanderPoint.set(
      Math.max(-lim, Math.min(lim, sp.x + Math.cos(Math.random() * Math.PI * 2) * (12 + Math.random() * 26))),
      sp.y,
      Math.max(-lim, Math.min(lim, sp.z + Math.sin(Math.random() * Math.PI * 2) * (12 + Math.random() * 26)))
    );
  }

  aiOnRespawn() {
    this.state = 'wander';
    this.pickWander();
    this.target = null;
  }

  pickTarget(game) {
    let best = null;
    let bestScore = -Infinity;
    for (const e of game.entities) {
      if (e === this || !e.alive) continue;
      const d = Math.hypot(e.pos.x - this.pos.x, e.pos.z - this.pos.z);
      if (d > 90) continue;
      let score = 100 - d;
      if (e.isPlayer) score += this.playerBias; // hanya sebagian bot mengincar player
      if (e === this.target) score += 12;      // stickiness
      if (e.health < e.maxHealth * 0.35) score += 20;
      if (score > bestScore) { bestScore = score; best = e; }
    }
    this.target = best;
  }

  think(game, dt) {
    this.attackThink -= dt;
    this.blockThink -= dt;
    this.chatT -= dt;

    // obrolan acak ala Markov: tidak membalas siapa pun, hanya mengoceh
    if (this.chatT <= 0) {
      this.chatT = 26 + Math.random() * 34;
      const lastAny = game.lastBotChat ?? -999;
      if (game.time - lastAny > 8 && Math.random() < 0.8) {
        game.lastBotChat = game.time;
        const line = Chatter.generate(8 + Math.floor(Math.random() * 8));
        game.ui?.addChat(`${this.name}: ${line}`, 'bot');
      }
    }

    if (!this.target || !this.target.alive || Math.random() < dt * 0.5) {
      this.pickTarget(game);
    }
    const target = this.target;

    // bahaya: keluar dari lava
    const dps = dangerDpsAt(game.arena.danger, this.pos.x, this.pos.y, this.pos.z);
    if (dps > 0) {
      const cx = -this.pos.x;
      const cz = -this.pos.z;
      this.avoidDir.set(cx, 0, cz).normalize();
      this.avoidT = 0.5;
    }

    // jangan mendekati tepi map
    const edge = game.arena.size * 0.62;
    if (Math.abs(this.pos.x) > edge || Math.abs(this.pos.z) > edge) {
      this.avoidDir.set(-this.pos.x, 0, -this.pos.z).normalize();
      this.avoidT = Math.max(this.avoidT, 0.4);
    }

    if (!target) {
      this.state = 'wander';
    } else {
      const d = Math.hypot(target.pos.x - this.pos.x, target.pos.z - this.pos.z);
      const dy = target.pos.y - this.pos.y;
      if (this.health < this.maxHealth * 0.25 && this.personality.aggression < 0.8 && Math.random() < 0.02) {
        this.state = 'retreat';
        this.stateT = 1.4 + Math.random() * 1.6;
      } else if (d < 7.2 && Math.abs(dy) < 3.4) {
        this.state = 'attack';
      } else if (d < 46) {
        this.state = 'chase';
      } else {
        this.state = 'wander';
      }
    }

    if (this.stateT > 0) this.stateT -= dt;
  }

  update(game, dt) {
    if (!this.alive) {
      this.avatar.update(dt, { speed: 0, onGround: true, vy: 0 });
      return;
    }

    this.think(game, dt);

    const target = this.target;
    const desired = tmpDir.set(0, 0, 0);
    let speed = 0;
    const base = PHYS.walkSpeed + this.speedBonus;
    let sprinting = false;

    if (this.state === 'chase' && target) {
      desired.set(target.pos.x - this.pos.x, 0, target.pos.z - this.pos.z);
      speed = (base + 3) * this.personality.speedMul;
      sprinting = true;
    } else if (this.state === 'attack' && target) {
      const dx = target.pos.x - this.pos.x;
      const dz = target.pos.z - this.pos.z;
      const d = Math.hypot(dx, dz);
      // jaga jarak ideal
      if (d > 5.4) {
        desired.set(dx, 0, dz);
        speed = base;
      } else if (d < 4.2) {
        desired.set(-dx, 0, -dz);
        speed = base * 0.7;
      } else {
        // strafe
        desired.set(-dz, 0, dx);
        speed = base * 0.55;
      }

      // hadap target
      if (d > 0.01) {
        const yaw = Math.atan2(dx, dz);
        let diff = yaw - this.yaw;
        while (diff > Math.PI) diff -= Math.PI * 2;
        while (diff < -Math.PI) diff += Math.PI * 2;
        this.yaw += diff * Math.min(1, dt * 10);
        this.avatar.setYaw(this.yaw);
      }

      // serangan
      if (this.attackThink <= 0 && !this.attacking && !this.blocking) {
        const dist = Math.hypot(dx, dz);
        if (dist < 6.6 && Math.abs(target.pos.y - this.pos.y) < 3.6) {
          const heavy = Math.random() < 0.24 + this.personality.aggression * 0.12;
          if (tryAttack(game, this, heavy ? 'heavy' : 'light')) {
            this.attackThink = (heavy ? 1.0 : 0.42) + Math.random() * this.personality.reaction * 1.6;
          }
        }
      }

      // block reaksi kalau target menyerang
      if (this.blockThink <= 0 && target.attacking && this.personality.blockChance > Math.random() * 1.6) {
        setBlocking(game, this, true);
        this.blockThink = 0.55;
        setTimeout(() => {
          if (this.alive && this.blocking) setBlocking(game, this, false);
        }, 260 + Math.random() * 220);
      }

      // dash sesekali
      if (Math.random() < this.personality.dashChance * dt * 0.9 && this.dashCd <= 0) {
        tryDash(game, this, dx, dz);
      }
    } else if (this.state === 'retreat') {
      desired.set(this.pos.x - (target ? target.pos.x : 0), 0, this.pos.z - (target ? target.pos.z : 0));
      speed = base + 2;
      sprinting = true;
      setBlocking(game, this, false);
    } else {
      // wander
      const dx = this.wanderPoint.x - this.pos.x;
      const dz = this.wanderPoint.z - this.pos.z;
      const d = Math.hypot(dx, dz);
      if (d < 3 || this.stateT < -6) {
        this.pickWander();
        this.stateT = 0;
      }
      desired.set(dx, 0, dz);
      speed = base * 0.55;
      if (target) {
        // tetap hadap target saat mengembara
        const yaw = Math.atan2(target.pos.x - this.pos.x, target.pos.z - this.pos.z);
        let diff = yaw - this.yaw;
        while (diff > Math.PI) diff -= Math.PI * 2;
        while (diff < -Math.PI) diff += Math.PI * 2;
        this.yaw += diff * Math.min(1, dt * 4);
        this.avatar.setYaw(this.yaw);
      }
    }

    // avoidance
    if (this.avoidT > 0) {
      this.avoidT -= dt;
      desired.copy(this.avoidDir);
      speed = Math.max(speed, base);
    }

    if (desired.lengthSq() > 0.0001) desired.normalize();

    // hindari melangkah ke jurang (penting untuk Sky Islands)
    if (this.moving !== false && this.onGround && desired.lengthSq() > 0.001) {
      const ahead = 3.2;
      const g = groundBelow(
        game.arena.colliders,
        this.pos.x + desired.x * ahead,
        this.pos.z + desired.z * ahead,
        this.pos.y + 0.6, this.radius * 0.8, 0.7
      );
      if (!Number.isFinite(g) || g < this.pos.y - 5) {
        const turn = Math.atan2(desired.x, desired.z) + (Math.random() < 0.5 ? 2.2 : -2.2);
        desired.set(Math.sin(turn), 0, Math.cos(turn));
      }
    }
    this.moving = desired.lengthSq() > 0.001;
    this.sprinting = sprinting && this.stamina > 2;

    // hadap arah gerak jika tidak sedang menyerang
    if (!this.target || this.state === 'wander') {
      if (this.moving) {
        const yaw = Math.atan2(desired.x, desired.z);
        let diff = yaw - this.yaw;
        while (diff > Math.PI) diff -= Math.PI * 2;
        while (diff < -Math.PI) diff += Math.PI * 2;
        this.yaw += diff * Math.min(1, dt * 6);
        this.avatar.setYaw(this.yaw);
      }
    }

    // gerak
    if (this.dashT <= 0) {
      const k = 1 - Math.exp(-(this.onGround ? 12 : 5) * dt);
      this.vel.x += (desired.x * speed - this.vel.x) * k;
      this.vel.z += (desired.z * speed - this.vel.z) * k;
    }

    // lompat kalau target di atas / tersangkut
    if (this.onGround) {
      if (target && target.pos.y > this.pos.y + 2.5 && Math.random() < dt * 2.2) this.wantsJump = true;
      if (this.stuckT > 0.55) {
        this.wantsJump = true;
        this.stuckT = 0;
        // saat macet, utamakan arah ke tengah arena (bukan arah acak yang bisa
        // tetap menabrak dinding)
        const cx = -this.pos.x;
        const cz = -this.pos.z;
        const len = Math.hypot(cx, cz) || 1;
        this.avoidDir.set(
          cx / len + (Math.random() - 0.5) * 0.6,
          0,
          cz / len + (Math.random() - 0.5) * 0.6
        ).normalize();
        this.avoidT = 0.6;
      }
    }

    const beforeX = this.pos.x;
    const beforeZ = this.pos.z;
    stepEntity(game.arena.colliders, this, dt);

    const moved = Math.hypot(this.pos.x - beforeX, this.pos.z - beforeZ);
    if (this.moving && moved < 0.02 && this.onGround) this.stuckT += dt;
    else this.stuckT = Math.max(0, this.stuckT - dt * 2);

    // lava
    const dps = dangerDpsAt(game.arena.danger, this.pos.x, this.pos.y, this.pos.z);
    if (dps > 0) {
      this.damageTickT = (this.damageTickT || 0) - dt;
      if (this.damageTickT <= 0) {
        this.damageTickT = 0.5;
        applyDamage(game, this, dps * 0.5, null, {});
      }
    }

    if (this.pos.y < game.arena.killY) {
      killFighter(game, this, this.lastHitBy && game.time - this.lastHitTime < 6 ? this.lastHitBy : null);
    }

    this.updateAvatar(dt, Math.hypot(this.vel.x, this.vel.z));
  }
}

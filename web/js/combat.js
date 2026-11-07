/* =========================================================================
   combat.js — sistem pertarungan: hitbox kerucut di depan karakter,
   damage, block, knockback, i-frame dash, VFX, dan kill handling.
   Referensi tuning: CombatHandler + ChopperSword di file .rbxl repo ini
   (light/heavy attack, cooldown, progress bar, knockback).
   ========================================================================= */

import * as THREE from 'three';
import { COMBAT, ROUND, PHYS } from './config.js';
import { dangerDpsAt } from './physics.js';
import { Audio } from './audio.js';

const VFX_GEO = new THREE.BoxGeometry(0.42, 0.42, 0.42);

const tmp = new THREE.Vector3();
const tmp2 = new THREE.Vector3();

/* ------------------------------------------------------------------ VFX -- */
export function spawnBurst(game, pos, color = '#ffe08a', count = 9, power = 12) {
  // batasi jumlah partikel supaya tidak meledak saat combo besar
  if (game.fx.length > 140) count = Math.min(count, 2);
  for (let i = 0; i < count; i++) {
    const mat = new THREE.MeshStandardMaterial({
      color: new THREE.Color(color),
      emissive: new THREE.Color(color),
      emissiveIntensity: 1.4,
      transparent: true,
      opacity: 1,
    });
    const mesh = new THREE.Mesh(VFX_GEO, mat);
    mesh.position.copy(pos);
    mesh.position.x += (Math.random() - 0.5) * 1.2;
    mesh.position.y += (Math.random() - 0.5) * 1.2;
    mesh.position.z += (Math.random() - 0.5) * 1.2;
    const vel = new THREE.Vector3(
      (Math.random() - 0.5) * power,
      Math.random() * power * 0.75 + 2,
      (Math.random() - 0.5) * power
    );
    game.fx.push({ mesh, vel, life: 0.5 + Math.random() * 0.3, maxLife: 0.8, spin: Math.random() * 8 });
    game.fxGroup.add(mesh);
  }
}

export function updateFx(game, dt) {
  for (let i = game.fx.length - 1; i >= 0; i--) {
    const f = game.fx[i];
    f.life -= dt;
    f.vel.y -= 42 * dt;
    f.mesh.position.addScaledVector(f.vel, dt);
    f.mesh.rotation.x += f.spin * dt;
    f.mesh.rotation.y += f.spin * dt * 0.7;
    const k = Math.max(0, f.life / f.maxLife);
    f.mesh.material.opacity = k;
    f.mesh.scale.setScalar(0.35 + k * 0.9);
    if (f.life <= 0) {
      game.fxGroup.remove(f.mesh);
      f.mesh.material.dispose();
      game.fx.splice(i, 1);
    }
  }
}

/* ------------------------------------------------------------- attacking -- */
export function attackSpec(fighter, kind) {
  if (kind === 'heavy') {
    return {
      ...COMBAT.heavy,
      damage: COMBAT.heavy.damage * fighter.gear.heavyMul,
      kind: 'heavy',
    };
  }
  const idx = Math.min(fighter.comboIndex, COMBAT.combo.length - 1);
  const c = COMBAT.combo[idx];
  return {
    ...COMBAT.light,
    ...c,
    damage: c.damage * fighter.gear.lightMul,
    crit: !!c.crit,
    kind: 'light',
    combo: idx,
  };
}

export function tryAttack(game, fighter, kind = 'light') {
  if (!fighter.alive || fighter.attacking || fighter.blocking) return false;
  if (fighter.attackCd > 0) return false;
  // selama intermission tidak ada damage — pemain aman saat belanja
  if (game.combatEnabled === false) return false;

  const heavy = kind === 'heavy';
  if (heavy && fighter.stamina < COMBAT.stamina.heavyCost) {
    if (fighter.isPlayer) Audio.deny();
    return false;
  }

  const spec = attackSpec(fighter, kind);
  fighter.attacking = {
    kind,
    t: 0,
    spec,
    hitSet: new Set(),
    struck: false,
  };
  fighter.attackCd = spec.cooldown;
  fighter.setWeaponForAttack();
  fighter.avatar.playAttack(kind);
  if (heavy) fighter.stamina = Math.max(0, fighter.stamina - COMBAT.stamina.heavyCost);

  if (fighter.isPlayer) {
    Audio.swing();
    if (heavy) Audio.slash();
  } else {
    // bot: suara lebih pelan
    Audio.swing();
  }
  return true;
}

/** Cek hitbox dan terapkan damage. Dipanggil tiap frame selama window aktif. */
function resolveHits(game, fighter) {
  const atk = fighter.attacking;
  if (!atk) return;
  const spec = atk.spec;
  const start = spec.windup ?? 0;
  const end = start + (spec.active ?? 0.12);
  if (atk.t < start || atk.t > end) return;

  const fwd = fighter.forward(tmp);
  for (const target of game.entities) {
    if (target === fighter || !target.alive) continue;
    if (atk.hitSet.has(target.id)) continue;
    if (target.iframes > 0) continue;

    const dx = target.pos.x - fighter.pos.x;
    const dz = target.pos.z - fighter.pos.z;
    const dist = Math.hypot(dx, dz);
    if (dist > spec.range + target.radius) continue;
    if (Math.abs(target.pos.y - fighter.pos.y) > 4.6) continue;

    if (dist > 0.001) {
      const dot = (dx / dist) * fwd.x + (dz / dist) * fwd.z;
      if (dot < Math.cos(spec.arc)) continue;
    }

    atk.hitSet.add(target.id);
    atk.struck = true;

    const dir = tmp2.set(dx, 0, dz);
    if (dir.lengthSq() < 0.0001) dir.copy(fwd);
    dir.normalize();

    applyDamage(game, target, spec.damage, fighter, {
      crit: !!spec.crit,
      knockback: spec.knockback,
      dir,
      heavy: spec.kind === 'heavy',
    });
  }
}

/* ---------------------------------------------------------------- damage -- */
export function applyDamage(game, target, amount, attacker, opts = {}) {
  if (!target.alive) return;

  // dash i-frame
  if (target.iframes > 0) {
    game.ui?.damageNumber(target.center, 'MISS', 'blocked');
    return;
  }

  let dmg = amount;
  let blocked = false;

  if (target.blocking) {
    const toAttacker = new THREE.Vector3(
      attacker ? attacker.pos.x - target.pos.x : 0, 0,
      attacker ? attacker.pos.z - target.pos.z : 0
    );
    if (toAttacker.lengthSq() > 0.0001) {
      toAttacker.normalize();
      const f = target.forward(tmp);
      if (f.dot(toAttacker) > 0.15) {
        blocked = true;
        dmg *= 1 - COMBAT.blockReduction;
      }
    }
  }

  dmg *= 1 - (target.gear.damageReduction || 0);
  dmg = Math.max(1, Math.round(dmg));

  target.health -= dmg;
  target.taken += dmg;
  target.lastHitBy = attacker || null;
  if (attacker) {
    if (!target.damagers) target.damagers = new Map();
    target.damagers.set(attacker.id, game.time);
  }
  target.lastHitTime = game.time;
  target.iframes = Math.max(target.iframes, COMBAT.hitInvuln);
  target.avatar.hitFlash(blocked ? 0.08 : 0.18);

  if (attacker) {
    attacker.dealt += dmg;
    // lifesteal
    if (attacker.gear.lifesteal > 0) {
      const healed = attacker.heal(attacker.gear.lifesteal);
      if (healed > 0 && attacker.isPlayer) game.ui?.damageNumber(attacker.center, `+${Math.round(healed)}`, 'heal');
    }
  }

  // knockback
  if (opts.knockback && opts.dir) {
    const k = opts.knockback * (blocked ? 0.25 : 1);
    target.vel.x += opts.dir.x * k;
    target.vel.z += opts.dir.z * k;
    if (!blocked) target.vel.y = Math.max(target.vel.y, opts.heavy ? 9 : 4.5);
    target.onGround = false;
  }

  /* feedback */
  const pos = target.center;
  if (blocked) {
    game.ui?.damageNumber(pos, 'BLOCK', 'blocked');
    if (target.isPlayer) Audio.block();
  } else {
    game.ui?.damageNumber(pos, String(dmg), opts.crit ? 'crit' : '');
    if (target.isPlayer) {
      Audio.hit(opts.crit);
      game.ui?.hurt(dmg / Math.max(1, target.maxHealth));
    } else {
      Audio.hit(opts.crit);
    }
  }

  if (opts.heavy) Audio.heavyHit();
  spawnBurst(game, pos, opts.crit ? '#ffd34d' : '#ff8f7a', opts.crit ? 12 : 7, opts.heavy ? 16 : 11);

  if (attacker?.isPlayer) {
    game.world.shake(opts.crit ? 0.35 : 0.16);
    game.ui?.crosshairHit();
  }
  if (target.isPlayer) {
    game.world.shake(0.45);
    game.ui?.hitFlash?.(blocked ? 0.35 : 1);
  }

  target.avatar.setHealth(target.health, target.maxHealth);
  game.ui?.refreshHealth?.();

  if (target.health <= 0) killFighter(game, target, attacker);
}

export function killFighter(game, victim, attacker) {
  if (!victim.alive) return;
  if (!game.stats) game.stats = { kills: 0, deaths: 0, coinsEarned: 0 };
  victim.alive = false;
  victim.health = 0;
  victim.deadTime = 0;
  victim.avatar.setDead(true);
  victim.avatar.setHealth(0, victim.maxHealth);
  victim.stats.deaths++;
  victim.killstreak = 0;
  victim.respawnT = COMBAT.respawnTime;

  if (attacker && attacker !== victim) {
    attacker.stats.kills++;
    attacker.killstreak++;
    attacker.bestStreak = Math.max(attacker.bestStreak, attacker.killstreak);

    const bonus = 1 + Math.min(ROUND.maxKillstreakBonus, (attacker.killstreak - 1) * 0.25);
    const coins = Math.round(ROUND.killCoins * bonus);

    if (attacker.isPlayer) {
      game.addCoins(coins, `${victim.name}`);
      Audio.kill();
      game.ui?.toast(`KO ${victim.name}  +${coins} coins`, 'gold');
      game.stats.kills++;
      game.onPlayerKill?.(victim);
      game.ui?.refreshHealth();
    } else if (victim.isPlayer) {
      Audio.death();
      game.ui?.toast(`Kamu dikalahkan oleh ${attacker.name}`, 'bad');
      game.stats.deaths++;
      game.onPlayerDeath?.(attacker);
      game.ui?.deathCam?.();
    }

    // assist: siapa pun yang melukai korban dalam 6 detik terakhir
    if (victim.damagers) {
      for (const [id, t] of victim.damagers) {
        if (id === attacker.id || game.time - t > 6) continue;
        const helper = game.entities.find((e) => e.id === id);
        if (helper && helper.isPlayer && helper.alive) {
          game.addCoins(ROUND.assistCoins, `assist ${victim.name}`, true);
          game.ui?.toast(`Assist +${ROUND.assistCoins}`, 'gold');
        }
      }
      victim.damagers.clear();
    }

    game.ui?.addChat(`${attacker.name} mengalahkan ${victim.name}`, 'warn');
    if (attacker.killstreak >= 3) {
      game.ui?.toast(`${attacker.name} killstreak ${attacker.killstreak}!`, 'gold');
    }
  } else if (victim.isPlayer) {
    Audio.death();
    game.stats.deaths++;
    game.onPlayerDeath?.(attacker);
    game.ui?.deathCam?.();
  }

  game.ui?.refreshLeaderboard();
  game.ui?.refreshHealth();
}

/* ---------------------------------------------------------------- respawn -- */
export function respawn(game, fighter) {
  const spawn = game.arena.randomSpawn();
  fighter.health = fighter.maxHealth;
  fighter.alive = true;
  fighter.deadTime = 0;
  fighter.respawnT = 0;
  fighter.attacking = null;
  fighter.attackCd = 0;
  fighter.comboIndex = 0;
  fighter.comboTimer = 0;
  fighter.dashT = 0;
  fighter.iframes = 1.2;
  fighter.blocking = false;
  fighter.stamina = fighter.maxStamina;
  fighter.vel.set(0, 0, 0);
  fighter.avatar.setDead(false);
  fighter.avatar.setHealth(fighter.maxHealth, fighter.maxHealth);
  fighter.teleport(spawn.x, spawn.y + 0.4, spawn.z, Math.random() * Math.PI * 2);
  if (fighter.isPlayer) {
    game.ui?.respawnCam?.();
    game.ui?.refreshHealth();
  } else {
    fighter.aiOnRespawn?.();
  }
  game.ui?.refreshLeaderboard();
}

/* ------------------------------------------------------------------ block -- */
export function setBlocking(game, fighter, on) {
  if (!fighter.alive) return;
  if (on && fighter.attacking) return;
  fighter.blocking = !!on;
  fighter.avatar.setBlocking(fighter.blocking);
  if (fighter.isPlayer && on) Audio.block();
}

/* ------------------------------------------------------------------- dash -- */
export function tryDash(game, fighter, dirX, dirZ) {
  if (!fighter.alive || fighter.dashCd > 0) return false;
  if (fighter.stamina < COMBAT.stamina.dashCost) {
    if (fighter.isPlayer) Audio.deny();
    return false;
  }
  let dx = dirX, dz = dirZ;
  if (!dx && !dz) {
    const f = fighter.forward(tmp);
    dx = f.x; dz = f.z;
  }
  const len = Math.hypot(dx, dz) || 1;
  fighter.dashDir.set(dx / len, 0, dz / len);
  fighter.dashT = COMBAT.dash.duration;
  fighter.dashCd = COMBAT.dash.cooldown * (fighter.gear.dashCdMul || 1);
  fighter.iframes = Math.max(fighter.iframes, COMBAT.dash.iframes);
  fighter.blocking = false;
  fighter.avatar.setBlocking(false);
  fighter.stamina = Math.max(0, fighter.stamina - COMBAT.stamina.dashCost);

  Audio.dash();
  spawnBurst(game, fighter.center, '#8fd4ff', 6, 6);
  if (fighter.isPlayer) game.world.shake(0.12);
  return true;
}

/* ------------------------------------------------------------------ update -- */
export function updateCombat(game, dt) {
  for (const fighter of game.entities) {
    if (!fighter.alive) {
      fighter.deadTime += dt;
      if (fighter.respawnT > 0) {
        fighter.respawnT -= dt;
        if (fighter.respawnT <= 0) respawn(game, fighter);
      }
      continue;
    }

    fighter.updateTimers(dt);

    // regen ala "Health" script Roblox: pulih pelan kalau lama tidak kena hit
    if (fighter.alive && fighter.health < fighter.maxHealth
        && game.time - fighter.lastHitTime > 6
        && !(game.arena.danger && game.arena.danger.length
          && dangerDpsAt(game.arena.danger, fighter.pos.x, fighter.pos.y, fighter.pos.z) > 0)) {
      fighter.heal(4.5 * dt);
    }

    if (fighter.attacking) {
      fighter.attacking.t += dt;
      resolveHits(game, fighter);
      const spec = fighter.attacking.spec;
      const total = (spec.windup ?? 0) + (spec.active ?? 0.12) + (spec.recover ?? 0.16);
      if (fighter.attacking.t >= total) {
        const wasCombo = fighter.attacking.kind === 'light';
        fighter.attacking = null;
        if (wasCombo) {
          fighter.comboIndex = (fighter.comboIndex + 1) % COMBAT.combo.length;
          fighter.comboTimer = COMBAT.comboWindow;
        }
        fighter.setWeaponForAttack();
      }
    }

    // dash motion
    if (fighter.dashT > 0) {
      fighter.vel.x = fighter.dashDir.x * COMBAT.dash.speed;
      fighter.vel.z = fighter.dashDir.z * COMBAT.dash.speed;
      fighter.vel.y = Math.max(fighter.vel.y, 0);
    }

    // batas dunia
    const s = game.arena.size;
    if (Math.abs(fighter.pos.x) > s * 1.4 || Math.abs(fighter.pos.z) > s * 1.4) {
      fighter.pos.x = Math.max(-s * 1.3, Math.min(s * 1.3, fighter.pos.x));
      fighter.pos.z = Math.max(-s * 1.3, Math.min(s * 1.3, fighter.pos.z));
    }
  }
}

export { PHYS };

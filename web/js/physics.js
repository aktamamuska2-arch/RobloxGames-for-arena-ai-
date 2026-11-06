/* =========================================================================
   physics.js — fisika karakter sederhana: tabrakan AABB vs collider box,
   gravitasi, step-up tangga, deteksi tanah, dan zona bahaya.
   Dibuat manual supaya ringan & deterministik (tanpa engine fisika penuh).
   ========================================================================= */

import * as THREE from 'three';
import { PHYS } from './config.js';

const EPS = 0.001;

function overlaps(c, x, y, z, r, h) {
  return (
    x + r > c.x0 && x - r < c.x1 &&
    z + r > c.z0 && z - r < c.z1 &&
    y + h > c.y0 && y + 0.2 < c.y1
  );
}

function hitsAt(colliders, x, y, z, r, h) {
  const out = [];
  for (let i = 0; i < colliders.length; i++) {
    if (overlaps(colliders[i], x, y, z, r, h)) out.push(colliders[i]);
  }
  return out;
}

/**
 * Tinggi permukaan tertinggi di bawah titik (untuk mendeteksi tanah).
 * Hanya mempertimbangkan collider yang bagian atasnya <= y + tolerance.
 */
export function groundBelow(colliders, x, z, y, r, tolerance = 0.65) {
  let top = -Infinity;
  for (let i = 0; i < colliders.length; i++) {
    const c = colliders[i];
    if (x + r <= c.x0 || x - r >= c.x1 || z + r <= c.z0 || z - r >= c.z1) continue;
    if (c.y1 > y + tolerance) continue;
    if (c.y1 > top) top = c.y1;
  }
  return top;
}

/** Cek apakah sebuah posisi bertabrakan dengan dunia. */
export function isBlocked(colliders, x, y, z, r, h) {
  return hitsAt(colliders, x, y, z, r, h).length > 0;
}

/** Cari collider yang menutupi titik (untuk zona bahaya). */
export function colliderAt(colliders, x, y, z) {
  for (let i = 0; i < colliders.length; i++) {
    const c = colliders[i];
    if (x > c.x0 && x < c.x1 && z > c.z0 && z < c.z1 && y >= c.y0 - 0.1 && y <= c.y1 + 0.5) return c;
  }
  return null;
}

/**
 * Step fisika untuk satu entity.
 * ent = { pos:Vector3, vel:Vector3, onGround:boolean, radius, height, wantsJump }
 * Mengembalikan event { landed:boolean, jumped:boolean, hitWall:boolean }
 */
export function stepEntity(colliders, ent, dt, opts = {}) {
  const r = ent.radius ?? PHYS.radius;
  const h = ent.height ?? PHYS.height;
  const gravity = opts.gravity ?? PHYS.gravity;
  const events = { landed: false, jumped: false, stepped: false, wall: false };

  if (ent.wantsJump && ent.onGround) {
    ent.vel.y = PHYS.jumpPower;
    ent.onGround = false;
    ent.wantsJump = false;
    events.jumped = true;
  }
  ent.wantsJump = false;

  /* ------------------------------ horizontal ------------------------------ */
  const moveAxis = (axis, amount) => {
    if (Math.abs(amount) < EPS) return;
    const nx = axis === 'x' ? ent.pos.x + amount : ent.pos.x;
    const nz = axis === 'z' ? ent.pos.z + amount : ent.pos.z;

    if (!isBlocked(colliders, nx, ent.pos.y, nz, r, h)) {
      ent.pos[axis] += amount;
      return;
    }

    // coba naik tangga kecil
    let highest = -Infinity;
    for (const c of hitsAt(colliders, nx, ent.pos.y, nz, r, h)) {
      if (c.y1 > highest) highest = c.y1;
    }
    if (highest - ent.pos.y <= (opts.stepHeight ?? PHYS.stepHeight) && highest - ent.pos.y > 0) {
      const stepY = highest + 0.02;
      if (!isBlocked(colliders, nx, stepY, nz, r, h)) {
        ent.pos.y = stepY;
        ent.pos[axis] += amount;
        events.stepped = true;
        return;
      }
    }
    events.wall = true;
    ent.vel[axis] = 0;
  };

  moveAxis('x', ent.vel.x * dt);
  moveAxis('z', ent.vel.z * dt);

  /* ------------------------------- vertikal ------------------------------- */
  const prevY = ent.pos.y;
  ent.vel.y -= gravity * dt;
  if (ent.vel.y < -PHYS.terminalVelocity) ent.vel.y = -PHYS.terminalVelocity;
  ent.pos.y += ent.vel.y * dt;

  // langit-langit
  if (ent.vel.y > 0) {
    const above = hitsAt(colliders, ent.pos.x, ent.pos.y, ent.pos.z, r, h);
    let ceiling = Infinity;
    for (const c of above) if (c.y0 < ceiling) ceiling = c.y0;
    if (ceiling < Infinity && ent.pos.y + ent.vel.y * dt + h > ceiling) {
      ent.pos.y = ceiling - h - 0.01;
      ent.vel.y = 0;
    }
  }

  const top = groundBelow(colliders, ent.pos.x, ent.pos.z, prevY + 0.5, r * 0.95, 0.7);
  if (top > -Infinity && ent.pos.y <= top + 0.02) {
    if (!ent.onGround) events.landed = true;
    ent.pos.y = top;
    ent.vel.y = 0;
    ent.onGround = true;
  } else {
    ent.onGround = false;
  }

  return events;
}

/** Dorong entity keluar dari entity lain (anti tumpang tindih). */
export function separateEntities(entities, dt) {
  for (let i = 0; i < entities.length; i++) {
    const a = entities[i];
    if (!a.alive) continue;
    for (let j = i + 1; j < entities.length; j++) {
      const b = entities[j];
      if (!b.alive) continue;
      const dx = b.pos.x - a.pos.x;
      const dz = b.pos.z - a.pos.z;
      const dy = Math.abs(b.pos.y - a.pos.y);
      if (dy > 4) continue;
      const minDist = (a.radius || PHYS.radius) + (b.radius || PHYS.radius) - 0.25;
      const dist = Math.hypot(dx, dz);
      if (dist > 0.0001 && dist < minDist) {
        const push = (minDist - dist) * 0.5;
        const nx = dx / dist;
        const nz = dz / dist;
        a.pos.x -= nx * push * 0.6;
        a.pos.z -= nz * push * 0.6;
        b.pos.x += nx * push * 0.6;
        b.pos.z += nz * push * 0.6;
      }
    }
  }
}

/** Apakah entity berada di dalam zona bahaya (lava). */
export function dangerDpsAt(danger, x, y, z) {
  let dps = 0;
  for (const d of danger) {
    if (x > d.x0 && x < d.x1 && z > d.z0 && z < d.z1 && y >= d.y0 - 0.2 && y <= d.y1 + 1.2) {
      dps += d.dps;
    }
  }
  return dps;
}

/**
 * Arah gerak horizontal relatif kamera.
 * Kamera berada di belakang target pada offset (sin(yaw), cos(yaw)),
 * jadi arah "maju" karakter adalah (-sin(yaw), -cos(yaw)).
 */
export function cameraRelative(input, camYaw, out = new THREE.Vector2()) {
  const fwd = input.forward || 0;
  const right = input.right || 0;
  const sin = Math.sin(camYaw);
  const cos = Math.cos(camYaw);
  out.set(right * cos - fwd * sin, -right * sin - fwd * cos);
  if (out.lengthSq() > 1) out.normalize();
  return out;
}

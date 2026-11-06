/* =========================================================================
   maps.js — 4 arena yang dipilih acak setiap round ("map randomizer").
   Semua geometri dibuat dari box/cylinder primitif ala part Roblox,
   lengkap dengan collider AABB, spawn point, zona bahaya, dan tema langit.
   ========================================================================= */

import * as THREE from 'three';
import { getTexture } from './textures.js';

const matCache = new Map();

function material(color, texName, opts = {}) {
  const key = `${color}|${texName}|${opts.emissive || ''}|${opts.opacity || 1}|${opts.roughness || 0.85}`;
  if (matCache.has(key)) return matCache.get(key);
  const mat = new THREE.MeshStandardMaterial({
    color: new THREE.Color(color),
    roughness: opts.roughness ?? 0.85,
    metalness: opts.metalness ?? 0.03,
    transparent: (opts.opacity ?? 1) < 1,
    opacity: opts.opacity ?? 1,
    map: texName ? getTexture(texName, 1, 1) : null,
    emissive: opts.emissive ? new THREE.Color(opts.emissive) : new THREE.Color('#000000'),
    emissiveIntensity: opts.emissiveIntensity ?? 1,
  });
  matCache.set(key, mat);
  return mat;
}

export class Arena {
  constructor(name, subtitle, theme) {
    this.name = name;
    this.subtitle = subtitle;
    this.theme = theme;
    this.group = new THREE.Group();
    this.colliders = [];      // { x0, x1, y0, y1, z0, z1 }
    this.spawns = [];         // { x, y, z }
    this.danger = [];         // { x0, x1, y0, y1, z0, z1, dps }
    this.animated = [];       // { mat, sx, sy }
    this.killY = -60;
    this.size = 120;
  }

  /**
   * Tambah box padat (solid) atau dekorasi.
   * x,z = pusat; y = dasar (bottom).
   */
  box(x, y, z, w, h, d, color, opts = {}) {
    const texName = opts.tex ?? 'stud';
    const repeat = opts.repeat ?? [Math.max(1, w / 6), Math.max(1, h / 6)];
    const mat = material(color, texName, opts).clone();
    if (mat.map) {
      mat.map = getTexture(texName, repeat[0], repeat[1]);
    }
    const geo = new THREE.BoxGeometry(w, h, d);
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(x, y + h / 2, z);
    mesh.castShadow = opts.castShadow !== false;
    mesh.receiveShadow = true;
    this.group.add(mesh);

    if (opts.solid !== false) {
      this.colliders.push({
        x0: x - w / 2, x1: x + w / 2,
        y0: y, y1: y + h,
        z0: z - d / 2, z1: z + d / 2,
      });
    }
    if (opts.dps) {
      this.danger.push({
        x0: x - w / 2, x1: x + w / 2,
        y0: y, y1: y + h,
        z0: z - d / 2, z1: z + d / 2,
        dps: opts.dps,
      });
    }
    if (opts.spin || opts.bob) {
      this.animated.push({
        mesh, spin: opts.spin || 0, bob: opts.bob || 0,
        baseY: y + h / 2, phase: Math.random() * Math.PI * 2,
      });
    }
    return mesh;
  }

  /** Silinder (tiang, tong, dsb). */
  cylinder(x, y, z, r, h, color, opts = {}) {
    const mat = material(color, opts.tex ?? null, opts).clone();
    if (mat.map) mat.map = getTexture(opts.tex, 2, 2);
    const mesh = new THREE.Mesh(new THREE.CylinderGeometry(r, r * (opts.taper ?? 1), h, 20), mat);
    mesh.position.set(x, y + h / 2, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    this.group.add(mesh);
    if (opts.solid !== false) {
      this.colliders.push({
        x0: x - r * 0.8, x1: x + r * 0.8,
        y0: y, y1: y + h,
        z0: z - r * 0.8, z1: z + r * 0.8,
      });
    }
    return mesh;
  }

  spawn(x, y, z) {
    this.spawns.push({ x, y, z });
    // pad spawn bergaya Roblox
    const ring = new THREE.Mesh(
      new THREE.CylinderGeometry(3.1, 3.1, 0.25, 26),
      new THREE.MeshStandardMaterial({
        color: '#eaf6ff', emissive: '#1e90ff', emissiveIntensity: 0.55,
        roughness: 0.4, transparent: true, opacity: 0.9,
      })
    );
    ring.position.set(x, y + 0.16, z);
    ring.receiveShadow = true;
    this.group.add(ring);
    return this;
  }

  update(dt, t) {
    for (const a of this.animated) {
      if (a.spin) a.mesh.rotation.y += a.spin * dt;
      if (a.bob) a.mesh.position.y = a.baseY + Math.sin(t * 1.5 + a.phase) * 0.7;
    }
  }

  randomSpawn() {
    if (!this.spawns.length) return { x: 0, y: 3, z: 0 };
    return this.spawns[Math.floor(Math.random() * this.spawns.length)];
  }

  dispose() {
    this.group.traverse((o) => {
      if (o.isMesh) {
        o.geometry?.dispose?.();
        if (Array.isArray(o.material)) o.material.forEach((m) => m.dispose());
        else o.material?.dispose?.();
      }
    });
    this.group.clear();
    this.colliders.length = 0;
    this.spawns.length = 0;
    this.danger.length = 0;
    this.animated.length = 0;
  }
}

/* ========================================================================== */
/*  MAP 1 — BRICK ARENA (default, paling mirip arena klasik Roblox)           */
/* ========================================================================== */
function buildBrickArena() {
  const a = new Arena('Brick Arena', 'Arena klasik bata & pilar', {
    skyTop: '#3f7fbf', skyBottom: '#d7ecf9', fog: '#a9d4e8', fogNear: 150, fogFar: 460,
    hemi: '#e6f4ff', hemiGround: '#6b6357', sun: '#fff3d6', sunIntensity: 2.2,
  });

  // lantai utama
  a.box(0, -2, 0, 150, 2, 150, '#b04a3c', { tex: 'brick', repeat: [18, 18] });

  // dinding keliling
  const wallColor = '#8f3b31';
  a.box(0, 0, -75, 150, 16, 4, wallColor, { tex: 'brick', repeat: [20, 3] });
  a.box(0, 0, 75, 150, 16, 4, wallColor, { tex: 'brick', repeat: [20, 3] });
  a.box(-75, 0, 0, 4, 16, 150, wallColor, { tex: 'brick', repeat: [3, 20] });
  a.box(75, 0, 0, 4, 16, 150, wallColor, { tex: 'brick', repeat: [3, 20] });

  // platform tengah + tangga
  a.box(0, 0, 0, 34, 6, 34, '#c9714f', { tex: 'brick', repeat: [7, 2] });
  a.box(0, 6, 0, 26, 1, 26, '#e0c48a', { tex: 'tile', repeat: [5, 5] });
  for (let i = 0; i < 4; i++) {
    a.box(0, i * 1.5, 19 + (4 - i) * 2.2, 10, 1.5, 2.4, '#c9714f', { tex: 'brick' });
    a.box(0, i * 1.5, -19 - (4 - i) * 2.2, 10, 1.5, 2.4, '#c9714f', { tex: 'brick' });
  }

  // empat pilar
  const pillarZ = [-46, 46];
  const pillarX = [-46, 46];
  for (const px of pillarX) {
    for (const pz of pillarZ) {
      a.cylinder(px, 0, pz, 4.4, 22, '#a8503f', { tex: 'brick' });
      a.box(px, 22, pz, 11, 1.6, 11, '#e0c48a', { tex: 'tile' });
    }
  }

  // krate & cover
  const crates = [
    [-28, 0, 24, 7], [-22, 0, 32, 6], [26, 0, 26, 8], [34, 0, 12, 6],
    [24, 0, -30, 7], [-30, 0, -22, 6], [-52, 0, 6, 8], [52, 0, -8, 8],
    [10, 6, -8, 5], [-10, 6, 8, 5],
  ];
  for (const [x, y, z, s] of crates) {
    a.box(x, y, z, s, s, s, '#c98b3f', { tex: 'brick', repeat: [2, 2] });
  }

  // ramp ke platform
  a.box(0, 0, 34, 14, 3, 10, '#b06040', { tex: 'brick' });

  // spawn ring
  const spawnRing = [
    [0, 0, 55], [0, 0, -55], [55, 0, 0], [-55, 0, 0],
    [42, 0, 42], [-42, 0, 42], [42, 0, -42], [-42, 0, -42],
  ];
  for (const [x, y, z] of spawnRing) a.spawn(x, y, z);
  a.killY = -45;
  return a;
}

/* ========================================================================== */
/*  MAP 2 — NEON GRID                                                         */
/* ========================================================================== */
function buildNeonGrid() {
  const a = new Arena('Neon Grid', 'Kisi neon di ruang gelap', {
    skyTop: '#05070d', skyBottom: '#0f2233', fog: '#08131d', fogNear: 90, fogFar: 300,
    hemi: '#3a6c8a', hemiGround: '#0a0f14', sun: '#9fe8ff', sunIntensity: 1.1,
  });

  a.box(0, -2, 0, 130, 2, 130, '#16202b', { tex: 'tile', repeat: [16, 16] });

  // jalur menyala membentuk plus
  a.box(0, 0, 0, 26, 0.6, 130, '#0b3d4a', { tex: 'neon', repeat: [2, 14], emissive: '#0891b2', emissiveIntensity: 0.5, solid: false });
  a.box(0, 0, 0, 130, 0.6, 26, '#0b3d4a', { tex: 'neon', repeat: [14, 2], emissive: '#0891b2', emissiveIntensity: 0.5, solid: false });

  // platform tengah
  a.box(0, 0, 0, 30, 8, 30, '#0e1a24', { tex: 'neon', repeat: [3, 3], emissive: '#0ea5b7', emissiveIntensity: 0.35 });
  a.box(0, 8, 0, 22, 0.8, 22, '#101a22', { tex: 'tile', repeat: [4, 4] });
  a.box(0, 8, 0, 8, 0.3, 8, '#22d3ee', { tex: 'tile', emissive: '#0891b2', emissiveIntensity: 1.2, solid: false });

  // tangga
  for (let i = 0; i < 5; i++) {
    a.box(0, i * 1.6, 21 + (5 - i) * 2, 12, 1.6, 2.2, '#0e1a24', { tex: 'neon' });
    a.box(0, i * 1.6, -21 - (5 - i) * 2, 12, 1.6, 2.2, '#0e1a24', { tex: 'neon' });
  }

  // blok mengambang
  const floaters = [
    [-40, 14, -30, 10, '#1b2a3a', '#7c3aed'],
    [42, 18, 26, 12, '#1b2a3a', '#f472b6'],
    [-38, 22, 36, 8, '#1b2a3a', '#22d3ee'],
    [36, 10, -40, 9, '#1b2a3a', '#a3e635'],
  ];
  for (const [x, y, z, s, col, emis] of floaters) {
    a.box(x, y, z, s, s, s, col, {
      tex: 'neon', emissive: emis, emissiveIntensity: 0.75,
      repeat: [1, 1], spin: 0.12, bob: 1,
    });
  }

  // tiang cahaya
  for (const [x, z] of [[-58, -58], [58, -58], [-58, 58], [58, 58]]) {
    a.cylinder(x, 0, z, 3, 26, '#14202b', { tex: 'metal' });
    a.box(x, 26, z, 7, 1.2, 7, '#22d3ee', { tex: 'tile', emissive: '#22d3ee', emissiveIntensity: 1.4, solid: false });
  }

  // dinding rendah
  for (const [x, z, w, d] of [[0, -60, 120, 4], [0, 60, 120, 4], [-60, 0, 4, 120], [60, 0, 4, 120]]) {
    a.box(x, 0, z, w, 6, d, '#0d1620', { tex: 'metal' });
  }

  const spawns = [[0, 0, 52], [0, 0, -52], [52, 0, 0], [-52, 0, 0], [34, 0, 34], [-34, 0, -34], [34, 0, -34], [-34, 0, 34]];
  for (const [x, y, z] of spawns) a.spawn(x, y, z);
  a.killY = -40;
  return a;
}

/* ========================================================================== */
/*  MAP 3 — SKY ISLANDS                                                       */
/* ========================================================================== */
function buildSkyIslands() {
  const a = new Arena('Sky Islands', 'Pulau terapung — jangan jatuh', {
    skyTop: '#2b4c8c', skyBottom: '#ffc98a', fog: '#ffd2a1', fogNear: 120, fogFar: 420,
    hemi: '#ffe6c7', hemiGround: '#4a5f7a', sun: '#ffd9a0', sunIntensity: 2.0,
  });

  const islands = [
    { x: 0, y: 0, z: 0, w: 54, d: 54, c: '#4f8a3f' },
    { x: -52, y: 8, z: 26, w: 32, d: 32, c: '#4f8a3f' },
    { x: 54, y: -4, z: -18, w: 34, d: 34, c: '#4f8a3f' },
    { x: 10, y: 14, z: -56, w: 28, d: 28, c: '#4f8a3f' },
  ];

  for (const is of islands) {
    a.box(is.x, is.y - 4, is.z, is.w, 4, is.d, '#8a6a45', { tex: 'brick', repeat: [6, 2] });
    a.box(is.x, is.y, is.z, is.w - 1, 0.7, is.d - 1, is.c, { tex: 'grass', repeat: [6, 6] });
    // bebatuan dekorasi
    a.box(is.x + is.w * 0.3, is.y + 0.7, is.z - is.d * 0.3, 5, 4, 5, '#7d8894', { tex: 'brick', repeat: [2, 2] });
  }

  // jembatan
  a.box(-26, 4, 13, 24, 1.2, 8, '#a88b5c', { tex: 'brick', repeat: [4, 1] });
  a.box(27, -2, -9, 26, 1.2, 8, '#a88b5c', { tex: 'brick', repeat: [4, 1] });
  a.box(5, 7, -28, 8, 1.2, 24, '#a88b5c', { tex: 'brick', repeat: [1, 4] });

  // pohon
  function tree(x, y, z) {
    a.cylinder(x, y, z, 1.1, 7, '#6b4a2c');
    a.box(x, y + 7, z, 9, 5, 9, '#3e7a33', { tex: 'grass', repeat: [2, 2] });
    a.box(x, y + 11, z, 5, 3, 5, '#4f9440', { tex: 'grass', repeat: [1, 1] });
  }
  tree(-14, 0.7, -14);
  tree(18, 0.7, 12);
  tree(-56, 8.7, 32);

  // platform kecil bergerak (dekor)
  a.box(28, 10, 28, 10, 1, 10, '#b08a5a', { tex: 'brick', repeat: [2, 2], spin: 0.35, bob: 1 });

  const spawns = [[0, 0.7, 20], [0, 0.7, -20], [20, 0.7, 0], [-20, 0.7, 0], [-52, 8.7, 26], [54, -3.3, -18], [10, 14.7, -56]];
  for (const [x, y, z] of spawns) a.spawn(x, y, z);
  a.killY = -55;
  return a;
}

/* ========================================================================== */
/*  MAP 4 — LAVA FOUNDRY                                                      */
/* ========================================================================== */
function buildLavaFoundry() {
  const a = new Arena('Lava Foundry', 'Pabrik lava — lantai bisa membakar', {
    skyTop: '#2a0f10', skyBottom: '#a33a1c', fog: '#6d2418', fogNear: 90, fogFar: 330,
    hemi: '#ff9a6a', hemiGround: '#2a1b18', sun: '#ffb072', sunIntensity: 1.7,
  });

  a.box(0, -2, 0, 120, 2, 120, '#3a3a42', { tex: 'metal', repeat: [14, 14] });

  // kolam lava
  const pools = [
    [-34, -30, 26, 20], [34, 30, 26, 18], [0, 0, 18, 18],
  ];
  for (const [x, z, w, d] of pools) {
    // lava sedikit menonjol di atas lantai supaya kelihatan & bisa "dirender"
    a.box(x, 0, z, w, 0.32, d, '#ff7a18', {
      tex: 'lava', repeat: [3, 3], dps: 26, solid: false,
      emissive: '#ff4400', emissiveIntensity: 1.4,
    });
  }

  // jembatan di atas lava tengah
  a.box(0, 0.6, 0, 6, 0.8, 26, '#4a4a54', { tex: 'metal', repeat: [1, 4] });
  a.box(0, 0.6, 0, 26, 0.8, 6, '#4a4a54', { tex: 'metal', repeat: [4, 1] });

  // platform tinggi
  a.box(-42, 0, 34, 30, 9, 30, '#46464f', { tex: 'metal', repeat: [5, 2] });
  a.box(42, 0, -34, 30, 9, 30, '#46464f', { tex: 'metal', repeat: [5, 2] });
  for (let i = 0; i < 3; i++) {
    a.box(-42, i * 3, 44 + (3 - i) * 2.2, 12, 3, 2.4, '#52525c', { tex: 'metal' });
    a.box(42, i * 3, -44 - (3 - i) * 2.2, 12, 3, 2.4, '#52525c', { tex: 'metal' });
  }

  // kontainer & pipa
  const crates = [
    [-18, 0, 40, 8], [18, 0, -40, 8], [-52, 0, -6, 7], [52, 0, 6, 7],
    [26, 0, 12, 6], [-26, 0, -12, 6],
  ];
  for (const [x, y, z, s] of crates) a.box(x, y, z, s, s, s, '#7a4a20', { tex: 'metal', repeat: [2, 2] });
  a.cylinder(-58, 0, 30, 4, 24, '#5a5a66', { tex: 'metal' });
  a.cylinder(58, 0, -30, 4, 24, '#5a5a66', { tex: 'metal' });

  const spawns = [[0, 0, 48], [0, 0, -48], [48, 0, 0], [-48, 0, 0], [-42, 9, 34], [42, 9, -34], [-14, 0, 20], [14, 0, -20]];
  for (const [x, y, z] of spawns) a.spawn(x, y, z);
  a.killY = -45;
  return a;
}

/* ========================================================================== */
/*  Registry + helper                                                         */
/* ========================================================================== */
const BUILDERS = [buildBrickArena, buildNeonGrid, buildSkyIslands, buildLavaFoundry];

export const MAP_INFO = [
  { id: 'brick', name: 'Brick Arena', blurb: 'Arena klasik bata & pilar' },
  { id: 'neon', name: 'Neon Grid', blurb: 'Kisi neon di ruang gelap' },
  { id: 'sky', name: 'Sky Islands', blurb: 'Pulau terapung — jangan jatuh' },
  { id: 'lava', name: 'Lava Foundry', blurb: 'Pabrik lava — lantai bisa membakar' },
];

/** Bangun map acak (atau sesuai indeks). */
export function createArena(index = null) {
  const i = index === null ? Math.floor(Math.random() * BUILDERS.length) : index % BUILDERS.length;
  return BUILDERS[i]();
}

export function arenaCount() {
  return BUILDERS.length;
}

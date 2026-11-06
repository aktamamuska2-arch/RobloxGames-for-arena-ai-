/* =========================================================================
   textures.js — tekstur procedural (kanvas), supaya proyek ini tetap
   100% offline dan tidak memakai aset Roblox yang proprietary.
   ========================================================================= */

import * as THREE from 'three';

const cache = new Map();

function canvas(size = 256) {
  const c = document.createElement('canvas');
  c.width = c.height = size;
  return { c, ctx: c.getContext('2d') };
}

function finish(c, { repeat = true, aniso = 8 } = {}) {
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  if (repeat) {
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  }
  tex.anisotropy = aniso;
  tex.needsUpdate = true;
  return tex;
}

/** Tekstur "stud" khas Roblox: permukaan plastik dengan tonjolan bulat. */
function makeStud() {
  const { c, ctx } = canvas(128);
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, 128, 128);

  // seam antar stud
  ctx.strokeStyle = 'rgba(0,0,0,0.10)';
  ctx.lineWidth = 2;
  ctx.strokeRect(1, 1, 126, 126);

  // bayangan stud
  ctx.beginPath();
  ctx.arc(64, 68, 30, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(0,0,0,0.13)';
  ctx.fill();

  // badan stud
  const grad = ctx.createRadialGradient(56, 56, 4, 64, 64, 32);
  grad.addColorStop(0, '#ffffff');
  grad.addColorStop(0.65, '#f4f4f4');
  grad.addColorStop(1, '#dcdcdc');
  ctx.beginPath();
  ctx.arc(64, 64, 29, 0, Math.PI * 2);
  ctx.fillStyle = grad;
  ctx.fill();

  ctx.beginPath();
  ctx.arc(64, 64, 29, 0, Math.PI * 2);
  ctx.strokeStyle = 'rgba(0,0,0,0.08)';
  ctx.lineWidth = 2;
  ctx.stroke();
  return finish(c);
}

/** Dinding bata. */
function makeBrick() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, 256, 256);
  const bh = 32;
  const bw = 64;
  for (let row = 0; row < 8; row++) {
    const offset = row % 2 ? bw / 2 : 0;
    for (let col = -1; col < 5; col++) {
      const x = col * bw + offset;
      const y = row * bh;
      ctx.fillStyle = `rgba(0,0,0,${0.02 + ((row * 7 + col * 13) % 5) * 0.012})`;
      ctx.fillRect(x + 2, y + 2, bw - 4, bh - 4);
      ctx.strokeStyle = 'rgba(0,0,0,0.13)';
      ctx.lineWidth = 2;
      ctx.strokeRect(x + 1, y + 1, bw - 2, bh - 2);
    }
  }
  return finish(c);
}

/** Lantai konser / ubin besar. */
function makeTile() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, 256, 256);
  ctx.strokeStyle = 'rgba(0,0,0,0.14)';
  ctx.lineWidth = 3;
  for (let i = 0; i <= 256; i += 64) {
    ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, 256); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, i); ctx.lineTo(256, i); ctx.stroke();
  }
  // kilau halus
  const g = ctx.createLinearGradient(0, 0, 256, 256);
  g.addColorStop(0, 'rgba(255,255,255,0.12)');
  g.addColorStop(0.5, 'rgba(255,255,255,0)');
  g.addColorStop(1, 'rgba(0,0,0,0.05)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 256, 256);
  return finish(c);
}

/** Kisi neon (map Neon Grid): garis menyala di atas dasar gelap. */
function makeNeon() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#0a1018';
  ctx.fillRect(0, 0, 256, 256);
  ctx.strokeStyle = 'rgba(0, 240, 255, 0.85)';
  ctx.lineWidth = 3;
  ctx.shadowColor = 'rgba(0, 240, 255, 0.9)';
  ctx.shadowBlur = 14;
  ctx.strokeRect(6, 6, 244, 244);
  ctx.beginPath();
  ctx.moveTo(128, 6); ctx.lineTo(128, 250);
  ctx.moveTo(6, 128); ctx.lineTo(250, 128);
  ctx.stroke();
  ctx.shadowBlur = 0;
  return finish(c);
}

/** Logam gelap (Lava Foundry). */
function makeMetal() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 256; i += 4) {
    ctx.fillStyle = `rgba(0,0,0,${0.02 + Math.random() * 0.03})`;
    ctx.fillRect(i, 0, 2, 256);
  }
  ctx.strokeStyle = 'rgba(0,0,0,0.22)';
  ctx.lineWidth = 4;
  ctx.strokeRect(2, 2, 252, 252);
  // baut sudut
  [[18, 18], [238, 18], [18, 238], [238, 238]].forEach(([x, y]) => {
    ctx.beginPath(); ctx.arc(x, y, 7, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0,0,0,0.28)'; ctx.fill();
    ctx.beginPath(); ctx.arc(x - 2, y - 2, 3, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.fill();
  });
  return finish(c);
}

/** Lava: blob oranye-merah. */
function makeLava() {
  const { c, ctx } = canvas(256);
  const g = ctx.createLinearGradient(0, 0, 256, 256);
  g.addColorStop(0, '#ff8a1e');
  g.addColorStop(0.45, '#e23c0d');
  g.addColorStop(1, '#8a1500');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 140; i++) {
    const x = Math.random() * 256;
    const y = Math.random() * 256;
    const r = 3 + Math.random() * 16;
    const blob = ctx.createRadialGradient(x, y, 0, x, y, r);
    const hot = Math.random() > 0.5;
    blob.addColorStop(0, hot ? 'rgba(255,230,140,0.9)' : 'rgba(120,20,0,0.65)');
    blob.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = blob;
    ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
  }
  return finish(c);
}

/** Rumput / tanah untuk pulau. */
function makeGrass() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 1400; i++) {
    ctx.fillStyle = `rgba(0,0,0,${Math.random() * 0.13})`;
    const x = Math.random() * 256;
    const y = Math.random() * 256;
    ctx.fillRect(x, y, 2 + Math.random() * 3, 2 + Math.random() * 3);
  }
  return finish(c);
}

const BUILDERS = {
  stud: makeStud,
  brick: makeBrick,
  tile: makeTile,
  neon: makeNeon,
  metal: makeMetal,
  lava: makeLava,
  grass: makeGrass,
};

/**
 * Ambil tekstur dengan skala dunia: repeat dihitung dari ukuran part
 * supaya kepadatan stud konsisten di semua ukuran.
 */
export function getTexture(name, repeatX = 1, repeatY = 1) {
  const base = BUILDERS[name] || BUILDERS.stud;
  const key = `${name}|${repeatX}|${repeatY}`;
  if (cache.has(key)) return cache.get(key);
  const tex = base().clone();
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(repeatX, repeatY);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.needsUpdate = true;
  cache.set(key, tex);
  return tex;
}

/** Wajah klasik Roblox (dua mata + senyum) untuk kepala. */
export function makeFaceTexture() {
  const { c, ctx } = canvas(128);
  ctx.clearRect(0, 0, 128, 128);
  ctx.fillStyle = 'rgba(20,18,16,0.92)';
  // mata
  ctx.beginPath(); ctx.ellipse(44, 46, 8, 11, 0, 0, Math.PI * 2); ctx.fill();
  ctx.beginPath(); ctx.ellipse(84, 46, 8, 11, 0, 0, Math.PI * 2); ctx.fill();
  // senyum
  ctx.strokeStyle = 'rgba(20,18,16,0.92)';
  ctx.lineWidth = 7;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.arc(64, 62, 26, 0.25 * Math.PI, 0.75 * Math.PI);
  ctx.stroke();
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

/** Tekstur untuk nametag / health bar di atas kepala. */
export function makeLabelTexture(text, color = '#ffffff', sub = '') {
  const w = 512;
  const h = 160;
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  const ctx = c.getContext('2d');
  ctx.clearRect(0, 0, w, h);

  ctx.font = '700 52px "Segoe UI", system-ui, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.lineWidth = 10;
  ctx.strokeStyle = 'rgba(0,0,0,0.72)';
  ctx.strokeText(text, w / 2, 58);
  ctx.fillStyle = color;
  ctx.fillText(text, w / 2, 58);

  if (sub) {
    ctx.font = '600 34px "Segoe UI", system-ui, sans-serif';
    ctx.lineWidth = 7;
    ctx.strokeText(sub, w / 2, 108);
    ctx.fillStyle = 'rgba(255,255,255,0.72)';
    ctx.fillText(sub, w / 2, 108);
  }

  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

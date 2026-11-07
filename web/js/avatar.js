/* =========================================================================
   avatar.js — karakter blocky R6 ala Roblox (6 part + kepala) dengan
   animasi jalan/lompat/serangan, nametag, health bar, dan senjata.
   ========================================================================= */

import * as THREE from 'three';
import { makeFaceTexture, makeLabelTexture } from './textures.js';

function mat(color, opts = {}) {
  return new THREE.MeshStandardMaterial({
    color: new THREE.Color(color),
    roughness: opts.roughness ?? 0.72,
    metalness: opts.metalness ?? 0.02,
  });
}

function boxMesh(w, h, d, material) {
  const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
  m.castShadow = true;
  m.receiveShadow = true;
  return m;
}

export class Avatar {
  constructor(opts = {}) {
    this.name = opts.name || 'Player';
    this.isPlayer = !!opts.isPlayer;
    this.colors = {
      skin: opts.skin || '#f1c9a5',
      shirt: opts.shirt || '#00b06f',
      pants: opts.pants || '#2b3a55',
      hair: opts.hair || '#2b1d16',
    };
    this.weapon = opts.weapon || 'none';   // none | sword | axe
    this.dead = false;
    this.health = opts.maxHealth ?? 100;
    this.maxHealth = opts.maxHealth ?? 100;

    this.group = new THREE.Group();
    this.group.name = `avatar:${this.name}`;

    this.body = new THREE.Group();
    this.group.add(this.body);

    this.materials = [];
    const skinMat = mat(this.colors.skin);
    const shirtMat = mat(this.colors.shirt);
    const pantsMat = mat(this.colors.pants);
    const hairMat = mat(this.colors.hair, { roughness: 0.85 });
    this.materials.push(skinMat, shirtMat, pantsMat, hairMat);

    /* torso (baju) */
    this.torso = boxMesh(2, 2, 1, shirtMat);
    this.torso.position.set(0, 3, 0);
    this.body.add(this.torso);

    /* kepala + wajah */
    this.headPivot = new THREE.Group();
    this.headPivot.position.set(0, 4, 0);
    this.body.add(this.headPivot);

    const headMats = [
      skinMat, skinMat, skinMat, skinMat,
      new THREE.MeshStandardMaterial({ map: makeFaceTexture(this.colors.skin), roughness: 0.7 }),
      skinMat,
    ];
    this.materials.push(headMats[4]);
    this.head = new THREE.Mesh(new THREE.BoxGeometry(1.3, 1.3, 1.3), headMats);
    this.head.position.set(0, 0.66, 0);
    this.head.castShadow = true;
    this.head.receiveShadow = true;
    this.headPivot.add(this.head);

    /* rambut (topi tipis ala Roblox) */
    this.hair = boxMesh(1.42, 0.34, 1.42, hairMat);
    this.hair.position.set(0, 1.32, 0);
    this.headPivot.add(this.hair);

    /* lengan */
    this.armL = this._limb(1, 2, 1, skinMat, -1.5, 4, 0);
    this.armR = this._limb(1, 2, 1, skinMat, 1.5, 4, 0);
    this.armLPivot = this.armL.pivot;
    this.armRPivot = this.armR.pivot;

    /* kaki */
    this.legL = this._limb(1, 2, 1, pantsMat, -0.5, 2, 0);
    this.legR = this._limb(1, 2, 1, pantsMat, 0.5, 2, 0);
    this.legLPivot = this.legL.pivot;
    this.legRPivot = this.legR.pivot;

    /* senjata */
    this.weaponGroup = new THREE.Group();
    this.weaponGroup.position.set(0, -1.85, 0.15);
    // senjata dipegang menghadap ke depan (kalau tidak, bilah menusuk lantai)
    this.weaponGroup.rotation.x = -Math.PI / 2;
    this.armRPivot.add(this.weaponGroup);
    this._buildWeapon();
    this.setWeapon(this.weapon);

    /* nametag */
    this.labelTex = makeLabelTexture(
      this.name,
      this.isPlayer ? '#8ff7c2' : '#ffffff',
      ''
    );
    const labelMat = new THREE.SpriteMaterial({
      map: this.labelTex, transparent: true, depthTest: true, depthWrite: false,
    });
    this.label = new THREE.Sprite(labelMat);
    this.label.scale.set(9.5, 2.97, 1);
    this.label.position.set(0, 7.6, 0);
    this.label.renderOrder = 20;
    this.group.add(this.label);

    /* health bar di atas kepala */
    const bgMat = new THREE.SpriteMaterial({ color: '#101418', depthTest: true, transparent: true, opacity: 0.85 });
    this.hpBg = new THREE.Sprite(bgMat);
    this.hpBg.scale.set(5.4, 0.62, 1);
    this.hpBg.position.set(0, 6.45, 0);
    this.hpBg.renderOrder = 19;
    this.group.add(this.hpBg);

    const fillMat = new THREE.SpriteMaterial({ color: '#25d98a', depthTest: true, transparent: true });
    this.hpFill = new THREE.Sprite(fillMat);
    this.hpFill.center.set(0, 0.5);
    this.hpFill.scale.set(5.1, 0.4, 1);
    this.hpFill.position.set(-2.55, 6.45, 0);
    this.hpFill.renderOrder = 20;
    this.group.add(this.hpFill);

    /* shield (block) */
    this.shield = new THREE.Mesh(
      new THREE.SphereGeometry(3.4, 16, 12),
      new THREE.MeshStandardMaterial({
        color: '#7fd7ff', transparent: true, opacity: 0.22,
        roughness: 0.2, metalness: 0.1, side: THREE.DoubleSide,
      })
    );
    this.shield.position.set(0, 2.9, 0.9);
    this.shield.visible = false;
    this.group.add(this.shield);

    /* state animasi */
    this.phase = 0;
    this.animSpeed = 0;
    this.attackT = -1;
    this.attackKind = 'light';
    this.blocking = false;
    this.hurtT = 0;
    this.deadT = 0;
    this.flashT = 0;
    this.baseY = 0;
    this.yaw = 0;
  }

  _limb(w, h, d, material, px, py, pz) {
    const pivot = new THREE.Group();
    pivot.position.set(px, py, pz);
    const mesh = boxMesh(w, h, d, material);
    mesh.position.set(0, -h / 2, 0);
    pivot.add(mesh);
    this.body.add(pivot);
    return { pivot, mesh };
  }

  _buildWeapon() {
    const steel = new THREE.MeshStandardMaterial({ color: '#d7dee7', metalness: 0.75, roughness: 0.28 });
    const darkSteel = new THREE.MeshStandardMaterial({ color: '#8e99a6', metalness: 0.6, roughness: 0.4 });
    const wood = new THREE.MeshStandardMaterial({ color: '#4a3222', roughness: 0.9 });
    this.materials.push(steel, darkSteel, wood);

    // pedang
    this.sword = new THREE.Group();
    const grip = new THREE.Mesh(new THREE.BoxGeometry(0.2, 1.1, 0.2), wood);
    grip.position.set(0, -0.35, 0);
    this.sword.add(grip);
    const guard = new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.16, 0.22), darkSteel);
    guard.position.set(0, -0.85, 0);
    this.sword.add(guard);
    const blade = new THREE.Mesh(new THREE.BoxGeometry(0.17, 3.4, 0.34), steel);
    blade.position.set(0, -2.6, 0);
    this.sword.add(blade);
    const tip = new THREE.Mesh(new THREE.ConeGeometry(0.19, 0.5, 4), steel);
    tip.position.set(0, -4.5, 0);
    tip.rotation.y = Math.PI / 4;
    this.sword.add(tip);
    this.sword.traverse((o) => { if (o.isMesh) { o.castShadow = true; } });

    // kapak
    this.axe = new THREE.Group();
    const haft = new THREE.Mesh(new THREE.BoxGeometry(0.22, 3.4, 0.22), wood);
    haft.position.set(0, -1.4, 0);
    this.axe.add(haft);
    const headBlade = new THREE.Mesh(new THREE.BoxGeometry(0.28, 1.5, 1.5), darkSteel);
    headBlade.position.set(0, -2.7, 0.45);
    this.axe.add(headBlade);
    const spike = new THREE.Mesh(new THREE.ConeGeometry(0.22, 1.2, 4), steel);
    spike.position.set(0, -2.7, -0.85);
    spike.rotation.x = Math.PI / 2;
    this.axe.add(spike);
    this.axe.traverse((o) => { if (o.isMesh) { o.castShadow = true; } });

    this.weaponGroup.add(this.sword);
    this.weaponGroup.add(this.axe);
  }

  setWeapon(kind) {
    this.weapon = kind || 'none';
    this.sword.visible = this.weapon === 'sword';
    this.axe.visible = this.weapon === 'axe';
  }

  setPosition(x, y, z) {
    this.group.position.set(x, y, z);
  }

  setYaw(yaw) {
    this.yaw = yaw;
    this.group.rotation.y = yaw;
  }

  setHealth(hp, max = this.maxHealth) {
    this.health = Math.max(0, Math.min(max, hp));
    this.maxHealth = max;
    const pct = this.maxHealth > 0 ? this.health / this.maxHealth : 0;
    this.hpFill.scale.x = Math.max(0.001, 5.1 * pct);
    this.hpFill.material.color.set(pct > 0.6 ? '#25d98a' : pct > 0.3 ? '#ffcf3f' : '#e3453a');
    this.hpFill.visible = pct > 0 && !this.dead;
    this.hpBg.visible = !this.dead;
  }

  hitFlash(strength = 0.16) {
    this.flashT = Math.max(this.flashT, strength);
  }

  playAttack(kind = 'light') {
    this.attackT = 0;
    this.attackKind = kind;
  }

  setBlocking(on) {
    this.blocking = !!on;
    this.shield.visible = this.blocking && !this.dead;
  }

  setVisible(v) {
    this.group.visible = v;
  }

  setDead(dead) {
    this.dead = !!dead;
    this.deadT = 0;
    this.setBlocking(false);
    this.shield.visible = false;
    this.label.visible = !dead;
    this.hpBg.visible = !dead;
    this.hpFill.visible = !dead;
    this.group.visible = !dead;
    if (!dead) {
      this.body.rotation.set(0, 0, 0);
      this.body.position.set(0, 0, 0);
      this.deadT = 0;
    }
  }

  /**
   * @param {number} dt
   * @param {{speed:number, onGround:boolean, vy:number, blocking?:boolean}} state
   */
  update(dt, state = {}) {
    const speed = state.speed || 0;
    const onGround = state.onGround !== false;

    // flash saat kena hit
    if (this.flashT > 0) {
      this.flashT = Math.max(0, this.flashT - dt);
      const k = this.flashT > 0 ? 0.55 : 0;
      for (const m of this.materials) {
        m.emissive?.setRGB(k, k * 0.25, k * 0.25);
      }
    } else {
      for (const m of this.materials) {
        if (m.emissive && (m.emissive.r || m.emissive.g || m.emissive.b)) m.emissive.setRGB(0, 0, 0);
      }
    }

    // mati: jatuh ke samping lalu menghilang
    if (this.dead) {
      this.deadT += dt;
      const k = Math.min(1, this.deadT / 0.55);
      this.body.rotation.z = k * (Math.PI / 2) * 0.92;
      this.body.position.y = -Math.min(0.6, this.deadT * 0.9);
      this.body.rotation.x = k * 0.18;
      this.group.visible = this.deadT < 3.2;
      return;
    }

    // fase jalan
    const moving = speed > 0.4 && onGround;
    this.animSpeed += ((moving ? Math.min(1, speed / 16) : 0) - this.animSpeed) * Math.min(1, dt * 10);
    if (onGround) this.phase += dt * (6.2 + this.animSpeed * 5.2) * (moving ? 1 : 0.16);

    const swing = Math.sin(this.phase) * 0.85 * this.animSpeed;
    const swing2 = Math.cos(this.phase) * 0.85 * this.animSpeed;

    if (this.blocking) {
      this.armLPivot.rotation.x = -1.35;
      this.armLPivot.rotation.z = 0.5;
      this.armRPivot.rotation.x = -1.35;
      this.armRPivot.rotation.z = -0.5;
    } else {
      this.armLPivot.rotation.x = -swing;
      this.armRPivot.rotation.x = swing;
      this.armLPivot.rotation.z = 0.06;
      this.armRPivot.rotation.z = -0.06;
    }

    this.legLPivot.rotation.x = swing;
    this.legRPivot.rotation.x = -swing;

    // lompat / jatuh
    if (!onGround) {
      const rising = (state.vy || 0) > 0;
      this.legLPivot.rotation.x = rising ? -0.55 : 0.35;
      this.legRPivot.rotation.x = rising ? 0.35 : -0.3;
      this.armLPivot.rotation.x = rising ? -1.9 : -0.7;
      this.armRPivot.rotation.x = rising ? -1.9 : -0.7;
    }

    // idle breathing
    this.torso.position.y = 3 + Math.sin(this.phase * 0.8) * 0.02 * (1 - this.animSpeed);
    this.headPivot.rotation.z = swing2 * 0.03;

    // animasi serangan menimpa lengan kanan
    if (this.attackT >= 0) {
      this.attackT += dt;
      const heavy = this.attackKind === 'heavy';
      const dur = heavy ? 0.62 : 0.34;
      const t = Math.min(1, this.attackT / dur);
      // windup -> strike -> recover
      const strike = t < 0.34 ? -1.5 * (t / 0.34) : -1.5 + 3.1 * ((t - 0.34) / 0.66);
      this.armRPivot.rotation.x = heavy ? strike * 0.85 - 0.25 : strike;
      this.armRPivot.rotation.z = -0.35 * Math.sin(t * Math.PI);
      this.headPivot.rotation.y = heavy ? -0.25 * Math.sin(t * Math.PI) : 0.16 * Math.sin(t * Math.PI);
      this.torso.rotation.y = (heavy ? -0.35 : -0.2) * Math.sin(t * Math.PI);
      if (t >= 1) {
        this.attackT = -1;
        this.torso.rotation.y = 0;
        this.headPivot.rotation.y = 0;
      }
    } else {
      this.headPivot.rotation.y *= 0.9;
      this.torso.rotation.y *= 0.9;
    }

    // shield pulse
    if (this.shield.visible) {
      const s = 1 + Math.sin(performance.now() * 0.012) * 0.03;
      this.shield.scale.setScalar(s);
    }
  }

  setLabel(text, color) {
    this.name = text;
    if (this.labelTex) this.labelTex.dispose();
    this.labelTex = null;
    this.labelTex = makeLabelTexture(text, color || (this.isPlayer ? '#8ff7c2' : '#ffffff'));
    this.label.material.map = this.labelTex;
    this.label.material.needsUpdate = true;
  }

  dispose() {
    this.group.traverse((o) => {
      if (o.isMesh || o.isSprite) {
        o.geometry?.dispose?.();
        if (Array.isArray(o.material)) o.material.forEach((m) => m.dispose());
        else o.material?.dispose?.();
      }
    });
    this.labelTex?.dispose?.();
  }
}

/** Pilih warna acak dari palet. */
export function randomLook(palette) {
  const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
  return {
    skin: pick(palette.skin),
    shirt: pick(palette.shirt),
    pants: pick(palette.pants),
    hair: pick(palette.hair),
  };
}

/* =========================================================================
   scene.js — renderer, langit, pencahayaan, dan kamera third-person.
   ========================================================================= */

import * as THREE from 'three';
import { CAMERA } from './config.js';

const SKY_VERT = `
varying vec3 vWorld;
void main() {
  vWorld = (modelMatrix * vec4(position, 1.0)).xyz;
  gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);
}`;

const SKY_FRAG = `
uniform vec3 topColor;
uniform vec3 bottomColor;
uniform vec3 sunColor;
uniform vec3 sunDir;
varying vec3 vWorld;
void main() {
  vec3 dir = normalize(vWorld);
  float h = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
  vec3 col = mix(bottomColor, topColor, pow(h, 0.75));
  float sun = pow(max(dot(dir, normalize(sunDir)), 0.0), 22.0);
  col += sunColor * sun * 0.55;
  gl_FragColor = vec4(col, 1.0);
}`;

export class World {
  constructor(canvas) {
    this.canvas = canvas;
    this.quality = 'high';
    this.shakeAmount = 0;
    this.shakeEnabled = true;
    this.tmpVec = new THREE.Vector3();

    this.renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      powerPreference: 'high-performance',
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.05;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color('#8ec9e8');
    this.scene.fog = new THREE.Fog('#a9d4e8', 130, 420);

    this.camera = new THREE.PerspectiveCamera(CAMERA.fov, 1, 0.2, 1400);

    /* ------------------------------ langit ------------------------------ */
    this.skyUniforms = {
      topColor: { value: new THREE.Color('#3f7fbf') },
      bottomColor: { value: new THREE.Color('#cfe7f5') },
      sunColor: { value: new THREE.Color('#ffe9b0') },
      sunDir: { value: new THREE.Vector3(0.4, 0.62, 0.35).normalize() },
    };
    const skyGeo = new THREE.SphereGeometry(900, 32, 16);
    const skyMat = new THREE.ShaderMaterial({
      uniforms: this.skyUniforms,
      vertexShader: SKY_VERT,
      fragmentShader: SKY_FRAG,
      side: THREE.BackSide,
      depthWrite: false,
      fog: false,
    });
    this.sky = new THREE.Mesh(skyGeo, skyMat);
    this.sky.frustumCulled = false;
    this.scene.add(this.sky);

    /* ---------------------------- pencahayaan ---------------------------- */
    this.hemi = new THREE.HemisphereLight('#dff2ff', '#5c5b4f', 0.85);
    this.scene.add(this.hemi);

    this.sun = new THREE.DirectionalLight('#fff4dc', 2.1);
    this.sun.position.set(60, 110, 40);
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(2048, 2048);
    this.sun.shadow.camera.near = 1;
    this.sun.shadow.camera.far = 400;
    this.sun.shadow.camera.left = -90;
    this.sun.shadow.camera.right = 90;
    this.sun.shadow.camera.top = 90;
    this.sun.shadow.camera.bottom = -90;
    this.sun.shadow.bias = -0.0006;
    this.sun.shadow.normalBias = 0.4;
    this.scene.add(this.sun);
    this.sunTarget = new THREE.Object3D();
    this.scene.add(this.sunTarget);
    this.sun.target = this.sunTarget;

    this.ambient = new THREE.AmbientLight('#ffffff', 0.25);
    this.scene.add(this.ambient);

    /* ------------------------------ kamera ------------------------------ */
    this.camYaw = Math.PI;
    this.camPitch = -0.18;
    this.camDist = CAMERA.distance;
    this.camPos = new THREE.Vector3(0, 20, 30);
    this.camLook = new THREE.Vector3();
    this.smoothLook = new THREE.Vector3(0, 4, 0);
    this.camShake = new THREE.Vector3();

    this.resize();
    window.addEventListener('resize', () => this.resize());
  }

  resize() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / Math.max(1, h);
    this.camera.updateProjectionMatrix();
  }

  setQuality(q) {
    this.quality = q;
    const ratio = q === 'low' ? 0.75 : q === 'medium' ? 1 : Math.min(window.devicePixelRatio || 1, 2);
    this.renderer.setPixelRatio(ratio);
    this.renderer.shadowMap.enabled = q !== 'low';
    this.sun.castShadow = q !== 'low';
    this.sun.shadow.mapSize.set(q === 'high' ? 2048 : 1024, q === 'high' ? 2048 : 1024);
    if (this.sun.shadow.map) {
      this.sun.shadow.map.dispose();
      this.sun.shadow.map = null;
    }
    this.resize();
  }

  setFov(fov) {
    this.camera.fov = fov;
    this.camera.updateProjectionMatrix();
  }

  applyTheme(theme) {
    if (!theme) return;
    if (theme.skyTop) this.skyUniforms.topColor.value.set(theme.skyTop);
    if (theme.skyBottom) this.skyUniforms.bottomColor.value.set(theme.skyBottom);
    if (theme.fog) {
      this.scene.fog.color.set(theme.fog);
      this.scene.background.set(theme.fog);
    }
    if (theme.hemi) this.hemi.color.set(theme.hemi);
    if (theme.hemiGround) this.hemi.groundColor.set(theme.hemiGround);
    if (theme.sun) this.sun.color.set(theme.sun);
    if (theme.sunIntensity !== undefined) this.sun.intensity = theme.sunIntensity;
    if (theme.fogNear !== undefined) this.scene.fog.near = theme.fogNear;
    if (theme.fogFar !== undefined) this.scene.fog.far = theme.fogFar;
  }

  shake(amount) {
    if (!this.shakeEnabled) return;
    this.shakeAmount = Math.min(1.4, this.shakeAmount + amount);
  }

  /**
   * Update kamera orbit dengan smoothing.
   * @param {THREE.Vector3} target posisi kaki karakter
   */
  updateCamera(target, dt) {
    const look = this.tmpVec.set(target.x, target.y + CAMERA.targetHeight, target.z);
    const k = 1 - Math.exp(-CAMERA.lerp * dt);
    this.smoothLook.lerp(look, k);

    const cp = Math.cos(this.camPitch);
    const offset = new THREE.Vector3(
      Math.sin(this.camYaw) * cp * this.camDist,
      Math.sin(-this.camPitch) * this.camDist + 1.2,
      Math.cos(this.camYaw) * cp * this.camDist
    );

    const desired = look.clone().add(offset);
    // jangan sampai kamera menembus lantai
    if (desired.y < look.y - 3.2) desired.y = look.y - 3.2;
    if (desired.y < 1.2) desired.y = 1.2;

    this.camPos.lerp(desired, k);

    // screen shake
    this.shakeAmount = Math.max(0, this.shakeAmount - dt * 2.6);
    const s = this.shakeAmount * this.shakeAmount;
    this.camShake.set(
      (Math.random() - 0.5) * s * 1.6,
      (Math.random() - 0.5) * s * 1.6,
      (Math.random() - 0.5) * s * 1.6
    );

    this.camera.position.copy(this.camPos).add(this.camShake);
    this.camera.lookAt(this.smoothLook);

    // langit & matahari ikut kamera
    this.sky.position.copy(this.camera.position);
    this.sun.position.set(
      this.camera.position.x + 60,
      130,
      this.camera.position.z + 40
    );
    this.sunTarget.position.set(this.camera.position.x, 0, this.camera.position.z);
  }

  render() {
    this.renderer.render(this.scene, this.camera);
  }
}

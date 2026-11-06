/* =========================================================================
   config.js — konstanta, data shop, nama bot, palet warna.
   Semua angka memakai "stud" (1 unit = 1 stud Roblox) supaya feel-nya sama.
   ========================================================================= */

export const SAVE_KEY = 'broken.webport.save.v2';

/** Fisika & gerak — mengikuti default Roblox (WalkSpeed 16, JumpPower 50). */
export const PHYS = {
  gravity: 196.2,        // studs/s^2 (default Roblox)
  walkSpeed: 16,
  sprintSpeed: 24,
  jumpPower: 50,
  airControl: 0.55,
  friction: 10,
  stepHeight: 1.1,       // bisa naik tangga/pijakan rendah
  radius: 1.35,          // radius tabrakan karakter (studs)
  height: 5.2,           // tinggi total karakter R6 klasik
  coyoteTime: 0.12,
  jumpBuffer: 0.13,
  terminalVelocity: 190,
};

/** Kamera third-person ala Roblox. */
export const CAMERA = {
  distance: 13.5,
  minDistance: 6,
  maxDistance: 24,
  targetHeight: 4.2,
  pitchMin: -1.15,
  pitchMax: 0.95,
  fov: 70,
  lerp: 14,
};

/** Combat tuning — mengacu ke CombatHandler/SwordScript di file .rbxl repo. */
export const COMBAT = {
  light: { damage: 7, range: 6.4, arc: 1.15, cooldown: 0.42, windup: 0.09, active: 0.14, knockback: 9 },
  combo: [
    { damage: 6, range: 6.2, cooldown: 0.34, knockback: 7 },
    { damage: 7, range: 6.4, cooldown: 0.34, knockback: 8 },
    { damage: 13, range: 7.0, cooldown: 0.62, knockback: 20, crit: true },
  ],
  comboWindow: 0.85,
  heavy: { damage: 23, range: 7.4, arc: 0.95, cooldown: 1.15, windup: 0.34, active: 0.18, knockback: 26, crit: true },
  blockReduction: 0.82,
  blockSpeed: 6,
  dash: { speed: 46, duration: 0.18, cooldown: 1.5, iframes: 0.26 },
  stamina: { max: 100, sprintDrain: 22, regen: 26, dashCost: 18, heavyCost: 12 },
  respawnTime: 4,
  hitInvuln: 0.18,
};

/** Item shop. level maksimum & efek per level. */
export const SHOP = [
  {
    id: 'sword', name: 'Katana', tag: 'Weapon',
    color: '#cfd8e3',
    desc: 'Senjata ringan. Menambah damage serangan ringan dan membuka animasi slash.',
    prices: [45, 110, 220], maxLevel: 3,
    effect: '+18% damage ringan / level',
  },
  {
    id: 'axe', name: 'Battle Axe', tag: 'Weapon',
    color: '#b06a3b',
    desc: 'Berat tapi brutal. Menambah damage & knockback serangan berat.',
    prices: [60, 140, 260], maxLevel: 3,
    effect: '+22% heavy damage & knockback / level',
  },
  {
    id: 'speed', name: 'Speed Coil', tag: 'Gear',
    color: '#2f9bff',
    desc: 'Coil klasik Roblox. Menaikkan kecepatan lari.',
    prices: [55, 130, 240], maxLevel: 3,
    effect: '+2 WalkSpeed / level',
  },
  {
    id: 'health', name: 'Health Coil', tag: 'Gear',
    color: '#00b06f',
    desc: 'Menambah max HP dan langsung menyembuhkan saat dibeli.',
    prices: [50, 120, 230], maxLevel: 3,
    effect: '+20 MaxHealth / level',
  },
  {
    id: 'armor', name: 'Armor Vest', tag: 'Defense',
    color: '#7d8894',
    desc: 'Mengurangi damage yang masuk. Berguna saat dikeroyok bot.',
    prices: [70, 160, 300], maxLevel: 3,
    effect: '-9% damage diterima / level',
  },
  {
    id: 'dash', name: 'Dash Module', tag: 'Utility',
    color: '#9b6bff',
    desc: 'Mempercepat cooldown dash dan menambah jarak dash.',
    prices: [40, 95, 190], maxLevel: 3,
    effect: '-14% cooldown dash / level',
  },
  {
    id: 'vampire', name: 'Vampire Fang', tag: 'Utility',
    color: '#e3453a',
    desc: 'Menyerap HP sedikit setiap kali berhasil memukul.',
    prices: [65, 150, 280], maxLevel: 3,
    effect: '+1.6 HP per hit / level',
  },
  {
    id: 'sprint', name: 'Trail Runner', tag: 'Utility',
    color: '#ffcf3f',
    desc: 'Stamina lebih besar dan regen lebih cepat.',
    prices: [45, 105, 200], maxLevel: 3,
    effect: '+25 stamina & regen / level',
  },
];

/** Palet warna ala Roblox untuk karakter & bot. */
export const PALETTE = {
  skin: ['#f1c9a5', '#d8a06a', '#a9714a', '#6d4a33', '#ffe0bd', '#c98b62'],
  shirt: ['#e3453a', '#2f9bff', '#00b06f', '#ffcf3f', '#9b6bff', '#ff8b3d', '#22c3d6', '#e0e6ed'],
  pants: ['#2b3a55', '#3c3c46', '#5a4632', '#1f2a37', '#42536b', '#26313f'],
  hair: ['#2b1d16', '#5a3a22', '#111318', '#c8a04b', '#7d8894', '#8f2f1f'],
};

export const BOT_NAMES = [
  'Builderman', 'NoobSlayer99', 'xX_ShadowBlade_Xx', 'Guest 1337', 'BaconHairBoy',
  'TixHunter', 'DominusKing', 'OofMaster2', 'Bloxxer_77', 'SlenderN00b',
  'PixelPuncher', 'Robloxian_1138', 'DarkEdge', 'ShedletskyFan', 'MrObby',
  'CoolCat_2016', 'SwordGuy', 'LavaWalker', 'IceCola', 'TheRealNoob',
];

export const CHAT_LINES = {
  kill: [
    'ez', 'gg', 'noob', 'get rekt', '1v1 me', 'that was close', 'lol', 'nice try',
    'skill issue', 'i lag', 'lag switch!!', 'ur bad', 'ez clap', 'combo go brrr',
  ],
  death: ['oof', 'lag', 'hacker', 'i was afk', 'bruh', 'my hands were cold', 'respawn pls'],
  idle: ['who wants to 1v1', 'shop first', 'this map is cool', 'anyone have coins?', 'join my group'],
  taunt: ['come here', 'you scared?', 'fight me'],
};

export const MAP_ROTATION_HINT = ['Brick Arena', 'Neon Grid', 'Sky Islands', 'Lava Foundry'];

export const DEFAULT_SETTINGS = {
  sensitivity: 1,
  volume: 0.6,
  fov: 70,
  quality: 'high',
  shake: true,
  music: false,
  forceMobile: false,
  name: '',
};

export const ROUND = {
  intermission: 20,
  duration: 120,
  results: 9,
  killCoins: 14,
  assistCoins: 4,
  winCoins: 60,
  joinCoins: 20,
  maxKillstreakBonus: 4,
};

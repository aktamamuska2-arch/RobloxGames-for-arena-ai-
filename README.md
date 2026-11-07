# BROKEN. — Web Port (eksperimen)

Port **browser** dari game Roblox *BROKEN.* yang ada di repo ini (file `BrokenPVPgame_20240713_01.rbxl`).
Dibuat sebagai eksperimen: **seberapa mirip game Roblox bisa direplikasi di HTML/WebGL tanpa Roblox Studio, tanpa Roblox Player, dan tanpa aset Roblox.**

> Fan project / riset pribadi. Bukan produk resmi Roblox, bukan afiliasi Roblox Corporation.
> Game aslinya milik **Dewan Mukto (D'MUKTO)** dan tersedia open source di repo ini (lihat bagian bawah).

```
buka terminal:
  node server.js          →  http://localhost:8080
  # atau tanpa Node:
  python3 -m http.server 8080 --directory web
```

Lalu mainkan di browser (Chrome/Edge/Firefox/Safari terbaru). Klik **PLAY**.

---

## 1. Apa yang dibuat

| Aspek | Roblox asli | Web port ini |
|---|---|---|
| Engine | Roblox Client (proprietary) | **Three.js / WebGL2** |
| Bahasa | Luau | JavaScript (ES modules, tanpa build step) |
| Karakter | R6/R15 + mesh & animasi Roblox | rig blocky R6 buatan sendiri (6 part + kepala + wajah) |
| Fisika | Humanoid + solver Roblox | fisika karakter sendiri (AABB, step-up, coyote jump) |
| UI | CoreGui + ScreenGui | HTML/CSS: topbar, chat, leaderboard, health bar, shop |
| Suara | `rbxassetid://` | **disintesis WebAudio** (tidak ada aset Roblox) |
| Server | Roblox server + RemoteEvents | simulasi lokal (player + 7 bot AI) |
| Map | `.rbxl` | 4 arena dibangun prosedural, dipilih acak per round |

Yang **ditiru langsung** dari file `.rbxl` di repo (lihat `docs/02-riset-file-rbxl.md`):
- struktur fitur *BROKEN.* sesuai deskripsi repo: **action PvP arena, map randomizer, round timer, shop, menu, NPC**
- pola combat dari `CombatHandler` (Bangla Battlegrounds) & `ChopperSword` (Demon Hunting):
  light/heavy attack, cooldown, progress bar cooldown, knockback, hit sound
- pola dialog NPC (ProximityPrompt + GUI pilihan) diubah jadi chat/toast bot
- gaya UI in-experience Roblox (panel gelap translucent, aksen hijau, health bar, leaderboard)

---

## 2. Cara menjalankan

### Opsi A — server bawaan (disarankan)
```bash
node server.js
# http://localhost:8080
```
Port bisa diganti: `PORT=3000 node server.js`. Server bind ke `0.0.0.0` supaya bisa dibuka dari
perangkat lain di jaringan yang sama (mis. HP): buka `http://IP-KOMPUTER:8080`.

### Opsi B — tanpa Node
```bash
python3 -m http.server 8080 --directory web
```

### Opsi C — server statis apa pun
Arahkan document root ke folder `web/`. **Jangan** buka `web/index.html` lewat `file://`
(karena memakai ES module + import map, browser akan memblokirnya).

Tidak ada `npm install` yang dibutuhkan untuk **memainkan** game — Three.js sudah
di-vendor di `web/vendor/three.module.js`. `node_modules` hanya dipakai untuk menjalankan tes.

---

## 3. Kontrol

| Tombol | Aksi |
|---|---|
| `W A S D` / panah | bergerak (relatif kamera) |
| Mouse | melihat sekeliling (pointer lock; karakter menghadap kamera) — kalau lock diblokir, **seret mouse** untuk memutar kamera |
| Klik kiri | serangan ringan — **combo 3x** (hit ke-3 crit + knockback besar) |
| Klik kanan | serangan berat (lebih lambat, damage & knockback besar) |
| `Q` | dash + i-frame singkat (0.26 s kebal) |
| `F` (tahan) | block — menahan ~82% damage |
| `Space` | lompat |
| `Shift` | sprint (menguras stamina) |
| Scroll | zoom kamera |
| `B` | shop |
| `Tab` | leaderboard |
| `Enter` / `/` | chat |
| `Esc` | pause / tutup overlay |
| `M` | musik on/off |
| Mobile | joystick kiri, tombol ATK/HVY/JUMP/DASH/BLK |

> **Mode fallback (iframe / pointer lock diblokir):** tahan-geser mouse untuk memutar
> kamera, lalu klik singkat (tanpa geser) untuk menyerang. Hint otomatis muncul di
> tengah layar saat lock tidak aktif.

Chat command: `/help`, `/heal`, `/coins`, `/map [nama]`, `/kill`, `/stats`, `/resetgear`, `/music`, `/clear`.

---

## 4. Fitur

**Gameplay**
- Free-for-all: 1 player + 7 bot dengan 4 kepribadian AI (agresif, seimbang, defensif, liar),
  nama ala Roblox, respawn otomatis, dan **obrolan bot memakai Markov chain**
  (bot tidak membalas siapa pun; mereka mengoceh acak sambil menyerap kosakata
  yang kamu ketik di chat).
- Sistem round: **intermission 20 s → round 120 s → hasil**, map diacak setiap round dari 4 arena.
- 4 arena: *Brick Arena*, *Neon Grid*, *Sky Islands* (bisa jatuh ke void), *Lava Foundry* (zona lava).
- Combat: combo, heavy, block, dash i-frame, stamina, knockback, lifesteal, crit, damage number,
  hit flash, particle burst, screen shake, cooldown bar, killstreak.
- Koin & shop: 8 item × 3 level (Katana, Battle Axe, Speed Coil, Health Coil, Armor Vest,
  Dash Module, Vampire Fang, Trail Runner). Progres disimpan di `localStorage`.
- Leaderboard KO/death, hasil round + hadiah koin, statistik total di menu.

**Presentasi**
- Avatar R6 blocky dengan wajah klasik Roblox, nametag + health bar di atas kepala.
- Tekstur **prosedural** (stud, bata, ubin, neon, logam, lava, rumput) — dibuat di canvas, bukan aset.
- Langit shader gradasi + matahari, fog per tema map, shadow map.
- UI Roblox-style (topbar, chat bubble, panel translucent), toast notifikasi, vignette saat kena hit.
- **Bot belajar bicara**: setiap pesan pemain di chat masuk ke rantai Markov; bot
  menghasilkan kalimat acak dari rantai itu (`web/js/markov.js`), bukan balasan bertarget.
- SFX & musik disintesis WebAudio (swing, hit, heavy, block, jump, dash, koin, UI, round, death).

**Teknis**
- Tanpa framework & tanpa bundler: HTML + CSS + ES modules.
- Fisika & tabrakan sendiri (tanpa cannon/rapier), deterministik dan ringan.
- 16 modul JS terpisah, ±4.600 baris; server dev tanpa dependency.
- 3 lapis tes: cek sintaks, smoke test logika (map/combat/fisika/AI/player), tes UI dengan jsdom.

---

## 5. Struktur repo

```
.
├── web/                        # GAME (yang dibuka browser)
│   ├── index.html              # shell UI + import map
│   ├── css/ui.css              # seluruh styling HUD/menu/shop
│   ├── js/
│   │   ├── main.js             # bootstrap + state machine round
│   │   ├── scene.js            # renderer, langit, lampu, kamera 3rd-person
│   │   ├── maps.js             # 4 arena + collider + spawn + zona bahaya
│   │   ├── avatar.js           # karakter R6 blocky + animasi + nametag
│   │   ├── entities.js         # Fighter (base player & bot)
│   │   ├── player.js           # input, gerak, jump, dash, block, serangan
│   │   ├── bots.js             # AI bot
│   │   ├── combat.js           # hitbox, damage, knockback, kill, VFX
│   │   ├── physics.js          # AABB collision, gravitasi, step-up
│   │   ├── input.js            # keyboard/mouse/pointer-lock/touch
│   │   ├── markov.js           # generator obrolan bot (Markov chain)
│   │   ├── ui.js               # HUD, chat, shop, leaderboard, menu
│   │   ├── audio.js            # sintesis SFX + musik
│   │   ├── textures.js         # tekstur procedural
│   │   ├── config.js           # tuning, item shop, nama bot
│   │   └── store.js            # save/load localStorage + stat gear
│   └── vendor/three.module.js  # Three.js 0.169 (MIT)
├── server.js                   # dev server statis (http bawaan Node)
├── scripts/                    # tes & tooling
│   ├── check-syntax.js
│   ├── smoke-test.mjs
│   ├── ui-test.mjs
│   └── vendor-link.mjs
├── tools/rbxl_inspect.py       # parser .rbxl (riset, lihat docs/02)
├── research/                   # script Luau hasil ekstraksi dari .rbxl (referensi)
├── docs/                       # catatan lengkap proyek
└── *.rbxl                      # file game Roblox asli (tidak diubah)
```

---

## 6. Tes

```bash
npm install          # sekali saja: jsdom (untuk tes UI + simulasi browser)
npm test             # jalankan keempat lapis tes

# atau satu per satu
node scripts/check-syntax.js      # cek sintaks 16 modul
node scripts/smoke-test.mjs       # map, combat, fisika, AI, player (headless)
node scripts/ui-test.mjs          # UI + wiring tombol (jsdom)
node scripts/browser-sim.mjs      # GAME UTUH di jsdom + WebGL palsu (90 asersi)
```

`browser-sim.mjs` memuat `index.html` dan `main.js` yang sebenarnya lalu memainkan
empat round: boot → PLAY → gerak/lompat/serang → kamera → mati & respawn → shop &
refund → pause → hasil round → markov/chat → kembali ke menu → main lagi, sambil
memeriksa NaN, kebocoran objek di scene, ukuran nameplate, dan error JS. **Inilah yang menangkap bug integrasi** yang tidak
terlihat dari tes per modul.

Semua tes berjalan tanpa browser dan tanpa GPU.

---

## 7. Batasan & catatan penting

- **Bukan multiplayer sungguhan.** Lawan adalah bot. Menambah multiplayer butuh
  server otoritatif + WebSocket (lihat roadmap di `docs/04-catatan-pengembangan.md`).
- **Tidak memakai satu pun aset Roblox** (mesh, animasi, audio, font, ikon). Semuanya
  dibuat ulang secara prosedural agar proyek legal dan bisa jalan offline.
- Map di sini adalah **reinterpretasi**, bukan import geometri dari `.rbxl`.
  Parser `.rbxl` sudah membaca **hierarki instance, nama, kelas, dan seluruh source Luau**
  (328 script, ±1,5 juta karakter diekstrak ke `research/`), tetapi properti
  `CFrame`/`Vector3` belum didekode sehingga geometri map asli belum bisa diimpor
  (detail + analisis di `docs/02-riset-file-rbxl.md`, rencana di roadmap).
- UI meniru *rasa* Roblox, bukan pixel-perfect CoreGui.
- Performa terbaik di desktop; mobile berjalan tetapi tombolnya masih kasar.
- **Status verifikasi:** `npm test` menjalankan 4 lapis tes, termasuk simulasi game
  utuh (90 asersi: boot → 4 round → shop → kamera → chat Markov → menu → main lagi). Hasil render
  WebGL yang sebenarnya tetap harus dilihat di browser — simulasi memakai WebGL palsu.
- Riwayat bug yang ditemukan saat audit v1.1.0 (20 item) ada di
  `docs/04-catatan-pengembangan.md` §1.

---

## 8. Dokumentasi lanjutan

- [`docs/01-desain-game.md`](docs/01-desain-game.md) — spesifikasi gameplay, angka balancing, ekonomi koin.
- [`docs/02-riset-file-rbxl.md`](docs/02-riset-file-rbxl.md) — anatomi `.rbxl`, parser, temuan script asli.
- [`docs/03-arsitektur.md`](docs/03-arsitektur.md) — arsitektur kode, game loop, fisika, strategi performa.
- [`docs/04-catatan-pengembangan.md`](docs/04-catatan-pengembangan.md) — changelog, roadmap, known issues.

---

## 9. Game Roblox asli di repo ini

Backup beberapa game Roblox milik [D'MUKTO](https://www.roblox.com/groups/17296061/D-MUKTO#!/about),
di-open-source-kan. Buka `.rbxl` dengan Roblox Studio, atau bebas mengimpor script/model/UI-nya.

- [Broken.](https://www.roblox.com/games/18129807606/Broken) — action PvP combat arena dengan map
  randomizer, round timer, shop, menu, NPCs. **Ini yang di-port.**
- [Demon Hunting Paradise](https://www.roblox.com/games/18375390394/Demon-Hunting-Paradise)
- [Bangla Battlegrounds](https://www.roblox.com/games/18321177918/Bangla-Battlegrounds)
- [Photon.](https://www.roblox.com/games/18305682277/Photon)
- [Save Her](https://www.roblox.com/games/18535230648/Save-Her)

Lisensi repo asli: **MIT** © 2024 Dewan Mukto (`LICENSE`).
Kode web port ini mengikuti lisensi yang sama. Three.js © three.js authors (MIT).

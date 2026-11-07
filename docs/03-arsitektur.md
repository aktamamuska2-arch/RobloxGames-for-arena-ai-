# 03 · Arsitektur Kode

Ringkasan teknis: bagaimana game ini disusun, urutan update tiap frame, dan
di mana harus menyentuh kode kalau ingin menambah fitur.

Prinsip yang dipegang:

1. **Tanpa build step** — HTML + ES modules + import map. Buka lewat server statis, jalan.
2. **Tanpa dependency runtime** — Three.js di-vendor (`web/vendor/`), server memakai
   modul `http` bawaan Node, audio & tekstur dibuat sendiri.
3. **Modul kecil & bertanggung jawab tunggal** — 15 file, masing-masing < 600 baris.
4. **Bisa dites tanpa GPU** — logika dipisah dari renderer.

---

## 1. Peta modul

```
index.html
  └── js/main.js ────────────── Game: bootstrap, state round, chat command, loop
        ├── scene.js ────────── World: renderer, sky, light, camera rig, shake
        ├── maps.js ─────────── Arena: 4 map prosedural + collider/danger/spawn
        │     └── textures.js ─ tekstur canvas (stud, bata, neon, lava, …)
        ├── entities.js ────── Fighter: base class player & bot + Avatar
        │     └── avatar.js ── rig R6, animasi, nametag, health bar, senjata
        ├── player.js ──────── Player extends Fighter (input, kamera, gerak)
        ├── bots.js ────────── Bot extends Fighter (AI)
        ├── combat.js ──────── hitbox, damage, block, knockback, kill, VFX
        ├── physics.js ─────── AABB collision, gravitasi, step-up, danger zone
        ├── input.js ───────── keyboard, mouse/pointer-lock, wheel, touch
        ├── ui.js ──────────── HUD, chat, shop, leaderboard, menu, toast
        ├── audio.js ───────── sintesis SFX + musik (WebAudio)
        ├── store.js ───────── localStorage save + stat turunan gear
        └── config.js ──────── semua tuning & data (SHOP, BOT_NAMES, …)
```

Arah dependensi selalu "ke bawah": `config` tidak mengimpor apa pun, `combat` tahu
tentang entitas tapi tidak tentang UI (memakai `game.ui?.…` opsional), `main`
merangkai semuanya.

---

## 2. Urutan boot

```
Game constructor
  Store.load()                     # baca localStorage (fallback default)
  new World(canvas)                # renderer, sky, lights, camera
  new Input(canvas); attach()      # listener global
  new UI(game)                     # cache DOM, bangun shop, bind tombol
  applySettings()                  # volume, fov, quality, music
  bindGlobalKeys(); bindWindow()
  loadArena(random, silent=true)   # arena sudah tampil di belakang menu
  spawnEntities(silent=true)       # player + 7 bot
  hide loading → show menu
  requestAnimationFrame(loop)
```

klik **PLAY** → `Game.start()`:

```
state = 'playing'
ui.hideAllScreens(); ui.show('hud')
startIntermission(first=true)
  phase = 'intermission', phaseT = 20
  loadArena(random)              # map baru + toast
  resetRoundStats()              # KO/death round di-nol-kan
  respawn semua entity
input.requestLock()
```

---

## 3. Game loop

Satu frame (`Game.update(dt)`, `dt` di-clamp maksimum 50 ms supaya tab yang di-background
tidak "teleport"):

```
1. active = (state === 'playing' && !paused)
2. timer fase
     intermission → countdown → startRound()
     round        → countdown → endRound()
3. kalau active:
     player.update()        # input → kamera → gerak → serangan → fisika → lava/void
     bots.update()          # AI → gerak → serangan (hindari jurang) → fisika
     updateCombat()         # timeline serangan, hitbox, regen, respawn
     separateEntities(..., arena.colliders)  # anti tumpang tindih (tanpa menembus dinding)
     updateFx()             # partikel
     arena.update()         # animasi blok (spin/bob)
   kalau state 'menu': kamera sinematik mengelilingi arena
   selain itu (pause/results): dunia dibekukan, kamera tetap
4. world.updateCamera(target)  # smoothing posisi & look, shake
5. ui.update(dt)               # health bar, vignette, hit flash, banner, hitung mundur respawn
6. input.endFrame()            # reset edge-trigger (klik, dash, jump, delta mouse)
7. world.render()
```

`world.updateCamera()` dipanggil di dua tempat (blok 3 untuk pause/menu, blok 4 untuk
semua state) — blok 3 hanya untuk state non-playing.

---

## 4. State machine

### 4.1 State global

| `game.state` | `paused` | Kondisi | Input | Dunia |
|---|---|---|---|---|
| `menu` | – | layar judul | UI saja | kamera sinematik |
| `playing` | `false` | main | pointer lock, HUD | update penuh |
| `playing` | `true` | pause / shop / settings | UI saja | dibekukan |
| `playing` + fase `intermission` | `false` | jeda belanja 20 s | bebas bergerak | **tanpa damage** (`combatEnabled = false`) |
| `results` | `false` | layar hasil round | UI saja | dibekukan |

`setPaused(on, silent)` menerima mode `silent` supaya overlay (shop/settings) bisa
membuka *tanpa* menampilkan layar pause. `openOverlay(name)` menyimpan
`overlayReturnPause` sehingga menutup shop dari menu pause akan kembali ke menu pause,
sedangkan membukanya saat bermain akan langsung resume.

### 4.2 Fase round

```
intermission (20 s) ──► round (120 s) ──► results (9 s) ──► intermission …
```

- `intermission`: pemain **aman** (`game.combatEnabled = false` sehingga `tryAttack`
  selalu gagal), map baru dimuat, semua karakter respawn dengan 1.5 s kebal.
- `round`: combat aktif; saat mulai semua respawn di titik acak dan skala bot
  dihitung ulang (`lightMul = 1 + (round−1)·0.045`).
- `results`: `endRound()` menghitung klasemen, memberi koin (join + menang + KO +
  assist), menampilkan tabel, lalu menunggu tombol **Lanjut**. Di state ini
  `setPaused`/`togglePause`/`Esc` sengaja diabaikan supaya layar hasil tidak bisa
  tertutup dan membuat game berhenti tanpa jalan keluar.

---

## 5. Fisika (`physics.js`)

Bukan engine fisik penuh — hanya yang dibutuhkan game ini:

- **Collider** = AABB sumbu-sumbu (`{x0,x1,y0,y1,z0,z1}`) yang dibangun bersamaan
  dengan mesh di `maps.js`. Karakter disederhanakan menjadi kotak
  (radius 1.35, tinggi 5.2).
- **Gerak per-sumbu**: coba geser X → kalau bertabrakan, cek "step-up" (naik tangga
  ≤ 1.1 stud) → kalau tetap gagal, `vel.x = 0`. Ulangi untuk Z. Ini memberi efek
  *sliding* di dinding tanpa solver.
- **Vertikal**: gravitasi 196.2, clamp `terminalVelocity`, deteksi langit-langit,
  lalu cari permukaan tertinggi di bawah kaki (`groundBelow`) untuk mendarat.
- **Pemisahan entitas** (`separateEntities(entities, dt, colliders)`): dorongan
  horizontal bila dua karakter terlalu rapat; dorongan **dibatalkan** bila hasilnya
  akan berada di dalam collider (mencegah karakter masuk ke dalam blok).
- **Zona bahaya**: array AABB ber-`dps` untuk lava; `dangerDpsAt()` dipakai player & bot.
- **Void**: `arena.killY`; jatuh melewatinya = mati (pembunuh terakhir dalam 6 s
  dihitung sebagai pembunuh).

Catatan: tidak ada collider miring/bola; semua map dibangun dari box & silinder
(silinder punya collider kotak).

---

## 6. Kamera

Third-person orbit di `scene.js`:

```
offset = (sin(yaw)·cos(pitch), −sin(pitch) + 1.2, cos(yaw)·cos(pitch)) · distance
pos    = lookTarget + offset        (di-clamp agar tidak menembus lantai)
look   = lerp(smoothLook, target + (0, 4.2, 0))   # smoothing eksponensial
```

- Yaw/pitch diatur `Player.updateCameraLook()` dari `input.mouseDX/DY × sensitivity`.
- Zoom: wheel → `camDist` 6–24.
- Pitch dibatasi −1.15 … 0.95 rad.
- Screen shake: `world.shake(n)` menumpuk amplitudo, diredam `−2.6/s`.
- **Occlusion kamera**: `world.setColliders(arena.colliders)` dipanggil setiap kali
  map dimuat. `updateCamera` mengambil 9 sampel titik dari target ke kamera dan
  memendekkan jarak kalau ada collider (minimal 3.2 stud agar tidak masuk ke tubuh
  karakter).
- Karakter **selalu menghadap arah kamera** (gaya shift-lock) agar combat mouse terasa
  natural; gerak memakai basis kamera (`cameraRelative`).

---

## 7. Combat pipeline

```
input (LMB) ─► tryAttack(fighter,'light')
                 ├─ cek alive / blocking / attackCd / stamina
                 ├─ attackSpec(): gabung COMBAT.light/combo + gear multiplier
                 ├─ fighter.attacking = {kind, t, spec, hitSet}
                 └─ avatar.playAttack() + Audio.swing()

setiap frame ─► updateCombat()
                 ├─ t += dt
                 ├─ resolveHits(): window [windup, windup+active]
                 │     uji jarak, sudut (dot ≥ cos(arc)), selisih tinggi
                 │     → applyDamage(target, dmg, attacker, {crit, knockback, dir})
                 └─ selesai → comboIndex++ (light) / reset, setWeaponForAttack()

applyDamage()
  ├─ i-frame / dash → "MISS"
  ├─ block di depan → dmg × 0.18
  ├─ gear.damageReduction
  ├─ kurangi HP, hitFlash, damage number, SFX, screen shake, partikel
  ├─ knockback (vel += dir × kb, +pop vertikal)
  ├─ lifesteal attacker
  ├─ catat pelaku di target.damagers (untuk assist)
  └─ HP ≤ 0 → killFighter()
        ├─ victim.alive=false, avatar.setDead, deaths++, respawnT=4
        ├─ attacker.kills++, streak++, koin (bonus streak)
        ├─ assist: pelaku lain dalam 6 s terakhir → +4 koin (jika pemain)
        ├─ chat "X mengalahkan Y", toast, refresh leaderboard
        └─ Store.bumpStat('kills'/'deaths') via callback game.onPlayerKill/Death
```

---

## 8. AI bot (`bots.js`)

Pemilihan target: skor `100 − jarak` (+18 kalau player, +12 kalau target lama,
+20 kalau HP target < 35%), maksimum jarak 90 stud.

State: `wander` → `chase` (jarak < 46) → `attack` (jarak < 7.2) → `retreat` (HP < 25%
dan kepribadian tidak agresif). Di `attack` bot menjaga jarak ideal 4.2–5.4 stud,
strafing melingkari target, menyerang dengan jitter reaksi, kadang block saat target
menyerang, kadang dash.

Anti-macet: deteksi "tidak berpindah padahal ingin bergerak" > 0.55 s → lompat +
pilih arah acak. Menjauhi lava dan tepi map (`size × 0.62`).

Empat kepribadian: `agresif`, `seimbang`, `defensif`, `liar` (aggression, blockChance,
dashChance, reaction, speedMul). `setTimeout` dipakai untuk melepas block setelah
260–480 ms (satu-satunya timer non-frame; dibersihkan otomatis saat bot mati karena
dicek `this.alive`).

---

## 9. UI & lapisan DOM

`#ui` menutupi layar dengan `pointer-events: none`; hanya elemen interaktif yang
menyalakan `pointer-events: auto`. Urutan z-index:

```
canvas 3D (z 0)
#ui (z 10)
  #hud (HUD, crosshair, chat, panel, toasts, damage layer)
  .screen (z 20)  menu · shop · pause · settings · howto · results · loading
#fatal (z 99)
```

Karena semua `.screen` punya z-index sama, yang **muncul terakhir di DOM** tampil di
atas. Itulah sebabnya `openOverlay()` menyembunyikan layar pause saat membuka shop.

Teknis UI yang perlu diketahui:

- `ui.refreshHealth()` dipanggil **setiap frame** (murah: 4 penulisan style).
- Leaderboard di-refresh tiap 0.6 s dan saat ada kill.
- Damage number: proyeksi `Vector3.project(camera)` → posisi px → elemen `.dmg`
  dengan animasi CSS 0.9 s, dihapus lewat `setTimeout`.
- Chat: maksimum 8 baris, fade setelah 15 s.
- Toasts: maksimum 4, auto hilang 2.6 s.

---

## 10. Save game (`store.js`)

Satu key: `broken.webport.save.v2`.

```json
{
  "version": 2,
  "coins": 120,
  "items": { "sword": 2, "speed": 1 },
  "stats": { "kills": 0, "deaths": 0, "rounds": 0, "bestStreak": 0, "wins": 0 },
  "settings": {
    "sensitivity": 1, "volume": 0.6, "fov": 70, "quality": "high",
    "shake": true, "music": false, "forceMobile": false, "name": ""
  },
  "name": "",
  "createdAt": 0
}
```

`gearStats(store)` menurunkan bonus dari level item → dipakai `Player` dan `applyGear()`
(setelah beli item, HP dipulihkan penuh sebagai hadiah).

Semua akses `localStorage` dibungkus `try/catch` (mode private / storage penuh tidak
membuat game crash).

---

## 11. Strategi tes

| Lapis | File | Cakupan | Butuh |
|---|---|---|---|
| Sintaks | `scripts/check-syntax.js` | 15 modul (salin ke `.mjs`, `node --check`) | Node |
| Logika (headless) | `scripts/smoke-test.mjs` | 4 map (collider/spawn/tanah), combat (hit/arah/block/kill/respawn), fisika (jatuh/mendarat/dinding), AI bot, player (gerak/lompat/serangan), lava, partikel | Node + stub DOM |
| UI | `scripts/ui-test.mjs` | konstruksi UI, klik PLAY, beli item, toast/chat, damage number, leaderboard, hasil round, slider settings, submit chat, **kelengkapan semua id** | Node + jsdom |
| **Game utuh** | `scripts/browser-sim.mjs` | `index.html` + `main.js` asli dengan WebGL palsu: boot, PLAY, gerak/lompat/serangan, kematian & respawn, intermission aman, shop + refund, pause, hasil round, Esc di results, 4 round berturut (kebocoran objek & NaN), kembali ke menu lalu main lagi, jarak kamera | Node + jsdom |

`browser-sim.mjs` menyediakan `getContext('webgl2')` palsu (semua panggilan GL
di-no-op-kan, `getParameter` mengembalikan nilai wajar) sehingga **seluruh jalur
render tetap dieksekusi** — cukup untuk menangkap error JS, tapi tidak untuk
memvalidasi hasil gambar.

Yang **belum** tercakup otomatis: hasil kompilasi shader, kualitas visual, audio
(WebAudio), dan interaksi pointer-lock nyata. Karena itu `main.js` memasang penangan error global
yang menampilkan layar `#fatal` berisi pesan, bukan layar putih.

`scripts/vendor-link.mjs` menyalin `web/vendor/three.module.js` ke `node_modules/three`
supaya Node bisa me-resolve bare import `three` saat tes (browser memakai import map).

---

## 12. Performa

- Target: 60 fps di laptop kelas menengah, 1280×720.
- Draw call: map ±80–130 mesh, 8 karakter × ~10 mesh, partikel < 60.
- Shadow map 2048 (high) / 1024 (medium) / mati (low); pixel ratio dibatasi 2 (high),
  1 (medium), 0.75 (low).
- Tekstur dibuat sekali dan di-cache per kombinasi `nama|repeatX|repeatY`.
- Tidak ada alokasi besar per frame kecuali beberapa `Vector3` di kamera/combat
  (masih aman; bisa di-pool kalau perlu).
- `dt` di-clamp 0.05 s; pause otomatis saat tab disembunyikan (`visibilitychange`).

---

## 13. Cara menambah fitur

**Map baru** — tambah builder di `maps.js` (pakai `a.box`, `a.cylinder`, `a.spawn`),
lalu daftarkan di `BUILDERS` dan `MAP_INFO`. Jangan lupa tema langit & `killY`.

**Item shop baru** — tambah entri di `SHOP` (`config.js`), lalu pakai field barunya di
`gearStats()` (`store.js`) dan konsumsi di `player.js`/`combat.js`.

**Kepribadian bot baru** — tambah objek di `PERSONALITIES` (`bots.js`).

**Keseimbangan combat** — semua di `COMBAT` (`config.js`); UI cooldown bar otomatis
mengikuti `spec.cooldown`. Ingat gate `game.combatEnabled` bila menambah sumber damage
baru (mis. hazard map) supaya tidak melukai pemain saat intermission.

**Command chat baru** — tambah `case` di `Game.command()` (`main.js`).

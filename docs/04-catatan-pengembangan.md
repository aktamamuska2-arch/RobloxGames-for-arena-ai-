# 04 · Catatan Pengembangan

Changelog, keputusan desain, masalah yang diketahui, dan roadmap.

---

## 1. Changelog

### v1.0.0 — 2026-11-07 (rilis pertama)

**Riset**
- Menulis `tools/rbxl_inspect.py`: parser `.rbxl` biner (LZ4, byte interleaving,
  zig-zag int, tahap akumulatif untuk referent, dekode hierarki `PRNT`).
- Memecahkan dua jebakan format: angka interleaved dan **referent akumulatif**
  (lihat `docs/02-riset-file-rbxl.md` §2.1–2.2).
- Mengekstrak **328 script / ±1,5 juta karakter** dari 5 game ke `research/`
  (beserta `tree.txt` & `summary.txt`).
- Membaca `CombatHandler`, `ChopperSword`, `CustomHealthBar`, `NotifScript`,
  `Shop`, `NPC_AI`, `MapLoader`, `SpawnPlayers` sebagai acuan mekanik & UI.

**Game**
- Game web lengkap: 4 arena acak, round 20 s / 120 s / 9 s, 1 player + 7 bot,
  free-for-all.
- Combat: combo ringan 3-hit (6/7/13), heavy 23, block 82%, dash i-frame,
  stamina, knockback, crit, lifesteal, damage number, hit flash, partikel,
  screen shake, cooldown bar.
- Avatar R6 blocky prosedural + wajah klasik + nametag & health bar 3D + 2 model senjata.
- Map: Brick Arena, Neon Grid, Sky Islands (void), Lava Foundry (lava 26 DPS),
  lengkap dengan spawn pad, collider, dan tema langit/fog.
- Shop 8 item × 3 level, koin dari KO/round, persist `localStorage`.
- HUD Roblox-style: topbar, health + stamina, round banner, leaderboard, chat +
  command, toast, hasil round, menu/pause/settings/how-to.
- Mobile: joystick virtual + 5 tombol aksi.
- Audio disintesis penuh (SFX + musik ambient opsional).
- Dev server `server.js` tanpa dependency; dokumentasi & tes.

**Tes**
- `check-syntax.js` (15 modul), `smoke-test.mjs` (map/combat/fisika/AI/player/FX),
  `ui-test.mjs` (jsdom: wiring tombol, shop, chat, hasil round, kelengkapan id).

---

## 2. Keputusan desain (dan alasannya)

| Keputusan | Alasan |
|---|---|
| **Three.js**, bukan engine penuh | ringan, stabil, satu file vendor, tanpa build |
| **Tanpa bundler / npm untuk main** | siapa pun bisa `node server.js` lalu main; mudah di-audit |
| **Map prosedural**, bukan impor `.rbxl` | 26.260 part + 5.686 MeshPart tidak realistis di browser; aset mesh/texture Roblox proprietary |
| **Bot, bukan multiplayer** | server otoritatif butuh waktu lebih; bot memberi lawan instan & offline |
| **Tanpa satu pun aset Roblox** | legal & etis; semua tekstur/audio dibuat sendiri |
| **Fisika sendiri** | kebutuhan terbatas (karakter di arena box), menghindari dependency rapier/cannon |
| **Karakter menghadap kamera** (shift-lock) | combat berbasis mouse butuh aim yang konsisten |
| **R6, bukan R15** | 6 part + 1 kepala jauh lebih murah & ikonik |
| **Semua tuning di `config.js`** | memudahkan balancing tanpa menyentuh logika |
| **Judul tetap "BROKEN."** | menghormati & mengkredit game asli; ditandai jelas sebagai fan port |

---

## 3. Masalah yang diketahui

Prioritas: 🔴 mengganggu, 🟡 terasa, 🟢 kosmetik.

1. 🔴 **Tidak ada multiplayer.** Lawan seluruhnya bot. Dua tab browser = dua dunia terpisah.
2. 🔴 **Belum bisa impor map asli.** Parser baru membaca properti string; `CFrame`/
   `Vector3`/`Color3` belum. (Roadmap #2.)
3. 🟡 **Bot tidak punya pathfinding.** Mereka mendekati target lurus; di map bertingkat
   (Sky Islands, Lava Foundry) kadang terjebak lalu lompat-lompat sampai berhasil.
4. 🟡 **Kamera menembus dinding.** Tidak ada raycast oklusi kamera; di sudut sempit
   kamera bisa masuk ke dalam pilar.
5. 🟢 **Pointer lock butuh klik.** Setelah `Esc` browser melepas lock; klik pertama di
   canvas melakukan serangan sekaligus mengunci pointer. Bila pointer lock diblokir
   (umum pada iframe), game otomatis beralih ke **drag-look**: seret untuk memutar
   kamera, klik singkat untuk menyerang.
6. 🟡 **Audio hanya setelah gesture.** Kebijakan autoplay browser; musik yang diaktifkan
   lewat settings sebelum klik pertama tidak akan berbunyi sampai ada interaksi.
7. 🟡 **Mobile belum halus.** Joystick dan area lihat berbagi canvas; kadang sentuhan
   untuk melihat ikut menggeser joystick kalau jari menyeberang.
8. 🟢 **`SSTR` belum terbaca** — tidak berdampak pada file di repo ini.
9. 🟢 **Quality setting** hanya mengubah pixel ratio & shadow, bukan jumlah mesh.
10. 🟢 **Tidak ada gamepad support.**
11. 🟢 **Timer `setTimeout` bot** untuk melepas block tidak dibatalkan saat bot di-dispose
    (aman karena dicek `this.alive`, tapi tetap kurang rapi).
12. 🟢 **Tidak ada gamepad/getaran**, tidak ada pilihan bahasa (UI campur ID/EN).

---

## 4. Roadmap

| # | Fitur | Nilai | Perkiraan usaha |
|---|---|---|---|
| 1 | **Multiplayer WebSocket** — server otoritatif ringan (Node + `ws`), room, bot mengisi slot kosong | sangat tinggi ("Roblox itu multiplayer") | besar (2–3× sesi) |
| 2 | **Importer map `.rbxl` → JSON** — dekode `CFrame`/`Vector3`/`Color3`, decimate part, ganti MeshPart dengan bounding box, opsi map "Broken Arena (asli)" | sangat tinggi (fidelity) | sedang–besar |
| 3 | Pathfinding bot (grid A* di atas collider) | tinggi (AI terasa bodoh di map bertingkat) | sedang |
| 4 | Kamera anti-tembus dinding (raycast/whisker) | sedang | kecil |
| 5 | Animasi lebih kaya (ragdoll sederhana, emote, footstep) | sedang | kecil–sedang |
| 6 | Mode tim / faksi (meniru `Script_Factions`) | sedang | sedang |
| 7 | Lebih banyak map + editor map JSON | sedang | sedang |
| 8 | Daily challenge / leaderboard lokal antar-sesi | rendah | kecil |
| 9 | Gamepad + haptic mobile | rendah | kecil |
| 10 | PWA (installable, offline) | rendah | kecil |
| 11 | i18n (ID/EN) | rendah | kecil |

Ide liar yang menarik (dicatat, belum dijadwalkan): memutar ulang input pemain
("replay" gaya Roblox recording), memakai `DamageBillboardHandler` asli sebagai
inspirasi sistem combo lanjutan (launch/air combo), dan mode spectate.

---

## 5. Cara debugging

Buka console browser:

```js
__GAME                    // objek Game utuh
__GAME.player             // Fighter pemain
__GAME.entities           // [player, ...bots]
__GAME.arena.colliders    // AABB map aktif
__GAME.state              // 'menu' | 'playing' | 'results'
__GAME.addCoins(999)      // tambah koin
__GAME.applyGear()        // terapkan ulang gear dari save
```

Command chat: `/help`, `/heal`, `/coins`, `/map [nama]`, `/kill`, `/stats`,
`/resetgear`, `/music`, `/clear`.

Tes:

```bash
node scripts/check-syntax.js
node scripts/smoke-test.mjs
npm i -D jsdom && node scripts/ui-test.mjs
```

Untuk mengosongkan progres: tombol **Reset gear** di shop (refund 75%),
atau di console: `localStorage.removeItem('broken.webport.save.v2')` lalu refresh.

---

## 6. Catatan performa yang diukur (perkiraan)

| Kondisi | Hasil |
|---|---|
| Brick Arena, 8 karakter, kualitas high | ±120 mesh map + ±80 mesh karakter; target 60 fps (belum diukur otomatis) |
| Sky Islands (paling banyak box) | ±150 mesh, masih ringan |
| Partikel saat combo besar | < 60 mesh, hidup < 0.8 s |
| Ukuran total game (tanpa Three.js) | ±180 KB teks (JS+CSS+HTML) |
| Three.js vendor | 1,3 MB (sekali unduh, di-cache browser) |

Angka fps belum diukur otomatis (butuh browser nyata); kalau terasa berat, ubah
**Settings → Kualitas grafis** ke Medium/Low.

---

## 7. Atribusi & lisensi

- Game asli: **BROKEN.** oleh **Dewan Mukto (D'MUKTO)** — repo ini, lisensi MIT
  (`LICENSE`, © 2024 Dewan Mukto).
- Kode web port: ditulis untuk eksperimen ini, mengikuti lisensi MIT yang sama.
- Three.js © three.js authors, MIT (`web/vendor/THREE-LICENSE.txt`).
- Tidak ada aset Roblox (mesh, animasi, audio, font, ikon) yang disalin; teks/istilah
  seperti "Roblox", "R6", "stud", "WalkSpeed" dipakai sebagai referensi deskriptif.
- Proyek ini **tidak berafiliasi** dengan Roblox Corporation.

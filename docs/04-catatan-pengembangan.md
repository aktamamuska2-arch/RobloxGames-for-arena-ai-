# 04 · Catatan Pengembangan

Changelog, keputusan desain, masalah yang diketahui, dan roadmap.

---

## 1. Changelog

### v1.2.0 — 2026-11-07 (nameplate 3D & obrolan Markov)

Dua keluhan dari pemakaian nyata (screenshot kedua):

1. **"Health-nya kenapa begini"** — health bar & nametag 3D di atas kepala
   berukuran 5.4 × 0.62 stud (dan nametag 9.5 stud). Saat karakter dekat, keduanya
   tampil raksasa dan nametag karakter pemain sendiri menutupi layar ("Berjalan
   bersama" besar di tengah).
   Perbaikan: health bar 3.0 × 0.30, nametag 6.4 × 2.0; opacity meredup mulai
   jarak 7 stud dan hilang di >85 stud; **nametag/HP bar karakter pemain sendiri
   disembunyikan** karena HUD kiri-bawah sudah menampilkan HP dan nama.
2. **Chat bot terlalu template** (`"come here"`). Bot sekarang memakai **rantai
   Markov** (`web/js/markov.js`): tidak membalas siapa pun, hanya mengoceh acak,
   tetapi **menyerap kosakata yang diketik pemain**. Lihat `docs/01` §6.1.

Detail implementasi:
- API: `MarkovChain(order)` dengan `learn()` / `generate()`; `Chatter` menyimpan
  rantai order-1 & order-2 sekaligus, korpus awal dari `CHAT_LINES` + 16 kalimat.
- Anti-ngawur: tanpa pengulangan kata berurutan, siklus A-B-A-B dipotong,
  maksimal 68 karakter, huruf awal dikapitalkan.
- Jeda global antar pesan bot minimal 8 detik (`game.lastBotChat`), tiap bot
  26–60 detik → chat tidak banjir.
- Kelas CSS `.chat-line.bot` untuk membedakan pesan bot.

**Tes baru (11):** Markov memakai kata dari korpus, chat pemain menambah kosakata,
kata pemain masuk rantai, bot mengirim chat, chat tidak menargetkan pemain,
panjang wajar, nameplate pemain tersembunyi, HP bar pemain tersembunyi, ukuran
HP bar ≤ 3.2, terlihat di 10 stud, hilang di jarak jauh. Total simulasi: **90 asersi**.

### v1.1.1 — 2026-11-07 (kamera beku)

Dilaporkan dari pemakaian nyata (screenshot): **kamera tidak bergerak dan karakter
sendiri tidak terlihat**. Penyebabnya ditemukan setelah melacak semua pemanggilan
`updateCamera`:

- `Game.update()` memanggil `world.updateCamera()` **hanya** di cabang `menu` dan
  `pause/results`. Saat state `playing` (cabang `active`) tidak ada pemanggilan sama
  sekali — warisan edit v1.0.0 yang salah menghapus "update kamera ganda".
  Akibatnya kamera membeku di posisi sinematik menu (tampak seperti game rusak, dan
  nametag/HP bar karakter yang kebetulan dekat kamera tampil raksasa).
- Perbaikan: `this.world.updateCamera(this.player.pos, dt)` dipanggil setiap frame
  di cabang aktif, termasuk saat pemain mati (kamera tetap di tubuh).
- Tambahan: nametag & HP bar meredup otomatis saat jarak kamera < 4.5 stud
  (`Avatar.updateNameplate`) supaya teks tidak pernah lagi menutupi layar.

**Tes baru (8):** kamera dekat pemain, kamera menghadap pemain (dot > 0.9),
kamera mengikuti teleport, mouse memutar kamera, posisi kamera berubah saat diputar,
kamera tetap di tubuh saat mati, nametag meredup saat dekat, dan kamera tidak
menembus karakter. Total simulasi: **79 asersi**.

Perbaikan tambahan dari sesi ini:

- Titik `wander` bot dibatasi ke dalam arena (`arenaLimit`) — sebelumnya bot bisa
  memilih titik di luar dinding lalu menekan dinding selamanya (tampak "AI rusak").
- Saat macet, arah lepas bot sekarang condong ke tengah arena, bukan acak.
- Batas bawah occlusion kamera diturunkan ke 1.6 stud supaya kamera tidak "lompat
  ke belakang dinding" di sudut sempit.
- `smoke-test.mjs` dibuat deterministik: arena tetap, posisi tetap, bot difokuskan
  ke satu target, dash/block dimatikan saat menguji damage (dulu kadang gagal
  karena i-frame dash — 8/8 run stabil).

### v1.1.0 — 2026-11-07 (audit menyeluruh + perbaikan bug)

Rilis v1.0.0 ditulis cepat dan **tidak diuji sebagai satu aplikasi utuh** — hanya
modul per modul. Setelah seluruh kode dibaca ulang dan dibuat simulator browser
(`scripts/browser-sim.mjs`), ditemukan dan diperbaiki bug berikut:

| # | Bug | Dampak | Perbaikan |
|---|---|---|---|
| 1 | `#round-banner` tidak pernah di-`show` | **tidak ada timer/nama map/round di HUD** — terasa seperti game rusak | `ui.setRoundInfo()` melepas `hidden`; `ui.update()` menyembunyikannya di luar state playing |
| 2 | `setPaused(false)` ikut menyembunyikan layar *results* | game **nyangkut**: hasil round hilang, tidak bisa lanjut ke round berikutnya | `setPaused`/`togglePause`/`Esc` diabaikan saat `state === 'results'` |
| 3 | Wajah karakter memakai tekstur transparan pada material opaque | **wajah hitam** di semua karakter | `makeFaceTexture(skin)` mengisi latar dengan warna kulit (cache per warna) |
| 4 | Bot menyerang selama intermission | pemain dibunuh saat belanja / jeda antar round | gate `game.combatEnabled`; hanya aktif di fase `round` |
| 5 | Semua 7 bot mengejar pemain (`score += 18`) | pemain dikeroyok & mati dalam ±10 detik | bias per bot 3–15, sisanya duel sesama bot |
| 6 | Tidak ada regenerasi HP | sekali kena, HP tidak pulih sampai mati | regen 4.5 HP/s setelah 6 detik tanpa hit (ala script `Health`) |
| 7 | Skala kesulitan bot hanya dihitung saat spawn (round 1) | round 2+ tidak pernah makin sulit | skala `lightMul/heavyMul` dihitung ulang di `startRound()` |
| 8 | Semua karakter bisa spawn di titik yang sama | tumpang tindih & langsung berkelahi | pemilihan spawn dengan jarak minimum 9 stud |
| 9 | `separateEntities()` mendorong karakter menembus dinding | karakter bisa masuk ke dalam blok | dorongan dibatalkan jika posisi hasilnya terblokir |
| 10 | Server mengembalikan `index.html` (200) untuk aset yang hilang | error membingungkan `Unexpected token '<'` | balas **404** untuk path ber-ekstensi |
| 11 | `while (used.has(n))` tanpa batas saat nama bot habis | **hang** total jika bot > 20 | fallback `Guest N` setelah 24 percobaan |
| 12 | Musik diputar sebelum gesture user | `AudioContext` ditolak, timer musik jalan sia-sia | musik ditunda sampai `unlock()` |
| 13 | Kamera menembus dinding | tidak bisa melihat karakter di sudut sempit | occlusion 9 sampel titik + tarik kamera (`World.setColliders`) |
| 14 | Tidak ada petunjuk saat mati | pemain bingung menunggu 4 detik | overlay `#death-note` dengan hitung mundur |
| 15 | Tanpa efek saat kena hit | feedback kurang | `#hit-flash` putih singkat + `ui.hitFlash()` |
| 16 | Map randomizer bisa memilih map yang sama 2× berturut | terasa tidak acak | pilih ulang maksimum 8× |
| 17 | `assistCoins` didefinisikan tapi tak pernah dipakai | janji di dokumen tidak jalan | peta `damagers` per korban: assist +4 koin untuk pemain |
| 18 | Bot berjalan ke jurang di Sky Islands | bot bunuh diri | cek `groundBelow()` 3.2 stud ke depan, putar arah |
| 19 | Canvas tidak bisa fokus | keyboard mati sampai klik pertama (khusus iframe) | `tabindex="0"` + `canvas.focus()` saat mulai/resume |
| 20 | `airControl` di config tidak dipakai | angka konfigurasi menyesatkan | dipakai pada akselerasi udara |

**Tes baru:** `scripts/browser-sim.mjs` — menjalankan `index.html` + `main.js` asli di
jsdom dengan WebGL palsu: boot, PLAY, gerak, lompat, serangan, kematian & respawn,
intermission aman, shop jual-beli & refund, pause, hasil round, Esc di results,
4 round berturut-turut (cek kebocoran objek & NaN), keluar ke menu lalu main lagi,
dan kamera. **69 asersi, semua lulus** (naik menjadi 90 di v1.2.0).

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
   (v1.1.0 menambahkan penghindaran jurang, bukan pencarian jalur.)
4. 🟢 **Kamera menembus dinding** — sudah diperbaiki di v1.1.0 (occlusion 9 sampel).
   Sisa: kamera masih bisa "menempel" ke dinding tipis pada sudut ekstrem.
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

## 4. Status verifikasi (v1.1.0)

| Lapis | Perintah | Cakupan | Hasil |
|---|---|---|---|
| sintaks | `npm run check` | 15 modul | 15/15 |
| logika | `node scripts/smoke-test.mjs` | map, combat, fisika, AI, lava, FX, player | lulus |
| UI | `node scripts/ui-test.mjs` | wiring DOM, shop, chat, results, settings | lulus |
| **game utuh** | `node scripts/browser-sim.mjs` | boot → 4 round → shop → kamera → markov/chat → menu → main lagi | **90 asersi lulus** |
| semua | `npm test` | keempatnya berurutan | lulus |

Yang **tetap tidak bisa** diverifikasi otomatis (butuh GPU/browser nyata): hasil
kompilasi shader, kualitas visual akhir, dan pointer lock asli.

## 5. Roadmap

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

## 6. Cara debugging

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

## 7. Catatan performa yang diukur (perkiraan)

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

## 8. Atribusi & lisensi

- Game asli: **BROKEN.** oleh **Dewan Mukto (D'MUKTO)** — repo ini, lisensi MIT
  (`LICENSE`, © 2024 Dewan Mukto).
- Kode web port: ditulis untuk eksperimen ini, mengikuti lisensi MIT yang sama.
- Three.js © three.js authors, MIT (`web/vendor/THREE-LICENSE.txt`).
- Tidak ada aset Roblox (mesh, animasi, audio, font, ikon) yang disalin; teks/istilah
  seperti "Roblox", "R6", "stud", "WalkSpeed" dipakai sebagai referensi deskriptif.
- Proyek ini **tidak berafiliasi** dengan Roblox Corporation.

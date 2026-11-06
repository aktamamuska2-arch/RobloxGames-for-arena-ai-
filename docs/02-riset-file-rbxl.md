# 02 · Riset File `.rbxl`

Supaya port ini bisa "semirip mungkin", langkah pertamanya bukan coding game,
tapi **membaca isi kelima file `.rbxl` di repo** — tanpa Roblox Studio.
Catatan ini mendokumentasikan formatnya, tool yang dibuat, apa yang ditemukan,
dan apa yang masih belum bisa dibaca.

> TL;DR: `.rbxl` = file biner Roblox (bukan XML). Dengan ~350 baris Python
> (`tools/rbxl_inspect.py`) kita berhasil membaca **hierarki instance, nama, kelas,
> dan seluruh source Luau** — total **328 script / ±1,5 juta karakter** dari 5 game.
> Yang belum: decoding properti non-string (CFrame/Vector3), jadi geometri map
> belum bisa diimpor.

---

## 1. Isi repo (fakta awal)

| File | Ukuran | Instance | Script | Karakter script |
|---|---:|---:|---:|---:|
| `BrokenPVPgame_20240713_01.rbxl` | 13.5 MB | 58.864 | 163 | 837.119 |
| `DemonHunting_20240717_04.rbxl` | 11.5 MB | 32.294 | 121 | 488.348 |
| `BanglaBattlegrounds_20240706_01.rbxl` | 235 KB | 1.096 | 27 | 145.770 |
| `SaveHer.rbxl` | 131 KB | 1.818 | 4 | 11.045 |
| `Photon_2.rbxl` | 79 KB | 101 | 13 | 25.642 |

Semua file diawali magic `3C 72 6F 62 6C 6F 78 21` (`<roblox!`) → format **biner**,
bukan `.rbxlx` (XML). Untuk membaca, dipakai dokumentasi komunitas rbx-dom
(`rojo-rbx/rbx-dom/docs/binary.md`) sebagai acuan format.

---

## 2. Anatomi file biner

```
HEADER (32 byte)
  magic "<roblox!"         8 byte
  signature 89 FF 0D 0A 1A 0A   6 byte
  version u16 (=0)         2 byte
  class count i32          4 byte
  instance count i32       4 byte
  reserved                 8 byte

CHUNK (berulang, masing-masing 16 byte header)
  name            4 byte  "META" | "SSTR" | "INST" | "PROP" | "PRNT" | "END"
  compressed len  u32
  uncompressed len u32
  reserved        u32
  data            ...
```

Detail yang penting saat implementasi:

1. **Kompresi.** Kalau `compressed len == 0` → data mentah. Kalau tidak, cek 4 byte
   pertama: `28 B5 2F FD` = ZSTD, selain itu **LZ4 blok** (tanpa frame).
   Di kelima file ini semua chunk non-kosong memakai LZ4 → `pip install lz4` cukup.
2. **`INST`**: `classId u32`, `className string`, `objectFormat u8`, `count u32`,
   lalu array referent; kalau class-nya service (`objectFormat = 1`) ada byte marker
   tambahan di akhir.
3. **`PROP`**: `classId u32`, `name string`, `typeId u8`, lalu **array nilai untuk
   semua instance class itu** (urutannya sama dengan urutan referent di `INST`).
   Contoh: `Source` (tipe `0x01` String) menyimpan seluruh Luau script secara inline.
4. **`PRNT`**: `version u8`, `count u32`, array child referent, array parent referent.
5. **`END`**: payload `</roblox>`.

### 2.1 Jebakan #1 — angka "diacak" (byte interleaving)

Array angka di Roblox **tidak** disimpan berurutan, melainkan per-kolom byte:

```
nilai:  A B C            (masing-masing 4 byte)
disk:   A0 B0 C0 | A1 B1 C1 | A2 B2 C2 | A3 B3 C3
```

Selain itu `Int32` disimpan **big-endian** dan ditransformasi zig-zag
(`x<0 → 2|x|−1`, `x≥0 → 2x`). Tanpa memperhitungkan dua hal ini, hasil bacaan
terlihat seperti angka acak raksasa (`-1946157056`, `0x04000000`, dst).

### 2.2 Jebakan #2 — referent bersifat akumulatif

Ini yang paling lama bikin buntu. Dokumentasi menyebut array `Referent` harus dibaca
**akumulatif** (prefix sum), bukan nilai absolut. Contoh nyata dari `Pose` (302 instance)
di Bangla Battlegrounds:

| Langkah | byte plane (hex) | nilai setelah un-interleave + zig-zag | referent sebenarnya |
|---|---|---|---|
| 1 | `… 54` | 682 | **682** |
| 2 | `… 02` | 1 | **683** |
| 3 | `… 02` | 1 | **684** |
| 4 | `… 02` | 1 | **685** |

Sebelum sadar soal akumulasi, hasil bacaan tampak seperti banyak nilai duplikat
(hanya 99–175 nilai unik untuk ribuan instance) — mustahil untuk referent yang unik.
Setelah diperbaiki: **1096 dari 1096 instance unik** di Bangla, dan hierarki
`Workspace → Map → Part` mulai terbaca.

### 2.3 Jebakan #3 — `SSTR` tidak terbaca

Chunk `SSTR` (kumpulan string yang dipakai ulang) punya header `version u32`,
`count u32`, lalu entri `MD5 (16 byte) + string`. Di lima file ini, chunk `SSTR`
**gagal didekompresi** dengan LZ4 standar (hasilnya sampah), padahal chunk `INST`/`PROP`
di file yang sama sukses. Kemungkinan besar Roblox memakai varian kompresi/dictionary
khusus untuk chunk ini.
**Untungnya tidak dibutuhkan**: properti `Source` pada file-file ini disimpan inline
sebagai String (tipe `0x01`), bukan SharedString. Parser dibuat *best-effort*:
kalau `SSTR` gagal, lewati saja.

---

## 3. Tool: `tools/rbxl_inspect.py`

Parser minimal (≈350 baris, dependensi: `lz4` saja) untuk kebutuhan riset.

```bash
python3 tools/rbxl_inspect.py <file.rbxl>                  # ringkasan + tree
python3 tools/rbxl_inspect.py <file.rbxl> --dump out/      # tulis scripts/*.lua + tree.txt
python3 tools/rbxl_inspect.py <file.rbxl> --max-depth 2
```

Yang dibaca:

| Bagian | Status |
|---|---|
| header, daftar chunk, dekompresi LZ4 | ✅ |
| `INST` (class, jumlah, referent) | ✅ |
| `PRNT` (hierarki parent/child) | ✅ |
| `PROP` tipe `String`, `ProtectedString`, `Bool`, `Int32`, `Int64`, `Enum` | ✅ |
| `PROP` tipe `SharedString` (indeks ke `SSTR`) | ⚠️ hanya bila `SSTR` terbaca |
| `PROP` tipe `Vector3`, `CFrame`, `Color3`, `UDim2`, dll. | ❌ belum |
| `SSTR` | ❌ (lihat §2.3) |
| `META` | ✅ (tidak ada di file-file ini) |

Karena properti non-string belum didekode, **geometri map belum bisa diimpor**.
Tapi justru bagian yang paling penting untuk "meniru" game — **script** — sudah terbaca penuh.

---

## 4. Hasil ekstraksi (`research/`)

```
research/<nama-game>/
  ├── summary.txt     # jumlah instance per class
  ├── tree.txt        # hierarki instance (dipotong di kedalaman 6)
  └── scripts/        # semua Script/LocalScript/ModuleScript (*.lua)
```

Jalankan ulang kapan saja dengan perintah di §3 (Broken butuh ±1–2 menit karena
58 ribu instance).

### 4.1 Yang ditemukan di **Broken.** (game yang di-port)

- **Combat**: `BaseWeapon`, `BulletWeapon`, `BowWeapon`, `Bomb`, `Airstrike`, `Ragdoll`,
  `DamageBillboardHandler` (angka damage melayang), `HurtScript` (9×), `Health` (10×).
- **UI**: `CustomHealthBar`, `NotifScript`, `Shop`, `Inventory`, `WeaponsGui`,
  `DirectionalIndicatorGuiManager`, `MouseIcon`, `LoadingScript`.
- **Round/match**: `MapLoader`, `SpawnPlayers`, `SpawnNPCs`, `NPC_AI` (9×), `Factions`,
  `TimePlayed`, `ShowStartMenu`, `cutsceneHandler`.
- **Gerak**: `SprintScript`, `Sprint_on_shift`, `DoubleJump`, `StuntsWallrun`,
  `StuntsRoll`, `Chassis`/`Vehicle` (A-Chassis).
- **Lain-lain**: `PianoScript`, `Glass`/`GlassScript`, `LightStateChanger`, dll.

### 4.2 Yang ditemukan di **Bangla Battlegrounds**

`CombatHandler` — pola combat yang paling relevan:

```lua
-- inti dari CombatHandler (disederhanakan)
function combatMove(player, move, partTemplate, duration, force, damage, soundid, opacity)
  local part = partTemplate:Clone()
  part.Position = root.Position + root.CFrame.LookVector * 2   -- hitbox di depan
  ...
  for t = 0, steps do
    part.Position = part.Position + root.CFrame.LookVector * (2 / steps)  -- hitbox bergerak
    applyForceAndDamage(player, part, force, damage)
  end
end

remoteEvent.OnServerEvent:Connect(function(player, actionName)
  if actionName == "Punch" then combatMove(player, "Punch", ..., 0.3, 0, 5, ...)
  elseif actionName == "Punch2" then ... 20 damage
  elseif actionName == "MegaPunch" then ... 50 damage
  elseif actionName == "HardSmack" then ... 25 damage
  elseif actionName == "LeftKick" then ... 15 damage
```

→ diadopsi sebagai: **hitbox kerucut di depan karakter, damage per jenis serangan,
knockback dari arah hadap, dan suara hit**. Nama serangan (Punch/Punch2/MegaPunch)
menginspirasi sistem combo 3-hit.

### 4.3 Yang ditemukan di **Demon Hunting**

`ChopperSword` (senjata melee) memberi banyak angka & detail "feel":

```lua
local LIGHT_DAMAGE = 12
local HEAVY_DAMAGE = 15
local COOLDOWN = 0.9
local punchAnims = {"Sweep2", "Swing3", "Sweep3"}
local heavyAnims = {"Stab1", "Stab2", "Stab2"}
-- + progress bar cooldown 80x3 px di bawah layar
```

→ diadopsi sebagai: **light/heavy attack dengan damage berbeda, cooldown, bar cooldown,
dan animasi terpisah** (di port ini: swing lengan + model senjata).

Selain itu ada `NPCTalk` (dialog ProximityPrompt 4 pilihan dengan teks berwarna
`<font color='#f1f100'>`) → di port ini NPC jadi bot yang chat sendiri.

### 4.4 Yang ditemukan di **Photon** dan **Save Her**

Dua game abstrak/eksperimental: lebih banyak `ImageLabel`, `TextLabel`, `Sound`,
`ColorCorrectionEffect`, `BlurEffect`. Berguna sebagai referensi gaya UI (panel gelap,
efek blur) tetapi tidak ada mekanik yang diadopsi.

---

## 5. Pemetaan: script Roblox → modul web

| Script asli | Fungsi | Modul web port |
|---|---|---|
| `CombatHandler` (Bangla) | hitbox + damage + knockback | `combat.js` (`resolveHits`, `applyDamage`) |
| `ChopperSword` (Demon Hunting) | light/heavy, cooldown, progress bar | `combat.js` + `ui.js` (`#cooldown-ring`) |
| `CustomHealthBar` | bar HP kustom | `ui.js` (`#hp-block`) |
| `NotifScript` | notifikasi popup | `ui.js` (`toast()`) |
| `DamageBillboardHandler` | angka damage melayang | `ui.js` (`damageNumber()`) |
| `MapLoader` | muat map per round | `maps.js` + `main.js` (`loadArena`) |
| `SpawnPlayers` / `SpawnNPCs` | spawn pemain & bot | `main.js` (`spawnEntities`) |
| `NPC_AI` | AI NPC | `bots.js` |
| `SprintScript`, `DoubleJump`, `StuntsRoll/Wallrun` | gerak tambahan | `player.js` (sprint, coyote jump, dash) |
| `Shop` (LocalScript) | toko | `ui.js` (`buildShop`) + `store.js` |
| `Inventory`, `WeaponsGui` | gear & senjata | `config.js` (`SHOP`) + `avatar.js` (model senjata) |
| `Ragdoll` | mati jatuh | `avatar.js` (`setDead`) |
| `Chassis` / `Vehicle` | kendaraan | *tidak di-port* |

---

## 6. Batasan & langkah berikutnya

1. **Properti non-string** butuh implementasi:
   - `Float32` format Roblox (bit sign dipindah ke belakang mantissa) + byte interleaving;
   - `Vector3` = 3 array komponen; `Color3uint8`; `CFrame` (ID rotasi + matriks 9 float + posisi).
   Setelah itu `Part.Size`, `Part.CFrame`, `Part.Color` bisa dibaca → **map asli bisa
   direkonstruksi** menjadi JSON (target: < 2.000 part setelah decimation, karena map
   Broken punya 26.260 part dan 5.686 MeshPart yang tidak bisa dirender tanpa aset).
2. **`SSTR`** masih misteri; kalau nanti ada file yang menyimpan `Source` sebagai
   SharedString, chunk ini wajib bisa dibaca.
3. **Union/MeshPart** tidak mungkin dirender tanpa aset Roblox — harus diganti box
   pengganti (bounding box) kalau map diimpor.

Semua keterbatasan ini dicatat juga di `docs/04-catatan-pengembangan.md` bagian roadmap.

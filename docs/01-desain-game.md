# 01 · Desain Game

Catatan ini menjelaskan **aturan main** versi web port: angka balancing, alur round,
ekonomi koin, isi shop, dan perbedaan yang disengaja dari game Roblox aslinya.

Semua angka ada di `web/js/config.js` (`PHYS`, `COMBAT`, `ROUND`, `SHOP`) supaya mudah
di-tuning tanpa menyentuh logika.

---

## 1. Fantasi inti (core fantasy)

Game aslinya, **BROKEN.**, adalah *action PvP combat arena*: sekumpulan pemain dilempar
ke arena, bertarung bebas (free-for-all) sampai timer habis, dengan map yang diacak tiap
round, shop di antara round, dan NPC yang berkeliaran. Port ini menjaga empat pilar itu:

1. **Gerak cepat & serangan melee** (bukan shooter).
2. **Round pendek** dengan jeda belanja.
3. **Map acak** tiap round.
4. **Progres gear** yang terasa antar-round.

Yang tidak dibawa: kendaraan (A-Chassis di file asli), sistem senjata api (WeaponsSystem),
cutscene menu, dan sistem tim/faksi (`Script_Factions`). Alasannya teknis (lihat §8).

---

## 2. Unit & skala

1 unit = **1 stud** Roblox (kepala karakter ±1.3 stud, tinggi total ±5.2 stud).
Fisika memakai angka default Roblox sebagai basis:

| Parameter | Nilai | Asal |
|---|---|---|
| Gravitasi | 196.2 stud/s² | default Roblox |
| WalkSpeed | 16 stud/s | default Roblox |
| Sprint | 24 stud/s (+`Speed Coil`) | kustom, meniru gear coil Roblox |
| JumpPower | 50 stud | default Roblox |
| Radius karakter | 1.35 stud | kira-kira lebar R6 |
| Tinggi karakter | 5.2 stud | R6 klasik |
| Step height | 1.1 stud | supaya bisa naik tangga member |

Kamera third-person: jarak default 13.5, FOV 70, jarak bisa di-zoom 6–24 stud.

---

## 3. Combat

### 3.1 Serangan ringan — combo 3x

| Hit | Damage | Range | Cooldown | Knockback | Catatan |
|---|---|---|---|---|---|
| 1 | 6 | 6.2 | 0.34 s | 7 | pembuka combo |
| 2 | 7 | 6.4 | 0.34 s | 8 | |
| 3 | 13 | 7.0 | 0.62 s | 20 | **crit** (warna kuning, shake lebih keras) |

Combo reset kalau jeda antar-hit > **0.85 s**. Setiap hit memakai hitbox berbentuk kerucut:
jarak ≤ `range + radius target`, sudut ≤ ±66°, selisih tinggi ≤ 4.6 stud. Satu swing
boleh mengenai beberapa target sekaligus (tapi setiap target hanya sekali per swing).

### 3.2 Serangan berat

Damage 23, windup 0.34 s, knockback 26, cooldown 1.15 s, biaya **12 stamina**.
Gerak diperlambat ke 32% selama animasi — memberi risiko pada pemakaian yang sembarangan.

### 3.3 Block

Menahan **82% damage** dan memotong knockback jadi 25%, tetapi kecepatan lari turun ke
6 stud/s dan tidak bisa menyerang. Block hanya bekerja bila penyerang ada di **depan**
(dot ≥ 0.15 terhadap arah hadap). Suara "klink" + teks `BLOCK` muncul sebagai umpan balik.

### 3.4 Dash

Kecepatan 46 stud/s selama **0.18 s**, memberi **i-frame 0.26 s** (semua damage diabaikan,
ditandai teks `MISS`), biaya 18 stamina, cooldown 1.5 s (bisa dipotong gear `Dash Module`).

### 3.5 Stamina

Maksimum 100. Sprint menguras 22/s, regen 26/s saat tidak sprint. Dash 18, heavy 12.
Saat stamina ≤ 1 sprint otomatis berhenti — mencegah "sprint abadi".

### 3.6 Kematian & respawn

HP 0 → mati, jatuh ke samping, respawn otomatis setelah **4 detik** di spawn point acak
dengan 1.2 s kebal. Mati juga terjadi kalau jatuh di bawah `killY` map (void) atau
terjebak di zona lava (26 DPS, tick tiap 0.5 s).

> I-frame 0.18 s setelah kena hit mencegah "double hit" dari satu swing yang sama.

---

## 4. Ronde

| Fase | Durasi | Isi |
|---|---|---|
| Intermission | 20 s | map baru dimuat, semua respawn, shop dibuka |
| Round | 120 s | free-for-all, timer berubah merah di 15 s terakhir |
| Results | 9 s | tabel hasil, hadiah koin, tombol lanjut |

`Round` berikutnya menaikkan level gear bot sedikit (`+4%` damage ringan per round,
`+3%` heavy) supaya kesulitan tidak datar.

Kemenangan = **KO terbanyak**. Kalau seri, layar hasil menampilkan "Seri".

---

## 5. Ekonomi koin

| Sumber | Koin |
|---|---|
| Start save baru | 120 |
| KO | 14 × (1 + 0.25 × (streak−1)), maksimum +4 streak |
| Ikut round (bonus akhir) | 20 |
| Menang round (bonus akhir) | 60 |
| **Refund reset gear** | 75% dari total harga item |

Koin disimpan di `localStorage`, tidak ada mata uang premium, tidak ada iklan.
Item dibeli permanen dengan 3 level (harga naik per level).

---

## 6. Shop

| Item | Efek per level | Harga (Lv1/2/3) |
|---|---|---|
| Katana | +18% damage serangan ringan, membuka model pedang | 45 / 110 / 220 |
| Battle Axe | +22% damage & knockback heavy, model kapak | 60 / 140 / 260 |
| Speed Coil | +2 WalkSpeed | 55 / 130 / 240 |
| Health Coil | +20 MaxHealth | 50 / 120 / 230 |
| Armor Vest | −9% damage diterima (maks 60%) | 70 / 160 / 300 |
| Dash Module | −14% cooldown dash | 40 / 95 / 190 |
| Vampire Fang | +1.6 HP per hit | 65 / 150 / 280 |
| Trail Runner | +25 stamina & regen | 45 / 105 / 200 |

Gear hanya memengaruhi pemain. Bot diberi gear acak ringan (pedang 55%, kapak 18%,
speed +2 25%) agar terlihat "juga main".

---

## 7. Map

| Map | Tema | Bahaya | Catatan desain |
|---|---|---|---|
| Brick Arena | siang cerah, bata | — | layout dasar: platform tengah + 4 pilar + krate cover |
| Neon Grid | malam, neon | — | jalur menyala, blok mengambang, pandangan lebih sempit |
| Sky Islands | senja | **void** (jatuh = mati) | 4 pulau + jembatan, memaksa duel di jalur sempit |
| Lava Foundry | gelap, asap | **lava 26 DPS** | kolam lava + jembatan, area tinggi di dua sisi |

Setiap map menyediakan ≥ 7 spawn point (ditandai pad bundar menyala).
Ukuran map 120–150 stud; kamera & fog disesuaikan per tema.

---

## 8. Kesengajaan yang beda dari aslinya

| Asli (`.rbxl`) | Di port ini | Alasan |
|---|---|---|
| Server Roblox, puluhan pemain | 1 player + 7 bot | belum ada backend otoritatif (roadmap #1) |
| Senjata api (`BulletWeapon`, `BowWeapon`, `Airstrike`) | melee saja | mempercepat scope, melee lebih "PvP arena" |
| Kendaraan A-Chassis | — | fisika kendaraan butuh engine fisik sungguhan |
| Map hasil import mesh 26.260 part | 4 map primitif | ukuran & performa browser (roadmap #2) |
| Animasi R15 Roblox | rig R6 prosedural | menghindari aset proprietary |
| NPC dialog dengan GUI pilihan | chat bot & toast | dialog GUI tidak menambah gameplay |

---

## 9. Umpan balik (game feel) yang dipakai

- Damage number melayang (crit lebih besar & kuning, block biru, heal hijau).
- Hit flash di model korban + partikel kotak sesuai arah serangan.
- Screen shake: 0.16 (hit biasa), 0.35 (crit), 0.45 (kena hit), 0.12 (dash).
- Crosshair merah 120 ms saat serangan mendarat.
- Vignette merah yang memudar saat menerima damage.
- Bar cooldown kecil di bawah crosshair (meniru `SwordScript` di Demon Hunting).
- Toasts: KO, killstreak ≥ 3, map baru, koin.

---

## 10. Telemetry internal (untuk balancing)

`game.stats` menyimpan KO/death per round; `Store.stats` menyimpan total (kills, deaths,
rounds, wins). Buka console browser lalu `__GAME` untuk melihat objek game (player,
entity, arena) saat tuning — tidak ada pengiriman data ke server mana pun.

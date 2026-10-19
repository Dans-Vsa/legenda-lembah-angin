# Legenda Lembah Angin (versi Godot)

Versi Godot 4 dari game web *Legenda Lembah Angin*: RPG turn-based dengan sistem ATB.
Isinya sama dengan versi web: desa, padang, hutan, gua, bos, ending, XP dan level up, toko,
penginapan, BURST, serta simpan/muat.

## Menjalankan

1. Buka Godot 4.7, klik **Import**, pilih `project.godot` di folder ini.
2. Tekan **F5**.

Save game tersimpan di `user://save.json`.

## Susunan scene

Seluruh game disusun sebagai scene dan node, jadi semuanya bisa dilihat dan ditata di editor.

| Scene | Isi |
|---|---|
| `main.tscn` | Scene utama: `World`, `BattleLayer/Battle`, `HintLayer`, `UILayer/UI`, `FadeLayer` |
| `scenes/world.tscn` | Penjelajahan: `MapHolder` (peta aktif), `Darkness` (gelap di gua), `Camera2D` |
| `maps/town.tscn`, `world.tscn`, `cave.tscn` | Peta desa, Padang Angin, dan Gua Kabut |
| `scenes/actors/player.tscn` | Pemain (Kael) |
| `scenes/objects/` | `npc`, `chest`, `sign`, `crystal`, `boss`, `warp`, `door` |
| `scenes/battle/battle.tscn` | Layar battle: latar, posisi musuh (`EnemySlots`), party, efek, HUD |
| `scenes/battle/battler.tscn` | Sprite battler dengan bayangan dan shader kilatan |
| `scenes/battle/party_row.tscn` | Baris status party di HUD battle |
| `scenes/ui/` | Layar judul, kotak dialog, pilihan, notifikasi, cerita, game over, menu lapangan, kartu party, toko |

## Mengedit peta

Buka scene di `maps/`. Setiap peta berisi:

- **Ground** (TileMapLayer): pilih node ini lalu lukis tile dari panel **TileMap** di bawah.
  Dinding, pohon, air, gunung, dan atap otomatis tidak bisa dilewati.
- **Labels**: tulisan di atas bangunan.
- **Objects**: NPC, peti, papan, kristal, dan bos sebagai instance scene dari `scenes/objects/`.
  Geser untuk memindahkan (otomatis menempel ke grid); ubah dialog NPC, isi peti, dan lainnya
  di **Inspector**. Tambah objek baru dengan menyeret scene dari `scenes/objects/` ke node
  **Objects**, atau duplikat yang sudah ada (Ctrl+D).
- **Warps**: titik pindah peta (kotak biru, hanya terlihat di editor).
- **Doors**: pintu bangunan (kotak oranye, hanya terlihat di editor).

Di node teratas peta kamu bisa mengatur nama peta, musik, peta gelap, dan tile mana yang
memunculkan monster (`zones`). ID peti harus unik agar status "sudah dibuka" tersimpan dengan benar.

## Mengedit battle dan UI

- **Posisi musuh**: geser `Marker2D` di `battle.tscn > EnemySlots` (`Satu`, `Dua`, `Tiga`, `Bos`
  untuk jumlah musuh 1, 2, 3, dan bos).
- **Posisi party**: geser `Kael`, `Rina`, `Lyra` di `battle.tscn > Party`.
- **Latar battle**: pilih node `Background` dan ganti `Bg Type` di Inspector untuk melihat latar lain.
- **Jendela**: semua jendela (`Win`) di HUD dan scene UI bisa dipindah dan diubah ukurannya.
  Musuh contoh di `Enemies` dan isi daftar menu hanya pratinjau; saat game berjalan isinya
  diganti otomatis.

## Gambar

Semua gambar ada di `assets/` dan bisa diedit dengan aplikasi gambar apa pun (pixel art):

- `assets/characters/`: karakter, NPC, dan monster (party menghadap kiri, monster menghadap kanan)
- `assets/objects/`: peti, papan, kristal
- `assets/tiles/tiles.png`: semua tile peta (4 variasi per baris; baris air, jembatan, dan air mancur berisi 2 frame animasi)

## Struktur kode

| File | Isi |
|---|---|
| `scripts/game.gd` | Autoload utama: input, dialog, adegan, transisi battle, simpan/muat, cerita |
| `scripts/data.gd` | Data karakter, skill, item, monster, rumus damage dan XP |
| `scripts/world_map.gd` | Memuat peta, pergerakan, interaksi, kamera, encounter acak |
| `scripts/battle.gd` | Logika battle ATB, efek visual, kemenangan |
| `scripts/menus.gd` | Menu lapangan, toko, penginapan, kristal penyimpanan |
| `scripts/entities/`, `scripts/actors/` | Script objek peta dan pemain |
| `scripts/battle/`, `scripts/ui/` | Script node battle dan UI |
| `scripts/snd.gd` | Musik dan efek suara chiptune (disintesis lewat kode) |
| `scripts/win.gd`, `list_menu.gd`, `bar.gd` | Komponen UI |
| `shaders/flash.gdshader` | Kilatan putih saat battler terkena serangan |

## Uji otomatis

```bash
godot --headless --path . -- --selftest
```

Memainkan alur utama dengan AI sederhana (peta, menu, toko, battle, bos, game over, simpan/muat)
dan mencetak hasil tiap pengecekan. Jalankan lagi setelah mengedit peta untuk memastikan semua
objek, pintu, dan warp masih bisa dicapai.

Tanpa `--headless`: `-- --shots` menyimpan screenshot permainan ke `user://shots`, dan
`-- --preview-scenes` menyimpan pratinjau scene ke `user://preview`.

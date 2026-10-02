# Legenda Lembah Angin (versi Godot)

Port versi Godot 4 dari game web *Legenda Lembah Angin*: RPG turn-based dengan sistem ATB.
Isinya sama dengan versi web: desa, padang, hutan, gua, bos, ending, XP dan level up, toko,
penginapan, BURST, serta simpan/muat. Semua grafis dan musik dibuat lewat kode.

## Menjalankan

1. Buka Godot 4.7, klik **Import**, pilih `project.godot` di folder ini.
2. Tekan **F5**.

Save game tersimpan di `user://save.json`.

## Struktur

| File | Isi |
|---|---|
| `scripts/game.gd` | Autoload utama: input, dialog, adegan, transisi battle, simpan/muat, cerita |
| `scripts/data.gd` | Data karakter, skill, item, monster, rumus damage dan XP |
| `scripts/art.gd` | Sprite pixel art dan tile peta (dibuat lewat kode) |
| `scripts/snd.gd` | Musik dan efek suara chiptune (disintesis lewat kode) |
| `scripts/world_map.gd` | Peta, pergerakan, NPC, peti, pintu, encounter acak |
| `scripts/battle.gd` | Sistem battle ATB, efek visual, kemenangan |
| `scripts/menus.gd` | Menu lapangan, toko, penginapan, kristal penyimpanan |
| `scripts/win.gd`, `list_menu.gd`, `bar.gd` | Komponen UI |

## Uji otomatis

```bash
godot --headless --path . -- --selftest
```

Memainkan alur utama dengan AI sederhana (peta, menu, toko, battle, bos, game over, simpan/muat)
dan mencetak hasil tiap pengecekan. `-- --shots` (tanpa `--headless`) menyimpan screenshot
beberapa adegan ke `user://shots`.

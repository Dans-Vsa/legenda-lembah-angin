# Legenda Lembah Angin

Game RPG turn-based dengan sistem ATB (Active Time Battle) yang bisa dimainkan langsung di browser.

**Main sekarang:** https://dans-vsa.github.io/legenda-lembah-angin/

## Cerita

Kabut ungu merayap keluar dari Gua Kabut dan mengancam Desa Lembah Angin. Tiga pengembara, yaitu Kael si pendekar pedang, Rina si petarung tangan kosong, dan Lyra si penyihir angin, berangkat untuk menghentikan Wyrm Kabut, naga purba yang menjadi sumbernya.

## Fitur

- Battle ATB dengan Serang, Teknik/Sihir, Item, Bertahan, dan Kabur
- Bar BURST untuk jurus pamungkas tiap karakter
- Kelemahan elemen (Api, Es, Petir), serangan kritis, dan status racun
- XP, level up, dan skill baru di level tertentu
- Desa dengan toko, penginapan, dan NPC; padang, hutan, dan gua dengan peti harta
- Pertarungan bos dan ending
- Simpan dan muat permainan (tersimpan di browser)
- Semua grafis pixel art dan musik chiptune dibuat lewat kode

## Kontrol

| Tombol | Fungsi |
|---|---|
| Panah / WASD | Bergerak, pindah pilihan menu |
| Enter / Z / Spasi | Pilih, bicara, buka peti |
| Esc / X | Batal, buka menu |
| M | Suara on/off |

## Menjalankan secara lokal

Buka `index.html` di browser, atau jalankan server statis di folder ini, misalnya:

```bash
python -m http.server 8000
```

## Versi Godot (opsional)

Folder [`godot/`](godot/) berisi versi Godot 4 dari game yang sama, dengan isi dan keseimbangan yang sama dengan versi web. Versi web di atas tidak bergantung pada folder ini.

1. Pasang [Godot 4.7](https://godotengine.org/download).
2. Di Godot, klik **Import** lalu pilih `godot/project.godot`.
3. Tekan **F5** untuk bermain.

Penjelasan struktur kode dan cara menjalankan uji otomatis ada di [godot/README.md](godot/README.md).

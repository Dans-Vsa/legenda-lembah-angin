"use strict";
// ============================================================
//  Main: state game, adegan (judul, cerita, ending), save/load
// ============================================================
let G = null;
const SAVE_KEY = 'legenda_lembah_angin_v1';
const cv = $('cv'), ctx = cv.getContext('2d');
ctx.imageSmoothingEnabled = false;

function newGame() {
  G = { party: ['kael', 'rina', 'lyra'].map(newMember), items: { ramuan: 3, penawar: 1 }, gold: 150, flags: { chests: {} }, time: 0 };
}
function saveGame() {
  const d = {
    v: 1, gold: G.gold, items: G.items, flags: G.flags, time: G.time,
    map: World.mapId, x: World.px, y: World.py, f: World.facing,
    party: G.party.map(m => ({ id: m.id, lvl: m.lvl, xp: m.xp, hp: m.hp, mp: m.mp, burst: m.burst, weapon: m.weapon, armor: m.armor })),
  };
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(d)); return true; } catch (e) { return false; }
}
function hasSave() { try { return !!localStorage.getItem(SAVE_KEY); } catch (e) { return false; } }
function loadGame() {
  const d = JSON.parse(localStorage.getItem(SAVE_KEY));
  G = {
    gold: d.gold, items: d.items, flags: d.flags, time: d.time,
    party: d.party.map(p => { const m = newMember(p.id); Object.assign(m, p); refreshStats(m); return m; }),
  };
  return d;
}

const Game = {
  scene: 'title',
  enterWorld(map, x, y, f) {
    UI.clear();
    World.load(map, x, y, f);
    Input.push(World);
    World.busy = false;
    this.scene = 'world';
  },
  encounter(zoneId) {
    const z = ZONES[zoneId];
    this.battle(pick(ENCOUNTERS[z.table]), z.bg);
  },
  async battle(group, bg, opts = {}) {
    World.busy = true;
    this.scene = 'trans';
    Snd.stopMusic();
    Snd.sfx('encounter');
    for (let i = 0; i < 3; i++) { await Fade.to(0.85, 70, '#fff'); await Fade.to(0, 70, '#fff'); }
    await Fade.to(1, 250, '#000');
    const result = Battle.start(group, bg, opts);
    await Fade.to(0, 300);
    const r = await result;
    if (r === 'lose') { await Fade.to(1, 900); Battle.teardown(); await GameOver.show(); return r; }
    await Fade.to(1, 350);
    Battle.teardown();
    this.scene = 'world';
    if (!opts.boss) Snd.play(World.def.music);
    await Fade.to(0, 350);
    World.busy = false; World.bumpLock = true;
    return r;
  },
};

// ---------- Cerita & NPC ----------
async function elderTalk() {
  const E = 'Tetua Baram';
  if (!G.flags.metElder) {
    G.flags.metElder = true;
    await say([
      { s: E, t: 'Oh! Kalian para pengembara yang datang dari utara? Syukurlah... desa kami sedang dalam bahaya besar.' },
      { s: E, t: 'Sejak bulan lalu, kabut ungu merayap keluar dari Gua Kabut di timur. Monster menjadi buas, dan warga jatuh sakit.' },
      { s: E, t: 'Konon di dasar gua itu tidur Wyrm Kabut, naga purba yang kini terbangun. Dialah sumber kabut terkutuk ini.' },
      { s: 'Kael', t: 'Serahkan pada kami, Tetua. Kami akan menghentikannya.' },
      { s: 'Rina', t: 'Hmph, naga ya? Tinjuku sudah gatal!' },
      { s: 'Lyra', t: 'Tapi kita harus bersiap dulu. Bertarung dengan monster di padang akan membuat kita lebih kuat.' },
      { s: E, t: 'Terimalah bekal ini. Belilah perlengkapan di toko, dan beristirahatlah di penginapan bila lelah.' },
    ]);
    G.gold += 100; addItem('ramuan', 2); Snd.sfx('chest');
    await say(['Menerima 100 Gold dan Ramuan x2!']);
    await say([{ s: E, t: 'Gua Kabut ada di timur. Ikuti jalan setapak, seberangi jembatan, lalu belok ke utara. Semoga angin melindungi kalian!' }]);
  } else if (!G.flags.boss) {
    await say([{ s: E, t: pick([
      'Jalan setapak aman dari monster. Kalau ingin berlatih, berjalanlah di rumput.',
      'Monster di Hutan Kelam di tenggara lebih kuat, tapi memberi lebih banyak EXP dan Gold.',
      'Bar BURST terisi saat kalian terkena serangan. Saat penuh, keluarkan jurus pamungkas kalian!',
      'Setiap monster punya kelemahan. Api, Es, atau Petir... amatilah baik-baik.',
      'Di dalam gua ada kristal biru bercahaya. Sentuhlah untuk memulihkan diri dan menyimpan perjalanan.',
      'Kudengar Wyrm Kabut sangat kuat. Sebaiknya capai setidaknya Level 8 sebelum menantangnya.',
    ]) }]);
  } else {
    await say([{ s: E, t: 'Kabut telah sirna berkat kalian. Desa ini berutang budi selamanya, wahai Penjaga Lembah!' }]);
  }
}

async function rangerTalk() {
  const A = 'Arga';
  if (!G.flags.metRanger) {
    G.flags.metRanger = true;
    await say([
      { s: A, t: 'Ugh... kalian hendak menantang Wyrm itu? Aku sudah mencoba... dan beginilah jadinya.' },
      { s: A, t: 'Dengar baik-baik. Sisiknya keras, tapi ia lemah terhadap PETIR. Kilat dan Pedang Petir akan sangat berguna.' },
      { s: A, t: 'Napas kabutnya menyerang semua orang sekaligus. Siapkan banyak penyembuh.' },
      { s: A, t: 'Ambil ini. Aku sudah tidak membutuhkannya.' },
    ]);
    addItem('ramuanSuper', 1); Snd.sfx('chest');
    await say(['Menerima Ramuan Super x1!']);
  } else {
    await say([{ s: A, t: 'Kristal biru di persimpangan utara akan memulihkan kalian. Semoga berhasil...' }]);
  }
}

async function bossEvent(e) {
  await say([
    { s: '???', t: '...Siapa yang berani mengusik tidurku?' },
    { s: 'Wyrm Kabut', t: 'Manusia kecil... Kabutku akan menelan seluruh lembah ini, dan kalian bersamanya!' },
    { s: 'Kael', t: 'Tidak akan kami biarkan! Rina, Lyra, bersiap!' },
  ]);
  const r = await Game.battle(['wyrm'], 'boss', { boss: true, music: 'boss' });
  if (r === 'win') {
    G.flags.boss = true;
    World.ents = World.ents.filter(x => x !== e);
    await Ending.play();
  }
}

// ---------- Layar judul ----------
const Title = {
  t: 0,
  layers: [0, 1, 2].map(i => { const r = mulberry32(i * 31 + 5); return Array.from({ length: 64 }, () => r()); }),
  stars: Array.from({ length: 90 }, (_, i) => { const r = mulberry32(i + 999); return [r() * VIEW_W, r() * 260, r()]; }),
  show() {
    UI.clear();
    Game.scene = 'title';
    Snd.play('title');
    const box = UI.win('', 385, 318, 190, null);
    const can = hasSave();
    const m = new ListMenu(box, [{ label: 'Mulai Baru', value: 'new' }, { label: 'Lanjutkan', value: 'load', disabled: !can }], {
      start: can ? 1 : 0,
      onSelect: async it => { m.deactivate(); if (it.value === 'new') await Intro.play(); else await continueGame(); },
    });
    el('div', 'title-help', 'Panah / WASD: gerak &nbsp;•&nbsp; Enter / Z: pilih &nbsp;•&nbsp; Esc / X: batal & menu &nbsp;•&nbsp; M: suara', UI.root);
  },
  drawBg(ctx, dt) {
    this.t += dt;
    const g = ctx.createLinearGradient(0, 0, 0, VIEW_H);
    g.addColorStop(0, '#0d0b2a'); g.addColorStop(0.45, '#3a2a6a'); g.addColorStop(0.75, '#c86a6a'); g.addColorStop(1, '#f2b880');
    ctx.fillStyle = g; ctx.fillRect(0, 0, VIEW_W, VIEW_H);
    for (const [x, y, b] of this.stars) { ctx.globalAlpha = 0.3 + 0.7 * Math.abs(Math.sin(this.t * (0.5 + b) + b * 10)); ctx.fillStyle = '#fff'; ctx.fillRect(x, y, 2, 2); }
    ctx.globalAlpha = 1;
    const cols = ['#4a3a78', '#2e2452', '#191433'];
    this.layers.forEach((hs, li) => {
      const speed = 6 + li * 10, base = 330 + li * 60, amp = 110 - li * 25, seg = VIEW_W / 16;
      const off = (this.t * speed) % (seg * hs.length);
      ctx.fillStyle = cols[li]; ctx.beginPath(); ctx.moveTo(0, VIEW_H);
      for (let i = 0; i <= 17; i++) {
        const gi = Math.floor(off / seg) + i, x = i * seg - (off % seg);
        ctx.lineTo(x, base - hs[gi % hs.length] * amp);
      }
      ctx.lineTo(VIEW_W, VIEW_H); ctx.closePath(); ctx.fill();
      ctx.fillStyle = `rgba(230,200,255,${0.05 + li * 0.02})`;
      ctx.fillRect(0, base - 10 + Math.sin(this.t * 0.4 + li) * 6, VIEW_W, 30);
    });
  },
  draw(ctx, dt) {
    this.drawBg(ctx, dt);
    ctx.textAlign = 'center';
    ctx.font = 'italic bold 24px Georgia, serif';
    ctx.fillStyle = '#ffe9b0'; ctx.fillText('~ Legenda ~', VIEW_W / 2, 118);
    ctx.font = 'bold 70px Georgia, serif';
    const tg = ctx.createLinearGradient(0, 140, 0, 205);
    tg.addColorStop(0, '#fff6d0'); tg.addColorStop(0.5, '#ffd060'); tg.addColorStop(1, '#c07820');
    ctx.lineWidth = 10; ctx.strokeStyle = '#2a1408'; ctx.lineJoin = 'round';
    ctx.strokeText('LEMBAH ANGIN', VIEW_W / 2, 196);
    ctx.fillStyle = tg; ctx.fillText('LEMBAH ANGIN', VIEW_W / 2, 196);
    ctx.font = 'italic 17px Georgia, serif'; ctx.fillStyle = '#f0e0ff';
    ctx.fillText('Sebuah Petualangan RPG Turn-Based', VIEW_W / 2, 232);
    const heroes = ['kael', 'rina', 'lyra'];
    heroes.forEach((h, i) => ctx.drawImage(Art.sprite(h, 3, true), VIEW_W / 2 - 110 + i * 76, 248 + Math.sin(this.t * 2 + i) * 3));
  },
};

async function continueGame() {
  await Fade.to(1, 500);
  const d = loadGame();
  Game.enterWorld(d.map, d.x, d.y, d.f);
  await Fade.to(0, 500);
  banner(World.def.name);
}

// ---------- Cerita pembuka ----------
const Intro = {
  async play() {
    await Fade.to(1, 700);
    UI.clear();
    Game.scene = 'black';
    const box = el('div', 'story', null, UI.root);
    const lines = [
      'Di kaki Pegunungan Biru, berdiri sebuah desa damai bernama Lembah Angin.',
      'Namun sejak bulan lalu, kabut ungu merayap keluar dari Gua Kabut di timur.',
      'Tanaman layu. Monster mengamuk. Warga jatuh sakit satu per satu.',
      'Pada suatu pagi, tiga pengembara tiba di gerbang desa...',
      'Kael si pendekar pedang, Rina si petarung, dan Lyra si penyihir angin.',
    ];
    lines.forEach((L, i) => { el('p', null, L, box).style.animationDelay = (i * 1.4) + 's'; });
    el('div', 'story-hint', 'Tekan Enter untuk melanjutkan ▶', box).style.animationDelay = (lines.length * 1.4) + 's';
    await Fade.to(0, 600);
    await waitOk();
    await Fade.to(1, 600);
    newGame();
    Game.enterWorld('town', 12, 10, 'up');
    await Fade.to(0, 700);
    banner(World.def.name);
    World.busy = true;
    await elderTalk();
    World.busy = false; World.bumpLock = true;
  },
};

// ---------- Ending ----------
const Ending = {
  async play() {
    World.busy = true;
    await Fade.to(1, 1500, '#fff');
    UI.clear();
    Game.scene = 'ending';
    Snd.play('title');
    let box = el('div', 'story', null, UI.root);
    const lines = [
      'Wyrm Kabut tumbang, dan kabut ungu perlahan memudar dari Gua Kabut.',
      'Untuk pertama kalinya dalam berbulan-bulan, matahari menyinari Desa Lembah Angin.',
      'Warga bersorak. Tetua Baram menjuluki ketiga pengembara itu sebagai "Penjaga Lembah".',
      'Namun Kael, Rina, dan Lyra tahu... perjalanan mereka baru saja dimulai.',
    ];
    lines.forEach((L, i) => { el('p', null, L, box).style.animationDelay = (i * 1.8) + 's'; });
    el('div', 'story-hint', 'Tekan Enter ▶', box).style.animationDelay = (lines.length * 1.8) + 's';
    await Fade.to(0, 1500, '#fff');
    await waitOk();
    box.remove();
    box = el('div', 'story', null, UI.root);
    const lv = G.party.map(m => `${CHARS[m.id].name} Lv ${m.lvl}`).join(' • ');
    box.innerHTML = `<h1>TAMAT</h1><p>Terima kasih telah bermain <b>Legenda Lembah Angin</b>!</p>
      <p style="animation-delay:1s;font-size:16px">${lv} &nbsp;—&nbsp; Waktu bermain ${fmtTime(G.time)}</p>
      <p style="animation-delay:2s;font-size:15px;color:#c8c0e8">Progres telah disimpan. Kamu bisa melanjutkan untuk menjelajah dan naik level.</p>
      <div class="story-hint" style="animation-delay:3s">Tekan Enter untuk kembali ke layar judul ▶</div>`;
    World.setFacing('down');
    saveGame();
    await waitOk();
    await Fade.to(1, 800);
    Title.show();
    await Fade.to(0, 800);
  },
};

// ---------- Game over ----------
const GameOver = {
  async show() {
    UI.clear();
    Game.scene = 'gameover';
    Snd.play('gameover');
    el('div', 'gameover-title', 'GAME OVER', UI.root);
    await Fade.to(0, 800);
    const can = hasSave();
    const box = UI.win('', 380, 300, 200, null);
    await new Promise(res => {
      const m = new ListMenu(box, [{ label: 'Muat Simpanan', value: 'load', disabled: !can }, { label: 'Ke Layar Judul', value: 'title' }], {
        start: can ? 0 : 1,
        onSelect: async it => {
          m.deactivate();
          await Fade.to(1, 600);
          if (it.value === 'load') { const d = loadGame(); Game.enterWorld(d.map, d.x, d.y, d.f); }
          else Title.show();
          await Fade.to(0, 600);
          res();
        },
      });
    });
  },
};

// ---------- Skala layar & loop utama ----------
function fit() { const s = Math.min(innerWidth / VIEW_W, innerHeight / VIEW_H); $('game').style.transform = `scale(${s})`; }
addEventListener('resize', fit);
fit();

cv.addEventListener('click', e => {
  if (Game.scene !== 'battle' || !Battle.clickHandler) return;
  const r = cv.getBoundingClientRect();
  Battle.clickHandler((e.clientX - r.left) * VIEW_W / r.width, (e.clientY - r.top) * VIEW_H / r.height);
});

let last = performance.now();
function frame(now) {
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;
  Tween.update(dt);
  if (G && (Game.scene === 'world' || Game.scene === 'battle')) G.time += dt;
  switch (Game.scene) {
    case 'title': Title.draw(ctx, dt); break;
    case 'ending': Title.drawBg(ctx, dt); break;
    case 'world': World.update(dt); World.draw(ctx); break;
    case 'trans': World.draw(ctx); break;
    case 'battle': Battle.update(dt); Battle.draw(ctx); break;
    case 'gameover': ctx.fillStyle = '#000'; ctx.fillRect(0, 0, VIEW_W, VIEW_H); break;
    default: ctx.fillStyle = '#000'; ctx.fillRect(0, 0, VIEW_W, VIEW_H);
  }
  requestAnimationFrame(frame);
}
Fade.set(0);
Title.show();
requestAnimationFrame(frame);

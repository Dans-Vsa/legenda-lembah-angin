"use strict";
// ============================================================
//  World: peta, pergerakan, NPC, peti, pintu, encounter acak
// ============================================================
const TILE = 32;
const DIRS = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };
const BLOCK = new Set('TPM~rRwnd|F#K'.split(''));
const ZONES = {
  grass:  { rate: 0.06, bg: 'field', table: 'grass' },
  forest: { rate: 0.1, bg: 'forest', table: 'forest' },
  cave:   { rate: 0.08, bg: 'cave', table: 'cave' },
};

// Padang Angin dibuat secara prosedural (seed tetap, jadi selalu sama).
function genWorld() {
  const W = 50, H = 36, r = mulberry32(2024), g = [];
  for (let y = 0; y < H; y++) {
    const row = [];
    for (let x = 0; x < W; x++) { const v = r(); row.push(v < 0.05 ? 'T' : v < 0.085 ? ':' : '.'); }
    g.push(row);
  }
  const set = (x, y, c) => { if (x >= 0 && y >= 0 && x < W && y < H) g[y][x] = c; };
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const d = Math.min(x, y, W - 1 - x, H - 1 - y);
    if (d < 2 || (d === 2 && r() < 0.45)) g[y][x] = 'M';
  }
  for (let y = 2; y <= 13; y++) for (let x = 35; x <= 47; x++) if (r() < 0.8) g[y][x] = 'M';
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const dx = (x - 22) / 7, dy = (y - 7) / 3.6;
    if (dx * dx + dy * dy < 1) g[y][x] = '~';
  }
  for (let y = 10; y < H - 2; y++) { const rx = 22 + Math.round(2 * Math.sin(y / 3)); set(rx, y, '~'); set(rx + 1, y, '~'); }
  for (let y = 21; y <= 33; y++) for (let x = 30; x <= 47; x++) if (g[y][x] !== 'M') g[y][x] = r() < 0.22 ? 'P' : 'f';
  const path = (x, y) => set(x, y, g[y][x] === '~' ? '=' : ',');
  for (let x = 8; x <= 41; x++) path(x, 18);
  for (let y = 13; y <= 18; y++) path(41, y);
  for (let y = 19; y <= 22; y++) path(34, y);
  const clear = (cx, cy, c = '.') => {
    for (let y = cy - 1; y <= cy + 1; y++) for (let x = cx - 1; x <= cx + 1; x++) if (!',=~'.includes(g[y][x])) set(x, y, c);
  };
  clear(7, 18); set(7, 18, 'V');
  set(41, 12, 'C');
  [[9, 17], [40, 15], [33, 19], [12, 30]].forEach(([x, y]) => clear(x, y));
  clear(43, 30, 'f');
  return g.map(row => row.join(''));
}

const MAPS = {
  town: {
    name: 'Desa Lembah Angin', music: 'town', pad: 'T',
    rows: [
      'TTTTTTTTTTTTTTTTTTTTTTTTTT',
      'T..:.......TTT.......:...T',
      'T.rrrrr...........RRRRR..T',
      'T.rrrrr...........RRRRR..T',
      'T.wndnw...........wnwdw..T',
      'T...c......ccc.......c...T',
      'T...cccccccccccccccccc...T',
      'T..........cFc...........T',
      'T...:......ccc......:....T',
      'T.rrrrr.....c.....rrrrr..T',
      'T.rrrrr.....c.....rrrrr..T',
      'T.wdnnw.....c.....wnndw..T',
      'T..c........c........c...T',
      'T..ccccccccccccccccccc...T',
      'T..:........c.........:..T',
      'T||||||||...c...|||||||||T',
      'T...........,............T',
      'TTTTTTTTTTTT,TTTTTTTTTTTTT',
    ],
    doors: { '4,4': 'elder', '21,4': 'shop', '3,11': 'inn', '21,11': 'locked' },
    warps: { '12,17': { map: 'world', x: 8, y: 18, f: 'right' } },
    labels: [{ x: 4.5, y: 2.55, t: 'TETUA' }, { x: 20.5, y: 2.55, t: 'TOKO' }, { x: 4.5, y: 9.55, t: 'PENGINAPAN' }],
    ents: () => [
      { type: 'npc', x: 10, y: 8, spr: 'elder', name: 'Tetua Baram', talk: () => elderTalk() },
      { type: 'npc', x: 16, y: 10, spr: 'kid', name: 'Dodi', wander: true, lines: [
        'Kata ayah, jangan main di rumput tinggi. Banyak monster!',
        'Kakak mau ke gua? Wah, keren! Aku juga mau jadi petualang kalau sudah besar!'] },
      { type: 'npc', x: 19, y: 7, spr: 'woman', name: 'Bu Sari', lines: [
        'Penginapan ada di barat daya desa. Semalam cuma 20 Gold, dan kalian akan pulih sepenuhnya.',
        'Toko Pak Darmo di timur laut menjual ramuan dan perlengkapan. Senjata baru sangat membantu!'] },
      { type: 'npc', x: 10, y: 15, spr: 'guard', name: 'Penjaga Desa', lines: [
        'Jalan setapak itu aman dari monster. Tapi rumput di kiri-kanannya... hati-hati.',
        'Tekan Esc atau X untuk membuka menu. Jangan lupa menyimpan permainan!'] },
      { type: 'chest', id: 't1', x: 24, y: 1, items: [['ramuan', 2]] },
    ],
  },
  world: {
    name: 'Padang Angin', music: 'field', pad: 'M', gen: genWorld,
    zone: ch => (ch === '.' || ch === ':') ? 'grass' : ch === 'f' ? 'forest' : null,
    warps: { '7,18': { map: 'town', x: 12, y: 16, f: 'up' }, '41,12': { map: 'cave', x: 15, y: 21, f: 'up' } },
    ents: () => [
      { type: 'sign', x: 9, y: 17, lines: ['← Desa Lembah Angin        Gua Kabut →\n(Seberangi jembatan, lalu belok ke utara)'] },
      { type: 'sign', x: 40, y: 15, lines: ['GUA KABUT — Monster kuat bersarang di dalam. Bersiaplah dengan baik!'] },
      { type: 'sign', x: 33, y: 19, lines: ['HUTAN KELAM — Monster di sini lebih kuat. Konon ada harta karun tersembunyi di dalamnya...'] },
      { type: 'chest', id: 'w1', x: 43, y: 30, gold: 300, items: [['eter', 2]] },
      { type: 'chest', id: 'w2', x: 12, y: 30, items: [['ramuan', 3]] },
    ],
  },
  cave: {
    name: 'Gua Kabut', music: 'cave', pad: '#', dark: true,
    zone: ch => ch === 'g' ? 'cave' : null,
    rows: [
      '################################',
      '#############gggg###############',
      '###########gggggggg#############',
      '##########gggggggggg############',
      '##########ggggggggggK###########',
      '###########gggggggg#############',
      '############gggggg##############',
      '#############gggg###############',
      '#####ggggg#####gg######ggggg####',
      '####gggggggg###gg####ggggggggg##',
      '####gg~~~ggg###gg###gggKgggggg##',
      '###ggg~~~ggggggggggggggggggggg##',
      '###gggggggggggggggggg####gggg###',
      '####ggggK####gg#####g####gggg###',
      '######gg#####gg###ggg####gggg###',
      '######gg####gggg##gg#####ggg####',
      '#####gggg###gggggggg####gggg####',
      '####gggggg##gggggggg###ggggg####',
      '####ggKggg###gggggg#####gggg####',
      '#####gggg#####gggg#######ggg####',
      '##############gggg##############',
      '###############gg###############',
      '###############EE###############',
      '################################',
    ],
    warps: { '15,22': { map: 'world', x: 41, y: 13, f: 'down' }, '16,22': { map: 'world', x: 41, y: 13, f: 'down' } },
    ents: () => [
      { type: 'boss', x: 14, y: 4 },
      { type: 'crystal', x: 13, y: 11 },
      { type: 'npc', x: 17, y: 17, spr: 'ranger', name: 'Arga', talk: () => rangerTalk() },
      { type: 'chest', id: 'c1', x: 5, y: 8, items: [['ramuanSuper', 2]] },
      { type: 'chest', id: 'c2', x: 5, y: 19, equip: 'pedangKristal' },
      { type: 'chest', id: 'c3', x: 26, y: 19, items: [['kristalHidup', 2]] },
      { type: 'chest', id: 'c4', x: 28, y: 9, equip: 'sarungNaga' },
      { type: 'chest', id: 'c5', x: 27, y: 16, equip: 'tongkatBintang' },
    ],
  },
};

const World = {
  mapId: null, def: null, grid: null, w: 0, h: 0, layers: [], ents: [],
  px: 0, py: 0, rx: 0, ry: 0, facing: 'down', flip: false, moving: null,
  steps: 0, busy: false, bumpLock: false, animT: 0, t: 0,

  load(id, x, y, facing) {
    const def = MAPS[id];
    if (def.gen && !def.rows) def.rows = def.gen();
    this.def = def; this.mapId = id;
    const w = Math.max(...def.rows.map(r => r.length));
    this.grid = def.rows.map(r => r.padEnd(w, def.pad).split(''));
    this.w = w; this.h = this.grid.length;
    this.layers = [0, 1].map(f => this.prerender(f));
    this.ents = def.ents().filter(e => !(e.type === 'boss' && G.flags.boss));
    this.ents.forEach(e => { e.hx = e.x; e.hy = e.y; e.rx = e.x * TILE; e.ry = e.y * TILE; e.wt = rand(1, 3); e.flip = false; });
    this.px = x; this.py = y; this.rx = x * TILE; this.ry = y * TILE;
    this.setFacing(facing || 'down');
    this.moving = null; this.steps = 0; this.bumpLock = true;
    Snd.play(def.music);
  },

  prerender(f) {
    const c = document.createElement('canvas');
    c.width = this.w * TILE; c.height = this.h * TILE;
    const x = c.getContext('2d');
    x.imageSmoothingEnabled = false;
    for (let ty = 0; ty < this.h; ty++) for (let tx = 0; tx < this.w; tx++) {
      x.drawImage(Art.tile(this.grid[ty][tx], hash2(tx, ty) % 4, f), tx * TILE, ty * TILE, TILE, TILE);
    }
    x.font = 'bold 11px "Segoe UI", sans-serif'; x.textAlign = 'center'; x.textBaseline = 'middle';
    x.lineWidth = 3; x.strokeStyle = '#2a1408'; x.fillStyle = '#fff4d0';
    for (const L of this.def.labels || []) { x.strokeText(L.t, L.x * TILE + 16, L.y * TILE); x.fillText(L.t, L.x * TILE + 16, L.y * TILE); }
    return c;
  },

  tileAt(x, y) { return (x < 0 || y < 0 || x >= this.w || y >= this.h) ? '#' : this.grid[y][x]; },
  entAt(x, y) { return this.ents.find(e => e.x === x && e.y === y); },
  walkable(x, y) { return !BLOCK.has(this.tileAt(x, y)) && !this.entAt(x, y); },
  setFacing(d) { this.facing = d; if (d === 'left') this.flip = false; else if (d === 'right') this.flip = true; },

  update(dt) {
    this.t += dt;
    for (const e of this.ents) {
      if (e.wander && !this.busy) {
        e.wt -= dt;
        if (e.wt <= 0) {
          e.wt = rand(1.5, 3.5);
          const [dx, dy] = pick(Object.values(DIRS)), nx = e.x + dx, ny = e.y + dy;
          const target = this.moving ? [this.px, this.py] : null;
          if (Math.abs(nx - e.hx) <= 2 && Math.abs(ny - e.hy) <= 2 && this.walkable(nx, ny) &&
              !(nx === this.px && ny === this.py) && !(target && nx === target[0] && ny === target[1])) {
            e.x = nx; e.y = ny; if (dx) e.flip = dx > 0;
          }
        }
      }
      e.rx += (e.x * TILE - e.rx) * Math.min(1, dt * 8);
      e.ry += (e.y * TILE - e.ry) * Math.min(1, dt * 8);
    }
    if (this.moving) {
      const m = this.moving;
      m.t += dt; this.animT += dt;
      const k = Math.min(1, m.t / 0.15);
      this.rx = m.fx + (this.px * TILE - m.fx) * k;
      this.ry = m.fy + (this.py * TILE - m.fy) * k;
      if (k >= 1) { this.moving = null; this.arrive(); }
      return;
    }
    if (this.busy || Input.top() !== this || Game.scene !== 'world') return;
    const dir = ['up', 'down', 'left', 'right'].find(a => Input.isHeld(a));
    if (!dir) { this.bumpLock = false; return; }
    this.setFacing(dir);
    const [dx, dy] = DIRS[dir], nx = this.px + dx, ny = this.py + dy;
    if (this.walkable(nx, ny)) {
      this.moving = { fx: this.rx, fy: this.ry, t: 0 };
      this.px = nx; this.py = ny;
    } else if (!this.bumpLock) {
      this.bumpLock = true;
      const e = this.entAt(nx, ny);
      if (e) this.interact(e);
      else if (this.def.doors && this.def.doors[`${nx},${ny}`]) this.useDoor(this.def.doors[`${nx},${ny}`]);
    }
  },

  arrive() {
    const w = this.def.warps && this.def.warps[`${this.px},${this.py}`];
    if (w) { this.warp(w); return; }
    const zone = this.def.zone && this.def.zone(this.tileAt(this.px, this.py));
    if (!zone) return;
    this.steps++;
    if (this.steps >= 7 && Math.random() < ZONES[zone].rate) { this.steps = 0; Game.encounter(zone); }
  },

  async warp(w) {
    this.busy = true;
    await Fade.to(1, 260);
    this.load(w.map, w.x, w.y, w.f);
    await Fade.to(0, 260);
    banner(this.def.name);
    this.busy = false;
  },

  onKey(a) {
    if (this.busy || this.moving || Game.scene !== 'world') return;
    if (a === 'ok') {
      const [dx, dy] = DIRS[this.facing], nx = this.px + dx, ny = this.py + dy;
      const e = this.entAt(nx, ny);
      if (e) this.interact(e);
      else if (this.def.doors && this.def.doors[`${nx},${ny}`]) this.useDoor(this.def.doors[`${nx},${ny}`]);
    } else if (a === 'cancel' || a === 'menu') FieldMenu.open();
  },

  async interact(e) {
    this.busy = true;
    if (e.type === 'npc') e.flip = this.px > e.x;
    if (e.type === 'chest') await openChest(e);
    else if (e.type === 'crystal') await saveCrystal();
    else if (e.type === 'boss') await bossEvent(e);
    else if (e.talk) await e.talk(e);
    else await say([{ s: e.name, t: e.lines[e.li = ((e.li ?? -1) + 1) % e.lines.length] }]);
    if (Game.scene === 'world') { this.busy = false; this.bumpLock = true; }
  },

  async useDoor(kind) {
    this.busy = true;
    await doorAction(kind);
    if (Game.scene === 'world') { this.busy = false; this.bumpLock = true; }
  },

  camera() {
    const mw = this.w * TILE, mh = this.h * TILE;
    const cx = mw <= VIEW_W ? -(VIEW_W - mw) / 2 : clamp(this.rx + 16 - VIEW_W / 2, 0, mw - VIEW_W);
    const cy = mh <= VIEW_H ? -(VIEW_H - mh) / 2 : clamp(this.ry + 16 - VIEW_H / 2, 0, mh - VIEW_H);
    return [Math.round(cx), Math.round(cy)];
  },

  draw(ctx) {
    const [cx, cy] = this.camera();
    ctx.fillStyle = '#000'; ctx.fillRect(0, 0, VIEW_W, VIEW_H);
    ctx.drawImage(this.layers[Math.floor(this.t * 2) % 2], -cx, -cy);
    const list = this.ents.map(e => ({ y: e.ry, f: () => this.drawEnt(ctx, e, e.rx - cx, e.ry - cy) }));
    list.push({ y: this.ry + 0.1, f: () => this.drawPlayer(ctx, this.rx - cx, this.ry - cy) });
    list.sort((a, b) => a.y - b.y).forEach(o => o.f());
    if (this.def.dark) {
      const px = this.rx - cx + 16, py = this.ry - cy + 16;
      const g = ctx.createRadialGradient(px, py, 70, px, py, 360);
      g.addColorStop(0, 'rgba(12,4,22,0)'); g.addColorStop(1, 'rgba(12,4,22,0.78)');
      ctx.fillStyle = g; ctx.fillRect(0, 0, VIEW_W, VIEW_H);
    }
    ctx.font = '12px "Segoe UI", sans-serif'; ctx.textAlign = 'right'; ctx.fillStyle = 'rgba(255,255,255,0.55)';
    ctx.fillText(Touch.active ? 'START: Menu   •   A: Bicara/Periksa' : 'Esc: Menu   •   Enter: Bicara/Periksa', VIEW_W - 10, VIEW_H - 10);
  },

  shadow(ctx, x, y, w = 22) {
    ctx.fillStyle = 'rgba(0,0,0,0.28)';
    ctx.beginPath(); ctx.ellipse(x + 16, y + 30, w / 2, 4, 0, 0, Math.PI * 2); ctx.fill();
  },

  drawPlayer(ctx, x, y) {
    const bob = this.moving && Math.floor(this.animT * 12) % 2 ? -2 : 0;
    this.shadow(ctx, x, y);
    ctx.drawImage(Art.sprite('kael', 2, this.flip), x, y - 4 + bob);
  },

  drawEnt(ctx, e, x, y) {
    if (e.type === 'chest') { ctx.drawImage(Art.obj('chest', !!G.flags.chests[e.id]), x, y, 32, 32); return; }
    if (e.type === 'sign') { ctx.drawImage(Art.obj('sign', 0), x, y, 32, 32); return; }
    if (e.type === 'crystal') {
      const a = 0.35 + Math.sin(this.t * 3) * 0.15;
      const g = ctx.createRadialGradient(x + 16, y + 16, 2, x + 16, y + 16, 40);
      g.addColorStop(0, `rgba(140,230,255,${a})`); g.addColorStop(1, 'rgba(140,230,255,0)');
      ctx.fillStyle = g; ctx.fillRect(x - 24, y - 24, 80, 80);
      ctx.drawImage(Art.obj('crystal', 0), x, y - 4 + Math.sin(this.t * 2) * 2, 32, 32);
      return;
    }
    if (e.type === 'boss') {
      const g = ctx.createRadialGradient(x + 16, y + 10, 4, x + 16, y + 10, 70);
      g.addColorStop(0, 'rgba(170,120,230,0.35)'); g.addColorStop(1, 'rgba(170,120,230,0)');
      ctx.fillStyle = g; ctx.fillRect(x - 60, y - 60, 150, 150);
      this.shadow(ctx, x, y, 40);
      ctx.drawImage(Art.sprite('wyrm', 2), x - 8, y - 20 + Math.sin(this.t * 1.5) * 2);
      return;
    }
    this.shadow(ctx, x, y);
    ctx.drawImage(Art.sprite(e.spr, 2, e.flip), x, y - 4);
  },
};

// ---------- Interaksi ----------
async function openChest(e) {
  if (G.flags.chests[e.id]) { await say(['Peti ini sudah kosong.']); return; }
  G.flags.chests[e.id] = true;
  Snd.sfx('chest');
  const msgs = [];
  if (e.gold) { G.gold += e.gold; msgs.push(`Mendapat ${e.gold} Gold!`); }
  for (const [id, n] of e.items || []) { addItem(id, n); msgs.push(`Mendapat ${ITEMS[id].name} x${n}!`); }
  if (e.equip) msgs.push(gainEquip(e.equip).join(' '));
  await say(msgs);
}

async function doorAction(kind) {
  if (kind === 'shop') await openShop();
  else if (kind === 'inn') await openInn();
  else if (kind === 'elder') await say(['Rumah Tetua Baram. Pintunya terkunci, Tetua sedang berada di alun-alun desa.']);
  else await say(['Pintunya terkunci. Terdengar suara dengkuran dari dalam...']);
}

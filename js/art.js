"use strict";
// ============================================================
//  Art: semua grafis pixel art dibuat lewat kode (tanpa file gambar)
// ============================================================
const OL = '#1b1424';

// Template sprite. Karakter menghadap KIRI, monster menghadap KANAN.
const TPL = {
  kael: [
    '......o.o.o.....',
    '.....ohohoho....',
    '....ohhhhhhhoo..',
    '...ohHHhhhhhhho.',
    '..ohhhhhhhhhhho.',
    '..ohhsshhhhhho..',
    '..osesSshhhhho..',
    '..osssSshhhho...',
    '...ossSSsoo.....',
    '...occcccco.....',
    '..ocCccccCco....',
    '..osocccccso....',
    '.gsoocCCCcco....',
    'wg..obbbbbo.....',
    'w...obbobbo.....',
    'w...obbobbo.....',
    '....oBBoBBo.....',
    '....ooo.ooo.....',
  ],
  rina: [
    '................',
    '.....oooo.......',
    '....ohhhhoo.....',
    '...ohHhhhhhoo...',
    '..ohhhhhhhhhhoo.',
    '..ohsshhhhhhohho',
    '..oseShhhhhho.oo',
    '..osssShhhho....',
    '...ossSSoo......',
    '...occcccco.....',
    '..ocCcccCcco....',
    '.ssocccccccoss..',
    '.ss.owwwwwo.ss..',
    '....occcccco....',
    '....obboobbo....',
    '....obbo.obbo...',
    '....oBBo.oBBo...',
    '....ooo..ooo....',
  ],
  lyra: [
    '.g....oooo......',
    'gGg..occcco.....',
    '.g..occCccco....',
    '.w.occcccccco...',
    '.w.ochhhhhhcco..',
    '.w.ohssshhhhco..',
    '.w.oseSshhhhco..',
    '.w.osssshhhhco..',
    '.w..osssohhhco..',
    '.wsoccccccccco..',
    '.wssoccCcccco...',
    '.w..occcccccco..',
    '.w.occCcccCccco.',
    '.w.occcccccccco.',
    '.w.oCcccccccCco.',
    '.w.oCCCCCCCCCo..',
    '.w..obbo.obbo...',
    '....oo....oo....',
  ],
  slime: [
    '................',
    '................',
    '................',
    '................',
    '......oooo......',
    '....oocccco.....',
    '...occWccccoo...',
    '..occWWcccccco..',
    '..occcccccccco..',
    '.occcoeccoeccco.',
    '.occcoeccoeccco.',
    '.occcccccccccco.',
    '.oCcccmmmmcccCo.',
    '.oCCcccccccCCCo.',
    '..oCCCCCCCCCCo..',
    '...oooooooooo...',
  ],
  bee: [
    '................',
    '.....oo..oo.....',
    '....oWWooWWo....',
    '....oWWWoWWo....',
    '.....oWWoWWo....',
    '......oooooo....',
    '....oyykkyyeo...',
    '...oyykkyykkyo..',
    '..okyykkyykkyyo.',
    '...oyykkyykkyo..',
    '....ooyykkyoo...',
    '......okkoo.....',
    '.....os.........',
    '................',
    '................',
    '................',
  ],
  wolf: [
    '................',
    '................',
    '...........o.o..',
    '..........ocoCo.',
    '..........occcco',
    'o.........oceccW',
    'co.......occcccN',
    '.co.oooooccccoo.',
    '..ocCcccccccco..',
    '..occcccccccco..',
    '...occCcccccCo..',
    '...ocooCCCooco..',
    '...oc.oc..oc.oc.',
    '...oc.oc..oc.oc.',
    '...oo.oo..oo.oo.',
    '................',
  ],
  mushroom: [
    '................',
    '....oooooooo....',
    '..ooccWcccWcoo..',
    '.occWWccccccWco.',
    'occcccccWWccccco',
    'occWccccWWcccWco',
    'oCcccccccccccCCo',
    '.oooossssssoooo.',
    '....osessesso...',
    '....ossssssso...',
    '....osSsmmsSo...',
    '....oSsssssSo...',
    '...oSSsssssSSo..',
    '...oooooooooo...',
    '................',
    '................',
  ],
  treant: [
    '..g..g.....g....',
    '.gGg.gGg..gGg...',
    '..ggggggggggg...',
    '.gGggggGggggGg..',
    '..ooggggggggoo..',
    '...obbbbbbbbo...',
    '...obebbbbebo...',
    '...obbbbbbbbo...',
    '...obboooobbo...',
    '...obbbbbbbbo...',
    '..obbBbbbbBbbo..',
    '.obbobbbbbbobbo.',
    'ob.o.obbbbo.o.bo',
    'o...obboobbo...o',
    '...ob.o..o.bo...',
    '...o........o...',
  ],
  bat: [
    '................',
    '................',
    '................',
    '.o....o..o....o.',
    '.oo...oooo...oo.',
    '.oWo.occcco.oWo.',
    '.oWWooceceooWWo.',
    '.oWWWocccccoWWWo',
    '.oWWWWocccoWWWWo',
    '.oWoWWoccoWWoWo.',
    '.o..oWo.ooWo..o.',
    '.....o.....o....',
    '................',
    '................',
    '................',
    '................',
  ],
  wisp: [
    '.......o........',
    '......oyo.......',
    '.....oyyo..o....',
    '....oyrryo.oyo..',
    '...oyrrrryoyo...',
    '..oyrrWWrrryo...',
    '..oyrWWWWrrryo..',
    '.oyrrWeWeWrrryo.',
    '.oyrrWWWWWrrryo.',
    '.oyrrrWWWrrrryo.',
    '..oyrrrrrrrryo..',
    '...oyyrrrrryo...',
    '....ooyyyyoo....',
    '......oooo......',
    '................',
    '................',
  ],
  golem: [
    '................',
    '....oooooooo....',
    '...occcccccco...',
    '...ocecccceco...',
    '...occcCCccco...',
    '.ooooccccccoooo.',
    'occccoCCCCocccco',
    'occCcoccccocCcco',
    'occccoccmcocccco',
    '.occoccccccocco.',
    '.occoCccccCocco.',
    '..oooccccccooo..',
    '....occoocco....',
    '...occco.occco..',
    '...oCCCo.oCCCo..',
    '...ooooo.ooooo..',
  ],
  wyrm: [
    '........................',
    '................o.......',
    '...............oHo..o...',
    '..............oHHo.oHo..',
    '.............occcoooHo..',
    '............occcccccco..',
    '...........occcccccecco.',
    '...........occcccccccWWo',
    '............oCcccccWWWo.',
    '.....ooo.....oCcccooooo.',
    '....oMMMo.....occco.....',
    '...oMMMMMo...occcco.....',
    '..oMMmMMMMoooccccco.....',
    '..oMmMMMMMoccccccoo.....',
    '...oMMMMMoccCcccco......',
    '....ooooocccCccccco.....',
    '.......occcCcccccccoo...',
    '......occcCccccooocccoo.',
    '.....occcCccccco..ocCcco',
    '.....occCcccccco...oCco.',
    '......oCCcccccoo....oo..',
    '.......ooCCCCoo.........',
    '.........oooo...........',
    '........................',
  ],
};

const SKIN = { s: '#f3caa0', S: '#d49a74', e: OL };
const SPR = {
  kael:  { t: 'kael', p: { o: OL, ...SKIN, h: '#b5452f', H: '#e8814f', c: '#3a62b4', C: '#24407c', b: '#5b3b29', B: '#2b1f19', w: '#e4ebf7', g: '#e0b040' } },
  rina:  { t: 'rina', p: { o: OL, ...SKIN, h: '#2a2232', H: '#5a4a74', c: '#c8383c', C: '#86201f', w: '#f2ead8', b: '#e6d8c0', B: '#3a2a22' } },
  lyra:  { t: 'lyra', p: { o: OL, s: '#f6d2b0', S: '#d8a888', e: '#3a6ad0', g: '#7ad8ff', G: '#e0faff', w: '#8a5a30', c: '#efeaf8', C: '#a99ad0', h: '#f2cc58', b: '#6a4a8e' } },
  elder: { t: 'lyra', p: { o: OL, ...SKIN, g: '#c09040', G: '#f0d080', w: '#7a5028', c: '#6a9a54', C: '#456e38', h: '#eeeeee', b: '#4a3a2a' } },
  woman: { t: 'rina', p: { o: OL, ...SKIN, h: '#8a4a2a', H: '#b86a40', c: '#d27aa0', C: '#9a4a70', w: '#f2ead8', b: '#efe0c8', B: '#5a3a28' } },
  kid:   { t: 'kael', p: { o: OL, ...SKIN, h: '#f0c040', H: '#ffe080', c: '#5aa05a', C: '#3a703a', b: '#4a3a6a', B: '#2a2030' } },
  guard: { t: 'kael', p: { o: OL, ...SKIN, h: '#4a3a2a', H: '#6a5a44', c: '#9a9aac', C: '#5e5e70', b: '#4a4a5a', B: '#22222a', w: '#d8dce8', g: '#a0a0b0' } },
  ranger:{ t: 'rina', p: { o: OL, ...SKIN, h: '#6a4a2a', H: '#8a6a44', c: '#4a7a4a', C: '#2e5a2e', w: '#a08050', b: '#6a5a40', B: '#2a2018' } },
  slime: { t: 'slime', p: { o: '#14301a', c: '#5ccb5c', C: '#2f8c3b', W: '#d2ffd2', e: OL, m: '#1a3a1a' } },
  bee:   { t: 'bee', p: { o: OL, y: '#f2c21f', k: '#2a2020', W: 'rgba(220,240,255,0.85)', e: '#e02020', s: '#d0d0d0' } },
  wolf:  { t: 'wolf', p: { o: OL, c: '#8c8ca4', C: '#5a5a72', e: '#ff3a3a', W: '#ffffff', N: OL } },
  mushroom: { t: 'mushroom', p: { o: OL, c: '#9a3ab2', C: '#621f82', W: '#f2e2ff', s: '#f2e2c8', S: '#c8b08e', e: OL, m: '#5a2020' } },
  treant:{ t: 'treant', p: { o: '#20140c', g: '#4aa040', G: '#8ad060', b: '#7a5030', B: '#4a3020', e: '#f2e040' } },
  bat:   { t: 'bat', p: { o: OL, c: '#5c3c70', W: '#3a2a4e', e: '#ff4040' } },
  wisp:  { t: 'wisp', p: { o: '#5a1a0a', y: '#ffa22a', r: '#e2442a', W: '#fff2a2', e: '#4a1010' } },
  golem: { t: 'golem', p: { o: '#2a2620', c: '#8e8678', C: '#5e584e', e: '#7af0ff', m: '#5ab04a' } },
  wyrm:  { t: 'wyrm', p: { o: '#1a1028', c: '#9a8ab8', C: '#6a5a8c', H: '#e8e0c8', e: '#ffe040', W: '#ffffff', M: '#5a3a7a', m: '#2e1e44' } },
};

const Art = {
  cache: new Map(),
  whites: new WeakMap(),

  canvas(w, h) {
    const c = document.createElement('canvas');
    c.width = w; c.height = h;
    const x = c.getContext('2d');
    x.imageSmoothingEnabled = false;
    return [c, x];
  },

  fromRows(rows, pal, scale = 1, flip = false) {
    const w = Math.max(...rows.map(r => r.length)), h = rows.length;
    const [c, x] = this.canvas(w * scale, h * scale);
    rows.forEach((r, y) => {
      for (let i = 0; i < w; i++) {
        const col = pal[r[i]];
        if (!col) continue;
        x.fillStyle = col;
        x.fillRect((flip ? w - 1 - i : i) * scale, y * scale, scale, scale);
      }
    });
    return c;
  },

  sprite(key, scale = 1, flip = false) {
    const k = `s|${key}|${scale}|${flip}`;
    if (!this.cache.has(k)) { const d = SPR[key]; this.cache.set(k, this.fromRows(TPL[d.t], d.p, scale, flip)); }
    return this.cache.get(k);
  },

  white(img) {
    if (!this.whites.has(img)) {
      const [c, x] = this.canvas(img.width, img.height);
      x.drawImage(img, 0, 0);
      x.globalCompositeOperation = 'source-in';
      x.fillStyle = '#fff'; x.fillRect(0, 0, c.width, c.height);
      this.whites.set(img, c);
    }
    return this.whites.get(img);
  },

  portrait(key) {
    const k = 'p|' + key;
    if (!this.cache.has(k)) this.cache.set(k, this.sprite(key, 3).toDataURL());
    return this.cache.get(k);
  },

  // ---------- Tile peta (16x16, digambar 2x) ----------
  tile(ch, v, f) {
    const k = `t|${ch}|${v}|${f}`;
    if (this.cache.has(k)) return this.cache.get(k);
    const [c, x] = this.canvas(16, 16);
    const r = mulberry32(v * 977 + ch.charCodeAt(0) * 131 + 17);
    const P = (px, py, col) => { x.fillStyle = col; x.fillRect(px | 0, py | 0, 1, 1); };
    const R = (px, py, w, h, col) => { x.fillStyle = col; x.fillRect(px, py, w, h); };
    const ri = n => Math.floor(r() * n);
    const grass = () => {
      R(0, 0, 16, 16, '#5da544');
      for (let i = 0; i < 16; i++) P(ri(16), ri(16), '#4e9238');
      for (let i = 0; i < 5; i++) { const gx = ri(15), gy = ri(14) + 1; P(gx, gy, '#7cc456'); P(gx + 1, gy - 1, '#7cc456'); }
    };
    const forestFloor = () => {
      R(0, 0, 16, 16, '#3b7d35');
      for (let i = 0; i < 18; i++) P(ri(16), ri(16), '#2f6a2b');
      for (let i = 0; i < 5; i++) P(ri(16), ri(16), '#4f9440');
    };
    const caveFloor = () => {
      R(0, 0, 16, 16, '#5e5068');
      for (let i = 0; i < 18; i++) P(ri(16), ri(16), '#52465c');
      for (let i = 0; i < 8; i++) P(ri(16), ri(16), '#6e6078');
      if (r() < 0.5) { const sx = ri(12) + 2, sy = ri(12) + 2; R(sx, sy, 2, 1, '#7a6c84'); P(sx, sy + 1, '#3a3044'); P(sx + 1, sy + 1, '#3a3044'); }
    };
    const cobble = () => {
      R(0, 0, 16, 16, '#8a867e');
      for (let by = 0; by < 16; by += 4) for (let bx = (by % 8 ? 2 : 0) - 4; bx < 16; bx += 4) {
        R(bx + 1, by + 1, 3, 3, r() < 0.5 ? '#b2ada2' : '#a39f95');
        P(bx + 1, by + 1, '#c8c3b8');
      }
    };
    const mountain = () => {
      for (let py = 1; py < 16; py++) {
        const half = (py - 1) * 0.55 + 0.5;
        for (let px = 0; px < 16; px++) {
          const dx = px - 7.5;
          if (Math.abs(dx) > half) continue;
          let col = dx < 0 ? '#9a9aa8' : '#72727f';
          if (Math.abs(dx) > half - 1) col = '#4a4a58';
          if (py < 5 && Math.abs(dx) < half - 0.5) col = py < 4 ? '#f4f4fa' : '#d8d8e4';
          P(px, py, col);
        }
      }
    };
    const wall = () => {
      R(0, 0, 16, 16, '#e8dcc0');
      R(0, 0, 16, 1, '#7a5432'); R(0, 0, 1, 16, '#7a5432'); R(15, 0, 1, 16, '#7a5432');
      R(0, 15, 16, 1, '#a89878');
      for (let i = 0; i < 6; i++) P(ri(14) + 1, ri(13) + 1, '#d8ccb0');
    };
    const roof = (base, dark, light) => {
      R(0, 0, 16, 16, base);
      for (let y = 0; y < 16; y += 4) {
        R(0, y + 3, 16, 1, dark);
        for (let x0 = (y % 8 ? 2 : 0); x0 < 16; x0 += 4) { P(x0, y, light); P(x0, y + 1, light); R(x0 + 3, y, 1, 3, dark); }
      }
    };
    switch (ch) {
      case '.': grass(); break;
      case ':': grass();
        for (let i = 0; i < 3; i++) {
          const fx = ri(12) + 2, fy = ri(12) + 2, col = pick(['#f05a5a', '#f8e050', '#ffffff', '#e080f0']);
          P(fx, fy - 1, col); P(fx - 1, fy, col); P(fx + 1, fy, col); P(fx, fy + 1, col); P(fx, fy, '#f8e050');
        }
        break;
      case 'f': forestFloor(); break;
      case ',':
        R(0, 0, 16, 16, '#d4b483');
        for (let i = 0; i < 14; i++) P(ri(16), ri(16), r() < 0.5 ? '#c4a170' : '#e2c79a');
        for (let i = 0; i < 2; i++) { const px = ri(14), py = ri(14); R(px, py, 2, 1, '#a88a60'); }
        break;
      case '~': case '=': {
        R(0, 0, 16, 16, '#3d7fd0');
        for (let i = 0; i < 6; i++) P(ri(16), ri(16), '#356fbc');
        for (const wy of [3, 9, 14]) { const xo = (f * 4 + v * 5 + wy * 3) % 16; for (let k2 = 0; k2 < 4; k2++) P((xo + k2) % 16, wy, '#8cc4f4'); P((xo + 1) % 16, wy - 1, '#c8e4fc'); }
        if (ch === '=') {
          R(0, 1, 16, 14, '#9a6a3a');
          for (const py of [1, 5, 9, 13]) R(0, py, 16, 1, '#6e4824');
          R(0, 0, 16, 1, '#4a2e14'); R(0, 15, 16, 1, '#4a2e14');
          for (let i = 0; i < 4; i++) P(ri(16), 2 + ri(12), '#b07c48');
        }
        break;
      }
      case 'T':
        grass();
        R(4, 14, 8, 1, 'rgba(0,0,0,0.25)');
        R(7, 10, 2, 5, '#6a4424');
        for (let py = 0; py < 13; py++) for (let px = 0; px < 16; px++) {
          const d = (px - 7.5) ** 2 + (py - 6.5) ** 2;
          if (d < 42) P(px, py, d > 32 ? '#1d5424' : ((px - 5.5) ** 2 + (py - 4.5) ** 2 < 9 ? '#4aa346' : '#2f7d33'));
        }
        P(5, 4, '#78c868'); P(9, 8, '#255f2a'); P(11, 6, '#255f2a');
        break;
      case 'P':
        forestFloor();
        R(7, 13, 2, 3, '#5a3a1a');
        for (let py = 1; py < 14; py++) {
          const w = 1 + ((py - 1) % 4) + Math.floor((py - 1) / 4) * 1.4;
          for (let px = Math.round(7.5 - w); px <= Math.round(7.5 + w); px++) {
            const edge = px === Math.round(7.5 - w) || px === Math.round(7.5 + w);
            P(px, py, edge ? '#16452a' : px < 7 ? '#3f9a4c' : '#2a7038');
          }
        }
        break;
      case 'M': grass(); mountain(); break;
      case 'C':
        grass(); mountain();
        R(5, 9, 6, 7, '#141018'); R(6, 8, 4, 1, '#141018'); R(4, 11, 1, 5, '#2a2430'); R(11, 11, 1, 5, '#2a2430');
        break;
      case 'V':
        grass();
        R(1, 7, 6, 6, '#e8dcc0'); R(0, 5, 8, 3, '#c04030'); R(3, 10, 2, 3, '#6a4020');
        R(9, 8, 6, 5, '#e8dcc0'); R(8, 6, 8, 3, '#3a60b0'); R(11, 10, 2, 3, '#6a4020');
        R(0, 13, 16, 1, 'rgba(0,0,0,0.2)');
        break;
      case 'c': cobble(); break;
      case 'r': roof('#b8402e', '#7e2a1e', '#e0664a'); break;
      case 'R': roof('#3a64b8', '#24427e', '#6a92e0'); break;
      case 'w': wall(); break;
      case 'n':
        wall();
        R(4, 3, 8, 8, '#5a3a20'); R(5, 4, 6, 6, '#8ad0f0'); R(5, 4, 2, 2, '#d0f0ff'); R(7, 4, 2, 6, '#5a3a20'); R(5, 6, 6, 1, '#5a3a20');
        R(3, 11, 10, 1, '#7a5432');
        break;
      case 'd':
        wall();
        R(4, 2, 8, 14, '#4a2a10'); R(5, 3, 6, 13, '#8a5a30');
        R(7, 3, 1, 13, '#6a4020'); P(9, 9, '#f0d050'); R(4, 15, 8, 1, '#3a2a1a');
        break;
      case '|':
        grass();
        R(2, 6, 2, 9, '#7a4a24'); R(12, 6, 2, 9, '#7a4a24');
        R(0, 8, 16, 2, '#b07844'); R(0, 12, 16, 2, '#b07844'); R(0, 9, 16, 1, '#8a5a30'); R(0, 13, 16, 1, '#8a5a30');
        break;
      case 'F':
        cobble();
        for (let py = 0; py < 16; py++) for (let px = 0; px < 16; px++) {
          const d = (px - 7.5) ** 2 + (py - 8) ** 2;
          if (d < 56) P(px, py, d > 40 ? '#7a7a88' : d > 34 ? '#5a5a68' : (f && (px + py) % 3 === 0 ? '#8cc8f8' : '#4a90e0'));
        }
        R(7, 3, 2, 6, '#c0d8ff'); P(7, 2, '#ffffff'); P(8, 2, '#ffffff');
        break;
      case 'g': caveFloor(); break;
      case 'E':
        caveFloor();
        x.fillStyle = 'rgba(255,240,200,0.35)'; x.fillRect(0, 0, 16, 16);
        for (let i = 0; i < 6; i++) P(ri(16), ri(16), '#fff4d8');
        break;
      case '#':
        R(0, 0, 16, 16, '#140f1a');
        for (let by = 0; by < 16; by += 5) for (let bx = (by % 10 ? -3 : 0); bx < 16; bx += 6) {
          R(bx + 1, by + 1, 5, 4, r() < 0.5 ? '#211a2a' : '#261e30');
          R(bx + 1, by + 1, 5, 1, '#30263c');
        }
        break;
      case 'K':
        R(0, 0, 16, 16, '#140f1a');
        for (let i = 0; i < 10; i++) P(ri(16), ri(16), '#261e30');
        for (const [cx, h, w2] of [[5, 11, 2], [9, 14, 3], [12, 8, 2]]) {
          for (let py = 0; py < h; py++) {
            const ww = Math.max(0, Math.round(w2 * Math.min(1, (h - py) / 4, py / 3 + 0.4)));
            for (let px = cx - ww; px <= cx + ww; px++) P(px, 15 - py, px < cx ? '#a8f0ff' : px === cx ? '#60d8f8' : '#2a90c0');
          }
        }
        break;
      default: grass();
    }
    this.cache.set(k, c);
    return c;
  },

  // ---------- Objek peta ----------
  obj(kind, state) {
    const k = `o|${kind}|${state}`;
    if (this.cache.has(k)) return this.cache.get(k);
    const [c, x] = this.canvas(16, 16);
    const R = (px, py, w, h, col) => { x.fillStyle = col; x.fillRect(px, py, w, h); };
    if (kind === 'chest') {
      R(2, 14, 12, 1, 'rgba(0,0,0,0.3)');
      if (!state) {
        R(1, 5, 14, 10, OL); R(2, 6, 12, 8, '#8a5a2a'); R(2, 6, 12, 3, '#b07838'); R(2, 6, 12, 1, '#d09858');
        R(2, 9, 12, 1, '#e0b040'); R(7, 8, 2, 3, '#f8e070'); R(7, 10, 2, 1, '#6a4a10');
      } else {
        R(1, 2, 14, 5, OL); R(2, 3, 12, 3, '#6a4420');
        R(1, 7, 14, 8, OL); R(2, 8, 12, 6, '#8a5a2a'); R(3, 8, 10, 2, '#1a0e06'); R(2, 10, 12, 1, '#e0b040');
      }
    } else if (kind === 'sign') {
      R(7, 9, 2, 7, '#5a3a1a'); R(1, 2, 14, 8, OL); R(2, 3, 12, 6, '#c09058');
      R(3, 4, 9, 1, '#7a5428'); R(3, 6, 7, 1, '#7a5428'); R(2, 3, 12, 1, '#e0b47a');
    } else if (kind === 'crystal') {
      R(3, 14, 10, 2, '#3a3046');
      for (let py = 0; py < 14; py++) {
        const w = py < 7 ? py * 0.75 : (14 - py) * 0.75;
        for (let px = Math.round(8 - w); px <= Math.round(7 + w); px++) R(px, py, 1, 1, px < 8 ? '#b8f4ff' : '#4cc8f0');
      }
      R(6, 3, 1, 3, '#ffffff');
    }
    this.cache.set(k, c);
    return c;
  },

  // ---------- Latar battle ----------
  battleBg(type) {
    const k = 'bg|' + type;
    if (this.cache.has(k)) return this.cache.get(k);
    const [c, x] = this.canvas(VIEW_W, VIEW_H);
    const r = mulberry32(type.length * 99 + 7);
    const grad = (y0, y1, stops) => {
      const g = x.createLinearGradient(0, y0, 0, y1);
      stops.forEach((s, i) => g.addColorStop(i / (stops.length - 1), s));
      x.fillStyle = g; x.fillRect(0, y0, VIEW_W, y1 - y0);
    };
    const ridge = (base, amp, color, seed) => {
      x.fillStyle = color; x.beginPath(); x.moveTo(0, VIEW_H);
      for (let px = 0; px <= VIEW_W; px += 8) x.lineTo(px, base - amp * (0.5 + 0.3 * Math.sin(px / 90 + seed) + 0.2 * Math.sin(px / 37 + seed * 2)));
      x.lineTo(VIEW_W, VIEW_H); x.closePath(); x.fill();
    };
    const ell = (cx, cy, rx, ry, col) => { x.fillStyle = col; x.beginPath(); x.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2); x.fill(); };
    const tufts = (y0, cols, n) => {
      for (let i = 0; i < n; i++) {
        const tx = r() * VIEW_W, ty = y0 + r() * (VIEW_H - y0), s = 1 + (ty - y0) / 120;
        x.strokeStyle = pick(cols); x.lineWidth = 1.5;
        x.beginPath(); x.moveTo(tx - 3 * s, ty - 5 * s); x.lineTo(tx, ty); x.lineTo(tx + 3 * s, ty - 6 * s); x.stroke();
      }
    };
    if (type === 'field') {
      grad(0, 240, ['#4f8fd8', '#a8d0f4', '#e4f2ff']);
      for (let i = 0; i < 6; i++) { const cx = r() * VIEW_W, cy = 30 + r() * 90; for (let j = 0; j < 5; j++) ell(cx + j * 22 - 44, cy + Math.sin(j) * 6, 26, 14, 'rgba(255,255,255,0.85)'); }
      ridge(190, 70, '#8ea8cc', 1); ridge(212, 40, '#6f9a6a', 3);
      grad(205, 540, ['#78b85a', '#4f9a3c', '#2f6e26']);
      for (let i = 0; i < 14; i++) { const y = 210 + Math.pow(i / 14, 1.7) * 330; x.fillStyle = 'rgba(0,0,0,0.05)'; x.fillRect(0, y, VIEW_W, 2 + i * 0.5); }
      tufts(215, ['#3a7a2a', '#8ad06a', '#2f6a22'], 160);
    } else if (type === 'forest') {
      grad(0, 250, ['#0f2416', '#24502e', '#4a7a48']);
      for (let i = 0; i < 9; i++) { x.fillStyle = 'rgba(255,255,200,0.05)'; x.beginPath(); const lx = r() * VIEW_W; x.moveTo(lx, 0); x.lineTo(lx + 40, 0); x.lineTo(lx + 160, 250); x.lineTo(lx + 90, 250); x.fill(); }
      for (let i = 0; i < 16; i++) { const tx = r() * VIEW_W, tw = 16 + r() * 24; x.fillStyle = i % 2 ? '#14281a' : '#1b3522'; x.fillRect(tx, 0, tw, 250); ell(tx + tw / 2, 10 + r() * 40, 60 + r() * 40, 50, i % 2 ? '#1a3a22' : '#21452a'); }
      ridge(240, 30, '#24482a', 2);
      grad(228, 540, ['#3d6e30', '#2c5524', '#1a3616']);
      for (let i = 0; i < 14; i++) ell(r() * VIEW_W, 260 + r() * 260, 40 + r() * 50, 8 + r() * 8, 'rgba(0,0,0,0.12)');
      tufts(232, ['#5a9a40', '#2a5a20', '#78b050'], 140);
    } else {
      const boss = type === 'boss';
      grad(0, 260, boss ? ['#120818', '#2a1438', '#3a2050'] : ['#0e0a16', '#1e1828', '#2e2640']);
      for (let i = 0; i < 20; i++) {
        const sx = r() * VIEW_W, w = 18 + r() * 34, h = 40 + r() * 110;
        x.fillStyle = '#16111f'; x.beginPath(); x.moveTo(sx, 0); x.lineTo(sx + w, 0); x.lineTo(sx + w / 2, h); x.fill();
        x.strokeStyle = '#2e2640'; x.beginPath(); x.moveTo(sx, 0); x.lineTo(sx + w / 2, h); x.stroke();
      }
      for (let i = 0; i < 9; i++) {
        const cx = r() * VIEW_W, cy = 60 + r() * 160, h = 10 + r() * 16, col = boss ? '#c080ff' : '#70e0ff';
        const g = x.createRadialGradient(cx, cy, 0, cx, cy, 40); g.addColorStop(0, boss ? 'rgba(190,120,255,0.3)' : 'rgba(110,220,255,0.3)'); g.addColorStop(1, 'rgba(0,0,0,0)');
        x.fillStyle = g; x.fillRect(cx - 40, cy - 40, 80, 80);
        x.fillStyle = col; x.beginPath(); x.moveTo(cx, cy - h); x.lineTo(cx + 5, cy); x.lineTo(cx, cy + 4); x.lineTo(cx - 5, cy); x.fill();
      }
      ridge(250, 30, boss ? '#2a1a3a' : '#2a2236', 4);
      grad(238, 540, boss ? ['#3a2a4a', '#2a1e36', '#160e1e'] : ['#4a3e56', '#342a40', '#1c1626']);
      for (let i = 0; i < 26; i++) ell(r() * VIEW_W, 260 + r() * 260, 10 + r() * 30, 4 + r() * 8, 'rgba(0,0,0,0.18)');
      if (boss) for (let i = 0; i < 12; i++) ell(r() * VIEW_W, 120 + r() * 300, 120 + r() * 120, 30 + r() * 30, 'rgba(180,140,220,0.07)');
    }
    this.cache.set(k, c);
    return c;
  },
};

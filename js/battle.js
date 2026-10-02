"use strict";
// ============================================================
//  Battle: sistem ATB (Active Time Battle) mode Wait
//  ATB berhenti saat menu terbuka atau animasi aksi berjalan.
// ============================================================

// ---------- Efek visual (partikel, garis, petir, angka damage) ----------
const FX = {
  parts: [], lines: [], pops: [], bolts: [], rings: [], flash: 0, flashColor: '#fff', shake: 0,
  reset() { this.parts = []; this.lines = []; this.pops = []; this.bolts = []; this.rings = []; this.flash = 0; this.shake = 0; },
  spawn(x, y, o = {}) {
    const life = o.life ?? 0.6;
    this.parts.push({ x, y, vx: o.vx ?? rand(-60, 60), vy: o.vy ?? rand(-60, 60), life, max: life, color: o.color || '#fff', size: o.size || 4, grav: o.grav || 0, shape: o.shape || 'sq', trail: o.trail });
  },
  burst(x, y, n, colors, o = {}) {
    for (let i = 0; i < n; i++) {
      const a = rand(0, Math.PI * 2), sp = rand(o.min || 40, o.max || 160);
      this.spawn(x, y, { vx: Math.cos(a) * sp, vy: Math.sin(a) * sp + (o.up || 0), life: rand(o.lmin || .3, o.lmax || .7), color: pick(colors), size: rand(o.smin || 2, o.smax || 5), grav: o.grav, shape: o.shape });
    }
  },
  line(x1, y1, x2, y2, o = {}) { const life = o.life || .25; this.lines.push({ x1, y1, x2, y2, life, max: life, color: o.color || '#fff', w: o.w || 4 }); },
  bolt(x, y) {
    const pts = [];
    let cx = x + rand(-40, 40), cy = -10;
    while (cy < y) { pts.push([cx, cy]); cy += rand(18, 34); cx += rand(-22, 22); }
    pts.push([x, y]);
    this.bolts.push({ pts, life: .3, max: .3 });
  },
  ring(x, y, o = {}) { const life = o.life || .4; this.rings.push({ x, y, r0: o.r0 || 5, r1: o.r1 || 80, life, max: life, color: o.color || '#fff' }); },
  pop(x, y, text, color, size = 26) {
    const near = this.pops.filter(p => Math.abs(p.x - x) < 30 && p.t < 0.5).length;
    this.pops.push({ x, y: y - near * 22, text: String(text), color, size, t: 0 });
  },
  update(dt) {
    for (const p of this.parts) { p.life -= dt; p.vy += p.grav * dt; p.x += p.vx * dt; p.y += p.vy * dt; }
    this.parts = this.parts.filter(p => p.life > 0);
    for (const arr of [this.lines, this.bolts, this.rings]) for (const o of arr) o.life -= dt;
    this.lines = this.lines.filter(o => o.life > 0); this.bolts = this.bolts.filter(o => o.life > 0); this.rings = this.rings.filter(o => o.life > 0);
    for (const p of this.pops) p.t += dt;
    this.pops = this.pops.filter(p => p.t < 1.25);
    this.flash = Math.max(0, this.flash - dt * 3);
    this.shake = Math.max(0, this.shake - dt * 30);
  },
  draw(ctx) {
    ctx.save();
    for (const r of this.rings) {
      const k = 1 - r.life / r.max;
      ctx.globalAlpha = r.life / r.max; ctx.strokeStyle = r.color; ctx.lineWidth = 4;
      ctx.beginPath(); ctx.arc(r.x, r.y, r.r0 + (r.r1 - r.r0) * k, 0, Math.PI * 2); ctx.stroke();
    }
    for (const p of this.parts) {
      ctx.globalAlpha = Math.min(1, p.life / p.max * 1.5); ctx.fillStyle = p.color;
      const s = p.size;
      if (p.trail) { ctx.strokeStyle = 'rgba(255,200,120,0.6)'; ctx.lineWidth = s * 0.7; ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(p.x - p.vx * 0.12, p.y - p.vy * 0.12); ctx.stroke(); }
      if (p.shape === 'circ') { ctx.beginPath(); ctx.arc(p.x, p.y, s, 0, Math.PI * 2); ctx.fill(); }
      else if (p.shape === 'dia') { ctx.beginPath(); ctx.moveTo(p.x, p.y - s); ctx.lineTo(p.x + s * 0.6, p.y); ctx.lineTo(p.x, p.y + s); ctx.lineTo(p.x - s * 0.6, p.y); ctx.fill(); }
      else if (p.shape === 'star') { ctx.fillRect(p.x - s, p.y - 1, s * 2, 2); ctx.fillRect(p.x - 1, p.y - s, 2, s * 2); }
      else ctx.fillRect(p.x - s / 2, p.y - s / 2, s, s);
    }
    for (const l of this.lines) {
      const k = l.life / l.max;
      ctx.globalAlpha = k; ctx.strokeStyle = l.color; ctx.lineWidth = l.w * k + 1; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(l.x1, l.y1); ctx.lineTo(l.x2, l.y2); ctx.stroke();
    }
    for (const b of this.bolts) {
      ctx.globalAlpha = b.life / b.max;
      for (const [w, col] of [[9, 'rgba(160,200,255,0.5)'], [3, '#ffffff']]) {
        ctx.strokeStyle = col; ctx.lineWidth = w; ctx.lineJoin = 'round';
        ctx.beginPath(); b.pts.forEach(([x, y], i) => i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)); ctx.stroke();
      }
    }
    ctx.globalAlpha = 1;
    ctx.textAlign = 'center'; ctx.lineJoin = 'round';
    for (const p of this.pops) {
      const t = p.t;
      const yo = t < .15 ? -t / .15 * 26 : t < .3 ? -26 + (t - .15) / .15 * 14 : -12;
      ctx.globalAlpha = t > .95 ? Math.max(0, 1 - (t - .95) / .3) : 1;
      ctx.font = `bold ${p.size}px "Segoe UI", sans-serif`;
      ctx.lineWidth = 5; ctx.strokeStyle = '#000'; ctx.strokeText(p.text, p.x, p.y + yo);
      ctx.fillStyle = p.color; ctx.fillText(p.text, p.x, p.y + yo);
    }
    ctx.restore();
  },
};

const ENEMY_SLOTS = { 1: [[250, 200]], 2: [[210, 140], [300, 265]], 3: [[190, 105], [320, 190], [190, 285]] };
const CMD_HELP = {
  attack: 'Serangan biasa dengan senjata ke satu musuh.',
  item: 'Gunakan item dari tas.',
  defend: 'Bertahan: damage yang diterima berkurang setengah sampai giliran berikutnya.',
  flee: 'Mencoba kabur dari pertarungan.',
};

const Battle = {
  state: 'off', party: [], enemies: [], ready: [], actor: null, cursor: null, t: 0, ui: null,

  start(group, bgType, opts = {}) {
    this.opts = opts; this.boss = !!opts.boss; this.bg = Art.battleBg(bgType); this.t = 0;
    this.party = G.party; this.ready = []; this.actor = null; this.cursor = null; this.clickHandler = null;
    this.party.forEach((m, i) => {
      m.atb = m.hp > 0 ? rand(0, 45) : 0; m.defending = false; m.poison = false;
      m.v = { ox: 0, oy: 0, alpha: 1, flash: 0, shake: 0 };
      m.bx = 772 + i * 30; m.by = 118 + i * 84;
      m.img = Art.sprite(m.id, 4); m.white = Art.white(m.img);
    });
    const slots = this.boss ? [[250, 190]] : ENEMY_SLOTS[group.length];
    this.enemies = group.map((id, i) => {
      const t = ENEMIES[id], img = Art.sprite(t.sprite, t.scale);
      return { tpl: t, isEnemy: true, name: t.name, hp: t.hp, maxHp: t.hp, atk: t.atk, def: t.def, mag: t.mag, spd: t.spd,
        atb: rand(0, 40), x: slots[i][0], y: slots[i][1], img, white: Art.white(img), w: img.width, h: img.height,
        v: { ox: 0, oy: 0, alpha: 1, flash: 0, shake: 0 }, dead: false, phase: rand(0, 6) };
    });
    const count = {};
    this.enemies.forEach(e => count[e.name] = (count[e.name] || 0) + 1);
    const seen = {};
    this.enemies.forEach(e => { if (count[e.name] > 1) { const k = seen[e.name] || 0; seen[e.name] = k + 1; e.name += ' ' + String.fromCharCode(65 + k); } });

    FX.reset();
    this.buildUI();
    Snd.play(opts.music || 'battle');
    Game.scene = 'battle';
    this.state = 'intro';
    const names = [...new Set(this.enemies.map(e => e.tpl.name))].join(', ');
    this.help(this.boss ? `${names} menghadang!` : `${names} muncul!`);
    Tween.wait(1000).then(() => { if (this.state === 'intro') { this.help(''); this.state = 'run'; } });
    return new Promise(res => this.resolve = res);
  },

  // ---------- UI bawah ----------
  buildUI() {
    this.ui = el('div', 'bui', null, UI.root);
    this.helpW = UI.win('bhelp hidden', 200, 10, 560, null, this.ui);
    this.enemyW = UI.win('benemy', 6, 374, 238, 160, this.ui);
    this.cmdBox = UI.win('bcmd', 250, 374, 180, 160, this.ui);
    this.partyW = UI.win('bparty', 436, 374, 518, 160, this.ui);
    el('div', 'prow-h', '<span>NAMA</span><span>HP</span><span>MP</span><span>ATB / BURST</span>', this.partyW);
    this.rows = new Map();
    for (const m of this.party) {
      const r = el('div', 'prow', null, this.partyW);
      const pn = el('div', null, null, r);
      const name = el('span', 'pn', CHARS[m.id].name, pn), st = el('span', 'pst', '', pn);
      const php = el('div', 'php', null, r), hpTxt = el('span', null, '', php);
      const hpBar = el('div', 'bar hp', '<i></i>', php);
      const mp = el('div', null, '', r);
      const g = el('div', 'gauges', null, r);
      const atbBar = el('div', 'bar atb', '<i></i>', g), burstBar = el('div', 'bar burst', '<i></i>', g);
      this.rows.set(m, { r, name, st, php, hpTxt, hpBar: hpBar.firstChild, mp, atbBar, atb: atbBar.firstChild, burstBar, burst: burstBar.firstChild, key: '' });
    }
    this.updateUI();
  },

  help(text, enemy) {
    if (!this.helpW) return;
    this.helpW.classList.toggle('hidden', !text);
    this.helpW.classList.toggle('enemy', !!enemy);
    this.helpW.textContent = text || '';
  },

  updateUI() {
    if (!this.ui) return;
    const names = {};
    for (const e of this.enemies) if (!e.dead) names[e.tpl.name] = (names[e.tpl.name] || 0) + 1;
    const ek = JSON.stringify(names);
    if (ek !== this._ek) { this._ek = ek; this.enemyW.innerHTML = Object.entries(names).map(([n, c]) => `<div class="ename">${n}${c > 1 ? ` <small>x${c}</small>` : ''}</div>`).join(''); }
    for (const m of this.party) {
      const r = this.rows.get(m), key = `${m.hp}|${m.mp}|${this.actor === m}|${m.poison}`;
      if (r.key !== key) {
        r.key = key;
        r.name.classList.toggle('act', this.actor === m);
        r.r.classList.toggle('ko', m.hp <= 0);
        r.st.textContent = m.poison ? 'Racun' : '';
        r.hpTxt.innerHTML = `${m.hp}<small>/${m.s.maxHp}</small>`;
        r.php.className = 'php' + (m.hp <= 0 ? ' ko' : m.hp < m.s.maxHp * 0.25 ? ' low' : '');
        r.hpBar.style.width = (m.hp / m.s.maxHp * 100) + '%';
        r.mp.textContent = m.mp;
      }
      r.atb.style.width = m.atb + '%';
      r.atbBar.classList.toggle('ready', m.atb >= 100);
      r.burst.style.width = m.burst + '%';
      r.burstBar.classList.toggle('full', m.burst >= 100);
    }
  },

  teardown() {
    if (this.cmd) { this.cmd.destroy(); this.cmd = null; }
    if (this.ui) { this.ui.remove(); this.ui = null; }
    this.helpW = null; this.state = 'off'; this.cursor = null; this.actor = null;
    for (const m of G.party) { m.poison = false; m.defending = false; }
  },

  // ---------- Loop ----------
  update(dt) {
    this.t += dt;
    FX.update(dt);
    for (const b of [...this.party, ...this.enemies]) { b.v.flash = Math.max(0, b.v.flash - dt * 4); b.v.shake = Math.max(0, b.v.shake - dt); }
    this.updateUI();
    if (this.state !== 'run') return;
    for (const m of this.party) {
      if (m.hp <= 0 || m.atb >= 100) continue;
      m.atb = Math.min(100, m.atb + (m.s.spd + 25) * 0.9 * dt);
      if (m.atb >= 100) { this.ready.push(m); Snd.sfx('ready'); }
    }
    for (const e of this.enemies) if (!e.dead && e.atb < 100) e.atb = Math.min(100, e.atb + (e.spd + 25) * 0.9 * dt);
    const e = this.enemies.find(e => !e.dead && e.atb >= 100);
    if (e) { this.enemyTurn(e); return; }
    this.ready = this.ready.filter(m => m.hp > 0 && m.atb >= 100);
    if (this.ready.length) this.openCommand(this.ready[0]);
  },

  pos(b) { return b.isEnemy ? { x: b.x + b.v.ox, y: b.y + b.v.oy } : { x: b.bx + b.v.ox, y: b.by + b.v.oy }; },
  aliveEnemies() { return this.enemies.filter(e => !e.dead); },
  randomEnemy() { const a = this.aliveEnemies(); return a.length ? pick(a) : null; },

  // ---------- Perintah pemain ----------
  openCommand(m) {
    this.state = 'menu'; this.actor = m; m.defending = false;
    Tween.to(m.v, { ox: -26 }, 140);
    this.showCommands(m);
  },

  showCommands(m) {
    if (this.cmd) this.cmd.destroy();
    const items = [];
    if (m.burst >= 100) items.push({ label: `<span class="burst-txt">${BURSTS[m.id].name}</span>`, value: 'burst', help: BURSTS[m.id].desc });
    items.push({ label: 'Serang', value: 'attack', help: CMD_HELP.attack });
    items.push({ label: CHARS[m.id].skillLabel, value: 'skill', disabled: !skillsOf(m).length, help: `Gunakan ${CHARS[m.id].skillLabel.toLowerCase()} (memakai MP).` });
    items.push({ label: 'Item', value: 'item', disabled: !Object.keys(G.items).length, help: CMD_HELP.item });
    items.push({ label: 'Bertahan', value: 'defend', help: CMD_HELP.defend });
    items.push({ label: 'Kabur', value: 'flee', disabled: this.boss, help: this.boss ? 'Tidak bisa kabur dari pertarungan ini!' : CMD_HELP.flee });
    this.cmd = new ListMenu(this.cmdBox, items, { onSelect: it => this.onCommand(m, it.value), onMove: it => this.help(`${CHARS[m.id].name}: ${it.help}`) });
  },

  closeCommand() { if (this.cmd) { this.cmd.destroy(); this.cmd = null; } },

  async onCommand(m, v) {
    this.cmd.deactivate();
    let act = null, targets = null;
    if (v === 'attack') { targets = await this.selectTargets('enemy', m); act = { type: 'attack' }; }
    else if (v === 'burst') { targets = await this.selectTargets(BURSTS[m.id].target, m); act = { type: 'burst' }; }
    else if (v === 'defend') { targets = []; act = { type: 'defend' }; }
    else if (v === 'flee') { targets = []; act = { type: 'flee' }; }
    else if (v === 'skill') {
      const r = await this.chooseFromList(m, skillsOf(m).map(id => ({ label: SKILLS[id].name, right: SKILLS[id].mp, value: id, disabled: m.mp < SKILLS[id].mp, help: SKILLS[id].desc })), id => SKILLS[id].target, 'lastSkill');
      if (r) { act = { type: 'skill', id: r.id }; targets = r.targets; }
    } else if (v === 'item') {
      const r = await this.chooseFromList(m, Object.keys(G.items).map(id => ({ label: ITEMS[id].name, right: 'x' + G.items[id], value: id, help: ITEMS[id].desc })), id => ITEMS[id].effect.revive ? 'deadAlly' : 'ally', 'lastItem');
      if (r) { act = { type: 'item', id: r.id }; targets = r.targets; }
    }
    if (!targets) { this.cmd.activate(); return; }
    this.closeCommand();
    await this.perform(m, act, targets);
  },

  // Daftar skill/item, lalu pilih target. Batal di target kembali ke daftar.
  async chooseFromList(m, items, targetOf, memKey) {
    while (true) {
      const id = await new Promise(res => {
        const w = UI.win('bsub', 6, 374, 424, 160, this.ui);
        const lm = new ListMenu(w, items, {
          cols: 2, start: m[memKey] || 0,
          onMove: it => this.help(it.help),
          onSelect: (it, i) => { m[memKey] = i; lm.destroy(); w.remove(); res(it.value); },
          onCancel: () => { lm.destroy(); w.remove(); this.help(''); res(null); },
        });
      });
      if (!id) return null;
      const targets = await this.selectTargets(targetOf(id), m);
      if (targets) return { id, targets };
    }
  },

  selectTargets(kind, actor) {
    let cands, multi = false;
    const aliveP = this.party.filter(p => p.hp > 0);
    switch (kind) {
      case 'enemy': cands = this.aliveEnemies(); break;
      case 'enemies': case 'randomEnemies': cands = this.aliveEnemies(); multi = true; break;
      case 'ally': cands = aliveP; break;
      case 'allies': cands = aliveP; multi = true; break;
      case 'allAllies': cands = this.party.slice(); multi = true; break;
      case 'deadAlly': cands = this.party.filter(p => p.hp <= 0); break;
      case 'self': cands = [actor]; break;
      default: cands = [];
    }
    if (!cands.length) { Snd.sfx('buzz'); this.help('Tidak ada target yang bisa dipilih.'); return Promise.resolve(null); }
    let idx = 0;
    if (kind === 'ally') idx = cands.indexOf(cands.slice().sort((a, b) => a.hp / a.s.maxHp - b.hp / b.s.maxHp)[0]);
    const label = () => multi ? (cands[0].isEnemy ? 'Semua musuh' : 'Semua kawan') : cands[idx].isEnemy ? cands[idx].name : CHARS[cands[idx].id].name;
    return new Promise(res => {
      const done = r => { Input.pop(h); this.cursor = null; this.clickHandler = null; Snd.sfx(r ? 'ok' : 'cancel'); res(r); };
      const h = {
        onKey: a => {
          if (a === 'ok') done(multi ? cands : [cands[idx]]);
          else if (a === 'cancel') done(null);
          else if (!multi && cands.length > 1 && ['up', 'down', 'left', 'right'].includes(a)) {
            idx = (idx + (a === 'up' || a === 'left' ? -1 : 1) + cands.length) % cands.length;
            Snd.sfx('cursor'); this.cursor = [cands[idx]]; this.help(label());
          }
        },
      };
      this.cursor = multi ? cands : [cands[idx]];
      this.help(label());
      this.clickHandler = (x, y) => {
        const hit = cands.find(b => { const p = this.pos(b), hw = b.isEnemy ? b.w / 2 : 32, hh = b.isEnemy ? b.h / 2 : 36; return Math.abs(x - p.x) < hw && Math.abs(y - p.y) < hh; });
        if (hit) done(multi ? cands : [hit]);
      };
      Input.push(h);
    });
  },

  // ---------- Eksekusi aksi ----------
  async perform(m, act, targets) {
    this.state = 'anim';
    if (act.type === 'attack') { this.help(''); await this.physAttack(m, targets[0], { power: 1, fx: 'slash' }); }
    else if (act.type === 'skill') { const sk = SKILLS[act.id]; m.mp -= sk.mp; this.help(sk.name); await this.useSkill(m, sk, targets); }
    else if (act.type === 'burst') {
      const sk = BURSTS[m.id]; m.burst = 0; this.help(`${CHARS[m.id].name}: ${sk.name}!`);
      FX.flash = 0.8; FX.flashColor = '#ffd0e8'; Snd.sfx('burst'); await Tween.wait(300);
      await this.useSkill(m, sk, targets);
    }
    else if (act.type === 'item') { removeItem(act.id); this.help(ITEMS[act.id].name); await this.useItem(m, act.id, targets[0]); }
    else if (act.type === 'defend') {
      m.defending = true; this.help(`${CHARS[m.id].name} bertahan`); Snd.sfx('defend');
      const p = this.pos(m); FX.ring(p.x, p.y, { r1: 50, color: '#9fd8ff' }); await Tween.wait(450);
    }
    else if (act.type === 'flee') { if (await this.tryFlee()) return; }
    this.help('');
    await Tween.to(m.v, { ox: 0, oy: 0 }, 140);
    m.atb = 0; this.ready = this.ready.filter(x => x !== m); this.actor = null;
    if (m.poison && m.hp > 0) {
      const d = Math.max(1, Math.floor(m.s.maxHp * 0.06));
      m.hp = Math.max(1, m.hp - d);
      const p = this.pos(m); FX.pop(p.x, p.y - 10, d, '#d48cff'); Snd.sfx('spore');
      await Tween.wait(350);
    }
    if (!this.checkEnd()) this.state = 'run';
  },

  async physAttack(m, t, o) {
    if (!t || t.dead) t = this.randomEnemy();
    if (!t) return;
    await Tween.to(m.v, { ox: t.x + t.w / 2 + 30 - m.bx, oy: (t.y - m.by) * 0.5 }, 220);
    const hits = o.hits || 1;
    for (let i = 0; i < hits; i++) {
      const tt = t.dead ? this.randomEnemy() : t;
      if (!tt) break;
      await this.fx(o.fx || 'slash', [tt], m);
      this.hitEnemy(tt, physDamage(m.s.atk, tt.def, o.power), o.elem, true);
      if (hits > 1) await Tween.wait(110);
    }
    await Tween.wait(220);
    await Tween.to(m.v, { ox: -26, oy: 0 }, 220);
  },

  async useSkill(m, sk, targets) {
    switch (sk.kind) {
      case 'phys': {
        if (sk.target === 'enemy') { await this.physAttack(m, targets[0], sk); return; }
        if (sk.target === 'randomEnemies') {
          await Tween.to(m.v, { ox: -300, oy: 0 }, 240);
          for (let i = 0; i < sk.hits; i++) {
            const t = this.randomEnemy();
            if (!t) break;
            await this.fx(sk.fx, [t], m);
            this.hitEnemy(t, physDamage(m.s.atk, t.def, sk.power), sk.elem, true);
            await Tween.wait(120);
          }
          await Tween.wait(200);
          return;
        }
        await Tween.to(m.v, { ox: -140 }, 200);
        const live = targets.filter(t => !t.dead);
        await this.fx(sk.fx, live, m);
        for (const t of live) this.hitEnemy(t, physDamage(m.s.atk, t.def, sk.power), sk.elem, true);
        await Tween.wait(350);
        return;
      }
      case 'mag': {
        await this.castAnim(m);
        const live = targets.filter(t => !t.dead);
        if (!live.length) { const r = this.randomEnemy(); if (r) live.push(r); }
        await this.fx(sk.fx, live, m);
        for (const t of live) this.hitEnemy(t, magDamage(m.s.matk, t.def, sk.power), sk.elem, false);
        await Tween.wait(350);
        return;
      }
      case 'heal': {
        await this.castAnim(m);
        const live = targets.filter(t => t.hp > 0);
        await this.fx('heal', live, m);
        const amt = healPower(m, sk);
        for (const t of live) this.healTarget(t, amt);
        await Tween.wait(350);
        return;
      }
      case 'revive': {
        await this.castAnim(m);
        const dead = targets.filter(t => t.hp <= 0);
        await this.fx('revive', dead, m);
        for (const t of dead) this.reviveTarget(t, sk.power);
        await Tween.wait(350);
        return;
      }
      case 'fullheal': {
        await this.castAnim(m);
        await this.fx('holy', this.party, m);
        for (const t of this.party) { if (t.hp <= 0) this.reviveTarget(t, 1); else this.healTarget(t, t.s.maxHp - t.hp); t.poison = false; }
        await Tween.wait(400);
        return;
      }
    }
  },

  async useItem(m, id, t) {
    await Tween.to(m.v, { oy: -12 }, 120); await Tween.to(m.v, { oy: 0 }, 120, 'in');
    const ef = ITEMS[id].effect;
    await this.fx(ef.revive ? 'revive' : 'heal', [t], m);
    const r = applyItem(id, t), p = this.pos(t);
    if (r.revived) { FX.pop(p.x, p.y - 40, 'Bangkit!', '#ffe080', 18); t.atb = 0; }
    if (r.hp) FX.pop(p.x, p.y - 10, r.hp, '#7dff8a');
    if (r.mp) FX.pop(p.x, p.y - 10, r.mp + ' MP', '#8ccaff');
    if (r.cured) FX.pop(p.x, p.y - 40, 'Sembuh', '#e0c0ff', 18);
    if (!r.revived && !r.hp && !r.mp && !r.cured) FX.pop(p.x, p.y - 10, 'Tidak berefek', '#c0c0c0', 16);
    await Tween.wait(400);
  },

  async castAnim(m) {
    Snd.sfx('cast');
    const p = this.pos(m);
    await Tween.to(m.v, { oy: -10 }, 150);
    for (let i = 0; i < 16; i++) FX.spawn(p.x + rand(-30, 30), p.y + rand(-30, 30), { vx: 0, vy: rand(-90, -30), life: .5, color: pick(['#fff', '#cfe8ff', '#ffe9a0']), size: 3, shape: 'star' });
    m.v.flash = 0.6;
    await Tween.wait(280);
    await Tween.to(m.v, { oy: 0 }, 120);
  },

  hitEnemy(t, base, elem, phys) {
    if (t.dead) return;
    let dmg = base * rand(0.9, 1.1), tag = null;
    const weak = t.tpl.weak || [], res = t.tpl.resist || [];
    if (elem && weak.includes(elem)) { dmg *= 2; tag = ['LEMAH!', '#ffe040']; }
    else if (elem && res.includes(elem)) { dmg *= 0.5; tag = ['TAHAN', '#a8a8c8']; }
    if (phys && Math.random() < 0.08) { dmg *= 1.8; tag = ['KRITIS!', '#ff9040']; }
    dmg = Math.max(1, Math.round(dmg));
    t.hp = Math.max(0, t.hp - dmg); t.v.flash = 1; t.v.shake = 0.25;
    const p = this.pos(t);
    FX.pop(p.x, p.y - 10, dmg, '#ffffff');
    if (tag) FX.pop(p.x, p.y - t.h / 2 - 6, tag[0], tag[1], 17);
    Snd.sfx(tag && tag[0] === 'KRITIS!' ? 'crit' : 'hit');
    if (t.hp <= 0) this.killEnemy(t);
  },

  killEnemy(t) {
    t.dead = true; t.atb = 0;
    Snd.sfx('enemyDie');
    const p = this.pos(t);
    FX.burst(p.x, p.y, t.tpl.boss ? 90 : 30, ['#ffffff', '#e0d0ff', '#a080ff'], { max: t.tpl.boss ? 320 : 140, lmax: .9, smax: 6 });
    Tween.to(t.v, { alpha: 0 }, t.tpl.boss ? 1600 : 600);
  },

  hitParty(m, base, act = {}) {
    if (m.hp <= 0) return 0;
    let dmg = base * rand(0.9, 1.1);
    if (m.defending) dmg *= 0.5;
    dmg = Math.max(1, Math.round(dmg));
    m.hp = Math.max(0, m.hp - dmg); m.v.flash = 1; m.v.shake = 0.25;
    m.burst = Math.min(100, m.burst + dmg / m.s.maxHp * 140);
    const p = this.pos(m);
    FX.pop(p.x, p.y - 10, dmg, '#ffffff');
    Snd.sfx('hurt');
    if (m.hp <= 0) {
      m.atb = 0; m.poison = false; m.defending = false;
      FX.pop(p.x, p.y - 44, 'KO', '#ff6a6a', 18);
      this.ready = this.ready.filter(x => x !== m);
    } else if (act.poison && !m.poison && Math.random() < act.poison) {
      m.poison = true; FX.pop(p.x, p.y - 44, 'Racun!', '#d48cff', 17);
    }
    return dmg;
  },

  healTarget(t, amt) {
    if (t.hp <= 0) return;
    const b = t.hp; t.hp = Math.min(t.s.maxHp, t.hp + amt);
    const p = this.pos(t); FX.pop(p.x, p.y - 10, t.hp - b, '#7dff8a');
  },

  reviveTarget(t, ratio) {
    if (t.hp > 0) return;
    t.hp = Math.max(1, Math.floor(t.s.maxHp * ratio)); t.atb = 0;
    const p = this.pos(t); FX.pop(p.x, p.y - 10, t.hp, '#7dff8a'); FX.pop(p.x, p.y - 44, 'Bangkit!', '#ffe080', 17);
  },

  // ---------- Giliran musuh ----------
  async enemyTurn(e) {
    this.state = 'anim';
    const acts = e.tpl.actions;
    let roll = Math.random() * acts.reduce((s, a) => s + a.w, 0), act = acts[0];
    for (const a of acts) { roll -= a.w; if (roll <= 0) { act = a; break; } }
    const alive = this.party.filter(m => m.hp > 0);
    const targets = act.target === 'all' ? alive : [pick(alive)];
    this.help(`${e.name}: ${act.name}`, true);
    if (act.kind === 'phys' && act.target !== 'all') {
      const t = targets[0];
      await Tween.to(e.v, { ox: 60 }, 150);
      await this.fx(act.fx || 'claw', targets, e);
      const d = this.hitParty(t, physDamage(e.atk, t.s.def, act.power), act);
      if (act.drain && d) { const h = Math.floor(d * 0.5); e.hp = Math.min(e.maxHp, e.hp + h); const p = this.pos(e); FX.pop(p.x, p.y - 10, h, '#7dff8a'); }
      await Tween.to(e.v, { ox: 0 }, 200);
    } else {
      await this.enemyCast(e);
      await this.fx(act.fx || 'magic', targets, e);
      for (const t of targets) this.hitParty(t, act.kind === 'phys' ? physDamage(e.atk, t.s.def, act.power) : magDamage(e.mag, t.s.def, act.power), act);
    }
    await Tween.wait(450);
    this.help('');
    e.atb = 0;
    if (!this.checkEnd()) this.state = 'run';
  },

  async enemyCast(e) {
    Snd.sfx('cast');
    const p = this.pos(e);
    for (let i = 0; i < 20; i++) FX.spawn(p.x + rand(-40, 40), p.y + rand(-40, 40), { vx: 0, vy: rand(-80, -20), life: .5, color: pick(['#ffb0b0', '#ff6060', '#ffffff']), size: 3, shape: 'star' });
    e.v.flash = 0.7;
    await Tween.wait(350);
  },

  async tryFlee() {
    this.help('Mencoba kabur...');
    await Tween.wait(400);
    if (Math.random() < 0.65) {
      Snd.sfx('flee'); this.help('Berhasil kabur!');
      this.party.forEach(m => { if (m.hp > 0) Tween.to(m.v, { ox: 320 }, 500); });
      await Tween.wait(650);
      this.state = 'end';
      this.resolve('flee');
      return true;
    }
    Snd.sfx('buzz'); this.help('Gagal kabur!');
    await Tween.wait(650);
    return false;
  },

  checkEnd() {
    if (this.enemies.every(e => e.dead)) { this.victory(); return true; }
    if (this.party.every(m => m.hp <= 0)) { this.defeat(); return true; }
    return false;
  },

  async victory() {
    this.state = 'end'; this.closeCommand(); this.help(''); this.actor = null;
    await Tween.wait(this.boss ? 1800 : 800);
    Snd.play('victory');
    const xp = this.enemies.reduce((s, e) => s + e.tpl.xp, 0), gold = this.enemies.reduce((s, e) => s + e.tpl.gold, 0);
    const drops = [];
    for (const e of this.enemies) if (e.tpl.drop && Math.random() < e.tpl.drop[1]) drops.push(e.tpl.drop[0]);
    G.gold += gold;
    drops.forEach(d => addItem(d, 1));
    const lines = [];
    for (const m of this.party) if (m.hp > 0) lines.push(...gainXp(m, xp));
    for (const m of this.party) { if (m.hp <= 0) m.hp = 1; m.poison = false; m.defending = false; }
    this.party.forEach(m => (async () => {
      await Tween.to(m.v, { ox: 0 }, 150);
      for (let i = 0; i < 2; i++) { await Tween.to(m.v, { oy: -20 }, 170); await Tween.to(m.v, { oy: 0 }, 170, 'in'); }
    })());
    const w = UI.win('victory', 250, 60, 460, null, this.ui);
    w.innerHTML = `<div class="vtitle">KEMENANGAN!</div>
      <div class="vrow"><span>EXP didapat</span><b>${xp}</b></div>
      <div class="vrow"><span>Gold didapat</span><b>${gold}</b></div>
      ${drops.length ? `<div class="vrow"><span>Item</span><b>${drops.map(d => ITEMS[d].name).join(', ')}</b></div>` : ''}
      ${lines.map(l => `<div class="vlvl">★ ${l}</div>`).join('')}
      <div class="vhint">Tekan Enter ▶</div>`;
    if (lines.length) setTimeout(() => Snd.sfx('levelup'), 300);
    await Tween.wait(500);
    await waitOk();
    this.resolve('win');
  },

  async defeat() {
    this.state = 'end'; this.closeCommand(); this.actor = null;
    this.help('Seluruh party tumbang...');
    await Tween.wait(1500);
    this.resolve('lose');
  },

  // ---------- Efek per jenis skill ----------
  async fx(kind, targets, src) {
    const P = targets.map(t => this.pos(t));
    switch (kind) {
      case 'slash':
        Snd.sfx('slash');
        P.forEach(p => { FX.line(p.x - 34, p.y - 34, p.x + 34, p.y + 34, { w: 5 }); FX.burst(p.x, p.y, 6, ['#fff', '#d8e8ff']); });
        await Tween.wait(120); break;
      case 'slash2':
        Snd.sfx('slash');
        P.forEach(p => { FX.line(p.x - 40, p.y - 40, p.x + 40, p.y + 40, { w: 6 }); FX.line(p.x + 40, p.y - 40, p.x - 40, p.y + 40, { w: 6, life: .35 }); FX.burst(p.x, p.y, 14, ['#fff', '#cfe8ff']); });
        await Tween.wait(160); break;
      case 'slashAll':
        for (const p of P) { Snd.sfx('slash'); FX.line(p.x - 44, p.y + 30, p.x + 44, p.y - 30, { w: 6, color: '#cfe8ff' }); FX.burst(p.x, p.y, 12, ['#fff', '#9fd0ff']); await Tween.wait(80); }
        await Tween.wait(120); break;
      case 'burstSlash':
        Snd.sfx('crit'); FX.flash = 1; FX.flashColor = '#fff4d0'; FX.shake = 12;
        P.forEach(p => {
          for (let i = 0; i < 6; i++) FX.line(p.x + rand(-70, 70), p.y - 80, p.x + rand(-70, 70), p.y + 80, { w: 7, color: pick(['#fff', '#ffe080', '#ffb040']), life: .55 });
          FX.burst(p.x, p.y, 50, ['#fff', '#ffe080', '#ff9040'], { max: 300, smax: 7 });
          FX.ring(p.x, p.y, { r1: 140, color: '#ffe080', life: .5 });
        });
        await Tween.wait(320); break;
      case 'punch':
        Snd.sfx('punch');
        P.forEach(p => { const x = p.x + rand(-18, 18), y = p.y + rand(-18, 18); FX.burst(x, y, 12, ['#fff', '#ffe060', '#ffa030'], { max: 180, lmax: .35 }); FX.ring(x, y, { r1: 32, life: .2 }); });
        await Tween.wait(80); break;
      case 'claw':
        Snd.sfx('slash');
        P.forEach(p => { for (let i = -1; i <= 1; i++) FX.line(p.x - 22 + i * 11, p.y - 30, p.x + 8 + i * 11, p.y + 30, { w: 3, color: '#ff9090' }); });
        await Tween.wait(120); break;
      case 'fire':
        Snd.sfx('fire');
        for (let k = 0; k < 7; k++) {
          P.forEach(p => { for (let i = 0; i < 6; i++) FX.spawn(p.x + rand(-30, 30), p.y + rand(0, 34), { vx: rand(-20, 20), vy: rand(-190, -80), life: rand(.4, .7), color: pick(['#fff0a0', '#ffb030', '#ff6020', '#e02010']), size: rand(4, 9) }); });
          await Tween.wait(50);
        }
        FX.flash = 0.25; FX.flashColor = '#ff9a50'; break;
      case 'ice':
        Snd.sfx('ice');
        P.forEach(p => { for (let i = 0; i < 16; i++) { const a = rand(0, Math.PI * 2), d = rand(60, 90); FX.spawn(p.x + Math.cos(a) * d, p.y + Math.sin(a) * d, { vx: -Math.cos(a) * d * 3, vy: -Math.sin(a) * d * 3, life: .33, color: pick(['#ffffff', '#bff0ff', '#6ad0ff']), size: rand(5, 8), shape: 'dia' }); } });
        await Tween.wait(330);
        P.forEach(p => FX.burst(p.x, p.y, 22, ['#fff', '#bff0ff', '#6ad0ff'], { shape: 'dia', smax: 7 }));
        FX.flash = 0.25; FX.flashColor = '#c8f4ff'; break;
      case 'thunder':
        Snd.sfx('thunder');
        P.forEach(p => { FX.bolt(p.x, p.y); FX.bolt(p.x + 10, p.y); FX.burst(p.x, p.y, 18, ['#fff', '#fff6a0', '#a0c8ff']); });
        FX.flash = 0.7; FX.flashColor = '#fffbe0';
        await Tween.wait(200); break;
      case 'wind':
        Snd.sfx('wind');
        for (let k = 0; k < 9; k++) {
          P.forEach(p => { const a = k * 0.8; FX.spawn(p.x + Math.cos(a) * 44, p.y + Math.sin(a) * 22, { vx: -Math.sin(a) * 170, vy: Math.cos(a) * 80 - 40, life: .5, color: pick(['#d0ffd8', '#80e0a0', '#ffffff']), size: 4 }); });
          await Tween.wait(40);
        }
        break;
      case 'meteor':
        Snd.sfx('meteor');
        for (const p of P) { for (let i = 0; i < 3; i++) FX.spawn(p.x - 160 + rand(-30, 30), p.y - 260, { vx: 355, vy: 578, life: .45, color: '#ffa050', size: 12, trail: true }); await Tween.wait(90); }
        await Tween.wait(380);
        FX.shake = 14; FX.flash = 0.6; FX.flashColor = '#ffd6a8';
        P.forEach(p => FX.burst(p.x, p.y, 34, ['#ffe0a0', '#ff8030', '#a04020', '#604030'], { max: 230, smax: 7 }));
        break;
      case 'heal':
        Snd.sfx('heal');
        for (let k = 0; k < 5; k++) {
          P.forEach(p => { for (let i = 0; i < 4; i++) FX.spawn(p.x + rand(-28, 28), p.y + rand(-10, 32), { vx: 0, vy: rand(-90, -40), life: .7, color: pick(['#ffffff', '#b0ffb0', '#60e080']), size: rand(3, 6), shape: 'star' }); });
          await Tween.wait(60);
        }
        break;
      case 'revive':
        Snd.sfx('revive');
        for (let k = 0; k < 6; k++) {
          P.forEach(p => { for (let i = 0; i < 5; i++) FX.spawn(p.x + rand(-14, 14), p.y + 40, { vx: rand(-10, 10), vy: rand(-260, -160), life: .6, color: pick(['#fff6c0', '#ffe060', '#ffffff']), size: rand(3, 5), shape: 'star' }); });
          await Tween.wait(60);
        }
        P.forEach(p => FX.ring(p.x, p.y, { r1: 70, color: '#ffe080' }));
        break;
      case 'holy':
        Snd.sfx('holy'); FX.flash = 1; FX.flashColor = '#ffffff';
        P.forEach(p => { FX.ring(p.x, p.y, { r1: 90, color: '#fff6c0', life: .6 }); for (let i = 0; i < 24; i++) FX.spawn(p.x + rand(-34, 34), p.y + rand(-34, 34), { vx: 0, vy: rand(-120, -40), life: rand(.6, 1), color: pick(['#fff', '#fff6a0', '#ffe060']), size: rand(3, 6), shape: 'star' }); });
        await Tween.wait(500); break;
      case 'spore':
        Snd.sfx('spore');
        for (let k = 0; k < 6; k++) {
          P.forEach(p => FX.spawn(p.x + rand(-32, 32), p.y + rand(-20, 30), { vx: rand(-20, 20), vy: rand(-40, -10), life: .8, color: pick(['rgba(200,112,224,0.8)', 'rgba(144,64,176,0.8)', 'rgba(224,160,255,0.8)']), size: rand(6, 12), shape: 'circ' }));
          await Tween.wait(60);
        }
        break;
      case 'mist': {
        Snd.sfx('mist');
        const sx = src ? this.pos(src).x : 250;
        for (let k = 0; k < 16; k++) { FX.spawn(sx, rand(60, 340), { vx: rand(650, 800), vy: rand(-20, 20), life: .9, color: pick(['rgba(210,190,240,0.75)', 'rgba(150,130,190,0.75)']), size: rand(16, 28), shape: 'circ' }); await Tween.wait(35); }
        await Tween.wait(250);
        FX.flash = 0.35; FX.flashColor = '#d8c8f0';
        break;
      }
      case 'quake':
        Snd.sfx('quake'); FX.shake = 16;
        P.forEach(p => FX.burst(p.x, p.y + 30, 18, ['#8a6a4a', '#5a4a3a', '#b09070'], { grav: 500, up: -150 }));
        await Tween.wait(320); break;
      default:
        Snd.sfx('magic');
        P.forEach(p => { FX.ring(p.x, p.y, { r1: 50, color: '#ffb0b0' }); FX.burst(p.x, p.y, 16, ['#fff', '#ffb0b0', '#ff6060']); });
        await Tween.wait(220);
    }
  },

  // ---------- Gambar ----------
  draw(ctx) {
    const sh = FX.shake > 0 ? (Math.random() - 0.5) * FX.shake : 0;
    ctx.save();
    ctx.translate(sh, sh * 0.5);
    ctx.drawImage(this.bg, 0, 0);
    const shadow = (x, y, w) => { ctx.fillStyle = 'rgba(0,0,0,0.3)'; ctx.beginPath(); ctx.ellipse(x, y, w, w * 0.22, 0, 0, Math.PI * 2); ctx.fill(); };
    for (const e of this.enemies.slice().sort((a, b) => a.y - b.y)) {
      if (e.v.alpha <= 0.01) continue;
      const bob = Math.sin(this.t * 2.2 + e.phase) * 3, shk = e.v.shake > 0 ? Math.sin(this.t * 90) * 6 : 0;
      const x = e.x + e.v.ox + shk, y = e.y + e.v.oy + bob;
      ctx.globalAlpha = e.v.alpha;
      shadow(e.x + e.v.ox, e.y + e.h / 2 - 2, e.w * 0.38);
      ctx.drawImage(e.img, Math.round(x - e.w / 2), Math.round(y - e.h / 2));
      if (e.v.flash > 0) { ctx.globalAlpha = e.v.flash * e.v.alpha; ctx.drawImage(e.white, Math.round(x - e.w / 2), Math.round(y - e.h / 2)); }
      ctx.globalAlpha = 1;
    }
    for (const m of this.party) {
      const shk = m.v.shake > 0 ? Math.sin(this.t * 90) * 5 : 0;
      const x = m.bx + m.v.ox + shk, y = m.by + m.v.oy;
      shadow(m.bx + m.v.ox, m.by + 34, 24);
      if (m.hp <= 0) {
        ctx.save(); ctx.globalAlpha = 0.65; ctx.translate(x, y + 24); ctx.rotate(-Math.PI / 2);
        ctx.filter = 'grayscale(0.7)'; ctx.drawImage(m.img, -32, -36); ctx.restore();
        continue;
      }
      const low = m.hp < m.s.maxHp * 0.25 ? 4 : 0;
      const breath = Math.sin(this.t * 3 + m.bx) * 1.2;
      ctx.drawImage(m.img, Math.round(x - 32), Math.round(y - 36 + low + breath));
      if (m.v.flash > 0) { ctx.globalAlpha = m.v.flash; ctx.drawImage(m.white, Math.round(x - 32), Math.round(y - 36 + low + breath)); ctx.globalAlpha = 1; }
      if (m.defending) { ctx.strokeStyle = 'rgba(150,210,255,0.6)'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(x - 6, y, 40, Math.PI * 0.6, Math.PI * 1.4); ctx.stroke(); }
      if (m.poison) { ctx.fillStyle = '#c070e0'; for (let i = 0; i < 3; i++) { const t = (this.t * 0.8 + i / 3) % 1; ctx.globalAlpha = 1 - t; ctx.beginPath(); ctx.arc(x + 18 + i * 4, y - 30 - t * 24, 3, 0, Math.PI * 2); ctx.fill(); } ctx.globalAlpha = 1; }
    }
    FX.draw(ctx);
    if (this.cursor) {
      for (const b of this.cursor) {
        const p = this.pos(b), top = b.isEnemy ? p.y - b.h / 2 - 12 : p.y - 46, bob = Math.sin(this.t * 10) * 4;
        ctx.fillStyle = '#fff'; ctx.strokeStyle = '#000'; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(p.x - 10, top - 16 + bob); ctx.lineTo(p.x + 10, top - 16 + bob); ctx.lineTo(p.x, top - 2 + bob); ctx.closePath(); ctx.fill(); ctx.stroke();
      }
    }
    ctx.restore();
    if (FX.flash > 0) { ctx.globalAlpha = Math.min(1, FX.flash) * 0.8; ctx.fillStyle = FX.flashColor; ctx.fillRect(0, 0, VIEW_W, VIEW_H); ctx.globalAlpha = 1; }
  },
};

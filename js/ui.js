"use strict";
// ============================================================
//  UI: jendela, menu daftar, dialog, fade
// ============================================================
const UI = {
  root: $('ui'),
  win(cls, x, y, w, h, parent) {
    const d = el('div', 'win' + (cls ? ' ' + cls : ''), null, parent || this.root);
    d.style.left = x + 'px'; d.style.top = y + 'px';
    if (w != null) d.style.width = w + 'px';
    if (h != null) d.style.height = h + 'px';
    return d;
  },
  clear() { this.root.innerHTML = ''; Input.stack.length = 0; },
};

const Fade = {
  el: $('fade'),
  set(op, color = '#000') { this.el.style.transition = 'none'; this.el.style.background = color; this.el.style.opacity = op; },
  async to(op, ms = 350, color = '#000') {
    this.el.style.background = color;
    this.el.style.transition = `opacity ${ms}ms linear`;
    void this.el.offsetWidth;
    this.el.style.opacity = op;
    await sleep(ms + 20);
  },
};

// Menu daftar yang bisa dipakai keyboard dan mouse.
class ListMenu {
  constructor(parent, items, o = {}) {
    this.o = o; this.items = items; this.idx = o.start || 0; this.cols = o.cols || 1; this.active = false;
    this.box = el('div', 'list' + (this.cols > 1 ? ' grid2' : '') + (o.cls ? ' ' + o.cls : ''), null, parent);
    this.render();
    if (!o.inactive) this.activate();
  }
  render() {
    this.box.innerHTML = '';
    if (this.idx >= this.items.length) this.idx = Math.max(0, this.items.length - 1);
    this.els = this.items.map((it, i) => {
      const d = el('div', 'menu-item' + (it.disabled ? ' disabled' : ''), null, this.box);
      el('span', 'l', it.label, d);
      if (it.right != null) el('span', 'r', it.right, d);
      d.onmouseenter = () => { if (this.active && this.idx !== i) { this.idx = i; this.update(); } };
      d.onclick = e => { e.stopPropagation(); if (!this.active) return; this.idx = i; this.update(); this.select(); };
      return d;
    });
    this.update();
  }
  update() {
    this.els.forEach((d, i) => d.classList.toggle('focus', this.active && i === this.idx));
    const it = this.items[this.idx];
    if (it && this.active && this.o.onMove) this.o.onMove(it, this.idx);
    const f = this.els[this.idx], b = this.box;
    if (f && b.scrollHeight > b.clientHeight) {
      if (f.offsetTop < b.scrollTop) b.scrollTop = f.offsetTop;
      else if (f.offsetTop + f.offsetHeight > b.scrollTop + b.clientHeight) b.scrollTop = f.offsetTop + f.offsetHeight - b.clientHeight;
    }
  }
  activate() { if (this.active) return; this.active = true; Input.push(this); this.update(); }
  deactivate() { if (!this.active) return; this.active = false; Input.pop(this); this.update(); }
  destroy() { this.deactivate(); this.box.remove(); }
  setItems(items) { this.items = items; this.render(); }
  move(d) {
    if (this.items.length < 2) return;
    this.idx = (this.idx + d + this.items.length) % this.items.length;
    Snd.sfx('cursor'); this.update();
  }
  select() {
    const it = this.items[this.idx];
    if (!it) return;
    if (it.disabled) { Snd.sfx('buzz'); return; }
    if (!this.o.silent) Snd.sfx('ok');
    if (this.o.onSelect) this.o.onSelect(it, this.idx);
  }
  onKey(a) {
    if (a === 'up') this.move(-this.cols);
    else if (a === 'down') this.move(this.cols);
    else if (a === 'left' && this.cols > 1) this.move(-1);
    else if (a === 'right' && this.cols > 1) this.move(1);
    else if (a === 'ok') this.select();
    else if (a === 'cancel' && this.o.onCancel) { Snd.sfx('cancel'); this.o.onCancel(); }
  }
}

// Tunggu tombol OK / klik.
function waitOk() {
  return new Promise(res => {
    const h = { onKey(a) { if (a === 'ok' || a === 'cancel') done(); } };
    const click = () => done();
    const done = () => { Input.pop(h); $('game').removeEventListener('click', click); res(); };
    Input.push(h);
    setTimeout(() => $('game').addEventListener('click', click), 50);
  });
}

// Dialog bertahap dengan efek mesin ketik. lines: string atau {s: pembicara, t: teks}
function say(lines) {
  return new Promise(res => {
    const box = UI.win('dialog', 40, 388, 880, 140);
    const name = el('div', 'dname', null, box), txt = el('div', 'dtext', null, box), more = el('div', 'dmore', '▼', box);
    let i = 0, typing = false, full = '', shown = 0, timer = null;
    const finish = () => { clearInterval(timer); typing = false; txt.textContent = full; more.style.visibility = 'visible'; };
    const showLine = () => {
      let L = lines[i];
      if (typeof L === 'string') L = { t: L };
      name.textContent = L.s || ''; name.style.display = L.s ? '' : 'none';
      full = L.t; shown = 0; typing = true; more.style.visibility = 'hidden';
      clearInterval(timer);
      timer = setInterval(() => { shown += 2; txt.textContent = full.slice(0, shown); if (shown >= full.length) finish(); }, 22);
    };
    const h = {
      onKey(a) {
        if (a !== 'ok' && a !== 'cancel') return;
        if (typing) { finish(); return; }
        i++;
        if (i >= lines.length) { Input.pop(h); box.remove(); res(); }
        else { Snd.sfx('cursor'); showLine(); }
      },
    };
    box.onclick = e => { e.stopPropagation(); h.onKey('ok'); };
    Input.push(h);
    showLine();
  });
}

// Pertanyaan dengan pilihan. Mengembalikan indeks pilihan atau -1 bila batal.
function ask(text, options) {
  return new Promise(res => {
    const box = UI.win('dialog', 40, 388, 880, 140);
    el('div', 'dtext', null, box).textContent = text;
    const cw = UI.win('choice', 700, 388 - 18 - options.length * 26, 220, null);
    const end = v => { m.destroy(); box.remove(); cw.remove(); res(v); };
    const m = new ListMenu(cw, options.map((o, i) => ({ label: o, value: i })), { onSelect: it => end(it.value), onCancel: () => end(-1) });
  });
}

function toast(text, ms = 1800) {
  const t = UI.win('toast', 0, 14, null, null);
  t.style.left = '50%';
  t.textContent = text;
  setTimeout(() => { t.style.opacity = 0; setTimeout(() => t.remove(), 450); }, ms);
}

function banner(text) {
  const b = UI.win('banner', 0, 22, null, null);
  b.style.left = '50%';
  b.textContent = text;
  setTimeout(() => { b.style.opacity = 0; setTimeout(() => b.remove(), 900); }, 1800);
}

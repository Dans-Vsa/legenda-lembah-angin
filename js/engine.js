"use strict";
// ============================================================
//  Engine: utilitas, tween, input, dan audio chiptune (WebAudio)
// ============================================================
const $ = id => document.getElementById(id);
const rand = (a, b) => a + Math.random() * (b - a);
const randi = (a, b) => Math.floor(rand(a, b + 1));
const pick = a => a[Math.floor(Math.random() * a.length)];
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const sleep = ms => new Promise(r => setTimeout(r, ms));
const VIEW_W = 960, VIEW_H = 540;

function mulberry32(a) {
  return function () {
    a |= 0; a = a + 0x6D2B79F5 | 0;
    let t = Math.imul(a ^ a >>> 15, 1 | a);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}
function hash2(x, y) {
  let h = Math.imul(x, 374761393) + Math.imul(y, 668265263);
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return (h ^ (h >>> 16)) >>> 0;
}
function el(tag, cls, html, parent) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (html != null) e.innerHTML = html;
  if (parent) parent.appendChild(e);
  return e;
}

// ---------- Tween (berjalan di loop utama) ----------
const Tween = {
  list: [],
  to(obj, props, ms, ease = 'out') {
    return new Promise(res => {
      const from = {};
      for (const k in props) from[k] = obj[k];
      this.list.push({ obj, from, props, ms: Math.max(1, ms), t: 0, ease, res });
    });
  },
  wait(ms) { return new Promise(res => this.list.push({ obj: null, ms: Math.max(1, ms), t: 0, res })); },
  update(dt) {
    const list = this.list;
    for (let i = list.length - 1; i >= 0; i--) {
      const tw = list[i];
      tw.t += dt * 1000;
      const k = Math.min(1, tw.t / tw.ms);
      if (tw.obj) {
        const e = tw.ease === 'linear' ? k : tw.ease === 'in' ? k * k : 1 - (1 - k) * (1 - k);
        for (const p in tw.props) tw.obj[p] = tw.from[p] + (tw.props[p] - tw.from[p]) * e;
      }
      if (k >= 1) { list.splice(i, 1); tw.res(); }
    }
  },
};

// ---------- Input (tumpukan handler: yang paling atas menerima tombol) ----------
const KEYMAP = {
  ArrowUp: 'up', KeyW: 'up', ArrowDown: 'down', KeyS: 'down',
  ArrowLeft: 'left', KeyA: 'left', ArrowRight: 'right', KeyD: 'right',
  Enter: 'ok', Space: 'ok', KeyZ: 'ok', NumpadEnter: 'ok',
  Escape: 'cancel', KeyX: 'cancel', Backspace: 'cancel',
  Tab: 'menu', KeyM: 'mute',
};
const Input = {
  held: new Set(),
  stack: [],
  push(h) { this.stack.push(h); return h; },
  pop(h) { const i = this.stack.lastIndexOf(h); if (i >= 0) this.stack.splice(i, 1); },
  top() { return this.stack[this.stack.length - 1]; },
  isHeld(a) { return this.held.has(a); },
};
addEventListener('keydown', e => {
  const a = KEYMAP[e.code];
  if (!a) return;
  e.preventDefault();
  Snd.unlock();
  if (a === 'mute') { if (!e.repeat) Snd.toggleMute(); return; }
  Input.held.add(a);
  if (e.repeat && (a === 'ok' || a === 'cancel' || a === 'menu')) return;
  const t = Input.top();
  if (t && t.onKey) t.onKey(a);
});
addEventListener('keyup', e => { const a = KEYMAP[e.code]; if (a) Input.held.delete(a); });
addEventListener('blur', () => Input.held.clear());
addEventListener('pointerdown', () => Snd.unlock());

// ---------- Audio ----------
const Snd = {
  ctx: null, song: null, pending: null, tracks: [],
  muted: (() => { try { return localStorage.getItem('lla_mute') === '1'; } catch (e) { return false; } })(),
  unlock() {
    if (this.ctx) { if (this.ctx.state === 'suspended') this.ctx.resume(); return; }
    const C = window.AudioContext || window.webkitAudioContext;
    if (!C) return;
    this.ctx = new C();
    this.master = this.ctx.createGain(); this.master.gain.value = this.muted ? 0 : 1; this.master.connect(this.ctx.destination);
    this.musicGain = this.ctx.createGain(); this.musicGain.gain.value = 0.11; this.musicGain.connect(this.master);
    this.sfxGain = this.ctx.createGain(); this.sfxGain.gain.value = 0.3; this.sfxGain.connect(this.master);
    const len = this.ctx.sampleRate;
    this.noiseBuf = this.ctx.createBuffer(1, len, len);
    const d = this.noiseBuf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    setInterval(() => this.schedule(), 50);
    const p = this.pending; this.pending = null;
    if (p) this.play(p);
  },
  toggleMute() {
    this.muted = !this.muted;
    try { localStorage.setItem('lla_mute', this.muted ? '1' : '0'); } catch (e) { /* abaikan */ }
    if (this.master) this.master.gain.value = this.muted ? 0 : 1;
    $('mute').classList.toggle('off', this.muted);
  },
  freq(n) {
    const m = /^([A-G])(#|b)?(-?\d)$/.exec(n);
    const base = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 }[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0);
    return 440 * Math.pow(2, ((+m[3] + 1) * 12 + base - 69) / 12);
  },
  tone(f, start, dur, type, vol, dest, slideTo) {
    const o = this.ctx.createOscillator(), g = this.ctx.createGain();
    o.type = type;
    o.frequency.setValueAtTime(f, start);
    if (slideTo) o.frequency.exponentialRampToValueAtTime(Math.max(20, slideTo), start + dur);
    g.gain.setValueAtTime(0.0001, start);
    g.gain.exponentialRampToValueAtTime(vol, start + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, start + Math.max(0.03, dur));
    o.connect(g); g.connect(dest);
    o.start(start); o.stop(start + dur + 0.05);
  },
  noise(start, dur, vol, freq, type = 'lowpass') {
    const s = this.ctx.createBufferSource(); s.buffer = this.noiseBuf;
    const f = this.ctx.createBiquadFilter(); f.type = type; f.frequency.value = freq;
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(vol, start); g.gain.exponentialRampToValueAtTime(0.001, start + dur);
    s.connect(f); f.connect(g); g.connect(this.sfxGain);
    s.start(start); s.stop(start + dur + 0.05);
  },
  sfx(name) {
    if (!this.ctx) return;
    const t = this.ctx.currentTime, d = this.sfxGain;
    const T = (f, s, dur, type, vol, slide) => this.tone(f, t + s, dur, type, vol, d, slide);
    const arp = (notes, step, dur, type, vol) => notes.forEach((n, i) => T(this.freq(n), i * step, dur, type, vol));
    switch (name) {
      case 'cursor': T(1046, 0, .04, 'square', .1); break;
      case 'ok': T(784, 0, .05, 'square', .13); T(1175, .05, .07, 'square', .13); break;
      case 'cancel': T(587, 0, .05, 'square', .11); T(392, .05, .07, 'square', .11); break;
      case 'buzz': T(140, 0, .16, 'square', .15); break;
      case 'menu': T(659, 0, .05, 'triangle', .2); T(988, .05, .08, 'triangle', .2); break;
      case 'ready': T(1568, 0, .06, 'triangle', .12); T(2093, .05, .08, 'triangle', .1); break;
      case 'slash': this.noise(t, .12, .35, 5000, 'highpass'); T(900, 0, .1, 'sawtooth', .06, 200); break;
      case 'hit': this.noise(t, .12, .5, 1500); T(160, 0, .1, 'square', .15, 60); break;
      case 'crit': this.noise(t, .22, .7, 2500); T(240, 0, .18, 'square', .2, 50); break;
      case 'punch': this.noise(t, .08, .45, 1200); T(200, 0, .07, 'square', .13, 80); break;
      case 'hurt': this.noise(t, .14, .45, 900); T(120, 0, .12, 'sawtooth', .12, 50); break;
      case 'fire': this.noise(t, .55, .45, 900); T(110, 0, .5, 'sawtooth', .06, 60); break;
      case 'ice': [0, .05, .1, .15].forEach((s, i) => T(1800 + i * 350, s, .14, 'triangle', .12)); this.noise(t + .3, .2, .3, 6000, 'highpass'); break;
      case 'thunder': this.noise(t, .45, .8, 3000); T(70, 0, .4, 'square', .2, 40); break;
      case 'wind': this.noise(t, .5, .4, 2500, 'bandpass'); break;
      case 'meteor': T(800, 0, .45, 'sawtooth', .07, 100); this.noise(t + .45, .5, .8, 1200); break;
      case 'heal': arp(['C5', 'E5', 'G5', 'C6', 'E6'], .06, .25, 'triangle', .14); break;
      case 'revive': arp(['G4', 'C5', 'E5', 'G5', 'C6', 'G6'], .07, .35, 'triangle', .14); break;
      case 'holy': arp(['C5', 'G5', 'E6', 'C6', 'G6', 'C7'], .08, .5, 'sine', .16); break;
      case 'cast': T(300, 0, .3, 'sine', .14, 1200); break;
      case 'magic': T(500, 0, .25, 'triangle', .12, 1500); this.noise(t, .25, .2, 5000, 'highpass'); break;
      case 'spore': this.noise(t, .5, .25, 600); break;
      case 'mist': this.noise(t, .9, .4, 700); T(90, 0, .8, 'sawtooth', .06, 70); break;
      case 'quake': this.noise(t, .6, .8, 300); T(50, 0, .5, 'square', .2, 30); break;
      case 'burst': T(200, 0, .4, 'sawtooth', .12, 1600); this.noise(t + .1, .4, .5, 4000); break;
      case 'defend': T(523, 0, .08, 'square', .12); T(784, .07, .12, 'square', .12); break;
      case 'enemyDie': this.noise(t, .5, .4, 2500); T(600, 0, .45, 'square', .1, 60); break;
      case 'flee': [0, .07, .14].forEach(s => this.noise(t + s, .05, .3, 3000)); break;
      case 'encounter': T(200, 0, .5, 'sawtooth', .12, 1800); T(300, .05, .5, 'square', .08, 2400); this.noise(t, .5, .3, 4000, 'highpass'); break;
      case 'levelup': arp(['C5', 'E5', 'G5', 'C6', 'G5', 'C6'], .09, .18, 'square', .12); break;
      case 'chest': arp(['G4', 'B4', 'D5', 'G5'], .08, .2, 'square', .12); break;
      case 'buy': T(988, 0, .06, 'square', .12); T(1319, .06, .14, 'square', .12); break;
      case 'save': arp(['E5', 'G#5', 'B5', 'E6'], .1, .3, 'triangle', .15); break;
      case 'inn': arp(['C5', 'E5', 'G5', 'E5', 'F5', 'A5', 'C6'], .18, .35, 'triangle', .15); break;
    }
  },
  play(name) {
    if (!this.ctx) { this.pending = name; return; }
    if (this.song === name) return;
    this.stopMusic();
    const s = SONGS[name];
    if (!s) return;
    this.song = name; this.beat = 60 / s.bpm;
    this.bus = this.ctx.createGain(); this.bus.connect(this.musicGain);
    const t0 = this.ctx.currentTime + 0.1;
    this.tracks = s.tracks.map(tr => ({ tr, i: 0, next: t0 }));
  },
  stopMusic() {
    if (!this.ctx) { this.pending = null; return; }
    if (this.bus) {
      const b = this.bus;
      b.gain.setTargetAtTime(0, this.ctx.currentTime, 0.06);
      setTimeout(() => b.disconnect(), 700);
    }
    this.bus = null; this.tracks = []; this.song = null;
  },
  schedule() {
    if (!this.ctx || !this.song) return;
    const now = this.ctx.currentTime, ahead = now + 0.25;
    for (const st of this.tracks) {
      if (st.next < now - 0.1) st.next = now + 0.05; // tab sempat tidur: sinkron ulang
      const notes = st.tr.notes;
      while (st.next < ahead) {
        const [n, len] = notes[st.i];
        const dur = len * this.beat;
        if (n) this.tone(this.freq(n), st.next, dur * 0.92, st.tr.wave, st.tr.vol, this.bus);
        st.next += dur;
        st.i = (st.i + 1) % notes.length;
      }
    }
  },
};
$('mute').classList.toggle('off', Snd.muted);
$('mute').onclick = () => { Snd.unlock(); Snd.toggleMute(); };

// ---------- Lagu (melodi original) ----------
function trk(wave, vol, str) {
  return {
    wave, vol,
    notes: str.trim().split(/\s+/).filter(s => s !== '|').map(s => {
      const [n, l] = s.split(':');
      return [n === '-' ? null : n, parseFloat(l)];
    }),
  };
}
function bassLine(roots, wave = 'triangle', vol = 0.5) {
  const parts = [];
  for (const r of roots) for (let i = 0; i < 4; i++) parts.push(`${r}2:.5 ${r}3:.5`);
  return trk(wave, vol, parts.join(' '));
}
const SONGS = {
  title: { bpm: 84, tracks: [
    trk('triangle', .5, 'E5:2 D5:1 B4:1 | C5:2 G4:2 | A4:2 B4:1 C5:1 | D5:4 | E5:2 G5:1 E5:1 | D5:2 C5:2 | B4:1 C5:1 D5:1 B4:1 | C5:4'),
    trk('sine', .45, 'A2:4 E2:4 F2:4 G2:4 C3:4 G2:4 G2:4 C3:4'),
    trk('square', .08, 'A3:1 C4:1 E4:1 C4:1 E3:1 G3:1 B3:1 G3:1 F3:1 A3:1 C4:1 A3:1 G3:1 B3:1 D4:1 B3:1 C4:1 E4:1 G4:1 E4:1 G3:1 B3:1 D4:1 B3:1 G3:1 B3:1 D4:1 B3:1 C4:1 E4:1 G4:1 E4:1'),
  ] },
  town: { bpm: 100, tracks: [
    trk('square', .12, 'A4:1 C5:1 F5:2 | E5:1 D5:1 C5:2 | Bb4:1 D5:1 G5:2 | F5:1 E5:1 C5:2 | A4:1 C5:1 F5:1 A5:1 | G5:1.5 F5:.5 D5:2 | C5:1 E5:1 G5:1 E5:1 | F5:3 -:1'),
    trk('triangle', .5, 'F2:2 C3:2 C3:2 A2:2 Bb2:2 G2:2 C3:2 C2:2 F2:2 A2:2 Bb2:2 D3:2 C3:2 C3:2 F2:2 F2:2'),
  ] },
  field: { bpm: 124, tracks: [
    trk('square', .12, 'E4:1 G4:1 C5:1.5 B4:.5 | A4:1 G4:1 E4:2 | F4:1 A4:1 D5:1.5 C5:.5 | B4:1 A4:1 G4:2 | E4:1 G4:1 C5:1 E5:1 | D5:1.5 C5:.5 A4:2 | F4:1 A4:1 B4:1 D5:1 | C5:3 -:1'),
    trk('triangle', .5, 'C3:1 G3:1 C3:1 G3:1 A2:1 E3:1 A2:1 E3:1 F2:1 C3:1 F2:1 C3:1 G2:1 D3:1 G2:1 D3:1 C3:1 G3:1 C3:1 G3:1 A2:1 E3:1 F2:1 C3:1 F2:1 C3:1 G2:1 D3:1 C3:1 G3:1 C3:2'),
  ] },
  cave: { bpm: 76, tracks: [
    trk('triangle', .45, 'D5:2 F5:1 E5:1 | D5:3 -:1 | A4:2 C5:1 Bb4:1 | A4:3 -:1 | F5:2 A5:1 G5:1 | E5:3 -:1 | D5:1 E5:1 F5:1 E5:1 | D5:4'),
    trk('sine', .5, 'D2:4 D2:4 Bb1:4 A1:4 F2:4 C2:4 Bb1:2 A1:2 D2:4'),
    trk('square', .05, 'D4:.5 -:1.5 A3:.5 -:1.5 D4:.5 -:1.5 A3:.5 -:1.5 Bb3:.5 -:1.5 F3:.5 -:1.5 A3:.5 -:1.5 E3:.5 -:1.5 F4:.5 -:1.5 C4:.5 -:1.5 C4:.5 -:1.5 G3:.5 -:1.5 Bb3:.5 -:1.5 A3:.5 -:1.5 D4:.5 -:1.5 A3:.5 -:1.5'),
  ] },
  battle: { bpm: 160, tracks: [
    trk('square', .13, 'A4:.5 A4:.5 C5:.5 A4:.5 E5:1 D5:1 | C5:.5 B4:.5 A4:.5 G4:.5 A4:2 | F4:.5 F4:.5 A4:.5 F4:.5 C5:1 B4:1 | A4:.5 G4:.5 F4:.5 E4:.5 G#4:2 | A4:.5 A4:.5 C5:.5 A4:.5 E5:1 G5:1 | F5:.5 E5:.5 D5:.5 C5:.5 D5:2 | E5:.5 D5:.5 C5:.5 B4:.5 C5:.5 B4:.5 A4:.5 G#4:.5 | A4:2 E4:1 -:1'),
    bassLine(['A', 'A', 'F', 'E', 'A', 'D', 'E', 'A']),
  ] },
  boss: { bpm: 172, tracks: [
    trk('sawtooth', .07, 'E5:.5 E5:.5 E5:.5 D5:.5 E5:1 G5:1 | F#5:.5 E5:.5 D5:.5 B4:.5 E5:2 | C5:.5 C5:.5 C5:.5 B4:.5 C5:1 E5:1 | D5:.5 C5:.5 B4:.5 A4:.5 B4:2 | E5:.5 G5:.5 B5:.5 G5:.5 E5:.5 G5:.5 B5:1 | A5:.5 G5:.5 F#5:.5 E5:.5 F#5:2 | G5:.5 F#5:.5 E5:.5 D5:.5 C5:.5 B4:.5 A4:.5 B4:.5 | E5:3 -:1'),
    trk('square', .06, 'B4:2 B4:2 B4:2 G4:2 G4:2 G4:2 F#4:2 F#4:2 B4:2 B4:2 C5:2 C5:2 E5:2 C5:2 B4:2 D#5:2'),
    bassLine(['E', 'E', 'C', 'B', 'E', 'A', 'C', 'B'], 'triangle', .55),
  ] },
  victory: { bpm: 140, tracks: [
    trk('square', .13, 'C5:.5 E5:.5 G5:.5 C6:1.5 A5:.5 B5:.5 C6:2 -:2 | F5:1 A5:1 G5:1 E5:1 F5:1 D5:1 C5:2'),
    trk('triangle', .5, 'C3:2 G2:2 C3:2 C3:2 F2:2 C3:2 G2:2 C3:2'),
  ] },
  gameover: { bpm: 66, tracks: [
    trk('triangle', .45, 'A4:2 G4:2 F4:2 E4:2 D4:2 E4:1 C4:1 D4:4'),
    trk('sine', .45, 'D2:4 C2:4 Bb1:4 A1:4'),
  ] },
};

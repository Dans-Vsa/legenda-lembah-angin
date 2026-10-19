"use strict";
// ============================================================
//  Kontrol layar sentuh: bodi konsol untuk HP.
//  Vertikal = gaya GameBoy/NES, horizontal = gaya PSP (lihat style.css).
//  Aktif otomatis di perangkat sentuh; paksa dengan ?pad=1 atau matikan dengan ?pad=0.
// ============================================================
const Touch = {
  active: false,

  init() {
    const force = new URLSearchParams(location.search).get('pad');
    this.active = force === '1' || (force !== '0' && matchMedia('(pointer: coarse)').matches);
    document.body.classList.toggle('pad', this.active);
    if (!this.active) return;
    const canFs = !!(document.documentElement.requestFullscreen || document.documentElement.webkitRequestFullscreen);
    document.body.classList.toggle('no-fs', !canFs);
    this.bindDpad($('dpad'));
    document.querySelectorAll('#shell [data-act]').forEach(b => this.bindButton(b));
    // Cegah zoom ketuk-ganda, menu tekan-lama, dan scroll di bodi konsol.
    $('shell').addEventListener('contextmenu', e => e.preventDefault());
    $('shell').addEventListener('touchmove', e => { if (!e.target.closest('.list')) e.preventDefault(); }, { passive: false });
  },

  buzz() { if (navigator.vibrate) navigator.vibrate(8); },

  bindButton(el) {
    const act = el.dataset.act;
    const down = e => {
      e.preventDefault();
      if (el.setPointerCapture) el.setPointerCapture(e.pointerId);
      el.classList.add('pressed');
      this.buzz();
      if (act === 'fullscreen') this.toggleFullscreen();
      else Input.press(act);
    };
    const up = () => {
      if (!el.classList.contains('pressed')) return;
      el.classList.remove('pressed');
      if (act !== 'fullscreen') Input.release(act);
    };
    el.addEventListener('pointerdown', down);
    el.addEventListener('pointerup', up);
    el.addEventListener('pointercancel', up);
    el.addEventListener('lostpointercapture', up);
  },

  // Satu area D-pad: arah dihitung dari posisi jari terhadap titik tengah,
  // jadi jari bisa digeser ke arah lain tanpa diangkat.
  bindDpad(el) {
    let cur = null, delay = null, rep = null;
    const set = dir => {
      if (dir === cur) return;
      if (cur) { Input.release(cur); el.classList.remove('d-' + cur); }
      clearTimeout(delay); clearInterval(rep);
      cur = dir;
      if (!dir) return;
      el.classList.add('d-' + dir);
      this.buzz();
      Input.press(dir);
      // Tahan untuk menggulir menu, seperti tombol keyboard yang ditahan.
      delay = setTimeout(() => { rep = setInterval(() => Input.press(dir, true), 110); }, 320);
    };
    const pick = e => {
      const r = el.getBoundingClientRect();
      const x = e.clientX - (r.left + r.width / 2), y = e.clientY - (r.top + r.height / 2);
      if (Math.hypot(x, y) < r.width * 0.1) return cur;
      return Math.abs(x) > Math.abs(y) ? (x < 0 ? 'left' : 'right') : (y < 0 ? 'up' : 'down');
    };
    el.addEventListener('pointerdown', e => { e.preventDefault(); el.setPointerCapture(e.pointerId); set(pick(e)); });
    el.addEventListener('pointermove', e => { if (el.hasPointerCapture(e.pointerId)) set(pick(e)); });
    const end = () => set(null);
    el.addEventListener('pointerup', end);
    el.addEventListener('pointercancel', end);
    el.addEventListener('lostpointercapture', end);
  },

  toggleFullscreen() {
    const d = document, root = d.documentElement;
    if (d.fullscreenElement || d.webkitFullscreenElement) (d.exitFullscreen || d.webkitExitFullscreen).call(d);
    else {
      const p = (root.requestFullscreen || root.webkitRequestFullscreen).call(root);
      if (p && p.catch) p.catch(() => {});
    }
  },
};
Touch.init();

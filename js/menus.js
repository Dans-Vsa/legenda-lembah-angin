"use strict";
// ============================================================
//  Menu lapangan, toko, penginapan, kristal penyimpanan
// ============================================================
const pct = (a, b) => clamp(a / b * 100, 0, 100).toFixed(1);
function fmtTime(t) {
  const s = Math.floor(t);
  return `${Math.floor(s / 3600)}:${String(Math.floor(s / 60) % 60).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
}

function cardHtml(m) {
  const c = CHARS[m.id], s = m.s, need = xpNext(m.lvl), max = m.lvl >= MAX_LVL;
  return `<div class="card${m.hp <= 0 ? ' ko' : ''}"><img class="por" src="${Art.portrait(m.id)}"><div class="ci">
    <div class="cn">${c.name}<span class="lv">Lv ${m.lvl}</span></div><div class="ct">${c.title}</div>
    <div class="st"><span>HP</span><span>${m.hp} / ${s.maxHp}</span></div><div class="bar hp"><i style="width:${pct(m.hp, s.maxHp)}%"></i></div>
    <div class="st"><span>MP</span><span>${m.mp} / ${s.maxMp}</span></div><div class="bar mp"><i style="width:${pct(m.mp, s.maxMp)}%"></i></div>
    <div class="st"><span>EXP</span><span>${max ? 'MAX' : `${m.xp} / ${need}`}</span></div><div class="bar xp"><i style="width:${max ? 100 : pct(m.xp, need)}%"></i></div>
  </div></div>`;
}

function statusHtml(m) {
  const c = CHARS[m.id], s = m.s, w = ITEMS[m.weapon], a = ITEMS[m.armor];
  const skills = c.skills.map(([l, id]) => `<div class="skill-line${l > m.lvl ? ' locked' : ''}">${l > m.lvl ? `Lv ${l}: ???` : `${SKILLS[id].name} <small>(${SKILLS[id].mp} MP)</small>`}</div>`).join('');
  return `<div class="sh">${c.name} — ${c.title}</div>
    <div class="stat-grid">
      <span>Level</span><b>${m.lvl}</b>
      <span>EXP ke level berikut</span><b>${m.lvl >= MAX_LVL ? '-' : xpNext(m.lvl) - m.xp}</b>
      <span>HP</span><b>${m.hp} / ${s.maxHp}</b>
      <span>MP</span><b>${m.mp} / ${s.maxMp}</b>
      <span>Serangan</span><b>${s.atk}</b>
      <span>Sihir</span><b>${s.matk}</b>
      <span>Pertahanan</span><b>${s.def}</b>
      <span>Kecepatan</span><b>${s.spd}</b>
      <span>Senjata</span><b>${w.name}</b>
      <span>Pelindung</span><b>${a.name}</b>
    </div>
    <div class="sh" style="margin-top:10px">${c.skillLabel}</div>${skills}
    <div class="skill-line" style="margin-top:4px;color:#ff9ccc">BURST: ${BURSTS[m.id].name}</div>`;
}

const FieldMenu = {
  open() {
    World.busy = true;
    Snd.sfx('menu');
    const root = el('div', 'overlay', null, UI.root);
    const cmdW = UI.win('', 16, 16, 190, null, root);
    const infoW = UI.win('', 16, 410, 190, 114, root);
    const cardsW = UI.win('fm-cards', 216, 16, 370, 508, root);
    const sideW = UI.win('', 596, 16, 348, 508, root);
    let closed = false;
    const refreshInfo = () => {
      infoW.innerHTML = `<div class="kv"><span>Gold</span><b>${G.gold}</b></div><div class="kv"><span>Waktu</span><b>${fmtTime(G.time)}</b></div><div class="loc">${World.def.name}</div>`;
    };
    const timer = setInterval(refreshInfo, 1000);
    const cards = new ListMenu(cardsW, [], { inactive: true });
    const refreshCards = filter => cards.setItems(G.party.map(m => ({ label: cardHtml(m), value: m, disabled: filter ? !filter(m) : false })));
    const side = html => { sideW.innerHTML = html; };
    const sideDefault = () => side(`<div class="sh">Kontrol</div><div class="help-list">
      ${Touch.active
        ? '<b>D-pad</b> — bergerak<br><b>A</b> — pilih, bicara, periksa<br><b>B</b> — batal<br><b>START</b> — buka menu<br><b>SELECT</b> — suara on/off'
        : '<b>Panah / WASD</b> — bergerak<br><b>Enter / Z / Spasi</b> — pilih, bicara, periksa<br><b>Esc / X</b> — batal, buka menu<br><b>M</b> — suara on/off'}</div>
      <div class="sh" style="margin-top:14px">Tips</div><div class="help-list">
      • Monster muncul di rumput dan di dalam gua. Jalan setapak aman.<br>
      • Bar <span style="color:#ff9ccc">BURST</span> terisi saat terkena serangan. Jika penuh, jurus pamungkas siap!<br>
      • Serang kelemahan elemen musuh untuk damage 2x.<br>
      • Penginapan & kristal biru memulihkan HP/MP.</div>`);
    refreshCards(); refreshInfo(); sideDefault();

    const pickMember = filter => new Promise(res => {
      refreshCards(filter);
      cards.o.onSelect = it => { cards.deactivate(); refreshCards(); res(it.value); };
      cards.o.onCancel = () => { cards.deactivate(); refreshCards(); res(null); };
      cards.activate();
    });
    const sideList = (title, items, start) => new Promise(res => {
      side(`<div class="sh">${title}</div><div class="side-list"></div><div class="side-help"></div>`);
      const help = sideW.querySelector('.side-help');
      const lm = new ListMenu(sideW.querySelector('.side-list'), items, {
        start, onMove: it => help.textContent = it.help || '',
        onSelect: (it, i) => { lm.deactivate(); res([it.value, i]); },
        onCancel: () => { lm.destroy(); res([null, start]); },
      });
    });

    const flows = {
      item: async () => {
        let idx = 0;
        while (true) {
          const ids = Object.keys(G.items);
          if (!ids.length) { side('<div class="sh">Item</div><div class="muted">Tas kosong.</div>'); Snd.sfx('buzz'); return; }
          const [id, i] = await sideList('Item', ids.map(k => ({ label: ITEMS[k].name, right: 'x' + G.items[k], value: k, disabled: !!ITEMS[k].battleOnly, help: ITEMS[k].desc + (ITEMS[k].battleOnly ? ' (Hanya di battle.)' : '') })), idx);
          idx = i;
          if (!id) { sideDefault(); return; }
          sideW.querySelector('.side-help').textContent = `Pakai ${ITEMS[id].name} untuk siapa?`;
          const t = await pickMember(m => canUseItem(id, m));
          if (!t) continue;
          const r = applyItem(id, t);
          removeItem(id);
          Snd.sfx(r.revived ? 'revive' : 'heal');
          refreshCards();
        }
      },
      skill: async () => {
        while (true) {
          side('<div class="sh">Skill</div><div class="muted">Pilih siapa yang memakai skill penyembuh.<br>(Lyra: Pulih, dll. Rina: Fokus Chi di Lv 6)</div>');
          const caster = await pickMember(m => m.hp > 0 && fieldSkills(m).length > 0);
          if (!caster) { sideDefault(); return; }
          let idx = 0;
          while (true) {
            const ids = fieldSkills(caster);
            const [sid, i] = await sideList(`${CHARS[caster.id].skillLabel} — ${CHARS[caster.id].name} (MP ${caster.mp})`, ids.map(k => ({ label: SKILLS[k].name, right: SKILLS[k].mp + ' MP', value: k, disabled: caster.mp < SKILLS[k].mp, help: SKILLS[k].desc })), idx);
            idx = i;
            if (!sid) break;
            const sk = SKILLS[sid];
            let targets;
            if (sk.target === 'allies') targets = G.party.filter(m => m.hp > 0);
            else if (sk.target === 'self') targets = [caster];
            else {
              sideW.querySelector('.side-help').textContent = `${sk.name} untuk siapa?`;
              const t = await pickMember(m => sk.kind === 'revive' ? m.hp <= 0 : m.hp > 0 && m.hp < m.s.maxHp);
              if (!t) continue;
              targets = [t];
            }
            caster.mp -= sk.mp;
            for (const t of targets) {
              if (sk.kind === 'revive') t.hp = Math.max(1, Math.floor(t.s.maxHp * sk.power));
              else t.hp = Math.min(t.s.maxHp, t.hp + healPower(caster, sk));
            }
            Snd.sfx(sk.kind === 'revive' ? 'revive' : 'heal');
            refreshCards();
          }
        }
      },
      status: async () => {
        cards.o.onMove = it => side(statusHtml(it.value));
        while (await pickMember()) { /* tetap di layar status sampai batal */ }
        cards.o.onMove = null;
        sideDefault();
      },
      save: async () => {
        if (saveGame()) { Snd.sfx('save'); side('<div class="sh">Simpan</div><div>Permainan tersimpan!</div><div class="muted" style="margin-top:6px">Pilih "Lanjutkan" di layar judul untuk memuatnya.</div>'); }
        else { Snd.sfx('buzz'); side('<div class="sh">Simpan</div><div>Gagal menyimpan (penyimpanan browser tidak tersedia).</div>'); }
      },
      title: async () => {
        const [v] = await sideList('Kembali ke layar judul?', [{ label: 'Ya', value: 'y', help: 'Progres yang belum disimpan akan hilang.' }, { label: 'Tidak', value: 'n', help: '' }], 1);
        if (v === 'y') { closed = true; clearInterval(timer); Title.show(); return; }
        sideDefault();
      },
    };
    const close = () => {
      if (closed) return;
      closed = true; clearInterval(timer);
      main.destroy(); cards.destroy(); root.remove();
      World.busy = false; World.bumpLock = true;
    };
    const main = new ListMenu(cmdW, [
      { label: 'Item', value: 'item' }, { label: 'Skill', value: 'skill' }, { label: 'Status', value: 'status' },
      { label: 'Simpan', value: 'save' }, { label: 'Ke Judul', value: 'title' }, { label: 'Tutup', value: 'close' },
    ], {
      onSelect: async it => {
        if (it.value === 'close') return close();
        main.deactivate();
        await flows[it.value]();
        if (!closed) main.activate();
      },
      onCancel: close,
    });
  },
};

// ---------- Toko ----------
async function openShop() {
  await say([{ s: 'Pak Darmo', t: 'Selamat datang di toko kami! Ramuan, senjata, pelindung... semua ada. Silakan lihat-lihat.' }]);
  await new Promise(res => {
    const root = el('div', 'overlay', null, UI.root);
    const head = UI.win('shop-head', 16, 16, 928, 50, root);
    const listW = UI.win('', 16, 76, 470, 448, root);
    const infoW = UI.win('', 496, 76, 448, 448, root);
    const upd = () => { head.innerHTML = `<span>Toko Pak Darmo</span><span>Gold: <b>${G.gold}</b></span>`; };
    const equippedBy = id => G.party.filter(m => m.weapon === id || m.armor === id).map(m => CHARS[m.id].name);
    const mk = () => SHOP.map(id => {
      const it = ITEMS[id];
      const owned = it.kind === 'weapon' && G.party.find(p => p.id === it.owner).weapon === id;
      return { label: it.name, right: owned ? 'Dipakai' : it.price + ' G', value: id, disabled: owned || G.gold < it.price };
    });
    const info = id => {
      const it = ITEMS[id];
      let html = `<div class="sh">${it.name}</div><div>${it.desc}</div><div class="muted" style="margin-top:6px">Harga: ${it.price} G</div>`;
      if (it.kind === 'item') html += `<div style="margin-top:12px">Dimiliki: <b>${G.items[id] || 0}</b></div>`;
      else {
        html += '<div class="sh" style="margin-top:14px">Perbandingan</div>';
        for (const m of G.party) {
          if (it.kind === 'weapon' && it.owner !== m.id) continue;
          const cur = ITEMS[it.kind === 'weapon' ? m.weapon : m.armor];
          const key = it.kind === 'armor' ? 'def' : it.atk ? 'atk' : 'mag';
          const label = key === 'def' ? 'Pertahanan' : key === 'atk' ? 'Serangan' : 'Sihir';
          const before = key === 'def' ? m.s.def : key === 'atk' ? m.s.atk : m.s.matk;
          const after = before - (cur[key] || 0) + (it[key] || 0);
          html += `<div class="kv"><span>${CHARS[m.id].name} — ${label}</span><span>${before} → <span class="${after >= before ? 'cmp-up' : 'cmp-down'}">${after}</span></span></div>`;
        }
        const who = equippedBy(id);
        if (who.length) html += `<div class="muted" style="margin-top:6px">Dipakai oleh: ${who.join(', ')}</div>`;
      }
      if (G.gold < it.price) html += '<div style="margin-top:12px;color:#ff9090">Gold tidak cukup.</div>';
      infoW.innerHTML = html;
    };
    const pickArmorOwner = id => new Promise(r2 => {
      const w = UI.win('', 496, 300, 448, 150, root);
      el('div', 'sh', `Pakaikan ${ITEMS[id].name} ke siapa?`, w);
      const m = new ListMenu(w, G.party.map(p => ({ label: CHARS[p.id].name, right: ITEMS[p.armor].name, value: p, disabled: p.armor === id })), {
        onSelect: it => { m.destroy(); w.remove(); r2(it.value); },
        onCancel: () => { m.destroy(); w.remove(); r2(null); },
      });
    });
    const buy = async id => {
      const it = ITEMS[id];
      if (it.kind === 'weapon') {
        const m = G.party.find(p => p.id === it.owner);
        G.gold -= it.price; equip(m, 'weapon', id); toast(`${CHARS[m.id].name} memakai ${it.name}!`);
      } else if (it.kind === 'armor') {
        lm.deactivate();
        const m = await pickArmorOwner(id);
        lm.activate();
        if (!m) return;
        G.gold -= it.price; equip(m, 'armor', id); toast(`${CHARS[m.id].name} memakai ${it.name}!`);
      } else {
        G.gold -= it.price; addItem(id, 1);
      }
      Snd.sfx('buy'); upd(); lm.setItems(mk()); info(id);
    };
    upd();
    const lm = new ListMenu(listW, mk(), {
      silent: true,
      onMove: it => info(it.value),
      onSelect: it => buy(it.value),
      onCancel: () => { lm.destroy(); root.remove(); res(); },
    });
  });
  await say([{ s: 'Pak Darmo', t: 'Terima kasih! Hati-hati di jalan, ya!' }]);
}

// ---------- Penginapan ----------
async function openInn() {
  const i = await ask('Bu Wina: Selamat datang di Penginapan Angin Sepoi! Menginap semalam 20 Gold. Mau beristirahat?', ['Menginap (20 G)', 'Tidak']);
  if (i !== 0) { await say([{ s: 'Bu Wina', t: 'Datang lagi kapan-kapan, ya!' }]); return; }
  if (G.gold < 20) { Snd.sfx('buzz'); await say([{ s: 'Bu Wina', t: 'Maaf, Gold-mu tidak cukup...' }]); return; }
  G.gold -= 20;
  await restAll();
  await say([{ s: 'Bu Wina', t: 'Selamat pagi! Kalian terlihat segar kembali. Semoga perjalanan kalian lancar!' }]);
}
async function restAll() {
  await Fade.to(1, 600);
  Snd.sfx('inn');
  fullHeal();
  await sleep(1500);
  await Fade.to(0, 600);
}

// ---------- Kristal penyimpanan ----------
async function saveCrystal() {
  Snd.sfx('holy');
  fullHeal();
  await say(['Cahaya biru kristal menyelimuti party... HP dan MP pulih sepenuhnya!']);
  const i = await ask('Simpan permainan di sini?', ['Simpan', 'Tidak']);
  if (i === 0) { if (saveGame()) { Snd.sfx('save'); await say(['Permainan tersimpan.']); } }
}

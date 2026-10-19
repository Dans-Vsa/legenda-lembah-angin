extends Node
## Audio chiptune: musik dan efek suara disintesis lewat kode menjadi AudioStreamWAV.
## Lagu dibangun di thread latar agar tidak membuat game tersendat.

const RATE := 16000

var muted := false
var current := ""
var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_i := 0
var _songs := {}
var _sfx_cache := {}
var _mutex := Mutex.new()
var _noise := PackedFloat32Array()
var _task := -1
var _stopping := false


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	add_child(_music)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -3.0
		add_child(p)
		_sfx.append(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_noise.resize(RATE)
	for i in RATE:
		_noise[i] = rng.randf_range(-1.0, 1.0)
	_task = WorkerThreadPool.add_task(_prebuild)


func _exit_tree() -> void:
	# Hentikan pembuatan lagu di latar sebelum node ini dihapus.
	_stopping = true
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _prebuild() -> void:
	for name in ["title", "town", "field", "battle", "cave", "victory", "boss", "gameover"]:
		if _stopping:
			return
		_song(name)


func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)


# ---------- Musik ----------
func play(name: String) -> void:
	if current == name:
		return
	current = name
	var s := _song(name)
	_music.stream = s
	_music.play()


func stop_music() -> void:
	current = ""
	_music.stop()


func _song(name: String) -> AudioStreamWAV:
	_mutex.lock()
	var s: AudioStreamWAV = _songs.get(name)
	_mutex.unlock()
	if s:
		return s
	s = _to_wav(_render_song(SONGS[name]), true)
	_mutex.lock()
	if not _songs.has(name):
		_songs[name] = s
	s = _songs[name]
	_mutex.unlock()
	return s


func _render_song(def: Dictionary) -> PackedFloat32Array:
	var beat: float = 60.0 / float(def["bpm"])
	var tracks := []
	var total := 0.0
	for t in def["tracks"]:
		var notes := _parse(t[2])
		var total_len := 0.0
		for n in notes:
			total_len += n[1]
		total = maxf(total, total_len)
		tracks.append([t[0], t[1], notes])
	var buf := PackedFloat32Array()
	buf.resize(int(total * beat * RATE))
	for tr in tracks:
		var pos := 0.0
		for n in tr[2]:
			var dur: float = n[1] * beat
			if n[0] != "":
				_tone(buf, int(pos * RATE), dur * 0.92, _freq(n[0]), tr[0], tr[1] * 0.32, 0.0)
			pos += dur
	return buf


func _parse(s: String) -> Array:
	var out := []
	for tok in s.split(" ", false):
		if tok == "|":
			continue
		var parts := tok.split(":")
		out.append(["" if parts[0] == "-" else parts[0], float(parts[1])])
	return out


func _freq(n: String) -> float:
	var base := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var semi: int = base[n[0]]
	var i := 1
	if n[1] == "#":
		semi += 1
		i = 2
	elif n[1] == "b":
		semi -= 1
		i = 2
	var octave := int(n.substr(i))
	return 440.0 * pow(2.0, ((octave + 1) * 12 + semi - 69) / 12.0)


# Osilator dengan envelope serang cepat lalu meluruh eksponensial (bunyi "plucky" khas chiptune).
func _tone(buf: PackedFloat32Array, start: int, dur: float, f: float, wave: String, vol: float, slide_to: float) -> void:
	var n := int(dur * RATE)
	var attack := int(0.012 * RATE)
	var decay := pow(0.0001 / vol, 1.0 / maxf(1.0, n - attack)) if vol > 0.0001 else 0.0
	var phase := 0.0
	var env := vol
	var size := buf.size()
	for i in n:
		var idx := start + i
		if idx >= size:
			break
		var fr := f
		if slide_to > 0.0:
			fr = f * pow(slide_to / f, float(i) / n)
		phase += fr / RATE
		phase -= floorf(phase)
		var s: float
		match wave:
			"square": s = 1.0 if phase < 0.5 else -1.0
			"triangle": s = 4.0 * absf(phase - 0.5) - 1.0
			"sawtooth": s = 2.0 * phase - 1.0
			_: s = sin(phase * TAU)
		var e: float
		if i < attack:
			e = vol * float(i) / attack
		else:
			env *= decay
			e = env
		buf[idx] += s * e


func _noise_burst(buf: PackedFloat32Array, start: int, dur: float, vol: float, cutoff: float, mode: String) -> void:
	var n := int(dur * RATE)
	var k := clampf(cutoff / RATE * TAU, 0.01, 1.0)
	var lp := 0.0
	var lp2 := 0.0
	var decay := pow(0.001 / vol, 1.0 / maxf(1.0, n))
	var env := vol
	for i in n:
		var idx := start + i
		if idx >= buf.size():
			break
		var x := _noise[(start + i) % _noise.size()]
		lp += (x - lp) * k
		lp2 += (lp - lp2) * k
		var s := lp
		if mode == "highpass":
			s = x - lp
		elif mode == "bandpass":
			s = lp - lp2
		buf[idx] += s * env
		env *= decay


func _to_wav(buf: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


# ---------- Efek suara ----------
func sfx(name: String) -> void:
	if not _sfx_cache.has(name):
		var buf := PackedFloat32Array()
		buf.resize(int(1.4 * RATE))
		var used := _render_sfx(name, buf)
		if used <= 0.0:
			return
		buf.resize(int(used * RATE) + 200)
		_sfx_cache[name] = _to_wav(buf, false)
	var p := _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = _sfx_cache[name]
	p.play()


# Mengembalikan durasi total (detik) dari efek yang digambar ke buffer.
func _render_sfx(name: String, buf: PackedFloat32Array) -> float:
	var end := 0.0
	match name:
		"cursor": _t(buf, 1046, 0, .04, "square", .1); end = .05
		"ok": _t(buf, 784, 0, .05, "square", .13); _t(buf, 1175, .05, .07, "square", .13); end = .13
		"cancel": _t(buf, 587, 0, .05, "square", .11); _t(buf, 392, .05, .07, "square", .11); end = .13
		"buzz": _t(buf, 140, 0, .16, "square", .15); end = .17
		"menu": _t(buf, 659, 0, .05, "triangle", .2); _t(buf, 988, .05, .08, "triangle", .2); end = .14
		"ready": _t(buf, 1568, 0, .06, "triangle", .12); _t(buf, 2093, .05, .08, "triangle", .1); end = .14
		"slash": _n(buf, 0, .12, .35, 5000, "highpass"); _t(buf, 900, 0, .1, "sawtooth", .06, 200); end = .13
		"hit": _n(buf, 0, .12, .5, 1500); _t(buf, 160, 0, .1, "square", .15, 60); end = .13
		"crit": _n(buf, 0, .22, .7, 2500); _t(buf, 240, 0, .18, "square", .2, 50); end = .23
		"punch": _n(buf, 0, .08, .45, 1200); _t(buf, 200, 0, .07, "square", .13, 80); end = .09
		"hurt": _n(buf, 0, .14, .45, 900); _t(buf, 120, 0, .12, "sawtooth", .12, 50); end = .15
		"fire": _n(buf, 0, .55, .45, 900); _t(buf, 110, 0, .5, "sawtooth", .06, 60); end = .56
		"ice":
			for i in 4: _t(buf, 1800 + i * 350, i * .05, .14, "triangle", .12)
			_n(buf, .3, .2, .3, 6000, "highpass"); end = .51
		"thunder": _n(buf, 0, .45, .8, 3000); _t(buf, 70, 0, .4, "square", .2, 40); end = .46
		"wind": _n(buf, 0, .5, .4, 2500, "bandpass"); end = .51
		"meteor": _t(buf, 800, 0, .45, "sawtooth", .07, 100); _n(buf, .45, .5, .8, 1200); end = .96
		"heal": _arp(buf, ["C5", "E5", "G5", "C6", "E6"], .06, .25, "triangle", .14); end = .5
		"revive": _arp(buf, ["G4", "C5", "E5", "G5", "C6", "G6"], .07, .35, "triangle", .14); end = .71
		"holy": _arp(buf, ["C5", "G5", "E6", "C6", "G6", "C7"], .08, .5, "sine", .16); end = .91
		"cast": _t(buf, 300, 0, .3, "sine", .14, 1200); end = .31
		"magic": _t(buf, 500, 0, .25, "triangle", .12, 1500); _n(buf, 0, .25, .2, 5000, "highpass"); end = .26
		"spore": _n(buf, 0, .5, .25, 600); end = .51
		"mist": _n(buf, 0, .9, .4, 700); _t(buf, 90, 0, .8, "sawtooth", .06, 70); end = .91
		"quake": _n(buf, 0, .6, .8, 300); _t(buf, 50, 0, .5, "square", .2, 30); end = .61
		"burst": _t(buf, 200, 0, .4, "sawtooth", .12, 1600); _n(buf, .1, .4, .5, 4000); end = .51
		"defend": _t(buf, 523, 0, .08, "square", .12); _t(buf, 784, .07, .12, "square", .12); end = .2
		"enemyDie": _n(buf, 0, .5, .4, 2500); _t(buf, 600, 0, .45, "square", .1, 60); end = .51
		"flee":
			for s in [0.0, .07, .14]: _n(buf, s, .05, .3, 3000)
			end = .2
		"encounter": _t(buf, 200, 0, .5, "sawtooth", .12, 1800); _t(buf, 300, .05, .5, "square", .08, 2400); _n(buf, 0, .5, .3, 4000, "highpass"); end = .56
		"levelup": _arp(buf, ["C5", "E5", "G5", "C6", "G5", "C6"], .09, .18, "square", .12); end = .64
		"chest": _arp(buf, ["G4", "B4", "D5", "G5"], .08, .2, "square", .12); end = .45
		"buy": _t(buf, 988, 0, .06, "square", .12); _t(buf, 1319, .06, .14, "square", .12); end = .21
		"save": _arp(buf, ["E5", "G#5", "B5", "E6"], .1, .3, "triangle", .15); end = .61
		"inn": _arp(buf, ["C5", "E5", "G5", "E5", "F5", "A5", "C6"], .18, .35, "triangle", .15); end = 1.4
	return end


func _t(buf: PackedFloat32Array, f: float, s: float, dur: float, wave: String, vol: float, slide := 0.0) -> void:
	_tone(buf, int(s * RATE), dur, f, wave, vol * 2.0, slide)


func _n(buf: PackedFloat32Array, s: float, dur: float, vol: float, cutoff: float, mode := "lowpass") -> void:
	_noise_burst(buf, int(s * RATE), dur, vol * 1.6, cutoff, mode)


func _arp(buf: PackedFloat32Array, notes: Array, step: float, dur: float, wave: String, vol: float) -> void:
	for i in notes.size():
		_tone(buf, int(i * step * RATE), dur, _freq(notes[i]), wave, vol * 2.0, 0.0)


# ---------- Lagu (melodi original) ----------
static func _bass(roots: Array) -> String:
	var parts := []
	for r in roots:
		for i in 4:
			parts.append("%s2:.5 %s3:.5" % [r, r])
	return " ".join(parts)

var SONGS := {
	"title": {"bpm": 84, "tracks": [
		["triangle", .5, "E5:2 D5:1 B4:1 C5:2 G4:2 A4:2 B4:1 C5:1 D5:4 E5:2 G5:1 E5:1 D5:2 C5:2 B4:1 C5:1 D5:1 B4:1 C5:4"],
		["sine", .45, "A2:4 E2:4 F2:4 G2:4 C3:4 G2:4 G2:4 C3:4"],
		["square", .08, "A3:1 C4:1 E4:1 C4:1 E3:1 G3:1 B3:1 G3:1 F3:1 A3:1 C4:1 A3:1 G3:1 B3:1 D4:1 B3:1 C4:1 E4:1 G4:1 E4:1 G3:1 B3:1 D4:1 B3:1 G3:1 B3:1 D4:1 B3:1 C4:1 E4:1 G4:1 E4:1"],
	]},
	"town": {"bpm": 100, "tracks": [
		["square", .12, "A4:1 C5:1 F5:2 E5:1 D5:1 C5:2 Bb4:1 D5:1 G5:2 F5:1 E5:1 C5:2 A4:1 C5:1 F5:1 A5:1 G5:1.5 F5:.5 D5:2 C5:1 E5:1 G5:1 E5:1 F5:3 -:1"],
		["triangle", .5, "F2:2 C3:2 C3:2 A2:2 Bb2:2 G2:2 C3:2 C2:2 F2:2 A2:2 Bb2:2 D3:2 C3:2 C3:2 F2:2 F2:2"],
	]},
	"field": {"bpm": 124, "tracks": [
		["square", .12, "E4:1 G4:1 C5:1.5 B4:.5 A4:1 G4:1 E4:2 F4:1 A4:1 D5:1.5 C5:.5 B4:1 A4:1 G4:2 E4:1 G4:1 C5:1 E5:1 D5:1.5 C5:.5 A4:2 F4:1 A4:1 B4:1 D5:1 C5:3 -:1"],
		["triangle", .5, "C3:1 G3:1 C3:1 G3:1 A2:1 E3:1 A2:1 E3:1 F2:1 C3:1 F2:1 C3:1 G2:1 D3:1 G2:1 D3:1 C3:1 G3:1 C3:1 G3:1 A2:1 E3:1 F2:1 C3:1 F2:1 C3:1 G2:1 D3:1 C3:1 G3:1 C3:2"],
	]},
	"cave": {"bpm": 76, "tracks": [
		["triangle", .45, "D5:2 F5:1 E5:1 D5:3 -:1 A4:2 C5:1 Bb4:1 A4:3 -:1 F5:2 A5:1 G5:1 E5:3 -:1 D5:1 E5:1 F5:1 E5:1 D5:4"],
		["sine", .5, "D2:4 D2:4 Bb1:4 A1:4 F2:4 C2:4 Bb1:2 A1:2 D2:4"],
	]},
	"battle": {"bpm": 160, "tracks": [
		["square", .13, "A4:.5 A4:.5 C5:.5 A4:.5 E5:1 D5:1 C5:.5 B4:.5 A4:.5 G4:.5 A4:2 F4:.5 F4:.5 A4:.5 F4:.5 C5:1 B4:1 A4:.5 G4:.5 F4:.5 E4:.5 G#4:2 A4:.5 A4:.5 C5:.5 A4:.5 E5:1 G5:1 F5:.5 E5:.5 D5:.5 C5:.5 D5:2 E5:.5 D5:.5 C5:.5 B4:.5 C5:.5 B4:.5 A4:.5 G#4:.5 A4:2 E4:1 -:1"],
		["triangle", .5, _bass(["A", "A", "F", "E", "A", "D", "E", "A"])],
	]},
	"boss": {"bpm": 172, "tracks": [
		["sawtooth", .07, "E5:.5 E5:.5 E5:.5 D5:.5 E5:1 G5:1 F#5:.5 E5:.5 D5:.5 B4:.5 E5:2 C5:.5 C5:.5 C5:.5 B4:.5 C5:1 E5:1 D5:.5 C5:.5 B4:.5 A4:.5 B4:2 E5:.5 G5:.5 B5:.5 G5:.5 E5:.5 G5:.5 B5:1 A5:.5 G5:.5 F#5:.5 E5:.5 F#5:2 G5:.5 F#5:.5 E5:.5 D5:.5 C5:.5 B4:.5 A4:.5 B4:.5 E5:3 -:1"],
		["square", .06, "B4:2 B4:2 B4:2 G4:2 G4:2 G4:2 F#4:2 F#4:2 B4:2 B4:2 C5:2 C5:2 E5:2 C5:2 B4:2 D#5:2"],
		["triangle", .55, _bass(["E", "E", "C", "B", "E", "A", "C", "B"])],
	]},
	"victory": {"bpm": 140, "tracks": [
		["square", .13, "C5:.5 E5:.5 G5:.5 C6:1.5 A5:.5 B5:.5 C6:2 -:2 F5:1 A5:1 G5:1 E5:1 F5:1 D5:1 C5:2"],
		["triangle", .5, "C3:2 G2:2 C3:2 C3:2 F2:2 C3:2 G2:2 C3:2"],
	]},
	"gameover": {"bpm": 66, "tracks": [
		["triangle", .45, "A4:2 G4:2 F4:2 E4:2 D4:2 E4:1 C4:1 D4:4"],
		["sine", .45, "D2:4 C2:4 Bb1:4 A1:4"],
	]},
}

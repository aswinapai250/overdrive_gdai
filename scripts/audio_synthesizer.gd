extends Node
class_name AudioSynthesizer

# Procedural Audio Synthesizer for Velocity: Momentum Protocol
# Generates 16-bit PCM AudioStreamWAV sounds dynamically in memory without external assets.

var sfx_players: Array[AudioStreamPlayer] = []
var max_polyphony: int = 12
var sfx_library: Dictionary = {}

var music_player: AudioStreamPlayer
var sample_rate: int = 22050

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_audio_pool()
	_generate_all_sfx()
	_start_cyber_music()

func _create_audio_pool() -> void:
	for i in range(max_polyphony):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -8.0
	add_child(music_player)

func play_sfx(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sfx_library.has(sound_name):
		return
	
	var stream: AudioStreamWAV = sfx_library[sound_name]
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
			player.volume_db = volume_db
			player.play()
			return
	
	# If all busy, use first
	sfx_players[0].stream = stream
	sfx_players[0].pitch_scale = pitch_scale
	sfx_players[0].volume_db = volume_db
	sfx_players[0].play()

func _generate_all_sfx() -> void:
	sfx_library["jump"] = _generate_jump_sfx()
	sfx_library["slide"] = _generate_slide_sfx()
	sfx_library["land"] = _generate_land_sfx()
	sfx_library["orb"] = _generate_orb_sfx()
	sfx_library["boost"] = _generate_boost_sfx()
	sfx_library["hit"] = _generate_hit_sfx()
	sfx_library["perfect_slide"] = _generate_perfect_sfx()
	sfx_library["game_over"] = _generate_game_over_sfx()

func _create_wav(data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = data.size() / 2
	return wav

func _generate_jump_sfx() -> AudioStreamWAV:
	var duration: float = 0.22
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var phase: float = 0.0
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var freq = lerpf(180.0, 480.0, t)
		var amp = sin(PI * (1.0 - t)) * 0.7
		phase += freq / float(sample_rate)
		var val = sin(phase * TAU) * amp
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

func _generate_slide_sfx() -> AudioStreamWAV:
	var duration: float = 0.55
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var noise_prev: float = 0.0
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var env = sin(t * PI) * 0.75
		var white = (randf() * 2.0 - 1.0)
		# Lowpass filter noise for smooth whoosh
		noise_prev = lerpf(noise_prev, white, 0.22)
		var bass = sin(float(i) * 110.0 / sample_rate * TAU) * 0.3
		var val = (noise_prev * 0.7 + bass * 0.3) * env
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

func _generate_land_sfx() -> AudioStreamWAV:
	var duration: float = 0.15
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var env = (1.0 - t) * (1.0 - t) * 0.8
		var freq = lerpf(90.0, 40.0, t)
		var val = sin(float(i) * freq / sample_rate * TAU) * env
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

func _generate_orb_sfx() -> AudioStreamWAV:
	var duration: float = 0.25
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var env = exp(-t * 5.5) * 0.75
		var freq = 987.77 if t < 0.35 else 1318.51 # B5 to E6 chime
		var tone = sin(float(i) * freq / sample_rate * TAU)
		var harmonic = sin(float(i) * freq * 2.0 / sample_rate * TAU) * 0.3
		var val = (tone + harmonic) * env
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

func _generate_boost_sfx() -> AudioStreamWAV:
	var duration: float = 0.6
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var noise_prev: float = 0.0
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var env = sin(t * PI * 0.5) if t < 0.3 else 1.0 - ((t - 0.3) / 0.7)
		var sweep_freq = lerpf(90.0, 320.0, t * t)
		var white = randf() * 2.0 - 1.0
		noise_prev = lerpf(noise_prev, white, 0.35)
		var rumble = sin(float(i) * sweep_freq / sample_rate * TAU) * 0.5
		var val = (rumble + noise_prev * 0.5) * env * 0.8
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

func _generate_hit_sfx() -> AudioStreamWAV:
	var duration: float = 0.35
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var env = (1.0 - t) * 0.9
		var crunch = 1.0 if sin(float(i) * 75.0 / sample_rate * TAU) > 0.0 else -1.0
		var noise = randf() * 2.0 - 1.0
		var val = (crunch * 0.6 + noise * 0.4) * env
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

func _generate_perfect_sfx() -> AudioStreamWAV:
	var duration: float = 0.4
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var env = (1.0 - t) * 0.7
		# Arpeggio: 880, 1108, 1320, 1760 Hz
		var note_idx = int(t * 4.0)
		var notes = [880.0, 1108.73, 1318.51, 1760.0]
		var freq = notes[clamp(note_idx, 0, 3)]
		var val = sin(float(i) * freq / sample_rate * TAU) * env
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

func _generate_game_over_sfx() -> AudioStreamWAV:
	var duration: float = 1.2
	var samples_count: int = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / float(samples_count)
		var env = (1.0 - t * 0.8) * 0.85
		var freq = lerpf(380.0, 80.0, t * t)
		var dist = sin(float(i) * freq / sample_rate * TAU)
		if dist > 0.4: dist = 0.4
		elif dist < -0.4: dist = -0.4
		var val = dist * 2.5 * env
		var sample_val: int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	return _create_wav(data)

# Procedural Cyberpunk looping music (132 BPM Synthwave pulse)
func _start_cyber_music() -> void:
	var bpm: float = 132.0
	var beat_sec: float = 60.0 / bpm
	var bar_sec: float = beat_sec * 4.0
	var loop_bars: int = 4
	var total_dur: float = bar_sec * float(loop_bars)
	var total_samples: int = int(total_dur * sample_rate)
	
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# Synth bass notes in D minor: D2 (73.4), F2 (87.3), G2 (98.0), A2 (110.0)
	var bass_notes = [73.42, 73.42, 87.31, 73.42, 98.0, 87.31, 110.0, 98.0]
	
	for i in range(total_samples):
		var cur_time = float(i) / float(sample_rate)
		var bar_progress = fmod(cur_time, bar_sec)
		var beat_progress = fmod(cur_time, beat_sec)
		var eighth_progress = fmod(cur_time, beat_sec * 0.5)
		var sixteenth_progress = fmod(cur_time, beat_sec * 0.25)
		
		# 1. Kick Drum on every beat
		var kick_t = beat_progress / beat_sec
		var kick_env = exp(-kick_t * 18.0)
		var kick_freq = lerpf(120.0, 45.0, kick_t * 3.0)
		var kick = sin(kick_t * beat_sec * kick_freq * TAU) * kick_env * 0.65
		
		# 2. Snare / Clack on beats 2 and 4
		var snare: float = 0.0
		var beat_idx = int(bar_progress / beat_sec)
		if beat_idx == 1 or beat_idx == 3:
			var snare_t = beat_progress / beat_sec
			if snare_t < 0.2:
				var snare_env = (1.0 - snare_t / 0.2)
				var white = (randf() * 2.0 - 1.0)
				var body = sin(snare_t * 220.0 * TAU) * 0.5
				snare = (white * 0.7 + body * 0.3) * snare_env * 0.45
				
		# 3. Hi-hat on 16th notes
		var hat_t = sixteenth_progress / (beat_sec * 0.25)
		var hat_env = exp(-hat_t * 35.0)
		var hat = (randf() * 2.0 - 1.0) * hat_env * 0.18
		
		# 4. Rolling Cyber Bassline (16th notes)
		var sixteenth_idx = int(fmod(cur_time / (beat_sec * 0.25), 8.0))
		var note_freq = bass_notes[sixteenth_idx]
		var bass_env = exp(-(sixteenth_progress / (beat_sec * 0.25)) * 6.5)
		var saw = (fmod(cur_time * note_freq, 1.0) * 2.0 - 1.0)
		var sub = sin(cur_time * note_freq * 0.5 * TAU) * 0.5
		var bass = (saw * 0.5 + sub) * bass_env * 0.35
		
		var mix = (kick + snare + hat + bass) * 0.55
		var sample_val: int = int(clampf(mix, -0.95, 0.95) * 32767.0)
		data.encode_s16(i * 2, sample_val)
		
	var loop_wav = _create_wav(data, true)
	music_player.stream = loop_wav
	music_player.play()

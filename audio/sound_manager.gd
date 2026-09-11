class_name SoundManagerNode
extends Node

const BeamTypes = preload("res://core/beam_types.gd")

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 8

var _players: Array[AudioStreamPlayer] = []
var _stream_red: AudioStreamWAV = null
var _stream_green: AudioStreamWAV = null
var _stream_blue: AudioStreamWAV = null
var _stream_white: AudioStreamWAV = null
var _stream_mismatch: AudioStreamWAV = null
var _stream_victory: AudioStreamWAV = null

func _ready() -> void:
	_init_streams()
	_init_pool()

func _init_pool() -> void:
	if not _players.is_empty():
		return
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		_players.append(player)

func _init_streams() -> void:
	_stream_red = _synthesize_tone(261.63, 0.16, 0.25)
	_stream_green = _synthesize_tone(329.63, 0.16, 0.25)
	_stream_blue = _synthesize_tone(392.00, 0.16, 0.25)
	_stream_white = _synthesize_tone(523.25, 0.16, 0.25)
	_stream_mismatch = _synthesize_mismatch()
	_stream_victory = _synthesize_victory()

func _synthesize_tone(freq: float, duration: float, harmonic_ratio: float = 0.2) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	var sample_count: int = int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-7.0 * t / duration)
		var sample: float = sin(2.0 * PI * freq * t) + harmonic_ratio * sin(2.0 * PI * (freq * 2.0) * t)
		sample *= env * 0.7
		var val: int = clampi(int(sample * 30000.0), -32767, 32767)
		data.encode_s16(i * 2, val)

	wav.data = data
	return wav

func _synthesize_mismatch() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	var duration: float = 0.10
	var sample_count: int = int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-10.0 * t / duration)
		var sample: float = sin(2.0 * PI * 110.0 * t) + 0.6 * sin(2.0 * PI * 165.0 * t)
		sample *= env * 0.6
		var val: int = clampi(int(sample * 30000.0), -32767, 32767)
		data.encode_s16(i * 2, val)

	wav.data = data
	return wav

func _synthesize_victory() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	var duration: float = 0.55
	var sample_count: int = int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var notes: Array[Dictionary] = [
		{"freq": 261.63, "start": 0.0},
		{"freq": 329.63, "start": 0.12},
		{"freq": 392.00, "start": 0.24},
		{"freq": 523.25, "start": 0.36}
	]

	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample_sum: float = 0.0
		for n in notes:
			var start_t: float = float(n["start"])
			if t >= start_t:
				var dt: float = t - start_t
				var env: float = exp(-5.0 * dt)
				sample_sum += sin(2.0 * PI * float(n["freq"]) * dt) * env * 0.25
		var val: int = clampi(int(sample_sum * 30000.0), -32767, 32767)
		data.encode_s16(i * 2, val)

	wav.data = data
	return wav

func is_sfx_enabled() -> bool:
	if not is_inside_tree():
		return true
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and "sfx_enabled" in game_state:
		return bool(game_state.sfx_enabled)
	return true

func get_sfx_volume() -> float:
	if not is_inside_tree():
		return 1.0
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and "sfx_volume" in game_state:
		return float(game_state.sfx_volume)
	return 1.0

func _get_available_player() -> AudioStreamPlayer:
	if _players.is_empty():
		_init_pool()
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

func play_stream(stream: AudioStream) -> void:
	if stream == null or not is_sfx_enabled():
		return
	if not is_inside_tree():
		return
	var vol: float = get_sfx_volume()
	if is_zero_approx(vol):
		return

	var player: AudioStreamPlayer = _get_available_player()
	player.stream = stream
	player.volume_db = linear_to_db(clampf(vol, 0.0001, 1.0))
	player.play()

func play_sink_lit(color: BeamTypes.RayColor) -> void:
	match color:
		BeamTypes.RayColor.RED:
			play_stream(_stream_red)
		BeamTypes.RayColor.GREEN:
			play_stream(_stream_green)
		BeamTypes.RayColor.BLUE:
			play_stream(_stream_blue)
		_:
			play_stream(_stream_white)

func play_mismatch() -> void:
	play_stream(_stream_mismatch)

func play_victory() -> void:
	play_stream(_stream_victory)

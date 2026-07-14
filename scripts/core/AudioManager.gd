class_name EmberAudioManager
extends Node

const DEFAULT_EVENT_ID := "ui_click"
const DEFAULT_MUSIC_CONTEXT := "menu"

var event_profiles: Dictionary = {
	"ui_click": {"frequency": 520.0, "duration": 0.045, "volume": 0.16},
	"card_play": {"frequency": 720.0, "duration": 0.07, "volume": 0.18},
	"card_attack": {"frequency": 360.0, "duration": 0.075, "volume": 0.20},
	"card_skill": {"frequency": 560.0, "duration": 0.09, "volume": 0.17},
	"card_power": {"frequency": 920.0, "duration": 0.12, "volume": 0.18},
	"turn_end": {"frequency": 260.0, "duration": 0.11, "volume": 0.16},
	"reward": {"frequency": 840.0, "duration": 0.09, "volume": 0.18},
	"potion": {"frequency": 680.0, "duration": 0.08, "volume": 0.17},
	"hit": {"frequency": 150.0, "duration": 0.065, "volume": 0.20},
	"block": {"frequency": 390.0, "duration": 0.075, "volume": 0.17},
	"heal": {"frequency": 760.0, "duration": 0.10, "volume": 0.16},
	"phase": {"frequency": 120.0, "duration": 0.16, "volume": 0.22},
	"phase_forge": {"frequency": 132.0, "duration": 0.18, "volume": 0.23},
	"phase_storm": {"frequency": 210.0, "duration": 0.17, "volume": 0.22},
	"phase_nexus": {"frequency": 92.0, "duration": 0.21, "volume": 0.24},
	"victory": {"frequency": 980.0, "duration": 0.18, "volume": 0.19},
	"defeat": {"frequency": 110.0, "duration": 0.18, "volume": 0.20},
	"map_select": {"frequency": 430.0, "duration": 0.06, "volume": 0.16},
	"campfire": {"frequency": 360.0, "duration": 0.12, "volume": 0.18},
	"shop": {"frequency": 610.0, "duration": 0.055, "volume": 0.15},
	"save": {"frequency": 910.0, "duration": 0.05, "volume": 0.14},
	"error": {"frequency": 180.0, "duration": 0.08, "volume": 0.18}
}

var event_stream_paths: Dictionary = {
	"ui_click": "res://assets/audio/ui_click.wav",
	"card_play": "res://assets/audio/card_play.wav",
	"card_attack": "res://assets/audio/card_attack.wav",
	"card_skill": "res://assets/audio/card_skill.wav",
	"card_power": "res://assets/audio/card_power.wav",
	"turn_end": "res://assets/audio/turn_end.wav",
	"reward": "res://assets/audio/reward.wav",
	"potion": "res://assets/audio/potion.wav",
	"hit": "res://assets/audio/hit.wav",
	"block": "res://assets/audio/block.wav",
	"heal": "res://assets/audio/heal.wav",
	"phase": "res://assets/audio/phase.wav",
	"phase_forge": "res://assets/audio/phase.wav",
	"phase_storm": "res://assets/audio/phase.wav",
	"phase_nexus": "res://assets/audio/phase.wav",
	"victory": "res://assets/audio/victory.wav",
	"defeat": "res://assets/audio/defeat.wav",
	"map_select": "res://assets/audio/map_select.wav",
	"campfire": "res://assets/audio/campfire.wav",
	"shop": "res://assets/audio/shop.wav",
	"save": "res://assets/audio/save.wav",
	"error": "res://assets/audio/error.wav"
}

var music_stream_paths: Dictionary = {
	"menu": "res://assets/audio/music/menu_loop.wav",
	"map": "res://assets/audio/music/map_loop.wav",
	"combat": "res://assets/audio/music/combat_loop.wav",
	"boss": "res://assets/audio/music/boss_loop.wav",
	"event": "res://assets/audio/music/event_loop.wav",
	"shop": "res://assets/audio/music/shop_loop.wav",
	"campfire": "res://assets/audio/music/campfire_loop.wav",
	"reward": "res://assets/audio/music/reward_loop.wav",
	"victory": "res://assets/audio/music/victory_loop.wav",
	"defeat": "res://assets/audio/music/defeat_loop.wav"
}

var stream_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var tone_player: AudioStreamPlayer
var enabled: bool = true
var music_enabled: bool = true
var master_volume: float = 1.0
var music_volume: float = 0.65
var headless_mode: bool = false
var suppress_stream_loading: bool = false
var stream_cache: Dictionary = {}
var music_cache: Dictionary = {}
var last_event_id: String = ""
var last_stream_path: String = ""
var last_stream_loaded: bool = false
var last_playback_mode: String = ""
var current_music_context: String = ""
var last_music_context: String = ""
var last_music_stream_path: String = ""
var last_music_stream_loaded: bool = false

func _ready() -> void:
	headless_mode = DisplayServer.get_name() == "headless"
	if headless_mode:
		return

	stream_player = AudioStreamPlayer.new()
	add_child(stream_player)

	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	tone_player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.2
	tone_player.stream = stream
	add_child(tone_player)

func play_event(event_id: String) -> void:
	last_event_id = event_id
	last_stream_path = stream_path_for_event(event_id)
	if suppress_stream_loading:
		last_stream_loaded = false
		last_playback_mode = "suppressed"
		return
	var stream := _load_event_stream(event_id)
	last_stream_loaded = stream != null
	last_playback_mode = "stream" if last_stream_loaded else "tone"

	if not enabled or headless_mode:
		return
	if stream != null and stream_player != null:
		_play_stream(stream)
		return
	if tone_player == null:
		return
	var profile: Dictionary = event_profiles.get(event_id, event_profiles.get(DEFAULT_EVENT_ID, {}))
	if profile.is_empty():
		return
	_play_tone(float(profile.get("frequency", 440.0)), float(profile.get("duration", 0.05)), float(profile.get("volume", 0.15)) * master_volume)

func apply_settings(settings: Dictionary) -> void:
	enabled = bool(settings.get("audio_enabled", enabled))
	master_volume = clamp(float(settings.get("master_volume", master_volume)), 0.0, 1.0)
	music_enabled = bool(settings.get("music_enabled", music_enabled))
	music_volume = clamp(float(settings.get("music_volume", music_volume)), 0.0, 1.0)
	_apply_music_volume()
	if not music_enabled and music_player != null:
		music_player.stop()

func stream_path_for_event(event_id: String) -> String:
	return str(event_stream_paths.get(event_id, event_stream_paths.get(DEFAULT_EVENT_ID, "")))

func stream_asset_exists(event_id: String) -> bool:
	var path: String = stream_path_for_event(event_id)
	return not path.is_empty() and FileAccess.file_exists(path)

func stream_asset_count() -> int:
	var count := 0
	for event_id in event_stream_paths.keys():
		if stream_asset_exists(str(event_id)):
			count += 1
	return count

func music_path_for_context(context_id: String) -> String:
	return str(music_stream_paths.get(context_id, music_stream_paths.get(DEFAULT_MUSIC_CONTEXT, "")))

func music_asset_exists(context_id: String) -> bool:
	var path: String = music_path_for_context(context_id)
	return not path.is_empty() and FileAccess.file_exists(path)

func music_asset_count() -> int:
	var count := 0
	for context_id in music_stream_paths.keys():
		if music_asset_exists(str(context_id)):
			count += 1
	return count

func play_music_context(context_id: String) -> void:
	last_music_context = context_id
	last_music_stream_path = music_path_for_context(context_id)
	if suppress_stream_loading:
		last_music_stream_loaded = false
		current_music_context = ""
		return
	var stream := _load_music_stream(context_id)
	last_music_stream_loaded = stream != null

	if current_music_context == context_id and music_player != null and music_player.playing:
		_apply_music_volume()
		return
	current_music_context = context_id
	if not music_enabled or headless_mode:
		return
	if stream == null or music_player == null:
		return
	music_player.stop()
	music_player.stream = stream
	_apply_music_volume()
	music_player.play()

func stop_music() -> void:
	current_music_context = ""
	if music_player != null:
		music_player.stop()

func set_stream_loading_suppressed(suppressed: bool) -> void:
	suppress_stream_loading = suppressed
	if suppress_stream_loading:
		release_streams_for_shutdown()

func release_streams_for_shutdown() -> void:
	if stream_player != null:
		stream_player.stop()
		stream_player.stream = null
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	if tone_player != null:
		tone_player.stop()
		tone_player.stream = null
	current_music_context = ""
	stream_cache.clear()
	music_cache.clear()

func _load_event_stream(event_id: String) -> AudioStream:
	var path: String = stream_path_for_event(event_id)
	if path.is_empty():
		return null
	if stream_cache.has(path):
		return stream_cache.get(path) as AudioStream

	var loaded_stream: AudioStream = null
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is AudioStream:
			loaded_stream = resource

	if loaded_stream == null and path.ends_with(".wav") and FileAccess.file_exists(path):
		if ClassDB.class_has_method("AudioStreamWAV", "load_from_file"):
			var wav_stream = AudioStreamWAV.load_from_file(path)
			if wav_stream is AudioStream:
				loaded_stream = wav_stream

	if loaded_stream != null:
		stream_cache[path] = loaded_stream
	return loaded_stream

func _load_music_stream(context_id: String) -> AudioStream:
	var path: String = music_path_for_context(context_id)
	if path.is_empty():
		return null
	if music_cache.has(path):
		return music_cache.get(path) as AudioStream

	var loaded_stream: AudioStream = null
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is AudioStream:
			loaded_stream = resource

	if loaded_stream == null and path.ends_with(".wav") and FileAccess.file_exists(path):
		if ClassDB.class_has_method("AudioStreamWAV", "load_from_file"):
			var wav_stream = AudioStreamWAV.load_from_file(path)
			if wav_stream is AudioStream:
				loaded_stream = wav_stream

	if loaded_stream is AudioStreamWAV:
		var wav := loaded_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = 0

	if loaded_stream != null:
		music_cache[path] = loaded_stream
	return loaded_stream

func _apply_music_volume() -> void:
	if music_player == null:
		return
	var final_volume: float = clamp(master_volume * music_volume, 0.0, 1.0)
	music_player.volume_db = -80.0 if final_volume <= 0.0 else linear_to_db(clamp(final_volume, 0.001, 1.0))

func _play_stream(stream: AudioStream) -> void:
	if stream_player == null:
		return
	if tone_player != null:
		tone_player.stop()
	stream_player.stop()
	stream_player.stream = stream
	stream_player.volume_db = -80.0 if master_volume <= 0.0 else linear_to_db(clamp(master_volume, 0.001, 1.0))
	stream_player.play()

func _play_tone(frequency: float, duration: float, volume: float) -> void:
	tone_player.stop()
	if stream_player != null:
		stream_player.stop()
	tone_player.play()
	var playback = tone_player.get_stream_playback()
	if playback == null:
		return
	var mix_rate: float = 22050.0
	var frame_count: int = int(mix_rate * duration)
	for i in range(frame_count):
		var t: float = float(i) / mix_rate
		var fade: float = 1.0 - (float(i) / max(1.0, float(frame_count)))
		var sample: float = sin(TAU * frequency * t) * volume * fade
		playback.push_frame(Vector2(sample, sample))

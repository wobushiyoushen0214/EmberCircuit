class_name EmberAudioManager
extends Node

var event_profiles: Dictionary = {
	"ui_click": {"frequency": 520.0, "duration": 0.045, "volume": 0.16},
	"card_play": {"frequency": 720.0, "duration": 0.07, "volume": 0.18},
	"turn_end": {"frequency": 260.0, "duration": 0.11, "volume": 0.16},
	"reward": {"frequency": 840.0, "duration": 0.09, "volume": 0.18},
	"potion": {"frequency": 680.0, "duration": 0.08, "volume": 0.17},
	"map_select": {"frequency": 430.0, "duration": 0.06, "volume": 0.16},
	"campfire": {"frequency": 360.0, "duration": 0.12, "volume": 0.18},
	"shop": {"frequency": 610.0, "duration": 0.055, "volume": 0.15},
	"save": {"frequency": 910.0, "duration": 0.05, "volume": 0.14},
	"error": {"frequency": 180.0, "duration": 0.08, "volume": 0.18}
}

var player: AudioStreamPlayer
var enabled: bool = true
var headless_mode: bool = false

func _ready() -> void:
	headless_mode = DisplayServer.get_name() == "headless"
	if headless_mode:
		return
	player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.2
	player.stream = stream
	add_child(player)

func play_event(event_id: String) -> void:
	if not enabled or headless_mode or player == null:
		return
	var profile: Dictionary = event_profiles.get(event_id, event_profiles.get("ui_click", {}))
	if profile.is_empty():
		return
	_play_tone(float(profile.get("frequency", 440.0)), float(profile.get("duration", 0.05)), float(profile.get("volume", 0.15)))

func _play_tone(frequency: float, duration: float, volume: float) -> void:
	player.stop()
	player.play()
	var playback = player.get_stream_playback()
	if playback == null:
		return
	var mix_rate: float = 22050.0
	var frame_count: int = int(mix_rate * duration)
	for i in range(frame_count):
		var t: float = float(i) / mix_rate
		var fade: float = 1.0 - (float(i) / max(1.0, float(frame_count)))
		var sample: float = sin(TAU * frequency * t) * volume * fade
		playback.push_frame(Vector2(sample, sample))

extends Node

const SAMPLE_RATE := 22050

var enabled: bool = true
var streams: Dictionary = {}


func _ready() -> void:
	streams["move"] = _make_tone([440.0], 0.055, 0.12)
	streams["blocked"] = _make_tone([190.0, 140.0], 0.16, 0.2)
	streams["placed"] = _make_tone([660.0, 880.0], 0.2, 0.18)
	streams["clear"] = _make_tone([523.25, 659.25, 783.99], 0.42, 0.17)
	streams["fail"] = _make_tone([220.0, 174.61, 130.81], 0.42, 0.18)
	streams["button"] = _make_tone([520.0], 0.07, 0.1)


func play_sfx(sound_name: String) -> void:
	if not enabled or not streams.has(sound_name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = streams[sound_name]
	player.volume_db = -7.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func set_enabled(value: bool) -> void:
	enabled = value


func _make_tone(frequencies: Array[float], duration: float, amplitude: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var segment_duration := duration / float(frequencies.size())
	for index in range(sample_count):
		var time := float(index) / float(SAMPLE_RATE)
		var segment_index := mini(frequencies.size() - 1, int(time / segment_duration))
		var envelope_in := minf(1.0, time / 0.008)
		var envelope_out := pow(maxf(0.0, 1.0 - time / duration), 1.35)
		var wave := sin(TAU * frequencies[segment_index] * time)
		var sample := clampf(wave * envelope_in * envelope_out * amplitude, -1.0, 1.0)
		pcm.encode_s16(index * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	return stream

extends Node
## Sound: one-shot effects from assets/audio/sfx (the original's "internal" sounds) and looping music from
## assets/audio/music (its "stream" tracks). Use AudioUtil.sfx("cursor") / AudioUtil.music("m_title") from anywhere.

const POOL := 12

var players: Array = []
var music_player := AudioStreamPlayer.new()
var fade_player := AudioStreamPlayer.new()
var current_music := ""
var sfx_volume_db := 0.0
var music_volume_db := -6.0
var cache := {}
var muted := false

func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	add_child(music_player)
	add_child(fade_player)
	music_player.volume_db = music_volume_db

func _load(path: String) -> AudioStream:
	if not cache.has(path):
		cache[path] = load(path) if ResourceLoader.exists(path) else null
	return cache[path]

func sfx(sfx_name: String) -> void:
	if muted or players.is_empty():
		return
	var s := _load("res://assets/audio/sfx/%s.ogg" % sfx_name)
	if s == null:
		return
	for p in players:
		if not (p as AudioStreamPlayer).playing:
			p.stream = s
			p.volume_db = sfx_volume_db
			p.play()
			return
	# all busy: steal the first one
	players[0].stream = s
	players[0].play()

func music(name: String, loop := true) -> void:
	if name in ["m_win", "m_lose"]:
		loop = false
	if not music_player.is_inside_tree():
		call_deferred("music", name, loop)
		return
	if name == current_music:
		return
	current_music = name
	var s := _load("res://assets/audio/music/%s.ogg" % name)
	if s == null:
		music_player.stop()
		return
	# crossfade: the old track fades out on the second player
	if music_player.playing:
		fade_player.stream = music_player.stream
		fade_player.volume_db = music_player.volume_db
		fade_player.play(music_player.get_playback_position())
		var tw := create_tween()
		tw.tween_property(fade_player, "volume_db", -60.0, 0.6)
		tw.tween_callback(fade_player.stop)
	if s is AudioStreamOggVorbis:
		s.loop = loop
	music_player.stream = s
	music_player.volume_db = -40.0 if not muted else -80.0
	music_player.play()
	var tw2 := create_tween()
	tw2.tween_property(music_player, "volume_db", music_volume_db, 0.6)

func stop_music() -> void:
	current_music = ""
	music_player.stop()

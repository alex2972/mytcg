class_name AudioUtil
extends RefCounted
## Plays sounds through the Audio autoload without a hard identifier dependency (scripts also load in test runs).

static func _node() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("Audio")
	return null

static func sfx(name: String) -> void:
	var a := _node()
	if a != null:
		a.sfx(name)

static func music(name: String, loop := true) -> void:
	var a := _node()
	if a != null:
		a.music(name, loop)

static func stop_music() -> void:
	var a := _node()
	if a != null:
		a.stop_music()

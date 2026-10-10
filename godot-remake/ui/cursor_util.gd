class_name CursorUtil
extends RefCounted
## Sets the GameCursor autoload's state without a hard identifier dependency (so scripts also load in test runs).

static func set_state(s: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var gc = (loop as SceneTree).root.get_node_or_null("GameCursor")
		if gc != null:
			gc.set_state(s)

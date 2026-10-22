class_name NetNode
extends Node
## The only RPC endpoints of the online game, identical on server and client (Godot 4 matches RPCs by
## their index in the node's RPC list, so both sides must use this same script).
## Every host (server or client) has its own SceneMultiplayer for its subtree and a child named "Net".
##   c2s(kind, rid, args)     client -> server request (rid > 0 expects a "reply" with the same rid)
##   s2c(kind, rid, payload)  server -> client: kind "reply" answers rid, anything else is a push
## Arguments are untyped on purpose: a malicious client could send anything, and the handler validates.

var handler: Object = null       ## GameServer on the server, OnlineClient on a client

@rpc("any_peer", "call_remote", "reliable")
func c2s(kind, rid, args) -> void:
	if handler != null and handler.has_method("on_c2s"):
		handler.on_c2s(multiplayer.get_remote_sender_id(), kind, rid, args)

@rpc("authority", "call_remote", "reliable")
func s2c(kind, rid, payload) -> void:
	if handler != null and handler.has_method("on_s2c"):
		handler.on_s2c(kind, rid, payload)

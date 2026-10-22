class_name Protocol
extends RefCounted
## Shared protocol constants and helpers (client and server).

const VERSION := 1
const DEFAULT_PORT := 9080
const DEFAULT_URL := "ws://127.0.0.1:9080"

## Error codes (string values travel in {"ok": false, "error": <code>}).
const ERRORS := ["outdated_client", "not_authenticated", "bad_credentials", "name_taken", "bad_name", "bad_password",
	"rate_limited", "busy", "not_found", "invalid_args", "not_your_turn", "not_your_decision", "illegal_action",
	"deck_invalid", "not_enough_dp", "set_complete", "unavailable", "already_in_duel", "server_error", "unknown_request",
	"timeout", "not_connected", "kicked", "unknown_account", "unknown_product", "save_failed", "in_queue", "not_in_duel"]

## Files whose content must be identical on client and server (rules, cards, shop).
const HASHED_FILES := ["res://data/cards.json", "res://data/card_tiers.json", "res://data/shop/catalog.json",
	"res://data/fusions.json", "res://data/limits.json", "res://data/card_pack.bin", "res://data/card_id.bin"]
const HASHED_DIRS := ["res://data/effects"]

static var _hash := ""

## SHA-256 over the rules/card data, so a client with different data is refused at hello.
static func data_hash() -> String:
	if _hash != "":
		return _hash
	var files: Array = HASHED_FILES.duplicate()
	for dir in HASHED_DIRS:
		var names := DirAccess.get_files_at(dir)
		names.sort()
		for n in names:
			if n.ends_with(".json"):
				files.append(dir + "/" + n)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(str(VERSION).to_utf8_buffer())
	for f in files:
		if FileAccess.file_exists(f):
			ctx.update(f.to_utf8_buffer())
			ctx.update(FileAccess.get_file_as_bytes(f))
	_hash = ctx.finish().hex_encode()
	return _hash

static func ok(data := {}) -> Dictionary:
	var out := {"ok": true}
	out.merge(data)
	return out

static func fail(code: String, extra := {}) -> Dictionary:
	var out := {"ok": false, "error": code}
	out.merge(extra)
	return out

## Converts any engine value into plain data that can travel over RPC (no Objects, no Callables).
## DCard becomes its uid. Depth and size are bounded.
static func plain(v, depth := 0):
	if depth > 12:
		return null
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return v
		TYPE_STRING_NAME:
			return str(v)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return [v.x, v.y]
		TYPE_ARRAY:
			var out := []
			for x in v:
				var p = plain(x, depth + 1)
				if p != null or x == null:
					out.append(p)
			return out
		TYPE_DICTIONARY:
			var out := {}
			for k in v:
				if str(k).begins_with("_"):
					continue
				var p = plain(v[k], depth + 1)
				if p != null or v[k] == null:
					out[str(k)] = p
			return out
		TYPE_OBJECT:
			if v is DCard:
				return (v as DCard).uid
			return null
		TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY:
			return Array(v)
	return null

## Is `v` made only of plain data (what a client may send)? Bounded depth/size.
static func is_plain(v, depth := 0, budget := [2000]) -> bool:
	budget[0] -= 1
	if budget[0] < 0 or depth > 8:
		return false
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			return true
		TYPE_STRING:
			return (v as String).length() <= 4096
		TYPE_ARRAY:
			if (v as Array).size() > 256:
				return false
			for x in v:
				if not is_plain(x, depth + 1, budget):
					return false
			return true
		TYPE_DICTIONARY:
			if (v as Dictionary).size() > 64:
				return false
			for k in v:
				if typeof(k) != TYPE_STRING or (k as String).length() > 64 or not is_plain(v[k], depth + 1, budget):
					return false
			return true
	return false

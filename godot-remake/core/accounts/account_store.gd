class_name AccountStore
extends RefCounted
## Local account database: one folder per account under `root`.
##   <root>/index.json                  {"accounts": [{"id", "name"}], "active": id}
##   <root>/<id>/profile.json           {"id", "name", "dp", "created"}
##   <root>/<id>/collection.json        Collection counts (CardDB index -> copies)
##   <root>/<id>/working_deck.ydc       the deck editor's autosaved deck
##   <root>/<id>/purchases.jsonl        one JSON line per completed purchase (audit log)
## This plays the part of the future server database. Only the backend (LocalShopBackend) and the
## account-switching code write to it; screens read through the backend / Session.

const DEFAULT_ROOT := "user://accounts"
const LEGACY_COLLECTION := "user://collection.json"
const LEGACY_DECK := "user://working_deck.ydc"

var root: String
var starting_dp := 0
var _index := {"accounts": [], "active": ""}

func _init(root_dir := DEFAULT_ROOT, start_dp := 0) -> void:
	root = root_dir.trim_suffix("/")
	starting_dp = start_dp
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
	var index_path := root + "/index.json"
	var parsed = _read_json(index_path)
	if parsed is Dictionary and parsed.get("accounts") is Array:
		_index = parsed
	elif FileAccess.file_exists(index_path):
		quarantine(index_path)
		rebuild_index()

## Rebuilds index.json from the account folders (each valid profile.json). Returns how many were found.
func rebuild_index() -> int:
	var active: String = str(_index.get("active", ""))
	_index = {"accounts": [], "active": ""}
	var dir := ProjectSettings.globalize_path(root)
	var ids := DirAccess.get_directories_at(dir)
	ids.sort()
	for id in ids:
		var p = _read_json(profile_path(id))
		if p is Dictionary and str(p.get("id", "")) == id:
			(_index["accounts"] as Array).append({"id": id, "name": str(p.get("name", id))})
	if has_account(active):
		_index["active"] = active
	_save_index()
	return (_index["accounts"] as Array).size()

## Checks every account file at startup. Unreadable files are moved aside (never overwritten) and
## accounts missing from the index are added back. Returns {"accounts", "quarantined": [paths], "reindexed"}.
func validate() -> Dictionary:
	var quarantined := []
	var dir := ProjectSettings.globalize_path(root)
	var missing := 0
	for id in DirAccess.get_directories_at(dir):
		for path in [profile_path(id), collection_path(id)]:
			if FileAccess.file_exists(path) and not _read_json(path) is Dictionary:
				quarantined.append(quarantine(path))
		if FileAccess.file_exists(profile_path(id)) and not has_account(id):
			missing += 1
	if missing > 0:
		rebuild_index()
	return {"accounts": accounts().size(), "quarantined": quarantined, "reindexed": missing}

## Moves a damaged file to "<path>.corrupt-<unix time>" so nothing overwrites it; returns the new path.
static func quarantine(path: String) -> String:
	var target := "%s.corrupt-%d" % [path, int(Time.get_unix_time_from_system())]
	DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(target))
	push_warning("Damaged save moved aside: %s" % target)
	return target

## Account id for a display name, compared case-insensitively ("" when none).
func find_by_name(display_name: String) -> String:
	var key := display_name.strip_edges().to_lower()
	for a in _index["accounts"]:
		if str(a["name"]).to_lower() == key:
			return str(a["id"])
	return ""

func accounts() -> Array:
	return (_index["accounts"] as Array).duplicate(true)

func has_account(id: String) -> bool:
	return accounts().any(func(a): return a["id"] == id)

func active_id() -> String:
	return str(_index.get("active", ""))

func set_active(id: String) -> bool:
	if not has_account(id):
		return false
	_index["active"] = id
	_save_index()
	return true

## Creates an account with its starting DP and starter collection. Returns its id ("" if the name is unusable).
## `migrate_legacy` copies the pre-account single-player save into it (used for the very first account only).
func create_account(display_name: String, db: CardDB, migrate_legacy := false) -> String:
	var clean := display_name.strip_edges().left(16)
	if clean.is_empty():
		return ""
	var id := _new_id(clean)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(account_dir(id)))
	var profile := {"id": id, "name": clean, "dp": starting_dp, "created": int(Time.get_unix_time_from_system())}
	write_json(profile_path(id), profile)
	if migrate_legacy and FileAccess.file_exists(LEGACY_COLLECTION):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(LEGACY_COLLECTION), ProjectSettings.globalize_path(collection_path(id)))
	if migrate_legacy and FileAccess.file_exists(LEGACY_DECK):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(LEGACY_DECK), ProjectSettings.globalize_path(deck_path(id)))
	if not FileAccess.file_exists(collection_path(id)):
		var c := Collection.new()
		c.db = db
		c.give_starter()
		c.save(collection_path(id))
	if not FileAccess.file_exists(deck_path(id)):
		Collection.starter_deck(db).save_working(db, deck_path(id))
	(_index["accounts"] as Array).append({"id": id, "name": clean})
	if active_id() == "":
		_index["active"] = id
	_save_index()
	return id

func account_dir(id: String) -> String:
	return "%s/%s" % [root, id]

func profile_path(id: String) -> String:
	return account_dir(id) + "/profile.json"

func collection_path(id: String) -> String:
	return account_dir(id) + "/collection.json"

func deck_path(id: String) -> String:
	return account_dir(id) + "/working_deck.ydc"

func purchases_path(id: String) -> String:
	return account_dir(id) + "/purchases.jsonl"

func profile(id: String) -> Dictionary:
	var parsed = _read_json(profile_path(id))
	return parsed if parsed is Dictionary else {}

func save_profile(p: Dictionary) -> Error:
	return write_json(profile_path(str(p["id"])), p)

func append_purchase(id: String, record: Dictionary) -> void:
	var path := purchases_path(id)
	var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(record))
	f.close()

func _new_id(display_name: String) -> String:
	var base := display_name.to_lower().validate_filename().replace(" ", "_")
	if base.is_empty():
		base = "account"
	var id := base
	var n := 2
	while has_account(id) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(account_dir(id))):
		id = "%s_%d" % [base, n]
		n += 1
	return id

func _save_index() -> void:
	write_json(root + "/index.json", _index)

static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data

## Write to a temporary file and rename, so a crash never leaves a half-written save.
static func write_json(path: String, data: Variant) -> Error:
	var temporary := path + ".tmp"
	var f := FileAccess.open(temporary, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, "\t"))
	f.flush()
	var error := f.get_error()
	f.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))

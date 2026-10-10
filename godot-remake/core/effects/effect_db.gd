class_name EffectDB
extends RefCounted
## Card effect definitions, keyed by the card's Konami number (CardDB card "number"), loaded from data/effects/*.json.
## An entry looks like {"name": "...", "fx": [ {effect}, ... ]}; see docs/EFFECTS.md for the effect language.

var entries := {}      ## number (int) -> Array of effect dictionaries
var cards: CardDB

static func load_default(card_db: CardDB) -> EffectDB:
	var db := EffectDB.new()
	db.cards = card_db
	var dir := DirAccess.open("res://data/effects")
	if dir == null:
		return db
	var files := Array(dir.get_files()).filter(func(f): return f.ends_with(".json"))
	files.sort()
	for f in files:
		db.merge_file("res://data/effects/" + f)
	return db

func merge_file(path: String) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "bad effects file " + path)
	for key in parsed:
		if key.begins_with("_"):
			continue
		var entry: Dictionary = parsed[key]
		if key.is_valid_int():
			entries[int(key)] = entry.get("fx", [])
			continue
		var found := false
		for i in range(1, cards.cards.size()):
			if cards.card_name(i, "eng") == key:
				entries[int(cards.cards[i]["number"])] = entry.get("fx", [])
				found = true
		if not found:
			push_warning("effects: no card named " + key)

func for_number(number: int) -> Array:
	return entries.get(number, [])

func has_card(number: int) -> bool:
	return entries.has(number)

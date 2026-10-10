class_name CardDB
extends RefCounted
## Read-only card database built by tools/build_data.py from the original game data.

const LANGS := ["eng", "fra", "ger", "ita", "spa", "jpn"]
const ATTRIBUTES := {1: "LIGHT", 2: "DARK", 3: "WATER", 4: "FIRE", 5: "EARTH", 6: "WIND", 7: "DIVINE", 8: "SPELL", 9: "TRAP"}
const CATEGORIES := ["Normal", "Effect", "Fusion", "Ritual"]
## Monster type names indexed by the card "kind" (1..20); taken from the original game's string table.
const RACES := ["", "Dragon", "Zombie", "Fiend", "Pyro", "Sea Serpent", "Rock", "Machine", "Fish", "Dinosaur", "Insect", "Beast", "Beast-Warrior", "Plant", "Aqua", "Warrior", "Winged Beast", "Fairy", "Spellcaster", "Thunder", "Reptile"]

var _ai_ids := PackedInt32Array()
var _fusions := {}
var cards: Array = []   ## index 0 is the card back; real cards are 1..size-1

static func load_default() -> CardDB:
	var db := CardDB.new()
	var f := FileAccess.open("res://data/cards.json", FileAccess.READ)
	assert(f != null, "data/cards.json missing - run tools/build_data.py")
	db.cards = JSON.parse_string(f.get_as_text())["cards"]
	return db

## The id the original's AI/effect code uses for a card (data/card_id.bin, indexed by card index).
func ai_id(index: int) -> int:
	if _ai_ids.is_empty():
		var bytes := FileAccess.get_file_as_bytes("res://data/card_id.bin")
		for i in range(bytes.size() / 2):
			_ai_ids.append(bytes.decode_u16(i * 2))
	return _ai_ids[index] if index >= 0 and index < _ai_ids.size() else 0xffff

## Fusion-Material names of a Fusion Monster (data/fusions.json), or [] when it has no recipe.
func fusion_recipe(card_name: String) -> Array:
	if _fusions.is_empty():
		_fusions = JSON.parse_string(FileAccess.get_file_as_string("res://data/fusions.json"))
	return _fusions.get(card_name, [])

func count() -> int:
	return cards.size() - 1

func card(index: int) -> Dictionary:
	return cards[index]

func card_name(index: int, lang := "eng") -> String:
	return cards[index].get("name", {}).get(lang, "")

func card_desc(index: int, lang := "eng") -> String:
	return cards[index].get("desc", {}).get(lang, "")

func art_path(index: int, small := false) -> String:
	var key := "mini" if small else "art"
	var override := "res://assets/art_override/%d.png" % int(cards[index].get("number", -1))
	if not small and FileAccess.file_exists(override):
		return override
	var base: String = cards[index].get(key, "")
	return "" if base.is_empty() else "res://assets/%s/%s.png" % ["mini" if small else "cards", base]

func is_monster(index: int) -> bool:
	return cards[index].get("type", "") == "monster"

func kind_label(index: int) -> String:
	var c: Dictionary = cards[index]
	match c.get("type", ""):
		"spell": return "Spell (%s)" % c.get("subtype_name", "?")
		"trap": return "Trap (%s)" % c.get("subtype_name", "?")
		"monster": return "%s monster" % CATEGORIES[c.get("category", 0)]
	return ""

func search(text: String, type_filter := "", lang := "eng") -> Array:
	var out := []
	var t := text.to_lower()
	for i in range(1, cards.size()):
		var c: Dictionary = cards[i]
		if type_filter != "" and c.get("type", "") != type_filter:
			continue
		if t != "" and not card_name(i, lang).to_lower().contains(t) and not card_desc(i, lang).to_lower().contains(t):
			continue
		out.append(i)
	return out

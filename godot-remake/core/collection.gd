class_name Collection
extends RefCounted
## The player's card collection: copies owned per card (CardDB index). Saved to user://collection.json.
## The Card List shows the "JOEY pool": the 350 cards whose card_pack value has bit 2 set, sorted by name
## (this is the set the original's Card List counts as "x/350").

const SAVE_PATH := "user://collection.json"
const POOL_BIT := 4

var db: CardDB
var counts := {}                 ## card index -> copies owned

static func load_default(card_db: CardDB, path := SAVE_PATH) -> Collection:
	var c := Collection.new()
	c.db = card_db
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			for k in parsed:
				c.counts[int(k)] = int(parsed[k])
			return c
	c.give_starter()
	c.save(path)
	return c

## First-run collection: the cards of the default deck (3 copies max each), like a starter set.
func give_starter() -> void:
	var d := Deck.load_file("res://data/default_deck.ydc", db)
	if d == null:
		return
	for i in d.main + d.extra + d.side:
		counts[i] = mini(3, int(counts.get(i, 0)) + 1)
	for i in counts.keys():
		counts[i] = mini(3, int(counts[i]) + 1)       # one spare copy of everything, so the deck can be edited

func save(path := SAVE_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(counts))

func owned(idx: int) -> int:
	return int(counts.get(idx, 0))

func add(idx: int, n := 1) -> void:
	counts[idx] = owned(idx) + n

## Cheat/debug: own 3 of every card.
func unlock_all() -> void:
	for i in range(1, db.cards.size()):
		counts[i] = 3

## The 350 cards of the Card List, in on-screen order (alphabetical).
func pool() -> Array:
	var out := []
	var pack := _pack()
	for i in range(1, db.cards.size()):
		if i < pack.size() and (pack[i] & POOL_BIT) != 0:
			out.append(i)
	out.sort_custom(func(a, b): return db.card_name(a).to_lower() < db.card_name(b).to_lower())
	return out

func owned_in_pool() -> int:
	var n := 0
	for i in pool():
		if owned(i) > 0:
			n += 1
	return n

func _pack() -> PackedInt32Array:
	var bytes := FileAccess.get_file_as_bytes("res://data/card_pack.bin")
	var out := PackedInt32Array()
	for i in range(bytes.size() / 2):
		out.append(bytes.decode_u16(i * 2))
	return out

class_name Collection
extends RefCounted
## The player's card collection: copies owned per card (CardDB index). Each account has its own file
## (AccountStore.collection_path); without the Session autoload it falls back to user://collection.json.
## The Card List shows the "JOEY pool": the 350 cards whose card_pack value has bit 2 set, sorted by name
## (this is the set the original's Card List counts as "x/350").

const SAVE_PATH := "user://collection.json"
const POOL_BIT := 4
const MAX_OWNED := 3             ## copies of one version (card index) an account can hold; versions are counted separately

var db: CardDB
var counts := {}                 ## card index -> copies owned

static func load_default(card_db: CardDB, path := "") -> Collection:
	if path.is_empty():
		path = active_path()
	var c := Collection.new()
	c.db = card_db
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			for k in parsed:
				c.counts[int(k)] = mini(MAX_OWNED, int(parsed[k]))     # saves from before the cap
			return c
	c.give_starter()
	c.save(path)
	return c

## What a brand-new account owns, and starts with in its deck: card name -> copies.
const STARTER := {"Polymerization": 3, "Little D": 3}

## First-run collection: only the starter cards (see STARTER).
func give_starter() -> void:
	for i in starter_cards(db):
		counts[i] = mini(MAX_OWNED, int(counts.get(i, 0)) + 1)

## The starter cards as a list of CardDB indices (one entry per copy; the first version of each name).
static func starter_cards(card_db: CardDB) -> Array:
	var out := []
	for card_name: String in STARTER:
		for i in range(1, card_db.cards.size()):
			if card_db.card_name(i) == card_name:
				for k in int(STARTER[card_name]):
					out.append(i)
				break
	return out

## The deck a new account starts with: just the starter cards (too small for a duel until it is built up).
static func starter_deck(card_db: CardDB) -> Deck:
	var deck := Deck.new()
	deck.main = starter_cards(card_db)
	return deck

## The biggest Main Deck this collection can make under the deck rules: Fusion monsters do not count,
## and copies are capped per card name (alternate versions and "treated as" cards share a limit).
func max_deck_size() -> int:
	var by_name := {}
	for idx in counts:
		if DeckRules.belongs_in_extra(db, int(idx)):
			continue
		var key := DeckRules.limit_name(db, int(idx))
		by_name[key] = {"owned": int((by_name.get(key, {}) as Dictionary).get("owned", 0)) + owned(int(idx)), "limit": DeckRules.copy_limit(db, int(idx))}
	var total := 0
	for key in by_name:
		total += mini(int(by_name[key]["owned"]), int(by_name[key]["limit"]))
	return total

## False when the collection is too small to ever fill a 40-card Main Deck.
func can_build_deck() -> bool:
	return max_deck_size() >= DeckRules.MIN_MAIN

# --- stable card identity (Konami numbers) for the network and the server store ---------------

static var _by_number := {}
static var _by_number_db: CardDB = null

## CardDB index of a Konami card number (0 when unknown).
static func index_of_number(card_db: CardDB, number: int) -> int:
	if _by_number_db != card_db:
		_by_number = {}
		for i in range(1, card_db.cards.size()):
			var n := int(card_db.cards[i].get("number", -1))
			if not _by_number.has(n):
				_by_number[n] = i
		_by_number_db = card_db
	return int(_by_number.get(number, 0))

## {"<number>": copies} -> {index: copies} (unknown numbers are dropped).
static func counts_from_numbers(card_db: CardDB, numbers: Dictionary) -> Dictionary:
	var out := {}
	for k in numbers:
		var i := index_of_number(card_db, int(k))
		if i > 0:
			out[i] = mini(MAX_OWNED, int(out.get(i, 0)) + int(numbers[k]))
	return out

## {index: copies} -> {"<number>": copies}
func to_numbers() -> Dictionary:
	var out := {}
	for i in counts:
		if int(counts[i]) > 0:
			out[str(int(db.cards[int(i)].get("number", 0)))] = int(counts[i])
	return out

## The signed-in account's collection file.
static func active_path() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var session: Node = tree.root.get_node_or_null("Session") if tree != null else null
	return session.collection_path() if session != null else SAVE_PATH

func save(path := "") -> Error:
	return AccountStore.write_json(active_path() if path.is_empty() else path, counts)

func owned(idx: int) -> int:
	return int(counts.get(idx, 0))

func add(idx: int, n := 1) -> void:
	counts[idx] = mini(MAX_OWNED, owned(idx) + n)

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

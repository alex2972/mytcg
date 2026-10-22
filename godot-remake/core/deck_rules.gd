class_name DeckRules
extends RefCounted
## Deck-building rules read from the original's tutorial text (strings 4201-4265).
## MAX_MAIN/MAX_SIDE and native restriction storage remain unverified.
## Restrictions use the original-game list supplied by the owner (2026-10-19).

const MIN_MAIN := 40
const MAX_MAIN := 60
const MAX_EXTRA := 15
const MAX_SIDE := 15
const MAX_COPIES := 3

## Fusion monsters live in the extra ("Fusion") deck and do not count toward the 40-card minimum.
static func belongs_in_extra(db: CardDB, idx: int) -> bool:
	var c: Dictionary = db.card(idx)
	return c.get("type", "") == "monster" and c.get("category", 0) == 2

static var _limits := {}
static var _limits_loaded := false

## Copies allowed in one deck: 3 normally, less for Limited (1) / Semi-Limited (2) / Forbidden (0) cards.
## The list comes from data/limits.json (the original's own list has not been located in the exe yet).
static func copy_limit(db: CardDB, idx: int) -> int:
	if not _limits_loaded:
		_limits_loaded = true
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/limits.json"))
		if parsed is Dictionary:
			for k in parsed:
				if not k.begins_with("_"):
					_limits[k.to_lower()] = int(parsed[k])
	return mini(MAX_COPIES, int(_limits.get(limit_name(db, idx), MAX_COPIES)))

## The name a card's copy limit is counted under. Alternate-art versions share their name; cards that are
## "treated as" another card (FxOps.NAME_ALIASES, e.g. Cyber Harpie = Harpie Lady) count under that card's name.
static func limit_name(db: CardDB, idx: int) -> String:
	var n := db.card_name(idx)
	return str(FxOps.NAME_ALIASES.get(n, n)).to_lower()

## Copies in the whole deck (Main + Fusion + Side) that share this card's limit name.
static func group_copies(deck: Deck, db: CardDB, idx: int) -> int:
	var key := limit_name(db, idx)
	var n := 0
	for i in deck.main + deck.extra + deck.side:
		if limit_name(db, i) == key:
			n += 1
	return n

static func section_of(deck: Deck, section: String) -> Array:
	match section:
		"extra": return deck.extra
		"side": return deck.side
	return deck.main

## Returns "" when the card may be added to the given section, else a short reason.
static func why_not(deck: Deck, db: CardDB, idx: int, section: String, owned := -1) -> String:
	if section == "extra" and not belongs_in_extra(db, idx):
		return "Only Fusion Monsters go in the Fusion Deck."
	if section != "extra" and belongs_in_extra(db, idx):
		return "Fusion Monsters belong in the Fusion Deck."
	if owned >= 0 and deck.copies(idx) >= owned:
		return "You don't own more copies of this card."
	if group_copies(deck, db, idx) >= copy_limit(db, idx):
		return "You can only have %d copies of each card." % copy_limit(db, idx)
	var cap: int = {"main": MAX_MAIN, "extra": MAX_EXTRA, "side": MAX_SIDE}[section]
	if section_of(deck, section).size() >= cap:
		return "That section is full (%d)." % cap
	return ""

static func add(deck: Deck, db: CardDB, idx: int, section := "", owned := -1) -> String:
	if section == "":
		section = "extra" if belongs_in_extra(db, idx) else "main"
	var reason := why_not(deck, db, idx, section, owned)
	if reason == "":
		section_of(deck, section).append(idx)
	return reason

## Problems that make the deck unusable for a duel (empty array = valid).
static func problems(deck: Deck, db: CardDB) -> Array:
	var out := []
	if deck.main.size() < MIN_MAIN:
		out.append("Deck needs at least %d cards (has %d)." % [MIN_MAIN, deck.main.size()])
	for i in deck.main + deck.extra + deck.side:
		if group_copies(deck, db, i) > copy_limit(db, i):
			out.append("Too many copies of %s." % db.card_name(i))
			break
	return out

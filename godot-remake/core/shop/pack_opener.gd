class_name PackOpener
extends RefCounted
## Rolls the contents of a product. Pure: the caller passes the card pools and the RNG, so the
## same code can run on the future server (which owns the RNG) and in tests (fixed seeds).
##
## Product contents are a list of slots. Each slot draws `count` cards; every card first picks a rarity
## by weight, then a card from that rarity's pool:
##   {"slots": [{"count": 5, "rarities": [
##       {"rarity": "ultra_rare", "pool": "m1_ultra", "weight": 1},
##       {"rarity": "common", "pool": "m1_common", "weight": 99}]}]}
## The shorthand {"count": 5, "pool": "x"} means one "common" rarity.
## A set slot {"set_pool": "rf1_fusion_sets", "rarity": "fusion_set"} gives one whole set of cards that belong
## together (a Fusion monster and its two materials, a Ritual monster and its Ritual Spell), in set order.
## A set is picked by weight among the sets that still have a card the account can receive; cards it already
## owns 3 of are left out of the pack. A set may carry its own rarity and weight (see "sets" below), e.g. an
## ultra rare set that shows and reveals gold and comes up less often than the others (weight < 1).
## With "equal_odds": true a rarity's weight is the number of cards it still has, so every card has the same
## chance and the rarity is only a label (it still decides the section and the golden reveal).

## Rarity of a slot entry that does not name one.
const DEFAULT_RARITY := "common"

## Returns [{"index": card, "rarity": name}, ...].
## `owned` (card index -> copies already owned) enforces the inventory cap: a card the account holds
## `Collection.MAX_OWNED` copies of is never rolled, counting copies rolled earlier in the same pack.
## A card appears at most once per slot. When a rarity's pool runs dry its weight goes to the others;
## when every pool is dry the pack simply has fewer cards.
static func roll(contents: Dictionary, pools: Dictionary, rng: RandomNumberGenerator, owned := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var have := owned.duplicate()
	for slot: Dictionary in contents.get("slots", []):
		if slot.has("set_pool"):
			var all_sets: Array = pools.get(str(slot["set_pool"]), [])
			var meta: Array = sets_info(pools, str(slot["set_pool"]))
			var open := []
			var total := 0.0
			for k in all_sets.size():
				if (all_sets[k] as Array).any(func(c): return int(have.get(int(c), 0)) < Collection.MAX_OWNED):
					open.append(k)
					total += float(meta[k]["weight"])
			if open.is_empty() or total <= 0.0:
				continue
			var x := rng.randf() * total
			var chosen: int = open[open.size() - 1]
			for k in open:
				x -= float(meta[k]["weight"])
				if x < 0.0:
					chosen = k
					break
			var set_rarity := str(meta[chosen].get("rarity", "")) if str(meta[chosen].get("rarity", "")) != "" else str(slot.get("rarity", DEFAULT_RARITY))
			for c in all_sets[chosen]:
				if int(have.get(int(c), 0)) < Collection.MAX_OWNED:
					out.append({"index": int(c), "rarity": set_rarity})
					have[int(c)] = int(have.get(int(c), 0)) + 1
			continue
		var rarities := slot_rarities(slot)
		var equal_odds := bool(slot.get("equal_odds", false))
		var taken := {}
		for _i in int(slot.get("count", 0)):
			var options := []
			var total := 0.0
			for r: Dictionary in rarities:
				var candidates: Array = (pools.get(str(r["pool"]), []) as Array).filter(func(c): return not taken.has(int(c)) and int(have.get(int(c), 0)) < Collection.MAX_OWNED)
				var weight: float = float(candidates.size()) if equal_odds else float(r["weight"])
				if not candidates.is_empty() and weight > 0.0:
					options.append({"rarity": r["rarity"], "cards": candidates, "weight": weight})
					total += weight
			if options.is_empty():
				break
			var x := rng.randf() * total
			var chosen: Dictionary = options[options.size() - 1]
			for o: Dictionary in options:
				x -= float(o["weight"])
				if x < 0.0:
					chosen = o
					break
			var list: Array = chosen["cards"]
			var card := int(list[rng.randi_range(0, list.size() - 1)])
			out.append({"index": card, "rarity": chosen["rarity"]})
			taken[card] = true
			have[card] = int(have.get(card, 0)) + 1
	return out

## A slot's rarity list in the long form.
static func slot_rarities(slot: Dictionary) -> Array:
	if slot.has("rarities"):
		return (slot["rarities"] as Array).map(func(r): return {"rarity": str(r.get("rarity", DEFAULT_RARITY)), "pool": str(r.get("pool", "")), "weight": float(r.get("weight", 1.0))})
	return [{"rarity": DEFAULT_RARITY, "pool": str(slot.get("pool", "")), "weight": 1.0}]

## What a product can contain, grouped by rarity (for the contents screen):
## [{"rarity", "chance" (percent per card, from the first slot that offers it), "cards": [index...]}].
static func describe(contents: Dictionary, pools: Dictionary) -> Array:
	var sections := {}
	var order := []
	for slot: Dictionary in contents.get("slots", []):
		if slot.has("set_pool"):
			var sets: Array = pools.get(str(slot["set_pool"]), [])
			var meta: Array = sets_info(pools, str(slot["set_pool"]))
			var total := 0.0
			for m in meta:
				total += float(m["weight"])
			var by_rarity := {}
			for k in sets.size():
				var key := str(meta[k].get("rarity", "")) if str(meta[k].get("rarity", "")) != "" else str(slot.get("rarity", DEFAULT_RARITY))
				if not by_rarity.has(key):
					by_rarity[key] = {"sets": 0, "weight": 0.0, "cards": []}
				by_rarity[key]["sets"] += 1
				by_rarity[key]["weight"] += float(meta[k]["weight"])
				for c in sets[k]:
					if not (by_rarity[key]["cards"] as Array).has(int(c)):
						(by_rarity[key]["cards"] as Array).append(int(c))
			for key in by_rarity:
				var part: Dictionary = by_rarity[key]
				var share := 100.0 * float(part["weight"]) / maxf(total, 0.0001)
				var caption := "%d of %d sets  ·  %.1f%% of packs" % [part["sets"], sets.size(), share] if share < 99.95 else "1 set per pack  ·  %d sets" % part["sets"]
				var short := "%s %.1f%%" % [str(slot.get("label", "")), share]
				if not sections.has(key):
					sections[key] = {"rarity": key, "chance": share, "cards": [], "ordered": true, "caption": caption, "_short": [short]}
					order.append(key)
				else:
					# Several slots share this rarity: "Fusion 5.1%  ·  Ritual 2.2% of packs".
					(sections[key]["_short"] as Array).append(short)
					sections[key]["caption"] = "  ·  ".join(PackedStringArray(sections[key]["_short"])) + " of packs"
				for c in part["cards"]:
					if not (sections[key]["cards"] as Array).has(int(c)):
						(sections[key]["cards"] as Array).append(int(c))
			continue
		var rarities := slot_rarities(slot)
		var equal_odds := bool(slot.get("equal_odds", false))
		var weight_of := func(r: Dictionary) -> float:
			return float((pools.get(str(r["pool"]), []) as Array).size()) if equal_odds else float(r["weight"])
		var total := 0.0
		for r: Dictionary in rarities:
			total += weight_of.call(r)
		for r: Dictionary in rarities:
			var key := str(r["rarity"])
			if not sections.has(key):
				sections[key] = {"rarity": key, "chance": 100.0 * weight_of.call(r) / maxf(total, 0.0001), "cards": []}
				order.append(key)
			for c in pools.get(str(r["pool"]), []):
				if not (sections[key]["cards"] as Array).has(int(c)):
					(sections[key]["cards"] as Array).append(int(c))
	return order.map(func(k): return sections[k])

## Resolves the catalog's pool definitions into lists of CardDB indices. Sources:
##   "card_list_pool"  the 350 Card List cards
##   "cards"           {"cards": ["Dark Magician", ...]} by English name (the first, normal-art version)
##   "sets"            {"sets": [["Skull Knight", "Tainted Wisdom", "Ancient Brain"], ...]}: lists of cards given together.
##                     A set can also be {"cards": [...], "rarity": "ultra_rare", "weight": 0.25}; plain sets weigh 1.
##   "filter"          {"base": "all" | "card_list_pool", "tiers": [1], "type": "monster" (or "types": ["spell", "trap"]),
##                      "categories": ["Normal", "Effect"], "min_level"/"max_level", "exclude_pools": ["other_pool"],
##                      "exclude_names": ["Card Name", ...]}
## Tokens (names ending in " Token") are never part of a filter pool.
## Tiers come from data/card_tiers.json (tools/tier_sorter): 1 = bottom, 2 = most cards, 3 = the best,
## 0 = special / never in packs. They are keyed by Konami number, so alternate-art versions have no tier.

const TIERS_PATH := "res://data/card_tiers.json"
static func build_pools(definitions: Dictionary, db: CardDB) -> Dictionary:
	var pools := {}
	# "filter" pools may exclude other pools, so resolve the simple sources first.
	for pass_no in 2:
		for name: String in definitions:
			var def: Dictionary = definitions[name]
			var source := str(def.get("source", ""))
			if (source == "filter") != (pass_no == 1):
				continue
			match source:
				"card_list_pool":
					pools[name] = _card_list_pool(db)
				"cards":
					pools[name] = (def.get("cards", []) as Array).map(func(n): return _index_of(db, str(n))).filter(func(i): return i > 0)
				"sets":
					var sets := []
					var meta := []
					for s in def.get("sets", []):
						var names: Array = (s["cards"] if s is Dictionary else s) as Array
						var cards: Array = names.map(func(n): return _index_of(db, str(n)))
						if not cards.has(0):
							sets.append(cards)
							meta.append({"rarity": str(s.get("rarity", "")) if s is Dictionary else "", "weight": float(s.get("weight", 1.0)) if s is Dictionary else 1.0})
						else:
							push_warning("Shop set %s has an unknown card name: %s" % [name, str(names)])
					pools[name] = sets
					pools[name + META_SUFFIX] = meta
				"filter":
					pools[name] = _filter(def, db, pools)
				_:
					pools[name] = []
	return pools

static func _card_list_pool(db: CardDB) -> Array:
	var c := Collection.new()
	c.db = db
	return c.pool()

static func _filter(def: Dictionary, db: CardDB, pools: Dictionary) -> Array:
	var base: Array = _card_list_pool(db) if str(def.get("base", "all")) == "card_list_pool" else range(1, db.cards.size())
	var tiers: Array = (def.get("tiers", []) as Array).map(func(t): return int(t))
	var tier_of := card_tiers() if not tiers.is_empty() else {}
	var seen_numbers := {}
	var excluded_names := {}
	for n in def.get("exclude_names", []):
		excluded_names[str(n)] = true
	var excluded := {}
	for p in def.get("exclude_pools", []):
		for i in pools.get(str(p), []):
			excluded[db.card_name(int(i))] = true      # by name, so other art versions are excluded too
	var categories: Array = (def.get("categories", []) as Array).map(func(n): return CardDB.CATEGORIES.find(str(n)))
	var out := []
	for i in base:
		var c := db.card(int(i))
		if def.has("type") and c.get("type", "") != def["type"]:
			continue
		if def.has("types") and not (def["types"] as Array).has(c.get("type", "")):
			continue
		if not categories.is_empty() and not categories.has(int(c.get("category", -1))):
			continue
		if def.has("max_level") and int(c.get("level", 99)) > int(def["max_level"]):
			continue
		if def.has("min_level") and int(c.get("level", 0)) < int(def["min_level"]):
			continue
		if excluded.has(db.card_name(int(i))) or excluded_names.has(db.card_name(int(i))) or db.card_name(int(i)).ends_with(" Token"):
			continue
		var number := int(c.get("number", -1))
		if not tiers.is_empty() and not tiers.has(int(tier_of.get(number, -1))):
			continue
		if seen_numbers.has(number):
			continue
		seen_numbers[number] = true
		out.append(int(i))
	return out

## Konami number -> tier (0-3).
static func card_tiers() -> Dictionary:
	var out := {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TIERS_PATH)) if FileAccess.file_exists(TIERS_PATH) else null
	if parsed is Dictionary:
		var tiers: Dictionary = parsed.get("tiers", {})
		for k in tiers:
			out[int(k)] = int(tiers[k])
	return out

## Per-set rarity and weight, aligned with pools[name] (sets without metadata weigh 1 and use the slot's rarity).
const META_SUFFIX := ":meta"

static func sets_info(pools: Dictionary, name: String) -> Array:
	var meta: Array = pools.get(name + META_SUFFIX, [])
	var sets: Array = pools.get(name, [])
	if meta.size() == sets.size():
		return meta
	var out := []
	for s in sets:
		out.append({"rarity": "", "weight": 1.0})
	return out

static func _index_of(db: CardDB, card_name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i).to_lower() == card_name.to_lower():
			return i
	return 0

class_name LocalShopBackend
extends ShopBackend
## Offline stand-in for the authoritative server: validates purchases, rolls pack contents with its
## own RNG, charges DP, adds the cards to the account's collection and logs the purchase.
## Everything a cheater could want to change happens here, never in the screens.

const CATALOG_PATH := "res://data/shop/catalog.json"

var store: AccountStore
var db: CardDB
var rng := RandomNumberGenerator.new()
var catalog := {}
var pools := {}

func _init(card_db: CardDB, root := AccountStore.DEFAULT_ROOT, catalog_path := CATALOG_PATH) -> void:
	db = card_db
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
	catalog = parsed if parsed is Dictionary else {}
	store = AccountStore.new(root, starting_dp())
	pools = PackOpener.build_pools(catalog.get("pools", {}), db)
	rng.randomize()

func starting_dp() -> int:
	return int(catalog.get("starting_dp", 0))

func get_profile(account_id: String) -> Dictionary:
	var p := store.profile(account_id)
	if p.is_empty():
		return {"ok": false, "error": "unknown_account"}
	return {"ok": true, "account": {"id": p["id"], "name": p["name"], "dp": int(p["dp"])}}

func get_catalog() -> Dictionary:
	var products := []
	for p: Dictionary in catalog.get("products", []):
		products.append({"id": p["id"], "category": p["category"], "name": p["name"], "price": int(p["price"]), "art": p["art"], "available": bool(p.get("available", true))})
	return {"ok": true, "products": products}

func purchase(account_id: String, product_id: String) -> Dictionary:
	var profile := store.profile(account_id)
	if profile.is_empty():
		return {"ok": false, "error": "unknown_account"}
	var product := _product(product_id)
	if product.is_empty():
		return {"ok": false, "error": "unknown_product"}
	if not bool(product.get("available", true)):
		return {"ok": false, "error": "unavailable"}
	var price := int(product["price"])
	if int(profile["dp"]) < price:
		return {"ok": false, "error": "not_enough_dp", "balance": int(profile["dp"])}
	var collection := Collection.load_default(db, store.collection_path(account_id))
	var rolled := PackOpener.roll(product.get("contents", {}), pools, rng, collection.counts)
	if rolled.is_empty():
		# Every card this pack can give is already owned 3 times: nothing to sell, nothing is charged.
		return {"ok": false, "error": "set_complete", "balance": int(profile["dp"])}
	var cards := []
	for pull: Dictionary in rolled:
		var index := int(pull["index"])
		var rarity := str(pull["rarity"])
		cards.append({"index": index, "name": db.card_name(index), "new": collection.owned(index) == 0, "rarity": rarity, "rare": _rarity(rarity).get("reveal", "") == "gold"})
		collection.add(index)
	# Cards first, then DP: an interrupted save can only ever favour the player, never take DP for nothing.
	if collection.save(store.collection_path(account_id)) != OK:
		return {"ok": false, "error": "save_failed"}
	profile["dp"] = int(profile["dp"]) - price
	if store.save_profile(profile) != OK:
		return {"ok": false, "error": "save_failed"}
	store.append_purchase(account_id, {"time": int(Time.get_unix_time_from_system()), "product": product_id, "price": price, "cards": rolled.map(func(p): return [int(p["index"]), str(p["rarity"])]), "balance": int(profile["dp"])})
	return {"ok": true, "product_id": product_id, "cards": cards, "balance": int(profile["dp"])}

## What a product can contain, by rarity, with the chance per card — public information, like the card
## lists real games show. {"ok", "product_id", "name", "sections": [{"rarity", "label", "chance", "rare", "cards": [index...]}]}
## Sections are ordered rarest first.
func get_product_contents(product_id: String) -> Dictionary:
	var product := _product(product_id)
	if product.is_empty():
		return {"ok": false, "error": "unknown_product"}
	if not bool(product.get("available", true)):
		return {"ok": false, "error": "unavailable"}
	var sections := PackOpener.describe(product.get("contents", {}), pools)
	for section: Dictionary in sections:
		var info := _rarity(str(section["rarity"]))
		section["label"] = str(info.get("label", str(section["rarity"]).to_upper()))
		section["rare"] = info.get("reveal", "") == "gold"
		section["rank"] = int(info.get("rank", 0))
	sections.sort_custom(func(a, b): return int(a["rank"]) > int(b["rank"]))
	return {"ok": true, "product_id": product_id, "name": product["name"], "sections": sections}

func _rarity(rarity: String) -> Dictionary:
	return (catalog.get("rarities", {}) as Dictionary).get(rarity, {})

func _product(product_id: String) -> Dictionary:
	for p: Dictionary in catalog.get("products", []):
		if p["id"] == product_id:
			return p
	return {}

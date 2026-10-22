class_name RemoteShopBackend
extends ShopBackend
## The shop/account API over the network: every call is one "shop" request answered by the server's
## LocalShopBackend logic for the signed-in account. Same Dictionaries as LocalShopBackend, always awaited.
## The account id argument is ignored: the server always acts for the session's own account.

var client: OnlineClient
var db: CardDB

func _init(online_client: OnlineClient, card_db: CardDB) -> void:
	client = online_client
	db = card_db

func _call(method: String, args := {}) -> Dictionary:
	if client == null:
		return {"ok": false, "error": "not_connected"}
	return await client.request("shop", {"method": method, "args": args})

func get_profile(_account_id: String) -> Dictionary:
	return await _call("get_profile")

func get_catalog() -> Dictionary:
	return await _call("get_catalog")

func get_product_contents(product_id: String) -> Dictionary:
	var r: Dictionary = await _call("get_product_contents", {"product_id": product_id})
	if r.get("ok", false):
		for s in r.get("sections", []):
			s["cards"] = (s.get("cards", []) as Array).map(func(n): return Collection.index_of_number(db, int(n))).filter(func(i): return i > 0)
	return r

func purchase(_account_id: String, product_id: String) -> Dictionary:
	var r: Dictionary = await _call("purchase", {"product_id": product_id})
	if r.get("ok", false):
		for c in r.get("cards", []):
			c["index"] = Collection.index_of_number(db, int(c.get("number", 0)))
			c["name"] = db.card_name(int(c["index"])) if int(c["index"]) > 0 else ""
	return r

## {"ok", "collection": Collection} built from the server's card numbers.
func get_collection(_account_id := "") -> Dictionary:
	var r: Dictionary = await _call("get_collection")
	if r.get("ok", false):
		var c := Collection.new()
		c.db = db
		c.counts = Collection.counts_from_numbers(db, r.get("cards", {}))
		r["collection"] = c
	return r

## {"ok", "deck": Deck}
func get_deck(_account_id := "") -> Dictionary:
	var r: Dictionary = await _call("get_deck")
	if r.get("ok", false):
		r["deck"] = Deck.from_numbers(db, r.get("deck", {}))
	return r

func save_deck(_account_id: String, deck: Deck) -> Dictionary:
	return await _call("save_deck", {"deck": deck.to_numbers(db)})

func get_account_summary(_account_id := "") -> Dictionary:
	return await client.request("account_summary")

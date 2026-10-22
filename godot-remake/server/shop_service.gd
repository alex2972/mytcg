class_name ServerShop
extends RefCounted
## The "shop" request: catalog, pack contents, purchases, collection and deck for the session's account.
## The logic is LocalShopBackend's (the same code the offline game uses); this layer only binds it to the
## caller's account and converts cards to Konami numbers for the wire.

const METHODS := ["get_profile", "get_catalog", "get_product_contents", "purchase", "get_collection", "get_deck", "save_deck"]

var server: GameServer
var shop: LocalShopBackend
var db: CardDB

func _init(game_server: GameServer, backend: LocalShopBackend) -> void:
	server = game_server
	shop = backend
	db = backend.db
	server.register("shop", _on_shop, true)

func _number(index: int) -> int:
	return int(db.cards[index].get("number", 0)) if index > 0 and index < db.cards.size() else 0

func _on_shop(peer: int, args: Dictionary) -> Dictionary:
	var method = args.get("method", "")
	var a = args.get("args", {})
	if typeof(method) != TYPE_STRING or not METHODS.has(method) or typeof(a) != TYPE_DICTIONARY:
		server.strike(peer, "bad shop call")
		return Protocol.fail("invalid_args")
	var account := server.account_of(peer)
	if server.services.has("rooms") and method in ["purchase", "save_deck"] and server.services["rooms"].room_of(account) != null:
		# Nothing that changes cards or decks while that account is in a duel.
		return Protocol.fail("busy")
	match method:
		"get_profile":
			return shop.get_profile(account)
		"get_catalog":
			return shop.get_catalog()
		"get_product_contents":
			if typeof(a.get("product_id", "")) != TYPE_STRING:
				return Protocol.fail("invalid_args")
			var r := shop.get_product_contents(str(a["product_id"]))
			if r.get("ok", false):
				r = r.duplicate(true)
				for s in r["sections"]:
					s["cards"] = (s["cards"] as Array).map(func(i): return _number(int(i)))
			return r
		"purchase":
			if typeof(a.get("product_id", "")) != TYPE_STRING:
				return Protocol.fail("invalid_args")
			var r := shop.purchase(account, str(a["product_id"]))
			if r.get("ok", false):
				for c in r["cards"]:
					c["number"] = _number(int(c["index"]))
					c.erase("index")
				server.audit("purchase", {"account": account, "product": a["product_id"], "cards": r["cards"].map(func(c): return c["number"]), "balance": r["balance"]})
			return r
		"get_collection":
			var r := shop.get_collection(account)
			if not r.get("ok", false):
				return r
			return Protocol.ok({"cards": (r["collection"] as Collection).to_numbers()})
		"get_deck":
			var r := shop.get_deck(account)
			if not r.get("ok", false):
				return r
			return Protocol.ok({"deck": (r["deck"] as Deck).to_numbers(db)})
		"save_deck":
			var data = a.get("deck", {})
			if typeof(data) != TYPE_DICTIONARY:
				return Protocol.fail("invalid_args")
			for key in ["main", "extra", "side"]:
				var list = data.get(key, [])
				if typeof(list) != TYPE_ARRAY or (list as Array).size() > 80 or not (list as Array).all(func(x): return typeof(x) == TYPE_INT):
					return Protocol.fail("invalid_args")
			var deck := Deck.from_numbers(db, data)
			var count: int = (data.get("main", []) as Array).size() + (data.get("extra", []) as Array).size() + (data.get("side", []) as Array).size()
			if deck.main.size() + deck.extra.size() + deck.side.size() != count:
				return Protocol.fail("deck_invalid", {"reason": "Unknown card."})
			return shop.save_deck(account, deck)
	return Protocol.fail("invalid_args")

class_name ShopBackend
extends RefCounted
## The shop/account API the game client talks to. Today it is LocalShopBackend (same process,
## files under user://). Later an HTTP/WebSocket implementation with the same methods will call the
## authoritative server, so screens must:
##   * send only ids (account id, product id) — never prices, balances or card results;
##   * show only what the backend returns (balance, cards);
##   * `await` every call (a network call returns later; a local one returns at once).
## Every result is a Dictionary with "ok" (bool) and, when false, "error" (one of ERRORS).

const ERRORS := ["unknown_account", "unknown_product", "not_enough_dp", "unavailable", "save_failed", "set_complete"]

## {"ok", "account": {"id", "name", "dp"}}
func get_profile(_account_id: String) -> Dictionary:
	return {"ok": false, "error": "unavailable"}

## {"ok", "products": [{"id", "category", "name", "price", "art", "available"}]}. "available": false = shown, not sold yet. Card lists come from get_product_contents;
## the slot weights and the RNG never leave the server.
func get_catalog() -> Dictionary:
	return {"ok": false, "error": "unavailable"}

## {"ok", "product_id", "name", "sections": [{"rarity", "label", "chance", "rare", "cards": [index...]}]}
func get_product_contents(_product_id: String) -> Dictionary:
	return {"ok": false, "error": "unavailable"}

## {"ok", "product_id", "cards": [{"index", "name", "new", "rarity", "rare"}], "balance"}
func purchase(_account_id: String, _product_id: String) -> Dictionary:
	return {"ok": false, "error": "unavailable"}

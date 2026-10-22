class_name ServerServices
extends RefCounted
## Wires the server's services into a GameServer (each registers its request kinds).

static func install(server: GameServer) -> void:
	server.db = CardDB.load_default()
	var shop := LocalShopBackend.new(server.db, server.data_dir + "/accounts")
	server.services["shop_backend"] = shop
	server.services["auth"] = ServerAuth.new(server, shop.store, server.db)

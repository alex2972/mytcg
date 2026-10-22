class_name ServerAuth
extends RefCounted
## Accounts on the server: register / login / token login / logout, one live session per account.
## Passwords are optional for now (empty = none). Non-empty ones are stored as salted PBKDF2-HMAC-SHA256.
## Failed logins delay further attempts for that name (1, 2, 4 ... s, capped).

const NAME_MIN := 3
const NAME_MAX := 16
const PASSWORD_MAX := 64
const RESERVED := ["admin", "administrator", "system", "server", "moderator", "cpu", "bot", "konami", "root", "guest"]

var server: GameServer
var store: AccountStore
var db: CardDB
var tokens := {}             ## token -> {account, expires}
var account_peer := {}       ## account id -> peer id
var _fails := {}             ## lowercase name -> {count, until}
var _name_re := RegEx.new()

func _init(game_server: GameServer, account_store: AccountStore, card_db: CardDB) -> void:
	server = game_server
	store = account_store
	db = card_db
	_name_re.compile("^[A-Za-z0-9_ -]+$")
	server.register("register", _on_register, false)
	server.register("login", _on_login, false)
	server.register("login_token", _on_login_token, false)
	server.register("logout", _on_logout, true)
	server.register("account_summary", func(peer, _a): return Protocol.ok({"account": summary(server.account_of(peer))}), true)
	server.peer_left.connect(_on_peer_left)

func status() -> Dictionary:
	return {"accounts": store.accounts().size(), "online": account_peer.size()}

# --- validation ------------------------------------------------------------------------------

func name_problem(display_name) -> String:
	if typeof(display_name) != TYPE_STRING:
		return "bad_name"
	var n: String = display_name
	if n != n.strip_edges() or n.length() < NAME_MIN or n.length() > NAME_MAX or _name_re.search(n) == null or "  " in n:
		return "bad_name"
	if RESERVED.has(n.to_lower()):
		return "bad_name"
	return ""

static func password_problem(password) -> String:
	if typeof(password) != TYPE_STRING or (password as String).length() > PASSWORD_MAX:
		return "bad_password"
	return ""

# --- hashing ---------------------------------------------------------------------------------

static func pbkdf2(password: String, salt: PackedByteArray, iterations: int) -> PackedByteArray:
	var crypto := Crypto.new()
	var key := password.to_utf8_buffer()
	var block := salt.duplicate()
	block.append_array(PackedByteArray([0, 0, 0, 1]))
	var u := crypto.hmac_digest(HashingContext.HASH_SHA256, key, block)
	var t := u.duplicate()
	for i in range(1, iterations):
		u = crypto.hmac_digest(HashingContext.HASH_SHA256, key, u)
		for j in t.size():
			t[j] = t[j] ^ u[j]
	return t

func hash_password(password: String) -> Variant:
	if password == "":
		return null
	var salt := Crypto.new().generate_random_bytes(16)
	var iterations := int(server.config["pbkdf2_iterations"])
	return {"salt": salt.hex_encode(), "hash": pbkdf2(password, salt, iterations).hex_encode(), "iterations": iterations}

static func password_matches(stored, password: String) -> bool:
	if stored == null or not stored is Dictionary:
		return password == ""
	if password == "":
		return false
	var expected: PackedByteArray = str(stored.get("hash", "")).hex_decode()
	var got := pbkdf2(password, str(stored.get("salt", "")).hex_decode(), int(stored.get("iterations", 10000)))
	if expected.size() != got.size():
		return false
	var diff := 0
	for i in got.size():
		diff |= expected[i] ^ got[i]
	return diff == 0

# --- requests --------------------------------------------------------------------------------

func _on_register(peer: int, args: Dictionary) -> Dictionary:
	var display_name = args.get("name", "")
	var password = args.get("password", "")
	var why := name_problem(display_name)
	if why != "":
		return Protocol.fail(why)
	why = password_problem(password)
	if why != "":
		return Protocol.fail(why)
	if store.find_by_name(display_name) != "":
		return Protocol.fail("name_taken")
	var id := store.create_account(display_name, db)
	if id == "":
		return Protocol.fail("bad_name")
	var p := store.profile(id)
	p["pw"] = hash_password(password)
	p.merge(fresh_stats(), false)
	store.save_profile(p)
	server.audit("register", {"account": id, "peer": peer})
	server.log_line("INFO", "registered %s" % id)
	return _bind(peer, id)

func _on_login(peer: int, args: Dictionary) -> Dictionary:
	var display_name = args.get("name", "")
	var password = args.get("password", "")
	if typeof(display_name) != TYPE_STRING or (display_name as String).length() > 32 or password_problem(password) != "":
		return Protocol.fail("invalid_args")
	var key := (display_name as String).strip_edges().to_lower()
	var t := server.now()
	var f: Dictionary = _fails.get(key, {"count": 0, "until": 0.0})
	if t < float(f["until"]):
		return Protocol.fail("rate_limited", {"retry_after": float(f["until"]) - t})
	var id := store.find_by_name(display_name)
	var p := store.profile(id) if id != "" else {}
	if id == "" or not password_matches(p.get("pw", null), password):
		f["count"] = int(f["count"]) + 1
		f["until"] = t + minf(float(server.config["login_delay_cap"]), pow(2.0, float(f["count"]) - 1.0))
		_fails[key] = f
		server.audit("login_failed", {"name": key, "peer": peer})
		return Protocol.fail("bad_credentials")
	if p.get("banned", false):
		return Protocol.fail("bad_credentials")
	_fails.erase(key)
	return _bind(peer, id)

func _on_login_token(peer: int, args: Dictionary) -> Dictionary:
	var token = args.get("token", "")
	if typeof(token) != TYPE_STRING or not tokens.has(token):
		return Protocol.fail("bad_credentials")
	var entry: Dictionary = tokens[token]
	if server.now() > float(entry["expires"]):
		tokens.erase(token)
		return Protocol.fail("bad_credentials")
	tokens.erase(token)       # tokens are single use: a fresh one comes back
	return _bind(peer, str(entry["account"]))

func _on_logout(peer: int, _args: Dictionary) -> Dictionary:
	var id := server.account_of(peer)
	for tk in tokens.keys():
		if tokens[tk]["account"] == id:
			tokens.erase(tk)
	_unbind(peer)
	return Protocol.ok()

## Ties `peer` to account `id`; an older session of the same account is kicked.
func _bind(peer: int, id: String) -> Dictionary:
	var old := int(account_peer.get(id, 0))
	if old != 0 and old != peer:
		server.peers.get(old, {})["account"] = ""
		server.kick(old, "logged in elsewhere")
	if server.account_of(peer) != "" and server.account_of(peer) != id:
		_unbind(peer)
	server.peers[peer]["account"] = id
	account_peer[id] = peer
	var p := store.profile(id)
	p.merge(fresh_stats(), false)
	p["last_login"] = int(server.now())
	store.save_profile(p)
	var token := Crypto.new().generate_random_bytes(32).hex_encode()
	tokens[token] = {"account": id, "expires": server.now() + float(server.config["token_hours"]) * 3600.0}
	server.audit("login", {"account": id, "peer": peer})
	if server.services.has("rooms"):
		server.services["rooms"].on_account_online(id, peer)
	return Protocol.ok({"token": token, "account": summary(id)})

func _unbind(peer: int) -> void:
	var id := server.account_of(peer)
	if id != "" and int(account_peer.get(id, 0)) == peer:
		account_peer.erase(id)
	if server.peers.has(peer):
		server.peers[peer]["account"] = ""

func _on_peer_left(peer: int) -> void:
	var id := server.account_of(peer)
	if id != "" and int(account_peer.get(id, 0)) == peer:
		account_peer.erase(id)

func peer_of(id: String) -> int:
	return int(account_peer.get(id, 0))

func fresh_stats() -> Dictionary:
	var r := int(server.config["elo_start"])
	return {"rating": r, "best_rating": r, "wins": 0, "losses": 0, "draws": 0, "streak": 0, "ranked_games": 0, "banned": false}

## What a client may know about an account.
func summary(id: String) -> Dictionary:
	var p := store.profile(id)
	if p.is_empty():
		return {}
	return {"id": id, "name": p.get("name", ""), "dp": int(p.get("dp", 0)), "rating": int(p.get("rating", 1500)),
		"wins": int(p.get("wins", 0)), "losses": int(p.get("losses", 0)), "draws": int(p.get("draws", 0)),
		"streak": int(p.get("streak", 0)), "best_rating": int(p.get("best_rating", 1500)), "ranked_games": int(p.get("ranked_games", 0))}

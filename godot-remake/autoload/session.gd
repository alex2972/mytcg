extends Node
## The signed-in account and the backend the screens talk to (autoload "Session").
## Offline: local accounts in user://accounts, `backend` is a LocalShopBackend.
## Online: a server account, `backend` is a RemoteShopBackend talking to the server through `online`.
## Screens never touch AccountStore directly: they ask Session for the account and go through `backend`.

signal account_changed(account_id: String)
signal balance_changed(dp: int)
signal mode_changed(mode: String)

var db: CardDB
var backend: ShopBackend                ## what screens use (local or remote)
var local_backend: LocalShopBackend     ## the offline one (always available)
var mode := "offline"                   ## "offline" | "online"
var online: OnlineClient                ## created on first use
var online_account := {}                ## server summary of the signed-in online account
var online_cfg_path := "user://online.cfg"
var _ready_root := ""

## Loads (or creates) the account database. The first run turns the old single-player save into
## an account called "Player". Tests call `use_root` with a throwaway folder instead.
func ensure_ready(root := AccountStore.DEFAULT_ROOT) -> void:
	if _ready_root == root:
		return
	if db == null:
		db = CardDB.load_default()
	local_backend = LocalShopBackend.new(db, root)
	if local_backend.store.accounts().is_empty():
		local_backend.store.create_account("Player", db, root == AccountStore.DEFAULT_ROOT)
	if local_backend.store.active_id() == "":
		local_backend.store.set_active(local_backend.store.accounts()[0]["id"])
	_ready_root = root
	if mode == "offline":
		backend = local_backend
	account_changed.emit(account_id())

func use_root(root: String) -> void:
	ensure_ready(root)

func is_online() -> bool:
	return mode == "online"

func account_id() -> String:
	if is_online():
		return str(online_account.get("id", ""))
	ensure_ready_default()
	return local_backend.store.active_id()

func display_name() -> String:
	if is_online():
		return str(online_account.get("name", ""))
	for a in accounts():
		if a["id"] == account_id():
			return str(a["name"])
	return ""

## Local accounts (the offline account switcher).
func accounts() -> Array:
	ensure_ready_default()
	return local_backend.store.accounts()

func collection_path() -> String:
	return backend_store().collection_path(account_id())

func deck_path() -> String:
	return backend_store().deck_path(account_id())

func backend_store() -> AccountStore:
	ensure_ready_default()
	return local_backend.store

func switch_account(id: String) -> bool:
	ensure_ready_default()
	if not local_backend.store.set_active(id):
		return false
	account_changed.emit(id)
	return true

## Creates a local account and signs into it. Returns its id, or "" for an empty name.
func create_account(display_name: String) -> String:
	ensure_ready_default()
	var id := local_backend.store.create_account(display_name, db)
	if id != "":
		switch_account(id)
	return id

func ensure_ready_default() -> void:
	if _ready_root == "":
		ensure_ready()

# --- online ------------------------------------------------------------------------------------

func online_client() -> OnlineClient:
	if online == null:
		online = OnlineClient.new()
		online.name = "Online"
		add_child(online)
		online.disconnected.connect(_on_online_lost)
	return online

## Connects to `url` and logs in (or registers when `create`). Returns the server reply.
func go_online(url: String, display_name: String, password: String, create := false) -> Dictionary:
	ensure_ready_default()
	var c := online_client()
	if not c.is_online() or c.url != url or not c.hello_ok:
		var hello: Dictionary = await c.connect_and_hello(url)
		if not hello.get("ok", false):
			return hello
	var r: Dictionary = await c.request("register" if create else "login", {"name": display_name, "password": password})
	if r.get("ok", false):
		_enter_online(url, r)
	return r

## Logs back in with the saved token (after a restart or a reconnect).
func resume_online(url := "") -> Dictionary:
	ensure_ready_default()
	var cfg := _load_cfg()
	var token := str(cfg.get("token", ""))
	if url == "":
		url = str(cfg.get("url", ""))
	if token == "" or url == "":
		return Protocol.fail("bad_credentials")
	var c := online_client()
	if not c.is_online() or not c.hello_ok:
		var hello: Dictionary = await c.connect_and_hello(url)
		if not hello.get("ok", false):
			return hello
	var r: Dictionary = await c.request("login_token", {"token": token})
	if r.get("ok", false):
		_enter_online(url, r)
	else:
		_save_cfg({"url": url, "name": cfg.get("name", ""), "token": ""})
	return r

func logout() -> void:
	if online != null and online.is_online():
		await online.request("logout")
		online.close()
	_save_cfg({"url": _load_cfg().get("url", ""), "name": _load_cfg().get("name", ""), "token": ""})
	_leave_online()

## Refreshes the cached account summary (DP, rating...) from the server.
func refresh_online_account() -> void:
	if not is_online():
		return
	var r: Dictionary = await online.request("account_summary")
	if r.get("ok", false):
		online_account = r["account"]
		balance_changed.emit(int(online_account.get("dp", 0)))

func last_online_settings() -> Dictionary:
	return _load_cfg()

func _enter_online(url: String, reply: Dictionary) -> void:
	online_account = reply.get("account", {})
	mode = "online"
	backend = RemoteShopBackend.new(online, db)
	_save_cfg({"url": url, "name": online_account.get("name", ""), "token": reply.get("token", "")})
	mode_changed.emit(mode)
	account_changed.emit(account_id())

func _leave_online() -> void:
	mode = "offline"
	online_account = {}
	backend = local_backend
	mode_changed.emit(mode)
	account_changed.emit(account_id())

func _on_online_lost() -> void:
	# The connection dropped: keep the online identity so screens can try resume_online().
	pass

func _load_cfg() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(online_cfg_path) != OK:
		return {}
	return {"url": cfg.get_value("online", "url", ""), "name": cfg.get_value("online", "name", ""), "token": cfg.get_value("online", "token", "")}

func _save_cfg(values: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for k in values:
		cfg.set_value("online", k, values[k])
	cfg.save(online_cfg_path)

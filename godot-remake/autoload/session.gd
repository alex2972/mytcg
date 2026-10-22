extends Node
## The signed-in account and the backend the screens talk to (autoload "Session").
## Screens never touch AccountStore directly: they ask Session for the account id / file paths and
## send requests through `backend`, so the local backend can later be swapped for the online one.

signal account_changed(account_id: String)
signal balance_changed(dp: int)

var db: CardDB
var backend: LocalShopBackend
var _ready_root := ""

## Loads (or creates) the account database. The first run turns the old single-player save into
## an account called "Player". Tests call `use_root` with a throwaway folder instead.
func ensure_ready(root := AccountStore.DEFAULT_ROOT) -> void:
	if _ready_root == root:
		return
	if db == null:
		db = CardDB.load_default()
	backend = LocalShopBackend.new(db, root)
	if backend.store.accounts().is_empty():
		backend.store.create_account("Player", db, root == AccountStore.DEFAULT_ROOT)
	if backend.store.active_id() == "":
		backend.store.set_active(backend.store.accounts()[0]["id"])
	_ready_root = root
	account_changed.emit(account_id())

func use_root(root: String) -> void:
	ensure_ready(root)

func account_id() -> String:
	ensure_ready_default()
	return backend.store.active_id()

func accounts() -> Array:
	ensure_ready_default()
	return backend.store.accounts()

func collection_path() -> String:
	return backend_store().collection_path(account_id())

func deck_path() -> String:
	return backend_store().deck_path(account_id())

func backend_store() -> AccountStore:
	ensure_ready_default()
	return backend.store

func switch_account(id: String) -> bool:
	ensure_ready_default()
	if not backend.store.set_active(id):
		return false
	account_changed.emit(id)
	return true

## Creates an account and signs into it. Returns its id, or "" for an empty name.
func create_account(display_name: String) -> String:
	ensure_ready_default()
	var id := backend.store.create_account(display_name, db)
	if id != "":
		switch_account(id)
	return id

func ensure_ready_default() -> void:
	if _ready_root == "":
		ensure_ready()

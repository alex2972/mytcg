extends SceneTree
## The 40-card minimum is enforced when starting a duel, and a collection too small to build a deck gets the shop notice.
var fails := 0
const ROOT := "user://test_deck_minimum"

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

static func wipe(dir: String) -> void:
	var path := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		wipe(dir + "/" + sub)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)

func _initialize() -> void:
	call_deferred("run")

func count_dialogs(node: Node) -> int:
	var n := 0
	for c in node.get_children():
		if c is DuelDialog and not c.done:
			n += 1
	return n

func run() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
		await process_frame
	wipe(ROOT)
	var session := root.get_node("Session")
	session.use_root(ROOT)
	var db: CardDB = session.db
	# A new account: 6 cards in total.
	var cards := Collection.load_default(db)
	check(cards.max_deck_size() == 6 and not cards.can_build_deck(), "6 starter cards cannot build a 40-card deck")
	var setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	await process_frame
	check(count_dialogs(setup) == 1, "Duel screen shows the shop notice when the collection is too small")
	check(DuelDialog.SHOP_NOTICE.contains("shop") and DuelDialog.SHOP_NOTICE.contains("starter cards"), "the notice sends the player to the shop for starter cards")
	for d in setup.get_children():
		if d is DuelDialog: d.queue_free()
	await process_frame
	setup.start(7, "", "cpu_000", true)
	check(setup.board == null and setup.form.visible, "a 6-card deck cannot start a duel")
	check(setup.last_refusal == DuelDialog.SHOP_NOTICE, "the refusal for a too-small collection is the shop notice")
	setup.queue_free()
	await process_frame
	# Enough cards for a deck, but the saved deck is under 40.
	var big := Collection.load_default(db)
	for i in range(1, 60): big.counts[i] = 3
	big.save()
	check(big.can_build_deck(), "a big collection can build a deck")
	setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	await process_frame
	check(count_dialogs(setup) == 0, "no shop notice when the collection is big enough")
	setup.start(7, "", "cpu_000", true)
	check(setup.board == null and setup.last_refusal.contains("6 cards") and setup.last_refusal.contains("40"), "a 6-card saved deck is refused with its size: %s" % setup.last_refusal.replace("\n", " "))
	var deck := Deck.load_working(db)
	for i in range(1, 60):
		if deck.main.size() >= 39: break
		DeckRules.add(deck, db, i, "", 3)
	check(deck.main.size() == 39 and setup.deck_problem(deck) != "", "39 cards is still refused")
	DeckRules.add(deck, db, 70, "", 3)
	deck.save_working(db)
	check(deck.main.size() >= 40 and setup.deck_problem(deck) == "", "40 cards is accepted")
	setup.start(7, "", "cpu_000", true)
	check(setup.board != null, "a 40-card deck starts the duel")
	setup.queue_free()
	await process_frame
	# Deck editor: same notice for a small collection.
	big.counts = {}
	big.give_starter()
	big.save()
	var editor = load("res://ui/deck_editor.gd").new()
	editor.working_path = ROOT + "/editor_deck.ydc"
	root.add_child(editor)
	await process_frame
	check(count_dialogs(editor) == 1, "Deck Editor shows the shop notice when the collection is too small")
	editor.queue_free()
	await process_frame
	wipe(ROOT)
	print("deck minimum tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

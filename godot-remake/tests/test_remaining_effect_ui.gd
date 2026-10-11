extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)
func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name:
			return i
	return 0
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.side(0).hand.clear()
	d.side(1).hand.clear()
	var spell := d.debug_give(0, idx(db, "Prohibition"))
	b._card_action(spell)
	check(d.fx.pending.get("catalog", false) and b.decision_popup.visible, "Prohibition opens searchable name picker")
	var search: LineEdit
	var items: ItemList
	var declare: Button
	for child in b.decision_box.get_children():
		if child is LineEdit: search = child
		if child is ItemList: items = child
		if child is Button: declare = child
	check(search != null and items != null and declare != null, "catalogue has search, scroll list and confirmation")
	check(items.item_count == int(d.fx.pending["count"]), "empty search shows every card name")
	search.text = "Pot of Greed"
	search.text_changed.emit(search.text)
	check(items.item_count == 1 and items.get_item_text(0) == "Pot of Greed", "search filters names")
	items.select(0)
	items.item_selected.emit(0)
	declare.pressed.emit()
	check(d.fx.pending.is_empty() and d.prohibited(d.debug_give(0, idx(db, "Pot of Greed"))), "Declare forwards selected name to engine")
	var moth := d.debug_give(0, idx(db, "Perfectly Ultimate Great Moth"))
	var petit := d.debug_place(0, idx(db, "Petit Moth"), 0, true)
	var cocoon := d.debug_give(0, idx(db, "Cocoon of Evolution"))
	b._card_action(cocoon)
	check(cocoon.equipped_to == petit, "hand click uses Cocoon equip effect")
	cocoon.flags["cocoon_turns"] = 6
	check(b._hover_cursor(moth) == "act", "ready Moth shows Activate cursor")
	b._card_action(moth)
	check(d.fx.pending.get("type", "") == "choice" and b.decision_popup.visible, "Moth click opens summon position choice")
	b._answer(1)
	check(d.side(0).monsters.has(moth) and moth.face_up and moth.pos == "def", "position choice summons Moth in Defense")
	# Inspection's reveal is temporary and visible through a card-art preview.
	var inspection := d.debug_place_spell(0, idx(db, "Inspection"), 1, true)
	d.debug_give(1, idx(db, "Axe Raider"))
	d.phase = "standby"
	d.turn_player = 1
	d.fx.window("standby_phase", {"player": 1})
	d.respond({"uid": inspection.uid, "idx": 1})
	while d.fx.pending.get("type", "") == "chain": d.respond("pass")
	b.presented_decision = {}
	b._check_decision()
	var preview := false
	for child in b.decision_box.get_children():
		if child is TextureRect and child.texture != null: preview = true
	check(d.fx.pending.has("reveal") and preview, "Inspection shows card artwork with acknowledgement")
	b.queue_free()
	await process_frame
	print("remaining effect UI tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

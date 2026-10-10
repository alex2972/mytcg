extends SceneTree
## Regression checks for modal targeting and texture-preserving LP depletion.
var fails := 0
var board: DuelBoard

func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func idx(name: String) -> int:
	for i in range(1, board.db.cards.size()):
		if board.db.card_name(i) == name:
			return i
	return 0

func dialog() -> DuelDialog:
	for child in board.get_children():
		if child is DuelDialog and not child.done:
			return child
	return null

func click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

func click_dialog(button: String) -> void:
	var dlg := dialog()
	if dlg == null:
		check(false, "dialog exists for " + button)
		return
	var e := click()
	e.position = dlg.panel.position + dlg._buttons()[button] * DuelDialog.SCALE
	dlg._on_input(e)

func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	board = DuelBoard.new(db, deck, deck, 3)
	board.ai_delay = 0.0
	board.duel.no_first_turn_attack = false
	root.add_child(board)
	await process_frame
	var d := board.duel
	board.shown_lp[0] = 4000
	board._update_ui()
	var fill: Control = board.hud.get_node("LPFill0")
	check(fill.size.x == 75 and fill.clip_contents, "half LP clips to half width")
	check(fill.get_child(0).size.x == 150, "LP artwork stays at full width")
	board.shown_lp[0] = 0
	board._update_ui()
	check(not fill.visible, "zero LP leaves an empty meter")
	board.shown_lp[0] = 8000
	board._update_ui()

	# A tribute summon must wait for YES and then OK before any tribute can be picked.
	d.side(0).hand.clear()
	d.side(1).hand.clear()
	var tribute := d.debug_place(0, idx("Armored Starfish"), 0)
	var summoned := d.debug_give(0, idx("Summoned Skull"))
	board._sync(false)
	board.fx_enabled = true
	board._card_action(summoned)
	click_dialog("no")
	check(dialog() == null and board.modal_depth == 0 and d.side(0).hand.has(summoned), "NO cancels without summoning")
	board._card_action(summoned)
	check(dialog() != null and dialog().kind == "yesno", "tribute summon first asks YES / NO")
	check(not board._can_act(), "modal blocks underlying board actions")
	if dialog() != null:
		check(dialog().panel.size.x == 412 and dialog().panel.scale == Vector2.ONE, "dialog uses native width")
		check(dialog().panel.position.x == 318, "dialog is centered over the playing field")
		click_dialog("yes")
	check(dialog() != null and dialog().kind == "ok", "tribute instruction waits for OK")
	board._on_card_input(click(), board.views[tribute.uid])
	check(d.side(0).monsters.has(tribute) and board.mode == DuelBoard.Mode.IDLE, "clicks cannot select tributes through instruction")
	if dialog() != null:
		click_dialog("ok")
	check(board.mode == DuelBoard.Mode.TRIBUTE and board.modal_depth == 0, "OK starts tribute selection")
	board.fx_enabled = false
	board._on_card_input(click(), board.views[tribute.uid])
	check(d.side(0).grave.has(tribute) and d.side(0).monsters.has(summoned), "tribute click completes summon")

	# A target instruction must appear once, then stay dismissed across UI refreshes.
	d.debug_place(1, idx("Armored Starfish"), 0)
	d.debug_place(1, idx("Armored Starfish"), 1)
	var spell := d.debug_give(0, idx("Fissure"))
	check(d.activate_effect(0, spell, 0) == "", "targeting spell activates")
	d.drain_events()
	board._sync(false)
	board.fx_enabled = true
	board._check_decision()
	check(dialog() != null and dialog().kind == "ok", "target instruction waits for OK")
	check(not board._decision_select_active(), "targets disabled until OK")
	var target: DCard = d.card_by_uid(d.fx.pending["candidates"][0])
	board._decision_toggle(target)
	check(d.side(1).monsters.has(target), "target cannot resolve behind the modal")
	if dialog() != null:
		click_dialog("ok")
	check(board._decision_select_active(), "OK enables target picking")
	check(board._hover_cursor(target) == "act", "valid targets show the selection cursor")
	board._check_decision()
	check(dialog() == null, "refresh does not repeat acknowledged instruction")
	board.fx_enabled = false
	board._decision_toggle(target)
	check(d.side(1).grave.has(target) and d.fx.pending.is_empty(), "target click resolves the effect")
	print("duel presentation tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

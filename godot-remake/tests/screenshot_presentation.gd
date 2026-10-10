extends SceneTree
## Render deterministic board / dialog / LP comparison images at the native layout size.
var board: DuelBoard
var output: String

func idx(name: String) -> int:
	for i in range(1, board.db.cards.size()):
		if board.db.card_name(i) == name:
			return i
	return 0

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func _init() -> void:
	await process_frame
	output = OS.get_cmdline_user_args()[0]
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	board = DuelBoard.new(db, deck, deck, 3)
	board.ai_delay = 0.0
	board.duel.no_first_turn_attack = false
	root.add_child(board)
	await process_frame
	var d := board.duel
	d.side(0).hand.clear()
	for name in ["Giant Soldier of Stone", "Zombyra the Dark", "Morphing Jar #2", "Axe Raider", "Kagemusha of the Blue Flame", "Card of Safe Return"]:
		d.debug_give(0, idx(name))
	for p in 2:
		d.side(p).extra.append(d._new_card(idx("Flame Swordsman"), p))
	board._show_card_detail(d.side(0).hand.back())
	await create_timer(0.4).timeout
	board._sync(false)
	board._update_ui()
	await capture("board_full_lp")
	board.shown_lp[0] = 4000
	board.shown_lp[1] = 2000
	board._update_ui()
	await capture("board_partial_lp")
	var dlg := DuelDialog.new()
	dlg.setup("Your opponent has declared battle.\nActivate the effect of a card?", "yesno")
	board.add_child(dlg)
	await capture("dialog_yes_no")
	dlg.queue_free()
	await process_frame
	dlg = DuelDialog.new()
	dlg.setup("Please select a monster as Tribute.", "ok")
	board.add_child(dlg)
	await capture("dialog_tribute_ok")
	dlg.queue_free()
	await process_frame
	dlg = DuelDialog.new()
	dlg.setup("Summoning this monster requires 2 Tributes. Do you wish to Summon?", "yesno")
	board.add_child(dlg)
	await capture("dialog_long")
	quit()

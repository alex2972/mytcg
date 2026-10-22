extends SceneTree

var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func idx(db: CardDB, card_name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == card_name: return i
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
	d.fx.interactive_selections = true
	d.side(0).deck.clear()
	d.side(0).grave.clear()
	d.side(1).grave.clear()
	var src := d.debug_place(0, idx(db, "Sangan"), 0, true, "atk")
	var ctx := {"src": src, "controller": 0, "vars": {}, "event": {}}
	d.drain_events()
	# Exercise the actual shared search script (Sangan/Witch), including shuffle.
	d.fx.push_script([{"op": "search", "filter": {"type": "monster", "atk_max": 1500}}], ctx)
	d.fx.pump()
	check(d.fx.pending.is_empty(), "empty optional search never asks for a selection")
	var events := d.drain_events()
	check(events.size() == 2 and events[0].type == "empty_search" and events[1].type == "shuffle", "notice precedes required deck shuffle")
	check(events[0].message == "There are no monsters with ATK 1500 or lower in your Deck.", "search notice describes restrictions and location")
	# A mandatory graveyard choice aborts exactly as before, with a notice.
	var result = d.fx.ops.run({"op": "select", "as": "t", "from": ["self.grave", "opp.grave"], "filter": {"type": "monster"}}, ctx)
	check(result == "abort" and ctx.vars.t.is_empty(), "mandatory empty search retains failure semantics")
	var notice: Dictionary = d.drain_events()[0]
	check(notice.message.contains("your Graveyard or your opponent's Graveyard"), "both graveyards are identified")
	# Costs and random removals must not produce misleading search messages.
	d.fx.ops.run({"op": "select", "as": "cost", "from": "self.grave", "cost": true}, ctx)
	check(d.drain_events().is_empty(), "cost failure is not a search notice")
	d.fx.ops.run({"op": "select", "as": "named", "from": "self.deck", "filter": {"name_is": "Dark Magician"}, "min": 0}, ctx)
	check(d.drain_events()[0].message == 'There are no "Dark Magician" cards in your Deck.', "named-card search describes the missing card")
	d.fx.ops.run({"op": "custom", "fn": "imitation_summon"}, {"src": src, "controller": 0, "vars": {"level": 5}, "event": {}})
	var insect_events := d.drain_events()
	check(insect_events[0].type == "empty_search" and insect_events[0].message.contains("Insect monsters with LEVEL 5"), "Insect Imitation reports its empty custom search")
	var card := DCard.new(9000, idx(db, "Armored Starfish"), 0)
	d.side(0).deck.append(card)
	result = d.fx.ops.run({"op": "select", "as": "t", "from": "self.deck", "auto": false}, ctx)
	check(result is Dictionary and result.type == "select" and result.candidates == [card.uid], "one valid result still requires choosing it")
	check(d.drain_events().is_empty(), "successful search has no failure notice")
	# Real modal is an OK dialog and blocks presentation until acknowledged.
	b.fx_enabled = true
	b._play_events([notice])
	await process_frame
	var dialog: DuelDialog = null
	for child in b.get_children():
		if child is DuelDialog: dialog = child
	check(dialog != null and dialog.kind == "ok" and b.modal_depth == 1, "empty search opens a blocking OK prompt")
	if dialog != null:
		dialog.answered.emit(true)
		dialog.queue_free()
	await process_frame
	check(b.modal_depth == 0, "acknowledgement releases the prompt")
	b.queue_free()
	await process_frame
	print("Empty search: ", "OK" if fails == 0 else str(fails) + " FAILED")
	quit(0 if fails == 0 else 1)

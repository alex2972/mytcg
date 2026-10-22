extends SceneTree
## Hover frames, attack-target highlight and idle swords leaving with their monsters.
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
	var b := DuelBoard.new(db, deck, deck, 5)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.no_first_turn_attack = false
	var actor := d.debug_place(0, idx(db, "Summoned Skull"), 0)
	var spare := d.debug_place(0, idx(db, "Armored Starfish"), 2)
	var foe := d.debug_place(1, idx(db, "Axe Raider"), 0)
	actor.summon_turn = -1
	spare.summon_turn = -1
	d.phase = "battle"
	b.anim_busy = false
	b._sync(false)
	d.drain_events()
	# Attack target: pink corners, plain hand cursor, no "Attack!" bubble.
	b._take_sword(actor)
	b.mode = DuelBoard.Mode.ATTACK_TARGET
	check(b._hover_cursor(foe) == "on", "attack target shows the plain cursor, not the Attack! bubble")
	var frame := b._frame_for(foe)
	check(frame != null and frame.resource_path.ends_with("card_waku#s2.png"), "hovered attack target gets the pink corner frame")
	b._cancel_mode()
	# Own hand cards always get the blue frame, even when they cannot be played now (Battle Phase).
	var hand_card: DCard = d.side(0).hand[0]
	check(b._hover_cursor(hand_card) == "off", "hand card cannot be played in the Battle Phase")
	var hand_frame := b._frame_for(hand_card)
	check(hand_frame != null and hand_frame.resource_path.ends_with("card_waku#l.png"), "unplayable hand card still shows the blue hover frame")
	# A monster leaving the field takes its idle sword with it right away.
	b._refresh_swords()
	check(b.idle_swords.has(spare.uid), "attacker has an idle sword")
	b.fx_enabled = false
	await b._play_events([{"type": "to_deck", "uid": spare.uid, "player": 0}])
	check(not b.idle_swords.has(spare.uid), "monster shuffled into the Deck loses its sword immediately")
	b.queue_free()
	await process_frame
	print("battle hover tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

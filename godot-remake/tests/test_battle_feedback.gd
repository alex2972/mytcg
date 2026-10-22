extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ",message)
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc",db)
	var b := DuelBoard.new(db,deck,deck,3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var cursor := root.get_node("GameCursor")
	check(cursor._tex("over")==cursor._tex("off"),"unavailable-action cursor never renders red marker")
	for player in 2:
		var pile: DuelBoard.PileView = b.piles["p%d_grave"%player]
		for count in [0,1,2,12]:
			pile.count = count
			check(pile.shows_count()==(count>1),"Graveyard counts appear only above one card")
	b.duel.turn_player = 1
	b.phase_flipping = true
	b._on_turn_wipe(0.0)
	check(b.phase_icons[0].texture.region.position.y==4.0,"flip starts with outgoing blue panel")
	b._on_turn_wipe(0.175)
	check(absf(b.phase_icons[0].scale.x)<0.01 and b.phase_icons[1].scale.x>0.5,"panels turn edge-on with staggered starts")
	b._on_turn_wipe(0.3)
	check(b.phase_icons[0].texture.region.position.y==79.0,"panel switches to red on its reverse half")
	b._on_turn_wipe(1.0)
	for icon in b.phase_icons:
		check(is_equal_approx(icon.scale.x,1.0) and icon.texture.region.position.y==79.0,"all flips finish at full size in incoming color")
	b.phase_flipping = false
	var card := b.duel.debug_place(1,deck.main[0],0)
	b._sync(false)
	b.mode = DuelBoard.Mode.ATTACK_TARGET
	b.attack_hover = card
	b._process(0.016)
	check(not b.attack_ring.visible,"hovering attack target never shows yellow orb")
	var view: DuelBoard.CardView = b.views[card.uid]
	var origin := view.position
	var samples: Array = []
	var shake_state := {"done": false}
	b.fx.animation_stage.connect(func(kind,stage):
		if kind == "battle_destroy" and stage == "shake_complete": shake_state["done"] = true)
	b.fx.battle_shake(view, 0.5)
	var deadline := Time.get_ticks_msec()+2000
	while not shake_state["done"] and Time.get_ticks_msec()<deadline:
		await process_frame
		samples.append(view.position.x-origin.x)
	check(shake_state["done"],"shake reports completion")
	check(samples.any(func(x):return absf(x)>0.1),"attacked card visibly shakes")
	check(view.position.is_equal_approx(origin),"shake restores original position")
	b.queue_free()
	await process_frame
	print("battle feedback tests: ","OK" if fails==0 else "%d FAILED"%fails)
	quit(1 if fails else 0)

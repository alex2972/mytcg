extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ",message)
func _init() -> void:
	await process_frame
	var glyphs := DuelBoard.LifeNumber.new()
	glyphs.remaining = 500
	glyphs.entry_tick = 16.0
	check(glyphs.glyph_pose(3)["visible"] and not glyphs.glyph_pose(0)["visible"],"entry begins at rightmost digit")
	glyphs.entry_tick = 32.0
	check(is_equal_approx(glyphs.glyph_pose(3)["y"],-40.0),"first bounce reaches native glyph height")
	glyphs.entry_tick = 80.0
	check(is_equal_approx(glyphs.glyph_pose(3)["y"],-10.0),"second bounce reaches quarter height")
	glyphs.entry_tick = 128.0
	for i in 4: check(is_zero_approx(glyphs.glyph_pose(i)["y"]),"all digits settle before LP countdown")
	glyphs.heal = true
	check(glyphs.number_text()=="+500","healing has positive sign")
	check(DuelBoard.LifeNumber.remaining_steps(115)==[115,15,5,4,3,2,1,0],"native countdown uses 100, ten, then single points")
	glyphs.free()
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc",db)
	var b := DuelBoard.new(db,deck,deck,3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	b.fx_enabled = true
	var d := b.duel
	var original_rng := d.rng.state
	var samples: Array = []
	var completed_values: Array = []
	b.lp_number_stage.connect(func(player,stage,remaining):
		samples.append([player,stage,remaining])
		if stage == "complete": completed_values.append(b.shown_lp[player]))
	d.damage_player(1,115,"effect")
	b._after_action()
	await create_timer(0.15).timeout
	check(b.anim_busy and b.shown_lp[1]==8000 and d.side(1).lp==7885,"LP is unchanged visually during entry; engine result is already fixed")
	while b.anim_busy: await process_frame
	check(b.shown_lp[1]==7885 and b.pending_lp_visuals.is_empty(),"damage countdown reaches exact LP and cleans pending visuals")
	check(samples==[[1,"entry",115],[1,"settled",115],[1,"count",115],[1,"complete",0]],"damage entry, settle and count run in order")
	samples.clear()
	d.heal_player(1,115)
	b._after_action()
	while b.anim_busy: await process_frame
	check(b.shown_lp[1]==8000 and samples.size()==4,"blue healing uses same ordered presentation")
	# Two changes in one engine batch must not collapse into a single final delta.
	samples.clear()
	d.damage_player(0,105,"effect")
	d.heal_player(0,15)
	b._after_action()
	while b.anim_busy: await process_frame
	check(b.shown_lp[0]==7910 and samples.size()==8,"damage then healing retain two separate animations and exact final LP")
	check(completed_values==[7885,8000,7895,7910],"each event reaches its own intermediate LP before the following event")
	check(d.rng.state==original_rng,"visual entry/countdown consumes no duel randomness")
	var live_numbers := b.get_children().filter(func(child):return child is DuelBoard.LifeNumber)
	check(live_numbers.is_empty() and b.battle_numbers==0,"no number remains when input resumes")
	b.queue_free()
	await process_frame
	print("LP animation tests: ","OK" if fails==0 else "%d FAILED"%fails)
	quit(1 if fails else 0)

extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ",message)
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1,db.cards.size()):
		if db.card_name(i) == card_name: return i
	return 0
func wait_board(b: DuelBoard) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while b.anim_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not b.anim_busy,"battle presentation releases its input lock")
func click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc",db)
	var b := DuelBoard.new(db,deck,deck,3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.no_first_turn_attack = false
	var actor := d.debug_place(0,idx(db,"Summoned Skull"),0)
	var spare := d.debug_place(0,idx(db,"Armored Starfish"),2)
	var defender := d.debug_place(1,idx(db,"Axe Raider"),0,false,"def")
	actor.summon_turn = -1
	spare.summon_turn = -1
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	var stages: Array = []
	var reaction_times := {}
	var defender_position: Vector2 = b.views[defender.uid].position
	var phase_frames: Array = []
	b.fx.animation_stage.connect(func(kind,stage): stages.append([kind,stage]))
	b.fx.animation_stage.connect(func(kind,stage):
		if kind == "attack" and stage == "impact": reaction_times["impact"] = Time.get_ticks_msec()
		if kind == "attack" and stage == "calculation" and not d.is_on_field(defender) and int(b.battle_visual.get("target",-1)) == defender.uid: check(b.lingering_stats.has(defender.uid),"destroyed monster keeps its ATK/DEF line until its destruction animation")
		if kind == "battle_destroy" and stage == "spokes": check(not b.lingering_stats.has(defender.uid),"ATK/DEF line disappears when the destruction animation starts")
		if kind != "battle_destroy": return
		reaction_times[stage] = Time.get_ticks_msec()
		if stage == "spokes":
			check(int(reaction_times[stage])-int(reaction_times["impact"]) >= int((b.BATTLE_TIMING.IMPACT_DURATION + b.BATTLE_TIMING.DAMAGE_STEP_DELAY) * 1000) - 50,"destruction waits for the damage-step pause")
			check(b.views[defender.uid].shown_face_up,"attacked Set monster flips before its destruction")
			check(b.views[defender.uid].visible and b.views[defender.uid].position.is_equal_approx(defender_position),"card stays visible on the field under the growing star"))
	b.fx.phase_frame_shown.connect(func(phase,progress): phase_frames.append([phase,progress]))
	b._do(d.to_battle(0))
	check(b.idle_swords.has(actor.uid) and b.idle_swords.has(spare.uid),"eligible swords appear immediately on entering Battle Phase")
	check(b.anim_busy and not b._can_act(),"phase announcement blocks attacks until its fade finishes")
	await wait_board(b)
	check(stages.slice(0,4) == [["battle","intro"],["battle","title"],["battle","fade"],["battle","complete"]],"phase entry, title and fade play in order")
	check(phase_frames.size() > 30,"phase motion updates at render rate rather than the reference's 10fps")
	check(b.idle_swords.has(actor.uid) and b.idle_swords.has(spare.uid),"valid attackers appear after the phase banner")
	b._card_action(actor)
	var sword := b.active_sword
	var sword_origin: Vector2 = sword.position
	b._on_card_input(click(),b.views[defender.uid])
	check(stages.has(["attack","flight"]),"target click launches immediately without confirmation wait")
	await process_frame
	await process_frame
	check(is_instance_valid(sword) and not sword.position.is_equal_approx(sword_origin),"sword moves on first rendered frames")
	check(b.anim_busy and not actor.attacked,"flight and impact precede declaration")
	check(b.idle_swords.has(spare.uid) and not b.idle_swords.has(actor.uid),"other valid swords remain, selected sword is not duplicated")
	await wait_board(b)
	var order := [["attack","flight"],["attack","impact"],["attack","calculation"],["battle_destroy","spokes"],["battle_destroy","core"],["battle_destroy","puffs"],["battle_destroy","complete"]]
	var battle_stages: Array = stages.filter(func(item):return item[0] in ["attack","battle_destroy"])
	check(battle_stages == order,"confirmation, flight, impact, calculation and destruction stay sequential: %s"%str(battle_stages))
	check(b.idle_swords.has(spare.uid) and not b.idle_swords.has(actor.uid),"spent sword never respawns on its attacker")
	check(d.side(1).grave.has(defender) and b.fx.get_child_count() == 0,"destroyed target reaches Graveyard once; effects finish before input")
	check(not stages.has(["attack","survival_shine"]),"destroyed defender explodes without a survival shine")
	var same_def := d.debug_place(1,idx(db,"Axe Raider"),1,true,"def")
	same_def.def_bonus = d.atk_of(spare)-d.def_of(same_def)
	b._sync(false)
	stages.clear()
	b._do(d.attack(0,spare,same_def))
	await wait_board(b)
	check(stages.count(["attack","calculation"]) == 1 and d.is_on_field(spare) and d.is_on_field(same_def),"zero-damage battles still show calculation and complete")
	check(stages.count(["attack","survival_shine"]) == 1 and not stages.has(["battle_destroy","shake"]),"surviving Defense monster shines once without shaking")
	# Higher DEF survives too, even though the attacker takes battle damage.
	spare.attacked = false
	same_def.def_bonus += 100
	stages.clear()
	b._do(d.attack(0,spare,same_def))
	await wait_board(b)
	check(stages.count(["attack","survival_shine"]) == 1 and not stages.has(["battle_destroy","shake"]),"higher-Defense survivor shines without shaking when it inflicts damage")
	b._do(d.to_main2(0))
	await wait_board(b)
	check(b.idle_swords.is_empty() and b.fx.get_child_count() == 0,"Main Phase 2 follows the completed battle with no lingering swords/effects")
	b.queue_free()
	await process_frame
	# A damage-step booster must reveal its random result before calculation starts.
	b = DuelBoard.new(db,deck,deck,7)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	d = b.duel
	d.turn_player = 1
	d.phase = "battle"
	d.no_first_turn_attack = false
	actor = d.debug_place(1,idx(db,"Summoned Skull"),0)
	actor.summon_turn = -1
	defender = d.debug_place(0,idx(db,"Axe Raider"),0)
	var dice := d.debug_place_spell(0,idx(db,"Graceful Dice"),0,false)
	dice.summon_turn = -1
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	b.decision_busy = true # Drive responses directly; don't open mouse dialogs in headless tests.
	d.fx.presentation_enabled = true
	d.fx.interactive_selections = true
	stages = []
	b.fx.animation_stage.connect(func(kind,stage): stages.append([kind,stage]))
	b.fx.result_shown.connect(func(kind,_results):
		check(not stages.has(["attack","calculation"]),"damage waits for dice result")
		stages.append([kind,"result"]))
	b.lp_number_stage.connect(func(_player,stage,_remaining):
		if stage == "entry": check(not stages.has(["battle_destroy","spokes"]),"player damage counts down before the destroyed monster explodes, like the original"))
	d.attack(1,actor,defender)
	await b._after_action()
	var used := false
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 25:
		guard += 1
		var p: Dictionary = d.fx.pending
		if p["type"] == "chain" and p.get("event","") == "damage_step" and p["player"] == 0 and not used:
			used = true
			d.respond({"uid":dice.uid,"idx":0})
		else:
			d.respond("pass" if p["type"] == "chain" else true)
		await b._after_action()
	check(used and stages.find(["dice","result"]) < stages.find(["attack","calculation"]),"damage-step Dice activates and finishes before calculation")
	check(stages.count(["attack","impact"]) == 1 and stages.count(["attack","calculation"]) == 1,"response windows do not replay sword hit or calculation")
	check(not b.anim_busy and b.shown_lp[0] == d.side(0).lp and b.battle_numbers == 0,"LP counter and damage number finish before the next action")
	b.queue_free()
	await process_frame
	# The same summon duration has many fractional updates and soft transition endpoints.
	b = DuelBoard.new(db,deck,deck,11)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	d = b.duel
	d.phase = "battle"
	d.no_first_turn_attack = false
	actor = d.debug_place(0,idx(db,"Summoned Skull"),0)
	actor.summon_turn = -1
	d.side(1).lp = 100
	b.shown_lp[1] = 100
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	b.decision_busy = true
	stages = []
	b.fx.animation_stage.connect(func(kind,stage): stages.append([kind,stage]))
	b._do(d.attack(0,actor,null))
	await wait_board(b)
	check(d.winner == 0 and b.shown_lp[1] == 0 and b.battle_numbers == 0,"lethal direct attack settles enemy LP and damage number before victory")
	check(stages == [["attack","flight"],["attack","impact"],["attack","calculation"]],"direct attack has one flight, hit and calculation without a target frame")
	b.queue_free()
	await process_frame
	var fx := DuelFx.new()
	root.add_child(fx)
	var view := TextureRect.new()
	view.texture = load(db.art_path(idx(db,"Axe Raider")))
	view.size = Vector2(50,72)
	root.add_child(view)
	var ticks: Array = []
	var strengths: Array = []
	fx.summon_frame_shown.connect(func(tick):
		ticks.append(tick)
		var crop: TextureRect = fx.get_node("SummonRainbow/RainbowCrop")
		strengths.append((crop.material as ShaderMaterial).get_shader_parameter("strength")))
	await fx.summon_rainbow(view)
	check(ticks.size() > 30 and ticks.any(func(tick):return not is_equal_approx(tick,roundf(tick/8)*8)),"summon interpolates between native ticks at render rate")
	check(strengths.front() == 0.0 and absf(strengths.back()) < 0.001 and strengths.any(func(value):return value>0.74),"summon preserves peak while fading transitions smoothly")
	fx.queue_free()
	view.queue_free()
	await process_frame
	print("battle pacing/smoothness tests: ","OK" if fails == 0 else "%d FAILED"%fails)
	quit(1 if fails else 0)

extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ",message)
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1,db.cards.size()):
		if db.card_name(i)==card_name: return i
	return 0
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
	d.phase = "main1"
	var target := d.debug_place_spell(1,idx(db,"Call Of The Haunted"),0,true)
	var mst := d.debug_place_spell(0,idx(db,"Mystical Space Typhoon"),0,false)
	mst.summon_turn = -1
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	b.decision_busy = true # Drive the target directly once visuals are complete.
	d.fx.interactive_selections = true
	d.fx.presentation_enabled = true
	var stages: Array = []
	var times := {}
	b.fx.animation_stage.connect(func(kind,stage):
		stages.append([kind,stage])
		times[kind+":"+stage] = Time.get_ticks_msec()
		if kind == "activation" and stage == "flare":
			check(b.views[mst.uid].shown_face_up,"Set card finishes flip before activation flare"))
	var why := d.activate_effect(0,mst)
	check(why=="","MST can activate on field: "+why)
	b._after_action()
	await create_timer(0.25).timeout
	check(b.anim_busy and not b._decision_select_active(),"activation blocks targeting")
	var early := InputEventMouseButton.new()
	early.button_index = MOUSE_BUTTON_LEFT
	early.pressed = true
	b._on_card_input(early,b.views[target.uid])
	check(d.side(1).spells.has(target) and not stages.has(["selection","flash"]),"early target click cannot overlap activation")
	while b.anim_busy: await process_frame
	check(stages==[["activation","flare"],["activation","complete"]],"activation finishes before target selection")
	b.decision_busy = false
	b._decision_toggle(target)
	check(b.anim_busy and d.side(1).spells.has(target),"target remains on field until confirmation flash ends")
	await create_timer(0.2).timeout
	check(d.side(1).spells.has(target) and not stages.has(["effect_destroy","fragments"]),"destruction waits for selection")
	var deadline := Time.get_ticks_msec()+5000
	while b.anim_busy and Time.get_ticks_msec()<deadline: await process_frame
	var expected := [["activation","flare"],["activation","complete"],["selection","flash"],["selection","complete"],["effect_destroy","fragments"],["effect_destroy","complete"],["graveyard","flight"],["graveyard","complete"]]
	check(stages==expected,"activation, selection, destruction and resolved-card flight play once in order: %s"%str(stages))
	for pair in [["activation",550],["selection",350],["effect_destroy",700],["graveyard",350]]:
		var begin: String = "flare" if pair[0]=="activation" else ("flash" if pair[0]=="selection" else ("fragments" if pair[0]=="effect_destroy" else "flight"))
		if times.has(pair[0]+":"+begin) and times.has(pair[0]+":complete"):
			check(int(times[pair[0]+":complete"])-int(times[pair[0]+":"+begin])>=pair[1],"%s stage gets its full visible duration"%pair[0])
	check(d.side(1).grave.count(target)==1 and d.side(0).grave.count(mst)==1,"both cards reach Graveyard once")
	check(not b.anim_busy and b.fx.get_child_count()==0,"all effects finish before input resumes")
	b.queue_free()
	await process_frame
	# Opponent choices use the same visual barrier without changing AI decisions.
	b = DuelBoard.new(db,deck,deck,7)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	d = b.duel
	d.turn_player = 1
	d.phase = "main1"
	target = d.debug_place_spell(0,idx(db,"Call Of The Haunted"),0,true)
	var other := d.debug_place_spell(0,idx(db,"Trap Hole"),1,false)
	mst = d.debug_place_spell(1,idx(db,"Mystical Space Typhoon"),0,false)
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	b.decision_busy = true
	d.fx.interactive_selections = true
	stages = []
	b.fx.animation_stage.connect(func(kind,stage): stages.append([kind,stage]))
	check(d.activate_effect(1,mst)=="","opponent MST activates")
	await b._after_action()
	var pending: Dictionary = d.fx.pending
	check(pending.get("type","")=="select","opponent chooses between field targets")
	var choices: Array[int] = [target.uid,other.uid]
	JoeyAI.step(d,1)
	await b._present_ai_target_choice(pending,choices)
	await b._after_action()
	check(stages==expected,"opponent activation and choice get the same sequential stages")
	check(d.side(0).grave.size()==1 and d.side(1).grave.has(mst),"opponent effect resolves normally after presentation")
	b.queue_free()
	await process_frame
	print("activation pacing tests: ","OK" if fails==0 else "%d FAILED"%fails)
	quit(1 if fails else 0)

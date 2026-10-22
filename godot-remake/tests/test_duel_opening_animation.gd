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
	check(DuelBoard.HAND_CARD == Vector2(100,145),"player draw arrives at original half-size hand card")
	for first in 2:
		var source := SubViewport.new()
		source.size = Vector2i(800,600)
		source.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(source)
		var outgoing := ColorRect.new()
		outgoing.color = Color.DARK_RED
		outgoing.size = Vector2(800,600)
		source.add_child(outgoing)
		var b := DuelBoard.new(db,deck,deck,3,first)
		b.opening_source = source
		b.ai_delay = 0.01
		b.ai_running = true
		root.add_child(b)
		check(b.anim_busy and not b._can_act() and b.duel.side(0).hand.is_empty() and b.duel.side(1).hand.is_empty(),"transition starts locked with empty hands")
		check(b.piles["p0_deck"].count==deck.main.size() and b.piles["p1_deck"].count==deck.main.size(),"decks already visible during transition and title")
		var stages: Array = []
		var ticks: Array = []
		var wipes: Array = []
		var draws: Array = []
		var opponent_frames := {}
		var opponent_turns: Array = []
		var opponent_before := {}
		var current := {"uid":-1,"progress":1.0}
		var snapshot := b.duel.rng.state
		b.fx.animation_stage.connect(func(kind,stage): stages.append([kind,stage]))
		b.fx.opening_wipe.connect(func(progress): wipes.append(progress))
		b.fx.opening_frame_shown.connect(func(tick):
			ticks.append(tick)
			var title: TextureRect = b.fx.get_node("StartTitle")
			if tick == 0.0:
				check(title.scale == Vector2(1.5,1.5) and title.modulate.a == 0.0,"native title grows into view from 1.5 scale with no first-frame flash")
			if tick > 64.0 and tick < 256.0:
				check(title.scale == Vector2.ONE and title.modulate.a == 1.0,"title holds at native size before fading"))
		b.draw_frame_shown.connect(func(uid,progress):
			var v: DuelBoard.CardView = b.views[uid]
			if uid != current["uid"]:
				check(current["progress"] == 1.0,"previous draw finishes before another starts")
				check(stages.has(["start","complete"]),"no draw starts before start title finishes")
				current["uid"] = uid
				draws.append([v.card.owner,uid])
			current["progress"] = progress
			check(v.presenting and b.anim_busy,"event owns card and input lock for whole draw")
			if v.card.owner == 0:
				check(v.rotation == 0.0,"player draw remains upright")
			else:
				opponent_frames[uid] = int(opponent_frames.get(uid,0)) + 1
				if progress > 0.0 and progress < 1.0: opponent_turns.append(v.rotation)
				if progress == 0.0:
					check(is_equal_approx(v.rotation,PI),"opponent draw starts in its resting orientation")
					opponent_before.clear()
					for older in b.duel.side(1).hand:
						if older.uid != uid and b.views.has(older.uid) and b.views[older.uid].visible:
							opponent_before[older.uid] = b.views[older.uid].position.x
				if progress == 1.0:
					check(is_equal_approx(v.rotation,PI),"opponent arrives inverted without a layout snap")
					for older_uid in opponent_before:
						check(v.position.x < b.views[older_uid].position.x,"new opponent card enters to the left of every existing hand card")
						check(b.views[older_uid].position.x >= float(opponent_before[older_uid])-0.01,"existing opponent cards shift right to make room" )
			check(v.shown_face_up == (v.card.owner == 0 and progress >= 0.5),"only player's card turns face-up in second half")
			var target_size := b.HAND_CARD if v.card.owner == 0 else b.OPP_HAND_CARD
			check(v.size.is_equal_approx(b.CARD.lerp(target_size,progress)),"draw size grows linearly instead of sharing generic card flight")
			if v.card.owner == 0:
				check(is_equal_approx(v.scale.x,absf(cos(progress*PI))),"flip spans complete draw flight"))
		var deadline := Time.get_ticks_msec()+14000
		while b.anim_busy and Time.get_ticks_msec() < deadline: await process_frame
		check(not b.anim_busy,"opening finishes and releases input")
		check(draws.size() == 11,"ten opening cards followed by first turn draw")
		check(not opponent_turns.is_empty() and opponent_turns.all(func(angle):return is_equal_approx(angle,PI)),"opponent draw slides without any rotation in flight")
		check(opponent_frames.values().all(func(count):return count>10),"every opponent draw updates at rendering rate")
		for card in b.duel.side(1).hand:
			check(is_equal_approx((b.views[card.uid] as DuelBoard.CardView).rotation,PI),"all resting opponent hand cards stay upside down after sync")
		if draws.size() == 11:
			for i in 11:
				check(draws[i][0] == (1-first if i<5 else first),"second player draws first, then first player including turn draw")
		check(wipes.size()>20 and wipes.front()==0.0 and wipes.back()==1.0,"strip wipe runs continuously to completion")
		check(ticks.size()>30 and ticks.front()==0.0 and ticks.back()==320.0,"start title interpolates native ticks at rendering rate")
		check(stages.slice(0,4)==[["opening","wipe"],["opening","board"],["start","title"],["start","complete"]],"Janken reveal precedes title and deal")
		check(b.fx.get_child_count()==0 and not is_instance_valid(source) and b.opening_source==null,"opening overlay and outgoing scene cleaned up")
		check(b.duel.rng.state==snapshot,"opening presentation consumes no duel randomness")
		b.queue_free()
		await process_frame
	# Effect draws are batched in the engine, but the visible hand grows one card at a time.
	var b := DuelBoard.new(db,deck,deck,11)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	for card in b.duel.side(1).hand:
		b.views[card.uid].hide()
	b.duel.side(1).hand.clear()
	var old := b.duel.debug_give(1,deck.main[0])
	b._sync(false)
	b.duel.drain_events()
	b.fx_enabled = true
	var arrivals: Array = []
	b.draw_frame_shown.connect(func(uid,progress):
		if progress == 0.0:
			arrivals.append(uid)
			check(b._presented_hand(1).size() == arrivals.size()+1,"batched opponent draw grows visible hand by one per animation")
			for later in b.duel.side(1).hand:
				if later.uid != old.uid and not arrivals.has(later.uid):
					check(not b.views.has(later.uid) or not b.views[later.uid].visible,"later draws stay hidden until their turn")
		if progress == 1.0:
			for earlier in b._presented_hand(1):
				if earlier.uid != uid:
					check(b.views[uid].position.x < b.views[earlier.uid].position.x,"each batched opponent draw settles at the left edge"))
	b.duel.draw_cards(1,3)
	await b._after_action()
	check(arrivals.size()==3 and b.pending_draws.is_empty(),"all batched draws complete without leftover hidden cards")
	for card in b.duel.side(1).hand:
		check(b.views[card.uid].visible and not b.views[card.uid].shown_face_up,"opponent hand finishes with all backs visible")
	b.queue_free()
	await process_frame
	print("duel opening animation tests: ","OK" if fails==0 else "%d FAILED"%fails)
	quit(1 if fails else 0)

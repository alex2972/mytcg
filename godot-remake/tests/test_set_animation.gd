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
	for card_name in ["Mystical Space Typhoon", "Trap Hole", "Axe Raider"]:
		var b := DuelBoard.new(db, deck, deck, 3)
		b.ai_delay = 0.0
		b.ai_running = true
		root.add_child(b)
		await process_frame
		b.duel.side(0).hand.clear()
		var card := b.duel.debug_give(0, idx(db, card_name))
		b._sync(false)
		b.duel.drain_events()
		b.fx_enabled = true
		var yellow: bool = card_name == "Axe Raider"
		var frames: Array = []
		var observer := func(color_yellow: bool, tick: float):
			var layer: Control = b.fx.get_node("SetCircle")
			var ring: TextureRect = layer.get_child(0)
			var stars: Array = layer.get_children().slice(1)
			frames.append({"tick": tick, "scale": ring.scale.x, "alpha": ring.modulate.a, "rotation": ring.rotation,
				"count": stars.filter(func(star): return star.visible).size(), "rising_y": stars[0].position.y,
				"star_texture": stars[0].texture, "ring_texture": ring.texture})
			check(color_yellow == yellow, "Set monsters are yellow; Spells/Traps are blue")
			check(layer.get_child_count() == 9, "Set has one rune circle and eight stars, without a Tribute white disc")
		b.fx.set_frame_shown.connect(observer)
		var rng_state := b.duel.rng.state
		b.hand_set_pref = true
		b._card_action(card)
		await create_timer(0.4).timeout
		check(b.anim_busy, "game waits while Set effect is visible")
		await create_timer(0.85).timeout
		check(not b.anim_busy and b.fx.get_node_or_null("SetCircle") == null, "Set presentation completes and cleans up before input resumes")
		check(b.duel.rng.state == rng_state, "visual star radii do not consume duel RNG")
		check(not card.face_up and b.duel.side(0).spells.has(card) == not yellow, "card remains Set in its correct zone")
		check(not frames.is_empty(), "board plays the Set renderer")
		if not frames.is_empty():
			var first: Dictionary = frames.front()
			var last: Dictionary = frames.back()
			check(first["scale"] == 1.0 and is_zero_approx(first["alpha"]) and first["count"] == 1, "circle fades into native size; stars enter successively")
			check(first["ring_texture"] == b.fx.tex("effect/eff_set_y" if yellow else "effect/eff_set_b"), "correct native ring artwork")
			check(last["scale"] == 2.0 and absf(last["alpha"]) < 0.001 and last["count"] == 8, "circle ends at twice native size and fully faded")
			check(last["rising_y"] < first["rising_y"] - 60.0 and last["rotation"] > first["rotation"], "stars rise while the ring rotates")
			check(frames.any(func(frame): return frame["alpha"] > 0.65), "native opacity peaks near 176/255")
			check(frames.all(func(frame): return frame["tick"] >= 128 or frame["scale"] == 1.0), "expansion begins in the second half")
			check(frames.any(func(frame): return frame["star_texture"] == b.fx.tex("effect/eff_star1_y" if yellow else "effect/eff_star1_b")), "rising stars alternate original texture frames")
		b.queue_free()
		await process_frame
	print("Set animation tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

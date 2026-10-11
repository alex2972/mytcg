extends SceneTree
var db: CardDB
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
func idx(name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name:
			return i
	return 0
func setup(material_player := 0) -> Duel:
	var deck := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	var d := Duel.create(db, deck, deck, 1, 0)
	d.side(0).hand.clear()
	d.side(1).hand.clear()
	for name in ["Flame Manipulator", "Masaki the Legendary Swordsman"]:
		var card := d.debug_give(material_player, idx(name))
		d.send_to_grave(card, "effect")
	var fusion := d.debug_place(1, idx("Flame Swordsman"), 0, true, "atk")
	var source := d.debug_give(0, idx("De-Fusion"))
	d.fx.push_script([{"op": "custom", "fn": "de_fusion"}], {"src": source, "controller": 0, "vars": {"t": [fusion]}, "event": {}})
	d.fx.pump()
	return d
func _init() -> void:
	db = CardDB.load_default()
	var d := setup()
	check(d.side(1).extra.size() > 0 and d.side(1).monsters[0] == null, "opponent Fusion returns to owner's Extra Deck before revival prompt")
	check(d.fx.pending.get("type", "") == "yesno", "material revival is optional")
	d.respond(false)
	check(d.side(0).grave.size() == 2 and d.monsters_of(0).is_empty(), "declining keeps all materials in Graveyard")
	d = setup()
	d.respond(true)
	check(d.fx.pending.get("type", "") == "choice", "first material receives position choice")
	d.respond(1)
	check(d.fx.pending.get("type", "") == "choice", "second material receives separate position choice")
	d.respond(0)
	check(d.monsters_of(0).size() == 2, "all materials revived")
	check(d.side(0).monsters[0].face_up and d.side(0).monsters[0].pos == "def", "first material face-up Defense")
	check(d.side(0).monsters[1].face_up and d.side(0).monsters[1].pos == "atk", "second material face-up Attack")
	d = setup(1)
	check(d.fx.pending.is_empty() and d.monsters_of(0).is_empty(), "opponent Graveyard does not supply activator's materials")
	d = setup(1)
	# Leave the prior De-Fusion scenario idle, then exercise the native Riot clamp.
	for i in 3:
		d.debug_place(0, idx("Axe Raider" if i == 0 else "Blue-Eyes White Dragon"), i, true, "atk")
	var riot := d.debug_give(0, idx("Major Riot"))
	d.fx.push_script([{"op": "custom", "fn": "major_riot"}], {"src": riot, "controller": 0, "vars": {}, "event": {}})
	d.fx.pump()
	check(d.fx.pending.get("type", "") == "choice" and d.fx.pending.has("reveal_cards"), "Riot reveals opponent hand")
	d.respond(0)
	d.respond(0)
	check(d.fx.pending.get("type", "") == "yesno" and d.fx.pending.get("show_hands", false), "Riot offers available lower-level monster despite returning three")
	d.respond(true)
	check(d.fx.pending.get("max", 0) == 1, "Riot clamps summon count to eligible hand monsters")
	d.respond(d.fx.pending.get("candidates", []).slice(0, 1))
	check(d.monsters_of(0).size() == 1 and not d.monsters_of(0)[0].face_up and d.monsters_of(0)[0].pos == "def", "Riot summons clamped count face-down Defense")
	test_chosen_one()
	test_tailor()
	print("native targeting tests: ", "OK" if failures == 0 else "%d FAILED" % failures)
	quit(1 if failures else 0)


func test_chosen_one() -> void:
	var d := setup(1)
	var monster := d.debug_give(0, idx("Axe Raider"))
	var first := d.debug_give(0, idx("Pot of Greed"))
	var second := d.debug_give(0, idx("Waboku"))
	var source := d.debug_give(0, idx("Chosen One"))
	var ctx := {"src": source, "controller": 0, "vars": {"m": [monster], "o": [first, second]}, "event": {}}
	d.fx.push_script([{"op": "custom", "fn": "chosen_one"}], ctx)
	d.fx.pump()
	check(d.fx.pending.get("player", -1) == 1 and d.fx.pending.get("count", 0) == 3, "Chosen One opponent chooses hidden card before position")
	d.respond(ctx["vars"]["_chosen_trio"].find(monster))
	check(d.fx.pending.get("reveal_cards", []) == [monster.uid] and d.side(0).hand.has(monster), "Chosen One reveals selected card before summoning")
	d.respond(0)
	check(d.side(0).grave.has(first) and d.side(0).grave.has(second), "Chosen One disposes other cards before position choice")
	check(d.fx.pending.get("count", 0) == 2, "Chosen One position offered only after successful reveal")
	d.respond(1)
	check(d.monsters_of(0).has(monster) and monster.pos == "def" and monster.face_up, "Chosen One chosen Defense position used")

func test_tailor() -> void:
	var d := setup(1)
	var original := d.debug_place(0, idx("Axe Raider"), 0, true, "atk")
	var wrong := d.debug_place(0, idx("Armored Starfish"), 1, true, "atk")
	var warrior := d.debug_place(1, idx("Masaki the Legendary Swordsman"), 0, true, "atk")
	var equip := d.debug_place_spell(0, idx("Lightning Blade"), 0, true)
	d.equip_card(equip, original, {"atk": 800})
	check(not FxCustom.tailor_host_valid(equip, original, d.fx), "Tailor excludes original host")
	check(not FxCustom.tailor_host_valid(equip, wrong, d.fx), "Tailor rejects non-Warrior for Lightning Blade")
	check(FxCustom.tailor_host_valid(equip, warrior, d.fx), "Tailor accepts correct opponent Warrior")
	var source := d.debug_give(0, idx("Tailor of the Fickle"))
	d.fx.push_script([{"op": "custom", "fn": "tailor_select"}, {"op": "custom", "fn": "tailor_finish"}], {"src": source, "controller": 0, "vars": {"e": [equip]}, "event": {}})
	d.fx.pump()
	check(d.fx.pending.get("candidates", []) == [warrior.uid], "Tailor presents only legal alternative host")
	d.respond([warrior.uid])
	check(equip.equipped_to == warrior and not original.equips.has(equip), "Tailor transfers to valid host")

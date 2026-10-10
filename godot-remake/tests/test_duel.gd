extends SceneTree
## Duel core scenarios. The battle examples come straight from the original game's tutorial text
## (dialog strings 4235-4238): 1550 ATK vs 1200 ATK / 1500 DEF / 2000 DEF / 1600 ATK.

var db: CardDB
var fails := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func new_duel(seed_value := 1) -> Duel:
	var d := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	return Duel.create(db, d, d, seed_value, 0)

## A monster card (any) tuned to exact ATK/DEF through the effect-bonus fields.
func place(d: Duel, p: int, zone: int, atk: int, def: int, face_up := true, pos := "atk") -> DCard:
	var base: int = db.search("armored starfish")[0]
	var c := d.debug_place(p, base, zone, face_up, pos)
	c.atk_bonus = atk - d.atk_of(c)
	c.def_bonus = def - d.def_of(c)
	return c

func to_battle(d: Duel) -> void:
	check(d.to_battle(0) == "", "enter battle phase")

func first_with_level(lv: int) -> int:
	for i in range(1, db.cards.size()):
		var c: Dictionary = db.cards[i]
		if c.get("type", "") == "monster" and int(c.get("level", 0)) == lv and int(c.get("kind", 0)) != 24 and int(c.get("category", 0)) != 2:
			return i
	return 0

func _init() -> void:
	db = CardDB.load_default()
	test_turn_start()
	test_tutorial_battles()
	test_other_battle()
	test_summon_rules()
	test_end_turn()
	test_win_conditions()
	print("duel tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_turn_start() -> void:
	var d := new_duel()
	check(d.phase == "main1" and d.turn == 1 and d.turn_player == 0, "starts in main phase 1, turn 1")
	check(d.side(0).hand.size() == 6 and d.side(1).hand.size() == 5, "first player draws on turn 1 (tutorial: 'You're going first!' then Draw Phase)")
	check(d.side(0).lp == 8000 and d.side(1).lp == 8000, "8000 LP")
	check(d.side(0).deck.size() == 34, "40 - 5 - 1 draw")

func test_tutorial_battles() -> void:
	# 4235: 1550 vs ATK 1200 -> target destroyed, 350 damage
	var d := new_duel()
	var a := place(d, 0, 0, 1550, 1000)
	var t := place(d, 1, 0, 1200, 800)
	to_battle(d)
	check(d.attack(0, a, t) == "", "attack ok")
	check(d.side(1).lp == 8000 - 350 and d.side(1).grave.has(t) and not d.side(0).grave.has(a), "ATK win: 350 damage, target destroyed")
	# 4236: vs DEF 1500 -> destroyed, no damage
	d = new_duel()
	a = place(d, 0, 0, 1550, 1000)
	t = place(d, 1, 0, 100, 1500, true, "def")
	to_battle(d)
	d.attack(0, a, t)
	check(d.side(1).lp == 8000 and d.side(1).grave.has(t), "DEF break: destroyed, NO damage")
	# 4237: vs DEF 2000 -> attacker takes 450, nobody destroyed
	d = new_duel()
	a = place(d, 0, 0, 1550, 1000)
	t = place(d, 1, 0, 100, 2000, true, "def")
	to_battle(d)
	d.attack(0, a, t)
	check(d.side(0).lp == 8000 - 450 and d.side(0).grave.is_empty() and d.side(1).grave.is_empty(), "DEF wall: attacker takes 450, nothing destroyed")
	# 4238: vs ATK 1600 -> attacker destroyed, takes 50
	d = new_duel()
	a = place(d, 0, 0, 1550, 1000)
	t = place(d, 1, 0, 1600, 800)
	to_battle(d)
	d.attack(0, a, t)
	check(d.side(0).lp == 8000 - 50 and d.side(0).grave.has(a) and not d.side(1).grave.has(t), "ATK loss: attacker destroyed, takes 50")

func test_other_battle() -> void:
	var d := new_duel()
	var a := place(d, 0, 0, 1500, 1000)
	var t := place(d, 1, 0, 1500, 1000)
	to_battle(d)
	d.attack(0, a, t)
	check(d.side(0).grave.has(a) and d.side(1).grave.has(t) and d.side(0).lp == 8000 and d.side(1).lp == 8000, "equal ATK: both destroyed, no damage")
	# direct attack rules
	d = new_duel()
	a = place(d, 0, 0, 1800, 1000)
	var b := place(d, 1, 0, 500, 500)
	to_battle(d)
	check(d.attack(0, a, null) != "", "no direct attack while the opponent has monsters")
	d.attack(0, a, b)
	d = new_duel()
	a = place(d, 0, 0, 1800, 1000)
	to_battle(d)
	check(d.attack(0, a, null) == "" and d.side(1).lp == 6200, "direct attack deals full ATK")
	check(d.attack(0, a, null) != "", "a monster attacks only once per turn")
	# face-down defender is flipped by the attack
	d = new_duel()
	a = place(d, 0, 0, 1000, 1000)
	t = place(d, 1, 0, 100, 500, false, "def")
	to_battle(d)
	d.attack(0, a, t)
	check(d.side(1).grave.has(t), "face-down defender flipped then destroyed")
	# defense-position monsters cannot attack
	d = new_duel()
	var s := place(d, 0, 0, 1000, 1000, true, "def")
	to_battle(d)
	check(d.attack(0, s, null) != "", "defense position monsters cannot attack")
	# cannot attack outside battle phase
	d = new_duel()
	a = place(d, 0, 0, 1000, 1000)
	check(d.attack(0, a, null) != "", "cannot attack in the main phase")

func test_summon_rules() -> void:
	var d := new_duel()
	var low := first_with_level(4)
	var c1 := DCard.new(900, low, 0)
	var c2 := DCard.new(901, low, 0)
	d.side(0).hand = [c1, c2]
	check(d.summon(0, c1) == "" and d.side(0).monsters[0] == c1 and c1.face_up and c1.pos == "atk", "normal summon")
	check(d.summon(0, c2) != "", "only one Normal Summon / Set per turn")
	# tributes
	d = new_duel()
	var lv5 := DCard.new(902, first_with_level(5), 0)
	var lv7 := DCard.new(903, first_with_level(7), 0)
	d.side(0).hand = [lv5, lv7]
	check(d.tributes_required(lv5) == 1 and d.tributes_required(lv7) == 2, "level 5-6 need 1 tribute, 7+ need 2")
	check(d.summon(0, lv5) != "", "tribute summon without tributes refused")
	var f1 := place(d, 0, 0, 1000, 1000)
	var f2 := place(d, 0, 1, 1000, 1000)
	check(d.summon(0, lv5, [f1]) == "" and (d.side(0).monsters as Array).has(lv5) and d.side(0).grave.has(f1) and not (d.side(0).monsters as Array).has(f1), "tribute summon sends the tribute to the graveyard")
	# full zone
	d = new_duel()
	var low2 := DCard.new(904, low, 0)
	d.side(0).hand = [low2]
	for z in 5:
		place(d, 0, z, 1000, 1000)
	check(d.summon(0, low2) != "", "max 5 monsters")
	# set + position change
	d = new_duel()
	var s := DCard.new(905, low, 0)
	d.side(0).hand = [s]
	check(d.summon(0, s, [], -1, true) == "" and not s.face_up and s.pos == "def", "Set = face-down defense")
	check(d.change_position(0, s) != "", "cannot change position the turn it was Set")
	# next own turn
	var empty := Deck.new()
	d.end_turn(0)
	d.end_turn(1)
	check(d.turn_player == 0 and d.turn == 3, "turns alternate")
	check(d.change_position(0, s) == "" and s.face_up and s.pos == "atk", "flip summon on a later turn")
	check(d.change_position(0, s) != "", "only one position change per turn")
	# spell/trap set
	d = new_duel()
	var sp := DCard.new(906, db.search("pot of greed")[0] if db.search("pot of greed").size() > 0 else db.search("monster reborn")[0], 0)
	d.side(0).hand = [sp]
	check(d.set_spell_trap(0, sp) == "" and d.side(0).spells[0] == sp and not sp.face_up, "set spell/trap")
	# wrong player / phase
	d = new_duel()
	check(d.summon(1, DCard.new(907, low, 1)) != "", "not your turn")

func test_end_turn() -> void:
	var d := new_duel()
	check(d.hand_excess(0) == 0, "6 cards in hand is within the limit")
	var extra := DCard.new(950, first_with_level(4), 0)
	d.side(0).hand.append(extra)
	check(d.end_turn(0) != "" and d.turn_player == 0, "over the hand limit: must discard")
	check(d.end_turn(0, [extra.uid]) == "" and d.turn_player == 1 and d.side(0).grave.has(extra), "discard to the limit then pass the turn")
	check(d.phase == "main1" and d.side(1).hand.size() == 6, "opponent drew for the new turn")

func test_win_conditions() -> void:
	var d := new_duel()
	var a := place(d, 0, 0, 9000, 0)
	to_battle(d)
	d.attack(0, a, null)
	check(d.winner == 0 and d.win_reason == "life_points" and d.side(1).lp == 0, "LP 0 loses")
	check(d.attack(0, a, null) != "", "no actions after the duel ends")
	d = new_duel()
	d.side(1).deck.clear()
	d.end_turn(0)
	check(d.winner == 0 and d.win_reason == "deck_out", "cannot draw -> you lose (tutorial 4213)")
	d = new_duel()
	d.surrender(0)
	check(d.winner == 1, "surrender")

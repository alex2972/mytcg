extends SceneTree

func _init() -> void:
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var d := Duel.create(db, deck, deck, 3, 0)
	d.no_first_turn_attack = true
	var r := d.to_battle(0)
	print("FAIL: battle allowed on turn 1" if r == "" else "first turn ok: " + r)
	quit()

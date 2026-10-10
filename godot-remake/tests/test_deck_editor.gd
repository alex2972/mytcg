extends SceneTree
## Deck Construction screen: loads the default deck, add / remove / sort / counters.

var fails := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func _init() -> void:
	var ed := Control.new()
	ed.set_script(load("res://ui/deck_editor.gd"))
	root.add_child(ed)
	await process_frame
	await process_frame
	check(ed.deck.main.size() == 40, "default deck loaded (40 cards)")
	check(ed.counters["total"].text == "40", "total counter shows 40")
	var sum := 0
	for k in ["normal", "effect", "spell", "trap", "ritual"]:
		sum += int(ed.counters[k].text)
	check(sum == 40, "category counters add up to the total (%d)" % sum)
	check(ed.grids["main"].get_child_count() == 40, "40 thumbnails drawn")
	# sorted: all monsters before all spells before all traps
	var order: Array = ed.deck.main.map(func(i): return ed.GROUP_ORDER.find(ed._group(i)))
	var sorted: Array = order.duplicate()
	sorted.sort()
	check(order == sorted, "deck is grouped normal > effect > spell > trap")
	ed.collection.unlock_all()
	# add / remove
	var starfish: int = ed.db.search("armored starfish")[0]
	ed._add_card(starfish)
	check(ed.deck.main.size() == 41 and ed.deck.copies(starfish) == 1, "adding a card")
	ed._on_thumb_input(_click(), "main", ed.deck.main.find(starfish))
	check(ed.deck.main.size() == 40, "clicking a deck card removes it")
	# fusion goes to the fusion deck
	var fusion: int = ed.db.search("aqua dragon")[0]
	ed._add_card(fusion)
	check(ed.deck.extra.has(fusion), "fusion monsters go to the Fusion Deck")
	# collection strip
	check(ed.pool.rows.size() > 0, "collection lists the cards you own")
	print("deck editor tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

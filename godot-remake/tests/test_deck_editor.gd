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
	ed.working_path = "res://tests/deck_editor_working.ydc"
	if FileAccess.file_exists(ed.working_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(ed.working_path))
	root.add_child(ed)
	await process_frame
	await process_frame
	# Deck atlases carry a green colour key in interior pixels, not just corners.
	for asset in ["kabegami/kaban", "icon/icon_syuzoku", "icon/icon_star"]:
		var source := (load("res://assets/j/deck_c/" + asset + ".png") as Texture2D).get_image()
		var cleaned: Image = ed._img(asset).get_image()
		var keyed := 0
		for y in source.get_height():
			for x in source.get_width():
				var pixel := source.get_pixel(x, y)
				if pixel.r8 == 85 and pixel.g8 == 255 and pixel.b8 == 0:
					keyed += 1
					check(cleaned.get_pixel(x, y).a == 0, asset + " colour key is transparent")
				elif pixel.a > 0:
					check(cleaned.get_pixel(x, y) == pixel, asset + " preserves artwork colours")
		check(keyed > 0, asset + " fixture contains keyed pixels")
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
	var banned_card: int = ed.db.search("Change of Heart")[0]
	var allowed_card: int = ed.db.search("Card Destruction")[0]
	check(ed.pool._name_color(banned_card) == Color.RED, "forbidden card names are red")
	check(ed.pool._name_color(allowed_card) == PoolList.NAME_GOLD, "limited card names stay gold")
	var axe: int = ed.db.search("Axe Raider")[0]
	ed._show_detail(axe)
	check(ed.detail_index == axe and ed.d_stats.text == "ATK/1700  DEF/1150", "preview shows selected monster stats")
	check(ed.d_text_box.get_rect().end.y < ed.d_icons.position.y - 6, "description is clipped above stat divider")
	ed._show_detail(ed.db.search("Mystical Space Typhoon")[0])
	check(ed.d_stats.text == "", "spell preview clears monster stats")
	await process_frame
	var hover_card: TextureRect = ed.grids["main"].get_child(0)
	var hover_position := hover_card.position
	var hover_z := hover_card.z_index
	hover_card.mouse_entered.emit()
	check(hover_card.modulate.r > 1.0, "deck hover brightens artwork")
	check(hover_card.position == hover_position and hover_card.z_index == hover_z and hover_card.get_child_count() == 0, "deck hover adds no border, movement or raised overlap")
	hover_card.mouse_exited.emit()
	check(hover_card.modulate == Color.WHITE, "hover exit restores normal brightness")
	check(ed.back_button.texture_hover != ed.back_button.texture_normal, "Back has original yellow hover texture")
	# Text handle follows overflow and scroll position, and disappears for short text.
	ed.d_text.text = "Long description line\n".repeat(30)
	ed._scroll_text(0)
	check(ed.text_scroll_handle.visible, "long description shows native red double arrow")
	var handle_top: float = ed.text_scroll_handle.position.y
	ed._scroll_text(24)
	check(ed.text_scroll_handle.position.y > handle_top, "wheel scrolling moves description arrow down")
	ed._scroll_text(100000)
	check(is_equal_approx(ed.text_scroll_handle.position.y, 481.0), "description arrow stops at track bottom")
	ed._show_detail(axe)
	check(not ed.text_scroll_handle.visible and is_zero_approx(ed.text_scroll), "short description hides arrow and resets scroll")
	check(ed.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and ed.pool.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "deck UI and pixel fonts use crisp filtering")
	check(ed.d_art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and ed.pool.artwork_layer.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "preview and collection artwork retain smooth filtering")
	check(ed.pool.artwork_layer.show_behind_parent and ed.pool.artwork_layer.z_index == 0, "artwork draws behind row icons without falling behind panel background")
	check(hover_card.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "deck thumbnails retain smooth filtering")
	# collection strip
	check(ed.pool.rows.size() > 0, "collection lists the cards you own")
	# Native drawer transitions preserve deck and collection order.
	var before: PackedByteArray = ed.deck.to_bytes(ed.db)
	ed._refresh_pool()
	var initial_rows: Array = ed.pool.rows.duplicate()
	check(not ed.filter_controls.visible, "collapsed header hides filters")
	ed._toggle_collection()
	await create_timer(0.12).timeout
	check(ed.expansion > 0.0 and ed.expansion < 1.0, "drawer animates instead of jumping")
	await create_timer(0.3).timeout
	check(ed.filter_controls.visible and is_equal_approx(ed.pool.size.x, 188), "expanded drawer shows full controls")
	check(ed.deck.to_bytes(ed.db) == before and ed.pool.rows == initial_rows, "drawer preserves deck and collection")
	for group in ["normal", "effect", "fusion", "ritual", "spell", "trap"]:
		ed._set_group(group)
		check(not ed.pool.rows.is_empty(), group + " filter has cards")
		check(ed.pool.rows.all(func(i): return ed._group(i) == group), group + " filter excludes other types")
	ed._set_group("")
	check(ed.pool.rows == initial_rows, "All restores collection")
	for mode in range(1, 6):
		ed._cycle_sort()
		check(ed.sort_mode == mode, "sort cycles in reference order")
		var key: String = ["", "atk", "def", "kind", "attribute", "level"][mode]
		var monsters: Array = ed.pool.rows.filter(func(i): return ed.db.is_monster(i))
		for i in range(1, monsters.size()):
			var previous := int(ed.db.card(monsters[i - 1]).get(key, 0))
			var current := int(ed.db.card(monsters[i]).get(key, 0))
			check(previous >= current if mode in [1, 2, 5] else previous <= current, "sort ordered by " + key)
	ed._cycle_sort()
	check(ed.pool.rows == initial_rows, "sort wraps back to alphabetic")
	ed.search_text = "dragon"
	ed._set_group("fusion")
	check(ed.pool.rows.all(func(i): return ed._group(i) == "fusion" and (ed.db.card_name(i).to_lower().contains("dragon") or ed.db.card_desc(i).to_lower().contains("dragon"))), "search combines with native filter")
	ed._toggle_collection()
	await create_timer(0.4).timeout
	check(is_zero_approx(ed.expansion) and not ed.filter_controls.visible, "drawer closes cleanly")
	check(ed.deck.to_bytes(ed.db) == before, "filters and sorts never mutate saved deck")
	var reloaded := Control.new()
	reloaded.set_script(load("res://ui/deck_editor.gd"))
	reloaded.working_path = ed.working_path
	root.add_child(reloaded)
	await process_frame
	check(reloaded.deck.to_bytes(ed.db) == ed.deck.to_bytes(ed.db), "fresh editor restores autosaved deck")
	reloaded.queue_free()
	print("deck editor tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ed.working_path))
	quit(1 if fails else 0)

func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

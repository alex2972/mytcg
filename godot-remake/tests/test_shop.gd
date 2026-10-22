extends SceneTree
## Navigation, visual-only selection, category isolation and overflowing catalog.
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(800, 600)
	# UI assertions do not need music; avoid outstanding streaming audio at test exit.
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
		await process_frame
	# A throwaway account folder: the real player's accounts are never touched.
	var accounts_dir := "user://test_shop_accounts"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(accounts_dir + "/player/collection.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(accounts_dir + "/player/profile.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(accounts_dir + "/index.json"))
	root.get_node("Session").use_root(accounts_dir)
	var shell = load("res://ui/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	check(shell.current.main_menu.visible, "main menu exposes Shop")
	shell.current.main_menu.chosen.emit(3)
	await process_frame
	var shop = shell.current
	check(shop.name == "Shop", "main menu opens Shop")
	check(not shell.back_button.visible, "only the themed Back button is shown")
	var names: Array = shop.catalog.packs.map(func(p): return p.name)
	check(names.slice(0, 3) == ["MONSTERS 1", "SPELLS & TRAPS 1", "RITUAL & FUSION"], "first row: Monsters 1, Spells & Traps 1, Ritual & Fusion (%s)" % str(names))
	check(shop.products.size() == 5, "five packs")
	check(shop.clip.clip_contents, "catalog clips while header and footer remain fixed")
	check(shop.products[0].position.y == shop.products[2].position.y and shop.products[3].position.y > shop.products[0].position.y, "three packs per row")
	check(shop.balance.text == "2,450", "balance shows the new account's starting DP")
	check(not shop.content.has_node("PreviewPack0"), "real second row replaces the visual placeholders")
	check(shop.scroll_thumb.visible and not shop.scroll_down.disabled, "second row makes the catalog scrollable")
	check(not shop.price_buttons[2].disabled and shop.price_buttons[2].get_node("Caption").text == "150 DP", "Ritual & Fusion is on sale")
	shop.select_product(2)
	check(not shop.contents_button.disabled, "Ritual & Fusion has a card list")
	shop.select_product(1)
	check(not shop.contents_button.disabled, "Spells & Traps 1 has a card list")
	# With only three packs the reference's preview row returns (placeholders, never products).
	var five: Array = shop.catalog.packs.duplicate(true)
	shop.catalog.packs = five.slice(0, 3)
	shop.show_category("packs")
	check(shop.content.has_node("PreviewPack0"), "three packs show the preview row")
	shop.show_preview_row = false
	shop.show_category("packs")
	check(not shop.scroll_thumb.visible and shop.scroll_down.disabled, "without preview row a short catalog does not offer false scrolling")
	shop.products[2].pressed.emit()
	check(shop.selected_index == 2 and shop.markers[2].visible and not shop.markers[0].visible, "product selection moves corner markers")
	check(shop.balance.text == "2,450", "selection does not spend DP")
	shop.tabs["decks"].pressed.emit()
	check(shop.active_category == "decks" and shop.products.is_empty(), "Decks has its own empty catalog")
	shop.tabs["bundles"].pressed.emit()
	check(shop.active_category == "bundles" and shop.products.is_empty(), "Bundles has its own empty catalog")
	shop.tabs["packs"].pressed.emit()
	check(shop.products.size() == 3, "returning to Packs restores its catalog")
	# Inject overflow only in the test; the shipped screen never duplicates packs.
	var original: Array = shop.catalog.packs.duplicate(true)
	shop.catalog.packs.append_array(original)
	shop.catalog.packs.append_array(original)
	shop.show_category("packs")
	await process_frame
	check(shop.products[3].position.y > shop.products[0].position.y, "fourth item begins the next row")
	check(shop.scrollbar.max_value > shop.scrollbar.page, "larger catalog can scroll")
	check(shop.scroll_thumb.visible and not shop.scroll_down.disabled, "overflow shows working scrollbar")
	shop.scrollbar.value = 100
	check(shop.content.position.y == -100, "scrollbar moves catalog contents")
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(400, 300)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	shop._input(wheel)
	check(shop.scrollbar.value == 170, "wheel scroll advances the catalog")
	wheel.position = Vector2(250, 200)
	root.push_input(wheel)
	await process_frame
	check(shop.scrollbar.value == 240, "wheel over a product reaches catalog scrolling (value=%s, viewport=%s)" % [shop.scrollbar.value, root.size])
	var scroll_click := InputEventMouseButton.new()
	scroll_click.position = Vector2(768, 450)
	scroll_click.button_index = MOUSE_BUTTON_LEFT
	scroll_click.pressed = true
	root.push_input(scroll_click)
	scroll_click = scroll_click.duplicate()
	scroll_click.pressed = false
	root.push_input(scroll_click)
	await process_frame
	check(shop.scrollbar.value > 240, "clicking scrollbar track advances a page")
	scroll_click.position = shop.scroll_thumb.position + Vector2(5, 5)
	scroll_click.pressed = true
	root.push_input(scroll_click)
	var drag := InputEventMouseMotion.new()
	drag.position = Vector2(766, 120)
	root.push_input(drag)
	scroll_click.position = drag.position
	scroll_click.pressed = false
	root.push_input(scroll_click)
	await process_frame
	check(shop.scrollbar.value < 30, "reference-sized handle supports dragging to the top")
	shop.select_product(8)
	check(shop.scrollbar.value > 170, "keyboard selection scrolls into view")
	shop.catalog.packs = five
	shop.show_preview_row = true
	shop.show_category("packs")
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/shop_ui_kit/shop_in_game.png")
	shop.back_button.pressed.emit()
	await process_frame
	check(shell.current.get("main_menu") != null, "Back returns to main menu")
	shell.current.main_menu.chosen.emit(3)
	await process_frame
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	shell.current._unhandled_key_input(cancel)
	await process_frame
	check(shell.current.get("main_menu") != null, "Escape returns to main menu")
	shell.queue_free()
	await process_frame
	print("Shop: ", "OK" if fails == 0 else str(fails) + " FAILED")
	quit(fails)

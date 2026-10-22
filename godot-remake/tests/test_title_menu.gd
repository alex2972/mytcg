extends SceneTree

var fails := 0
var last_action := ""
const OUTPUT := "res://output/title_menu_checks"

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "/" + file + ".png")

func check_plank_animation(menu: PlankMenu, row: int, label: String) -> void:
	# Inspect actual GPU output: the untouched end of a custom plank must match
	# every original animation frame, not merely change its font or opacity.
	menu.set_process(false)
	menu.hover = -1
	menu._process(1.0)
	var idle_wood: PackedByteArray
	var idle_white := 0
	var clean_board: PackedByteArray
	var idle_letters: Image
	for frame in 7:
		if frame > 0:
			menu.hover = row
			menu._process(1.0 / PlankMenu.FRAME_SPEED)
		check(int(round(menu.level[row])) == frame, label + " advances through all seven frames")
		if DisplayServer.get_name() == "headless":
			continue
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		var origin := Vector2i(menu.global_position) + Vector2i(0, row * 50)
		var wood := rendered.get_region(Rect2i(origin + Vector2i(4, 4), Vector2i(44, 37)))
		var original := menu.frames[frame].get_image()
		var error := 0.0
		for y in 37:
			for x in 44:
				var actual := wood.get_pixel(x, y)
				var expected := original.get_pixel(x + 4, 150 + y + 4)
				error += absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b)
		check(error / (44 * 37 * 3) < 0.015, label + " wood matches original frame " + str(frame))
		# The previous inset spanned x=56..344 and y=4..40, which the old end-only
		# comparison missed. Check a full-width line INSIDE its lower boundary.
		# Unlike the top bevel, this line is clear of every highlighted glyph.
		var offset := 4 if frame == 6 else 0
		var seam_error := 0.0
		var idle_original := menu.frames[0].get_image()
		for x in range(4, 396):
			var actual := rendered.get_pixel(origin.x + x, origin.y + 40 + offset)
			var expected := idle_original.get_pixel(x, 190)
			seam_error += absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b)
		check(seam_error / (392 * 3) < 0.005, label + " has continuous original wood across the former inset, frame " + str(frame))
		var board := rendered.get_region(Rect2i(origin + Vector2i(0, offset), Vector2i(400, 44)))
		if frame == 0:
			idle_letters = board
		elif frame == 4 and label == "Shop":
			# Compare real idle ink with its solid counterpart at identical glyph
			# geometry. Most strokes must remain intact, with a minority of scrapes.
			var background: Image = PlankMenu.ORIGINAL_ART.theme(false).image
			var strokes := 0
			var intact := 0
			var scratched := 0
			for y in 44:
				for x in 400:
					if board.get_pixel(x, y).b < 0.98:
						continue
					strokes += 1
					var base := background.get_pixel(x, y).b
					var ink := (idle_letters.get_pixel(x, y).b - base) / maxf(0.01, 0.45 * (1.0 - base))
					if ink > 0.85:
						intact += 1
					elif ink > 0.1 and ink < 0.7:
						scratched += 1
			check(float(intact) / maxf(1, strokes) > 0.6, "Shop idle keeps most lettering intact")
			check(float(scratched) / maxf(1, strokes) > 0.05 and float(scratched) / maxf(1, strokes) < 0.35, "Shop idle mixes worn areas with clean strokes")
		elif frame == 5:
			clean_board = board.get_data()
		elif frame == 6:
			check(board.get_data() == clean_board, label + " plank AND letters move together by exactly four pixels")
		rendered.save_png(OUTPUT + "/" + label.to_lower() + "_frame_" + str(frame) + ".png")
		var white := 0
		for y in range(5, 40):
			for x in range(135, 265):
				var color := rendered.get_pixel(origin.x + x, origin.y + y)
				if minf(color.r, minf(color.g, color.b)) > 0.92:
					white += 1
		if frame == 0:
			idle_wood = wood.get_data()
			idle_white = white
		elif frame == 6:
			check(wood.get_data() != idle_wood, label + " animates the wooden plank itself")
			check(white > idle_white + 250, label + " restores clean highlighted lettering")
	menu.hover = -1
	menu._process(1.0)
	check(menu.level[row] == 0.0, label + " returns to worn idle state on exit")
	menu.set_process(true)

func run() -> void:
	root.size = Vector2i(800, 600)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
		await process_frame
	root.get_node("Session").use_root(OUTPUT + "/test_accounts")
	var title = load("res://ui/title_screen.gd").new()
	root.add_child(title)
	title.action.connect(func(action: String): last_action = action)
	await process_frame
	check(title.main_menu.custom_rows[3].text == "SHOP", "Shop replaces Options on the fourth plank")
	check(not title.has_node("ShopButton"), "temporary corner Shop button removed")
	check(title.options_button.position == Vector2(16, 16), "gear is in the top-left")
	await capture("main_idle")
	await check_plank_animation(title.main_menu, 3, "Shop")
	title.main_menu.hover = 3
	title.main_menu._process(0.3)
	check(title.main_menu.level[3] == 6.0, "Shop uses the existing hover animation timing")
	await capture("main_shop_hover")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(200, 175)
	title.main_menu._gui_input(click)
	check(last_action == "shop", "fourth plank requests Shop")
	title.options_button.pressed.emit()
	check(last_action == "options", "gear requests the original Options action")
	title.main_menu.chosen.emit(0)
	check(title.duel_menu.visible and not title.main_menu.visible, "Duel Mode opens its submenu")
	check(title.duel_menu.source_rows == [0, 1, 3, 4, 0], "Duelist LV is excluded and rows move up")
	check(title.duel_menu.custom_rows[4].text == "BACK", "fifth yellow plank is Back")
	check(not title.duel_menu.enabled[3], "unimplemented 2-player mode remains disabled")
	await capture("duel_idle")
	await check_plank_animation(title.duel_menu, 4, "Back")
	title.duel_menu.chosen.emit(2)
	check(last_action == "replay", "Replay uses its new third-row position")
	title.duel_menu.hover = 4
	title.duel_menu._process(0.3)
	await capture("duel_back_hover")
	click.position = Vector2(200, 225)
	title.duel_menu._gui_input(click)
	check(title.main_menu.visible and not title.duel_menu.visible and title.options_button.visible, "Back restores the main menu and gear")
	title.main_menu.chosen.emit(0)
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	title._unhandled_input(escape)
	check(title.main_menu.visible, "Escape also returns to main menu")
	title.queue_free()
	await process_frame
	var shell = load("res://ui/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	shell.current.main_menu.chosen.emit(3)
	await process_frame
	check(shell.current.name == "Shop", "new Shop plank reaches the actual Shop screen")
	shell.current.back_button.pressed.emit()
	await process_frame
	check(shell.current.get("main_menu") != null, "Shop Back returns to the updated main menu")
	shell.queue_free()
	await process_frame
	print("Title menu: ", "OK" if fails == 0 else str(fails) + " FAILED")
	quit(fails)

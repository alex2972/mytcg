extends SceneTree
## Windowed helper: screenshots of the janken screens. Run: Godot --path . -s tests/screenshot_janken.gd -- <dir>

func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var j := JankenScreen.new(5)
	root.add_child(j)
	await create_timer(0.5).timeout
	j._on_hand_hover(1, true)
	await create_timer(0.2).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/janken_select.png")
	j.my_pick = "cyo"
	j.cpu_pick = "pa"
	j._show_result()
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/janken_result.png")
	j.human_won = true
	j._show_order()
	await create_timer(0.3).timeout
	j._on_order_hover(0, true)
	await create_timer(0.2).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/janken_order.png")
	quit()

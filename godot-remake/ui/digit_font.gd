class_name DigitFont
extends RefCounted
## Draws numbers with the original's sprite fonts (a strip image with the digits 0-9 side by side).

static func draw_number(canvas: CanvasItem, tex: Texture2D, text: String, pos: Vector2, digit_w: float, digit_h: float, align := "left") -> void:
	var total := digit_w * text.length()
	var x := pos.x
	if align == "right":
		x -= total
	elif align == "center":
		x -= total / 2.0
	for ch in text:
		var d := "0123456789".find(ch)
		if d >= 0:
			canvas.draw_texture_rect_region(tex, Rect2(round(x), pos.y, floor(digit_w), digit_h), Rect2(floor(d * digit_w), 0, floor(digit_w), digit_h))
		x += digit_w

## A small Control that shows one number in a sprite font.
class Counter:
	extends Control
	var tex: Texture2D
	var text := ""
	var digit_w := 9.0
	var digit_h := 17.0
	var align := "center"

	func set_value(v, pad := 2) -> void:
		text = str(v).pad_zeros(pad)
		queue_redraw()

	func _draw() -> void:
		var x := size.x / 2.0 if align == "center" else (size.x if align == "right" else 0.0)
		DigitFont.draw_number(self, tex, text, Vector2(x, 0), digit_w, digit_h, align)

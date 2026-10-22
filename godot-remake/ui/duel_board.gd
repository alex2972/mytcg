class_name DuelBoard
extends Control
## The duel screen, laid out like the original (800x600): left info panel (230px), phase buttons (x=221),
## field art at x=230, hands peeking in from the top/bottom edges.
## Player 0 is the human (bottom), player 1 is the AI (top). The board only renders Duel state and forwards
## the player's choices; every rule lives in core/duel.gd.
##
## Interaction (from the original tutorial): hover a hand card -> cursor says Summon; right-click toggles
## Summon/Set; left-click does it. Right-click an empty part of the field for the phase menu.

signal left
signal draw_frame_shown(uid: int, progress: float)
signal lp_number_stage(player: int, stage: String, remaining: int)

const ICON_TEXTURES := preload("res://ui/deck_textures.gd")

const SIZE := Vector2(800, 600)
const BOARD_X := 230.0
const CARD := Vector2(50, 72)            # card on the field (the hover frame card_waku#s is 58x80 = 4px around it)
const HAND_CARD := Vector2(100, 145)    # native half-size card; mostly below the screen edge
const OPP_HAND_CARD := Vector2(100, 145)
const HAND_CENTER_X := 524.0             # hands are centred over the field...
const HAND_SPAN := 416.0                 # ...and spread over at most this width (6 cards overlap, like the original)
const HAND_MAX_STEP := 103.0
const COL0 := 100.0                       # board-relative x of the first column
const COLW := 78.0
const ROW_TOP := {"opp_st": 96.0, "opp_mon": 198.0, "my_mon": 306.0, "my_st": 414.0}
const MOVE_TIME := 0.28
const BATTLE_TIMING := preload("res://ui/battle_timing.gd")
const DRAW_TIME := 0.32
const LP_UPDATE_RATE := 60.0
const LP_ENTRY_TIME := 256.0 / (8.0 * LP_UPDATE_RATE)
const PHASE_KEYS := ["dr", "st", "m1", "ba", "m2", "en"]
const PHASE_IDS := ["draw", "standby", "main1", "battle", "main2", "end"]

enum Mode { IDLE, TRIBUTE, ATTACK_TARGET, DISCARD, AI }
const SELECT_HINT := "Select a card."

var db: CardDB
var duel: Duel
var lang := "eng"
## Field spells -> the original's field artwork (field/fie_<key>.png, name banner fie_<key>_f<lang letter>.png).
const FIELD_ART := {"Umiiruka": "water", "Umi": "umi", "Gaia Power": "gaia", "Wasteland": "kouya", "Luminous Spark": "shine",
	"Chorus of Sanctuary": "sanctu", "Sogen": "sougen", "Mystic Plasma Zone": "dark", "Rising Air Current": "desert",
	"Molten Destruction": "burn", "Fusion Gate": "fusion", "Forest": "mori", "Mountain": "yama", "Yami": "yami"}
const LANG_LETTER := {"eng": "e", "fra": "f", "ger": "g", "ita": "i", "spa": "s"}
var mode := Mode.IDLE
var views := {}                 # uid -> CardView
var cards_by_uid := {}          # uid -> DCard
var selected: Array = []        # uids chosen in TRIBUTE / DISCARD mode
var pending_card: DCard = null  # card being summoned / attacking
var hand_set_pref := false      # right-click toggles Summon <-> Set on hand monsters
var hovered: DCard = null
var cards_layer := Control.new()
var popup := PopupMenu.new()
var confirm := ConfirmationDialog.new()
var prompt := Label.new()
var banner := Label.new()
var shown_lp := [8000, 8000]
var ai_delay := 0.7
var hud := Control.new()
var phase_icons: Array = []
var phase_hover := -1
var phase_flipping := false
var phase_turn_progress := 1.0
var deck_armed := false          # first click on our own deck shows the Surrender hand

# detail panel parts
var d_art := TextureRect.new()
var d_name := Label.new()
var d_attr := Label.new()
var d_text := Label.new()
var d_stats := Label.new()

var tex_cache := {}
var detail_card: DCard = null
var pile_browser: Control = null
var pile_cards: Array = []
var pile_page := 0
var pile_player := 0
var pile_kind := "grave"
var piles := {}                 # "p0_deck" ... -> PileView
var stats_layer := Control.new()
var sword_layer := Control.new()
var idle_swords := {}           # uid -> TextureRect (translucent swords on monsters that can attack)
var sword_attacker_uid := -1
var active_sword: TextureRect = null
var attack_hover: DCard = null
var stat_cache := {}        # uid -> last drawn ATK/DEF line, so a battle-destroyed card keeps it until its explosion
var lingering_stats := {}   # uid -> true while a destroyed monster still shows on the field
var battle_visual := {}
var pending_draws := {}         # Batched draws enter the visible hand one at a time.
var battle_numbers := 0
var pending_lp_visuals: Array[Dictionary] = []

class LifeNumber:
	extends Control
	var sheet: Texture2D
	var remaining := 0
	var heal := false
	var entry_tick := 0.0
	func number_text() -> String:
		return ("+" if heal else "-")+str(remaining)
	func glyph_pose(index: int) -> Dictionary:
		var count := number_text().length()
		var delay := floorf(64.0/maxi(1,count-1))
		var age := entry_tick*2.0-(count-1-index)*delay
		if age < 0.0 or entry_tick <= 0.0: return {"visible":false,"y":0.0}
		var y := 0.0
		if age < 128.0:
			y = -sin(age*PI/128.0)*40.0
		elif age < 192.0:
			y = -sin((age-128.0)*PI/64.0)*10.0
		return {"visible":true,"y":y}
	func _draw() -> void:
		if sheet == null or remaining <= 0: return
		var text := number_text()
		var origin := (size.x-text.length()*16.0)/2
		for i in text.length():
			var pose := glyph_pose(i)
			if not pose["visible"]: continue
			var glyph := "0123456789+-".find(text[i])
			draw_texture_rect_region(sheet,Rect2(origin+i*16.0,float(pose["y"]),16,40),Rect2(glyph*16,0,16,40))
	static func remaining_steps(amount: int) -> Array[int]:
		var steps: Array[int] = [maxi(0,amount)]
		while amount > 0:
			amount -= 100 if amount >= 100 else (10 if amount >= 10 else 1)
			steps.append(amount)
		return steps
var attack_ring := TextureRect.new()
var modal_depth := 0
var presented_decision: Dictionary = {}
var discard_dialog: DuelDialog = null
var revealed_cards: Dictionary = {}  # Visual only: never changes DCard.face_up or fires effects.
var order_panel: Control = null
var order_ranks: Dictionary = {}
var decision_busy := false      # a decision dialog is being shown / answered right now
var sword_anchor := Vector2.ZERO   # centre of the monster the active sword is stuck in
var skip_next_sword := false    # the human's own attack already flew its sword
var d_text_box := Control.new()
var d_icons := Control.new()
var text_scroll := 0.0

# effect decisions
var decision_popup := PopupPanel.new()
var decision_box := VBoxContainer.new()
var decision_label := Label.new()
var list_dialog := ConfirmationDialog.new()
var list_view := ItemList.new()
var list_cards: Array = []
var ok_button := Button.new()
var response_selection: Dictionary = {}
var decision_selected: Array = []
var ai_running := false
var fx: DuelFx
var anim_busy := false
var fx_enabled := true
var music_started := false
var strings: Array = []
var opening_source: SubViewport = null

func _init(card_db: CardDB, deck0: Deck, deck1: Deck, seed_value := 0, first := 0) -> void:
	db = card_db
	duel = Duel.create(db, deck0, deck1, seed_value, first, null, true)
	duel.no_first_turn_attack = true
	custom_minimum_size = SIZE
	size = SIZE

func _ready() -> void:
	fx_enabled = ai_delay > 0.0
	duel.fx.presentation_enabled = fx_enabled
	duel.fx.interactive_selections = fx_enabled
	_build()
	_sync(false)
	_update_ui()
	_update_music()
	if fx_enabled:
		anim_busy = true
		if is_instance_valid(opening_source):
			await fx.reveal_board(opening_source.get_texture())
		await fx.start_duel(LANG_LETTER.get(lang, "e"))
		anim_busy = false
	if is_instance_valid(opening_source):
		opening_source.queue_free()
		opening_source = null
	duel.start_opening_deal()
	await _after_action()
	_maybe_ai()

func _exit_tree() -> void:
	if is_instance_valid(opening_source):
		opening_source.queue_free()

# --- construction -------------------------------------------------------------

func _tex(path: String) -> Texture2D:
	if not tex_cache.has(path):
		tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[path]

func _ui(rel: String) -> Texture2D:
	if rel in ["card/icon_zokusei", "card/icon_syuzoku"]:
		return ICON_TEXTURES.get_texture("res://assets/j/duel/%s.png" % rel)
	return _tex("res://assets/j/duel/%s.png" % rel)

func _add_tex(parent: Node, tex: Texture2D, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

func _label(parent: Node, pos: Vector2, size_: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size_
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _build() -> void:
	var field := _add_tex(self, _tex("res://assets/ui/field_normal.png"), Vector2(BOARD_X, 0))
	field.name = "Field"
	for key in ["p0_deck", "p0_grave", "p0_extra", "p1_deck", "p1_grave", "p1_extra"]:
		var pv := PileView.new()
		pv.board = self
		pv.kind = key.substr(3)
		pv.player = int(key.substr(1, 1))
		pv.position = _pile_pos(key)
		pv.z_index = 2
		add_child(pv)
		piles[key] = pv
		if pv.kind in ["grave", "extra"]:
			var hot := Control.new()
			hot.position = pv.position + Vector2(6, 0)
			hot.size = CARD
			hot.z_index = 4
			hot.mouse_filter = Control.MOUSE_FILTER_STOP
			hot.gui_input.connect(_on_pile_input.bind(pv.player, pv.kind))
			hot.mouse_entered.connect(func():
				var contents: Array = duel.side(pv.player).get(pv.kind)
				if pv.kind == "grave" and not contents.is_empty(): _show_card_detail(contents.back())
				CursorUtil.set_state("on"))
			add_child(hot)
	var deck_hot := Control.new()
	deck_hot.position = _pile_pos("p0_deck") + Vector2(6, 0)
	deck_hot.size = CARD
	deck_hot.z_index = 3
	deck_hot.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_hot.mouse_exited.connect(func():
		deck_armed = false
		CursorUtil.set_state("off"))
	deck_hot.gui_input.connect(_on_own_deck_input)
	add_child(deck_hot)
	cards_layer.size = SIZE
	cards_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards_layer)
	stats_layer.size = SIZE
	stats_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_layer.z_index = 7
	stats_layer.draw.connect(_draw_stats)
	add_child(stats_layer)
	sword_layer.size = SIZE
	sword_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sword_layer.z_index = 58
	add_child(sword_layer)
	# left panel on top of the board edge
	hud.size = SIZE
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.z_index = 40
	add_child(hud)
	_add_tex(hud, _ui("detail/detail"), Vector2.ZERO)
	d_art.position = Vector2(7, 78)
	d_art.size = Vector2(188, 280)
	d_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d_art.stretch_mode = TextureRect.STRETCH_SCALE
	d_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(d_art)
	d_name = _label(hud, Vector2(7, 361), Vector2(180, 18), 12, Color.BLACK)
	var name_font := SystemFont.new()
	name_font.font_names = PackedStringArray(["Arial"])
	name_font.font_weight = 700
	d_name.add_theme_font_override("font", name_font)
	d_name.clip_text = true
	d_text_box.position = Vector2(7, 379)
	d_text_box.size = Vector2(178, 128)
	d_text_box.clip_contents = true
	d_text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(d_text_box)
	d_attr = _label(d_text_box, Vector2.ZERO, Vector2(178, 16), 11, Color(0.72, 0.18, 0.05))
	d_text = _label(d_text_box, Vector2(0, 16), Vector2(176, 400), 11, Color(0.15, 0.1, 0.05))
	d_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_icons.position = Vector2(6, 510)
	d_icons.size = Vector2(36, 16)
	d_icons.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	d_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d_icons.draw.connect(_draw_detail_icons)
	hud.add_child(d_icons)
	d_stats = _label(hud, Vector2(42, 509), Vector2(150, 16), 10, Color.BLACK)
	var stat_font := SystemFont.new()
	stat_font.font_names = PackedStringArray(["Arial Black", "Arial"])
	stat_font.font_weight = 900
	stat_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	stat_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	d_stats.add_theme_font_override("font", stat_font)
	d_stats.scale.x = 1.1
	# LP meters (positions from the original's lifepoint.txt)
	_add_tex(hud, _ui("life/lp_aite1"), Vector2(14, 43))
	_add_tex(hud, _ui("life/lp_jibu1"), Vector2(14, 571))
	for p in 2:
		# Reveal a fixed-size texture through a shrinking clip; never squeeze its pattern.
		var fill := Control.new()
		fill.name = "LPFill%d" % p
		fill.position = Vector2(42, 45 if p == 1 else 573)
		fill.size = Vector2(150, 16)
		fill.clip_contents = true
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(fill)
		_add_tex(fill, _ui("life/lp_aite2" if p == 1 else "life/lp_jibu2"), Vector2.ZERO)
		var digits := Control.new()
		digits.name = "LPDigits%d" % p
		digits.position = Vector2(0, 1 if p == 1 else 528)
		digits.size = Vector2(190, 34)
		digits.mouse_filter = Control.MOUSE_FILTER_IGNORE
		digits.draw.connect(_draw_lp.bind(digits, p))
		hud.add_child(digits)
	# The board artwork already contains the metal strip. Overlay only each button,
	# excluding the sprite cell's extra mesh and bevel that otherwise duplicate it.
	for i in 6:
		var icon := TextureRect.new()
		icon.position = Vector2(221, 86 + 75 * i)
		icon.size = Vector2(30, 52)
		icon.pivot_offset = icon.size / 2
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.gui_input.connect(_on_phase_icon.bind(i))
		icon.mouse_entered.connect(func():
			phase_hover = i
			CursorUtil.set_state("on" if _phase_click_ok(i) else "off")
			_set_phase_icons())
		icon.mouse_exited.connect(func():
			phase_hover = -1
			CursorUtil.set_state("off")
			_set_phase_icons())
		hud.add_child(icon)
		phase_icons.append(icon)
	prompt.position = Vector2(BOARD_X + 8, 470)
	prompt.size = Vector2(SIZE.x - BOARD_X - 16, 40)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 5)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.z_index = 45
	add_child(prompt)
	banner.position = Vector2(BOARD_X, 230)
	banner.size = Vector2(SIZE.x - BOARD_X, 100)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 56)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.add_theme_constant_override("outline_size", 12)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 60
	banner.visible = false
	add_child(banner)
	popup.id_pressed.connect(_on_menu)
	add_child(popup)
	confirm.dialog_text = "End your turn?"
	confirm.confirmed.connect(func(): _try_end_turn())
	add_child(confirm)
	gui_input.connect(_on_board_input)
	fx = DuelFx.new()
	fx.z_index = 55
	add_child(fx)
	fx.turn_wipe.connect(_on_turn_wipe)
	attack_ring.texture = _ui("effect/atk_eff")
	attack_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attack_ring.size = Vector2(80, 80)
	attack_ring.hide()
	sword_layer.add_child(attack_ring)
	_build_decision_ui()
	_show_card_detail(null)

## A deck / graveyard / fusion pile drawn like the original: the edge strip (deck.png / grave.png) under the top card
## gives the stack its thickness, and the card count sits underneath in the small white digit font.
class PileView:
	extends Control
	var board: DuelBoard
	var kind := "deck"
	var player := 0
	var count := 0
	var top: Texture2D

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(60, 96)

	func stack_depth() -> int:
		# A two-card pile exposes one thin edge; only a full deck gets the full stack.
		return clampi(ceili((count - 1) / 4.0), 0, 10)
	func shows_count() -> bool:
		return count > (1 if kind == "grave" else 0)

	func _draw() -> void:
		if count <= 0:
			return
		var edge: Texture2D = board._ui("card/grave" if kind == "grave" else "card/deck")
		var depth := stack_depth()
		if depth > 0 and edge != null:
			# Two 60x82 variants: bottom-left and bottom-right edges around a
			# 50x72 card. Scale only the exposed edges, leaving the card unchanged.
			var right := player == 1
			var side_src := 110.0 if right else 0.0
			var bottom_src := 60.0 if right else 10.0
			var side_x := 6.0 + CARD.x if right else 6.0 - depth
			draw_texture_rect_region(edge, Rect2(side_x, 0, depth, CARD.y), Rect2(side_src, 0, 10, CARD.y))
			draw_texture_rect_region(edge, Rect2(side_x, CARD.y, depth, depth), Rect2(side_src, CARD.y, 10, 10))
			draw_texture_rect_region(edge, Rect2(6, CARD.y, CARD.x, depth), Rect2(bottom_src, CARD.y, CARD.x, 10))
		if top != null:
			if player == 1 and kind == "deck":
				# Native opponent deck has KONAMI at bottom-left. Flip the face
				# vertically; the perspective edges and counter have their own layout.
				draw_set_transform(Vector2(6, CARD.y), 0.0, Vector2(1, -1))
				draw_texture_rect(top, Rect2(Vector2.ZERO, CARD), false)
				draw_set_transform(Vector2.ZERO)
			else:
				draw_texture_rect(top, Rect2(6, 0, CARD.x, CARD.y), false)
		var small: Texture2D = board._ui("font/duel_fonts")
		if small != null and shows_count():
			DigitFont.draw_number(self, small, str(count), Vector2(31, 82), 6, 8, "center")

func _atlas(t: Texture2D, r: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = t
	a.region = r
	return a

func _pile_pos(key: String) -> Vector2:
	var p := int(key.substr(1, 1))
	var kind := key.substr(3)
	if p == 0:
		return {"deck": Vector2(728, 414), "grave": Vector2(728, 330), "extra": Vector2(250, 422)}[kind]
	return {"deck": Vector2(248, 94), "grave": Vector2(248, 176), "extra": Vector2(732, 102)}[kind]

func _draw_lp(canvas: Control, p: int) -> void:
	var digits := _ui("life/lp_123")
	var text := str(shown_lp[p])
	var x := 186.0 - 26.0 * text.length()
	for ch in text:
		var d := int(ch)
		canvas.draw_texture_rect_region(digits, Rect2(x, 0, 26, 34), Rect2(d * 26, 0, 26, 34))
		x += 26.0

# --- positions ---------------------------------------------------------------

func _zone_pos(p: int, spell: bool, z: int) -> Vector2:
	var col := z if p == 0 else 4 - z
	var key := ("my_st" if spell else "my_mon") if p == 0 else ("opp_st" if spell else "opp_mon")
	return Vector2(BOARD_X + COL0 + COLW * col + (COLW - CARD.x) / 2, ROW_TOP[key] + (100 - CARD.y) / 2)

func _hand_pos(p: int, i: int, n: int, raised := false) -> Vector2:
	var w := HAND_CARD.x if p == 0 else OPP_HAND_CARD.x
	var step: float = minf(HAND_MAX_STEP, HAND_SPAN / maxf(1.0, n - 1))
	var total := step * (n - 1) + w
	var visual_index: int = i if p == 0 else n - 1 - i
	var x := HAND_CENTER_X - total / 2 + step * visual_index
	if p == 0:
		return Vector2(x, 466 if raised else 530)
	return Vector2(x, -75)

# --- view sync ---------------------------------------------------------------

class CardView:
	extends TextureRect
	var card: DCard
	var shown_face_up := false
	var motion: Tween
	var presenting := false  # Event playback owns this view until its awaited motion completes.
	var frame := TextureRect.new()

	func _init() -> void:
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.visible = false
		add_child(frame)

	func show_frame(tex: Texture2D) -> void:
		frame.texture = tex
		frame.position = Vector2(-4, -4)
		frame.size = size + Vector2(8, 8)
		frame.visible = tex != null

func _all_cards() -> Array:
	var out := []
	for p in 2:
		var s: Duel.PlayerSide = duel.side(p)
		for c in s.deck + s.hand + s.grave + s.banished + s.extra + s.monsters + s.spells:
			if c != null:
				out.append(c)
		if s.field_spell != null:
			out.append(s.field_spell)
	return out

func _texture_for(c: DCard, face_up: bool) -> Texture2D:
	if face_up:
		var path := db.art_path(c.idx)
		var t := _tex(path) if path != "" else null
		if t != null:
			return t
	return _tex("res://assets/ui/card_back.png")

## Where a card should be drawn: {pos, size, face_up, rot, visible, z}
func _layout(c: DCard) -> Dictionary:
	var s: Duel.PlayerSide = duel.side(c.owner)
	var human := c.owner == 0
	var i: int = (s.hand as Array).find(c)
	if i != -1:
		var hand: Array = _presented_hand(c.owner)
		i = hand.find(c)
		var raised := human and hovered == c and mode in [Mode.IDLE, Mode.DISCARD, Mode.AI]
		return {"pos": _hand_pos(c.owner, maxi(i,0), hand.size(), raised), "size": HAND_CARD if human else OPP_HAND_CARD,
			"face_up": human, "rot": 0.0 if human else 180.0, "visible": i != -1, "z": 20 + i}
	var controlled: Duel.PlayerSide = duel.side(c.controller)
	if controlled.field_spell == c:
		return {"pos": _field_spell_position(c.controller), "size": CARD, "face_up": c.face_up, "rot": 0.0 if c.controller == 0 else 180.0, "visible": true, "z": 5}
	i = (controlled.monsters as Array).find(c)
	if i != -1:
		return {"pos": _zone_pos(c.controller, false, i), "size": CARD, "face_up": c.face_up,
			"rot": (90.0 if c.pos == "def" else 0.0) + (0.0 if c.controller == 0 else 180.0), "visible": true, "z": 5}
	i = (controlled.spells as Array).find(c)
	if i != -1:
		return {"pos": _zone_pos(c.controller, true, i), "size": CARD, "face_up": c.face_up, "rot": 0.0 if c.controller == 0 else 180.0, "visible": true, "z": 5}
	i = (s.grave as Array).find(c)
	if i != -1:
		return {"pos": _pile_pos("p%d_grave" % c.owner) + Vector2(6, 0), "size": CARD, "face_up": true, "rot": 0.0, "visible": i == s.grave.size() - 1, "z": 3}
	return {"pos": _pile_pos("p%d_deck" % c.owner) + Vector2(6, 0), "size": CARD, "face_up": false, "rot": 0.0, "visible": false, "z": 0}

func _make_view(c: DCard) -> CardView:
	var v := CardView.new()
	v.card = c
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	v.gui_input.connect(_on_card_input.bind(v))
	v.mouse_entered.connect(_on_card_enter.bind(v))
	v.mouse_exited.connect(_on_card_exit.bind(v))
	cards_layer.add_child(v)
	return v

func _sync(animate := true) -> void:
	var alive := {}
	for c in _all_cards():
		alive[c.uid] = true
	for uid in views.keys():                      # tokens that left the field vanish
		var cc: DCard = duel.card_by_uid(uid)
		if cc != null and cc.token != "" and not alive.has(uid) and not (views[uid] as CardView).presenting:
			(views[uid] as Node).queue_free()
			views.erase(uid)
	for c in _all_cards():
		cards_by_uid[c.uid] = c
		var v: CardView = views.get(c.uid)
		# Killing an event tween does not emit finished; its caller would wait forever.
		if v != null and v.presenting:
			continue
		var lay := _layout(c)
		if v == null:
			v = _make_view(c)
			views[c.uid] = v
			v.size = lay["size"]
			v.position = _pile_pos("p%d_deck" % c.owner)
		var face: bool = lay["face_up"] or revealed_cards.has(c.uid)
		if v.shown_face_up != face or v.texture == null:
			v.texture = _texture_for(c, face)
			v.shown_face_up = face
		v.visible = lay["visible"]
		v.z_index = lay["z"]
		var sz: Vector2 = lay["size"]
		v.pivot_offset = sz / 2
		if v.motion != null and v.motion.is_valid():
			v.motion.kill()
		if animate and v.visible:
			var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			v.motion = tw
			tw.tween_property(v, "position", lay["pos"], MOVE_TIME)
			tw.tween_property(v, "size", sz, MOVE_TIME)
			tw.tween_property(v, "rotation_degrees", lay["rot"], MOVE_TIME)
		else:
			v.position = lay["pos"]
			v.size = sz
			v.rotation_degrees = lay["rot"]
	_highlight()

func _set_phase_icons(wipe := 1.0) -> void:
	if phase_flipping: wipe = phase_turn_progress
	var cur := PHASE_IDS.find(duel.phase)
	for i in 6:
		var turn := clampf((wipe-i*0.13)/0.35,0.0,1.0) if phase_flipping else 1.0
		var red := (duel.turn_player == 1) if turn >= 0.5 else (duel.turn_player == 0)
		var sheet := _ui("phase/pha_s_%s" % PHASE_KEYS[i])
		if sheet == null:
			continue
		var active := i == cur or (i == phase_hover and _phase_click_ok(i))
		phase_icons[i].texture = _atlas(sheet, Rect2(40 if active else 0, (75 if red else 0) + 4, 30, 52))
		phase_icons[i].scale.x = absf(cos(turn*PI))

func _on_turn_wipe(progress: float) -> void:
	phase_turn_progress = progress
	_set_phase_icons(progress)

func _update_ui() -> void:
	for p in 2:
		var s: Duel.PlayerSide = duel.side(p)
		var back := _tex("res://assets/ui/card_back.png")
		var deck_pv: PileView = piles["p%d_deck" % p]
		deck_pv.count = s.deck.size()
		deck_pv.top = back
		deck_pv.queue_redraw()
		var extra_pv: PileView = piles["p%d_extra" % p]
		extra_pv.count = s.extra.size()
		extra_pv.top = back
		extra_pv.queue_redraw()
		var grave_pv: PileView = piles["p%d_grave" % p]
		grave_pv.count = s.grave.size()
		grave_pv.top = null                    # the top grave card is a real card view (face-up)
		grave_pv.queue_redraw()
		(hud.get_node("LPDigits%d" % p) as Control).queue_redraw()
		var fill := hud.get_node("LPFill%d" % p) as Control
		var ratio := clampf(float(shown_lp[p]) / Duel.START_LP, 0.0, 1.0)
		fill.size = Vector2(150.0 * ratio, 16)
		fill.visible = ratio > 0.0
	_set_phase_icons()
	_update_field_art()
	_refresh_swords()
	match mode:
		Mode.TRIBUTE:
			prompt.text = "Select %d monster(s) as Tribute (%d chosen). Right-click to cancel." % [duel.tributes_required(pending_card), selected.size()]
		Mode.ATTACK_TARGET:
			prompt.text = "Select the monster you wish to attack. Right-click to cancel."
		Mode.DISCARD:
			prompt.text = ""
			_show_discard_prompt()
		_:
			if prompt.text.begins_with("Select") or prompt.text.begins_with("Hand limit"):
				prompt.text = ""
	_highlight()

func _highlight() -> void:
	for uid in views:
		(views[uid] as CardView).modulate = Color.WHITE

# --- detail panel ---------------------------------------------------------------

func _show_card_detail(c: DCard) -> void:
	if c == null or (c.owner == 1 and not c.face_up and not revealed_cards.has(c.uid) and not duel.side(1).grave.has(c) and not pile_cards.has(c)):
		d_art.texture = _tex("res://assets/ui/card_back.png")
		d_name.text = ""
		d_attr.text = ""
		d_text.text = ""
		d_stats.text = ""
		detail_card = null
		d_icons.queue_redraw()
		return
	var path := db.art_path(c.idx)
	var art := _tex(path) if path != "" else null
	d_art.texture = art if art != null else _tex("res://assets/ui/card_back.png")
	var data := db.card(c.idx)
	d_name.text = db.card_name(c.idx, lang)
	var is_mon := db.is_monster(c.idx)
	d_attr.text = "[%s]" % CardDB.RACES[int(data.kind)] if is_mon and int(data.kind) < CardDB.RACES.size() else ""
	d_attr.visible = is_mon
	d_text.position.y = 16.0 if is_mon else 0.0
	d_text.text = db.card_desc(c.idx, lang)
	text_scroll = 0.0
	d_stats.text = "ATK/%d  DEF/%d" % [duel.atk_of(c), duel.def_of(c)] if is_mon else ""
	detail_card = c
	d_icons.queue_redraw()

# --- messages / feedback ------------------------------------------------------------

func _floating(text: String, pos: Vector2, color := Color.SALMON) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.z_index = 100
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 60, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(l.queue_free)

var match_game := 0                 # 0 = single duel, 1..3 = game of a Match Duel (picks m_duel1..3)
var single_theme := -1

## Series theme normally; m_furi / m_yuri while the player is losing / winning badly (LP lead of 1500 and under 3000).
func _update_music() -> void:
	if duel.winner != -1:
		return
	if single_theme < 0:
		single_theme = duel.rng.randi() % 3
	var mood := MusicMood.mood(duel.side(0).lp, duel.side(1).lp)
	AudioUtil.music(MusicMood.track(mood, match_game, single_theme))

func _animate_lp(reconcile := true) -> void:
	while not pending_lp_visuals.is_empty():
		var state: Dictionary = pending_lp_visuals.pop_front()
		await _finish_lp_visual(state)
	if not reconcile and fx_enabled: return
	for p in 2:
		var target: int = duel.side(p).lp
		if shown_lp[p] != target:
			if not fx_enabled:
				shown_lp[p] = target
				continue
			var steps := LifeNumber.remaining_steps(absi(target-int(shown_lp[p])))
			var direction := 1 if target > int(shown_lp[p]) else -1
			var start: int = int(shown_lp[p])
			var animation := create_tween()
			animation.tween_method(func(progress: float):
				shown_lp[p] = start+direction*(steps[0]-steps[mini(int(progress),steps.size()-1)])
				_update_ui(),0.0,float(steps.size()-1),(steps.size()-1)/BATTLE_TIMING.LP_COUNT_RATE)
			await animation.finished

## Run after every engine action: play the animations for what happened, then refresh the board.
func _after_action() -> void:
	while anim_busy:
		await get_tree().process_frame
	anim_busy = true
	var battle_finished := false
	while true:
		await _play_events(duel.drain_events())
		while is_instance_valid(pile_browser):
			await get_tree().process_frame
		if duel.fx.pending.get("type", "") != "presentation":
			break
		_sync(false)
		duel.respond(true)
	if not battle_visual.is_empty() and duel.current_attack.is_empty() and duel.fx.pending.is_empty():
		if battle_visual.get("damage_step", false) and duel.is_on_field(duel.card_by_uid(int(battle_visual["attacker"]))):
			var target: DCard = duel.card_by_uid(int(battle_visual["target"]))
			if target == null or duel.is_on_field(target):
				await _present_damage_calculation()
		battle_visual.clear()
		battle_finished = true
	await fx.wait_for_tributes()
	_sync(fx_enabled)
	await _animate_lp()
	await _wait_battle_numbers()
	_update_ui()
	_update_music()
	if battle_finished:
		await _battle_pause(BATTLE_TIMING.AFTER_ATTACK_PAUSE)
	anim_busy = false
	if active_sword == null and mode != Mode.ATTACK_TARGET and duel.current_attack.is_empty():
		sword_attacker_uid = -1
	_refresh_swords()
	_check_decision()

func _view_center(uid: int) -> Vector2:
	var v: CardView = views.get(uid)
	if v == null:
		return Vector2(515, 300)
	return v.position + v.size / 2

func _zone_center(p: int, spell: bool, z: int) -> Vector2:
	return _zone_pos(p, spell, z) + CARD / 2

## Sounds and animations for the events of one engine action (events are in the order they happened).
func _play_events(events: Array) -> void:
	for event in events:
		if event["type"] == "draw":
			pending_draws[int(event["uid"])] = true
			if views.has(int(event["uid"])): views[int(event["uid"])].hide()
	var battle_deaths: Array = events.filter(func(item): return item["type"] in ["to_grave", "destroy"] and item.get("reason", "") == "destroyed:battle").map(func(item): return int(item["uid"]))
	if not battle_visual.is_empty() and battle_deaths.has(int(battle_visual["target"])):
		battle_visual["target_destroyed"] = true
	var battle_group: Array = events.filter(func(item): return _is_battle_result(item))
	var battle_group_done := false
	for e in events:
		while is_instance_valid(pile_browser):
			await get_tree().process_frame
		if e["type"] in ["to_deck", "to_hand", "to_grave", "banish", "destroy", "tribute", "token_gone", "control"] and e.has("uid"):
			_drop_idle_sword(int(e["uid"]))
		if _is_battle_result(e):
			if not battle_group_done:
				battle_group_done = true
				await _present_battle_result(battle_group)
			continue
		match e["type"]:
			"turn":
				AudioUtil.sfx("turn_change")
				if fx_enabled and e["turn"] > 1:
					phase_flipping = true
					phase_turn_progress = 0.0
					_set_phase_icons(0.0)
					await fx.turn_banner(e["player"] == 0)
					phase_flipping = false
					phase_turn_progress = 1.0
					_set_phase_icons()
			"phase":
				_refresh_swords()
				if e["phase"] == "battle":
					AudioUtil.sfx("battle_turn")
				if fx_enabled:
					await fx.phase_banner(e["phase"], e["player"] == 0)
					if e["phase"] == "battle": await _battle_pause(BATTLE_TIMING.AFTER_PHASE_ENTRY_PAUSE)
			"draw":
				var player: int = int(e["player"])
				var card: DCard = duel.card_by_uid(int(e["uid"]))
				pending_draws.erase(card.uid)
				var hand: Array = _presented_hand(player)
				AudioUtil.sfx("card_move")
				_update_ui()
				await _draw_to_hand(card, player, hand.find(card), hand.size())
				_sync(false)
				_update_ui()
				if fx_enabled and e.get("opening", false):
					await get_tree().create_timer(0.08 if hand.size() < 5 else 0.35).timeout
			"summon", "set_monster":
				await _move_card(int(e["uid"]), _zone_pos(int(e["player"]), false, int(e["zone"])), e["type"] == "summon", (0.0 if e["type"] == "summon" else 90.0) + (180.0 if int(e["player"]) == 1 else 0.0))
				AudioUtil.sfx("card_move")
				if fx_enabled:
					var summoned_view: CardView = views.get(int(e["uid"]))
					stats_layer.queue_redraw()
					if e["type"] == "summon":
						await get_tree().create_timer(0.2).timeout
					_show_card_detail(duel.card_by_uid(int(e["uid"])))
					if e["type"] == "set_monster":
						await fx.set_card(_zone_center(e["player"], false, e["zone"]), true)
					elif summoned_view != null:
						await fx.summon_rainbow(summoned_view)
			"set_spell":
				await _move_card(int(e["uid"]), _zone_pos(int(e["player"]), true, int(e["zone"])), false, 180.0 if int(e["player"]) == 1 else 0.0)
				AudioUtil.sfx("card_move")
				if fx_enabled:
					await fx.set_card(_zone_center(e["player"], true, e["zone"]))
			"to_grave":
				var uid := int(e["uid"])
				var reason := str(e.get("reason", ""))
				var destroyed := reason.begins_with("destroyed")
				if destroyed and fx_enabled and views.has(uid):
					await _present_destroyed_to_grave(e)
				else:
					if reason == "tribute":
						await _present_tribute(uid, int(e["player"]))
					else:
						if fx_enabled and reason == "resolved": fx.animation_stage.emit("graveyard", "flight")
						await _move_card(uid, _pile_pos("p%d_grave" % int(e["player"])) + Vector2(6, 0), true, 0.0, CARD, 0.4 if reason == "resolved" else MOVE_TIME)
						if fx_enabled and reason == "resolved": fx.animation_stage.emit("graveyard", "complete")
				# the original's scene-change sound belongs to Field Spells leaving the field
				var gone: DCard = duel.card_by_uid(int(e["uid"]))
				if gone != null and duel.card_data(gone).get("subtype_name", "") == "field":
					AudioUtil.sfx("scene_change")
			"activate_spell", "field_spell":
				if e["type"] == "field_spell":
					await _move_card(int(e["uid"]), _field_spell_position(int(e["player"])), true, 180.0 if int(e["player"]) == 1 else 0.0)
				elif e.has("zone"):
					await _move_card(int(e["uid"]), _zone_pos(int(e["player"]), true, int(e["zone"])), true, 180.0 if int(e["player"]) == 1 else 0.0)

				if e["type"] == "field_spell" and fx_enabled:
					var key := _field_key(duel.card_by_uid(int(e["uid"])))
					if key != "":
						await fx.banner(["field/fie_%s_f%s" % [key, LANG_LETTER.get(lang, "e")]], 0.0, 0.9)
			"special_summon":
				var reborn: DCard = duel.card_by_uid(int(e["uid"]))
				var summoned_face_up: bool = e.get("face_up", reborn.face_up)
				await _move_card(reborn.uid, _zone_pos(int(e["player"]), false, int(e["zone"])), summoned_face_up, (90.0 if e.get("pos", reborn.pos) == "def" else 0.0) + (180.0 if int(e["player"]) == 1 else 0.0))
				AudioUtil.sfx("reborn")
				if fx_enabled:
					stats_layer.queue_redraw()
					if summoned_face_up:
						await fx.summon_rainbow(views[int(e["uid"])])
					else:
						await fx.set_card(_zone_center(int(e["player"]), false, int(e["zone"])), true)
			"tribute":
				await _present_tribute(int(e["uid"]), int(e["player"]))
			"flip", "flip_summon":
				var battle_flip: bool = not battle_visual.is_empty() and int(battle_visual["target"]) == int(e["uid"])
				await _display_flip(int(e["uid"]), BATTLE_TIMING.CARD_FLIP_DURATION if battle_flip else 0.16)
			"card_activated":
				var kind: String = str(e["kind"])
				if views.has(int(e["uid"])) and not views[int(e["uid"])].shown_face_up:
					await _display_flip(int(e["uid"]))
				_show_card_detail(duel.card_by_uid(int(e["uid"])))
				AudioUtil.sfx("scene_change" if kind == "field" else "magic_active")
				if fx_enabled:
					await fx.activation(_view_center(int(e["uid"])))
			"change_position":
				AudioUtil.sfx("card_move")
			"equip":
				AudioUtil.sfx("equip")
			"to_deck":
				AudioUtil.sfx("return")
				await _move_card(int(e["uid"]), _pile_pos("p%d_%s" % [int(e["player"]), "extra" if e.get("extra", false) else "deck"]), false)
			"to_hand":
				AudioUtil.sfx("return")
			"excavate":
				await _move_card(int(e["uid"]), Vector2(499, 269), true)
				_show_card_detail(duel.card_by_uid(int(e["uid"])))
				fx.animation_stage.emit("excavate", "reveal")
				if fx_enabled:
					await get_tree().create_timer(0.45).timeout
				fx.animation_stage.emit("excavate", "complete")
			"shuffle_set_monsters":
				if fx_enabled:
					var shuffle_motion := create_tween().set_parallel(true)
					for item in e["positions"]:
						if views.has(int(item["uid"])):
							shuffle_motion.tween_property(views[int(item["uid"])], "position", _zone_pos(int(e["player"]), false, int(item["zone"])), 0.35)
					await shuffle_motion.finished
			"shuffle":
				if fx_enabled:
					await fx.shuffle_deck(_pile_pos("p%d_deck" % int(e["player"])) + CARD / 2, LANG_LETTER.get(lang, "e"))
			"chain":
				if int(e.get("n", 1)) > 1:
					AudioUtil.sfx("chain")
			"reveal_cards":
				await _present_reveal(e)
			"empty_search":
				await _ask(str(e["message"]), "ok")
			"coin", "coins":
				AudioUtil.sfx("coin")
				if fx_enabled:
					var outcomes: Array = e.get("outcomes", [bool(e.get("heads", false))])
					await fx.toss_coins(outcomes)
			"dice":
				AudioUtil.sfx("dice")
				if fx_enabled:
					await fx.roll_dice(int(e["roll"]))
			"attack":
				battle_visual = {"attacker": int(e["attacker"]), "target": int(e["target"]), "calculated": false, "damage_step": false, "target_destroyed": battle_deaths.has(int(e["target"]))}
				if skip_next_sword:
					skip_next_sword = false
				elif fx_enabled and views.has(e["attacker"]):
					var attacker_uid: int = int(e["attacker"])
					sword_attacker_uid = attacker_uid
					var sw: TextureRect
					if idle_swords.has(attacker_uid):
						sw = idle_swords[attacker_uid]
						idle_swords.erase(attacker_uid)
						sw.modulate.a = 1.0
					else:
						sw = _new_sword(_view_center(attacker_uid), e["player"] == 1)
					await _present_attack(int(e["attacker"]), int(e["target"]), int(e["player"]), sw)
			"damage_step":
				if not battle_visual.is_empty():
					battle_visual["damage_step"] = true
			"destroy":
				# Paired to_grave already played destruction at the former field location.
				if not events.any(func(item): return item["type"] == "to_grave" and int(item["uid"]) == int(e["uid"])):
					AudioUtil.sfx("card_normal_brake")
					if fx_enabled:
						await fx.explosion(_view_center(int(e["uid"])))
			"damage":
				AudioUtil.sfx("damage")
				await _damage_number(e["amount"], Vector2(525,140 if e["player"] == 1 else 460), false, false, int(e["player"]))
				await _animate_lp(false)
			"heal":
				AudioUtil.sfx("life_up")
				await _damage_number(e["amount"], Vector2(525,140 if e["player"] == 1 else 460), true, false, int(e["player"]))
				await _animate_lp(false)
			"win":
				if fx_enabled:
					await _animate_lp()
					await _wait_battle_numbers()
				_show_result(e["player"] == 0)

func _battle_pause(seconds: float) -> void:
	if fx_enabled and seconds > 0.0:
		await get_tree().create_timer(seconds).timeout

func _present_attack(attacker: int, target: int, player: int, sword: TextureRect) -> void:
	var actor := duel.card_by_uid(attacker)
	if actor != null:
		_show_card_detail(actor)
	var to := _view_center(target) if target >= 0 else (Vector2(HAND_CENTER_X,30) if player == 0 else Vector2(HAND_CENTER_X,570))
	fx.animation_stage.emit("attack", "flight")
	AudioUtil.sfx("attack")
	await _fly_sword(sword, to)
	await fx.burst(to)
	await _battle_pause(BATTLE_TIMING.AFTER_IMPACT_PAUSE)

func _present_damage_calculation() -> void:
	if battle_visual.is_empty() or battle_visual.get("calculated", false):
		return
	battle_visual["calculated"] = true
	if fx_enabled:
		await _battle_pause(BATTLE_TIMING.DAMAGE_STEP_DELAY)
		var target := int(battle_visual["target"])
		var defender: DCard = duel.card_by_uid(target)
		# This sweep is the surviving defender's reaction. Battle destruction has
		# already been resolved in the engine and uses its own shake/explosion.
		var surviving_view: CardView = views.get(target) if defender != null and duel.is_on_field(defender) and not battle_visual.get("target_destroyed", false) else null
		await fx.damage_calculation(surviving_view)
		if surviving_view != null:
			await _battle_pause(BATTLE_TIMING.AFTER_SURVIVAL_SHINE_PAUSE)

## Destruction at the card's field position, then the card lands in the Graveyard.
func _present_destroyed_to_grave(e: Dictionary, finished: Dictionary = {}) -> void:
	var uid := int(e["uid"])
	var reason := str(e.get("reason", ""))
	var v: CardView = views[uid]
	var old_center := _view_center(uid)
	if reason != "destroyed:battle": AudioUtil.sfx("card_normal_brake")
	var presentation := {"done": false, "grave_ready": false}
	_destroy_presentation(v, old_center, reason == "destroyed:battle", presentation)
	if reason == "destroyed:battle":
		while not presentation["grave_ready"]:
			await get_tree().process_frame
	else:
		await get_tree().create_timer(0.2).timeout
	v.texture = _texture_for(v.card, true)
	v.position = _pile_pos("p%d_grave" % int(e["player"])) + Vector2(6, 0)
	for other_uid in views:
		var other_view: CardView = views[other_uid]
		if other_uid != uid and other_view.position.is_equal_approx(v.position): other_view.hide()
	v.size = CARD
	v.rotation = 0.0
	v.show()
	var grave_pile: PileView = piles["p%d_grave" % int(e["player"])]
	grave_pile.count = mini(grave_pile.count+1,duel.side(int(e["player"])).grave.size())
	grave_pile.queue_redraw()
	while not presentation["done"]:
		await get_tree().process_frame
	finished["done"] = true

static func _is_battle_result(e: Dictionary) -> bool:
	if e["type"] in ["to_grave", "destroy"]:
		return str(e.get("reason", "")) == "destroyed:battle"
	return e["type"] == "damage" and str(e.get("reason", "")) in ["battle", "direct_attack"]

## The original's order (recorded at 60fps): damage step pause, survivor shine, damage number over the damaged
## player's battling monster, hold, LP countdown, short pause, then the destroyed monsters flash and explode.
func _present_battle_result(group: Array) -> void:
	for e in group:
		var dead: DCard = duel.card_by_uid(int(e.get("uid", -1)))
		if e["type"] != "to_grave" or dead == null or not views.has(dead.uid):
			continue
		if not stat_cache.has(dead.uid):
			# Flipped and destroyed in one action: its line was never drawn on the field.
			stat_cache[dead.uid] = {"p": int(e["player"]), "a": str(duel.atk_of(dead)), "d": str(duel.def_of(dead)), "ta": _stat_texture(dead, "atk"), "td": _stat_texture(dead, "def"), "pos": dead.pos}
		lingering_stats[dead.uid] = true
	stats_layer.queue_redraw()
	await _present_damage_calculation()
	var damages: Array = group.filter(func(item): return item["type"] == "damage")
	for e in damages:
		AudioUtil.sfx("damage")
		await _damage_number(e["amount"], _battle_number_anchor(int(e["player"])), false, fx_enabled, int(e["player"]))
	if fx_enabled and not damages.is_empty():
		await _battle_pause(BATTLE_TIMING.DAMAGE_NUMBER_HOLD)
		await _animate_lp(false)
		await _battle_pause(BATTLE_TIMING.AFTER_LP_COUNT_PAUSE)
	var running: Array = []
	for e in group:
		var uid := int(e["uid"]) if e.has("uid") else -1
		if e["type"] == "to_grave" and fx_enabled and views.has(uid):
			var finished := {"done": false}
			running.append(finished)
			_present_destroyed_to_grave(e, finished)
		elif e["type"] == "to_grave":
			await _move_card(uid, _pile_pos("p%d_grave" % int(e["player"])) + Vector2(6, 0), true)
		elif e["type"] == "destroy" and not group.any(func(item): return item["type"] == "to_grave" and int(item["uid"]) == uid):
			AudioUtil.sfx("card_normal_brake")
			if fx_enabled:
				await fx.explosion(_view_center(uid))
	for finished in running:
		while not finished["done"]:
			await get_tree().process_frame

## Battle damage numbers rise from the damaged player's battling monster (native 00414110 mode 7);
## direct attacks use the LP-side default position.
func _battle_number_anchor(player: int) -> Vector2:
	if not battle_visual.is_empty():
		for key in ["attacker", "target"]:
			var c: DCard = duel.card_by_uid(int(battle_visual[key]))
			if c != null and c.controller == player and views.has(c.uid):
				return _view_center(c.uid)
	return Vector2(525,140 if player == 1 else 460)

func _destroy_presentation(view: CardView, center: Vector2, battle: bool, completion: Dictionary) -> void:
	if view.motion != null and view.motion.is_valid():
		view.motion.kill()
	view.presenting = true
	if battle:
		# The original has no shake: the card stays visible under the growing star until the puffs.
		if BATTLE_TIMING.SHAKE_DURATION > 0.0:
			AudioUtil.sfx("damage")
			await fx.battle_shake(view)
			await _battle_pause(BATTLE_TIMING.AFTER_SHAKE_PAUSE)
		AudioUtil.sfx("card_attacked_brake")
		lingering_stats.erase(view.card.uid)
		stat_cache.erase(view.card.uid)
		stats_layer.queue_redraw()
		await fx.explosion(center, completion)
		await _battle_pause(BATTLE_TIMING.AFTER_DESTRUCTION_PAUSE)
	else:
		await fx.shatter(view)
	view.presenting = false
	completion["done"] = true

func _present_tribute(uid: int, player: int) -> void:
	var view: CardView = views.get(uid)
	if fx_enabled and view != null:
		var completion := {"ready": false, "done": false}
		if view.motion != null and view.motion.is_valid():
			view.motion.kill()
		view.presenting = true
		fx.tribute_glow(_view_center(uid), view.rotation, completion)
		while not completion["ready"]:
			await get_tree().process_frame
		# The monster disappears into its white afterimage. The real Graveyard card
		# updates here; it does not fly intact across the field in the reference.
		for other in duel.side(player).grave:
			if other.uid != uid and views.has(other.uid) and views[other.uid].position.is_equal_approx(_pile_pos("p%d_grave" % player) + Vector2(6, 0)):
				views[other.uid].hide()
		view.texture = _texture_for(view.card, true)
		view.shown_face_up = true
		view.position = _pile_pos("p%d_grave" % player) + Vector2(6, 0)
		view.size = CARD
		view.pivot_offset = CARD / 2
		view.rotation = 0.0
		view.scale = Vector2.ONE
		view.z_index = 3
		view.show()
		view.presenting = false
		var pile: PileView = piles["p%d_grave" % player]
		pile.count = duel.side(player).grave.size()
		pile.queue_redraw()
		await get_tree().create_timer(0.15).timeout
	else:
		AudioUtil.sfx("ikenie")
		await _move_card(uid, _pile_pos("p%d_grave" % player) + Vector2(6, 0), true)

func _field_key(c: DCard) -> String:
	return "" if c == null else str(FIELD_ART.get(db.card_name(c.idx, "eng"), ""))

## The board artwork follows the face-up field spell (either player's), like the original.
func _update_field_art() -> void:
	var key := ""
	for p in 2:
		var fs: DCard = duel.side(p).field_spell
		if fs != null and fs.face_up:
			key = _field_key(fs)
	var t := _tex("res://assets/ui/field_normal.png") if key == "" else _ui("field/fie_%s" % key)
	var field := get_node_or_null("Field") as TextureRect
	if field != null and t != null and field.texture != t:
		field.texture = t

func _show_result(won: bool) -> void:
	var kind := "win" if won else "lose"
	if duel.winner == 2:
		kind = "draw"
	var sprite := fx.tex("effect/duel_%s_%s" % [kind, LANG_LETTER.get(lang, "e")])
	if sprite != null and fx_enabled:
		var r := TextureRect.new()
		r.texture = sprite
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.position = Vector2(BOARD_X + (SIZE.x - BOARD_X - sprite.get_width()) / 2.0, 250)
		r.z_index = 60
		add_child(r)
	else:
		banner.text = "YOU WIN!" if won else "YOU LOSE"
		banner.add_theme_color_override("font_color", Color.GOLD if won else Color.CRIMSON)
		banner.visible = true
	AudioUtil.music("m_win" if won else "m_lose", false)

# --- hover / cursor -----------------------------------------------------------------

func _can_act() -> bool:
	return duel.winner == -1 and duel.turn_player == 0 and mode not in [Mode.AI, Mode.DISCARD] and duel.fx.pending.is_empty() and not anim_busy and modal_depth == 0

## First effect of `c` that the human can activate right now, or -1.
func _first_effect_idx(c: DCard) -> int:
	for o in duel.activatable_effects(0):
		if o["uid"] == c.uid:
			return int(o["idx"])
	return -1

## Cursor to show while hovering `c`.
func _tribute_instruction(need: int) -> String:
	return "Select %d monster%s as Tribute." % [need, "s" if need != 1 else ""]

func _hover_cursor(c: DCard) -> String:
	if _response_pick_active():
		for option in response_selection["options"]:
			if int(option["uid"]) == c.uid:
				return "act"
		return "off"
	if mode == Mode.DISCARD and modal_depth == 0 and not anim_busy:
		return "on" if duel.side(0).hand.has(c) else "off"
	if _decision_select_active():
		return "on" if (duel.fx.pending["candidates"] as Array).has(c.uid) else "off"
	if not _can_act():
		return "off"
	var s: Duel.PlayerSide = duel.side(0)
	match mode:
		Mode.ATTACK_TARGET:
			return "on" if duel.side(1).monsters.has(c) else "off"
		Mode.TRIBUTE:
			return "on" if _tribute_candidates().has(c) else "off"
		Mode.DISCARD:
			return "on" if s.hand.has(c) else "off"
	if s.hand.has(c) and duel.in_main_phase():
		if duel.is_monster(c):
			if _first_effect_idx(c) != -1 and not hand_set_pref:
				return "act"
			if duel.normal_summoned:
				return "over"
			if duel.summon_problem(0, c) != "":
				return "off"            # cannot be summoned or Set right now (no tributes, no room, restricted): no bubble
			return "set" if hand_set_pref else "summon"
		if hand_set_pref:
			return "set"
		return "act" if _first_effect_idx(c) != -1 else "set"
	if (s.spells.has(c) or s.field_spell == c) and duel.in_main_phase():
		return "act" if _first_effect_idx(c) != -1 else "off"
	if s.monsters.has(c):
		if duel.in_main_phase():
			if c.summon_turn == duel.turn or c.pos_changed or c.attacked:
				return "over"
			if not c.face_up:
				return "flip"
			return "setdef" if c.pos == "atk" else "setatk"
		if duel.phase == "battle":
			return "atk" if duel.can_attack(0, c) == "" else "over"
	return "off"

func _frame_for(c: DCard) -> Texture2D:
	var in_hand := duel.side(c.owner).hand.has(c)
	if duel.side(c.owner).deck.has(c) or duel.side(c.owner).grave.has(c):
		return null
	if mode == Mode.ATTACK_TARGET and duel.side(1).monsters.has(c):
		# The original marks the hovered attack target with pink corners (card_waku#s2).
		return _ui("card/card_waku#s2") if _hover_cursor(c) != "off" else null
	if in_hand and c.owner == 0:
		return _ui("card/card_waku#l")    # own hand cards always get the blue frame, playable or not
	if _hover_cursor(c) in ["off", "over"]:
		return null
	return _ui("card/card_waku#%s" % ["l" if in_hand else "s"])

func _on_card_enter(v: CardView) -> void:
	var c := v.card
	if hovered != c:
		hand_set_pref = false
	hovered = c
	v.show_frame(_frame_for(c))
	if mode == Mode.ATTACK_TARGET and duel.side(1).monsters.has(c):
		attack_hover = c
		stats_layer.queue_redraw()
	if c.owner == 0 or c.face_up or revealed_cards.has(c.uid) or duel.side(1).grave.has(c):
		_show_card_detail(c)
	CursorUtil.set_state(_hover_cursor(c))
	if duel.side(0).hand.has(c):
		_refresh_hand_hover()

func _on_card_exit(v: CardView) -> void:
	v.show_frame(null)
	if attack_hover == v.card:
		attack_hover = null
	if hovered == v.card:
		hovered = null
	CursorUtil.set_state("off")
	if duel.side(0).hand.has(v.card):
		_refresh_hand_hover()

## Inspecting the hand is allowed during either turn, including opponent animations.
## Move only settled hand cards so hover cannot interrupt event playback elsewhere.
func _refresh_hand_hover() -> void:
	for c in _presented_hand(0):
		var view: CardView = views.get(c.uid)
		if view == null or view.presenting or not view.visible:
			continue
		if view.motion != null and view.motion.is_valid():
			view.motion.kill()
		view.motion = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		view.motion.tween_property(view, "position", _layout(c)["pos"], MOVE_TIME)

# --- input -------------------------------------------------------------------

func _on_card_input(event: InputEvent, v: CardView) -> void:
	if modal_depth > 0 or decision_busy or anim_busy:
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var c := v.card
	if duel.winner != -1:
		left.emit()
		return
	if _response_pick_active():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_answer("pass")
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_pick_response(c)
		return
	if _decision_select_active():
		if event.button_index == MOUSE_BUTTON_LEFT:
			_decision_toggle(c)
		return
	if mode == Mode.DISCARD:
		if event.button_index == MOUSE_BUTTON_LEFT and not anim_busy and duel.side(0).hand.has(c):
			_toggle(c.uid)
			if selected.size() == duel.hand_excess(0):
				var uids := selected.duplicate()
				_cancel_mode()
				_do(duel.end_turn(0, uids))
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if mode != Mode.IDLE:
			_cancel_mode()
		elif _can_act() and duel.side(0).hand.has(c) and duel.in_main_phase():
			hand_set_pref = not hand_set_pref
			CursorUtil.set_state(_hover_cursor(c))
		elif _can_act():
			_open_phase_menu()
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not _can_act():
		return
	var s: Duel.PlayerSide = duel.side(0)
	match mode:
		Mode.TRIBUTE:
			if _tribute_candidates().has(c):
				_toggle(c.uid)
				if selected.size() == duel.tributes_required(pending_card):
					var tributes := selected.map(func(u): return cards_by_uid[u])
					var card := pending_card
					_cancel_mode()
					_do(duel.summon(0, card, tributes, -1, hand_set_pref))
		Mode.ATTACK_TARGET:
			if duel.side(1).monsters.has(c):
				var attacker := pending_card
				var sword := active_sword
				active_sword = null
				attack_hover = null
				anim_busy = true
				if fx_enabled:
					await _present_attack(attacker.uid,c.uid,0,sword)
				else:
					await _fly_sword(sword, _view_center(c.uid))
				anim_busy = false
				skip_next_sword = true
				var result := duel.attack(0, attacker, c)
				_cancel_mode()
				_do(result)
		Mode.IDLE:
			_card_action(c)

func _card_action(c: DCard) -> void:
	var s: Duel.PlayerSide = duel.side(0)
	pending_card = c
	if s.hand.has(c) and duel.in_main_phase():
		if duel.is_monster(c):
			var effect_idx: int = _first_effect_idx(c)
			if effect_idx != -1 and not hand_set_pref:
				_do(duel.activate_effect(0, c, effect_idx))
				return
			var blocked := duel.summon_problem(0, c)
			if blocked != "" and not duel.normal_summoned:
				prompt.text = blocked               # nothing to Tribute / no room: do not even start the summon
				AudioUtil.sfx("unable")
				pending_card = null
				return
			if duel.tributes_required(c) > 0 and not duel.normal_summoned:
				var need := duel.tributes_required(c)
				if fx_enabled:
					# the original asks first ("requires 1 Tribute. Do you wish to Summon?"), then tells you what to pick
					if not await _ask(_dlg_text(1 if need == 1 else 2), "yesno"):
						pending_card = null
						return
					if not await _ask(_tribute_instruction(need), "ok"):
						pending_card = null
						return
				mode = Mode.TRIBUTE
				selected.clear()
				_update_ui()
				return
			_do(duel.summon(0, c, [], -1, hand_set_pref))
		else:
			var idx := _first_effect_idx(c)
			if idx != -1 and not hand_set_pref:
				_do(duel.activate_effect(0, c, idx))
			else:
				_do(duel.set_spell_trap(0, c))
	elif (s.spells.has(c) or s.field_spell == c) and duel.in_main_phase():
		var idx2 := _first_effect_idx(c)
		if idx2 != -1:
			_do(duel.activate_effect(0, c, idx2))
	elif s.monsters.has(c):
		if duel.in_main_phase():
			_do(duel.change_position(0, c))
		elif duel.phase == "battle" and duel.can_attack(0, c) == "":
			_take_sword(c)
			if duel.monsters_of(1).is_empty() or (duel.can_attack_directly(c) and await _ask("Attack your opponent directly?", "yesno")):
				# direct attack: the sword flies straight at the opponent
				var sword := active_sword
				active_sword = null
				mode = Mode.ATTACK_TARGET
				anim_busy = true
				if fx_enabled:
					await _present_attack(c.uid,-1,0,sword)
				else:
					await _fly_sword(sword, Vector2(HAND_CENTER_X, 30))
				anim_busy = false
				skip_next_sword = true
				mode = Mode.IDLE
				_do(duel.attack(0, c, null))
			else:
				mode = Mode.ATTACK_TARGET
				_update_ui()
	CursorUtil.set_state("off")

func _on_board_input(event: InputEvent) -> void:
	if mode == Mode.DISCARD or modal_depth > 0 or decision_busy:
		return
	if event is InputEventMouseButton and event.pressed:
		if duel.winner != -1:
			left.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if mode != Mode.IDLE:
				_cancel_mode()
			elif _can_act():
				_open_phase_menu()

## Click your own deck once: the cursor turns into the "Surrender" hand. Click again: "Do you surrender ?".
func _on_own_deck_input(event: InputEvent) -> void:
	if modal_depth > 0 or decision_busy or duel.winner != -1 or not _can_act():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if deck_armed:
			deck_armed = false
			CursorUtil.set_state("off")
			_on_menu(8)
		else:
			deck_armed = true
			CursorUtil.set_state("surrender")

func _phase_click_ok(i: int) -> bool:
	if not _can_act() or mode != Mode.IDLE:
		return false
	match duel.phase:
		"main1": return (i == 3 and not (duel.no_first_turn_attack and duel.turn == 1)) or i == 5
		"battle": return i == 4 or i == 5
		"main2": return i == 5
	return false

func _on_phase_icon(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _phase_click_ok(i):
		match i:
			3: _do(duel.to_battle(0))
			4: _do(duel.to_main2(0))
			5: _confirm_end_turn()

func _toggle(uid: int) -> void:
	if selected.has(uid):
		selected.erase(uid)
	else:
		selected.append(uid)
	_update_ui()

func _cancel_mode() -> void:
	sword_attacker_uid = -1
	_close_discard_prompt()
	if active_sword != null:
		active_sword.queue_free()
		active_sword = null
	attack_hover = null
	if mode != Mode.AI:
		mode = Mode.IDLE
	selected.clear()
	pending_card = null
	_update_ui()

# Menu ids: 5 Battle, 6 Main2, 7 EndTurn, 8 Surrender
func _open_menu(items: Array) -> void:
	popup.clear()
	for it in items:
		popup.add_item(it[0], it[1])
	popup.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i(0, 0)))

func _open_phase_menu() -> void:
	match duel.phase:
		"main1": _open_menu([["Enter Battle Phase", 5], ["End Turn", 7], ["Surrender", 8]])
		"battle": _open_menu([["Proceed to Main Phase 2", 6], ["End Turn", 7], ["Surrender", 8]])
		"main2": _open_menu([["End Turn", 7], ["Surrender", 8]])

func _on_menu(id: int) -> void:
	match id:
		5: _do(duel.to_battle(0))
		6: _do(duel.to_main2(0))
		7: _confirm_end_turn()
		8:
			if await _ask(_dlg_text(6), "yesno"):
				duel.surrender(0)
				await _after_action()

func _do(result: String) -> void:
	if result != "":
		prompt.text = result
		AudioUtil.sfx("unable")
	_refresh_swords()
	await _after_action()
	_maybe_ai()

## "End your turn?" with the original's YES / NO panel (a plain dialog when animations are off, i.e. in tests).
func _confirm_end_turn() -> void:
	_try_end_turn()           # the original asks nothing when you end your turn

## Modal question in the original's style; returns the answer (always true when dialogs are off, as in tests).
func _ask(text: String, kind := "yesno", text_left := DuelDialog.TEXT_X) -> bool:
	if not fx_enabled or not is_inside_tree():
		return true
	modal_depth += 1
	var dlg := DuelDialog.new()
	dlg.setup(text, kind)
	dlg.text_x = text_left
	add_child(dlg)
	var result = await dlg.answered
	modal_depth -= 1
	return bool(result)

func _try_end_turn() -> void:
	if duel.hand_excess(0) > 0:
		mode = Mode.DISCARD
		selected.clear()
		_update_ui()
		return
	_do(duel.end_turn(0))

# --- opponent turn -------------------------------------------------------------

func _maybe_ai() -> void:
	if ai_running:
		return
	ai_running = true
	while duel.winner == -1:
		while anim_busy or is_instance_valid(pile_browser):
			await get_tree().process_frame
		var pend: Dictionary = duel.fx.pending
		if not pend.is_empty() and pend["player"] == 0:
			break                                   # waiting for the human's answer
		if pend.is_empty() and duel.turn_player != 1:
			break
		mode = Mode.AI
		_update_ui()
		# Combat response windows already follow the sword/impact presentation.
		# Repeating the normal turn-action delay here creates a silent gap before
		# damage calculation, sometimes once for each response window.
		var battle_response := not pend.is_empty() and not duel.current_attack.is_empty()
		if ai_delay > 0 and not battle_response:
			await get_tree().create_timer(ai_delay).timeout
		while modal_depth > 0 or anim_busy:
			await get_tree().process_frame
		var field_choices: Array[int] = []
		if pend.get("type", "") == "select" and not pend.get("discard", false) and not pend.get("cost", false):
			for uid in pend.get("candidates", []):
				if duel.is_on_field(duel.card_by_uid(int(uid))): field_choices.append(int(uid))
		JoeyAI.step(duel, 1)
		await _present_ai_target_choice(pend,field_choices)
		await _after_action()
	ai_running = false
	if mode == Mode.AI:
		mode = Mode.IDLE
	_update_ui()
	_check_decision()

## Observe the existing AI answer; presentation never changes its choice or rules.
func _present_ai_target_choice(pending: Dictionary, field_choices: Array[int]) -> void:
	if not fx_enabled or field_choices.is_empty() or is_same(pending,duel.fx.pending): return
	var task: Dictionary = pending.get("_task", {})
	var ctx: Dictionary = task.get("ctx", {})
	var picked: Array = ctx.get("vars", {}).get(pending.get("as", ""), [])
	anim_busy = true
	for card in picked:
		if card is DCard and field_choices.has(card.uid) and views.has(card.uid):
			await fx.selection_flash(views[card.uid])
	anim_busy = false

# --- effect decisions (chain prompts, targets, yes/no, lists) ----------------------------

func _build_decision_ui() -> void:
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings.json"))["eng"]
	decision_popup.popup_window = false
	decision_popup.exclusive = false
	decision_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_label.custom_minimum_size = Vector2(340, 0)
	decision_box.add_child(decision_label)
	decision_popup.add_child(decision_box)
	add_child(decision_popup)
	list_view.custom_minimum_size = Vector2(380, 300)
	list_view.fixed_icon_size = Vector2i(36, 52)
	list_dialog.add_child(list_view)
	list_dialog.confirmed.connect(_on_list_confirmed)
	list_dialog.canceled.connect(func(): if _human_pending() and duel.fx.pending.get("min", 1) == 0: _answer([]))
	add_child(list_dialog)
	ok_button.text = "OK"
	ok_button.position = Vector2(BOARD_X + 8, 440)
	ok_button.size = Vector2(120, 26)
	ok_button.z_index = 60
	ok_button.visible = false
	ok_button.pressed.connect(func(): _answer(decision_selected.duplicate()))
	add_child(ok_button)

func _dlg_text(id: int, card_name := "") -> String:
	if id <= 0 or id >= strings.size():
		return ""
	var t: String = strings[id]
	t = t.replace("\n", " ")
	var re := RegEx.new()
	re.compile("@[0-9]")
	t = re.sub(t, "", true)
	return t.replace("%s", card_name)

func _human_pending() -> bool:
	return not duel.fx.pending.is_empty() and duel.fx.pending["player"] == 0

func _uses_list(p: Dictionary) -> bool:
	if p.get("hidden_pick", false):
		return false
	for u in p["candidates"]:
		var c := duel.card_by_uid(u)
		if not (duel.is_on_field(c) or duel.side(0).hand.has(c)):
			return true
	return false

func _show_discard_prompt() -> void:
	if is_instance_valid(discard_dialog):
		return
	discard_dialog = DuelDialog.new()
	discard_dialog.setup(_dlg_text(235), "discard")
	add_child(discard_dialog)
	prompt.text = ""

func _close_discard_prompt() -> void:
	if is_instance_valid(discard_dialog):
		discard_dialog.hide()
		discard_dialog.queue_free()
	discard_dialog = null

func _is_hand_discard(p: Dictionary) -> bool:
	if p.get("type", "") != "select" or not p.get("discard", false):
		return false
	for uid in p.get("candidates", []):
		if not duel.side(0).hand.has(duel.card_by_uid(uid)):
			return false
	return true

func _decision_select_active() -> bool:
	return not anim_busy and modal_depth == 0 and not decision_busy and _human_pending() and duel.fx.pending["type"] == "select" and not _uses_list(duel.fx.pending)

## Chain-window question text: what just happened (the original's own announcement) + "Activate the effect of a card?".
const EVENT_STRINGS := {"summoned": 169, "flip_summoned": 171, "special_summoned": 173, "monster_set": 175, "attack_declared": 182}
const EVENT_SINGLE := {"position_changed": 178, "control_switched": 180, "equipped": 196, "returned_to_hand": 199}

func _chain_question(p: Dictionary) -> String:
	var task: Dictionary = p.get("_task", {})
	var data: Dictionary = task.get("data", {})
	var head := ""
	if p.get("event", "") == "damage_step":
		var a: DCard = duel.card_by_uid(int(data.get("attacker", -1)))
		var t: DCard = duel.card_by_uid(int(data.get("target", -1)))
		if a != null:
			var foe_value: int = 0 if t == null else (duel.atk_of(t) if t.pos == "atk" else duel.def_of(t))
			head = _dlg_text(266) % [duel.atk_of(a), foe_value] + "\n"
	elif p.get("event", "") == "target_declared":
		var tc: DCard = duel.card_by_uid(int(data.get("target", -1)))
		head = _dlg_text(177, "" if tc == null else db.card_name(tc.idx, lang)) + "\n"
	elif EVENT_SINGLE.has(p.get("event", "")):
		head = _dlg_text(EVENT_SINGLE[p["event"]]) + "\n"
	elif EVENT_STRINGS.has(p.get("event", "")):
		head = _dlg_text(EVENT_STRINGS[p["event"]] + (0 if int(data.get("player", 0)) == 0 else 1)) + "\n"
	return head + _dlg_text(269)

func _check_decision() -> void:
	if anim_busy: return
	if not _human_pending():
		response_selection = {}
		if mode != Mode.DISCARD:
			_close_discard_prompt()
		_close_order_panel()
		presented_decision = {}
		decision_popup.hide()
		ok_button.visible = false
		return
	if decision_busy or modal_depth > 0:
		return
	var p: Dictionary = duel.fx.pending
	if is_same(p, presented_decision):
		return
	presented_decision = p
	match p["type"]:
		"select":
			prompt.text = ""
			decision_selected.clear()
			if _is_hand_discard(p):
				_show_discard_prompt()
				_highlight()
				return
			_close_discard_prompt()
			var t: String = str(p.get("prompt_text", ""))
			if t == "":
				t = _dlg_text(int(p.get("prompt", 0)))
			if fx_enabled:
				decision_busy = true
				await _ask(t if t != "" else SELECT_HINT, "ok", 22.0)
				decision_busy = false
				if not _human_pending() or not is_same(p, duel.fx.pending):
					return
			if p.get("order_deck", false):
				_show_order_panel(p)
			elif _uses_list(p):
				_show_list(p)
			else:
				prompt.text = t if t != "" else SELECT_HINT
				ok_button.visible = int(p["min"]) < int(p["max"])
				_highlight()
		"yesno":
			var c := duel.card_by_uid(int(p.get("card", -1)))
			var t2: String = str(p.get("prompt_text", ""))
			if t2 == "":
				t2 = _dlg_text(int(p.get("prompt", 0)), db.card_name(c.idx, lang) if c != null else "")
			if t2 == "" and c != null:
				t2 = _dlg_text(250, db.card_name(c.idx, lang))
			if fx_enabled:
				decision_busy = true
				var yes := await _ask(t2 if t2 != "" else "Activate the effect?", "yesno")
				decision_busy = false
				_answer(yes)
			else:
				_show_buttons(t2 if t2 != "" else "Activate the effect?", [["YES", true], ["NO", false]])
		"choice":
			if p.get("catalog", false):
				_show_name_catalog(p)
				return
			var items := []
			for i in int(p["count"]):
				items.append([(p["labels"][i] if i < (p["labels"] as Array).size() else str(i + 1)), i])
			var title: String = str(p.get("prompt_text", ""))
			_show_buttons(title if title != "" else _dlg_text(int(p.get("prompt", 0))), items)
			if p.has("reveal_cards"):
				var revealed_list := ItemList.new()
				revealed_list.custom_minimum_size = Vector2(340, 220)
				revealed_list.fixed_icon_size = Vector2i(36, 52)
				for uid in p["reveal_cards"]:
					var card: DCard = duel.card_by_uid(int(uid))
					revealed_list.add_item(db.card_name(card.idx, lang), _tex(db.art_path(card.idx, true)))
				decision_box.add_child(revealed_list)
				decision_box.move_child(revealed_list, 1)
				decision_popup.reset_size()
			if p.has("reveal"):
				var revealed: DCard = duel.card_by_uid(int(p["reveal"]))
				var art := TextureRect.new()
				art.texture = _tex(db.art_path(revealed.idx, false))
				art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				art.custom_minimum_size = Vector2(190, 270)
				decision_box.add_child(art)
				decision_box.move_child(art, 1)
				decision_popup.reset_size()
			if p.has("reveal") or p.has("reveal_cards"):
				decision_popup.popup_centered()
		"chain":
			if fx_enabled:
				decision_busy = true
				var go := await _ask(_chain_question(p), "yesno")
				decision_busy = false
				if not _human_pending():
					return
				if not go:
					_answer("pass")
					return
				response_selection = p
				prompt.text = ""
				_highlight()
				return
			var items2 := []
			var top_name := ""
			if not duel.fx.chain.is_empty():
				top_name = db.card_name((duel.fx.chain.back()["card"] as DCard).idx, lang)
			for o in p["options"]:
				items2.append(["Chain: " + str(o["name"]), {"uid": o["uid"], "idx": o["idx"]}])
			items2.append(["No", "pass"])
			var head := _dlg_text(8, top_name) if top_name != "" else "Chain a card?"
			_show_buttons(head, items2)

func _show_buttons(text: String, items: Array) -> void:
	for ch in decision_box.get_children():
		if ch != decision_label:
			decision_box.remove_child(ch)
			ch.queue_free()
	decision_label.text = text
	for it in items:
		var b := Button.new()
		b.text = str(it[0])
		var value = it[1]
		b.pressed.connect(func(): _answer(value))
		b.mouse_entered.connect(func(): CursorUtil.set_state("on"))
		b.mouse_exited.connect(func(): CursorUtil.set_state("off"))
		decision_box.add_child(b)
	decision_popup.reset_size()
	decision_popup.popup(Rect2i(Vector2i(BOARD_X + 60, 250), Vector2i(360, 10)))

func _show_list(p: Dictionary) -> void:
	list_cards = (p["candidates"] as Array).map(func(u): return duel.card_by_uid(u))
	list_view.clear()
	list_view.select_mode = ItemList.SELECT_MULTI if int(p["max"]) > 1 else ItemList.SELECT_SINGLE
	for c in list_cards:
		var path := db.art_path(c.idx, true)
		var icon: Texture2D = _tex(path) if path != "" and _tex(path) != null else _tex("res://assets/ui/card_back_mini.png")
		list_view.add_item(db.card_name(c.idx, lang), icon)
	var t := _dlg_text(int(p.get("prompt", 0)))
	list_dialog.title = t if t != "" else "Select a card"
	list_dialog.get_cancel_button().visible = int(p["min"]) == 0
	list_dialog.popup_centered()

func _on_list_confirmed() -> void:
	if not _human_pending():
		return
	var p: Dictionary = duel.fx.pending
	var picks := []
	for i in list_view.get_selected_items():
		picks.append((list_cards[i] as DCard).uid)
	if picks.size() < int(p["min"]) or picks.size() > int(p["max"]):
		_show_list(p)
		return
	_answer(picks)

func _decision_toggle(c: DCard) -> void:
	if not _decision_select_active():
		return
	var p: Dictionary = duel.fx.pending
	if not (p["candidates"] as Array).has(c.uid):
		return
	if decision_selected.has(c.uid):
		decision_selected.erase(c.uid)
	else:
		decision_selected.append(c.uid)
	_highlight()
	if decision_selected.size() == int(p["max"]):
		_answer(decision_selected.duplicate())

## Send the human's answer to the engine and carry on.
func _answer(value) -> void:
	if anim_busy: return
	var flash_views: Array = []
	if fx_enabled and value is Array and duel.fx.pending.get("type", "") == "select" and not duel.fx.pending.get("discard", false):
		for uid in value:
			if views.has(int(uid)) and duel.is_on_field(duel.card_by_uid(int(uid))):
				flash_views.append(views[int(uid)])
	response_selection = {}
	prompt.text = ""
	_close_order_panel()
	_close_discard_prompt()
	presented_decision = {}
	decision_popup.hide()
	ok_button.visible = false
	if not flash_views.is_empty():
		anim_busy = true
		for view in flash_views:
			await fx.selection_flash(view)
		anim_busy = false
	var why := duel.respond(value)
	if why != "":
		prompt.text = why
	decision_selected.clear()
	await _after_action()
	_maybe_ai()


# --- field stats, swords, numbers (original-style overlays) ---------------------------------

func _process(_delta: float) -> void:
	stats_layer.queue_redraw()
	attack_ring.hide()
	# The chosen attacker's sword stays put on its monster and turns its tip toward the mouse. The anchor is the
	# monster's own (never rotated) centre, not derived from the sword, so the angle cannot feed back into itself.
	if active_sword != null and is_instance_valid(active_sword):
		var mouse := get_local_mouse_position()
		if mouse != sword_anchor:
			active_sword.rotation = (mouse - sword_anchor).angle() + PI / 2.0

## ATK / DEF under my monsters and above the opponent's, active stat white, the other dark grey (duel_fontm / _k).
func _draw_stats() -> void:
	var white := _ui("font/duel_fontm")
	if white == null:
		return
	for p in 2:
		for c in duel.monsters_of(p):
			if (not c.face_up and p != 0) or not views.has(c.uid):
				continue
			var v: CardView = views[c.uid]
			if anim_busy and not v.position.is_equal_approx(_zone_pos(p, false, duel.side(p).monsters.find(c))):
				continue
			var line := {"p": p, "a": str(duel.atk_of(c)), "d": str(duel.def_of(c)), "ta": _stat_texture(c, "atk"), "td": _stat_texture(c, "def"), "pos": c.pos}
			stat_cache[c.uid] = line
			_draw_stat_line(v, line, white)
	for uid in lingering_stats:
		var dead: CardView = views.get(uid)
		if dead != null and dead.visible and stat_cache.has(uid) and not duel.is_on_field(dead.card):
			_draw_stat_line(dead, stat_cache[uid], white)

func _draw_stat_line(v: CardView, line: Dictionary, white: Texture2D) -> void:
	var p: int = line["p"]
	var center := v.position + v.size / 2
	var half_h := (v.size.x if absf(fmod(v.rotation_degrees, 180.0)) > 45.0 else v.size.y) / 2.0
	var y := center.y + half_h + 3.0 if p == 0 else center.y - half_h - 13.0
	var a: String = line["a"]
	var d: String = line["d"]
	var total := 7.0 * (a.length() + d.length() + 1) + 8.0
	var x := center.x - total / 2.0
	_draw_glyphs(line["ta"], a, Vector2(x, y), Color.WHITE if line["pos"] == "atk" else INACTIVE)
	x += 7.0 * a.length() + 4.0
	_draw_glyphs(white, "/", Vector2(x, y))
	x += 11.0
	_draw_glyphs(line["td"], d, Vector2(x, y), Color.WHITE if line["pos"] == "def" else INACTIVE)

func _stat_texture(c: DCard, stat: String) -> Texture2D:
	var value: int = duel.atk_of(c) if stat == "atk" else duel.def_of(c)
	var base: int = int(db.card(c.idx).get(stat, 0))
	var suffix := "_b" if value > base else ("_r" if value < base else "")
	return _ui("font/duel_fontm" + suffix)

const INACTIVE := Color(0.5, 0.5, 0.55)      # the stat that does not count in the current position

func _draw_glyphs(tex: Texture2D, text: String, pos: Vector2, tint := Color.WHITE) -> void:
	var x := pos.x
	for ch in text:
		var g := "0123456789/".find(ch)
		if g >= 0:
			stats_layer.draw_texture_rect_region(tex, Rect2(x, pos.y, 7, 10), Rect2(g * 7, 0, 7, 10), tint)
		x += 7.0

func _draw_detail_icons() -> void:
	if detail_card == null:
		return
	d_icons.draw_line(Vector2(0, -2), Vector2(176, -2), Color.BLACK, 1.0)
	if not db.is_monster(detail_card.idx):
		return
	var data := db.card(detail_card.idx)
	var attr := int(data.attribute)
	var attr_icon: int = {1: 0, 2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 9}.get(attr, -1)
	var zok := _ui("card/icon_zokusei")
	var syu := _ui("card/icon_syuzoku")
	if zok != null and attr_icon >= 0:
		d_icons.draw_texture_rect_region(zok, Rect2(0, 0, 16, 16), Rect2(attr_icon * 16, 0, 16, 16))
	var kind := int(data.kind)
	if syu != null and kind >= 1 and kind <= 20:
		d_icons.draw_texture_rect_region(syu, Rect2(17, 0, 16, 16), Rect2((kind - 1) * 16, 0, 16, 16))

func _new_sword(center: Vector2, pointing_down := false) -> TextureRect:
	var s := TextureRect.new()
	s.texture = _ui("effect/atk_icon")
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.size = Vector2(35, 71)
	s.pivot_offset = s.size / 2
	s.position = center - s.size / 2
	if pointing_down:
		s.rotation = PI
	sword_layer.add_child(s)
	return s

## Translucent swords on every monster that can attack this Battle Phase.
func _refresh_swords() -> void:
	var want := {}
	var player: int = duel.turn_player
	if duel.phase == "battle" and duel.winner == -1:
		for c in duel.monsters_of(player):
			if c.uid == sword_attacker_uid or duel.current_attack.get("attacker") == c:
				continue
			if duel.can_attack(player, c, true) == "" and views.has(c.uid):
				want[c.uid] = true
	for uid in idle_swords.keys():
		if not want.has(uid):
			(idle_swords[uid] as TextureRect).queue_free()
			idle_swords.erase(uid)
	for uid in want:
		if not idle_swords.has(uid):
			var s := _new_sword(_zone_center(player, false, (duel.side(player).monsters as Array).find(cards_by_uid[uid])), player == 1)
			s.modulate.a = 0.5
			idle_swords[uid] = s

## A monster leaving the field (or changing sides) takes its idle attack sword with it.
func _drop_idle_sword(uid: int) -> void:
	if idle_swords.has(uid):
		(idle_swords[uid] as TextureRect).queue_free()
		idle_swords.erase(uid)

## The clicked attacker's sword becomes solid and follows the mouse.
func _take_sword(c: DCard) -> void:
	sword_attacker_uid = c.uid
	sword_anchor = _view_center(c.uid)
	if idle_swords.has(c.uid):
		active_sword = idle_swords[c.uid]
		idle_swords.erase(c.uid)
	else:
		active_sword = _new_sword(sword_anchor)
	active_sword.position = sword_anchor - active_sword.size / 2.0
	active_sword.modulate.a = 1.0

func _fly_sword(s: TextureRect, to: Vector2) -> void:
	if s == null:
		return
	if not fx_enabled:
		s.queue_free()
		return
	# Aim and travel together; target clicks must not wait through a turn-in-place.
	var from := s.position + s.size / 2.0
	var aim := (to - from).angle() + PI / 2.0
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "position", to - s.size / 2, BATTLE_TIMING.SWORD_FLIGHT_DURATION)
	tw.tween_property(s, "rotation", aim, BATTLE_TIMING.SWORD_FLIGHT_DURATION * 0.4)
	await tw.finished
	sword_layer.remove_child(s)
	s.queue_free()

## Floating damage / heal number in the original's big red / blue digits (font/damage00, damage01: 0-9 + -).
func _damage_number(amount: int, center: Vector2, heal: bool, blocking := false, player := -1) -> void:
	if not fx_enabled or amount <= 0: return
	if blocking:
		battle_numbers += 1
	var n := LifeNumber.new()
	n.sheet = _ui("font/damage01" if heal else "font/damage00")
	n.remaining = amount
	n.heal = heal
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.z_index = 100
	n.size = Vector2(16*n.number_text().length(),40)
	n.position = center - n.size / 2
	add_child(n)
	var state := {"node":n,"player":player,"amount":amount,"heal":heal,"blocking":blocking}
	lp_number_stage.emit(player,"entry",amount)
	var entry := create_tween()
	entry.tween_method(func(tick: float):
		n.entry_tick = tick
		n.queue_redraw(),0.0,256.0,LP_ENTRY_TIME)
	await entry.finished
	lp_number_stage.emit(player,"settled",amount)
	if player >= 0: pending_lp_visuals.append(state)
	else: await _finish_lp_visual(state)

func _finish_lp_visual(state: Dictionary) -> void:
	var n: LifeNumber = state["node"]
	var player: int = state["player"]
	var amount: int = state["amount"]
	var steps := LifeNumber.remaining_steps(amount)
	var start := int(shown_lp[player]) if player >= 0 else 0
	var direction := 1 if state["heal"] else -1
	lp_number_stage.emit(player,"count",amount)
	var counter := create_tween()
	counter.tween_method(func(progress: float):
		n.remaining = steps[mini(int(progress),steps.size()-1)]
		n.queue_redraw()
		if player >= 0:
			shown_lp[player] = maxi(0,start+direction*(amount-n.remaining))
			_update_ui(),0.0,float(steps.size()-1),(steps.size()-1)/BATTLE_TIMING.LP_COUNT_RATE)
	await counter.finished
	if state["blocking"]: battle_numbers -= 1
	remove_child(n)
	n.queue_free()
	lp_number_stage.emit(player,"complete",0)

func _wait_battle_numbers() -> void:
	while fx_enabled and battle_numbers > 0:
		await get_tree().process_frame

## Prohibition uses a searchable catalogue; answers stay ordinary choices for the existing AI.
func _show_name_catalog(p: Dictionary) -> void:
	_show_buttons(str(p.get("prompt_text", "Declare a card name.")), [])
	var search := LineEdit.new()
	search.placeholder_text = "Search card names"
	decision_box.add_child(search)
	var names := ItemList.new()
	names.custom_minimum_size = Vector2(340, 280)
	decision_box.add_child(names)
	var fill := func(query: String):
		names.clear()
		for i in int(p["count"]):
			if query.is_empty() or str(p["labels"][i]).to_lower().contains(query.to_lower()):
				var row: int = names.add_item(str(p["labels"][i]))
				names.set_item_metadata(row, i)
	fill.call("")
	search.text_changed.connect(fill)
	var declare_button := Button.new()
	declare_button.text = "Declare"
	declare_button.disabled = true
	decision_box.add_child(declare_button)
	names.item_selected.connect(func(_row): declare_button.disabled = false)
	search.text_changed.connect(func(_query): declare_button.disabled = true)
	var answer := func():
		var rows: PackedInt32Array = names.get_selected_items()
		if not rows.is_empty():
			_answer(int(names.get_item_metadata(rows[0])))
	declare_button.pressed.connect(answer)
	names.item_activated.connect(func(_row): answer.call())
	decision_popup.reset_size()
	decision_popup.popup_centered()
	search.grab_focus()


## Temporary knowledge, displayed in place without touching duel state.
func _present_reveal(e: Dictionary) -> void:
	if not e.get("public", false) and int(e.get("viewer", 0)) != 0:
		return
	_sync(false)
	for uid in e["cards"]:
		await _flip_reveal(int(uid), true)
	if fx_enabled:
		await get_tree().create_timer(float(e.get("seconds", 4.0))).timeout
	for uid in e["cards"]:
		await _flip_reveal(int(uid), false)
	_show_card_detail(null)

func _flip_reveal(uid: int, shown: bool) -> void:
	var v: CardView = views.get(uid)
	if fx_enabled and v != null:
		var close := create_tween()
		close.tween_property(v, "scale:x", 0.0, 0.08)
		await close.finished
		_set_revealed(uid, shown)
		AudioUtil.sfx("card_open")
		var open := create_tween()
		open.tween_property(v, "scale:x", 1.0, 0.08)
		await open.finished
	else:
		_set_revealed(uid, shown)

func _set_revealed(uid: int, shown: bool) -> void:
	if shown:
		revealed_cards[uid] = true
	else:
		revealed_cards.erase(uid)
	var c: DCard = duel.card_by_uid(uid)
	var v: CardView = views.get(uid)
	if c != null and v != null:
		var visible_face: bool = shown or bool(_layout(c)["face_up"])
		v.texture = _texture_for(c, visible_face)
		v.shown_face_up = visible_face

func _close_order_panel() -> void:
	if is_instance_valid(order_panel):
		remove_child(order_panel)
		order_panel.queue_free()
	order_panel = null
	order_ranks.clear()

func _show_order_panel(p: Dictionary) -> void:
	_close_order_panel()
	order_panel = Control.new()
	order_panel.position = Vector2(298, 205)
	order_panel.size = Vector2(451, 191)
	order_panel.z_index = 140
	add_child(order_panel)
	var background := TextureRect.new()
	background.texture = _tex("res://assets/j/duel/list/list_select0.png")
	background.size = order_panel.size
	var key_shader := Shader.new()
	key_shader.code = "shader_type canvas_item; void fragment() { vec4 c = texture(TEXTURE, UV); if (c.g > 0.95 && c.r < 0.05 && c.b < 0.3) { c.a = 0.0; } COLOR = c; }"
	var key_material := ShaderMaterial.new()
	key_material.shader = key_shader
	background.material = key_material
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_panel.add_child(background)
	var candidates: Array = p["candidates"]
	for i in candidates.size():
		var c: DCard = duel.card_by_uid(int(candidates[i]))
		var card_button := TextureButton.new()
		card_button.texture_normal = _texture_for(c, true)
		card_button.ignore_texture_size = true
		card_button.stretch_mode = TextureButton.STRETCH_SCALE
		card_button.position = Vector2(73 + i * 64, 60)
		card_button.size = CARD
		card_button.mouse_entered.connect(func(): _show_card_detail(c); CursorUtil.set_state("on"))
		card_button.pressed.connect(_order_pick.bind(c.uid))
		order_panel.add_child(card_button)
		var rank := DigitFont.Counter.new()
		rank.tex = _ui("chain/chain_font")
		rank.digit_w = rank.tex.get_width() / 10.0
		rank.digit_h = rank.tex.get_height()
		rank.position = card_button.position + Vector2(0, 24)
		rank.size = Vector2(50, 22)
		rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		order_panel.add_child(rank)
		order_ranks[c.uid] = rank
		var bar := ColorRect.new()
		bar.color = Color(0.1, 0.7, 0.9)
		bar.position = card_button.position - Vector2(0, 10)
		bar.size = Vector2(50, 3)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		order_panel.add_child(bar)
		var diamond := Control.new()
		diamond.position = card_button.position + Vector2(25, -9)
		diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		diamond.draw.connect(func():
			diamond.draw_colored_polygon(PackedVector2Array([Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0)]), Color(0.65, 0.38, 0.1))
			diamond.draw_polyline(PackedVector2Array([Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0), Vector2(0, -5)]), Color.BLACK))
		order_panel.add_child(diamond)
		if db.is_monster(c.idx):
			var stats := Label.new()
			stats.text = "%d/ %d" % [duel.atk_of(c), duel.def_of(c)]
			stats.position = card_button.position + Vector2(-5, 73)
			stats.add_theme_font_size_override("font_size", 10)
			stats.add_theme_color_override("font_color", Color.BLACK)
			order_panel.add_child(stats)

func _order_pick(uid: int) -> void:
	if not _human_pending() or not duel.fx.pending.get("order_deck", false):
		return
	if decision_busy or decision_selected.has(uid):
		return
	decision_selected.append(uid)
	(order_ranks[uid] as DigitFont.Counter).set_value(decision_selected.size(), 1)
	if decision_selected.size() == int(duel.fx.pending["max"]):
		if fx_enabled:
			decision_busy = true
			await get_tree().create_timer(0.45).timeout
			decision_busy = false
		_answer(decision_selected.duplicate())


## Read-only pile browser; first card is the visible top of the pile.
func _on_pile_input(event: InputEvent, player: int, kind: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_show_pile(player, kind)

func _show_pile(player: int, kind: String) -> void:
	if kind not in ["grave", "extra"] or is_instance_valid(pile_browser):
		return
	pile_player = player
	pile_kind = kind
	pile_cards = (duel.side(player).get(kind) as Array).duplicate()
	pile_cards.reverse()
	pile_page = 0
	modal_depth += 1
	pile_browser = Control.new()
	pile_browser.size = SIZE
	pile_browser.z_index = 250
	pile_browser.mouse_filter = Control.MOUSE_FILTER_STOP
	pile_browser.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			_close_pile())
	add_child(pile_browser)
	_render_pile()
	if not pile_cards.is_empty():
		_show_card_detail(pile_cards[0])

func _render_pile() -> void:
	for child in pile_browser.get_children():
		pile_browser.remove_child(child)
		child.queue_free()
	var asset := "list/list_grave%d" % pile_player if pile_kind == "grave" else "list/list_fusion%d" % pile_player
	var background := TextureRect.new()
	background.texture = _ui(asset)
	background.size = background.texture.get_size()
	background.position = Vector2(524, 300) - background.size / 2
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment() { vec4 c = texture(TEXTURE, UV); if (c.g > 0.95 && c.r < 0.05 && c.b < 0.3) { c.a = 0.0; } COLOR = c; }"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	background.material = shader_material
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pile_browser.add_child(background)
	var origin: Vector2 = background.position
	var title := Label.new()
	title.text = "%s %s" % ["Your" if pile_player == 0 else "Opponent's", "Graveyard" if pile_kind == "grave" else "Extra Deck"]
	title.position = origin + Vector2(44, 23)
	title.add_theme_color_override("font_color", Color.WHITE if pile_kind == "grave" else Color.BLACK)
	pile_browser.add_child(title)
	var first := pile_page * 5
	for i in mini(5, pile_cards.size() - first):
		var c: DCard = pile_cards[first + i]
		var card_button := TextureButton.new()
		card_button.texture_normal = _texture_for(c, true)
		card_button.ignore_texture_size = true
		card_button.stretch_mode = TextureButton.STRETCH_SCALE
		card_button.size = CARD
		card_button.position = origin + Vector2(45 + i * 64, 63)
		card_button.mouse_entered.connect(func(): _show_card_detail(c); CursorUtil.set_state("on"))
		card_button.pressed.connect(func(): _show_card_detail(c))
		pile_browser.add_child(card_button)
	var count_label := Label.new()
	count_label.text = "%d card(s) - %d / %d" % [pile_cards.size(), pile_page + 1, maxi(1, ceili(pile_cards.size() / 5.0))]
	count_label.position = origin + Vector2(100, 145)
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color.WHITE if pile_kind == "grave" else Color.BLACK)
	pile_browser.add_child(count_label)
	for direction in [-1, 1]:
		var arrow := Button.new()
		arrow.text = "<" if direction == -1 else ">"
		arrow.position = origin + Vector2(24 if direction == -1 else 355, 85)
		arrow.size = Vector2(30, 30)
		arrow.disabled = pile_page == 0 if direction == -1 else first + 5 >= pile_cards.size()
		arrow.pressed.connect(_pile_move.bind(direction))
		pile_browser.add_child(arrow)
	var close := Button.new()
	close.text = "Close"
	close.position = origin + Vector2(162, 167)
	close.size = Vector2(85, 25)
	close.pressed.connect(_close_pile)
	pile_browser.add_child(close)

func _pile_move(direction: int) -> void:
	pile_page = clampi(pile_page + direction, 0, maxi(0, ceili(pile_cards.size() / 5.0) - 1))
	_render_pile()

func _close_pile() -> void:
	if not is_instance_valid(pile_browser):
		return
	remove_child(pile_browser)
	pile_browser.queue_free()
	pile_browser = null
	pile_cards.clear()
	modal_depth -= 1
	_check_decision()


func _tribute_candidates() -> Array:
	var candidates: Array = duel.monsters_of(0).filter(func(c): return c.token not in ["Sheep Token", "Kuriboh Token"])
	if int(duel.soul_exchange.get("player", -1)) == 0:
		var borrowed: DCard = duel.card_by_uid(int(duel.soul_exchange.get("uid", -1)))
		if borrowed != null and duel.side(1).monsters.has(borrowed):
			candidates.append(borrowed)
	return candidates

## Pile browsing remains available even during selection, animations and response prompts.
func _input(event: InputEvent) -> void:
	if is_instance_valid(pile_browser):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_pile()
			get_viewport().set_input_as_handled()
		return
	if _response_pick_active() and ((event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT)):
		_answer("pass")
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT or not event.double_click:
		return
	var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	for player in 2:
		for kind in ["grave", "extra"]:
			if Rect2(_pile_pos("p%d_%s" % [player, kind]), Vector2(66, 96)).has_point(point):
				_show_pile(player, kind)
				get_viewport().set_input_as_handled()
				return


func _response_pick_active() -> bool:
	return not decision_busy and modal_depth == 0 and not anim_busy and _human_pending() and duel.fx.pending.get("type", "") == "chain" and is_same(response_selection, duel.fx.pending)

func _pick_response(c: DCard) -> void:
	var options: Array = response_selection.get("options", []).filter(func(o): return int(o["uid"]) == c.uid)
	if options.size() == 1:
		_answer({"uid": c.uid, "idx": options[0]["idx"]})
	elif options.size() > 1:
		var items := []
		for option in options:
			items.append(["Activate effect %d" % (int(option["idx"]) + 1), {"uid": c.uid, "idx": option["idx"]}])
		_show_buttons("Choose the effect to activate.", items)

## Native draw motion: ease the center, grow linearly and flip throughout the flight.
func _presented_hand(player: int) -> Array:
	return duel.side(player).hand.filter(func(card): return not pending_draws.has(card.uid))

func _draw_to_hand(card: DCard, player: int, index: int, count: int) -> void:
	var final_size := HAND_CARD if player == 0 else OPP_HAND_CARD
	var destination := _hand_pos(player,index,count,false)
	if not fx_enabled:
		await _move_card(card.uid,destination,player == 0,0.0 if player == 0 else 180.0,final_size)
		return
	var view: CardView = views.get(card.uid)
	if view == null:
		view = _make_view(card)
		views[card.uid] = view
		cards_by_uid[card.uid] = card
	if view.motion != null and view.motion.is_valid():
		view.motion.kill()
	view.presenting = true
	view.visible = true
	view.z_index = 50
	view.rotation = 0.0
	view.scale = Vector2.ONE
	var from := _pile_pos("p%d_deck" % player) + Vector2(6,0) + CARD / 2
	var to := destination + final_size / 2
	var spread: Array[Dictionary] = []
	var hand: Array = _presented_hand(player)
	for existing in hand:
		if existing.uid == card.uid or not views.has(existing.uid): continue
		var other: CardView = views[existing.uid]
		if not other.visible: continue
		if other.motion != null and other.motion.is_valid(): other.motion.kill()
		other.presenting = true
		spread.append({"view":other,"from":other.position,"to":_hand_pos(player,hand.find(existing),count,false)})
	_update_draw_frame(0.0,view,from,to,final_size,player,spread)
	var flight := create_tween()
	view.motion = flight
	flight.tween_method(_update_draw_frame.bind(view,from,to,final_size,player,spread),0.0,1.0,DRAW_TIME)
	await flight.finished
	view.presenting = false
	for item in spread:
		(item["view"] as CardView).presenting = false

func _update_draw_frame(progress: float, view: CardView, from: Vector2, to: Vector2, final_size: Vector2, player: int, spread: Array[Dictionary]) -> void:
	var travel := sin(progress * PI / 2)
	view.size = CARD.lerp(final_size,progress)
	view.pivot_offset = view.size / 2
	view.position = from.lerp(to,travel) - view.size / 2
	# Opponent cards slide into their hand without an extra turn in flight.
	view.rotation = PI if player == 1 else 0.0
	var face_up := player == 0 and progress >= 0.5
	if view.texture == null or view.shown_face_up != face_up:
		view.texture = _texture_for(view.card,face_up)
		view.shown_face_up = face_up
	view.scale.x = absf(cos(progress * PI)) if player == 0 else 1.0
	for item in spread:
		(item["view"] as CardView).position = (item["from"] as Vector2).lerp(item["to"],travel)
	draw_frame_shown.emit(view.card.uid,progress)

## Animate the event destination even when the effect has already moved the card on to another zone.
func _move_card(uid: int, destination: Vector2, face_up: bool, angle := 0.0, destination_size := CARD, duration := MOVE_TIME) -> void:
	var c: DCard = duel.card_by_uid(uid)
	if c == null:
		return
	var v: CardView = views.get(uid)
	if v == null:
		v = _make_view(c)
		views[uid] = v
		cards_by_uid[uid] = c
		v.position = _pile_pos("p%d_deck" % c.owner)
		v.size = CARD
	if v.motion != null and v.motion.is_valid():
		v.motion.kill()
	var in_flight_flip := fx_enabled and face_up != v.shown_face_up
	if not in_flight_flip:
		v.texture = _texture_for(c, face_up)
		v.shown_face_up = face_up
	v.visible = true
	v.pivot_offset = destination_size / 2
	v.z_index = 50
	if fx_enabled:
		var motion := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		v.motion = motion
		v.presenting = true
		if in_flight_flip:
			_flight_flip(v, face_up)
		motion.tween_property(v, "position", destination, duration)
		motion.tween_property(v, "size", destination_size, duration)
		motion.tween_property(v, "rotation_degrees", angle, duration)
		await motion.finished
		v.presenting = false
	else:
		v.position = destination
		v.size = destination_size
		v.rotation_degrees = angle


## Flip midway through the flight rather than exposing an opponent's card in hand.
func _flight_flip(view: CardView, face_up: bool) -> void:
	await get_tree().create_timer(0.06).timeout
	var shut := create_tween()
	shut.tween_property(view, "scale:x", 0.0, 0.07)
	await shut.finished
	view.texture = _texture_for(view.card, face_up)
	view.shown_face_up = face_up
	var open := create_tween()
	open.tween_property(view, "scale:x", 1.0, 0.1)
	await open.finished

## Native field-spell centers from 0045c280, table at 005db5e0.
func _field_spell_position(player: int) -> Vector2:
	return (Vector2(286, 353) if player == 0 else Vector2(766, 236)) - CARD / 2


func _display_flip(uid: int, duration := 0.16) -> void:
	var v: CardView = views.get(uid)
	if v == null:
		return
	if fx_enabled:
		var close := create_tween()
		close.tween_property(v, "scale:x", 0.0, duration / 2.0)
		await close.finished
	v.texture = _texture_for(v.card, true)
	v.shown_face_up = true
	AudioUtil.sfx("card_open")
	if fx_enabled:
		var open := create_tween()
		open.tween_property(v, "scale:x", 1.0, duration / 2.0)
		await open.finished

func _preview_set_cards(point: Vector2) -> void:
	for c in duel.monsters_of(0) + duel.side(0).spells:
		if c != null and not c.face_up and views.has(c.uid):
			var v: CardView = views[c.uid]
			if Rect2(Vector2.ZERO, v.size).has_point(v.get_transform().affine_inverse() * point):
				_show_card_detail(c)
				return

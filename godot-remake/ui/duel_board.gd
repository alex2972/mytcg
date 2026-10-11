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

const SIZE := Vector2(800, 600)
const BOARD_X := 230.0
const CARD := Vector2(50, 72)            # card on the field (the hover frame card_waku#s is 58x80 = 4px around it)
const HAND_CARD := Vector2(90, 131)     # human hand cards; mostly below the screen edge
const OPP_HAND_CARD := Vector2(100, 145)
const HAND_CENTER_X := 524.0             # hands are centred over the field...
const HAND_SPAN := 416.0                 # ...and spread over at most this width (6 cards overlap, like the original)
const HAND_MAX_STEP := 103.0
const COL0 := 100.0                       # board-relative x of the first column
const COLW := 78.0
const ROW_TOP := {"opp_st": 96.0, "opp_mon": 198.0, "my_mon": 306.0, "my_st": 414.0}
const MOVE_TIME := 0.28
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
var deck_armed := false          # first click on our own deck shows the Surrender hand

# detail panel parts
var d_art := TextureRect.new()
var d_name := Label.new()
var d_attr := Label.new()
var d_text := Label.new()
var d_stats := Label.new()

var tex_cache := {}
var detail_card: DCard = null
var piles := {}                 # "p0_deck" ... -> PileView
var stats_layer := Control.new()
var sword_layer := Control.new()
var idle_swords := {}           # uid -> TextureRect (translucent swords on monsters that can attack)
var active_sword: TextureRect = null
var attack_hover: DCard = null
var modal_depth := 0
var presented_decision: Dictionary = {}
var discard_dialog: DuelDialog = null
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
var decision_selected: Array = []
var ai_running := false
var fx: DuelFx
var anim_busy := false
var fx_enabled := true
var music_started := false
var strings: Array = []

func _init(card_db: CardDB, deck0: Deck, deck1: Deck, seed_value := 0, first := 0) -> void:
	db = card_db
	duel = Duel.create(db, deck0, deck1, seed_value, first)
	duel.no_first_turn_attack = true
	custom_minimum_size = SIZE
	size = SIZE

func _ready() -> void:
	fx_enabled = ai_delay > 0.0
	duel.fx.presentation_enabled = fx_enabled
	_build()
	AudioUtil.music("m_duel%d" % (1 + duel.rng.randi() % 3))
	AudioUtil.sfx("start")
	_after_action()
	_maybe_ai()

# --- construction -------------------------------------------------------------

func _tex(path: String) -> Texture2D:
	if not tex_cache.has(path):
		tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[path]

func _ui(rel: String) -> Texture2D:
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
	d_name = _label(hud, Vector2(7, 361), Vector2(180, 18), 12, Color(0.08, 0.04, 0.0))
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
	d_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d_icons.draw.connect(_draw_detail_icons)
	hud.add_child(d_icons)
	d_stats = _label(hud, Vector2(42, 509), Vector2(150, 16), 10, Color(0.1, 0.05, 0.0))
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
			draw_texture_rect(top, Rect2(6, 0, CARD.x, CARD.y), false)
		var small: Texture2D = board._ui("font/duel_fonts")
		if small != null and kind != "grave":
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
	var x := HAND_CENTER_X - total / 2 + step * i
	if p == 0:
		return Vector2(x, 466 if raised else 530)
	return Vector2(x, -75)

# --- view sync ---------------------------------------------------------------

class CardView:
	extends TextureRect
	var card: DCard
	var shown_face_up := false
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
		var raised := human and hovered == c and mode in [Mode.IDLE, Mode.DISCARD]
		return {"pos": _hand_pos(c.owner, i, s.hand.size(), raised), "size": HAND_CARD if human else OPP_HAND_CARD,
			"face_up": human, "rot": 0.0 if human else 180.0, "visible": true, "z": 20 + i}
	i = (s.monsters as Array).find(c)
	if i != -1:
		return {"pos": _zone_pos(c.owner, false, i), "size": CARD, "face_up": c.face_up,
			"rot": (90.0 if c.pos == "def" else 0.0) + (0.0 if human else 180.0), "visible": true, "z": 5}
	i = (s.spells as Array).find(c)
	if i != -1:
		return {"pos": _zone_pos(c.owner, true, i), "size": CARD, "face_up": c.face_up, "rot": 0.0 if human else 180.0, "visible": true, "z": 5}
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
		if cc != null and cc.token != "" and not alive.has(uid):
			(views[uid] as Node).queue_free()
			views.erase(uid)
	for c in _all_cards():
		cards_by_uid[c.uid] = c
		var v: CardView = views.get(c.uid)
		var lay := _layout(c)
		if v == null:
			v = _make_view(c)
			views[c.uid] = v
			v.size = lay["size"]
			v.position = _pile_pos("p%d_deck" % c.owner)
		var face: bool = lay["face_up"]
		if v.shown_face_up != face or v.texture == null:
			v.texture = _texture_for(c, face)
			v.shown_face_up = face
		v.visible = lay["visible"]
		v.z_index = lay["z"]
		var sz: Vector2 = lay["size"]
		v.pivot_offset = sz / 2
		if animate and v.visible:
			var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(v, "position", lay["pos"], MOVE_TIME)
			tw.tween_property(v, "size", sz, MOVE_TIME)
			tw.tween_property(v, "rotation_degrees", lay["rot"], MOVE_TIME)
		else:
			v.position = lay["pos"]
			v.size = sz
			v.rotation_degrees = lay["rot"]
	_highlight()

func _set_phase_icons() -> void:
	var cur := PHASE_IDS.find(duel.phase)
	var red := duel.turn_player == 1
	for i in 6:
		var sheet := _ui("phase/pha_s_%s" % PHASE_KEYS[i])
		if sheet == null:
			continue
		var active := i == cur or (i == phase_hover and _phase_click_ok(i))
		phase_icons[i].texture = _atlas(sheet, Rect2(40 if active else 0, (75 if red else 0) + 4, 30, 52))

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
	var pick := []
	match mode:
		Mode.TRIBUTE: pick = duel.monsters_of(0)
		Mode.ATTACK_TARGET: pick = duel.monsters_of(1)
		Mode.DISCARD: pick = duel.side(0).hand
	for c in pick:
		if views.has(c.uid):
			(views[c.uid] as CardView).modulate = Color(1, 1, 0.55)
	if _decision_select_active():
		for u in duel.fx.pending["candidates"]:
			if views.has(u):
				(views[u] as CardView).modulate = Color(1, 1, 0.55)
		for u in decision_selected:
			if views.has(u):
				(views[u] as CardView).modulate = Color(0.55, 1, 0.55)
	for uid in selected:
		if views.has(uid):
			(views[uid] as CardView).modulate = Color(0.55, 1, 0.55)

# --- detail panel ---------------------------------------------------------------

func _show_card_detail(c: DCard) -> void:
	if c == null or (c.owner == 1 and not c.face_up and not duel.side(1).grave.has(c)):
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

func _animate_lp() -> void:
	for p in 2:
		var target: int = duel.side(p).lp
		if shown_lp[p] != target:
			var tw := create_tween()
			tw.tween_method(func(v): shown_lp[p] = int(v); _update_ui(), float(shown_lp[p]), float(target), 0.5)

## Run after every engine action: play the animations for what happened, then refresh the board.
func _after_action() -> void:
	if anim_busy:
		return
	anim_busy = true
	while true:
		await _play_events(duel.drain_events())
		if duel.fx.pending.get("type", "") != "presentation":
			break
		duel.respond(true)
	_sync(true)
	_animate_lp()
	_update_ui()
	anim_busy = false
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
	for e in events:
		match e["type"]:
			"turn":
				AudioUtil.sfx("turn_change")
				if fx_enabled and e["turn"] > 1:
					fx.turn_banner(e["player"] == 0)
			"phase":
				if e["phase"] == "battle":
					AudioUtil.sfx("battle_turn")
				if fx_enabled:
					fx.phase_banner(e["phase"], e["player"] == 0)
			"draw":
				AudioUtil.sfx("card_move")
			"summon", "set_monster":
				AudioUtil.sfx("card_move")
				if fx_enabled:
					fx.sparkle(_zone_center(e["player"], false, e["zone"]))
					await get_tree().create_timer(0.2).timeout
			"set_spell":
				AudioUtil.sfx("card_move")
			"activate_spell", "field_spell":
				AudioUtil.sfx("magic_active")
				if e["type"] == "field_spell" and fx_enabled:
					var key := _field_key(duel.card_by_uid(int(e["uid"])))
					if key != "":
						fx.banner(["field/fie_%s_f%s" % [key, LANG_LETTER.get(lang, "e")]], 0.0, 0.9)
				if fx_enabled:
					await get_tree().create_timer(0.25).timeout
			"special_summon":
				AudioUtil.sfx("reborn")
				if fx_enabled:
					fx.sparkle(_zone_center(e["player"], false, e["zone"]))
					await get_tree().create_timer(0.25).timeout
			"tribute":
				AudioUtil.sfx("ikenie")
			"flip", "flip_summon":
				AudioUtil.sfx("card_open")
			"change_position":
				AudioUtil.sfx("card_move")
			"equip":
				AudioUtil.sfx("equip")
			"to_hand", "to_deck":
				AudioUtil.sfx("return")
			"chain":
				AudioUtil.sfx("chain")
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
				AudioUtil.sfx("attack")
				var to := _view_center(e["target"]) if e["target"] != -1 else (Vector2(HAND_CENTER_X, 30) if e["player"] == 0 else Vector2(HAND_CENTER_X, 570))
				if skip_next_sword:
					skip_next_sword = false
					fx.burst(to)
				elif fx_enabled and views.has(e["attacker"]):
					var sw := _new_sword(_view_center(e["attacker"]), e["player"] == 1)
					await _fly_sword(sw, to)
					fx.burst(to)
			"destroy":
				AudioUtil.sfx("card_normal_brake" if str(e.get("reason", "")).contains("effect") else "card_attacked_brake")
				if fx_enabled:
					fx.explosion(_view_center(e["uid"]))
					await get_tree().create_timer(0.35).timeout
			"damage":
				AudioUtil.sfx("damage")
				_damage_number(e["amount"], Vector2(HAND_CENTER_X, 230 if e["player"] == 1 else 360), false)
				if fx_enabled:
					await get_tree().create_timer(0.25).timeout
			"heal":
				AudioUtil.sfx("life_up")
				_damage_number(e["amount"], Vector2(HAND_CENTER_X, 230 if e["player"] == 1 else 360), true)
			"win":
				_show_result(e["player"] == 0)

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
	AudioUtil.music("m_win" if won else "m_lose")

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
func _hover_cursor(c: DCard) -> String:
	if mode == Mode.DISCARD and modal_depth == 0 and not anim_busy:
		return "on" if duel.side(0).hand.has(c) else "off"
	if _decision_select_active():
		return "act" if (duel.fx.pending["candidates"] as Array).has(c.uid) else "off"
	if not _can_act():
		return "off"
	var s: Duel.PlayerSide = duel.side(0)
	match mode:
		Mode.ATTACK_TARGET:
			return "atk" if duel.side(1).monsters.has(c) else "off"
		Mode.TRIBUTE:
			return "act" if s.monsters.has(c) else "off"
		Mode.DISCARD:
			return "on" if s.hand.has(c) else "off"
	if s.hand.has(c) and duel.in_main_phase():
		if duel.is_monster(c):
			if _first_effect_idx(c) != -1 and not hand_set_pref:
				return "act"
			if duel.normal_summoned:
				return "over"
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
	var mine := c.controller == 0 if not in_hand else c.owner == 0
	return _ui("card/card_waku#%s%s" % ["l" if in_hand else "s", "" if mine else "2"])

func _on_card_enter(v: CardView) -> void:
	var c := v.card
	hovered = c
	v.show_frame(_frame_for(c))
	if mode == Mode.ATTACK_TARGET and duel.side(1).monsters.has(c):
		attack_hover = c
		stats_layer.queue_redraw()
	if c.owner == 0 or c.face_up or duel.side(1).grave.has(c):
		_show_card_detail(c)
	CursorUtil.set_state(_hover_cursor(c))
	if duel.side(0).hand.has(c) and mode in [Mode.IDLE, Mode.DISCARD]:
		_sync(true)

func _on_card_exit(v: CardView) -> void:
	v.show_frame(null)
	if attack_hover == v.card:
		attack_hover = null
	if hovered == v.card:
		hovered = null
	CursorUtil.set_state("off")
	if duel.side(0).hand.has(v.card):
		_sync(true)

# --- input -------------------------------------------------------------------

func _on_card_input(event: InputEvent, v: CardView) -> void:
	if modal_depth > 0 or decision_busy:
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var c := v.card
	if duel.winner != -1:
		left.emit()
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
			if s.monsters.has(c):
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
				mode = Mode.IDLE
				attack_hover = null
				anim_busy = true
				await _fly_sword(sword, _view_center(c.uid))
				anim_busy = false
				skip_next_sword = true
				_cancel_mode()
				_do(duel.attack(0, attacker, c))
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
			if duel.tributes_required(c) > 0 and not duel.normal_summoned:
				var need := duel.tributes_required(c)
				if fx_enabled:
					# the original asks first ("requires 1 Tribute. Do you wish to Summon?"), then tells you what to pick
					if not await _ask(_dlg_text(1 if need == 1 else 2), "yesno"):
						pending_card = null
						return
					await _ask(_dlg_text(5 if need == 1 else 3), "ok")
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
				anim_busy = true
				await _fly_sword(sword, Vector2(HAND_CENTER_X, 30))
				anim_busy = false
				skip_next_sword = true
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
	await _after_action()
	_maybe_ai()

## "End your turn?" with the original's YES / NO panel (a plain dialog when animations are off, i.e. in tests).
func _confirm_end_turn() -> void:
	_try_end_turn()           # the original asks nothing when you end your turn

## Modal question in the original's style; returns the answer (always true when dialogs are off, as in tests).
func _ask(text: String, kind := "yesno") -> bool:
	if not fx_enabled or not is_inside_tree():
		return true
	modal_depth += 1
	var dlg := DuelDialog.new()
	dlg.setup(text, kind)
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
		var pend: Dictionary = duel.fx.pending
		if not pend.is_empty() and pend["player"] == 0:
			break                                   # waiting for the human's answer
		if pend.is_empty() and duel.turn_player != 1:
			break
		mode = Mode.AI
		_update_ui()
		if ai_delay > 0:
			await get_tree().create_timer(ai_delay).timeout
		JoeyAI.step(duel, 1)
		await _after_action()
	ai_running = false
	if mode == Mode.AI:
		mode = Mode.IDLE
	_update_ui()
	_check_decision()

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
	return modal_depth == 0 and not decision_busy and _human_pending() and duel.fx.pending["type"] == "select" and not _uses_list(duel.fx.pending)

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
	if not _human_pending():
		if mode != Mode.DISCARD:
			_close_discard_prompt()
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
				await _ask(t if t != "" else SELECT_HINT, "ok")
				decision_busy = false
				if not _human_pending() or not is_same(p, duel.fx.pending):
					return
			if _uses_list(p):
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
				if (p["options"] as Array).size() == 1:
					var only: Dictionary = p["options"][0]
					_answer({"uid": only["uid"], "idx": only["idx"]})
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
	_close_discard_prompt()
	presented_decision = {}
	decision_popup.hide()
	ok_button.visible = false
	var why := duel.respond(value)
	if why != "":
		prompt.text = why
	decision_selected.clear()
	await _after_action()
	_maybe_ai()


# --- field stats, swords, numbers (original-style overlays) ---------------------------------

func _process(_delta: float) -> void:
	stats_layer.queue_redraw()
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
	if attack_hover != null and views.has(attack_hover.uid):
		var tc := _view_center(attack_hover.uid)
		stats_layer.draw_circle(tc, 46, Color(1, 0.95, 0.3, 0.28))
		stats_layer.draw_circle(tc, 34, Color(1, 0.95, 0.4, 0.25))
	for p in 2:
		for c in duel.monsters_of(p):
			if (not c.face_up and p != 0) or not views.has(c.uid):
				continue
			var v: CardView = views[c.uid]
			var center := v.position + v.size / 2
			var half_h := (v.size.x if absf(fmod(v.rotation_degrees, 180.0)) > 45.0 else v.size.y) / 2.0
			var y := center.y + half_h + 3.0 if p == 0 else center.y - half_h - 13.0
			var a := str(duel.atk_of(c))
			var d := str(duel.def_of(c))
			var total := 7.0 * (a.length() + d.length() + 1) + 8.0
			var x := center.x - total / 2.0
			_draw_glyphs(white, a, Vector2(x, y), Color.WHITE if c.pos == "atk" else INACTIVE)
			x += 7.0 * a.length() + 4.0
			_draw_glyphs(white, "/", Vector2(x, y))
			x += 11.0
			_draw_glyphs(white, d, Vector2(x, y), Color.WHITE if c.pos == "def" else INACTIVE)

const INACTIVE := Color(0.5, 0.5, 0.55)      # the stat that does not count in the current position

func _draw_glyphs(tex: Texture2D, text: String, pos: Vector2, tint := Color.WHITE) -> void:
	var x := pos.x
	for ch in text:
		var g := "0123456789/".find(ch)
		if g >= 0:
			stats_layer.draw_texture_rect_region(tex, Rect2(x, pos.y, 7, 10), Rect2(g * 7, 0, 7, 10), tint)
		x += 7.0

func _draw_detail_icons() -> void:
	if detail_card == null or not db.is_monster(detail_card.idx):
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
	if duel.phase == "battle" and duel.turn_player == 0 and duel.winner == -1 and mode == Mode.IDLE and duel.fx.pending.is_empty():
		for c in duel.monsters_of(0):
			if duel.can_attack(0, c) == "" and views.has(c.uid):
				want[c.uid] = true
	for uid in idle_swords.keys():
		if not want.has(uid):
			(idle_swords[uid] as TextureRect).queue_free()
			idle_swords.erase(uid)
	for uid in want:
		if not idle_swords.has(uid):
			var s := _new_sword(_zone_center(0, false, (duel.side(0).monsters as Array).find(cards_by_uid[uid])))
			s.modulate.a = 0.5
			idle_swords[uid] = s

## The clicked attacker's sword becomes solid and follows the mouse.
func _take_sword(c: DCard) -> void:
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
	# turn the tip exactly onto the target, then lunge forward until it hits and disappears
	var from := s.position + s.size / 2.0
	var aim := (to - from).angle() + PI / 2.0
	var turn := create_tween()
	turn.tween_property(s, "rotation", aim, 0.1)
	await turn.finished
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(s, "position", to - s.size / 2, 0.26)
	await tw.finished
	s.queue_free()

## Floating damage / heal number in the original's big red / blue digits (font/damage00, damage01: 0-9 + -).
func _damage_number(amount: int, center: Vector2, heal: bool) -> void:
	var tex := _ui("font/damage01" if heal else "font/damage00")
	var n := Control.new()
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.z_index = 100
	var text := ("+" if heal else "-") + str(amount)
	n.size = Vector2(16 * text.length(), 40)
	n.position = center - n.size / 2
	n.draw.connect(func():
		var x := 0.0
		for ch in text:
			var g := "0123456789+-".find(ch)
			if g >= 0 and tex != null:
				n.draw_texture_rect_region(tex, Rect2(x, 0, 16, 40), Rect2(g * 16, 0, 16, 40))
			x += 16.0)
	add_child(n)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(n, "position:y", n.position.y - 50, 1.0)
	tw.tween_property(n, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tw.chain().tween_callback(n.queue_free)

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
	var confirm := Button.new()
	confirm.text = "Declare"
	confirm.disabled = true
	decision_box.add_child(confirm)
	names.item_selected.connect(func(_row): confirm.disabled = false)
	search.text_changed.connect(func(_query): confirm.disabled = true)
	var answer := func():
		var rows: PackedInt32Array = names.get_selected_items()
		if not rows.is_empty():
			_answer(int(names.get_item_metadata(rows[0])))
	confirm.pressed.connect(answer)
	names.item_activated.connect(func(_row): answer.call())
	decision_popup.reset_size()
	decision_popup.popup_centered()
	search.grab_focus()

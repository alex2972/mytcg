extends Control
## Pick two decks and start a duel against the placeholder opponent.

var db: CardDB
var presets := {}
var mine: OptionButton
var theirs: OptionButton
var form: VBoxContainer
var board: DuelBoard
var last_refusal := ""            # message of the last refused duel start (the 40-card rule)

func _ready() -> void:
	db = CardDB.load_default()
	presets = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	form = VBoxContainer.new()
	form.set_anchors_preset(Control.PRESET_CENTER)
	form.custom_minimum_size = Vector2(320, 0)
	form.position = Vector2(60, 60)
	add_child(form)
	var title := Label.new()
	title.text = "Duel"
	title.add_theme_font_size_override("font_size", 28)
	form.add_child(title)
	form.add_child(_label("Your deck"))
	mine = OptionButton.new()
	mine.add_item("My saved deck")
	for k in presets.keys():
		mine.add_item(k)
	form.add_child(mine)
	form.add_child(_label("Opponent's deck"))
	theirs = OptionButton.new()
	for k in presets.keys():
		theirs.add_item(k)
	form.add_child(theirs)
	var go := Button.new()
	go.text = "Start duel"
	go.pressed.connect(start)
	form.add_child(go)
	# Too few cards to ever make a 40-card deck: point the player to the shop.
	var cards := Collection.load_default(db)
	if not cards.can_build_deck():
		DuelDialog.notice(self, DuelDialog.SHOP_NOTICE)

func _label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l

func _deck_from_preset(preset_name: String) -> Deck:
	var p: Dictionary = presets[preset_name]
	var d := Deck.new()
	d.main = p["main"].map(func(x): return int(x))
	d.extra = p["extra"].map(func(x): return int(x))
	d.side = p["side"].map(func(x): return int(x))
	return d

## Why the player's deck may not play, or "" when it can. Only the 40-card minimum is enforced here: the original's own
## CPU decks use cards from the forbidden list, so the full DeckRules check would block them.
func deck_problem(deck: Deck) -> String:
	if deck.main.size() < DeckRules.MIN_MAIN:
		return "Your deck has %d cards.
A deck needs at least %d cards to duel." % [deck.main.size(), DeckRules.MIN_MAIN]
	return ""

func start(seed_value := -1, deck_a := "", deck_b := "", skip_janken := false) -> void:
	var a: Deck = Deck.load_working(db) if mine.selected == 0 else _deck_from_preset(mine.get_item_text(mine.selected))
	var b: Deck = _deck_from_preset(theirs.get_item_text(theirs.selected))
	if deck_a != "":
		a = _deck_from_preset(deck_a)
	if deck_b != "":
		b = _deck_from_preset(deck_b)
	var problem := deck_problem(a)
	if problem != "":
		# The 40-card minimum is enforced here: no duel starts with an illegal deck.
		if not Collection.load_default(db).can_build_deck():
			problem = DuelDialog.SHOP_NOTICE
		AudioUtil.sfx("unable")
		last_refusal = problem
		DuelDialog.notice(self, problem)
		return
	form.visible = false
	var seed_used := randi() if seed_value < 0 else seed_value
	if skip_janken:
		_start_board(a, b, seed_used, true)
		return
	AudioUtil.music("m_jyank")
	var janken := JankenScreen.new(seed_used)
	add_child(janken)
	janken.finished.connect(func(human_first: bool):
		# Render the outgoing scene separately: the live cursor stays above the wipe.
		var source := SubViewport.new()
		source.size = Vector2i(800,600)
		source.disable_3d = true
		source.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(source)
		janken.reparent(source)
		janken.position = Vector2.ZERO
		_start_board(a, b, seed_used, human_first, source))

var match_mode := false             # opened from "Match Duel": the board plays m_duel1 for the first game

func _start_board(a: Deck, b: Deck, seed_used: int, human_first: bool, opening_source: SubViewport = null) -> void:
	board = DuelBoard.new(db, a, b, seed_used, 0 if human_first else 1)
	board.opening_source = opening_source
	board.match_game = 1 if match_mode else 0
	board.position = Vector2.ZERO
	add_child(board)
	board.left.connect(func():
		board.queue_free()
		form.visible = true)

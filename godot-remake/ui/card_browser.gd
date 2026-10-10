extends Control
## Card browser: search/filter every card, see art, stats and text in any language.

var db: CardDB
var lang := "eng"
var type_filter := ""
var list: ItemList
var search_box: LineEdit
var detail := CardDetail.new()
var shown: Array = []

func _ready() -> void:
	db = CardDB.load_default()
	detail.db = db
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 380
	root.add_child(left)
	var bar := HBoxContainer.new()
	left.add_child(bar)
	search_box = LineEdit.new()
	search_box.placeholder_text = "Search name or text..."
	search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_box.text_changed.connect(func(_t): _refresh())
	bar.add_child(search_box)
	var types := OptionButton.new()
	for t in ["All", "Monster", "Spell", "Trap"]:
		types.add_item(t)
	types.item_selected.connect(func(i): type_filter = "" if i == 0 else types.get_item_text(i).to_lower(); _refresh())
	bar.add_child(types)
	var langs := OptionButton.new()
	for l in CardDB.LANGS:
		langs.add_item(l)
	langs.item_selected.connect(func(i): lang = CardDB.LANGS[i]; _refresh())
	bar.add_child(langs)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(func(row): detail.show_card(shown[row], lang))
	left.add_child(list)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(detail)

func _refresh() -> void:
	shown = db.search(search_box.text, type_filter, lang)
	list.clear()
	for i in shown:
		list.add_item("%04d  %s" % [i, db.card_name(i, lang)])
	if shown.size() > 0:
		list.select(0)
		detail.show_card(shown[0], lang)

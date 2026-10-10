class_name CardDetail
extends VBoxContainer
## Shared card panel: art + stats + description.

var db: CardDB
var art := TextureRect.new()
var info := RichTextLabel.new()

func _init() -> void:
	art.custom_minimum_size = Vector2(200, 290)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(art)
	info.bbcode_enabled = true
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(info)

func show_card(i: int, lang: String) -> void:
	var c := db.card(i)
	var p := db.art_path(i)
	art.texture = load(p) if p != "" and ResourceLoader.exists(p) else null
	var s := "[b]%s[/b]\n%s   (card #%d, no. %d, internal %d)\n" % [db.card_name(i, lang), db.kind_label(i), i, c.get("number", 0), c.get("intid", 0)]
	if db.is_monster(i):
		s += "%s  Level %d  Type %d\nATK %d / DEF %d\n" % [CardDB.ATTRIBUTES.get(int(c.attribute), "?"), c.level, c.kind, c.atk, c.def]
	info.text = s + "\n" + db.card_desc(i, lang)

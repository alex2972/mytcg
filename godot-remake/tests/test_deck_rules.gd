extends SceneTree

func _init() -> void:
	var db := CardDB.load_default()
	var fails := 0
	var d := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	if DeckRules.problems(d, db).is_empty(): fails += 1; print("FAIL old fixture contains now-forbidden Change of Heart")
	var legal := Deck.new()
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "" or DeckRules.belongs_in_extra(db, i): continue
		for copy in DeckRules.copy_limit(db, i):
			if legal.main.size() < 40: legal.main.append(i)
		if legal.main.size() == 40: break
	if not DeckRules.problems(legal, db).is_empty(): fails += 1; print("FAIL legal 40-card deck rejected")
	var forbidden := ["Change of Heart", "Delinquent Duo", "Harpie's Feather Duster", "Painful Choice", "Raigeki", "Cyber Jar", "Imperial Order"]
	var limited := ["Card Destruction", "Confiscation", "Dark Hole", "Graceful Charity", "Heavy Storm", "Mage Power", "Monster Reborn", "Pot of Greed", "Premature Burial", "Snatch Steal", "Swords of Revealing Light", "The Forceful Sentry", "United We Stand", "Upstart Goblin", "Jinzo", "Witch of the Black Forest", "Sangan", "Exodia the Forbidden One", "Sinister Serpent", "Call of the Haunted", "Ceasefire", "Magic Cylinder", "Mirror Force", "Ring of Destruction"]
	var semi := ["Nobleman of Crossout", "Morphing Jar", "Morphing Jar #2"]
	for group in [forbidden, limited, semi]:
		var limit := 0 if group == forbidden else (1 if group == limited else 2)
		for card_name in group:
			var matches := db.search(card_name).filter(func(i): return db.card_name(i).to_lower() == card_name.to_lower())
			if matches.is_empty(): fails += 1; print("FAIL unknown restriction name: ", card_name); continue
			var card: int = matches[0]
			if DeckRules.copy_limit(db, card) != limit: fails += 1; print("FAIL wrong limit: ", card_name)
			var copies := Deck.new()
			for copy in limit:
				if DeckRules.add(copies, db, card, "side" if copy == 1 else "main") != "": fails += 1; print("FAIL allowed copy rejected: ", card_name)
			if DeckRules.add(copies, db, card) == "": fails += 1; print("FAIL excess copy allowed: ", card_name)
	var e := Deck.new()
	if DeckRules.problems(e, db).is_empty(): fails += 1; print("FAIL empty deck must be invalid")
	var starfish: int = db.search("armored starfish")[0]
	for k in 3: DeckRules.add(e, db, starfish)
	if DeckRules.add(e, db, starfish) == "": fails += 1; print("FAIL 4th copy allowed")
	# The limit is shared by name: alternate-art versions and "treated as" cards count together.
	var versions := []
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Kuriboh" and db.is_monster(i) and int(db.card(i).get("number", 0)) < 2000 + 1000: versions.append(i)
	var kur := Deck.new()
	for v in versions:
		for k in 3: DeckRules.add(kur, db, v)
	if kur.main.size() != 3 or versions.size() < 2: fails += 1; print("FAIL alternate-art Kuriboh must share one 3-copy limit: ", kur.main.size())
	var harpie: int = -1
	var cyber: int = -1
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Harpie Lady" and harpie < 0: harpie = i
		if db.card_name(i) == "Cyber Harpie" and cyber < 0: cyber = i
	var hd := Deck.new()
	for k in 2: DeckRules.add(hd, db, harpie)
	if DeckRules.add(hd, db, cyber) != "": fails += 1; print("FAIL 3rd Harpie-Lady-group card refused")
	if DeckRules.add(hd, db, cyber) == "": fails += 1; print("FAIL Cyber Harpie must count as Harpie Lady for the limit")
	if DeckRules.add(hd, db, harpie) == "": fails += 1; print("FAIL Harpie Lady must count Cyber Harpie")
	var fusion: int = db.search("aqua dragon")[0]
	DeckRules.add(e, db, fusion)
	if e.extra.size() != 1 or e.main.size() != 3: fails += 1; print("FAIL fusion routing")
	if DeckRules.add(e, db, fusion, "main") == "": fails += 1; print("FAIL fusion in main")
	var decks = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var bad := 0
	for k in decks:
		var p: Dictionary = decks[k]
		if p["main"].size() < 40 and not k.begins_with("ful_"): bad += 1
	print("presets with <40 main (info): ", bad, " of ", decks.size())
	print("deck rules tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

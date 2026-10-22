extends SceneTree
## Which music plays when: furi/yuri thresholds and the Match Duel themes.

var fails := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func _init() -> void:
	check(MusicMood.mood(8000, 8000) == "normal", "even duel is normal")
	check(MusicMood.mood(2900, 4500) == "losing", "me 2900 vs 4500 (gap 1600) is losing")
	check(MusicMood.mood(2900, 4400) == "normal", "a gap of exactly 1500 is not enough")
	check(MusicMood.mood(3000, 8000) == "normal", "3000 LP is not under 3000")
	check(MusicMood.mood(2000, 8000) == "losing", "2000 vs 8000 is losing")
	check(MusicMood.mood(8000, 2999) == "winning", "opponent under 3000 and I lead by more than 1500 is winning")
	check(MusicMood.mood(4000, 2500) == "normal", "a lead of exactly 1500 is not enough")
	check(MusicMood.track("losing", 2, 0) == "m_furi" and MusicMood.track("winning", 2, 0) == "m_yuri", "furi when losing, yuri when winning")
	check(MusicMood.track("normal", 1, 0) == "m_duel1" and MusicMood.track("normal", 2, 0) == "m_duel2" and MusicMood.track("normal", 3, 0) == "m_duel3", "Match Duel games use m_duel1..3")
	check(MusicMood.track("normal", 0, 4) in ["m_duel1", "m_duel2", "m_duel3"], "single duels use a duel theme")
	for f in ["m_menu", "m_jyank", "m_kaban", "m_win", "m_lose", "m_furi", "m_yuri", "m_get", "m_duel1", "m_duel2", "m_duel3"]:
		check(ResourceLoader.exists("res://assets/audio/music/%s.ogg" % f), "music file %s exists" % f)
	print("music tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

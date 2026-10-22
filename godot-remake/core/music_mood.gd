class_name MusicMood
extends RefCounted
## Which music the duel should play: the series theme normally, "furi" when the player is losing badly, "yuri" when winning.
## losing  = my LP under 3000 and the opponent has more than 1500 LP over me
## winning = the opponent's LP under 3000 and I have more than 1500 LP over them

const LOW_LP := 3000
const LEAD := 1500

static func mood(my_lp: int, foe_lp: int) -> String:
	if my_lp < LOW_LP and foe_lp - my_lp > LEAD:
		return "losing"
	if foe_lp < LOW_LP and my_lp - foe_lp > LEAD:
		return "winning"
	return "normal"

static func track(mood_name: String, match_game: int, rng_pick: int) -> String:
	match mood_name:
		"losing": return "m_furi"
		"winning": return "m_yuri"
	if match_game > 0:
		return "m_duel%d" % clampi(match_game, 1, 3)       # best-of-3 series: game 1, 2, 3
	return "m_duel%d" % (1 + rng_pick % 3)                  # single duels: one of the duel themes (not confirmed by the original)

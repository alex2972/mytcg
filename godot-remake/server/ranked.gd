class_name RankedService
extends RefCounted
## Results of finished duels: Elo ratings (ranked, human vs human only), win/loss records, DP rewards,
## the match log (<data>/matches/<yyyy-mm>.jsonl, written before the profiles), and the leaderboard.

const NO_CONTEST := ["server_shutdown", "stuck"]

var server: GameServer
var store: AccountStore
var _board_cache := []
var _board_at := -1000.0

func _init(game_server: GameServer, account_store: AccountStore) -> void:
	server = game_server
	store = account_store
	server.register("leaderboard", _on_leaderboard, true)
	server.register("my_rank", _on_my_rank, true)

## Expected score of a player rated `ra` against `rb`.
static func expected(ra: float, rb: float) -> float:
	return 1.0 / (1.0 + pow(10.0, (rb - ra) / 400.0))

## New rating after scoring `score` (1 win, 0.5 draw, 0 loss).
static func elo(rating: int, opponent: int, score: float, k: float, floor_value: int) -> int:
	return maxi(floor_value, roundi(float(rating) + k * (score - expected(float(rating), float(opponent)))))

func k_factor(profile: Dictionary) -> float:
	return float(server.config["elo_k_new"]) if int(profile.get("ranked_games", 0)) < int(server.config["elo_new_games"]) else float(server.config["elo_k"])

## Applies the result of `room`; returns per-seat extras for "room_result".
func on_duel_finished(room: DuelRoom) -> Array:
	var r: Dictionary = room.result
	var winner := int(r.get("winner", 2))
	var per_seat := [{}, {}]
	var humans := [not room.seats[0]["bot"], not room.seats[1]["bot"]]
	var profiles := [{}, {}]
	for i in 2:
		if humans[i] and room.seats[i]["account"] != "":
			profiles[i] = store.profile(room.seats[i]["account"])
	var pvp: bool = humans[0] and humans[1] and not profiles[0].is_empty() and not profiles[1].is_empty()
	if NO_CONTEST.has(str(r.get("reason", ""))):
		# The duel did not really finish (server shut down, rules engine stuck): log it, change nothing.
		_append_match({"room": room.id, "mode": room.mode, "time": int(server.now()), "winner": winner, "reason": r.get("reason", ""),
			"turns": int(r.get("turns", 0)), "players": [room.seats[0]["account"], room.seats[1]["account"]], "no_contest": true})
		return [{"no_contest": true}, {"no_contest": true}]
	var ranked: bool = room.mode == "ranked" and pvp
	var log_row := {"room": room.id, "mode": room.mode, "time": int(server.now()), "winner": winner, "reason": r.get("reason", ""),
		"turns": int(r.get("turns", 0)), "players": [room.seats[0]["account"], room.seats[1]["account"]], "bots": [room.seats[0]["bot"], room.seats[1]["bot"]]}
	if ranked:
		var before := [int(profiles[0].get("rating", 1500)), int(profiles[1].get("rating", 1500))]
		var after := [0, 0]
		for i in 2:
			var score := 0.5 if winner == 2 else (1.0 if winner == i else 0.0)
			after[i] = elo(before[i], before[1 - i], score, k_factor(profiles[i]), int(server.config["elo_floor"]))
		log_row["rating_before"] = before
		log_row["rating_after"] = after
		for i in 2:
			per_seat[i]["rating_before"] = before[i]
			per_seat[i]["rating_after"] = after[i]
			per_seat[i]["rating_delta"] = after[i] - before[i]
	_append_match(log_row)
	for i in 2:
		if profiles[i].is_empty():
			continue
		var p: Dictionary = profiles[i]
		var won := winner == i
		var reward := 0
		if room.mode == "ranked" and pvp:
			reward = int(server.config["reward_ranked_win"]) if won else (int(server.config["reward_ranked_loss"]) if winner != 2 else 0)
		elif room.mode == "casual" and pvp and won:
			reward = int(server.config["reward_casual_win"])
		if won and pvp and room.mode in ["ranked", "casual"]:
			var day := Time.get_date_string_from_unix_time(int(server.now()))
			if str(p.get("first_win_day", "")) != day:
				p["first_win_day"] = day
				reward += int(server.config["reward_first_win_of_day"])
		if ranked:
			p["rating"] = per_seat[i]["rating_after"]
			p["best_rating"] = maxi(int(p.get("best_rating", 1500)), int(p["rating"]))
			p["ranked_games"] = int(p.get("ranked_games", 0)) + 1
		if pvp:
			if winner == 2:
				p["draws"] = int(p.get("draws", 0)) + 1
				p["streak"] = 0
			elif won:
				p["wins"] = int(p.get("wins", 0)) + 1
				p["streak"] = maxi(0, int(p.get("streak", 0))) + 1
			else:
				p["losses"] = int(p.get("losses", 0)) + 1
				p["streak"] = mini(0, int(p.get("streak", 0))) - 1
		p["dp"] = int(p.get("dp", 0)) + reward
		store.save_profile(p)
		per_seat[i]["dp_reward"] = reward
		per_seat[i]["dp"] = int(p["dp"])
		if ranked or reward > 0:
			server.audit("duel_result", {"account": p["id"], "room": room.id, "mode": room.mode, "won": won, "reward": reward, "rating": int(p.get("rating", 0))})
	_board_at = -1000.0
	return per_seat

func _append_match(row: Dictionary) -> void:
	var month := Time.get_date_string_from_unix_time(int(server.now())).left(7)
	var path := server.data_dir + "/matches/%s.jsonl" % month
	var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(row))
	f.close()

## Accounts with ranked games, best first (rating, then wins, then name).
func ranking() -> Array:
	if server.now() - _board_at < float(server.config["leaderboard_cache_seconds"]):
		return _board_cache
	var rows := []
	for a in store.accounts():
		var p := store.profile(str(a["id"]))
		if int(p.get("ranked_games", 0)) <= 0 or p.get("banned", false):
			continue
		rows.append({"id": p["id"], "name": p.get("name", ""), "rating": int(p.get("rating", 1500)), "wins": int(p.get("wins", 0)),
			"losses": int(p.get("losses", 0)), "draws": int(p.get("draws", 0))})
	rows.sort_custom(func(x, y):
		if x["rating"] != y["rating"]: return x["rating"] > y["rating"]
		if x["wins"] != y["wins"]: return x["wins"] > y["wins"]
		return str(x["name"]).to_lower() < str(y["name"]).to_lower())
	for i in rows.size():
		rows[i]["rank"] = i + 1
	_board_cache = rows
	_board_at = server.now()
	return rows

func _on_leaderboard(_peer: int, args: Dictionary) -> Dictionary:
	var limit = args.get("limit", 100)
	var offset = args.get("offset", 0)
	if typeof(limit) != TYPE_INT or typeof(offset) != TYPE_INT or limit < 1 or offset < 0:
		return Protocol.fail("invalid_args")
	var rows := ranking()
	return Protocol.ok({"rows": rows.slice(offset, offset + mini(limit, 100)).map(func(x): var y: Dictionary = x.duplicate(); y.erase("id"); return y), "total": rows.size()})

func _on_my_rank(peer: int, _args: Dictionary) -> Dictionary:
	var id := server.account_of(peer)
	for row in ranking():
		if row["id"] == id:
			return Protocol.ok({"rank": row["rank"], "rating": row["rating"], "total": ranking().size()})
	return Protocol.ok({"rank": 0, "rating": int(store.profile(id).get("rating", 1500)), "total": ranking().size()})

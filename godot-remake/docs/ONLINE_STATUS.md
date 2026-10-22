# Online: status (autonomous run, stopped early at the usage limit)

Branch `online` (local only, nothing pushed). Plan: `docs/ONLINE_PLAN.md`. Decisions: `docs/ONLINE_DECISIONS.md`.
User overrides: no web build (phase 8 skipped), no pushing.

## Done
- **Phase 1 transport**: WebSocket + Godot high-level RPC (`shared/net_node.gd`, 2 generic RPCs), `GameServer` (config, logging, audit log,
  rate limit, strikes/kicks, hello/version+data-hash check, idle/hello timeouts), `OnlineClient`, `server/server_main.tscn`, test harness.
- **Phase 2 accounts**: register/login/token/logout, empty passwords allowed, PBKDF2 hashes, login delays, one session per account,
  login screen (`client/login_screen.gd`), title-screen "Online" button, `Session` online mode with saved token.
- **Phase 3 data**: shop/collection/deck on the server (`server/shop_service.gd`), `RemoteShopBackend`, card numbers on the wire and in
  collection files (format 2, old format still read), deck save validation, idempotent retransmissions, screens load through `Session`.
- **Phase 4 rooms**: `server/duel_room.gd` (janken, intents validated, bots via JoeyAI, timers, disconnect grace, reconnect resync, surrender),
  `shared/duel_snapshot.gd` (hidden-info filter, mirrored so each client is player 0), `server/room_manager.gd`, dev bot duel.
- **Phase 5 client duel**: `client/remote_duel.gd` (extends Duel; DuelBoard runs unchanged), janken online mode, `client/online_duel_screen.gd`.
- **Phase 6 ranked**: `server/matchmaker.gd` (ranked window, casual, CPU fallback, practice), `server/ranked.gd` (Elo, records, rewards,
  match log, leaderboard), `DeckRules.ranked_problem`, `client/online_lobby.gd`.
- **Phase 7 (part)**: fuzz test (found and fixed a shop crash and a reply-cache bug).
- CPU fix found by 200 bot duels: an effect that changes nothing (Fusion Gate) is no longer retried forever (also affected offline play).

## Tests (all green when last run individually)
`tests/online/`: test_transport, test_auth, test_online_data, test_room_rules, test_hidden_info, test_online_duel, test_matchmaking, test_fuzz_rpc.
Run everything: `bash tools/run_all_tests.sh` (from `godot-remake/`). The full suite was green after phase 3; it was NOT rerun after phases 4-7
(the last background run started in the wrong folder). Rerun it first.
Tools: `tools/online/bot_duels.gd` (200 CPU duels: all finished; rerun after the CPU fix), `tools/online/shot_online.gd` (windowed end-to-end screenshots).

## Run it
Server: `godot --headless --path . res://server/server_main.tscn -- --port 9080 --data user://server_dev --dev`
Client: start the game, Online, server `ws://127.0.0.1:9080`, Register, Play Online.

## Open items (not done)
- Phase 7 rest: quarantine of corrupt JSON files, daily backups, graceful shutdown (end rooms as no-contest; ranked should not rate
  "stuck"/"server_shutdown"), native TLS options, `deploy/` (Dockerfile, compose, Caddyfile, README).
- Phase 9: soak test with many bot clients, `docs/ONLINE.md` (protocol reference), final full-suite run.
- Phase 8 (web build) skipped by request.

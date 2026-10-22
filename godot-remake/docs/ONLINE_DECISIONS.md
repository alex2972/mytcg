# Online: decisions made during the autonomous run

Format: one entry per decision, newest last. Why it was chosen in one or two lines.

- **User override (2026-10-22): no web build in this run, no pushing.** Phase 8 (Web export, bundled web fonts, audio unlock) is skipped; the transport stays WebSocket so a browser client remains possible later. Commits are local on branch `online` only.
- **Git snapshot** includes only `godot-remake/` and `analysis/` (not `scratch/`, `videos/`, `ghproj2/`), so videos and Ghidra databases stay out of history.
- **Two generic RPCs instead of one RPC per message.** Godot 4 identifies RPCs by their index in the node's sorted RPC list, so client and server scripts must declare exactly the same RPC set. One shared script (`shared/net_node.gd`) with `c2s(kind, rid, args)` and `s2c(kind, rid, payload)` makes that impossible to get wrong; the protocol is the set of `kind` strings, validated on the server.
- **Every host (server or client) owns its own `SceneMultiplayer`** set with `SceneTree.set_multiplayer(api, host_path)` and a child named `Net`. RPC paths are relative to the host, so one process can run a server and several clients (tests), and production is the same code with one host.
- **`server_relay = false`** so clients can never message each other through the server.
- **Server-side engine runs with `presentation_enabled = false`** (no animation barriers; the engine resolves synchronously) and `interactive_selections = true` for every human seat (engine change: `Fx.interactive_players`).
- **Clients always see themselves as player 0.** Snapshots and events are mirrored for seat 1, so the existing board renders either seat unchanged.
- **Card uids are randomized per duel** (decks are shuffled before `Duel.create` assigns uids) so a uid never reveals which card it is.
- **Events never carry card identities** (audit of every `_emit`/`log_event`: only uids). Identities reach a client only through its filtered snapshot (`cards` it may see) plus a `known` map for cards legitimately revealed in that batch (reveal_cards, excavate, own selection candidates).
- **Casual ignores ratings** and pairs any two players at once; after 30 s alone the CPU takes the other seat. A separate **practice** mode starts a CPU duel immediately.
- **Rewards only against humans** (ranked win 50, ranked loss 10, casual win 20, first win of the day 100). CPU duels give nothing, so they cannot be farmed.
- **No-contest** for `server_shutdown` and `stuck`: logged in the match log, no rating, no rewards, no win/loss.
- **Retransmission cache keyed by (request id, kind, arguments)**: an exact repeat gets the stored answer; a reused id with different content is a new request (the fuzz test showed id-only keys could return stale answers).
- **Disconnect grace 90 s, decision 60 s, own turn 240 s, +15 s for animations, 3 timeouts = loss.** Timeouts answer safely (pass / no / first choice) or end the turn.
- **Ranked decks get the full rules** (40-60, Fusion/Side <= 15, forbidden/limited list, ownership); casual and practice only the 40 minimum, like offline play.
- **CPU never retries an effect more than twice per turn** (`CardAI.use_main`): found by bot-vs-bot duels (Fusion Gate looped forever; also affected offline play).
- **`Duel.dispose()`** breaks the engine's reference cycles (Duel <-> Fx <-> FxOps, equip links); rooms and online duel screens call it. Without it every finished duel leaked about 0.4 MB.
- **Damaged save files are moved aside** (`.corrupt-<time>`), never overwritten; the account index is rebuilt from the folders at startup.
- **Daily backups** of `<data>/accounts`, newest 7 kept. **Native TLS** via `--tls-cert/--tls-key`, or Caddy in front (deploy kit).
- **Phase 8 (web) skipped** as requested; WebSocket transport and plain-data protocol keep a browser client possible.

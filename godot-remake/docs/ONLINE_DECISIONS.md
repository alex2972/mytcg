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

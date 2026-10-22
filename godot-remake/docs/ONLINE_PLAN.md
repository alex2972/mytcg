# Going online: master plan (autonomous run)

Goal: the game becomes a **browser game with an authoritative server**: accounts (name + password, empty password allowed for now), a server-owned
collection / deck / DP / shop, **ranked and casual matchmaking**, and duels where the **server runs the rules** and clients only send intents and draw what the server tells them.
Transport: Godot's **high-level multiplayer API** (`SceneMultiplayer`, `@rpc`) over **WebSocket** (the only transport browsers support).
The offline game (single duel vs the AI, deck editor, shop against the local backend) must keep working at every step.

This file is the contract for the agent that executes it. **Read "Rules of engagement" first.** The agent must not ask the user anything: every open question below already has a default.

---------------------------------------------------------------------------------------------------

## 0. Rules of engagement (read first)

1. **Never ask the user anything.** The user is asleep. Where this plan is silent, pick the simplest option that fits the architecture, write the choice and the reason in `docs/ONLINE_DECISIONS.md` (append, one short entry), and continue.
2. **Never get stuck.** If a step fails after ~3 honest attempts, stub it behind a clearly named `TODO(online)` with a failing-safe default, record it in `docs/ONLINE_STATUS.md` under "Open items", and move on to the next step. Prefer a working vertical slice over a perfect layer.
3. **Do not break offline play.** After every phase run the whole test suite (see 10.). All existing tests must pass at the end of every phase (the `test_deck_editor` "drawer animates" check is known to be flaky: rerun it alone before calling it a failure).
4. **Protect the user's data.** Never read, write or delete anything under `%APPDATA%\Godot\app_userdata\Godot remake\` (their real accounts/saves). Tests and tools use throwaway folders (`user://test_*`, wipe them yourself) and `Session.use_root(<throwaway>)`.
5. **Git:** first commit the current working tree to a new branch `online` (`git switch -c online`, `git add -A`, message "Snapshot before online work"). Then one commit per finished phase on that branch (message "Online phase N: ..."). **Do not push, do not merge into `main`, do not delete anything.**
6. **No network side effects** beyond localhost, except downloading Godot export templates (allowed, see 9.) from the official source. Do not install system services.
7. **Tooling gotchas** (learned the hard way):
   - Godot: `Z:\godot\Godot_v4.7.1-stable_win64_console.exe`. Headless test: `godot --headless --path . -s tests/<name>.gd`. After adding a `class_name`, run `godot --headless --path . --import` once.
   - Always wrap test runs in `timeout 90` (a parse error makes a script hang until the timeout). Run long jobs with `run_in_background` and wait for the notification; never `sleep`-poll.
   - Edit files with small Python scripts (read, `assert s.count(old) == 1`, replace, write). Files mix CRLF and LF: preserve what each file uses (`newline=''`). Bash heredocs with quotes/apostrophes break; use the Write tool for new files.
   - GDScript is strict: warnings are errors. Do not name methods like built-ins (`set_meta`, `get_meta`...). Type inference fails on Variant values: annotate (`var x: int = ...`).
   - Windows paths with spaces: quote them. The project path is `Z:\process\godot-remake`.
8. **Keep going until the Definition of Done (section 11) is met**, then write `docs/ONLINE_STATUS.md` (what exists, how to run server/client, test commands, open items) and update the memory file `C:\Users\Usuario\.claude\projects\Z--process\memory\joey-godot-rebuild.md` with a short "Update 16: online" paragraph.
9. Work in the order of the phases. Inside a phase, write the tests first or alongside; a phase is done only when its **Done when** list passes.

---------------------------------------------------------------------------------------------------

## 1. What already exists (reuse it, do not rewrite it)

| Piece | Where | Online role |
|---|---|---|
| Headless rules engine | `core/duel.gd`, `core/effects/*`, `core/duel_card.gd` | runs **on the server**, unchanged rules; no UI dependencies |
| Decision system | `fx.pending` + `duel.respond(answer)` | maps 1:1 to "server asks seat N, seat N answers" |
| Events for animation | `duel.events` / `drain_events()` | the stream the server sends to clients (after hidden-info filtering) |
| Shop/accounts API | `core/shop/shop_backend.gd` (abstract), `local_shop_backend.gd` (logic), `core/accounts/account_store.gd`, `autoload/session.gd` | `LocalShopBackend` **is the server logic**; add `RemoteShopBackend` (same methods, over RPC) for the client |
| Packs, rarities, sets, caps | `core/shop/pack_opener.gd`, `data/shop/catalog.json` | server only |
| Deck rules | `core/deck_rules.gd` (40 minimum, 3 per name, forbidden list, aliases) | server validates decks; ranked uses the **full** rules (see 5.4) |
| AI | `core/ai/joey_ai.gd` (`JoeyAI.step(duel, player)`) | server-side bot seat (tests, matchmaking fallback, practice) |
| UI | `ui/duel_board.gd` (2500 lines, reads `duel.*`, calls `duel.<action>()`), `ui/duel_setup.gd`, `ui/janken_screen.gd`, shop, deck editor, card list | adapt via a view/port layer (phase 5) |

Facts that shape the design:
- `Duel` holds `Callable`s inside `fx.tasks`: **the engine state cannot be serialized or copied to the client.** The client therefore cannot hold a real `Duel`. It holds a *view* built from snapshots (4.3).
- `DuelBoard` makes ~18 action calls (`duel.summon/set_spell_trap/attack/activate_effect/change_position/to_battle/to_main2/end_turn/respond/surrender/skip_phase`) and ~75 read calls (`duel.side(p)`, `card_by_uid`, `atk_of`, `monsters_of`, `summon_problem`, `can_attack`, `activatable_effects`, ...).
- The engine asks the UI for **presentation barriers** (`pending.type == "presentation"`, answered with `respond(true)` after animations). The server must auto-answer these.
- `JankenScreen` decides who goes first with a local RNG. Online this is decided by the server.
- The shop font uses `SystemFont` (Impact/Arial) in ~9 places: **not available in browsers**. Bundle fonts (5.9).
- `assets/` is ~217 MB (audio, art). A web build needs a size budget and lazy loading (9.).

---------------------------------------------------------------------------------------------------

## 2. Architecture

```
 Browser (Godot Web export)                      Dedicated server (Godot headless, same project)
 ┌───────────────────────────┐   WebSocket        ┌────────────────────────────────────────────┐
 │ ui/*  (screens)           │  (wss in prod)     │ server/server_main.gd  (entry, config, tick)│
 │ client/net_client.gd Net  │ ◄────────────────► │ server/net_server.gd   (RPC endpoints)      │
 │ client/remote_*.gd        │   @rpc, high-level │ server/auth.gd  sessions.gd  rate_limit.gd  │
 │ RemoteShopBackend         │   SceneMultiplayer │ server/matchmaker.gd  ranked.gd             │
 │ RemoteDuel (view+port)    │                    │ server/duel_room.gd  (one Duel per room)    │
 └───────────────────────────┘                    │ core/* (rules, shop logic, deck rules)       │
                                                  │ server/store/*  (accounts, decks, results)   │
                                                  └────────────────────────────────────────────┘
```
Directory layout (new): `server/`, `client/`, `shared/` (protocol constants, serialization helpers used by both), `tests/online/`, `tools/online/`. `core/` stays engine-only.
One project, two entry points: the normal main scene is the client; `server/server_main.tscn` (run with `godot --headless --path . res://server/server_main.tscn -- --port 9080 --data <dir>`) is the server. Export presets: **Web** (client) and **Linux dedicated server** (9.).

### 2.1 Transport: Godot high-level multiplayer
- `WebSocketMultiplayerPeer` on both sides, `SceneMultiplayer` as the API. Server peer id is always 1. Browsers cannot use ENet.
- RPC endpoints live on **nodes with identical paths on both sides**: autoload-like node `/root/Net` (`client/net_client.gd` on clients, `server/net_server.gd` on the server, same `name`). Declare the same `@rpc` signatures on both scripts (a shared base `shared/net_api.gd` holds the stubs).
- Client → server calls: `@rpc("any_peer", "call_remote", "reliable")`. Server → client: `@rpc("authority", "call_remote", "reliable")` called with `rpc_id(peer, ...)`.
- **Return values do not exist in RPC.** Request/reply uses a request id: client `request(kind, args) -> awaits reply signal keyed by rid`, server answers with `reply.rpc_id(peer, rid, result)`. `RemoteShopBackend` is built on this.
- **Never trust the sender**: identify callers only with `multiplayer.get_remote_sender_id()` mapped through the server's session table. Do not enable object decoding. Only send `int/float/bool/String/Array/Dictionary/PackedByteArray`.
- Dev: `ws://127.0.0.1:9080`. Prod: Godot TLS (`TLSOptions.server(key, cert)`) or a TLS-terminating reverse proxy (Caddy/nginx) giving `wss://`. A browser on https refuses plain `ws://`.
- Protocol handshake: first RPC is `hello(protocol_version, data_hash)`. `data_hash` = hash of `data/cards.json` + effect JSONs + `data/card_tiers.json` + catalog. Mismatch -> `{"ok": false, "error": "outdated_client"}` and disconnect (the browser just needs a refresh).
- Keepalive: client pings every 5 s; server drops peers silent for 20 s (a dropped *dueling* peer gets the reconnect grace, 5.6).

### 2.2 Authority rules (the security model)
1. The client never sends results, prices, balances, card lists, card ids it "has", or damage. It sends **intents** (ids of its own cards/choices) and the server re-validates all of them with the same engine methods that already return reasons (`"Not your turn."`, ...).
2. All randomness (shuffles, packs, dice/coins, first player) uses server RNGs seeded from `Crypto.generate_random_bytes`. Seeds are never sent.
3. Hidden information never leaves the server (4.4).
4. Every RPC validates: types, ranges, string lengths, caller session state, and rate limits. Anything invalid returns an error code and increments a strike counter (kick after N).

---------------------------------------------------------------------------------------------------

## 3. Data model (server side)

`ServerStore` interface (`server/store/store.gd`), first implementation `JsonStore` (atomic write via temp file + rename, as `AccountStore.write_json` does). Keep every access behind the interface so a real database can replace it later.

```
<data>/accounts/index.json                   name(lowercase) -> account id, counters
<data>/accounts/<id>/profile.json            {id, name, pw: {salt, hash, iterations} | null, dp, created, last_login,
                                              rating, wins, losses, draws, streak, best_rating, banned: false}
<data>/accounts/<id>/collection.json         card index -> copies   (existing format; migrate to Konami number keys, see 3.1)
<data>/accounts/<id>/deck.ydc                working deck (existing format)
<data>/accounts/<id>/purchases.jsonl         existing
<data>/matches/<yyyy-mm>.jsonl               one line per finished duel: players, ranked, winner, reason, turns, rating deltas, seed? (no seed)
<data>/config.json                           ports, limits, K factor, timers, ranked rules, rewards
```
### 3.1 Stable card identity
The collection stores CardDB **indices**, which change if the card DB is rebuilt. Online data must use the stable **Konami number** (`cards.json "number"`; alternate-art versions already have their own numbers). Add `Collection.to_numbers()/from_numbers()` and store numbers server-side; the wire format uses numbers too. Do this in phase 3 and migrate the local format with a one-time conversion (keep reading the old format).

### 3.2 Passwords
Empty passwords are allowed now (`pw: null`). When non-empty: salted PBKDF2-HMAC-SHA256 (>= 10 000 iterations, implemented with `Crypto.hmac_digest`), constant-time compare, max length 64. Failed logins: delay grows per attempt per account+peer (1,2,4... s, cap 30 s). Passwords are never logged. Session tokens: 32 random bytes hex, in memory, 24 h expiry, bound to the account (re-login kicks the old session).
Names: 3-16 chars, `[A-Za-z0-9_ -]`, unique case-insensitively, no leading/trailing space, a small reserved list (`admin`, `system`, `server`, ...).

---------------------------------------------------------------------------------------------------

## 4. Online duels

### 4.1 Rooms
`DuelRoom` owns one `Duel` (`Duel.create(db, deck0, deck1, seed, first, null, true)`), two seats `{account, peer, connected, timer}`, a monotonically increasing `seq`, the event log, and a state machine:
`janken -> opening -> playing -> finished`. A room never touches the UI. Rooms live in `RoomManager`; at most one active room per account.
- **Janken:** the server collects both picks (timeout 15 s = random pick), resolves, lets the winner choose first/second (timeout 15 s = first), then starts the opening deal.
- **Presentation barriers:** the server auto-answers `pending.type == "presentation"` with `respond(true)` immediately; clients queue and play event batches in order. A client may take a while to animate, so decision timers start only after the client acks the batch containing the prompt (`ack(seq)`), with a hard cap.
- **After each accepted intent** the room drains `duel.events`, bumps `seq`, and sends each seat **its own filtered** `{seq, events, state}` batch (4.3, 4.4).
- **Bot seat:** `BotSeat` drives a seat with `JoeyAI.step` (used by tests, "practice vs CPU online", matchmaking fallback after N seconds in casual).

### 4.2 Intents (client -> server), all `{room_id, seq_seen, kind, args}`
`summon(uid, tributes[], zone, face_down)`, `set_spell_trap(uid, zone)`, `change_position(uid)`, `activate(uid, effect_idx)`, `attack(attacker_uid, target_uid|-1)`, `to_battle`, `to_main2`, `end_turn(discards[])`, `respond(answer)` (chain/selection/yes-no answers, validated against `pending`), `surrender`, plus lobby-level `janken_pick(hand)`, `choose_order(first)`.
Server checks: caller owns the seat; `pending.player == seat` when answering; `uid`s exist and belong to the right zone/controller; no intent is accepted while another seat's decision is pending; duplicate/old `seq_seen` is ignored safely. Result to the caller: `{ok, error?}`; state changes arrive via the broadcast, not the reply.

### 4.3 Snapshot / view (client state)
After every batch the server sends a **filtered snapshot** for the receiving seat, serialized as plain dictionaries: players' LP, phase, turn, turn player, per-zone cards, counts (opponent hand, both decks, extra decks), graveyards and banished (public), `pending` (only when it is this seat's decision: type, options, candidates, prompt id), attack in progress, and for the **viewer's own cards** the precomputed *legal info* the UI needs for hover/cursors: `summon_problem`, `can_attack`, `activatable effect indices`, `tributes_required`, `atk/def` (current, with effects) for **all visible** cards. Each visible card: `uid, idx|number, owner, controller, face_up, pos, atk, def, level, equipped_to, counters/flags the UI shows (marker tokens, negated, ...)`.
Client side: `shared/duel_view.gd` (`DuelView`, duck-types the `Duel` read API used by `DuelBoard`: `side(p)`, `card_by_uid`, `atk_of`, `def_of`, `monsters_of`, `is_on_field`, `summon_problem`, `can_attack`, `activatable_effects`, `pending()`, `phase`, `turn_player`, `winner`, `events`, ...). Cards are lightweight `DCard` objects built from the snapshot (hidden cards: `idx = 0`, `face_up = false`).
Actions on the client go through a **`DuelPort`**: `LocalPort` (calls the real `Duel`, synchronous, today's behaviour) and `RemotePort` (sends the intent, returns `""` optimistically, the real outcome arrives with the next batch; errors surface as a toast + a forced resync). `DuelBoard` is changed to use the port and a `view` object instead of touching `Duel` directly; offline it gets `LocalPort` + the real `Duel` as the view, so offline behaviour and tests are unchanged.
Resync: any time the client's `seq` does not follow, it requests `resync(room_id)` and gets a full snapshot (also used for reconnects).

### 4.4 Hidden information (must be airtight)
Filtered per seat, enforced in one place (`shared/view_filter.gd`):
- opponent hand: only a count and `uid`s (so draw/discard animations can address cards); `idx = 0`.
- both decks and extra decks: counts only (the owner may see the *count*); top card of a deck is never revealed unless an effect event says so (`reveal_cards` events carry the card to **both** seats when the rules reveal it).
- face-down monsters/spells of the opponent: `uid`, zone, position only. Own face-down cards: full info.
- **Events** are filtered the same way: e.g. `draw` for the opponent has no card id; `set_monster/set_spell` hide the card; `flip`/`reveal` include it. **Audit every `_emit(...)` call in `core/` and `core/effects/`** and write the filter as an allow-list per event type with a default of "strip card identity"; unknown event types are stripped.
- Test (`tests/online/test_hidden_info.gd`): play scripted and random duels, serialize everything sent to seat A, and assert no card number/idx of seat B's hand, deck order, face-down cards, or deck-top appears anywhere (except when legitimately revealed).

### 4.5 Timers and disconnects
Defaults (in `config.json`): per-decision limit 60 s (chain/selection), turn bank 6 min per player with 30 s increment per turn; janken/order 15 s. Timeout on a decision = auto "pass/no" (a safe default per prompt type); bank exhausted = loses the turn's remaining actions by auto end-turn; 3 consecutive timeouts = forfeit.
Disconnect: the room pauses that seat's clock for a **grace of 90 s**; the client reconnects with its token and `rejoin(room_id)` and receives a full snapshot. Grace expired = forfeit loss. Both disconnected for >2 min = abandoned (ranked: both count as a loss only for the player who had the clock; keep it simple: the one who left first loses).

---------------------------------------------------------------------------------------------------

## 5. Phases (execute in order)

### Phase 1: Server skeleton and transport
- `server/server_main.gd/.tscn`: parses `--port`, `--data`, `--config`; creates `WebSocketMultiplayerPeer` server; logs to stdout and `<data>/logs/server.log` (rotating by size); graceful shutdown on SIGINT/`quit`; a 1 Hz tick for timers.
- `shared/net_api.gd` (rpc stubs, `PROTOCOL_VERSION`, error codes), `server/net_server.gd`, `client/net_client.gd` (autoload `Net`, `connect_to(url)`, `request(kind, args)`, signals `connected/disconnected/reply`), `server/rate_limit.gd` (token bucket per peer: default 30 msgs/s burst 60), `data_hash()` helper, `hello` handshake, `ping`.
- `tests/online/harness.gd`: starts the server **in-process** (a second `SceneMultiplayer` on a subtree via `get_tree().set_multiplayer(api, path)`, or, if that proves awkward, as a child process with `OS.create_process` on a free port) and connects N clients; helper `await_reply`, free-port picker, temp data dirs, teardown.
- **Done when:** a test connects 2 clients, handshake ok, outdated version rejected, rate limit trips, a client that never says hello is dropped; server runs headless via the documented command.

### Phase 2: Accounts and auth
- `server/store/store.gd` (interface) + `json_store.gd`; `server/auth.gd`: `register(name, password)`, `login(name, password)` -> `{token, account}`, `login_token(token)`, `logout`; one session per account; strikes/delays; name validation; password hashing (3.2). New accounts get what `AccountStore.create_account` gives today (starting DP, starter 3x Polymerization + 3x Little D, 6-card deck).
- Client: `client/login_screen.gd` (name + password fields, "Register" and "Login" buttons, "Play offline" button that keeps today's behaviour, server URL field with a default from `config`/`localStorage` on web); `Session` gets `mode = "offline" | "online"`, `account_id()` returns the online account; on web persist the token via `JavaScriptBridge` (localStorage), elsewhere in `user://online.cfg`; auto re-login on start; main menu shows the account name and a Logout button.
- **Done when:** register -> logout -> login works (also with empty password); wrong password refused with delay; duplicate and invalid names refused; two logins of one account kick the first; restart the server and the accounts/profiles persist; token re-login works; tests cover all of it.

### Phase 3: Remote data and shop
- Extend `ShopBackend` (rename nothing, only add): `get_collection()`, `get_deck()`, `save_deck(deck)` (server validates ownership, 3-copy rules by name/alias, section limits; **does not** reject <40 so players can save work in progress), `get_account_summary()` (name, dp, rating, W/L). `LocalShopBackend` implements them on the local files; the **server wires one `LocalShopBackend`-equivalent per request** with the account's folder (or refactor so the logic takes an `account_id` and a `Store`).
- `client/remote_shop_backend.gd` (`extends ShopBackend`): every method = request/reply RPC. `Session.backend` is `LocalShopBackend` offline and `RemoteShopBackend` online. The Shop, pack opening, pack contents, Card List, Deck Editor and Duel screens must obtain collection/deck/DP **only through `Session`** (remove direct `Collection.load_default()`/`Deck.load_working()` in `ui/` online paths; keep local behaviour offline). Deck Editor autosave becomes `save_deck` (debounced 1 s) online.
- Switch collections to Konami numbers on the wire and in the server store (3.1).
- Make every `await backend.x()` call site robust to latency and failure (loading indicator, error toast, no double-submit; purchases are idempotent per request id: the server remembers the last 50 request ids per session and returns the stored result on a repeat).
- **Done when:** online account buys packs (DP and cards change server-side, restart-safe), edits and saves a deck, sees the Card List; two accounts never see each other's data; refused purchases (no DP / set complete / unavailable) behave like offline; the existing shop tests pass against both backends (parametrize `tests/test_accounts_shop.gd` logic through the `ShopBackend` API where practical).

### Phase 4: Authoritative duel rooms
- `server/duel_room.gd`, `room_manager.gd`, `bot_seat.gd`, `shared/view_filter.gd`, `shared/snapshot.gd` (build/parse), event-type allow-list and audit (4.4), janken/order handshake, presentation auto-ack, intents (4.2), timers and disconnect handling (4.5), `surrender`, game end -> result object (winner, reason, turns).
- A debug-only RPC `dev_start_bot_duel(deck)` (enabled with `--dev` flag) creates a room vs `BotSeat` for tests and manual play.
- `tests/online/test_room_rules.gd`: scripted duels through the room API: illegal intents refused (wrong seat, wrong zone, wrong phase, answering someone else's prompt), seq handling, surrender, timeouts, disconnect/reconnect with snapshot, presentation auto-ack, bot vs bot reaches a winner.
- `tests/online/test_hidden_info.gd` (4.4).
- **Done when:** 200 bot-vs-bot duels with random seeds finish without exceptions or stuck rooms (a watchdog fails any room with no progress for 30 s of game time), hidden-info test passes, determinism holds (same seed + same intents -> same events).

### Phase 5: Client duel (RemoteDuel, board adaptation)
- Introduce `shared/duel_port.gd` (`LocalPort`, `RemotePort`) and `shared/duel_view.gd`; refactor `ui/duel_board.gd` to the port/view with **no behaviour change offline** (run all duel/board tests after the refactor before touching online).
- `RemotePort` + `RemoteDuel`: apply batches in `seq` order, queue them for the board's existing `_play_events` pipeline, expose `state_updated`; show opponent name/rating and a turn/decision timer on the board; "Surrender" works; connection-lost overlay with automatic reconnect; the board never lets the human act when the view says it is not their decision.
- Janken online: `ui/janken_screen.gd` gets an online mode where the pick is sent to the server and the result is read from it (no local RNG).
- **Done when:** two scripted client processes (or in-process clients with a headless board, `fx_enabled = false`) play a full duel against each other through the server and **both views end identical** to what the server holds (compare filtered snapshots at the end of every batch); a human can play a casual duel against `BotSeat` in the real UI (take screenshots with the windowed helper pattern in `tools/shot_*.gd` to confirm the board renders both seats correctly).

### Phase 6: Matchmaking and ranked
- `server/matchmaker.gd`: queues `casual` and `ranked`; `queue_join(mode)`, `queue_leave`; one queue entry per account; match when `|rating diff| <= 100 + 25 * seconds_waiting` (cap 600); casual matches anyone after 5 s; casual falls back to a bot after 30 s (the opponent is labelled "CPU"); matches create a `DuelRoom` with both seats; `match_found` event to both clients with a 10 s accept-less auto-start (no accept step).
- `server/ranked.gd`: Elo, start 1500, K = 32 (K = 40 for the first 20 ranked games), result applied only for ranked **human vs human** finished duels (including forfeits/disconnect losses); draws give half; rating never below 100; stores `wins/losses/draws/streak/best_rating`; appends to the matches log; transactionally updates both profiles (write both or neither; on crash recovery trust the match log).
- **Ranked deck rules** (`DeckRules.problems` + a new `DeckRules.ranked_problems`): >= 40 main, <= 60, extra <= 15, side <= 15, 3 per name (aliases), **forbidden/limited list enforced**, ownership verified server-side at queue time. A deck that fails is refused with the first reason. Casual: only the 40-card minimum (like offline).
- Rewards (config, default): ranked win +50 DP, loss +10 DP, casual win +20 DP; first win of the day +100 DP (UTC day). Server grants them at duel end and includes them in the result.
- Leaderboard: `leaderboard(limit<=100, offset)` + `my_rank()`; cached 10 s on the server.
- Client UI: "Play Online" entry on the main menu -> screen with **Ranked / Casual** buttons, searching animation with a cancel button and elapsed time, the player's rating/W-L, the Top 100 leaderboard screen, result screen after a duel (win/lose banner already exists; add rating change and DP reward line). Keep the visual style of the shop/menu screens.
- **Done when:** two accounts queue ranked, get matched, duel (bots-as-clients in tests), ratings and DP change correctly and persist after a server restart; rating symmetry holds (sum of deltas ~0 apart from rounding); a forfeit counts; casual fallback bot works; leaderboard orders correctly; an invalid ranked deck is refused with a reason; tests cover Elo math (known values), queue windows (fake clock), deck-rule refusal.

### Phase 7: Hardening and operations
- Input validation fuzz: `tests/online/test_fuzz_rpc.gd` sends random/garbage/oversized arguments to every endpoint and asserts the server never crashes, never leaks stack traces to clients, and strikes/kicks abusers.
- Logging with levels; `--verbose`; audit log for logins, purchases, ranked results; `/healthz`-equivalent: an RPC `server_status` (uptime, players, rooms, version) usable by a script; metrics counters printed every 60 s.
- Persistence safety: all store writes atomic; on startup validate JSON and quarantine corrupt files (rename `.corrupt-<time>`) instead of crashing; daily backup copy of `<data>/accounts` into `<data>/backups/<date>/` (keep 7).
- Config: everything tunable in `<data>/config.json` with defaults written on first run; no magic numbers in code.
- Graceful restart: on SIGTERM, stop matchmaking, let rooms finish up to 60 s (or snapshot them as abandoned), flush stores.
- Deployment kit (`deploy/`): `Dockerfile` for the headless server, `docker-compose.yml` (server + Caddy for `wss://`, sample `Caddyfile`), `README` with exact steps; Godot-native TLS option documented. No secrets in the repo.
- **Done when:** fuzz test green, restart/backup tests green, `deploy/` files present and linted by reading them (cannot run Docker here; say so in the status file).

### Phase 8: Web client build
- Create `export_presets.cfg` with **Web** (single-threaded, no PWA, `canvas_resize_policy` adaptive, 800x600 stretch kept) and **Linux dedicated server**. Try to export; if templates are missing, download the official 4.7.1 templates (`Godot_v4.7.1-stable_export_templates.tpz` from the official GitHub releases) into `%APPDATA%\Godot\export_templates\4.7.1.stable\` and retry. If that is impossible in this environment, finish everything else, document the exact commands in `docs/ONLINE.md`, and list it under Open items (do not block).
- Web specifics: replace every `SystemFont` with bundled open-license fonts (e.g. Anton or Bebas Neue for the Impact look, Liberation Sans/Arimo for Arial; put them in `assets/fonts/` with their license files; load them in `shared/fonts.gd`) and verify text metrics on the shop, deck editor and duel board with screenshots; add a "Click to start" overlay that unlocks audio on the first user gesture; audio: prefer lower-bitrate ogg for the web preset or lazy-load music; **size budget**: report the exported `.pck`/`.wasm` sizes in the status file and, if the pack is > 150 MB, split rarely-needed assets (Joey voice lines are unused) via export filters; `JavaScriptBridge` for the stored token and the server URL (`?server=wss://...` query parameter); handle `window` focus/visibility so timers do not lie.
- Smoke test: export to `output/web/`, serve with `python -m http.server`, open in the built-in browser pane (preview tools) and check the login screen renders and connects to a locally started server. If automation of the browser is not possible, document the manual steps.
- **Done when:** the Web export exists or the exact blocker is documented; fonts are bundled; offline play still works from the desktop build.

### Phase 9: Soak, docs, handover
- `tools/online/soak.gd`: spawns the server and K bot clients that play ranked/casual matches continuously for N minutes; asserts no exceptions, no rooms stuck, rating sums consistent, no memory growth beyond a threshold (print RSS-like counters from the server). Run for at least a few thousand duel-turns in total.
- Write `docs/ONLINE.md` (architecture as built, protocol list with every RPC and error code, data formats, config keys, how to run server/client/tests/soak/export, security notes, known limitations) and `docs/ONLINE_STATUS.md` (checklist of this plan with done/open items, test results, soak result).
- Update memory (rule 8).
- **Done when:** the Definition of Done below is satisfied.

---------------------------------------------------------------------------------------------------

## 6. Protocol cheat sheet (names are the contract; arguments may be refined)

Auth/session: `hello`, `register`, `login`, `login_token`, `logout`, `ping`, `server_status`
Data: `shop_request(rid, method, args)` -> `shop_reply(rid, result)` (methods: `get_profile`, `get_catalog`, `get_product_contents`, `purchase`, `get_collection`, `get_deck`, `save_deck`, `get_account_summary`)
Matchmaking: `queue_join(mode)`, `queue_leave`, `queue_status` (server push), `match_found` (push), `dev_start_bot_duel` (dev only)
Duel: `room_intent(room_id, seq_seen, kind, args)`, `room_ack(room_id, seq)`, `room_resync(room_id)`, `room_rejoin(room_id)`; pushes: `room_batch(room_id, seq, events, snapshot)`, `room_prompt`, `room_result`
Social/ranked: `leaderboard(limit, offset)`, `my_rank`
Errors (string codes): `outdated_client, not_authenticated, bad_credentials, name_taken, bad_name, bad_password, rate_limited, busy, not_found, invalid_args, not_your_turn, not_your_decision, illegal_action, deck_invalid, not_enough_dp, set_complete, unavailable, already_in_duel, server_error`.

---------------------------------------------------------------------------------------------------

## 7. Testing strategy (headless, all on code)

- Unit: Elo math, queue windows (fake clock), password hashing, name validation, view filter, snapshot round trip, event allow-list, `DeckRules.ranked_problems`, rate limiter.
- Integration (in-process server + clients over localhost WebSocket): auth flows, shop through RPC, deck save, matchmaking, full bot-vs-bot duels through the room API, reconnect, timeouts (use a fake clock hook in `DuelRoom`/`Matchmaker`, never real waits > 2 s in tests).
- Property/fuzz: random legal-intent playout (200+ seeds) comparing server state vs every client view after each batch; garbage RPCs.
- Hidden-info scan (4.4) on the raw serialized payloads.
- Soak (phase 9).
- Every new test file is added to the normal `tests/` run (`tests/online/*.gd` must be discovered by a small runner script `tools/run_all_tests.sh`; create it: runs every `tests/test_*.gd` and `tests/online/test_*.gd` with `timeout 90` each, prints failures only).

## 8. Out of scope for this run (note them, do not build them)
Email/OAuth login, password reset, spectators, chat, friends, tournaments/seasons, anti-cheat telemetry, payments, multiple deck slots, replays, mobile layout, a real SQL database (the `ServerStore` interface is the seam), card-art CDN.

## 9. Known risks and the planned answers
- *`DuelBoard` is large and reads the engine everywhere.* -> port/view facade, offline path unchanged and tested first (phase 5); if a read has no snapshot equivalent, add it to the snapshot instead of touching the engine.
- *Event streams leak hidden info.* -> allow-list filter + audit + scan test (4.4).
- *Engine presentation barriers assume a UI.* -> server auto-ack (4.1), clients queue batches.
- *Animations make clients lag behind the server.* -> batches are buffered per client; decision timers start after `ack`; input locked while the view is behind the server `seq`.
- *Web fonts/audio/size.* -> bundled fonts, audio unlock overlay, size report and export filters (phase 8).
- *WebSocket multiplayer details in 4.7 (inbound/outbound buffer sizes, `handshake_timeout`, `supported_protocols`).* -> set `inbound_buffer_size`/`outbound_buffer_size` to >= 1 MB (snapshots), `handshake_timeout` 10 s; read the engine docs/class reference through `godot --doctool` or the editor help text if an API detail is unclear; if a detail is still uncertain, write a tiny experiment script before building on it.

## 10. Commands (reference)
```
cd Z:\process\godot-remake
godot --headless --path . --import                          # after adding class_names
godot --headless --path . -s tests/<name>.gd                # one test (wrap in timeout 90)
bash tools/run_all_tests.sh                                  # everything (create it in phase 1)
godot --headless --path . res://server/server_main.tscn -- --port 9080 --data user://server_dev   # server
godot --headless --path . -s tools/online/soak.gd -- 10      # soak minutes
```
(`godot` = `Z:\godot\Godot_v4.7.1-stable_win64_console.exe`.)

## 11. Definition of Done
1. `bash tools/run_all_tests.sh` is green (only the known flaky deck-editor check may need a rerun), including all `tests/online/*`.
2. A fresh account can: register, log in, buy packs, edit/save a deck, join ranked, play a **complete duel against another account** (bots in tests; a human against `BotSeat` in the UI), win/lose, see rating/DP changes, appear on the leaderboard, log out and back in with everything persisted server-side.
3. Hidden-info scan, fuzz test and soak report pass.
4. Offline mode (single duel vs AI, deck editor, shop, Card List) works exactly as before.
5. `docs/ONLINE.md` and `docs/ONLINE_STATUS.md` exist and are honest about open items; `docs/ONLINE_DECISIONS.md` lists the choices made; memory updated; commits made on branch `online`.

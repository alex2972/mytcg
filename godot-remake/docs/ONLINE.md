# Online play: how it works (as built)

The game has an **authoritative server**: accounts, cards, decks, DP, packs and every duel rule run on the server.
Clients send requests and duel *intents* and draw what the server sends back. Offline play (single duel vs the CPU,
local accounts, local shop) still works exactly as before.

## Running
```
# server (from godot-remake/); --dev enables the dev-only bot duel request
godot --path . --headless -- --server --port=27840 --data=user://server_dev [--dev]
      [--tls-cert=fullchain.pem --tls-key=privkey.pem]
# client: start the game -> "Online" (bottom right of the title) -> server ws://127.0.0.1:27840 -> Register/Login -> Play Online
```
Deployment (Docker + Caddy for wss://): `deploy/README.md`.

## Layout
| Folder | What |
|---|---|
| `shared/` | `net_node.gd` (the RPC node), `protocol.gd` (version, data hash, error codes, plain-data helpers), `duel_snapshot.gd` (per-seat filtered state) |
| `server/` | `game_server.gd` (peers, routing, rate limits, config, logs), `auth.gd`, `shop_service.gd`, `room_manager.gd`, `duel_room.gd`, `matchmaker.gd`, `ranked.gd`, `maintenance.gd`, `services.gd`, `server_main.tscn` |
| `client/` | `online_client.gd` (connection + requests), `remote_shop_backend.gd`, `remote_duel.gd`, `login_screen.gd`, `online_lobby.gd`, `online_duel_screen.gd` |
| `core/` | unchanged rules engine and shop logic (used by the server); `Collection`/`Deck` number conversion, `DeckRules.ranked_problem` |
| `tests/online/` | transport, auth, data, rooms, hidden info, network duel, matchmaking, fuzz, operations; `harness.gd` runs server + clients in one process |
| `tools/online/` | `soak.gd`, `bot_duels.gd`, `shot_online.gd`, `shot_login.gd` |

## Transport
- WebSocket (`WebSocketMultiplayerPeer`) with Godot's high-level multiplayer (`SceneMultiplayer`, `@rpc`). Browsers can use the same server later.
- Each host (server or client) owns a `SceneMultiplayer` for its own subtree and a child node `Net` (`shared/net_node.gd`) with exactly two RPCs:
  `c2s(kind, rid, args)` (client -> server) and `s2c(kind, rid, payload)` (server -> client; kind `"reply"` answers `rid`, any other kind is a push).
  One script on both sides avoids Godot's RPC-index mismatches; the protocol is the set of `kind` strings.
- `server_relay` is off and object decoding is off. Arguments must be plain data (bounded depth/size); anything else is a strike.
- Rate limit per connection (token bucket, default 30/s burst 60); malformed or abusive requests add strikes; 20 strikes = kick.
- Connections must say `hello` within 10 s; silence for 20 s drops a connection (clients ping every 5 s).
- A request repeated with the same id, kind and arguments gets the stored answer (safe retransmission of purchases/intents).

## Requests (client -> server). Replies are `{"ok": true, ...}` or `{"ok": false, "error": code, ...}`.
| kind | needs login | args | reply |
|---|---|---|---|
| `hello` | no | `version`, `data_hash` | `server_time`, `version` (or `outdated_client` and the connection is closed) |
| `ping` | no | - | `time` |
| `server_status` | no | - | `uptime, peers, version, accounts, online, rooms, duels_finished, queue_ranked, queue_casual, last_backup` |
| `register` | no | `name` (3-16: letters, digits, space, _ -), `password` (0-64, may be empty) | `token`, `account` (logs in) |
| `login` | no | `name`, `password` | `token`, `account`; failures wait 1, 2, 4... s (`rate_limited`, `retry_after`) |
| `login_token` | no | `token` (single use, 24 h) | new `token`, `account` |
| `logout` | yes | - | - |
| `account_summary` | yes | - | `account` {id, name, dp, rating, best_rating, wins, losses, draws, streak, ranked_games} |
| `shop` | yes | `method`, `args` (below) | per method |
| `queue_join` | yes | `mode`: ranked / casual / practice | `mode` or `room_id` (practice); `deck_invalid` + `reason`, `in_queue`, `already_in_duel` |
| `queue_leave` | yes | - | - |
| `room_intent` | yes | `room_id`, `kind`, `args` (duel intents, below) | ok or `illegal_action` / `not_your_turn` / `not_your_decision` / `invalid_args` / `not_in_duel` (+ `reason`) |
| `room_rejoin` | yes | - | `room_id` and a full resend of the duel |
| `leaderboard` | yes | `limit` (1-100), `offset` | `rows` [{rank, name, rating, wins, losses, draws}], `total` |
| `my_rank` | yes | - | `rank` (0 = unranked), `rating`, `total` |
| `dev_start_bot_duel` | yes | `deck_preset?`, `bot_preset?`, `seed?` | `room_id` (only with `--dev`) |

Shop methods: `get_profile`, `get_catalog`, `get_product_contents {product_id}`, `purchase {product_id}`, `get_collection`, `get_deck`,
`save_deck {deck: {main, extra, side: [card numbers]}}` (checks ownership, copies per name, Fusion routing, section sizes; not the 40 minimum).
Cards travel as Konami card numbers. Purchases and deck saves are refused (`busy`) during a duel.

## Pushes (server -> client)
`room_start {room_id, mode, state, you, opponent{name, rating, bot}}`, `room_janken {phase: pick|order, tie?, picks: [mine, theirs], you_won?}`,
`room_batch {room_id, seq, events, state, resync?}`, `room_result {you_won, draw, reason, turns, mode, rating_before/after/delta?, dp_reward, dp, no_contest?}`,
`queue_status {mode, waiting, in_queue, cancelled?}`, `kicked {reason}`, `server_closing`.

## Duels
- `DuelRoom` (server) owns one `Duel`. Flow: janken (both pick 0 rock / 1 paper / 2 scissors; ties repeat) -> the winner chooses first/second -> the starting
  picture (full decks, empty hands) -> the opening deal -> play.
- Intents: `janken_pick {hand}`, `choose_order {first}`, `summon {uid, tributes[], zone, face_down}`, `set_spell_trap {uid, zone}`, `change_position {uid}`,
  `activate {uid, idx}`, `attack {uid, target (-1 = direct)}`, `to_battle`, `to_main2`, `end_turn {discards[]}`, `respond {answer}`, `surrender`, `resync`.
  Every one is re-validated with the same engine calls the offline game uses; answers are coerced to the shape the pending decision expects.
- The server never waits for animations (presentation barriers off) and plays CPU seats inline with the offline AI (JoeyAI).
- After every change each human seat gets its own `room_batch`. `state` is built by `DuelSnapshot` from **that seat's point of view (it is always player 0)**:
  opponent hand, both decks and the opponent's Fusion deck are uids only (decks in a random order); the opponent's face-down cards show only zone and position;
  graveyards, banished and face-up cards are public; `known` adds identities revealed in this batch (reveal effects, excavate) and the seat's own selection candidates;
  `legal` holds the server's answers to the board's rule questions (summon problems, tributes, can attack, direct attack, activatable effects, hand excess).
  Events carry only uids, never card identities. Card uids are shuffled per duel, so a uid tells nothing about the card.
- Timers: 60 s per decision, 240 s for your own turn, +15 s grace for animations, 15 s for janken/order. A timeout answers safely (pass/no/first choice)
  or ends the turn; 3 consecutive timeouts lose the duel. A disconnected player has 90 s to come back (token login), then loses.
- `RemoteDuel` (client) extends `Duel`, so the existing `DuelBoard` plays online duels unchanged: batches are queued and applied when the board drains events,
  card objects persist per uid, actions become intents, and input is blocked while an intent is in flight.
- No-contest: a server shutdown or a stuck rules engine ends the duel with no rating change, no rewards and no win/loss.

## Matchmaking and ranked
- Ranked: pairs players whose rating gap is within `100 + 25 x seconds waited` (cap 600) for both. Ranked decks must pass every deck rule
  (40-60 Main, Fusion/Side <= 15, copies per name under the limited/forbidden list, owned cards).
- Casual: pairs any two players at once; after 30 s alone you get the CPU. Only the 40-card minimum is checked.
- Practice: an immediate duel against the CPU (no rewards).
- Elo: start 1500, K = 40 for the first 20 ranked games then 32, floor 100. Only ranked human-vs-human duels change ratings.
- Rewards: ranked win +50 DP, ranked loss +10, casual win vs a human +20, first win of the UTC day +100 (ranked/casual vs humans).
- Every finished duel is a line in `<data>/matches/<yyyy-mm>.jsonl` (written before profiles change).

## Server data and operations
`<data>/config.json` (all tunables, written with defaults on first run), `accounts/` (profile with hashed password, collection, deck, purchases),
`matches/`, `logs/server.log` (rotated at 5 MB), `logs/audit.log` (registrations, logins, failed logins, purchases, duel results), `backups/<date>/` (daily, newest 7).
At startup every account file is checked: damaged files are moved to `<file>.corrupt-<time>` (never overwritten) and the account index is rebuilt from the folders.
All saves are written to a temporary file and renamed. Shutdown (window close / SIGINT) cancels queues and ends running duels as no-contest.

## Security notes
- Passwords: optional for now; non-empty ones are salted PBKDF2-HMAC-SHA256 (10 000 iterations), compared in constant time, never logged.
- One session per account (a new login kicks the old). Tokens are random 256-bit, single use, 24 h, in server memory (a server restart logs everyone out).
- The client is never trusted: no prices, balances, results or card lists are accepted from it; all randomness is server-side.
- Clients whose card/rules data differ from the server's are refused at hello.

## Tests
`bash tools/run_all_tests.sh` runs everything (each script with a 90 s timeout). Online tests: `tests/online/test_*.gd`.
Soak: `godot --headless --path . -s tools/online/soak.gd -- <minutes> <clients>`. CPU robustness: `godot --headless --path . -s tools/online/bot_duels.gd -- 200`.

## Known limitations
- No web export yet (skipped on request); the transport is ready for it (WebSocket), the UI would need bundled fonts instead of system fonts.
- No password reset, email, friends, chat, spectators, replays, seasons; one deck per account.
- Tokens are in memory only; JSON files are the database (the `AccountStore` API is the seam for a real database).
- Animations of the board run from the server's batches; small presentation differences from offline play are possible where the offline engine paused mid-action for an animation.

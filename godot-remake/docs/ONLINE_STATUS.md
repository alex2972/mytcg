# Online: status

Branch `online` (local only, nothing pushed). Plan: `docs/ONLINE_PLAN.md`. How it works: `docs/ONLINE.md`. Decisions: `docs/ONLINE_DECISIONS.md`.
User overrides: no web build (phase 8 skipped), no pushing.

## Phase checklist
| Phase | State |
|---|---|
| 1 Transport, server skeleton | done (WebSocket + high-level RPC, hello/version/data hash, rate limit, strikes, timeouts, logs, config) |
| 2 Accounts and auth | done (register/login/token/logout, optional passwords hashed with PBKDF2, login delays, one session per account, login screen) |
| 3 Remote data and shop | done (shop, collection, deck on the server; card numbers on the wire and in files; idempotent requests) |
| 4 Authoritative duel rooms | done (janken, intents, CPU seats, timers, disconnect grace, reconnect, surrender, hidden-info filter) |
| 5 Client duel | done (RemoteDuel extends Duel so the board is unchanged; janken online; online duel screen) |
| 6 Matchmaking and ranked | done (ranked window, casual, CPU fallback, practice, Elo, rewards, match log, leaderboard, lobby) |
| 7 Hardening and operations | done (fuzz test, damaged-file quarantine + index rebuild, daily backups, no-contest shutdown, TLS, deploy kit, memory leak fix) |
| 8 Web client build | skipped on request |
| 9 Soak, docs, handover | done (soak tool, ONLINE.md, this file) |

## Results
- Test suite: `bash tools/run_all_tests.sh` -> 75 test scripts (including 9 online files), all pass. The one intermittent failure seen
  (`tests/test_deck_editor.gd` "drawer animates instead of jumping", a frame-timing check older than the online work) passes when rerun alone.
- Soak (`tools/online/soak.gd -- 4 8`): 4.3 min, 8 clients, 70 duels (42 ranked, 28 casual) through the real protocol, 38 rooms, 0 stuck,
  0 errors, rating changes sum to 0. Memory grew 81 -> 117 MB in that run, which led to the `Duel.dispose()` fix (30 CPU duels: +11.4 MB before, +2.8 MB after).
- Soak after the fix (`-- 3 8`, the soak's clients now dispose their duels as the real duel screen does): 3.5 min, 72 duels (46 ranked, 26 casual),
  36 rooms, 0 stuck, 0 errors, 0 refusals, rating sum 0; memory 81.6 -> 84.7 MB, no objects leaked at exit.
- CPU robustness (`tools/online/bot_duels.gd -- 200`): all 200 duels finished; the 14 CPU stalls seen before the `CardAI` fix were Fusion Gate retry loops
  and a progress check that ignored closing response windows (both fixed; 80 seeded duels then ran clean).
- Hidden information: 16 duels, ~12 000 card entries checked against the server's real state, no leaks.
- Real window: lobby -> janken -> board -> summon -> surrender -> result checked with `tools/online/shot_online.gd`.

## Not verified here
- Docker/Caddy deployment (no Docker in this environment); the files are in `deploy/`.
- Two humans on two machines over the internet (tested with in-process clients over localhost WebSocket).

## Open items / ideas
- Web export (needs export templates, bundled fonts instead of system fonts, an audio-unlock click).
- Persistent tokens (a server restart logs everyone out; clients fall back to the login screen).
- A real database behind `AccountStore` when the player count grows; multiple deck slots; friends/chat/spectators; seasons.
- The soak's CPU-like clients are simple; a human-like client could find more rule-edge refusals.

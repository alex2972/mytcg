# Original AI: where it lives (found by reverse engineering joey_pc.exe)

There is NO AI data file. `data/J/file/cpu_*.ydc` are only the opponent decks. The AI is code plus one table.
Addresses are virtual (image base 0x400000). Decompile dump: `analysis/decomp.c`, `analysis/funcs.pkl`.

## Game state (globals, no classes)
- Per-player block stride `0xd44` bytes (`DAT_00a55d74 + player*0xd44`); monster zones stride `0x48` bytes, 5 zones.
- `_DAT_00a54e5c & 1` = the human player. Messages are only shown when `player == human`.
- `FUN_004022e0(card)` reads `CARD_ID.bin` (card index -> card id used everywhere in AI/effect code).
  `FUN_004026c0(card)` = level (0-4 normal, 5-6 one tribute, 7+ two tributes). `FUN_004027b0/402800` = ATK/DEF.

## Per-turn CPU main phase: `FUN_005b72a0` (NOT in the Ghidra function list; created by `tools/scripts/ExportAt.java`,
decompile saved in `analysis/ai_main.c`). It is a state machine on `_DAT_00a579a2 & 0xff`:
| state | does |
|---|---|
| 0 | decide first action: spell/trap activation check, then `FUN_005b1360` (evaluate summon candidates by simulation), then `FUN_005b6ff0` executes |
| 1 | `FUN_005b08b0` |
| 2 | `FUN_005b6690` |
| 3 | `FUN_005b6630` |
| 4 | **choose a monster to summon**: `FUN_005b16c0` returns the hand index, `FUN_005b6ff0` summons/sets it (tributes picked by `FUN_005aece0`) |

## Key AI functions
- `FUN_005b16c0` (summon choice): hard-coded priority list of card ids (e.g. 500, 0x21c, 0x1ab, 0x65 ...) via `FUN_0056d340(player,id)`
  when board conditions hold (opponent monsters, LP, spell counts); otherwise picks the hand monster with the highest
  max(ATK,DEF) that beats the opponent's best monster (`FUN_0056f690`) and is legal (`FUN_005aab90`).
- `FUN_005b1360`: tries each hand card, simulates the board (`FUN_005b08e0/09c0/0a50/0950`) and keeps the best evaluation.
- Legality / "can I do this" bitmask (also drives the hover cursor): `FUN_005a02a0` -> `FUN_005aab90` (summon/set), `FUN_005aae00` (spell/trap).
- Hand/board scans: `FUN_0056a000`, `FUN_00569d50`, `FUN_0056a030`, `FUN_005ae9c0`, `FUN_005ae3e0`.

## Per-card AI table (the "when to use this card" logic)
269 entries of `(handler_function, card_id)` at file offset `0x1dd11c..0x1dd984` (8 bytes each, `card_id` -> card via `card_id.bin`).
Saved as `analysis/card_ai_table.pkl`. Handlers: 0x581040 = default (68 cards), 0x5b5a20 (41), 0x5b48d0 (14), 0x5b5010 (13),
0x5b4860 (10), 0x5b2e60 (9), 0x5b5b80 (9) ... in 0x5b1b50-0x5b5b80. Examples: Call Of The Haunted -> 0x5b2640,
Skull Dice -> 0x5b2e60.

## Still to do
1. Decompile the remaining handlers (some may also be missing from Ghidra's function list -- use `ExportAt.java`).
2. Callers of `FUN_005b3fa0` (0x5939c6..0x597599) look like the chain/response AI.
3. Port: summon choice + attack choice + per-card handlers into `core/ai/`.

## Port status (core/ai/joey_ai.gd, used by the duel board for the opponent)
Ported: attack planner (005b0b90/0d90/0f40/05a0, incl. "face-down enemy = 1000/1900"), summon-for-attack simulation (005b1360),
general summon choice + flip-effect priority list (005b16c0), attack/defense/set decision (005ae0a0/ae270/adec0),
flip and reposition passes (005b77f0), tribute choice (005aed60). `FLIP_IDS` is the id list from 00567620.
Approximated: 005ae3e0 veto list (only Exodia pieces and a few flip monsters), 005ae9c0 special tribute preferences,
005b05a0 special-card cases, "can reposition" checks (assumed true).
NOT ported: the 269-entry per-card handler table (spell/trap/effect timing) and the chain/response AI (FUN_005b3fa0 callers);
those still use SimpleAI.use_effects ("use anything harmless").
Check: tests/test_joey_vs_simple.gd (Joey beat the old placeholder 13-7), tests/test_ai_duel.gd (duels now last ~11 turns instead of ~69).

## Per-card AI (core/ai/card_ai.gd, data/ai_cards.json)
Table entries are (card id u16, pad, handler u32) at 8-byte stride; groups = standby 0x5dd3c8, main 0x5dd4c0, main_s2 0x5dd858, end 0x5dd8d0,
chain_response 0x5dd0a8, tbl_5dd308 (responses to spells). The AI only ever uses cards listed there. (An earlier note paired ids with the
wrong handlers; analysis/card_ai_groups.json has the correct pairing.)
Ported handlers: 581040 (always), 5b5a20/5b5a60/5b5ab0 (equip/curse: target ATK > 1299), 5b5010 (field spell), 5b48d0 (heal, held while Fire Princess is in
hand/deck), 5b4860/5b5b80 (targets exist / would not hit my own), 5b2640 (all 18 attack-time traps), 5b2e60 (battle boosters, approximated on
attack_declared), plus single-card ones: Sebek's Blessing, Just Desserts, Card of Safe Return, Tremendous Fire, Harpie's Feather Duster, MST (standby),
Heavy Storm, Soul Release, The Dark Door, Swords of Revealing Light/Nightmare's Steelcage, Dark Hole, Raigeki, Final Destiny, Change of Heart,
Share the Pain, Mystic Box, Monster Reborn, Block Attack, Card Destruction, Giant Trunade.
Not ported: the ~60 handlers for cards without effect data yet (they fall back to "use if harmless" / "yes"), MST as a response (5b1f10, 5b3210).

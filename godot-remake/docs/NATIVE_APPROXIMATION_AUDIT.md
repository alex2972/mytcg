# Approximation audit against the original executable

The source is Ghidra pseudocode from Joey the Passion, not recovered original source or an observed original-game run. Binary SHA-256: `c5749eb934a1cf68d9236e44ff81e98b8aaee486b4f8ebd417440505d44ac1ea`.

Native effect callbacks were recovered from the 443-row table at `0x005ed0a8` (24-byte records), using `FUN_0059dbe0`. Additional functions were exported from the existing Ghidra project in read-only mode. The project database and executable were not modified. Exports: `Z:/process/analysis/all_approximation_handlers.c`, `native_approximation_handlers.c`, and `approximation_handler_map.json`. A missing table callback does not prove a card has no effect; shared turn/battle code can implement it.

## Implemented and tested

See [battle audit](NATIVE_BATTLE_AUDIT.md), [summon audit](NATIVE_RULES_AUDIT.md), and [targeting audit](NATIVE_TARGETING_AUDIT.md) for their source functions and limits.

- Mirror Wall, Metalmorph, Copycat and Mage Power now use the native stat rules.
- Jam Breeding Machine and Scapegoat now use the native summon restrictions, including Scapegoat's eligibility and resolution rechecks.
- De-Fusion offers optional revival and individual positions; Chosen One follows hidden choice, reveal, discard, then position; Tailor checks the Equip restrictions before the response chain.
- Garuda offers the native yes/no prompt. Barrel Dragon's existing three coins need no call, so that stale gap was removed.
- Time Wizard (`FUN_005835f0`), Fairy Box (`FUN_0058da80`), Goddess of Whim (`FUN_00585540`) and Gamble (`FUN_0058ed20`) request a coin call with `FUN_005bf9a0(7,0)`, store the call in `DAT_00a558b4`, then compare it with the random result from `FUN_005bddb0(2)`. The remake now offers Heads/Tails before the toss and chooses success/failure based on that call. Actual coin outcome and correctness are recorded separately.
- Spear Cretin and The Immortal of Thunder now require flipped history in the grave-transition event, surviving field cleanup and resetting when Set again. Native `FUN_00577cf0` gates their grave trigger on byte 7 mask `2`; `FUN_0056af90` reinitializes that guard when resetting a monster face-down. `FUN_0058b3d0` handles Spear's grave trigger, and `FUN_00585970` distinguishes Immortal's grave LP loss from its flip LP gain. The guard's complete interaction with negated Flip effects still needs tracing; no claim of complete native timing parity is made.
- Lightforce Sword (`FUN_00587e80`) encodes `((~controller XOR turn_player) & 1) + 6` turn ticks before return. The remake now returns on the affected player's fourth turn: six global turns when activated during that player's turn, seven otherwise. Regression scenarios check both activation sides and every preceding turn.
- Major Riot (`FUN_0058bb10`, state `0x7e`) clamps return counts to eligible hand monsters and available zones. `FUN_00581790` compares the bounced monster's previous controller with the Trap controller, and the effect controller with the opponent; it does not require ownership of the bounced monster. Both are now matched. Last-action timing remains explicitly unverified.

## Remaining limits

This audit resolves sixteen old gap entries and narrows additional entries; it does not establish complete executable parity. Remaining approximations stay in `data/approximations.json`. In particular, shared phase consumers for Solomon's Lawbook and Sinister Serpent, Spell/Trap redirection for Shift, actual Fusion material history, special Equip predicates, and exact queued event order need more tracing. The AI in `core/ai/` was not edited.

Validation: `test_native_battle.gd`, `test_native_rules.gd`, `test_native_targeting.gd`, `test_native_coins.gd`, `test_native_history.gd`, plus all handoff and existing UI suites.


## Completed validation

All 33 suites passed on 2026-10-10: the 28 existing handoff/UI suites and all five new native comparison suites. Effect names match the card database; preset decks and the 350-card Card List still have zero missing effects. There are 54 card gaps and nine rule gaps left in the approximation register. Existing Godot shutdown resource-leak warnings remain outside this change.

Mapping caution: `FUN_004022e0(index)` returns the official card number. `FUN_00402460(number)` uses `CARD_IntID.bin` indexed by number modulo 2000 to recover the card index (plus one for numbers at least 2000). The existing `cards.json.intid` field is indexed differently by `build_data.py` and must not be treated as the native effect-table key. No card metadata was changed in this audit.

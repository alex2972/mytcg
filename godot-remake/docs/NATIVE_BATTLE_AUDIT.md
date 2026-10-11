# Native battle approximation audit

Static evidence from `Z:/process/analysis/decomp.c` (Joey executable export); this audit does not claim a runtime comparison.

## Confirmed fixes

- **Mirror Wall:** `FUN_0056dd30`, lines 219024–219047, sums the card's stat changes and clamps negative ATK before applying each Mirror Wall reduction. Temporary and equip changes therefore participate in the halving. `FUN_005be050`, lines 244463–244469, evaluates `(value * 5 + 5) / 10`, rounding nonnegative odd ATK upward. The remake now performs this final calculation and supports successive Walls.
- **Metalmorph:** `FUN_005b7c50`, lines 239688–239698, computes half of the defending monster's current ATK, multiplies by the attacker's active Metalmorph count, halves that bonus separately for each applicable Mirror Wall, then adds it to the attacker's already-adjusted ATK. No target means no extra bonus (early direct-attack branch, lines 239602–239607). The remake now follows this calculation.

`tests/test_native_battle.gd` covers current modifiers, odd rounding, two Walls, attacker/defender/direct distinctions, and resulting battle damage/destruction.

## Additional source leads, not yet implemented here

- **Sword of Dragon's Soul:** `FUN_005b8210`, lines 239945–239956, schedules the opposing Dragon's destruction while calculating an individual battle. The battle state's case `0x1c` invokes this function at lines 240465–240466. This places the native processing in battle resolution; a complete event-order trace is still needed before replacing the remake's Battle Phase-end flag.
- **Spear Cretin / The Immortal of Thunder:** grave transition `FUN_00577cf0`, lines 222210–222241, suppresses their triggered effect if bit 2 of the card record's byte 7 is set. `FUN_00576f40`, lines 221649–221660 and 221695–221696, shares the guard. `FUN_0056af90`, lines 216431–216465, sets this bit for these cards when resetting a face-down monster. Establish the flip/summon clearing path before assigning the precise meaning of the bit.
- **Big Shield Gardna:** `FUN_00583510`, lines 225001–225014, confirms a face-down target check and automatic spell negation/face-up defense. Its battle position-change timing needs the function-table/event-order trace.
- **Slate Warrior:** `FUN_0056dd30`, lines 218937–218942, stores the -500/-500 as persistent modifier kind `0xb`; mutual-destruction trigger eligibility needs tracing beyond this stat consumer.
- **Fairy Box:** the stat consumer sets ATK to zero at lines 218849–218854; maintenance `FUN_005a8040`, lines 232643–232644, charges 500. Coin-call interaction and result duration remain unverified.
- **Red-Moon Baby:** no reliable handler identification in this audit; its delayed revival should not be inferred merely from current card text.

## Additional confirmed fixes and verification

- **Copycat:** `FUN_0058e790` in `analysis/all_approximation_handlers.c` encodes the selected target's card index with `0x6000` in modifier kind `0xb`. `FUN_0056dd30`, `decomp.c` lines 218863–218867, interprets that encoding by fetching printed ATK/DEF with `FUN_004027b0` and `FUN_00402800`. The remake now uses original values and has a regression against both persistent and temporary changes on the selected monster.
- **Mage Power:** `FUN_0056dd30`, lines 218789–218793, calls `FUN_0056a320(equip_controller, 0, 0, 1)` and adds the count times 500 to both stats. That counter iterates occupied positions 5 through 10 inclusive: all five Spell/Trap zones and the Field Spell zone, including Set cards. The remake now includes the Field Spell and uses the equip card's controller when it is attached to an opposing monster.
- **Barrel Dragon:** `FUN_005871a0` in `analysis/all_approximation_handlers.c` calls `FUN_005bddb0(2)` three times, counts results equal to zero, emits the three-result display event `0xe1`, then destroys the target only if the count exceeds one. Its selection handler `FUN_00593970` calls the ordinary targeting chooser. There is no heads/tails call decision in this path. The remake's three random rolls with a two-success threshold match this behavior; the logged no-call concern can be removed.

The native battle suite passes after the duel engine's damage-calculation hook snapshots stats before clearing the active attack. It also checks Copycat and Mage Power's original-stat/count behavior.

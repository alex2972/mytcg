# Summon restrictions checked against the original executable

Static evidence from `analysis/decomp.c`, supplemented by targeted Ghidra exports in `analysis/native_approximation_handlers.c`. This is a source audit, not a recording of the original game running.

The card effect table at virtual address `0x005ed0a8` has 24-byte records keyed by the official card number. `FUN_0059dbe0` (decomp.c lines 230025-230063) searches this table. `FUN_004022e0` reads CARD_ID.bin and converts a card index to its official number. CARD_IntID.bin is the inverse lookup indexed by official number; the `intid` metadata in cards.json must not be used as that return value.

## Jam Breeding Machine

Official number `0x592`. `FUN_00570a70` (decomp.c lines 219928-219944) rejects Normal Summons when the controller has this face-up card. `FUN_00570b40` (219983-219997) separately rejects Special Summons. `FUN_005a0530` (231632-231648) checks the normal gate before offering a Flip Summon. The opponent is not restricted.

Setting remains legal: `FUN_005b6ff0` (239394-239410) switches to the Set option when the normal gate rejects Summoning. The remake now blocks Normal, Flip and Special Summons for the controller, permits Sets, and permits the machine's own Slime Token creation. The effect is inactive when the continuous Spell is negated.

## Scapegoat

Official number `0x76e`; table callbacks `FUN_0058e670` and `FUN_005821a0`, exported separately because the original bulk decompile omitted them. The eligibility callback requires at least four free Monster Zones, checks controller bit `0x10000` (a prior Summon), and checks the Special Summon gate. The resolution callback repeats those checks, creates four Sheep Tokens, then sets player rules 20 and 21 with `FUN_00579930`.

`FUN_00579930` (decomp.c 223167-223176) sets the numbered player flag; the normal gate checks bit 20 (`0x100000`) and the Special Summon gate checks bit 21 (`0x200000`). The same normal gate controls Flip Summons. Sets remain legal. The remake records successful Normal/Flip/Special Summons throughout the current turn, rejects activation after one, repeats eligibility at resolution, creates all four tokens, then blocks further Summons until cleanup.

Tests: `tests/test_native_rules.gd` covers both cards, opponent independence, Sets, Flip Summons, normal/special summons, token creation and negation.

## Remaining uncertainty

Solomon's Lawbook callback `FUN_0058a660` sets player flag 2, but the consuming turn phase has not been traced, so this audit does not establish its exact skip timing. Last Will callbacks `FUN_00589610`/`FUN_00581050` show an installed rule and later optional summon gated by flag `0x1000000`; its complete cleanup lifetime needs tracing. Dimensionhole callback `FUN_0058f2d0` stores identity information with rule `0x23`, but reserved-zone return has not been fully traced. These gaps remain logged. No AI files were changed.

## Garuda the Wind Spirit

`FUN_0057cd40` in `analysis/all_approximation_handlers.c` shows the original asks a yes/no question before selecting a monster: prompt `0xfa`, `FUN_005bf9a0(1,0)`, followed by `-1` on decline and `1` on acceptance. `FUN_0057b1f0` restricts targeting to the opponent's face-up monsters. The remake now uses that explicit optional prompt before selection; the regression suite covers both choices.

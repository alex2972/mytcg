# Remaining Card List effects: implementation handoff

Implemented in batches 18-20, in the missing-card report's priority order: Bait Doll; Wall Shadow, Major Riot, Perfectly Ultimate Great Moth; Prohibition, Inspection, Scroll of Bewitchment, Deepsea Warrior, Jam Defender, Manga Ryu-Ran, Insect Imitation, Makiu, Magical Labyrinth and Spirit Elimination. Cocoon of Evolution was added as the required support for the Moth summon chain.

`tools/list_missing_effects.py` now reports zero missing preset-deck effects and zero missing Card List effects. There are 125 cards outside those pools, which were not part of this request.

## Engine changes required by these cards

- Summon procedures, eligibility checks and persistent proper-summon history; Cocoon evolution counts actual controller turns and resets when the Equip is lost.
- Source-aware Spell immunity for Deepsea Warrior (including field/equip modifiers), effective Attribute queries for Scroll, Prohibition's play restrictions and pre-existing field exemptions.
- Manga Ryu-Ran's Special Summon, two Tributes, summon-turn attack restriction, 500 LP attack cost and Toon target rules; the board offers direct attacks through opposing non-Toons.
- Spirit Elimination substitutes monsters on the field for graveyard banish costs while preserving the original Type/Attribute restriction. Unrestricted effect removals prompt for field substitutes; removed Tokens disappear.
- Major Riot uses returned-to-hand event controller/source information, reveals hands and offers face-down Defense summons. Fusion cards return to the Extra Deck and do not count as cards returned to the hand.
- Bait Doll forces Trap resolution without an additional chain. Forced counter-Traps cannot negate an already resolving Bait Doll. Jinzo/Royal Decree suppress Trap effects while active.
- Inspection can be used repeatedly, with a fresh optional response window after each privately acknowledged reveal.

No files in `core/ai/` were edited. Existing AI answers still use the same select/choice/yes-no/chain protocol.

## Tests and visual checks

New suites: `test_effects13.gd`, `test_effects14.gd`, `test_effects15.gd`, `test_remaining_effect_ui.gd`. All suites required by HANDOFF_EFFECTS.md were run, along with the newer effects10-15 suites and the presentation/discard regressions: 28 suites in total. Logs are saved in `Z:/process/scratch/effect_port_tests/`.

Prohibition's searchable catalogue and Inspection's private card-art reveal were rendered and visually checked through `screenshot_remaining_effects.gd`. Captures are in `Z:/process/scratch/codex_ui/prohibition_picker.png` and `inspection_reveal.png`.

## Recorded approximation

Major Riot currently uses the existing queued return-to-hand window after chain resolution, without testing whether the return was the resolving effect's final action. This is recorded under `RULE: remaining-effect native parity` in `data/approximations.json`, and the generated approximation document has been refreshed. Native executable timing still needs tracing for that edge case.

Known shutdown resource-leak and audio-startup diagnostics also appear in existing suites; test assertions and exit codes pass.

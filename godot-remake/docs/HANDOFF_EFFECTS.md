# Handoff: finishing the card effects

You are continuing a Godot 4 (GDScript) rebuild of a 2004 PC game, Konami's *Yu-Gi-Oh! Power of Chaos: Joey the Passion*. The owner is the
original developer and has Konami's permission; the project is private and non-commercial. Goal: the same behaviour a player sees in the original,
with simpler, data-driven code (it is NOT a 1:1 port of the code).

## Read first
- `docs/EFFECTS.md` - the effect language (JSON in `data/effects/*.json`, keyed by English card name). Sections "Added in batches ..." list newer ops.
- `docs/APPROXIMATIONS.md` (source: `data/approximations.json`) - what is already implemented only approximately.
- `docs/DUEL_FLOW.md` - the original's response windows; `docs/AI_NOTES.md` - the original AI (already ported to `core/ai/`).
- `core/effects/` (`fx.gd` chains/windows, `fx_ops.gd` verbs/filters/conditions, `fx_custom.gd` one-off ops) and `core/duel.gd` (rules engine).

## What is left
Run `python tools/list_missing_effects.py` (add `--all` for everything). At the time of writing: ~12 cards of the preset decks
(Chosen One, Bait Doll, Gryphon Wing, Kotodama, Return of the Doomed, Gilasaurus, Respect Play, Sword Hunter, Big Shield Gardna, Supply, ...),
then ~70 more in the 350-card Card List, then ~130 others. Work in that order. Implement every card text faithfully; if you must simplify,
write it down (see "Approximations" below).

## How to add cards
1. Write the effect JSON in a new `data/effects/batchNN.json` (copy the style of `batch3.json`...`batch12.json`). Use existing ops where possible.
   A new verb/filter/condition goes into `core/effects/fx_ops.gd` (or `fx_custom.gd` for a one-off); document it in `docs/EFFECTS.md`.
2. Add a test scenario to a `tests/test_effectsN.gd` file (copy `tests/test_effects8.gd`: helpers `new_duel`, `mon`, `settle`, `next_turn`).
3. Card names must match `data/cards.json` exactly (e.g. "Alpha The Magnet Warrior" with a capital T). A wrong name silently does nothing,
   so after editing run the name check below.
4. If the card is in the AI's table (`data/ai_cards.json`), its AI decision lives in `core/ai/card_ai.gd` (handler = last 6 hex digits of the
   original handler address; handler code dumps are in the owner's `analysis/` folder if available). Unported handlers fall back to "use if harmless".

## Approximations (important)
Whenever you implement something approximately (missing part of the text, simplified timing, assumption), add it to `data/approximations.json`
(card name or "RULE: ..." -> "gap", "fix") and run `python tools/list_approximations.py`. Do it at the moment you write the approximation.

## Running things (Windows)
- Godot: `Z:\godot\Godot_v4.7.1-stable_win64_console.exe` (headless) / `...win64.exe` (window). Python: use the full path of python.exe.
- Test one suite: `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s tests/test_effects8.gd`; the last line says OK or N FAILED.
  Run ALL suites before finishing: duel, effects, effects2..effects9, battle_steps, ai_responses, ai_duel, board, board_effects, sword, janken, deck_editor, approximations.
- After adding a new `class_name` script run once: `Godot... --headless --path . --import`.
- Synthetic mouse clicks do not work headless; tests call handlers directly.
- Tests set `board.ai_delay = 0.0`, which turns animations/dialogs off.

## Gotchas learned the hard way
- JSON numbers load as floats: `Array.has(5)` fails on `[5.0]`; compare with `int()`.
- GDScript warnings are errors in this project: give explicit types (`var x: int = ...`), avoid untyped `:=` from Variant.
- Cards leaving the field lose their `flags`; use the `sent_to_grave`/`destroyed` event data (`pos`, `was_face_up`, `killer`, `reason`) instead.
- `Fx.activating` queues events raised while a cost is being paid, otherwise a discard cost would resolve the chain early.
- Tokens (`Duel.TOKENS`) use CardDB index 0; the board removes their view when they vanish.
- Opening many response windows is cheap only because rare ones are gated by `fx.has_listener(event)`; do the same for new frequent events.
- In bash tool calls do not put two heredocs with the same delimiter in one command; write files with a file-writing tool.
- Do not touch: Joey voice lines, reaction scenes and cut-ins are intentionally skipped by the owner.

## Name check (run after editing effect files)
```python
import json, glob
cards = {c["name"]["eng"] for c in json.load(open("data/cards.json", encoding="utf-8"))["cards"] if "name" in c}
for f in glob.glob("data/effects/*.json"):
    for k in json.load(open(f, encoding="utf-8")):
        if not k.startswith("_") and k not in cards:
            print("unknown card name:", f, k)
```

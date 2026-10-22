# Original duel flow (what we know so far)

Sources: the decompile (analysis/decomp.c), the AI tables (docs/AI_NOTES.md) and the game's own message strings (data/strings.json, ids 169-199, 248, 265, 266).

## Response windows the original announces (string id: "message")
169-176 Summon / Flip Summon / Special Summon / Set (you vs opponent, +1 for the opponent) · 177 "The target for attack is X" · 178 monster's position changed ·
179 monster flipped face-up · 180 control switched · 181 reverse (flip) effect activated as the result of battle · 182/183 declared battle ·
184 monster destroyed as a result of battle · 185/186 battle damage taken / dealt · 187/188 deflected damage · 189/190 effect damage ·
191 Spell destroyed · 192 Trap destroyed · 193 continuous Trap played · 194 continuous Spell played · 195 Field Spell played · 196 equipped ·
197/198 a player drew a card · 199 a monster returned to the hand. Strings 248/265 are the "change the target of attack?" questions (Magic-Arm Shield, Shift...), 266 is the damage step comparison "Attack side: X versus Defense side: Y".

## Implemented in our engine
attack_declared, damage_step (new, before damage; shows string 266), summoned / flip_summoned / special_summoned, flipped, damaged, destroyed, sent_to_grave, position_changed,
drew, discarded, healed, standby_phase, end_phase, activated_spell / activated_trap.
Added since: damage_step (second battle window), target_declared (177, Shift answers it), monster_set (175/176), control_switched (180), equipped (196), returned_to_hand (199);
the last four only open while a card on the field listens for them. Battle destruction (184), battle damage (185/186), effect damage and Spell/Trap destroyed (191/192) are covered by
`destroyed` / `damaged` with their reason; played continuous cards (193-195) have no window yet.

## Turn sequence per player (from the AI's phase table 0x5efb50 and the engine's phase table 0x5efa68)
Draw, Standby (standby-group cards), Main 1 (spells, summons), Battle (declare, target, damage step), Main 2 (summon/Set, reposition), End (end-group cards).

## UI timing and normal summon placement
The board awaits each phase/next-turn banner before processing the next event or permitting another action. Result music plays once. Tribute summons without an explicit zone reuse the leftmost eligible offered monster zone, independent of tribute selection order; Soul Exchange falls back to a free own zone if all offerings are on the other side.
Graveyard and Extra Deck double-clicks open a read-only browser for either player, showing cards top-first with five cards per page. Browsing pauses board input and the opponent's next action. Selection cursors use `on`; `act` is reserved for activating your own effects. Current ATK/DEF values above/below their printed values use the original blue/red digit sheets independently.

## Presentation barriers (reported gameplay regressions)
With `Fx.presentation_enabled`, End Phase, next turn, Draw Phase and Standby Phase each pause the engine through `after_presentation` before their continuation runs. Drawing cannot occur before the Draw Phase banner finishes. The board awaits its existing presentation and pauses its AI loop while animations or pile browsing are active. Engine-only tests remain synchronous.
Field views use current controller for positioning, while hand/graveyard use owner. A card has only one movement tween; later synchronization cancels the older tween. Graveyard/Extra Deck double-click input is intercepted before target selection and works during response dialogs and animations without answering or cancelling them.

## Card movement, response selection and deck shuffle
Card placement events animate their recorded destination before synchronizing final engine state. This also preserves hand -> field -> Graveyard movement for a Spell that resolves immediately. Normal Summons, Sets, played Spells, Field Spells and Special Summons use the same awaitable movement helper.
Accepting a human chain-response question enables board selection even with one available response. Offered cards show Activate; the effect starts only after clicking the card. Escape/right-click passes. With multiple effects on one card, clicking that card opens its effect choices.
The shuffle panel uses the original `deck_shuf_waku_?.png` and five `deck_shufN.png` frames. The archive's `j/duel/effect/shuffle.txt` is preserved in `data/native_shuffle.txt`. Native handlers 00453540/00453560 increment the counter by 8, end at 0x144, and select `(counter >> 3) % 5 + 1`; center X is 525 and Y is 300, with deck-to-center motion and a return. Wall-clock frequency and sound mapping still need runtime confirmation (registered in approximations). Shuffle ops pause subsequent effect steps while the animation plays; visual playback never modifies RNG or Deck contents.

## Opening deal and activation staging
The board creates a deferred duel with empty hands. The second player receives five cards first, then the first player receives five, with an engine presentation barrier after each individual draw. The first turn (including its extra draw) begins only afterward. Engine-only callers of `Duel.create` keep synchronous initialization unless `deferred_start` is requested.
Normal Spell/Trap activations have a presentation barrier after placement/turning face up and before costs, targets and chain resolution continue. The board completes the flip and one activation flash/sound before acknowledging it. Dice/coin barriers then hold stat/effect application until the outcome animation finishes. Decision button hover is silent; right-click answers No, and tribute instructions can be cancelled before entering selection. Selection keeps card artwork untinted. Friendly Set cards remain inspectable under the decision dialog.

The working deck is autosaved atomically to `user://working_deck.ydc`; both Deck Construction and the default duel deck reload it. Persistence tests use separate workspace files, never the player's save.

Idle attack swords remain visible on all eligible attackers throughout the human Battle Phase, including during target selection, prompts and animations. Eligibility uses the normal attack rules while ignoring the temporary busy-state guard for display only. The selected/current attacker is excluded to avoid duplicating its active/flying sword. Cancelling restores its idle sword; spent, blocked or removed monsters lose theirs.

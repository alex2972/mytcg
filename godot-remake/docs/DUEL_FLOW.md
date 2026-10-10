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

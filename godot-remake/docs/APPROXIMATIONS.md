# Approximations: things that are not yet like the original

Generated from `data/approximations.json` by `tools/list_approximations.py`. Do not edit by hand.

48 cards and 6 rules.

## Cards

| Card | What differs | What it takes to fix |
|---|---|---|
| Alligator's Sword Dragon | Face-down opposing monsters count as their real attribute when deciding if a direct attack is allowed. | Check what the original does with face-down monsters. |
| Aqua Spirit | The Standby Phase position-change effect is missing (only the special summon condition is in). | A trigger on the opponent's Standby Phase that lets the owner change one face-up monster's position. |
| Barrel Dragon | Coins tossed without a call (the original has no call here, so this may be exact). | Verify against the original. |
| Black Illusion Ritual | Relinquished's special effect is missing (it is only a 0/0 monster). | Implement Relinquished (equip and take over ATK/DEF). |
| Blue-Eyes Toon Dragon | The 'attack directly while the opponent controls no Toon monster' rule is missing. | As Toon Summoned Skull. |
| Copycat | Copies the target's current ATK/DEF (with modifiers) instead of the original values. | A 'base stats' value that ignores mods and equips. |
| Cyber Jar | Summon positions and the order in which the two players pick up cards are simplified. | Check the original's order and which player's monsters are summoned first. |
| DNA Surgery | Monster Type icons in the interface do not change. | Use Duel.race_of in the card detail panel. |
| Dark Necrofear | Only the special summon condition is in; the 'becomes an Equip Card and takes control' effect is missing. | Use become_equip plus a control link when destroyed. |
| Dark Spirit of the Silent | The new attacker keeps the original target instead of choosing again; its position is flipped quietly. | Check the original's sequence. |
| Destiny Board | The Spirit Message cards can still be played or Set by hand; only the board places them properly. | Forbid playing/Setting the Spirit Message cards manually. |
| Dream Clown | Only triggers when the player changes its position, not when an effect does. | Fire position_changed from force_position too (with a flag for effect-caused changes). |
| Earthshaker | The opponent's choice is labelled 'First/Second' instead of showing the two attributes. | Pass the chosen attribute names into the choice labels. |
| Exchange | The hands are not shown to both players. | A hand-reveal screen. |
| Fairy Box | The coin is tossed without the player calling Heads or Tails. | A 'call it' prompt before the toss. |
| Fusion Gate | Only used through an effect button; the original may offer it automatically. | Compare with the original's interface. |
| Gamble | Coin tossed without a call. | A 'call it' prompt before the toss. |
| Goddess of Whim | Coin tossed without a call. | A 'call it' prompt before the toss. |
| Ground Collapse | Only zones on the opponent's side can be blocked, and an occupied choice moves to the next free zone automatically. | A zone-picker UI for either side. |
| Gust | Triggers when any of my Spells is destroyed, not only when the opponent's card effect destroyed it. | Record who caused a destruction (effect owner) in the destroyed event. |
| Insect Queen | The Insect Monster Token appears immediately, not at the end of the turn. | Create the token in the End Phase. |
| Jam Breeding Machine | The restriction on summoning/special summoning monsters is missing; only the Slime Tokens are in. | Static rules for summon/flip/special summon limited to the controller. |
| Jirai Gumo | Coin tossed without a call. | A 'call it' prompt before the toss. |
| Last Will | Implemented as a continuous effect for the turn; needs checking against the original timing. | Verify with the original. |
| Lightforce Sword | The return turn (opponent's 4th turn) is computed as 7 turns later; not checked against the original. | Verify the turn count with the original and add a test. |
| Mage Power | Counts the Spell/Trap Cards in the Spell zone only (not a face-up Field Spell). | Include the field spell zone in the count. |
| Magic Thorn | Also triggers on discards paid as a cost, not only discards caused by Spell/Trap/Effect Monster effects. | Tag the discard reason (cost vs effect) and only count effect discards. |
| Magical Hats | The two decoys are tokens; the original takes 2 non-monster cards out of the Deck. | Move two Spell/Trap cards from the Deck onto the field as 0/0 monsters, return them afterwards. |
| Mask of Dispel | The card is only destroyed at the next Standby Phase after the selected Spell leaves the field. | A trigger on the selected card leaving the field. |
| Metalmorph | The extra ATK when attacking (half of the target's ATK) is missing; only the +300/+300 is in. | A battle-time ATK bonus on the equipped monster (needs the damage-step window). |
| Morphing Jar #2 | The card count each player picks up is an interpretation of an ambiguous card text. | Check how the original counts. |
| Patrol Robo | No effect at all (the peek at a Set card needs an interface). | A 'look at 1 Set card' prompt shown to the player during the Standby Phase. |
| Polymerization | 'Goddess with the Third Eye' / 'Versago the Destroyer' can be picked for more than one material slot. | Allow at most one substitute per Fusion. |
| Red-Moon Baby | The destroyed monster comes back immediately, not at the end of the Battle Phase, and always in Attack Position. | Queue the revival for the end of the Battle Phase and let the player pick the position. |
| Relinquished | Special effect missing. | Implement the equip and stat takeover. |
| Scapegoat | The 'no summons this turn' rule blocks Normal Summons/Sets only, not Flip or Special Summons. | Use a rule that also covers flip and special summons. |
| Shift | Redirects only to my other monsters, and is limited to monster attacks (not Spell/Trap targets). | Add target_declared events for Spell/Trap targeting. |
| Sinister Serpent | Returning to the hand is automatic instead of optional. | A yes/no prompt. |
| Slate Warrior | The penalty applies to whoever destroys it in battle, including in a mutual destruction. | Check the original for mutual destruction. |
| Soul of Purity and Light | The -300 ATK to the opponent's monsters during their Battle Phase is missing. | A static modifier that depends on the current phase/turn. |
| Spear Cretin | Also triggers if it was face-up without ever being flipped. | Remember that the card was flipped (survive the grave transition). |
| Spirit of Flames | The +300 ATK during my Battle Phase is missing. | A static modifier that depends on the current phase/turn. |
| The Rock Spirit | The +300 ATK during the opponent's Battle Phase is missing. | A static modifier that depends on the current phase/turn. |
| Time Wizard | Coin tossed without a call. | A 'call it' prompt before the toss. |
| Toon Mermaid | The 'attack directly while the opponent controls no Toon monster' rule is missing. | As Toon Summoned Skull. |
| Toon Summoned Skull | The 'attack directly while the opponent controls no Toon monster' rule is missing. | Use the direct_vs_attributes style rule with a Toon-monster check. |
| Valkyrion the Magna Warrior | Only the summon condition is in; the rest of the card text has not been read for details. | Check the full original text and effects. |
| Wall of Illusion | Sent back to the hand after damage calculation using a flag; edge cases with multiple attackers untested. | More tests. |

## Rules and systems

| Area | What differs | What it takes to fix |
|---|---|---|
| AI | About 60 per-card AI handlers (for cards that had no effects) fall back to 'use if harmless'; battle boosters are approximated. | See docs/AI_NOTES.md. |
| hand limit 6 | The 6-card hand limit is an assumption from the tutorial text. | Find it in the original's code. |
| only 1 attack restriction on turn 1 | 'No attack on the first turn' follows what you told me; the exact original rule (also for the second player's first turn) is not verified. | Check the original's code. |
| spell speed | Chains follow normal spell-speed rules; the original's response-window rules (who may respond when) are only partly verified. | Finish docs/DUEL_FLOW.md from the original's code. |
| three tributes for the Gods | The Egyptian Gods need 3 tributes by assumption. | Check the original. |
| windows | 'Continuous card played' (strings 193-195) and the exact order of the 31 announced windows are not all implemented. | See docs/DUEL_FLOW.md. |

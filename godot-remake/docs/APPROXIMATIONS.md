# Approximations: things that are not yet like the original

Generated from `data/approximations.json` by `tools/list_approximations.py`. Do not edit by hand.

75 cards and 10 rules.

## Cards

| Card | What differs | What it takes to fix |
|---|---|---|
| Alligator's Sword Dragon | Face-down opposing monsters count as their real attribute when deciding if a direct attack is allowed. | Check what the original does with face-down monsters. |
| Ancient Telescope | No effect: seeing the opponent's top 5 cards needs an interface. | A card-list dialog. |
| Aqua Spirit | The Standby Phase position-change effect is missing (only the special summon condition is in). | A trigger on the opponent's Standby Phase that lets the owner change one face-up monster's position. |
| Big Eye | No effect: seeing and ordering the top 5 cards needs an interface. | A card-ordering dialog. |
| Big Shield Gardna | The face-down single-target Spell negation is implemented. The shift to Attack Position still happens at Battle Phase end rather than immediately after the individual Damage Step; exact native position-event order needs tracing. | Spell targets in the chain link, and a post-Damage-Step window. |
| Black Illusion Ritual | Relinquished's special effect is missing (it is only a 0/0 monster). | Implement Relinquished (equip and take over ATK/DEF). |
| Blue-Eyes Toon Dragon | The 'attack directly while the opponent controls no Toon monster' rule is missing. | As Toon Summoned Skull. |
| Call of the Dark | Only the ban on playing Monster Reborn is in; monsters already restored with Monster Reborn are not sent to the Graveyard. | Remember which Special Summons came from Monster Reborn. |
| Ceremonial Bell | No effect: the hand reveal is only a display matter and needs an interface. | Show both hands while the card is face-up (board view). |
| Cyber Jar | Summon positions and the order in which the two players pick up cards are simplified. | Check the original's order and which player's monsters are summoned first. |
| DNA Surgery | Monster Type icons in the interface do not change. | Use Duel.race_of in the card detail panel. |
| Dark Necrofear | Only the special summon condition is in; the 'becomes an Equip Card and takes control' effect is missing. | Use become_equip plus a control link when destroyed. |
| Dark Spirit of the Silent | The original target is retained, as confirmed by FUN_0058dcc0. The forced position change is still quiet; exact position-change response timing needs tracing. | Trace FUN_005751e0 and the queued attack commands before changing position response windows. |
| De-Fusion | Revival is now optional, each material has a position choice, and the activating player's Graveyard is used. Material eligibility still matches the printed Fusion recipe rather than recording the actual cards used, including substitutes. | Trace the native material-history flags in FUN_00599e30 and persist actual Fusion materials. |
| Destiny Board | The Spirit Message cards can still be played or Set by hand; only the board places them properly. | Forbid playing/Setting the Spirit Message cards manually. |
| Dimensionhole | The Monster Card Zone is not reserved while the monster is removed from play, and the monster comes back as a Special Summon. | Reserve the zone and return the monster without a summon. |
| Dream Clown | Only triggers when the player changes its position, not when an effect does. | Fire position_changed from force_position too (with a flag for effect-caused changes). |
| Earthshaker | The opponent's choice is labelled 'First/Second' instead of showing the two attributes. | Pass the chosen attribute names into the choice labels. |
| Exchange | The hands are not shown to both players. | A hand-reveal screen. |
| Fairy's Hand Mirror | The new target must satisfy the Spell's own target filter; extra restrictions of Equip Cards are not re-checked. | Reuse the Equip Card's host legality check. |
| Fake Trap | The substitution is automatic whenever the opponent's effect would destroy my other Trap Card; there is no choice and it also works face-up. | Offer the choice and require the card to be Set. |
| Fusion Gate | Only used through an effect button; the original may offer it automatically. | Compare with the original's interface. |
| Gate Guardian | Can only be Special Summoned from the hand with its three Tributes; other Special Summons are not blocked. | A summon-procedure rule. |
| Gilasaurus | The 'treat as Special Summon' choice only marks the card as Special Summoned (the Normal Summon of the turn is still used). | Let the summon dialog offer Special Summon, which would not use the Normal Summon. |
| Ground Collapse | Only zones on the opponent's side can be blocked, and an occupied choice moves to the next free zone automatically. | A zone-picker UI for either side. |
| Harpie Lady Sisters | Cannot be Normal Summoned, but other Special Summons (not only Elegant Egotist) are not blocked. | A summon-procedure rule like Wall Shadow's. |
| Hourglass of Courage | The doubling is computed from the printed ATK/DEF (other bonuses are not doubled). | Double the final value. |
| Infinite Dismissal | Destroys every Level 3 or lower monster summoned (Normal Summoned, Flip Summoned or Set) during the turn, including ones summoned before the trap was activated. | Only count monsters summoned after the activation. |
| Insect Queen | The Insect Monster Token appears immediately, not at the end of the turn. | Create the token in the End Phase. |
| Jirai Gumo | Coin tossed without a call. | A 'call it' prompt before the toss. |
| Kazejin | The once-only ATK reduction is tracked per time the card is on the field (also Sanga of the Thunder). | Remember the use across leaving the field if the original does. |
| Kotodama | Only the 'later copy is destroyed' rule is in; the 'two copies played at the same time are both destroyed' case is not. | Detect simultaneous summons (Fusion Gate / Cyber Jar) and destroy both. |
| Last Will | Implemented as a continuous effect for the turn; needs checking against the original timing. | Verify with the original. |
| Lord of D. | Selection-based Dragon targeting protection is implemented. Completeness of target classification across individual effect scripts has not been audited; attacks and effects without targets correctly remain eligible. | Audit targeting steps against FUN_0056c510 without extending protection to attacks or effects without targets. |
| Magic Thorn | Also triggers on discards paid as a cost, not only discards caused by Spell/Trap/Effect Monster effects. | Tag the discard reason (cost vs effect) and only count effect discards. |
| Magical Hats | The two decoys are tokens; the original takes 2 non-monster cards out of the Deck. | Move two Spell/Trap cards from the Deck onto the field as 0/0 monsters, return them afterwards. |
| Mask of Dispel | The card is only destroyed at the next Standby Phase after the selected Spell leaves the field. | A trigger on the selected card leaving the field. |
| Metal Detector | The negated Continuous Trap stays on the field with its effects switched off until the end of the turn (it is not destroyed); same for Mystic Probe, World Suppression and Armored Glass. | Check what the original does to the negated card. |
| Minar | Only effects that go through the standard 'discard', 'mill' and 'to_grave' steps count as the opponent's effect (also Electric Snake, Penguin Knight). | Set Duel.effect_player in every custom op that moves cards. |
| Morphing Jar #2 | The card count each player picks up is an interpretation of an ambiguous card text. | Check how the original counts. |
| Mystical Refpanel | A Spell 'targets 1 player' if its effect damages, heals, draws, mills or discards for a player; the effect is swapped as a whole. | Mark such Spells explicitly. |
| Patrol Robo | No effect at all (the peek at a Set card needs an interface). | A 'look at 1 Set card' prompt shown to the player during the Standby Phase. |
| Polymerization | 'Goddess with the Third Eye' / 'Versago the Destroyer' can be picked for more than one material slot. | Allow at most one substitute per Fusion. |
| Pumpking the King of Ghosts | The Standby Phase counter is reset only at the next Standby Phase after Castle of Dark Illusions leaves the field. | Reset the counter when the Castle leaves. |
| Red-Moon Baby | The destroyed monster comes back immediately, not at the end of the Battle Phase, and always in Attack Position. | Queue the revival for the end of the Battle Phase and let the player pick the position. |
| Relinquished | Special effect missing. | Implement the equip and stat takeover. |
| Respect Play | The card has no effect: the hand reveal is only a display matter and needs an interface. | Show the other player's hand while the card is face-up (board view). |
| Return of the Doomed | The Spell Card stays face-up on the field until the End Phase instead of going to the Graveyard right away. | A delayed end-of-turn effect that is not tied to a card on the field. |
| Riryoku | The ATK change lasts until the end of the turn (the card text gives no duration). | Check the original's duration. |
| Riryoku Field | 'Designates 1 monster' means the Spell's target step ended with exactly 1 monster selected; Spells that affect monsters without a target step are not detected. | Mark target-style Spells explicitly in the effect data. |
| Shadow of Eyes | Works once, as a normal Trap, for the monster that was just Set. | Check the original: continuous or one-shot. |
| Shift | Redirects only to my other monsters, and is limited to monster attacks (not Spell/Trap targets). | Add target_declared events for Spell/Trap targeting. |
| Sinister Serpent | Returning to the hand is automatic instead of optional. | A yes/no prompt. |
| Slate Warrior | The penalty applies to whoever destroys it in battle, including in a mutual destruction. | Check the original for mutual destruction. |
| Solomon's Lawbook | Implemented as 'skip my next draw'; other Standby Phase effects of mine still happen. | Skip the whole Standby Phase of my next turn. |
| Soul Exchange | The game engine accepts the opponent's monster as a Tribute, but the board interface does not offer it yet (AI does not use it either). | Let the Tribute dialog list the opponent's monster. |
| Soul of Purity and Light | The -300 ATK to the opponent's monsters during their Battle Phase is missing. | A static modifier that depends on the current phase/turn. |
| Spellbinding Circle | The card is also destroyed when the selected monster is offered as a Tribute (the original keeps it). | Tell Tributes apart from other ways of leaving the field. |
| Spirit of Flames | The +300 ATK during my Battle Phase is missing. | A static modifier that depends on the current phase/turn. |
| Stim-Pack | The -200 ATK per Standby Phase stays on the monster if the Equip Card leaves the field (also Germ Infection, -300). | Tie the decrease to the Equip Card (a counter on it). |
| Sword of Dragon's Soul | The Dragon is destroyed when the Battle Phase ends (entering Main Phase 2 or ending the turn). | Verify the timing against the original. |
| Tailor of the Fickle | The new host is selected before the chain and checked against the Equip effect's race/Attribute/side restrictions. Special native host predicates for revival and monster Equip Cards are not fully ported. | Port the remaining Equip-specific predicates from FUN_0056fc50; preserve them when moving the Equip. |
| The Eye of Truth | The hand reveal is missing (interface); only the +1000 LP effect is in. | Show the other player's hand while the card is face-up (board view). |
| The Flute of Summoning Dragon | Needs a free Monster Card Zone for every Dragon; extra ones fail silently. | Limit the selection to the number of free zones. |
| The Inexperienced Spy | No effect: seeing a card of the opponent's hand needs an interface. | A card-view dialog. |
| The Rock Spirit | The +300 ATK during the opponent's Battle Phase is missing. | A static modifier that depends on the current phase/turn. |
| The Stern Mystic | No effect: turning all face-down cards face-up and back only matters as information (interface). | Show the face-down cards briefly. |
| Thousand-Eyes Restrict | A face-down monster should give 0 ATK/DEF; it gives its printed values. The stats are the equipped monster's printed ones. | Use 0/0 for face-down monsters. |
| Toon Mermaid | The 'attack directly while the opponent controls no Toon monster' rule is missing. | As Toon Summoned Skull. |
| Toon Summoned Skull | The 'attack directly while the opponent controls no Toon monster' rule is missing. | Use the direct_vs_attributes style rule with a Toon-monster check. |
| Trap Master | A face-up card of the wrong kind can be selected and nothing happens (also Reaper of the Cards, Armed Ninja, De-Spell). | Restrict the selection to face-down cards and face-up cards of the right kind. |
| Valkyrion the Magna Warrior | Only the summon condition is in; the rest of the card text has not been read for details. | Check the full original text and effects. |
| Wall of Illusion | Sent back to the hand after damage calculation using a flag; edge cases with multiple attackers untested. | More tests. |
| Weather Report | Only the destruction of Swords of Revealing Light is in; the extra Battle Phase is missing. | Let Duel run the Battle Phase twice after the flag is set. |
| Zone Eater | 'The fifth turn after the attack' is counted in game turns of both players (also Swordsman from a Foreign Land and Steel Scorpion). | Verify the turn counting with the original. |

## Rules and systems

| Area | What differs | What it takes to fix |
|---|---|---|
| AI | About 60 per-card AI handlers (for cards that had no effects) fall back to 'use if harmless'; battle boosters are approximated. | See docs/AI_NOTES.md. |
| Quick-Play Spells | A Set Quick-Play Spell can only be played in the response windows the engine opens (summons, attacks, target declaration, damage step, chain links, Standby and End Phase). | Open a window whenever a player gets priority. |
| Who destroyed a card | The player responsible for a destruction is only known for the plain 'destroy' effect step (Gust, Driving Snow, Fairy Guardian); custom effects (Crush Card, Cyber Jar, ...) report none. | Set Duel.effect_player in every custom op that destroys cards. |
| hand limit 6 | The 6-card hand limit is an assumption from the tutorial text. | Find it in the original's code. |
| only 1 attack restriction on turn 1 | 'No attack on the first turn' follows what you told me; the exact original rule (also for the second player's first turn) is not verified. | Check the original's code. |
| random-result animation motion | Dice and coin animations now use the extracted sprite strips, final faces, shadows and sounds, and pause resolution until the result is displayed. Flight paths, frame cadence and result hold times are reconstructed rather than copied from the native renderer. | Trace the native coin/dice renderer frame order, positions and timing, then replace the reconstructed motion while keeping the recorded-result presentation barrier. |
| remaining-effect native parity | Major Riot now matches the recovered handler's available-card/zone summon-count clamp and controller-based bounce eligibility. Multi-step effect return-window timing remains unverified: queued returns open after the chain without a last-action check. Other batches 18-20 still use extracted text and period rulings where native dispatch has not been traced. | Trace FUN_00581790 and native event delivery around FUN_0058bb10 before imposing a last-action timing rule. |
| spell speed | Chains follow normal spell-speed rules; the original's response-window rules (who may respond when) are only partly verified. | Finish docs/DUEL_FLOW.md from the original's code. |
| three tributes for the Gods | The Egyptian Gods need 3 tributes by assumption. | Check the original. |
| windows | 'Continuous card played' (strings 193-195) and the exact order of the 31 announced windows are not all implemented. | See docs/DUEL_FLOW.md. |

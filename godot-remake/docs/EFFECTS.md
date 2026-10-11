# Card effect language

Cards are described in `data/effects/*.json`, keyed by **English card name** (or Konami number). The engine
(`core/effects/`) interprets them; there is no per-card GDScript except rare `custom` ops (`fx_custom.gd`).

```json
"Hinotama": {"fx": [ {"type": "spell", "do": [{"op": "damage", "who": "opp", "amount": 500}]} ]}
```

## An effect

| key | meaning |
|-----|---------|
| `type` | `spell` `quickplay` `equip` `field` `ritual_spell` · `trap` `counter` `continuous_trap` · `flip` `trigger` `trigger_forced` `ignition` · `static` |
| `speed` | spell speed 1-3 (default 1; traps 2, counters 3). Responses need speed >= 2 and >= the top of the chain |
| `when` | event(s) it can respond to (see below). Required for traps / quick-play / triggers |
| `zone` | where the card must be: `field` (default; spells default to hand or field), `grave`, `hand`, `hand_or_field` |
| `cond` | list of conditions, all must hold to activate |
| `cost` | steps run first at activation (pay LP, discard, offer a monster...) |
| `target` | steps run at activation after the cost (choose targets). Activation is refused when no valid target exists |
| `do` | steps run on resolution |
| `stay` | the card remains on the field after resolving (continuous cards) |
| `once_per_turn`, `mandatory` | self explanatory (`flip` and `trigger_forced` are mandatory = they fire on their own) |

`static` effects are always on while the card is face-up: `{"type":"static","mod":{"scope":"all|mine|theirs|self|equipped","filter":{...},"atk":N,"def":N}}`
or a rule: `{"type":"static","rule":"no_attack|no_position_change","scope":"all|mine|theirs","filter":{...}}`.

## Events (`when`)
`summoned` (normal) · `special_summoned` · `flip_summoned` · `flipped` · `attack_declared` {attacker, target} ·
`destroyed` · `sent_to_grave` {was_on_field, reason} · `damaged` · `standby_phase` · `end_phase` ·
`activated_spell` / `activated_trap` / `activated_monster_effect` (a chain link was added).
Event data always has `player` (who caused it) and usually `uid` (the card involved).

## Steps (`op`)
Selection: `select` {as, from, filter, n, min, pick: min_atk|max_atk|min_def|max_def, random, chooser, prompt, cost} ·
`yesno` · `choice` {count, labels} · `let` {as, what}.
Movement: `destroy` `to_grave` `to_hand` `to_deck` {where} `banish` `special_summon` {pos|pos_var, face_up} `discard` {who, n, random} `search` {filter} `shuffle`.
Stats: `mod` {atk, def, until: end_turn|forever} `set_stat` `equip` {to, atk, def}.
Players: `damage` `heal` `pay_lp` `set_lp` `draw` `skip_next_draw`.
Board: `take_control` {until} `set_pos` {pos, face_up} `flip_down`.
Chain/battle: `negate` {destroy} `negate_attack` `skip_phase`.
Flow: `if` {cond, then, else} `coin` {heads, tails} `counter` {name, add} `set_flag` `rule_turn` `win` `custom` {fn}.
`what` is `$var` (a selection), `src`, `event_card`, `attacker`, `attack_target`, `equipped`, or `{"from": zone, "filter": {...}}`.
Values: a number, `{"stat":"atk","of":"var"}`, `{"lp":"self"}`, `{"count": zone, "filter": {}}`, `{"mul": v, "by": n}`, `{"half": v}`.

## Zones and filters
Zones: `monsters spells fieldspell hand deck grave banished extra field`, prefixed `self.` / `opp.` (none = both).
Filters: `face_up face_down(false) pos type[spell|trap|monster, or list] subtype category[0-3] attribute race level_min/max atk_min/max def_min/max name_has number not_src owner`.

## Conditions (`c`)
`has` {zone, filter, n} · `none` · `lp` {who, op, v} · `hand` · `deck` · `event_by` {who} · `event_card` {filter} · `event_target` · `event_attacker` ·
`event_src` (the event is about this very card) · `event_reason` · `was_on_field` · `phase` · `turn` {is} · `chain_top_by` · `counter` · `free_zone` · `flag`.

## How it runs
Actions that raise events open a **response window** (turn player first, then the other); players may chain legal effects
(speed rules enforced); the chain resolves last-in-first-out. Anything that needs a choice sets `duel.fx.pending`
and waits for `duel.respond(answer)`. The AI and the UI answer through the same call.

## Added in batches 3-5
Ops: `dice` {as} · `coins` {n, as} (number of heads) · `redirect_attack` {to} · `flip_pos` · `token` {kind, n, pos} (Sheep Token / Insect Monster Token, see `Duel.TOKENS`) ·
`bind` {a, b} (when one leaves the field the other is destroyed) · `link_control` (Snatch Steal) · `swap_stats` · `mill` {who, n} · `borrow` (Graverobber) ·
`fusion` {mode: poly|gate} (recipes in data/fusions.json, parsed from the card texts).
Targets: `killer` (the monster that destroyed the event card in battle), `attack_target`. Filters: `name_is`, `not_in` [vars], `not_attacker`.
Conditions: `attacker_is_src` `target_is_src` `killer_is_src` `fusion_possible` `var_ge` `var_le`.
Events: `drew`, `discarded` (only opened while a face-up/set card listens for them), `destroyed` now carries `killer`.
Static rules: `no_trap` (Jinzo) `no_spell` `no_tribute` `no_set` `no_direct_attack` `no_battle_damage_self` `pierce` `destroy_equips` `free_summon_behind` `attack_needs_tribute`
`no_normal_summon` `summon_needs` {name}. `def_after_battle` / `lock_pos_until` are card flags used by Goblin Attack Force.

## Added in batches 6-8
Ops: `double_atk` {what, destroy_at_end} · `ritual` {monster, level} (select the Ritual Monster from hand, then tributes whose Levels add up; `select` has `sum_level_min`) ·
`set_pos` accepts `quiet` (no Flip effects) · custom ops `cyber_jar`, `morphing_jar2` (core/effects/fx_custom.gd).
Zone `dead_battle` = my monsters destroyed in battle this turn. Conditions: `source_is_src` (this monster inflicted the damage), `var_matches` {name, filter}, `ritual_possible`.
Events: `healed`. Static rules: `no_damage` (Tornado Wall, player-wide) `no_equip` `double_attack` `can_attack_directly` `direct_vs_attributes` {attributes} `no_summon_any`
`protected_by_field` {name}. Flags: `destroy_at_end`, `return_after_battle`. Exodia: five pieces in hand win (Duel.check_exodia).

## Added in batch 9
Filters `name_in`, `level_eq` (a value, e.g. `{"var": "roll"}`), `same_name_as_event`. Value `{"var_count": "x"}`. Event `position_changed` {pos}; `sent_to_grave`/`destroyed` carry `pos` and `was_face_up`.
Conditions `event_pos`, `was_face_up`. `special_summon` takes `pos_event`. Fusion materials may be replaced by "Goddess with the Third Eye" / "Versago the Destroyer".

## Added in batches 10-12
Ops: `become_equip` {to, atk, def} (a monster/card turns into an Equip Card: Blast Sphere, Kiseitai, Beast of Gilfer) · `flag_from_var` · `watch` · `skip_turn` · `lockdown` {turns} (Cold Wave) ·
`draw_until` · `banish_random_hand` {after} · `give_to_deck` · `block_zones` {a, b, side} · `move_equips` · `swap_attacker` · `take_from_hand` (Exchange) · custom ops `crush_card`, `magical_hats`, `destiny_board`, `damage_watched`.
Filters `attr_var`, `race_of_src_flag`, `special_summoned`. Conditions `src_face_down`, `free_zones`. Effect key `face_down_ok` (a face-down monster may use a trigger). Effect zones `extra` and `deck`.
Static mods: `lp_rule` (Megamorph), `same_name` (Aqua Chorus). Rules: `dna_surgery`, `ground_collapse`, `no_special_summon`. Duel: `race_of`, `zone_blocked`, `skip_turn`, `lockdown_until`, `crush_until`.

## Added in batch 14
Ops: `remove_top` {who, n, as} (banish the top cards of a Deck) · `become_equip` now takes `card` (any card, default `src`) and `on_host_side` (put it in the host's controller's Spell zone; Sword Hunter) ·
custom ops `chosen_one`, `nobleman_ext`. Conditions: `src_pos` {is: atk|def} (this card is face-up in that position) · `in_battle` (this card is the attacker or the attack target) ·
`attacker_weaker_than_target` (the attacked monster is in Defense Position with more DEF than the attacker's ATK) · `event_src` takes `is: false` ("the event is about another card").
Filter `fusion_mat`: a card in the Graveyard that was sent there as a Fusion Material (flag set by `Duel.send_to_grave` for the reason `fusion_material`).
Flag `atk_after_battle`: the monster turns to face-up Attack Position when the Battle Phase ends (Big Shield Gardna).

## Added in batch 15
Ops: `extra_summon` (one more Normal Summon or Set this turn) · `token` accepts `n: "free"` (one per open Monster Card Zone) · `mod` accepts `turn_offset` (lasts until the end of that many turns from now) ·
`set_flag` accepts `value_src` (stores the uid of the card running the effect) · `equip` accepts `race` (the equipped monster is treated as that Type) · custom op `de_fusion`.
Filters `attacking` (the monster currently attacking) and `fusion`. Condition `normal_summon_used`. Static mod keys `half_atk` (Mirror Wall) and `per.max_n` (count at most n).
Rules: `attack_in_def` (Total Defense Shogun) `banish_graveyard` (Banisher of the Light) `no_hand_limit` `no_flip_effects` (Royal Command). Turn rule `inf_dismissal`. Card flag `cannot_attack_by` (uid of the card that binds it).
Turn flags (`attacked`, `pos_changed`) are reset for the monsters of both players at the start of every turn, so a monster taken with Change of Heart can act normally.
Mods ending at a later turn use `until: "turn:N"`; a monster that is a Tribute goes to its owner's Graveyard even if you control it.

## Added in batch 16
Quick-Play Spells (card subtype 5) are declared as `quickplay` with `speed: 2` and a `when` list, so they can be Set and played from the turn after, in response to
`summoned special_summoned flip_summoned attack_declared target_declared damage_step activated_spell activated_trap standby_phase end_phase` (tests/test_effects11.gd checks every one).
Ops: `switch_equip` {card, to} (Tailor of the Fickle) · custom ops `dimensionhole` (`Duel.dimension_holes`), `monster_recovery`.
Filters `equipping` (an Equip Card attached to a monster) and `not_equipped_by` {var}. Condition `battle_involves_equipped`. Rule `untargetable` (Lord of D.: such cards are dropped from target selections; see `Fx.has_untargetable`).

## Added in batch 17
A card chained inside a response window (attack, summon, ...) does not open an `activated_*` window of its own: the other player answers in the same window with the same event.
Cards that react to a chained card therefore list the usual timings in `when` and look at the top of the chain: conditions `chain_top_card` {filter}, `chain_top_by` {is}, `chain_top_single_monster_target` (exactly 1 monster chosen by a Spell's target step), `chain_top_targets_src` (that monster is this card).
Turn rules `neg_continuous_trap`, `neg_continuous_spell`, `neg_field_spell`, `neg_equip` (set for both players with two `rule_turn` steps) switch off the effects of that kind of face-up card (`Fx.effects_of`, equip bonuses in `Fx.stat_bonus`) until the end of the turn.
Rule `spells_must_set` (Anti-Spell Fragrance). The `destroyed` event carries `by` (the player whose effect destroyed the card, -1 if none/battle); condition `destroyed_by_opp_effect`. `Duel.lost_spells` / zone `self.lost_spells`: my Spells destroyed by an opponent's effect this turn (Fairy Guardian).
Effects that respond to a chain link need `speed: 2`, also `trigger_forced` ones (Big Shield Gardna).


## Added in batches 18-20

- `procedure: true` on an ignition entry performs a summon procedure without starting a chain. Costs and choices pause normally; Summon response windows open after the procedure finishes. `DCard.properly_summoned` persists outside temporary field flags for eligible revivals.
- Conditions: `procedure_possible` (`kind`: `wall_shadow`/`ultimate_moth`), `labyrinth_possible`, `manga_possible`, `spell_zone`, `imitation_possible`, `makiu_possible`, `inspection_source`. Filter: `tribute_legal` excludes Sheep/Kuriboh Tokens.
- `equip.attribute_var` sets an effective Attribute from a six-option choice (index + 1). All Attribute filters and field modifiers use `Duel.attribute_of()`. Spell immunity suspends Equip effects without detaching the Equip.
- `prompt_text` supplies a direct prompt on `select`, `yesno`, or `choice`. `choice.catalog` is a searchable card-name catalogue; `choice.reveal` privately displays a card's art, and `choice.reveal_cards` displays a hand list. These use the existing choice-answer protocol; AI code is unchanged.
- Custom functions: `bait_doll`, `summon_procedure`/`procedure_finish`, `labyrinth_summon`/`labyrinth_finish`, `cocoon_equip`, `major_riot`/`riot_show_hands`, `declare_card`/`prohibition`, `inspection`/`inspection_again`, `manga_summon`/`manga_finish`, `imitation_cost`/`imitation_tribute`/`imitation_summon`/`imitation_finish`, `makiu_target`/`makiu`.
- Static rules: `summon_procedure`, `spell_immune_umi`, `toon_attack`. Turn rules: `spirit_elimination` (replaces graveyard monster banish costs using the original filter; effects ask for a field substitute), `battle_entered` (Makiu cannot be activated after taking a Battle Phase).
- Bait Doll resolves a forced Trap within its own resolution, with no new response chain; counter negation cannot negate the already resolving Bait Doll. Printed free-timing Traps are checked separately from the existing restricted response-window lists. Jinzo/Royal Decree negate Trap effects and static rules while active.
- Prohibition snapshots field exemptions on activation, removes exemptions when cards leave, blocks playing declared cards, and suppresses effects/attacks of non-exempt declared cards summoned by an effect. Effect summons remain possible (period ruling), while direct summon procedures are prohibited.
- `returned_to_hand` now includes `by` (effect controller) as well as the previous field controller. Major Riot requires an opponent effect. Its queued last-action timing limitation is recorded in `data/approximations.json`.
- Inspection opens an `inspection_again` window after each paid reveal, allowing repeated optional uses during the same opponent Standby Phase.

Validation: `test_effects13.gd` (batch 18), `test_effects14.gd` (batch 19), `test_effects15.gd` (batch 20), `test_remaining_effect_ui.gd`; visual fixtures in `screenshot_remaining_effects.gd`.

Period-rule reference used to clarify incomplete printed text: [2003 tournament card rulings](https://ms.yugipedia.com/a/a1/2003_tournament_rulings.pdf), particularly Manga Ryu-Ran, Major Riot, Prohibition, Bait Doll and Spirit Elimination. Newer errata are not applied when they contradict the extracted 2004 text (e.g. an opponent's Toon World permits Manga's summon).


## Native approximation audit

Source functions and remaining timing limits are in `NATIVE_APPROXIMATION_AUDIT.md`.

- Value expressions support `original: true` on `stat` to read printed ATK/DEF.
- Coin scripts can insert a `choice` named `coin_call` (Heads=0, Tails=1), then use `coin.call: "coin_call"`; `heads`/`tails` branches mean correct/incorrect call. The coin log records actual `heads`, `call`, and `correct` separately.
- `free_zone.n` requires a specific number of free Monster Card Zones. `summon_unused` checks all Normal/Flip/Special Summons this turn. Sets remain legal under the native summon locks.
- `banish_random_hand.owner_turns` counts the affected player's turns, including the current one when applicable, for Lightforce Sword.
- `event_was_flipped` uses history captured before a monster leaves the field. Setting it again resets that history.
- Mage Power supports `per.include_field_spell` and source-controller counting. Mirror Wall halves final current ATK; Metalmorph's battle bonus uses the native separate rounding.


## Random-result animation playback

`Fx.presentation_enabled` is enabled by the animated duel board and defaults to false for standalone rules/AI simulations. Coin, multiple-coin and dice operations record their result once, then yield a `presentation` barrier before executing following effects or coin branches. The board drains events, awaits the original sprite-strip animation, acknowledges the barrier, and continues draining resulting events. No AI decision changes are needed.

Multiple-coin events include an `outcomes` array in addition to the success count. `DuelFx` uses the original `coin_rotate`, dice tumble/random strips, all six `dice_decide` textures, shadows and ripple; recorded outcomes select the final face. Presentation does not consume duel RNG. The motion timing approximation is recorded in `data/approximations.json`. `test_roll_animations.gd` checks waiting, single resolution, matching all coin faces, disabled animation handling, and cleanup.

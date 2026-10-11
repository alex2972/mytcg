# Native targeting and selection audit

Static evidence from `Z:/process/analysis/decomp.c`, compared with the current remake. This audit does not claim runtime observation of the original executable.

## De-Fusion: improved

`FUN_005914a0` (lines 225713-225775) stores the returned Fusion identity, checks that every material exists in the activating player's Graveyard and that enough monster zones are free, and offers a yes/no confirmation (`FUN_005bf9a0(1,0)`, lines 225752-225755). Its next state calls `FUN_005adb10` individually for each material (lines 225733-225738), the shared summon interface. The extracted original card text explicitly permits face-up Attack or Defense.

The remake now asks whether to revive the materials after returning the Fusion to its owner's Extra Deck, then asks the position separately for each material. Material eligibility and free-zone checks are performed before offering the revival. Spell immunity and a target that already left the field prevent the return. Tests cover declining, different positions, and an opponent-owned Fusion using only the activating player's Graveyard.

`FUN_00599e30` lines 229020-229060 searches `param_1 & 1`'s Graveyard, not the Fusion owner's Graveyard. Therefore the old approximation's suggestion to use the owner's Graveyard was incorrect. Selecting a Fusion belonging to either player is legal. The native routine also checks material-history bitfields (`0x180000`) and matching helpers; the remake still uses its printed recipe. Exact native material-history/substitute behavior remains unverified.

## Major Riot: native count clamp

The newly exported `FUN_0058bb10`, state `0x7e`, clamps the returned-monster count to the available eligible hand monsters and free monster zones. The remake now performs the same clamp, instead of requiring enough eligible monsters for the entire original count. The targeted regression returns three monsters, including two Level 8 monsters, and confirms that the one eligible Level 4 monster can be summoned face-down in Defense Position after both hand reveals. See the main audit for return-event timing.

## Lord of D.: approximation wording correction

`FUN_0056c510`, lines 217146-217164, guards the native target picker. It only applies to face-up monsters in monster zones (`param_2 < 5`) and rejects effective race 1 (Dragon) when `FUN_005699c0(0x2e4)` finds Lord of D. This supports target protection. It does not justify protecting against attacks or effects that do not target. The existing approximation should not suggest broadening protection to either case; remaining work is explicit effect-target metadata and coverage.

## Other scoped cards: evidence insufficient for a faithful change

- Magic Thorn: `FUN_005759a0` calls `FUN_0059ce90` when the sent card is owned by the discarding player (lines 220930-220941); `FUN_0059cf30` applies the accumulated count times 500 (lines 229520-229556). This demonstrates aggregation, but does not yet establish cost-versus-effect handling at every caller. Keep that approximation until the relevant cost paths are traced.
- Ground Collapse: `FUN_00569e10`, lines 215431-215462, checks the selected player's zone against links to an active Ground Collapse. This supports both-side zone storage. The original chooser and current UI integration still need tracing.
- Chosen One is now traced and improved; see below.
- Return of the Doomed: `FUN_005a4c00`, lines 232458-232474, refers to its saved effect record in zone `0xb`; the distinction between that internal record and a physically face-up Spell still needs tracing. No speculative engine change was made.
- Tailor of the Fickle is now traced and improved; see below. Shift and Dark Spirit are traced below.

Validation: `tests/test_native_targeting.gd` passes.

## Additional recovered handlers

Source: `Z:/process/analysis/all_approximation_handlers.c`, with card mapping in `approximation_handler_map.json`.

### Chosen One: improved

`FUN_0058fa90` state `0x7a` shuffles the three selected cards and invokes the opponent's hidden-card chooser (`FUN_005bcfe0`). State `0x79` identifies the picked card, `0x78` reveals its name, `0x77` sends the other two cards to the Graveyard, and `0x76` invokes the shared summon interface only if the picked card is a monster. The remake now follows this sequence. It offers three indistinguishable card choices to the opponent, reveals the chosen card, sends the other two to the Graveyard, and only then asks for Attack/Defense if the result is a valid monster. No position choice appears for a failed pick.

### Tailor of the Fickle: improved

`FUN_00589c70` validates the equipped card and invokes `FUN_0056fc50` for its new host. The helper (`decomp.c`, lines 219383 onward) delegates to the Equip Card's normal target predicate, `FUN_00579ce0`. `FUN_0057b3b0` scans both players' monster zones for a valid alternative and excludes the existing host. The remake now reuses the Equip Card's target filters and controller restrictions to present valid alternate hosts, and validates again before moving the equip. Tests cover Lightning Blade rejecting an Aqua monster, accepting an opposing Warrior, and excluding its existing host.

### Shift: verified remaining engine gap

`FUN_00582590` first checks a pending opposing non-monster card whose selected target is a monster controlled by Shift's controller, and separately checks the battle-attack window (`0x480`). `FUN_0058f140` dispatches between the Spell/Trap-target and attack-target implementations. This confirms that the remake's attack-only redirect is incomplete. The original target predicate is reused for the replacement target; simply allowing an arbitrary monster would be wrong.

### Dark Spirit of the Silent: original target retained

`FUN_0058dcc0` negates the original attack, changes a selected face-up Defense Position attacker through `FUN_005751e0`, and creates the replacement attack using the original target stored at `param_1 + 0x12` (or direct-attack command `0x34` when that target is not a monster zone). The remake retaining the original target is therefore supported by the native code. The existing approximation suggesting the attacker must choose again should be corrected. The position-change notification timing remains to be checked through the shared helper.

Additional validation: `test_effects10.gd`, `test_effects12.gd`, and the expanded `test_native_targeting.gd` pass.

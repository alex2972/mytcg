# Battle phase: how the original paces it (from joey_pc.exe)

Sources: `analysis/phase_fns.c` (sub-state functions 0x5a1e50-0x5a4010, exported with ExportAt.java), `analysis/battle_ui_fns.c`,
`analysis/native_battle_presentation.c`, `analysis/event_map.txt` (UI event id -> handler), `analysis/decomp.c`.
Reference clip: `videos/battlephase.mp4` (10 fps).

## 1. The engine never sleeps; it waits for the UI
- Master step `FUN_005bc700`: each update it runs ONE state step of the current sub-state function (table 0x5efa68, state byte `_DAT_00a577fc`),
  but only if no UI work is pending (`FUN_0040cf20` modal dialogs, `FUN_005b9ca0` event queue). So the engine costs ~1 tick per state step
  and everything else is the length of the UI events it queued.
- `FUN_005b9170(id, a, b, c)` queues a UI event (queue at 0xa550a8, max 256). `FUN_005b9ca0` pops one event at a time and calls its handler
  (`FUN_005b9470`, id -> handler table in event_map.txt) every tick until the handler clears bit 0x4000 of `DAT_00a558ac` ("busy").
  A handler's own state lives in `DAT_00a558ac & 0x7f`.
- There are no wall-clock waits in the battle code. All waits are animation counters (below).

## 2. Tick length
One tick = one call of an animation object's update. The frame object defaults to 0x3c (60) but all the clips fit ~30-32 ticks per second
(summon 256/8 = 32 ticks in 1.0 s, Set 256/12 ticks in 0.71 s, battle banner below). Durations below are given in ticks, then at 30 ticks/s
(fitted) and 60 ticks/s (frame-limiter default). The 30/s column matches the 10 fps clip; treat it as "fitted", not traced.

## 3. Battle sub-states (DAT_00a577f8 high byte), in order for an attack on a monster
| idx | fn | what it does |
|---|---|---|
| 6 | 5a22c0 | 0: mark attacker used (event 0x35, no animation). 1: flip a face-down defender (`FUN_00574f70`). 2: attack-declared triggers. 3: opens response window 0x13 ("declared battle", strings 182/183). 1 tick per state |
| 7 | 5a2740 | 0: event 0x30 (compute damage: `FUN_005b7c50`, no animation). 1: `FUN_005b8210(1)` calc + triggers. 2: event 0x31 = the damage-step animation (section 4). 3: events 0x3c for each destroyed card |
| 8 | 5a2990 | applies LP damage (`FUN_00578540`), LP-damage event 0x43, win check |
| 9 | 5a2d60 | after-damage triggers (Kunai, Sword-type cards...) |
| 10 | 5a31a0 | sends destroyed monsters to the Graveyard, destroyed-by-battle triggers, response window 0x12 |
| 11 | 5a3a10 | end of battle (Spirit Reaper-style cleanup) then back to sub-state 1 (action select) |
The target choice itself is the event 0x33 (monster target) / 0x34 (direct attack): `FUN_00407880/407960` set the battle struct (0xa57840) and call the
sword object (`FUN_00413af0`, `FUN_00413b30`), then hold until it is idle.

## 4. The sword / damage-step object (vtable 0x5da710, update 0x414110, draw 0x4142c0)
Fields: +0x10 mode, +0x14 counter. Busy (`0x413f10`) only in modes 4, 6, 7.
| mode | meaning | counter | length |
|---|---|---|---|
| 1 | idle swords on eligible attackers | - | - |
| 2 | attacker picked, sword follows | - | - |
| 3 | hovering a target: sword turns toward it | +0x10/tick, stops at 0x80 | pre-paid aim (8 ticks) |
| 4 | launched (event 0x33) | +0x10/tick from the hover value (clamped to 0x80) up to 0x200 | 0-0x80 aim, 0x80-0x100 eased travel (8 ticks, attack sound at 0x90), 0x100-0x200 yellow impact ring (16 ticks). After a hover the cost is 8+16 = **24 ticks** (0.80 s @30, 0.40 s @60); max 32 ticks |
| 5 | arrived, not busy | - | - |
| 6 | damage step "shine" (event 0x31), only when the defender SURVIVES and its player takes no damage | +0x10/tick to 0x200, drawn only below 0x100 | 32 ticks (1.07 s @30), visible sweep 16 ticks |
| 7 | damage step effects | +8/tick, 0x100 total | **32 ticks (1.07 s @30, 0.53 s @60)**. On its FIRST tick it starts the destruction effect on each destroyed card (card sprite effect state 2), the LP-damage popups and the damage sound (0x10000009) |
Mode 6 is followed by mode 7, so a surviving defender costs 64 ticks, a destroyed one or any LP damage 32. Mode 7 is a plain wait: the explosion lasts less than
the 32 ticks, the event still holds for all of them.

## 5. Other waits
- Phase banners (events 0x50-0x55, `FUN_00404920`; banner object 0x480c20 / 0x480c60): counter +8/tick, done at 0x100 = 32 ticks
  (1.07 s @30). In the Battle Phase (banner mode 3) the counter is +4/tick between 0x40 and 0x80, so it takes **40 ticks (1.33 s @30)**.
  Slide-in 0-0x40 (8 ticks), hold 0x40-0x80, fade 0x80-0x100 (16 ticks). The engine does not continue until the banner finishes.
  The clip shows the Battle Phase banner about 1.1-1.2 s (frames 6.5-17.5), which fits 30/s and not 60/s.
- Destruction event 0x3c (`FUN_00405020`): tick 0 starts the explosion effect object, tick 1 moves the card data to the Graveyard and finishes.
  It does NOT wait for the explosion; the explosion runs while the next events start.
- LP event 0x43 (`FUN_00408470`): starts the LP counter, waits until both LP counter objects are idle, then waits until every
  card/sprite effect object is idle, then 11 more ticks (counter +0x80 until >0x500, 0.37 s @30), then the next action.
- Every sub-state step costs 1 tick; response windows (0x12, 0x13) cost only the time of the player/CPU choice (no fixed timer found in
  `FUN_005bafd0`, the window state machine).

## 6. Our old values versus the original @30 ticks/s
Applied: ui/battle_timing.gd now holds the @30/s tick counts below (survivor: 16-tick shine + 48-tick hold; kill: 15-tick shake + 17-tick explosion = the 32-tick hold).
| item | ours | original @30/s | @60/s |
|---|---|---|---|
| Battle Phase banner | 0.8 | 1.33 | 0.67 |
| other phase banners | 0.8 | 1.07 | 0.53 |
| sword after click (travel) | 0.3 | 0.27 (aim is pre-paid by hovering; 0.53 if clicked without hover) | 0.13 |
| impact ring | 0.5 | 0.53 | 0.27 |
| damage step (shine for survivor) | 0.5 | 1.07 (visible ~0.53) then +1.07 | 0.53 / +0.53 |
| damage step for a kill / LP damage | shake 0.6 + 0.4 pause + explosion 0.6 | one 1.07 hold with shake-free flash+explosion starting at once | 0.53 |
| after LP event | 0.5 | objects idle + 0.37 | +0.18 |
Notes: the original has no pre-explosion "shake" in the code (the destroyed card's own sprite effect does the flash and burst); the shake was
reconstructed from the clip. The video also has a ~2.4 s gap (frames 26-49) between the end of the impact ring and the shine/explosion where nothing
moves; the code has no matching timer in the sub-states above, so it is probably a response window (CPU or player decision) and was left out.

## 7. Measured from a 60fps recording (user's clip 2026-10-20 18-22-48: Sangan 1000 attacks Giant Rat 1400 ATK)
Times are from the target click (t=0). Pixel-change measurements per 1/60 s around the attacker, target and LP counter.
| t (s) | what happens | length |
|---|---|---|
| -0.35 | cursor reaches the target; sword already aimed while hovering | - |
| 0.00 | click: sword leaves the attacker | travel 0.25 |
| 0.30 | impact ring at the target (peak ~0.58) | 0.47 |
| 0.77 | nothing moves (damage step) | 1.06 |
| 1.83 | surviving defender: white diagonal shine (its player takes no damage) | 0.30 |
| 2.13 | nothing moves | 0.69 |
| 2.82 | "-400" pops over the damaged player's battling monster (Sangan), hop | 0.50 |
| 3.32 | number holds (Sangan's ATK/DEF label disappears at 3.93) | 1.18 |
| 4.50 | LP countdown 400 -> 0 in 100 steps, one step per 1/30 s; number removed with it | 0.12 |
| 4.62 | pause | 0.33 |
| 4.95 | destroyed card: growing star over the still-visible card | 0.48 |
| 5.43 | yellow puffs / orange ring; card gone | 0.27 |
| 5.70 | card in the Graveyard; its trigger (Sangan) flashes ~0.35 later | - |
So the original counts LP damage down BEFORE the destroyed monster explodes, and there is no shake. Banners in the same clip:
Draw ~1.0 s, Standby ~0.63 s (cut by Main 1), Main 1 ~1.0 s, Battle ~1.3 s. The clip has no audio, so sound timing is not measured.
ui/battle_timing.gd now uses these measured values and ui/duel_board.gd `_present_battle_result` plays the battle results in this order.

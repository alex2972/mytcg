extends RefCounted
## BATTLE TIMING SETTINGS — edit these numbers, save, and restart the duel.
## All values are seconds. Smaller duration = faster animation.
## Pause values add waiting BETWEEN animations; 0.0 means no extra wait.
## Card-effect prompts/animations still resolve before combat continues.
## Defaults are measured from a 60fps recording of the original (docs/BATTLE_TIMING_NATIVE.md).

# Clicking Battle Phase -> announcement finishes -> attacker selection unlocks.
# Recording: Battle Phase banner ~1.3 s, the other phases ~1.0 s.
const PHASE_ENTRY_DURATION := 1.33
const OTHER_PHASE_DURATION := 1.05
const AFTER_PHASE_ENTRY_PAUSE := 0.0

# Clicking a target -> sword arrives. Aiming happens while hovering / during the flight.
const SWORD_FLIGHT_DURATION := 0.25

# Sword arrives -> impact ring finishes -> optional pause -> flip/reactions.
const IMPACT_DURATION := 0.47
const AFTER_IMPACT_PAUSE := 0.0
const CARD_FLIP_DURATION := 0.26

# Impact ring gone -> quiet damage step -> shine / damage numbers.
const DAMAGE_STEP_DELAY := 1.06

# Surviving defender's white shine (only when its own player takes no damage),
# then the rest of the original's shine stage before the damage numbers.
const SURVIVAL_SHINE_DURATION := 0.30
const AFTER_SURVIVAL_SHINE_PAUSE := 0.69

# Damage number pops over the damaged player's monster (0.53 s hop), stays this long,
# then counts down together with the LP bar at this many steps per second.
const DAMAGE_NUMBER_HOLD := 1.15
const LP_COUNT_RATE := 30.0

# LP countdown finishes -> destroyed monsters start their star/explosion.
const AFTER_LP_COUNT_PAUSE := 0.33

# Optional shake before destruction. The original has none (0.0).
const SHAKE_DURATION := 0.7
const AFTER_SHAKE_PAUSE := 0.3

# Destruction: growing star over the still-visible card (~0.46 s), then the puffs (~0.29 s).
# Graveyard handoff follows the animation stage, automatically scaling with duration.
const DESTRUCTION_DURATION := 0.75
# Card lands in the Graveyard -> optional pause -> its effects (e.g. Sangan) start.
const AFTER_DESTRUCTION_PAUSE := 0.35

# All destruction, effects and player LP animations finish -> next action unlocks.
const AFTER_ATTACK_PAUSE := 0.33

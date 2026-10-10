# Duel rules implemented (core/duel.gd)

Confirmed by the original's own tutorial text (dialog strings 4201-4265) - covered by tests/test_duel.gd:
- 8000 LP. Six phases: Draw, Standby, Main 1, Battle, Main 2, End. The first player draws on turn 1. Cannot draw => lose.
- 5 monster zones, 5 spell/trap zones, 1 field-spell zone, graveyard, fusion deck (not counted toward the 40-card minimum).
- Summon = face-up attack; Set = face-down defense. Only attack-position face-up monsters attack. Monsters may attack the turn they are summoned.
- Level 5-6 need 1 tribute, 7+ need 2 (dialog strings 1-2).
- Battle: ATK vs ATK -> loser destroyed, difference to its controller. ATK vs DEF -> if ATK > DEF defender destroyed, no damage;
  if ATK < DEF attacker takes the difference, nothing destroyed. Direct attack when the opponent has no monsters.

ASSUMED (standard rules; verify against the exe/original when relevant):
- One Normal Summon/Set per turn; one position change per monster per turn; none on the turn it was summoned/Set.
- Equal ATK: both destroyed. Equal ATK vs DEF: nothing happens. Hand limit 6 at the End Phase (discard excess).
- Gods (kind 24) need 3 tributes. Opening hand 5.
- No first-turn attack restriction (the tutorial attacks on the player's first turn).

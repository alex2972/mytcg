class_name FxCustom
extends RefCounted
## One-off effects that the generic verbs cannot express. Referenced from effect data as {"op": "custom", "fn": "<name>"}.
## Same return convention as FxOps.run(): null = continue, Dictionary = pending decision, "pushed", "abort".

static func run(fn: String, _step: Dictionary, ctx: Dictionary, fx: Fx):
	var d: Duel = fx.duel
	match fn:
		"crush_card":
			var foe: int = 1 - int(ctx["controller"])
			for c in d.monsters_of(foe):
				if d.atk_of(c) >= 1500:
					d.destroy_card(c, "effect")
			for c in (d.side(foe).hand as Array).duplicate():
				if d.is_monster(c) and d.atk_of(c) >= 1500:
					d.send_to_grave(c, "crush_card")
			for c in (d.side(foe).deck as Array).duplicate():
				pass
			d.crush_until[foe] = d.turn + 6
		"magical_hats":
			var me: int = ctx["controller"]
			var chosen: Array = ctx["vars"].get("m", [])
			var decoys := []
			for i in 2:
				var tk := d.new_token("Hat Token", me)
				if d.special_summon(tk, me, "def", false) == "":
					tk.flags["destroy_at_battle_end"] = true
					decoys.append(tk)
			var all := decoys.duplicate()
			if not chosen.is_empty():
				d.force_position(chosen[0], "def", false, true)
				all.append(chosen[0])
			# shuffle the three across the zones they occupy
			var zones := []
			for c in all:
				zones.append((d.side(me).monsters as Array).find(c))
			for i in range(zones.size() - 1, 0, -1):
				var j := d.rng.randi_range(0, i)
				var tmp = zones[i]
				zones[i] = zones[j]
				zones[j] = tmp
			for i in all.size():
				d.side(me).monsters[zones[i]] = all[i]
			d.negate_current_attack()
		"destiny_board":
			var board: DCard = ctx["src"]
			var owner: int = ctx["controller"]
			var letters := ["I", "N", "A", "L"]
			var placed: Array = board.flags.get("board_cards", [])
			for uid in placed:
				var pc := d.card_by_uid(uid)
				if pc == null or not d.is_on_field(pc):
					for u2 in placed:
						var pc2 := d.card_by_uid(u2)
						if pc2 != null and d.is_on_field(pc2):
							d.send_to_grave(pc2, "destiny_board")
					placed = []
					break
			var want := 'Spirit Message "%s"' % letters[placed.size()]
			var found: DCard = null
			for c in d.side(owner).hand + d.side(owner).deck:
				if d.db.card_name(c.idx) == want:
					found = c
					break
			var zone: int = d.free_zone(d.side(owner).spells)
			if found != null and zone != -1:
				var from_deck: bool = (d.side(owner).deck as Array).has(found)
				d._detach(found)
				d.side(owner).spells[zone] = found
				found.face_up = true
				found.controller = owner
				placed.append(found.uid)
				if from_deck:
					d.shuffle_deck(owner)
				d._emit("set_spell", {"player": owner, "uid": found.uid, "zone": zone})
			board.flags["board_cards"] = placed
			if placed.size() == 4:
				d.force_win(owner, "destiny_board")
		"damage_watched":
			var watcher: DCard = ctx["src"]
			var watched := d.card_by_uid(int(watcher.flags.get("watch", -1)))
			if watched == null or not d.is_on_field(watched):
				d.destroy_card(watcher, "effect")
			elif d.turn_player == watched.controller:
				d.damage_player(watched.controller, 500, "effect")
		"cyber_jar":
			# everything on the field is destroyed, then both players pick up 5 cards: Level 4 or lower monsters are
			# Special Summoned face-up, everything else goes to the hand
			for c in d.monsters_of(0) + d.monsters_of(1):
				d.destroy_card(c, "effect")
			for p in [ctx["controller"], 1 - int(ctx["controller"])]:
				for i in 5:
					var s: Duel.PlayerSide = d.side(p)
					if s.deck.is_empty():
						break
					var top: DCard = s.deck.back()
					if d.is_monster(top) and d.level_of(top) <= 4 and d.free_zone(s.monsters) != -1:
						d.special_summon(top, p, "atk", true)
					else:
						s.deck.erase(top)
						s.hand.append(top)
						d._emit("draw", {"player": p, "uid": top.uid})
		"morphing_jar2":
			var returned := [0, 0]
			for p in 2:
				for c in d.monsters_of(p):
					if d.level_of(c) <= 4:
						returned[p] += 1
					d.return_to_deck(c, "shuffle")
			for p in 2:
				var found := 0
				var s2: Duel.PlayerSide = d.side(p)
				while found < returned[p] and not s2.deck.is_empty():
					var top2: DCard = s2.deck.back()
					if d.is_monster(top2) and d.level_of(top2) <= 4 and d.free_zone(s2.monsters) != -1:
						d.special_summon(top2, p, "def", false)
						found += 1
					else:
						d.send_to_grave(top2, "discard")
		"chosen_one":
			# Chosen One: the opponent picks at random 1 of the 3 selected cards (vars m = the Monster, o = the 2 others)
			var me2: int = ctx["controller"]
			var trio: Array = (ctx["vars"].get("m", []) as Array) + (ctx["vars"].get("o", []) as Array)
			if trio.is_empty():
				return null
			var picked: DCard = trio[d.rng.randi_range(0, trio.size() - 1)]
			var hit: bool = d.is_monster(picked) and d.free_zone(d.side(me2).monsters) != -1
			if hit:
				trio.erase(picked)
				d.special_summon(picked, me2, "def" if int(ctx["vars"].get("pos", 0)) == 1 else "atk", true)
			for c in trio:
				d.send_to_grave(c, "effect")
		"nobleman_ext":
			# Nobleman of Extermination: remove the selected face-down Spell/Trap from play; for a Trap, every Trap of the
			# same name leaves both Decks (removed from play) and the Decks are shuffled
			for c in ctx["vars"].get("t", []):
				var is_trap: bool = d.card_data(c).get("type", "") == "trap"
				var nm: String = d.db.card_name(c.idx)
				d.banish_card(c)
				if is_trap:
					for p2 in 2:
						for dc in (d.side(p2).deck as Array).duplicate():
							if d.db.card_name(dc.idx) == nm:
								d.banish_card(dc)
						d.shuffle_deck(p2)
		"de_fusion":
			# De-Fusion: the Fusion Monster goes back to the Fusion Deck; if all its materials are in my Graveyard they are Special Summoned
			var me3: int = ctx["controller"]
			for c in ctx["vars"].get("t", []):
				var recipe: Array = d.db.fusion_recipe(d.db.card_name(c.idx))
				var on_field: bool = d.is_on_field(c)
				d._detach(c)
				if on_field:
					d._leave_field_cleanup(c)
				c.controller = c.owner
				c.face_up = false
				d.side(c.owner).extra.append(c)
				d._emit("to_deck", {"player": c.owner, "uid": c.uid})
				var picked := []
				for need in recipe:
					for g in d.side(me3).grave:
						if d.db.card_name(g.idx) == need and not picked.has(g) and d.is_monster(g):
							picked.append(g)
							break
				if not recipe.is_empty() and picked.size() == recipe.size() and (d.side(me3).monsters as Array).count(null) >= picked.size():
					for g in picked:
						d.special_summon(g, me3, "atk", true)
		_:
			push_warning("unknown custom effect: " + fn)
	return null

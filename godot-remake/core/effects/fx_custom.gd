class_name FxCustom
extends RefCounted
## One-off effects that the generic verbs cannot express. Referenced from effect data as {"op": "custom", "fn": "<name>"}.
## Same return convention as FxOps.run(): null = continue, Dictionary = pending decision, "pushed", "abort".

static func run(fn: String, _step: Dictionary, ctx: Dictionary, fx: Fx):
	var d: Duel = fx.duel
	match fn:
		"bait_doll":
			var selected: Array = ctx["vars"].get("t", [])
			if selected.is_empty():
				return null
			var target: DCard = selected[0]
			if not d.is_on_field(target) or target.face_up or d.card_data(target).get("type", "") != "trap":
				return null
			# No chain can be opened during resolution. Force a legal Trap's costs,
			# targets and effect here; its negation cannot stop a resolving Spell.
			var effs: Array = fx.edb.for_number(target.number)
			for i in effs.size():
				var e: Dictionary = effs[i]
				var free_timing: bool = d.db.card_name(target.idx) in ["Waboku", "Just Desserts", "Jar of Greed", "Time Seal", "Skull Dice", "Reverse Trap", "Windstorm of Etaqua", "Reinforcements", "Castle Walls", "Snake Fang", "Deal of Phantom", "Ring of Destruction", "Two-Pronged Attack", "Gift of The Mystical Elf", "Lightforce Sword", "Dust Tornado", "Graverobber", "Backup Soldier", "Gamble", "Earthshaker", "Collected Power", "Metalmorph", "Call Of The Haunted", "Shadow Spell", "Spellbinding Circle", "Acid Trap Hole", "Skull Lair", "Aqua Chorus", "Mask of Restrict", "The Regulation of Tribe", "Destiny Board", "Robbin' Goblin", "Royal Decree", "Royal Command", "Imperial Order", "Solemn Wishes", "Mirror Wall", "Gravity Bind", "Minor Goblin Official", "Skull Invitation", "The Eye of Truth", "Respect Play", "Light of Intervention", "Dragon Capture Jar", "Tornado Wall", "Graverobber's Retribution", "The Emperor's Holiday", "Anti-Spell Fragrance", "Magic Thorn", "Blind Destruction", "Infinite Dismissal", "Fairy Box", "Call of the Dark"]
				var forced_effect: Dictionary = e.duplicate(true)
				if free_timing:
					forced_effect["cond"] = (e.get("cond", []) as Array).filter(func(c): return c.get("c", "") != "event_by")
				var forced := {"src": target, "controller": target.controller, "vars": {}, "event": {"player": ctx["controller"], "uid": ctx["src"].uid}, "effect": forced_effect, "idx": i, "forced_by": ctx["src"]}
				# Check counter conditions against the resolving Bait Doll, not the next link.
				fx.chain.append({"card": ctx["src"], "player": ctx["controller"], "kind": "spell", "ctx": ctx})
				var conditions: bool = fx.ops.conditions_ok(forced_effect.get("cond", []), forced, true) == ""
				fx.chain.pop_back()
				var legal: bool = (d.db.card_name(target.idx) != "Skull Dice" or d.phase == "battle") and e.get("type", "") in ["trap", "continuous_trap", "counter"] and target.summon_turn < d.turn and (free_timing or fx._event_matches(e, "activated_spell")) and not d.prohibited(target) and conditions
				if not legal:
					continue
				target.face_up = true
				if fx.rule_active("no_trap"):
					if e.get("type", "") != "continuous_trap":
						d.destroy_card(target, "effect")
					return null
				target.used[i] = d.turn
				d.log_event("flip", {"player": target.controller, "uid": target.uid})
				fx.push_call(func(): fx._dispose_after_resolution({"card": target, "ctx": forced}))
				fx.push_script(e.get("cost", []) + e.get("target", []) + e.get("do", []), forced)
				return "pushed"
			d.effect_player = ctx["controller"]
			d.destroy_card(target, "effect")
			d.effect_player = -1
		"summon_procedure":
			var kind: String = _step["kind"]
			var materials: Array = procedure_materials(d, ctx["src"], kind)
			ctx["vars"]["_materials"] = materials
			fx.push_script([{"op": "select", "as": "material", "from": "$_materials", "n": 1, "cost": true, "prompt": 154}, {"op": "choice", "as": "position", "count": 2, "labels": ["Face-up Attack", "Face-up Defense"]}, {"op": "custom", "fn": "procedure_finish", "kind": kind}], ctx)
			return "pushed"
		"procedure_finish":
			var source: DCard = ctx["src"]
			var chosen: Array = ctx["vars"].get("material", [])
			if chosen.is_empty() or not procedure_materials(d, source, _step["kind"]).has(chosen[0]):
				return null
			d.send_to_grave(chosen[0], "tribute")
			source.flags["procedure_authorized"] = true
			if d.special_summon(source, ctx["controller"], "def" if int(ctx["vars"].get("position", 0)) == 1 else "atk") == "":
				source.properly_summoned = true
			source.flags.erase("procedure_authorized")
		"labyrinth_summon":
			var wall: DCard = ctx["src"].equipped_to
			var shadows := []
			for c in d.side(ctx["controller"]).deck:
				if d.db.card_name(c.idx) == "Wall Shadow" and procedure_materials(d, c, "wall_shadow").has(wall):
					shadows.append(c)
			ctx["vars"]["_shadows"] = shadows
			fx.push_script([{"op": "select", "as": "shadow", "from": "$_shadows", "n": 1, "prompt": 241}, {"op": "choice", "as": "position", "count": 2, "labels": ["Face-up Attack", "Face-up Defense"]}, {"op": "custom", "fn": "labyrinth_finish"}], ctx)
			return "pushed"
		"labyrinth_finish":
			var chosen_shadow: Array = ctx["vars"].get("shadow", [])
			var host: DCard = ctx["src"].equipped_to
			if not chosen_shadow.is_empty() and procedure_materials(d, chosen_shadow[0], "wall_shadow").has(host):
				d.send_to_grave(host, "tribute")
				chosen_shadow[0].flags["procedure_authorized"] = true
				if d.special_summon(chosen_shadow[0], ctx["controller"], "def" if int(ctx["vars"].get("position", 0)) == 1 else "atk") == "":
					chosen_shadow[0].properly_summoned = true
				chosen_shadow[0].flags.erase("procedure_authorized")
				d.shuffle_deck(ctx["controller"])
		"cocoon_equip":
			var cocoon: DCard = ctx["src"]
			var hosts: Array = ctx["vars"].get("t", [])
			if not hosts.is_empty() and d.is_on_field(hosts[0]) and hosts[0].face_up:
				var z: int = d.free_zone(d.side(ctx["controller"]).spells)
				if z != -1:
					d._detach(cocoon)
					d.side(ctx["controller"]).spells[z] = cocoon
					cocoon.face_up = true
					d.equip_card(cocoon, hosts[0], {"cocoon_stats": true})
		"major_riot":
			var counts := [0, 0]
			for c in d.monsters_of(0) + d.monsters_of(1):
				if c.token == "" and d.db.fusion_recipe(d.db.card_name(c.idx)).is_empty():
					counts[c.owner] += 1
				d.return_to_hand(c)
			for player in [1 - int(ctx["controller"]), int(ctx["controller"])]:
				var pool: Array = d.side(player).hand.filter(func(c): return d.is_monster(c) and d.level_of(c) <= 4 and d.special_summon_problem(c, player, true) == "")
				var n: int = mini(counts[player], mini(pool.size(), d.side(player).monsters.count(null)))
				if n > 0:
					var subctx := {"src": ctx["src"], "controller": player, "vars": {"pool": pool}, "event": ctx["event"]}
					fx.push_script([{"op": "yesno", "as": "summon", "prompt_text": "Special Summon %d monster(s) in face-down Defense Position?" % n, "show_hands": true}, {"op": "if", "cond": [{"c": "var_true", "name": "summon"}], "then": [{"op": "select", "as": "m", "from": "$pool", "n": n, "auto": false, "prompt": 241}, {"op": "special_summon", "what": "$m", "pos": "def", "face_up": false}]}], subctx)
			for player in [1, 0]:
				var reveal_ctx := {"src": ctx["src"], "controller": player, "vars": {}, "event": ctx["event"]}
				fx.push_script([{"op": "custom", "fn": "riot_show_hands"}], reveal_ctx)
			return "pushed"
		"riot_show_hands":
			var revealed: Array = d.side(1 - int(ctx["controller"])).hand.map(func(c): return c.uid)
			return {"type": "choice", "player": ctx["controller"], "as": "seen", "count": 1, "labels": ["OK"], "reveal_cards": revealed, "prompt_text": "Your opponent's hand (Major Riot)."}
		"declare_card":
			var names := []
			for i in range(1, d.db.cards.size()):
				var name: String = d.db.card_name(i)
				if name != "" and not names.has(name):
					names.append(name)
			names.sort()
			ctx["vars"]["names"] = names
			return {"type": "choice", "player": ctx["controller"], "as": "named", "count": names.size(), "labels": names, "catalog": true, "prompt_text": "Declare a card name."}
		"prohibition":
			ctx["src"].flags["prohibited_name"] = ctx["vars"]["names"][int(ctx["vars"]["named"])]
		"inspection":
			var seen: Array = ctx["vars"].get("peek", [])
			if not seen.is_empty():
				return {"type": "choice", "player": ctx["controller"], "as": "seen", "count": 1, "labels": ["OK"], "reveal": seen[0].uid, "prompt_text": d.db.card_name(seen[0].idx)}
		"inspection_again":
			fx.window("inspection_again", {"player": 1 - int(ctx["controller"]), "inspection": ctx["src"].uid})
		"imitation_cost":
			ctx["vars"]["materials"] = imitation_materials(d, ctx["controller"])
			fx.push_script([{"op": "select", "as": "m", "from": "$materials", "n": 1, "cost": true, "prompt": 154}, {"op": "custom", "fn": "imitation_tribute"}], ctx)
			return "pushed"
		"imitation_tribute":
			var offered: Array = ctx["vars"].get("m", [])
			if not offered.is_empty():
				ctx["vars"]["level"] = d.level_of(offered[0]) + 1
				d.send_to_grave(offered[0], "tribute")
		"imitation_summon":
			var insects: Array = d.side(ctx["controller"]).deck.filter(func(c): return d.is_monster(c) and d.race_of(c) == fx.ops.race_id("Insect") and d.level_of(c) == int(ctx["vars"].get("level", -1)) and d.special_summon_problem(c, ctx["controller"], true) == "")
			ctx["vars"]["insects"] = insects
			if insects.is_empty():
				d.shuffle_deck(ctx["controller"])
				return null
			fx.push_script([{"op": "select", "as": "insect", "from": "$insects", "n": 1, "auto": false, "prompt": 241}, {"op": "choice", "as": "position", "count": 2, "labels": ["Face-up Attack", "Face-down Defense"], "prompt_text": "Choose the summon position."}, {"op": "custom", "fn": "imitation_finish"}], ctx)
			return "pushed"
		"imitation_finish":
			for c in ctx["vars"].get("insect", []):
				var defense: bool = int(ctx["vars"].get("position", 0)) == 1
				d.special_summon(c, ctx["controller"], "def" if defense else "atk", not defense)
			d.shuffle_deck(ctx["controller"])
		"makiu_target":
			ctx["vars"]["makiu_monsters"] = makiu_monsters(d, ctx["controller"])
			fx.push_script([{"op": "select", "as": "t", "from": "$makiu_monsters", "n": 1, "prompt": 241}], ctx)
			return "pushed"
		"makiu":
			var selected: Array = ctx["vars"].get("t", [])
			if not selected.is_empty() and d.is_on_field(selected[0]) and selected[0].face_up and not d.spell_unaffected(selected[0], ctx["src"]):
				var attack: int = d.atk_of(selected[0])
				for c in d.monsters_of(1 - int(ctx["controller"])):
					if d.def_of(c) < attack:
						d.destroy_card(c, "effect")
		"manga_summon":
			fx.push_script([{"op": "select", "as": "tributes", "from": "self.monsters", "filter": {"tribute_legal": true}, "n": 2, "cost": true, "auto": false, "prompt": 154}, {"op": "choice", "as": "position", "count": 2, "labels": ["Face-up Attack", "Face-up Defense"]}, {"op": "custom", "fn": "manga_finish"}], ctx)
			return "pushed"
		"manga_finish":
			if not manga_possible(d, ctx["src"]):
				return null
			for c in ctx["vars"].get("tributes", []):
				d.send_to_grave(c, "tribute")
			ctx["src"].flags["procedure_authorized"] = true
			if d.special_summon(ctx["src"], ctx["controller"], "def" if int(ctx["vars"].get("position", 0)) == 1 else "atk", true) == "":
				ctx["src"].properly_summoned = true
			ctx["src"].flags.erase("procedure_authorized")
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
		"tailor_select":
			var equips: Array = ctx["vars"].get("e", [])
			if equips.is_empty():
				return null
			var hosts := []
			for c in d.monsters_of(0) + d.monsters_of(1):
				if tailor_host_valid(equips[0], c, fx):
					hosts.append(c)
			ctx["vars"]["_tailor_hosts"] = hosts
			if hosts.is_empty():
				return null
			fx.push_script([{"op": "select", "as": "h", "from": "$_tailor_hosts", "n": 1, "auto": false, "prompt": 140}], ctx)
			return "pushed"
		"tailor_finish":
			var equips: Array = ctx["vars"].get("e", [])
			var hosts: Array = ctx["vars"].get("h", [])
			if not equips.is_empty() and not hosts.is_empty() and tailor_host_valid(equips[0], hosts[0], fx):
				d.equip_card(equips[0], hosts[0], equips[0].equip_mod)
		"chosen_one":
			var trio: Array = (ctx["vars"].get("m", []) as Array) + (ctx["vars"].get("o", []) as Array)
			if trio.size() != 3:
				return null
			for i in range(trio.size() - 1, 0, -1):
				var j: int = d.rng.randi_range(0, i)
				var swap = trio[i]
				trio[i] = trio[j]
				trio[j] = swap
			ctx["vars"]["_chosen_trio"] = trio
			fx.push_script([{"op": "choice", "as": "_chosen_pick", "chooser": "opp", "count": 3, "labels": ["Face-down card 1", "Face-down card 2", "Face-down card 3"], "prompt_text": "Choose one of the three face-down cards."}, {"op": "custom", "fn": "chosen_one_reveal"}, {"op": "custom", "fn": "chosen_one_finish"}], ctx)
			return "pushed"
		"chosen_one_reveal":
			var trio: Array = ctx["vars"]["_chosen_trio"]
			var picked: DCard = trio[int(ctx["vars"]["_chosen_pick"])]
			ctx["vars"]["_chosen_card"] = [picked]
			return {"type": "choice", "player": ctx["controller"], "as": "_chosen_seen", "count": 1, "labels": ["OK"], "reveal_cards": [picked.uid], "prompt_text": "Chosen One selected %s." % d.db.card_name(picked.idx)}
		"chosen_one_finish":
			var picked: DCard = ctx["vars"]["_chosen_card"][0]
			for c in ctx["vars"]["_chosen_trio"]:
				if c != picked:
					d.send_to_grave(c, "effect")
			if d.is_monster(picked) and d.special_summon_problem(picked, ctx["controller"], true) == "" and d.free_zone(d.side(ctx["controller"]).monsters) != -1:
				fx.push_script([{"op": "choice", "as": "pos", "count": 2, "labels": ["Face-up Attack", "Face-up Defense"], "prompt_text": "Choose the Special Summon position."}, {"op": "custom", "fn": "chosen_one_summon"}], ctx)
				return "pushed"
			d.send_to_grave(picked, "effect")
		"chosen_one_summon":
			var picked: DCard = ctx["vars"]["_chosen_card"][0]
			d.special_summon(picked, ctx["controller"], "def" if int(ctx["vars"].get("pos", 0)) == 1 else "atk", true)
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
			var me3: int = ctx["controller"]
			for c in ctx["vars"].get("t", []):
				if not d.is_on_field(c) or d.spell_unaffected(c, ctx["src"]):
					continue
				var recipe: Array = d.db.fusion_recipe(d.db.card_name(c.idx))
				d._detach(c)
				d._leave_field_cleanup(c)
				c.controller = c.owner
				c.face_up = false
				d.side(c.owner).extra.append(c)
				d._emit("to_deck", {"player": c.owner, "uid": c.uid})
				var picked := []
				for need in recipe:
					for g in d.side(me3).grave:
						if d.db.card_name(g.idx) == need and not picked.has(g) and d.is_monster(g) and d.special_summon_problem(g, me3, true) == "":
							picked.append(g)
							break
				if not recipe.is_empty() and picked.size() == recipe.size() and (d.side(me3).monsters as Array).count(null) >= picked.size():
					var summons := []
					for i in picked.size():
						var key := "_defusion_material_%d" % i
						ctx["vars"][key] = [picked[i]]
						summons.append({"op": "choice", "as": "_defusion_position", "count": 2, "labels": ["Face-up Attack", "Face-up Defense"], "prompt_text": "Choose the position for %s." % d.db.card_name(picked[i].idx)})
						summons.append({"op": "custom", "fn": "de_fusion_summon", "material": key})
					fx.push_script([{"op": "yesno", "as": "_defusion_revive", "prompt_text": "Special Summon the Fusion Materials from your Graveyard?"}, {"op": "if", "cond": [{"c": "var_true", "name": "_defusion_revive"}], "then": summons}], ctx)
					return "pushed"
		"de_fusion_summon":
			for g in ctx["vars"].get(_step["material"], []):
				if d.side(ctx["controller"]).grave.has(g):
					d.special_summon(g, ctx["controller"], "def" if int(ctx["vars"].get("_defusion_position", 0)) == 1 else "atk", true)
		"dimensionhole":
			for c in ctx["vars"].get("t", []):
				d.banish_card(c)
				d.dimension_holes.append({"uid": c.uid, "player": c.owner})
		"monster_recovery":
			# the chosen monster joins the Deck, the hand is shuffled into the Deck and the same number of cards is drawn
			var me4: int = ctx["controller"]
			for c in ctx["vars"].get("t", []):
				d.return_to_deck(c, "shuffle")
			var drawn: int = d.side(me4).hand.size()
			for c in (d.side(me4).hand as Array).duplicate():
				d.return_to_deck(c, "shuffle")
			d.shuffle_deck(me4)
			d.draw_cards(me4, drawn)
		"hand_mirror":
			# Fairy's Hand Mirror: the opponent's Spell that designates 1 monster is switched to another correctly targeted monster
			if fx.chain.is_empty():
				return null
			var mlink: Dictionary = fx.chain.back()
			var mctx: Dictionary = mlink["ctx"]
			var mstep: Dictionary = {}
			for st in (mctx["effect"].get("target", []) as Array):
				if st.get("op", "") == "select":
					mstep = st
					break
			if mstep.is_empty():
				return null
			var olds: Array = mctx["vars"].get(mstep["as"], [])
			var others: Array = fx.ops.select_candidates(mstep, mctx).filter(func(x): return not olds.has(x))
			if others.is_empty():
				return null
			ctx["vars"]["_hm"] = others
			fx.push_script([{"op": "select", "as": "_nt", "from": "$_hm", "n": 1, "prompt": 94}, {"op": "custom", "fn": "hand_mirror_apply"}], ctx)
			return "pushed"
		"hand_mirror_apply":
			if not fx.chain.is_empty() and not (ctx["vars"].get("_nt", []) as Array).is_empty():
				var alink: Dictionary = fx.chain.back()
				for st in (alink["ctx"]["effect"].get("target", []) as Array):
					if st.get("op", "") == "select":
						alink["ctx"]["vars"][st["as"]] = ctx["vars"]["_nt"]
						break
		"shadow_scout":
			# Hiro's Shadow Scout: the opponent draws 3 cards, both players see them and every Spell among them is discarded
			var foe3: int = 1 - int(ctx["controller"])
			d.draw_cards(foe3, 3)
			var hand3: Array = d.side(foe3).hand
			for c in hand3.slice(maxi(0, hand3.size() - 3)):
				if d.card_data(c).get("type", "") == "spell":
					d.send_to_grave(c, "discard")
		"swap_control":
			# Invader of the Throne: switch control of this card and the selected monster (not during the Battle Phase)
			var mine2: DCard = ctx["src"]
			for theirs2 in ctx["vars"].get("t", []):
				var me5: int = mine2.controller
				var zi: int = (d.side(me5).monsters as Array).find(mine2)
				var zj: int = (d.side(theirs2.controller).monsters as Array).find(theirs2)
				if zi != -1 and zj != -1 and d.is_on_field(mine2) and d.is_on_field(theirs2):
					var other_side: int = theirs2.controller
					d.side(me5).monsters[zi] = theirs2
					d.side(other_side).monsters[zj] = mine2
					mine2.controller = other_side
					theirs2.controller = me5
					d._emit("control", {"player": me5, "uid": theirs2.uid})
					d._emit("control", {"player": other_side, "uid": mine2.uid})
		"probe_destroy":
			# Trap Master, Reaper of the Cards, Armed Ninja, De-Spell: flip the selected card face-up without activating it;
			# destroy it if it is the right kind of card, otherwise turn it back face-down
			for c in ctx["vars"].get("t", []):
				var right: bool = d.card_data(c).get("type", "") == str(_step.get("kind", "trap"))
				if right:
					c.face_up = true
					d.destroy_card(c, "effect")
				elif not c.face_up:
					d.log_event("flip", {"player": c.controller, "uid": c.uid})
		"acid_trap_hole":
			for c in ctx["vars"].get("t", []):
				c.face_up = true
				if d.def_of(c) <= 2000:
					d.destroy_card(c, "effect")
				else:
					c.face_up = false
		_:
			push_warning("unknown custom effect: " + fn)
	return null

## Special Summon procedures must stay legal before the Tribute is committed.
static func procedure_materials(d: Duel, source: DCard, kind: String) -> Array:
	var p: int = source.owner
	if d.prohibited(source) or d.fx.rule_active("no_special_summon") or d.fx.rule_active("no_summon_any") or d.fx.rule_active("no_tribute"):
		return []
	if kind in ["wall_shadow", "metalzoa"] and not d.side(p).deck.has(source):
		return []
	if kind in MOTH_TURNS and not d.side(p).hand.has(source):
		return []
	var result := []
	for c in d.monsters_of(p):
		if not c.face_up or d.prohibited(c):
			continue
		var name: String = {"wall_shadow": "Labyrinth Wall", "metalzoa": "Zoa"}.get(kind, "Petit Moth")
		if d.db.card_name(c.idx) != name:
			continue
		for eq in c.equips:
			if not eq.face_up or not d.is_on_field(eq) or d.fx._negated_this_turn(eq):
				continue
			if kind == "wall_shadow" and d.db.card_name(eq.idx) == "Magical Labyrinth":
				result.append(c)
			elif kind == "metalzoa" and d.db.card_name(eq.idx) == "Metalmorph":
				result.append(c)
			elif kind in MOTH_TURNS and d.db.card_name(eq.idx) == "Cocoon of Evolution" and int(eq.flags.get("cocoon_turns", 0)) >= int(MOTH_TURNS[kind]):
				result.append(c)
	return result

## Turns of the Petit Moth's controller that must pass with "Cocoon of Evolution" equipped before each Moth can be summoned.
const MOTH_TURNS := {"larvae_moth": 2, "great_moth": 4, "ultimate_moth": 6}

static func imitation_materials(d: Duel, p: int) -> Array:
	if d.fx.rule_active("no_tribute") or d.fx.rule_active("no_special_summon") or d.fx.rule_active("no_summon_any"):
		return []
	return d.monsters_of(p).filter(func(m):
		if m.token in ["Sheep Token", "Kuriboh Token"]:
			return false
		for c in d.side(p).deck:
			if d.is_monster(c) and d.race_of(c) == d.fx.ops.race_id("Insect") and d.level_of(c) == d.level_of(m) + 1 and d.special_summon_problem(c, p, true) == "":
				return true
		return false)

static func makiu_monsters(d: Duel, p: int) -> Array:
	return d.monsters_of(p).filter(func(c): return c.face_up and (d.db.card_name(c.idx) == "Summoned Skull" or d.race_of(c) == d.fx.ops.race_id("Thunder")))

static func manga_possible(d: Duel, c: DCard) -> bool:
	return d.side(c.owner).hand.has(c) and not d.prohibited(c) and d.has_face_up_name("Toon World") and not d.fx.rule_active("no_tribute") and not d.fx.rule_active("no_special_summon") and not d.fx.rule_active("no_summon_any") and d.monsters_of(c.owner).filter(func(m): return m.token not in ["Sheep Token", "Kuriboh Token"]).size() >= 2

## Native Tailor uses the Equip Card's own host legality (0056fc50).
static func tailor_host_valid(equip: DCard, host: DCard, fx: Fx) -> bool:
	var d: Duel = fx.duel
	if not d.is_on_field(equip) or equip.equipped_to == null or not d.is_on_field(host) or not host.face_up or not d.is_monster(host) or equip.equipped_to == host or d.spell_unaffected(host, equip):
		return false
	var eqctx := {"src": equip, "controller": equip.controller, "vars": {}, "event": {}}
	for effect in fx.edb.for_number(equip.number):
		for step in effect.get("target", []):
			if step.get("op", "") == "select":
				var from: String = step.get("from", "monsters")
				if from == "self.monsters" and host.controller != equip.controller:
					continue
				if from == "opp.monsters" and host.controller == equip.controller:
					continue
				if fx.ops.matches(host, step.get("filter", {}), eqctx):
					return true
	return false

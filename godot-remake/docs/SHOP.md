# Shop, accounts and DP (foundations)

Open the **Shop** plank, the fourth row of the main menu. `ui/main.gd` routes it to `ui/shop.gd`; the themed Back button and Escape return to the main menu. Options is now the gear at the top left (its screen is not implemented yet).
The temporary **Account** button at the lower left switches accounts or creates a new one.

## Architecture (built for a future authoritative server)
```
ui/shop.gd, ui/title_screen.gd        screens: show results, send ids only
autoload/session.gd  (Session)        signed-in account + the backend object
core/shop/shop_backend.gd             the API: get_profile, get_catalog, purchase (all awaited)
core/shop/local_shop_backend.gd       offline implementation = what the server will do
core/shop/pack_opener.gd              rolls pack contents from pools with the backend's RNG
core/accounts/account_store.gd        local "database": one folder per account
data/shop/catalog.json                products, prices, pack contents, pools, starting DP
```
Rules the screens follow so the online version is a drop-in:
- Requests carry only an account id and a product id. Prices, balances and rolled cards come back from the backend; the client never computes them.
- `get_catalog` returns name/price/art only; pack contents (slots, pools) stay on the backend.
- Every backend call is `await`ed. The local backend answers immediately; a network backend (HTTP/WebSocket to the server) will answer later with the same Dictionaries.
- Results: `{"ok": true, ...}` or `{"ok": false, "error": <unknown_account | unknown_product | not_enough_dp | unavailable | save_failed>}`.

## Accounts
`user://accounts/index.json` lists accounts and the active one. Each account folder holds `profile.json` (id, name, DP, created), `collection.json` (card counts),
`working_deck.ydc` (deck editor autosave) and `purchases.jsonl` (one line per purchase: time, product, price, cards, balance after).
`Collection.load_default(db)` and `Deck.load_working(db)` read the signed-in account's files (they fall back to the old single files when there is no Session).
On the first run the old `user://collection.json` and `user://working_deck.ydc` are copied into an account called **Player**, so nothing is lost; new accounts get the starting DP and nothing else but 3 Polymerization and 3 Little D, which are also their whole deck (`Collection.STARTER`).
Account names are 1-16 characters; ids are derived from the name (`player`, `rival`, `rival_2`...). There are no passwords: real logins belong to the server.

## Packs and rarities
Each pack in `data/shop/catalog.json` has `contents.slots`. A slot draws `count` cards; each card first picks a rarity by weight, then a card from that rarity's pool:
`{"count": 5, "rarities": [{"rarity": "ultra_rare", "pool": "m1_ultra", "weight": 1}, {"rarity": "common", "pool": "m1_common", "weight": 99}]}`.
The short form `{"count": 5, "pool": "joey_pool"}` is a single "common" rarity. Rarities are declared under `"rarities"` (label, `"reveal": "gold"` for the golden pack-opening effect, `rank` for display order).
A card appears at most once per slot, a card the account already owns 3 of is never rolled, and when a rarity's pool runs dry its weight goes to the other rarities (if every pool is dry the pack has fewer cards).

Current test setup: **MONSTERS 1** = 2% ultra rare per card (Dark Magician, Dark Magician Girl, Red-Eyes B. Dragon, Tri-Horned Dragon, Wingweaver, Sengenjin, Valkyrion the Magna Warrior, Perfectly Ultimate Great Moth, Blue-Eyes White Dragon: Tier 1 monsters),
98% common (every other Tier 1 Normal and Effect monster except tokens and the `exclude_names` list, 259 cards). Tiers come from `data/card_tiers.json` (made with `tools/tier_sorter`). About 9.6% of packs contain an ultra rare.
**SPELLS & TRAPS 1** = every Tier 1 Spell and Trap (75 cards). De-Spell, The Flute of Summoning Dragon, Waboku, Fake Trap and Stim-Pack are labelled ULTRA RARE
(card list section, gold outline, golden reveal) but the slot uses `"equal_odds": true`: each rarity's weight is the number of cards it still has, so every card has the same
chance (the card list shows the ultra group at 6.7% = 5 of 75 cards).
**RITUAL & FUSION** = 5 cards in a fixed shape: card 1 a Fusion monster, cards 2-3 its two materials, card 4 a Ritual monster, card 5 the Ritual Spell that summons it.
It uses set slots: `{"set_pool": "rf1_fusion_sets", "rarity": "fusion_set"}` gives one whole set, picked uniformly among the sets that still have a card the account can receive
(cards already owned 3 times are left out). 17 Fusion sets (from `data/fusions.json`) and 12 Ritual sets (from each Ritual Spell's effect data) are written out in the catalog as
`"source": "sets"` pools; a test checks them against that data. Four sets are ULTRA RARE (gold section, gold reveal) and weigh 0.25 instead of 1: Gaia the Dragon Champion + Gaia The Fierce Knight + Curse of Dragon,
Thousand Dragon + Time Wizard + Baby Dragon, Labyrinth Tank + Giga-Tech Wolf + Cannon Soldier, and Zera The Mant + Zera Ritual. So each is 4x rarer than a normal set:
an ultra rare Fusion set comes in ~5.1% of packs (each ~1.7%), the Zera set in ~2.2% (normal sets ~6.8% / ~8.9%). Per-set metadata: `{"cards": [...], "rarity": "ultra_rare", "weight": 0.25}`.
Magician of Black Chaos is not in the pack: its Ritual Spell is not in the list. A full set takes 51 packs
(the Ritual sets run out after 36 packs, then packs are 3 cards). The card list shows the sets in order with "1 set per pack".
The first row is MONSTERS 1, SPELLS & TRAPS 1, RITUAL & FUSION; MONSTERS 2 and 3 (still the whole Card List pool as commons) are on the second row, so the preview placeholders no longer show.
Pool sources: `card_list_pool` (the 350 Card List cards), `cards` (by English name, normal-art version) and `filter` (`base` = `all` or `card_list_pool`, `type` or `types`, `tiers` (from card_tiers.json, keyed by Konami number, so alternate-art versions have no tier), `type`, `categories`, `min_level`/`max_level`, `exclude_pools`; exclusion is by name, so alternate arts are excluded too).
A purchase checks the account and product, refuses `not_enough_dp`, rolls the cards, saves the collection, then deducts DP and logs the purchase (card index and rarity per card).
Locally that is two file writes (cards first, so an interrupted save never takes DP for nothing); the server should do it in one database transaction.
The purchase result marks each card's `rarity` and `rare` (gold reveal), so the pack opening no longer uses the "rightmost card" placeholder.

### Completing a set
The 2% is not fixed: it is the weight of the ultra rare group, renormalised each card among the groups that still have cards left (not owned 3 times yet).
As commons run out, the ultra rare share rises on its own; when all ultra rares are maxed, commons get 100%, and the other way round. When the last cards are left, packs
get smaller (fewer than 5 cards), and when nothing is left the purchase is refused with `set_complete`, **without charging DP** (the shop says "You already own every card in this pack").
`tools/sim_complete.gd` buys a product until that happens.

## Card list (pack contents)
The **CARD LIST** button in the Shop footer opens `ui/pack_contents.gd` for the selected pack: every card it can give, grouped by rarity (rarest first, gold-outlined) with the chance per card,
as small card images in a scrolling grid. Hovering a card shows it large on the left with its rarity, stats and how many the account owns (x1-x3 badges on the thumbnails; gold at 3, which no longer drops).
The list comes from `backend.get_product_contents(product_id)`: card lists and chances are public like in real games, while the slot weights and RNG stay on the backend.

## Screen
The 800x600 layout, header, tabs, scrolling and corner-bracket selection are unchanged from the appearance prototype. The balance shows the account's DP; each price tag is the buy button
(disabled and greyed when the balance is too low). Buying plays the pack opening (`ui/pack_opening.gd`, ~8 s): the pack rises into a spotlight and hovers, its top strip tears off with a flash and a light beam,
the card backs shoot out from behind the pack, land in a row (with floor reflections) and flip one by one. NEW! tags pop on cards the account did not own before and blink
(visible ~1.5 s of every 2 s). Rare cards get a golden build-up (glow, shaking, other cards dimmed) and a burst on the flip: gold screen flash, rotating light rays,
sparkle burst and aura, a pulsing gold frame and a slight screen shake. Rarity is not in the catalog yet, so the Shop marks the rightmost card as rare (placeholder);
when the backend's results carry `"rare"`, that value is used instead. Clicking or any key fast-forwards (x6); OK, Enter or Escape closes it once all cards are face up.
Sounds are borrowed from the duel set (`SFX_*` constants at the top of `pack_opening.gd`) until dedicated ones exist.
`show_preview_row` still repeats the three pack images as a noninteractive, unbuyable second row while only three packs exist.
DP cannot be earned yet (duel rewards are future work); `starting_dp` (2450) is the only source.

## Not yet / for the online version
Server process and protocol, logins/passwords, earning DP, decks and bundles products, pack tiers, stable card ids on the wire (the collection uses CardDB indices, which change if the card database is rebuilt), and a licensed bundled font (the screen uses system Impact).

## Tests
`tests/test_shop.gd` (navigation, categories, scrolling) and `tests/test_accounts_shop.gd` (starting DP, purchase, 5 different cards from the pool, persistence, refused purchases change nothing, seeded rolls, separate accounts, Shop buy/reveal). Both use throwaway account folders.
`tools/shot_pack_contents.gd` saves the Shop and the card list; `tools/shot_shop_reveal.gd` (windowed: `godot --path . -s tools/shot_shop_reveal.gd -- <folder>`) saves a Shop screenshot and the pack opening as a frame sequence (every 0.2 s).

class_name DCard
extends RefCounted
## A card instance during a duel (the CardDB entry is identified by `idx`).

var uid := 0
var borrowed_from := -1      ## real owner while a Spell from the opponent's graveyard is used as mine (Graverobber)
var home_owner := -1           ## Exchange: real owner of a card taken from the other hand
var planted_by := -1          ## Parasite Paracide: the player whose deck it was put into
var token := ""             ## token kind (Duel.TOKENS key); tokens vanish instead of going to the graveyard
var idx := 0                 ## CardDB index
var number := 0              ## Konami card number (key into EffectDB)
var owner := 0               ## 0 / 1
var controller := 0          ## who currently controls it (differs from owner after Change of Heart etc.)
var face_up := false
var pos := "atk"             ## "atk" or "def" (monsters only)
var summon_turn := -1        ## turn it was summoned/set (for position-change and attack rules)
var attacked := false
var pos_changed := false
var atk_bonus := 0           ## legacy/test hook; effects use `mods`
var def_bonus := 0
var mods: Array = []         ## {atk, def, until: "end_turn"|"forever", src: uid}
var equipped_to: DCard = null
var equips: Array = []       ## equip cards attached to this monster
var equip_mod := {}          ## {atk, def} granted to the monster this equip card is attached to
var flags := {}              ## free-form per-card state set by effects ("cannot_attack", "negated", ...)
var used := {}               ## effect index -> turn it was last used (once-per-turn effects)
var activated_turn := -1     ## turn a Set spell/trap was last flipped by activation

func _init(p_uid: int, p_idx: int, p_owner: int, p_number := 0) -> void:
	uid = p_uid
	idx = p_idx
	owner = p_owner
	controller = p_owner
	number = p_number

func reset_turn_flags() -> void:
	attacked = false
	pos_changed = false

func expire_mods(until: String) -> void:
	mods = mods.filter(func(m): return m.get("until", "forever") != until)

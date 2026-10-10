class_name Deck
extends RefCounted
## A deck as stored by the original game (.ydc): u16 little-endian values
##   [magic, ?, check_lo, check_hi, main_count, main..., extra_count, extra..., side_count, side...]
## Cards are Konami card numbers (CardDB card "number"); in memory we keep CardDB indices.
## The four header words are kept verbatim; their meaning (looks like a checksum) is still unknown.

var main: Array = []    ## card indices
var extra: Array = []
var side: Array = []
var header: Array = [0xc101, 0x00e3, 0, 0]

static func from_bytes(bytes: PackedByteArray, db: CardDB) -> Deck:
	var by_number := {}
	for i in range(1, db.cards.size()):
		by_number[int(db.cards[i]["number"])] = i
	var d := Deck.new()
	@warning_ignore("integer_division")
	var n := bytes.size() / 2
	var pos := 4
	d.header = [bytes.decode_u16(0), bytes.decode_u16(2), bytes.decode_u16(4), bytes.decode_u16(6)]
	pos = 4
	for section in [d.main, d.extra, d.side]:
		if pos >= n:
			break
		var count := bytes.decode_u16(pos * 2)
		pos += 1
		for k in count:
			if pos >= n:
				break
			var num := bytes.decode_u16(pos * 2)
			pos += 1
			if by_number.has(num):
				section.append(by_number[num])
	return d

func to_bytes(db: CardDB) -> PackedByteArray:
	var out := PackedByteArray()
	for h in header:
		out.append(h & 0xff); out.append(h >> 8 & 0xff)
	for section in [main, extra, side]:
		out.append(section.size() & 0xff); out.append(section.size() >> 8 & 0xff)
		for idx in section:
			var num: int = db.cards[idx]["number"]
			out.append(num & 0xff); out.append(num >> 8 & 0xff)
	return out

static func load_file(path: String, db: CardDB) -> Deck:
	var f := FileAccess.open(path, FileAccess.READ)
	return null if f == null else from_bytes(f.get_buffer(f.get_length()), db)

func copies(card_index: int) -> int:
	return main.count(card_index) + extra.count(card_index) + side.count(card_index)

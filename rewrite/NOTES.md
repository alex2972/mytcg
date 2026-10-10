# Joey PC (2004) -> Rust rewrite: findings

## Original (Z:\process\my old yu gi oh game)
- joey_pc.exe: 32-bit Win32 PE, DirectX9/DirectInput/DirectShow, WinMM, MSACM32. Sections `.ksss`, `.ycnett`, `.$$$` => packed/protected; unpack before analysis.
- exporter.exe: small deck exporter (reads Region.dat, *.ydc, system.dat).
- data.dat (3568 entries), Voice.dat (132 entries): KCEJYUGI archives.
- deck.ydc (96 B), system.dat (5 KB), Region.dat (1 B) are save/config.

## Archive format (implemented in tools/unpack_dat.py, verified: 0 size mismatches)
- 'KCEJYUGI', u32 count, count * 268-byte entries.
- Entry: 256-byte path (every byte nibble-swapped), u32 offset, u32 stored size, u32 original size.
- stored != original => Okumura LZSS (N=4096, F=18, threshold 2, LSB-first flags, 1=literal, window zero-filled, r=N-F).
- Extracted to Z:\process\extracted\{data,voice}: 2763 bmp, 537 yga, 168 txt layout scripts, 41 bin card DBs, 131 wav.

## Card DB (extracted/data/bin#) - not yet decoded
card_name*/desc*/indx*(u32 offsets)/sort*, card_prop, card_id, card_intid, card_pass, card_pack; 6 languages (eng fra ger ita jpn spa). dlg_* = dialog strings.

## Next
1. Restart Claude so REA's Ghidra tools load; unpack joey_pc.exe; recover duel rules, effect scripts, AI, UI flow.
2. Decode card_prop / yga / layout .txt formats.

## Progress (REA + Ghidra working; Ghidra opens joey_pc.exe: 8090 procedures, 2591 strings, code in .text is NOT packed)
- Image base 0x400000, MSVC 6-era C++, MFC-less raw Win32.
- 0x4025f0: card_prop lookup `card_prop[id & 0x7ff]` (u32 per card, lazy-loaded from data/bin#/CARD_Prop.bin; values look scrambled).
- Card text: card_name*.bin = 64-byte fixed records, card N (1-based) at 64*N, NUL padded.
  card_desc*.bin = NUL-terminated strings, card_indx*.bin = u32 byte offsets into desc (index = card number). Verified for English.
- 0xb6f2c8.. in .ksss region: hex-encoded encrypted strings (protection/debug text); ignore.
- Layout scripts (data/j/**.txt) are tab-separated scene definitions ("kabegami/back_1_?.bmp<TAB>0<TAB>6<TAB>1548...").
## TODO
- Decode card_prop bitfields (find consumers of 0x4025f0 via callers), card_id/intid/pass scrambling.
- Find duel state machine, effect handlers, AI; .yga format; replay/deck formats (deck.ydc 96 B, system.dat).

## Update 2 (corrections + engine map)
- FIX: .dat entry fields are (offset, ORIGINAL size, STORED size); LZSS when stored != original. Old extraction truncated compressed files; re-extracted. 3363 raw + 205 compressed, 0 mismatches.
- 1115 cards (card_id.bin = 1115 u16; card_name*.bin = 1115 x 64-byte records, card N at 64*N).
- card_prop u32 bitfields (from accessors 0x4025d0..0x402800), p = card_prop[id & 0x7ff]:
  kind = p>>20 & 0x1f (0-20 monster types/races; 21 spell, 22 trap, 23 ?, 24 special 4000/4000 lvl10)
  ATK = (p & 0x1ff)*10; DEF = (p>>9 & 0x1ff)*10  (0 for kinds 21-23; 4000 for kind 24)
  level = p>>25 & 0xf (kind<21); attribute = p>>29 (kind 21 => 9, 22 => 8)
  sub = p>>17 & 7 (spell/trap subtype, kinds 21-22); category = p>>18 & 3 (override table for ids 0x776-0x778)
  Verified vs names: Armored Starfish 1400/850 L4, Earthbound Spirit 2000/500 L4.
- Full decompile of .text: Z:\process\analysis\decomp.c (6517 funcs; tools/scripts/ExportDecomp.java, tools/run_decomp.bat). funcs.pkl = python index.
- Duel engine lives in ~0x560000-0x5c0000 (333 funcs). Global state at 0xa55d68..0xa585a4: per-player block stride 0xd44 bytes (0x6a2 shorts);
  card slot = 4 bytes (u16 id|flags, u16 state); zone counts are bytes at +0 / +1 of 0xa55d68 block. Player index = param&1.
- Card effects are HARDCODED per internal card id (FUN_004022e0 = card_intid lookup) in giant switch functions:
  0x599e30 (target selection by effect id, 61 ids), 0x56dd30, 0x579ce0, 0x592bb0, 0x56fd40, 0x59df40 (7.4 KB, calls 0x599e30). No script/data effect table.
- AI not located yet.

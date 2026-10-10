"""Decode the original game's .yga sprite format.
Header (24 bytes, little endian): 'yga\0', u32 width, u32 height, u32 flag (1 = LZSS compressed, 0 = raw),
u32 raw size (= w*h*4), u32 stored size. Pixels are BGRA, 8 bits per channel (real alpha)."""
import os, struct, sys
sys.path.insert(0, os.path.dirname(__file__))
from unpack_dat import lzss
from PIL import Image

def load(path):
    d = open(path, "rb").read()
    magic, w, h, flag, raw, stored = struct.unpack("<4sIIIII", d[:24])
    assert magic == b"yga\0", path
    body = d[24:24 + stored]
    px = lzss(body, raw) if flag == 1 else body[:raw]
    if len(px) != raw:
        raise ValueError(f"{path}: expected {raw} bytes, got {len(px)}")
    return Image.frombytes("RGBA", (w, h), px, "raw", "BGRA"), flag

if __name__ == "__main__":
    src, out = sys.argv[1], sys.argv[2]
    n = bad = 0
    flags = {}
    for root, _, files in os.walk(src):
        for f in files:
            if f.lower().endswith(".yga"):
                p = os.path.join(root, f)
                try:
                    im, flag = load(p)
                except Exception as e:
                    bad += 1; print("BAD", p, e); continue
                flags[flag] = flags.get(flag, 0) + 1
                dst = os.path.join(out, os.path.relpath(p, src))[:-4] + ".png"
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                im.save(dst); n += 1
    print("converted", n, "bad", bad, "flags", flags)

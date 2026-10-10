"""Unpack KCEJYUGI .dat archives.
Layout: 'KCEJYUGI', u32 count, then count*268-byte entries:
  256-byte path (each byte nibble-swapped), u32 offset, u32 original size, u32 stored size.
When stored != original the entry is Okumura LZSS (N=4096, F=18, threshold 2,
LSB-first flags, 1=literal, window pre-filled with zeros, start r=N-F)."""
import struct, sys, os
def ns(b): return bytes(((x & 15) << 4) | (x >> 4) for x in b)
def lzss(src, outlen):
    N, F = 4096, 18
    win = bytearray(N); r = N - F
    out = bytearray(); i = 0; flags = 0
    while len(out) < outlen and i < len(src):
        flags >>= 1
        if not flags & 0x100:
            flags = src[i] | 0xFF00; i += 1
            if i >= len(src): break
        if flags & 1:
            c = src[i]; i += 1; out.append(c); win[r] = c; r = (r + 1) & (N - 1)
        else:
            if i + 1 >= len(src): break
            a, b = src[i], src[i + 1]; i += 2
            pos = a | ((b & 0xF0) << 4); ln = (b & 0x0F) + 3
            for k in range(ln):
                c = win[(pos + k) & (N - 1)]; out.append(c); win[r] = c; r = (r + 1) & (N - 1)
    return bytes(out[:outlen])
if __name__ == "__main__":
    src, out = sys.argv[1], sys.argv[2]; bad = 0
    with open(src, "rb") as f:
        assert f.read(8) == b"KCEJYUGI"
        n = struct.unpack("<I", f.read(4))[0]; tab = f.read(n * 268)
        for i in range(n):
            e = tab[i*268:(i+1)*268]
            name = ns(e[:256]).split(b"\0")[0].decode("latin-1").replace("\\", "/")
            off, orig, stored = struct.unpack("<3I", e[256:])
            if not name: continue
            f.seek(off); data = f.read(stored)
            if stored != orig:
                data = lzss(data, orig)
                if len(data) != orig: bad += 1; print("BAD", name, len(data), orig)
            p = os.path.join(out, name); os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "wb").write(data)
    print("entries", n, "bad", bad)

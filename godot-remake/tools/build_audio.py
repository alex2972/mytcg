"""Convert the original's sound effects, voices and music (extracted from Voice.dat) to OGG for Godot.
usage: build_audio.py <extracted voice dir> <godot project dir> [ffmpeg path]
  voice/joey/english/internal/*.wav -> assets/audio/sfx/*.ogg   (sound effects + Joey voice lines)
  voice/joey/english/stream/*.wav   -> assets/audio/music/*.ogg (background music)"""
import os, subprocess, sys

src, proj = sys.argv[1], sys.argv[2]
ffmpeg = sys.argv[3] if len(sys.argv) > 3 else "ffmpeg"
base = os.path.join(src, "joey", "english")
jobs = [("internal", "sfx", "3"), ("stream", "music", "4")]
n = 0
for sub, out_name, quality in jobs:
    out = os.path.join(proj, "assets", "audio", out_name)
    os.makedirs(out, exist_ok=True)
    for f in sorted(os.listdir(os.path.join(base, sub))):
        if not f.lower().endswith(".wav") or f.startswith("_"):
            continue
        dst = os.path.join(out, os.path.splitext(f)[0] + ".ogg")
        if os.path.exists(dst):
            continue
        subprocess.run([ffmpeg, "-loglevel", "error", "-y", "-i", os.path.join(base, sub, f), "-c:a", "libvorbis", "-q:a", quality, dst], check=True)
        n += 1
print("converted", n)

"""Turn docs/token_lists/all.txt (card names) into .ydk deck files using Project Ignis EDOPro's card databases.

Usage: python tools/token_art_ydk.py [path to the ProjectIgnis folder]   (default G:\\ProjectIgnis)
Writes docs/token_lists/all.ydk, part01.ydk ... and not_matched.txt (names the databases do not know).
"""
import glob
import re
import sqlite3
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
root = sys.argv[1] if len(sys.argv) > 1 else "G:\\ProjectIgnis"
names = [l[3:].strip() for l in open("docs/token_lists/all.txt", encoding="utf-8") if l.strip()]
files = [root + "\\expansions\\cards.db".replace(".db", ".cdb")]
files += sorted(glob.glob(root + "\\expansions\\cards-unofficial*.cdb"))
files += sorted(glob.glob(root + "\\repositories\\*\\cards*.cdb"))

def norm(n):
    return re.sub(r"[^a-z0-9]", "", n.lower())

db = {}
for f in files:
    try:
        con = sqlite3.connect(f)
        for cid, name, typ in con.execute("select t.id, t.name, d.type from texts t join datas d on d.id = t.id"):
            db.setdefault(norm(name), (cid, typ, name))
    except Exception as e:
        print("skipped", f, e)
print(len(db), "card names in the databases")

found, missing = [], []
for n in names:
    hit = db.get(norm(n))
    (found if hit else missing).append((n,) + hit if hit else n)
print(len(found), "matched,", len(missing), "not matched")

EXTRA_TYPES = 0x40 | 0x2000 | 0x800000 | 0x2000000 | 0x4000000      # fusion, synchro, xyz, pendulum-extra, link

def ydk(rows):
    main = [r[1] for r in rows if not r[2] & EXTRA_TYPES]
    extra = [r[1] for r in rows if r[2] & EXTRA_TYPES]
    return "#created by the Joey remake\n#main\n" + "\n".join(map(str, main)) + "\n#extra\n" + "\n".join(map(str, extra)) + "\n!side\n"

open("docs/token_lists/all.ydk", "w", encoding="utf-8").write(ydk(found))
for i in range(0, len(found), 60):
    open("docs/token_lists/part%02d.ydk" % (i // 60 + 1), "w", encoding="utf-8").write(ydk(found[i:i + 60]))
open("docs/token_lists/not_matched.txt", "w", encoding="utf-8").write("\n".join(missing) + "\n")
print("not matched:", missing)

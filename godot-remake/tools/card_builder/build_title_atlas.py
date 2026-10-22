"""Extract native small-cap title glyphs from the game's original card images."""
import base64
import io
import json
from collections import defaultdict, Counter
from pathlib import Path
from PIL import Image, ImageDraw
import server

import argparse
parser=argparse.ArgumentParser();parser.add_argument("--light",action="store_true");args=parser.parse_args()
samples=defaultdict(list)
for key,c in server.CATALOG.items():
    name=c['name']
    if len(name)>24 or ((c['kind'] in ('Spell','Trap')) != args.light):
        continue
    im=server.source(key)
    ink=Image.new('L',(139,17))
    for x in range(139):
        bg=sum(im.getpixel((x+20,y))[i] for y in (18,35) for i in range(3))/6
        for y in range(17):
            value=sum(im.getpixel((x+20,y+18)))/3
            alpha=max(0,min(255,round(255*((value-bg)/max(255-bg,1) if args.light else 1-value/max(bg,1)))))
            ink.putpixel((x,y),alpha if alpha>55 else 0)
    columns=[any(ink.getpixel((x,y))>145 for y in range(17)) for x in range(139)]
    runs=[];start=None
    for x,on in enumerate(columns+[False]):
        if on and start is None:start=x
        if not on and start is not None:runs.append((start,x));start=None
    letters=[ch for ch in name if ch!=' ']
    if len(runs)!=len(letters):continue
    # Full-sized titles only; long names sometimes use horizontally compressed letters.
    if not runs or ink.getbbox()[3]-ink.getbbox()[1]<11:continue
    for ch,(a,b) in zip(letters,runs):
        crop=ink.crop((max(0,a-1),0,min(139,b+1),17))
        samples[ch].append((b-a,crop,key))

glyphs={}
sheet=Image.new('RGB',(650,160),'#dfbb76');draw=ImageDraw.Draw(sheet)
for i,(ch,values) in enumerate(sorted(samples.items())):
    width=Counter(v[0] for v in values).most_common(1)[0][0]
    compatible=[v for v in values if v[0]==width]
    # Median suppresses frame texture and antialias noise without changing glyph shape.
    glyph=Image.new('L',(width+2,17))
    for y in range(17):
        for x in range(width+2):
            vals=sorted(v[1].getpixel((min(x,v[1].width-1),y)) for v in compatible)
            glyph.putpixel((x,y),vals[len(vals)//2])
    buf=io.BytesIO();glyph.save(buf,format='PNG')
    glyphs[ch]={'mask':base64.b64encode(buf.getvalue()).decode(),'width':width,'source':compatible[0][2]}
    x=(i%26)*25;y=(i//26)*50
    draw.text((x,y),ch,fill='black');sheet.paste('black',(x,y+16),glyph)
# J's hook extends left of the standard title crop and below the common
# baseline. Capture the complete letter from a clear native leading J.
j_source='LON047' if args.light else 'MRD072'
j_image=server.source(j_source).convert('L')
j_mask=Image.new('L',(7,19))
for y in range(19,36):
    bg=j_image.getpixel((27 if y>=32 else 18,y))
    for x in range(19,25):
        pixel=j_image.getpixel((x,y))
        value=(pixel-bg)/max(1,255-bg) if args.light else 1-pixel/max(bg,1)
        alpha=max(0,min(255,round(value*255)))
        j_mask.putpixel((x-18,y-18),alpha if alpha>30 else 0)
buf=io.BytesIO();j_mask.save(buf,format='PNG')
glyphs['J']={'mask':base64.b64encode(buf.getvalue()).decode(),'width':5,'source':j_source}

target=Path(__file__).with_name('title_glyphs_light.json' if args.light else 'title_glyphs.json')
target.write_text(json.dumps({'height':17,'baseline':15,'glyphs':glyphs},indent=2))
out=server.ROOT/'output/card_builder_checks';out.mkdir(parents=True,exist_ok=True)
sheet.save(out/('title-atlas-light.png' if args.light else 'title-atlas.png'))
print('Native title glyphs:', ''.join(sorted(glyphs)), 'from',sum(len(v) for v in samples.values()),'samples')
print('Missing:', ''.join(ch for ch in 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-#&.,\'/' if ch not in glyphs))

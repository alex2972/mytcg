"""Local card editor. Run python tools/card_builder/server.py, then open localhost:8765."""
import base64
import io
import json
import re
import threading
import socket
import webbrowser
from pathlib import Path
from functools import lru_cache
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from PIL import Image, ImageDraw, ImageEnhance, ImageFont, ImageFilter, ImageChops

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
CARDS = ROOT / 'assets/cards'
OUT = ROOT / 'output/card_builder'
SCALE = 4
SIZE = (200, 290)
ART = (28, 63, 173, 207)
RACES = ['', 'Dragon', 'Zombie', 'Fiend', 'Pyro', 'Sea Serpent', 'Rock', 'Machine', 'Fish', 'Dinosaur', 'Insect', 'Beast', 'Beast-Warrior', 'Plant', 'Aqua', 'Warrior', 'Winged Beast', 'Fairy', 'Spellcaster', 'Thunder', 'Reptile']
ATTRS = {1:'LIGHT',2:'DARK',3:'WATER',4:'FIRE',5:'EARTH',6:'WIND',7:'DIVINE'}
DEFAULTS = {'Normal':'MRD023', 'Effect':'MRL010', 'Fusion':'TP3007', 'Ritual':'MRL068', 'Spell':'SDY042', 'Trap':'EDS003'}
DB = json.loads((ROOT / 'data/cards.json').read_text(encoding='utf-8'))['cards']
CATALOG = {}
SYMBOLS = {}
SUBTYPES = {}
TITLE_ATLAS = json.loads((HERE/'title_glyphs.json').read_text()) if (HERE/'title_glyphs.json').exists() else None
LIGHT_TITLE_ATLAS = json.loads((HERE/'title_glyphs_light.json').read_text()) if (HERE/'title_glyphs_light.json').exists() else None
STAT_ATLAS = json.loads((HERE/'stat_glyphs.json').read_text())
for c in DB:
    key = c.get('art', '')
    path = CARDS / (key + '.png')
    if not path.is_file() or key.startswith('token') or key in CATALOG:
        continue
    with Image.open(path) as im:
        if im.size != SIZE:
            continue
    kind = ['Normal','Effect','Fusion','Ritual'][c.get('category',0)] if c.get('type') == 'monster' else c.get('type','spell').title()
    CATALOG[key] = {'id':key, 'name':c.get('name',{}).get('eng',key), 'kind':kind,
                    'description':c.get('desc',{}).get('eng',''), 'race':RACES[c.get('kind',0)] if c.get('kind',0)<len(RACES) else '',
                    'attribute':ATTRS.get(c.get('attribute'),'EARTH'), 'level':c.get('level',4),
                    'atk':c.get('atk',0), 'def':c.get('def',0), 'subtype':c.get('subtype_name','normal')}
    if c.get('type') == 'monster':
        SYMBOLS.setdefault(ATTRS.get(c.get('attribute')), key)
    elif c.get('type') in ('spell','trap'):
        SUBTYPES.setdefault((kind,c.get('subtype_name','normal')),key)

def source(key):
    if key not in CATALOG:
        raise ValueError('Choose an original card template from the list.')
    return Image.open(CARDS / (key + '.png')).convert('RGB')

def font(size, face='regular', custom=None):
    if custom:
        data = decode_image_data(custom, 8_000_000)
        return ImageFont.truetype(io.BytesIO(data), size)
    files = {'title':'times.ttf','bold':'timesbd.ttf','italic':'timesi.ttf','regular':'arial.ttf'}
    paths = [Path('C:/Windows/Fonts') / files.get(face,'arial.ttf'), Path('/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf')]
    for path in paths:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    raise ValueError('No font found. Upload a TTF font in the editor.')

def decode_image_data(value, limit=25_000_000):
    if not isinstance(value,str) or not value.startswith('data:') or ',' not in value:
        raise ValueError('Invalid uploaded file.')
    data = base64.b64decode(value.split(',',1)[1],validate=True)
    if len(data)>limit:
        raise ValueError('Uploaded file is too large.')
    return data

def rect(box):
    return tuple(round(v*SCALE) for v in box)

def erase_print(image, boxes, white=False, title=False, solid=False, threshold=12, spread=3, safe_box=None):
    """Remove only ink pixels. Never resize a background patch or touch a bevel."""
    gray=image.convert('L'); background=gray.filter(ImageFilter.MedianFilter(9))
    color_background=image.filter(ImageFilter.MedianFilter(9)) if title else None
    mask=Image.new('L',image.size)
    for left,top,right,bottom in boxes:
        for y in range(top,bottom):
            for x in range(left,right):
                delta=gray.getpixel((x,y))-background.getpixel((x,y))
                colored=title and max(abs(a-b) for a,b in zip(image.getpixel((x,y)),color_background.getpixel((x,y))))>18
                if solid or colored or (delta>threshold if white else delta < -threshold):mask.putpixel((x,y),255)
    mask=mask.filter(ImageFilter.MaxFilter(spread))
    bounds=Image.new('L',image.size);d=ImageDraw.Draw(bounds)
    for l,t,r,b in boxes:d.rectangle((l,t,r-1,b-1),fill=255)
    mask=ImageChops.multiply(mask,bounds)
    pending={(x,y) for l,t,r,b in boxes for y in range(t,b) for x in range(l,r) if mask.getpixel((x,y))}
    points=list(pending); result=image.copy(); pixels=result.load()
    def adjacent(x,y):
        return [(a,b) for a,b in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)) if 0<=a<image.width and 0<=b<image.height and (safe_box is None or safe_box[0]<=a<safe_box[2] and safe_box[1]<=b<safe_box[3])]
    while pending:
        fill=[]
        for x,y in pending:
            neighbors=[pixels[a,b] for a,b in adjacent(x,y) if (a,b) not in pending]
            if neighbors:fill.append((x,y,tuple(round(sum(p[c] for p in neighbors)/len(neighbors)) for c in range(3))))
        if not fill:raise ValueError('Could not reconstruct printed area.')
        for x,y,color in fill:pixels[x,y]=color;pending.remove((x,y))
    for _ in range(35):
        fill=[]
        for x,y in points:
            neighbors=[pixels[a,b] for a,b in adjacent(x,y)]
            fill.append((x,y,tuple(round(sum(p[c] for p in neighbors)/len(neighbors)) for c in range(3))))
        for x,y,color in fill:pixels[x,y]=color
    return result

@lru_cache(maxsize=6)
def clean_frame(kind):
    original=source(DEFAULTS[kind])
    # Native one-star rows provide clear background without stretched patches.
    row_source={'Fusion':'PSV084','Ritual':'MRL029'}.get(kind)
    if row_source:
        original.paste(source(row_source).crop((24,41,178,58)),(24,41))
    result=erase_print(original,[(20,19,158,35)],white=kind in ('Spell','Trap'),title=True)
    ink_bottom={'Fusion':240}.get(kind,263)
    boxes=[(20,224,180,ink_bottom)] if kind not in ('Spell','Trap') else [(20,224,180,273)]
    result=erase_print(result,boxes,threshold=4,spread=5,safe_box=(20,224,180,273 if kind in ('Spell','Trap') else 264))
    # Remove only the printed code; preserve the artwork shadow and box bevel.
    result=erase_print(result,[(144,213,181,219)],threshold=4,spread=5,safe_box=(20,213,181,219))
    # Old text reaches the last two interior columns on some originals.
    # Reconstruct their vertical shading from clean endpoints, not letter fragments.
    bottom=272 if kind in ('Spell','Trap') else 263
    for x in (180,181):
        top_color=original.getpixel((x,223))
        bottom_color=original.getpixel((x,bottom))
        for y in range(224,bottom):
            ratio=(y-223)/(bottom-223)
            result.putpixel((x,y),tuple(round(a*(1-ratio)+b*ratio) for a,b in zip(top_color,bottom_color)))
    if kind not in ('Spell','Trap'):
        # Recover each row of the original pale stat-panel background.
        for y in range(265,273):
            # The stat panel has its own pale highlight, particularly below
            # the baseline; the empty left half is darker and loses this.
            samples=[original.getpixel((x,y)) for x in range(103,180)]
            paper=tuple(sorted(pixel[c] for pixel in samples)[round((len(samples)-1)*.9)] for c in range(3))
            for x in range(102,181):result.putpixel((x,y),paper)
    return result

def text_layer(text, size, face, color, custom=None, caps=False):
    if face=='title' and caps and not custom and TITLE_ATLAS:
        return native_title(text,size,color)
    f = font(round(size*SCALE),face,custom)
    if not caps:
        box = f.getbbox(text or ' ')
        layer = Image.new('RGBA',(max(1,round(f.getlength(text))+8),round(size*SCALE*1.5)),(0,0,0,0))
        ImageDraw.Draw(layer).text((0,-box[1]),text,font=f,fill=color)
        return layer.crop(layer.getbbox() or (0,0,1,1))
    # Classic small caps: capitals at full height, lowercase as smaller capitals.
    little=font(round(size*SCALE*.77),face,custom)
    layer=Image.new('RGBA',(max(1,round(f.getlength(text.upper()))+20),round(size*SCALE*1.5)),(0,0,0,0))
    draw=ImageDraw.Draw(layer); x=0; baseline=round(size*SCALE)
    for ch in text:
        cf=little if ch.islower() else f
        draw.text((x,baseline),ch.upper(),font=cf,fill=color,anchor='ls')
        x+=cf.getlength(ch.upper())
    return layer.crop(layer.getbbox() or (0,0,1,1))

def native_title(text,size,color):
    # White/gold titles use masks measured from the game's white lettering.
    # Black-letter opacity masks make bright lettering look translucent/thin.
    rgb=tuple(int(color[i:i+2],16) for i in (1,3,5)) if isinstance(color,str) else color[:3]
    light=LIGHT_TITLE_ATLAS if sum(rgb)/3>110 else None
    glyphs=dict(TITLE_ATLAS['glyphs'])
    if light:glyphs.update(light['glyphs'])
    pieces=[]
    for ch in text:
        if ch==' ':
            pieces.append((None,4)); continue
        entry=glyphs.get(ch)
        if entry:
            mask=Image.open(io.BytesIO(base64.b64decode(entry['mask']))).convert('L')
            width=entry['width']
        elif ch.isupper() and ch.lower() in glyphs:
            entry=glyphs[ch.lower()]
            small=Image.open(io.BytesIO(base64.b64decode(entry['mask']))).convert('L')
            ink=small.crop(small.getbbox());ink=ink.resize((round(ink.width*1.25),12),Image.Resampling.BICUBIC)
            width=ink.width;mask=Image.new('L',(width+2,17));mask.paste(ink,(1,3))
        else:
            # Rare punctuation/digits unavailable in the original titles retain a fallback.
            f=font(16,'title');width=round(f.getlength(ch));mask=Image.new('L',(width+2,17))
            ImageDraw.Draw(mask).text((1,15),ch,font=f,fill=255,anchor='ls')
        pieces.append((mask,width+2))
    alpha=Image.new('L',(max(1,sum(w for _,w in pieces)+2),max([17]+[m.height for m,_ in pieces if m is not None])));x=0
    for mask,advance in pieces:
        if mask: alpha.paste(mask,(x,0))
        x+=advance
    alpha=alpha.crop(alpha.getbbox() or (0,0,1,1))
    if light:
        alpha=alpha.point(lambda value:min(255,round(value*1.2)))
    alpha=alpha.resize((max(1,round(alpha.width*SCALE*size/16)),max(1,round(alpha.height*SCALE*size/16))),Image.Resampling.NEAREST)
    layer=Image.new('RGBA',alpha.size,color);layer.putalpha(alpha)
    return layer

def put(im, text, box, size, face='regular', color='#000000', custom=None, caps=False, align='left'):
    layer=text_layer(text,size,face,color,custom,caps)
    bounds=rect(box); w=bounds[2]-bounds[0]; h=bounds[3]-bounds[1]
    if face=='title' and caps:
        layer=layer.resize((min(layer.width,w),min(layer.height,h)),Image.Resampling.LANCZOS)
    ratio=min(1,w/layer.width,h/layer.height)
    if ratio<1:
        layer=layer.resize((max(1,round(layer.width*ratio)),max(1,round(layer.height*ratio))),Image.Resampling.LANCZOS)
    x=bounds[0] if align=='left' else bounds[2]-layer.width
    im.paste(layer,(x,bounds[1]),layer)

def wrapped(text, size, width, face='regular'):
    f=font(round(size*SCALE),face)
    lines=[]
    for para in text.split('\n'):
        line=''
        for word in para.split():
            candidate=(line+' '+word).strip()
            if f.getlength(candidate)<=width*SCALE:
                line=candidate
            else:
                if line: lines.append(line)
                line=word
                while f.getlength(line)>width*SCALE and len(line)>1:
                    cut=len(line)-1
                    while cut>1 and f.getlength(line[:cut])>width*SCALE: cut-=1
                    lines.append(line[:cut]); line=line[cut:]
        lines.append(line)
    return lines

def native_stats(image, params):
    """Use original native-size print; avoid rescaling the tiny stat strokes."""
    def mask(data):
        return Image.open(io.BytesIO(base64.b64decode(data))).convert('L')
    for field,left,end in [('atk',101,139),('def',143,180)]:
        value=str(int(params.get(field,0)))
        if not value.isdigit() or len(value)>4:
            raise ValueError('ATK and DEF must be between 0 and 9999.')
        image.paste((0,0,0),(left,265),mask(STAT_ATLAS['labels'][field]))
        digits=Image.new('L',(5*len(value),9))
        for i,ch in enumerate(value):
            data=STAT_ATLAS['leadingDigits'][ch] if i==0 and len(value)==4 else STAT_ATLAS['digits'][ch]['mask']
            digits.paste(mask(data),(i*5,0))
        image.paste((0,0,0),(end-digits.width,265),digits)


def render(p):
    kind=p.get('kind','Normal')
    if kind not in DEFAULTS: raise ValueError('Unknown card type.')
    key=DEFAULTS[kind]
    orig=source(key); native=clean_frame(kind).copy(); base=native.resize((800,1160),Image.Resampling.NEAREST);im=base.copy()
    native_slot=None
    monster=kind not in ('Spell','Trap')
    # Reuse original panel pixels; retain bevels, exact frame palette and copyright.
    title_color=p.get('titleColor') or ('#ffffff' if not monster else '#000000')
    if not re.fullmatch(r'#[0-9a-fA-F]{6}',title_color): raise ValueError('Invalid title color.')
    put(im,str(p.get('name','New Card'))[:100],(20,20,158,34),float(p.get('titleSize',16)), 'title',title_color,p.get('titleFont'),True)
    if p.get('artwork'):
        with Image.open(io.BytesIO(decode_image_data(p['artwork']))) as loaded:
            if loaded.width*loaded.height>40_000_000: raise ValueError('Artwork exceeds 40 megapixels.')
            art=loaded.convert('RGB')
        for field,enhancer in [('brightness',ImageEnhance.Brightness),('contrast',ImageEnhance.Contrast),('saturation',ImageEnhance.Color)]:
            art=enhancer(art).enhance(max(0,min(2,float(p.get(field,1)))))
        w,h=(ART[2]-ART[0])*SCALE,(ART[3]-ART[1])*SCALE
        factor=max(w/art.width,h/art.height)*max(1,min(4,float(p.get('zoom',1))))
        art=art.resize((round(art.width*factor),round(art.height*factor)),Image.Resampling.LANCZOS)
        x=round((art.width-w)*max(0,min(1,float(p.get('cropX',.5)))))
        y=round((art.height-h)*max(0,min(1,float(p.get('cropY',.5)))))
        im.paste(art.crop((x,y,x+w,y+h)),rect(ART)[:2])
    else:
        ImageDraw.Draw(im).rectangle(rect(ART),fill='#33404b')
        put(im,'Add artwork',(42,124,163,144),12,'title','#ffffff')
    if monster:
        attribute=p.get('attribute','EARTH')
        if attribute not in SYMBOLS: raise ValueError('Unsupported attribute.')
        # Copy a native symbol slot from the same frame family. A circular
        # crop from a Normal card includes its gold edge pixels on other frames.
        candidates=[c['id'] for c in CATALOG.values()
                    if c['kind']==kind and c['attribute']==attribute]
        if candidates:
            symbol_key=key if CATALOG[key]['attribute']==attribute else sorted(candidates)[0]
            slot=source(symbol_key).crop((159,14,184,39))
            native_slot=slot
            im.paste(slot.resize((100,100),Image.Resampling.NEAREST),(159*SCALE,14*SCALE))
        else:
            # Attributes absent from the original family retain only the icon's
            # interior, without the source frame's antialiased outer fringe.
            orb=source(SYMBOLS[attribute]).crop((161,15,182,37)).resize((84,88),Image.Resampling.NEAREST)
            mask=Image.new('L',orb.size,0)
            ImageDraw.Draw(mask).ellipse((8,8,79,79),fill=255)
            im.paste(orb,(161*SCALE,15*SCALE),mask)
        # Every fixed monster frame is a one-star original. Keep its complete
        # star-row background and rightmost star intact; add only extra stars.
        star=source('MRD023').crop((163,43,176,56)).resize((52,52),Image.Resampling.NEAREST)
        star_mask=Image.new('L',star.size,0); ImageDraw.Draw(star_mask).ellipse((0,0,51,51),fill=255)
        level=int(p.get('level',4))
        if not 1<=level<=12: raise ValueError('Level must be 1–12.')
        for i in range(1,level): im.paste(star,rect((163-i*14,43,176-i*14,56))[:2],star_mask)
        race=p.get('race','Dragon')
        label=race if kind=='Normal' else race+' / '+kind
        put(im,'['+label+']',(20,224,181,233),9,'bold',caps=True)
        body_top,body_bottom=232,263
    else:
        # Preserve authentic subtype glyphs from another original when available.
        glyph_source=SUBTYPES.get((kind,p.get('subtype','normal')),key)
        band=source(glyph_source).crop((83,41,179,56)).resize((384,60),Image.Resampling.NEAREST)
        im.paste(band,rect((83,41,179,56))[:2])
        body_top,body_bottom=224,271
    description=str(p.get('description',''))[:3000]
    face='italic' if kind=='Normal' else 'regular'
    requested=float(p.get('bodySize',6.3)); actual=requested
    while True:
        lines=wrapped(description,actual,160,face)
        if len(lines)*actual*1.12<=body_bottom-body_top or actual<=3.5: break
        actual-=.2
    if len(lines)*actual*1.12>body_bottom-body_top: raise ValueError('Description is too long to fit. Shorten it.')
    body=Image.new('RGBA',(160*SCALE,(body_bottom-body_top)*SCALE),(0,0,0,0))
    draw=ImageDraw.Draw(body); f=font(round(actual*SCALE),face)
    for i,line in enumerate(lines):
        draw.text((0,i*actual*1.12*SCALE),line,font=f,fill='#000000',anchor='lt')
    im.paste(body,(20*SCALE,body_top*SCALE),body)
    put(im,str(p.get('code',''))[:24],(125,214,178,220),5.2,'title',align='right')
    put(im,str(p.get('edition',''))[:24],(21,214,115,220),5.2,'title')
    # Downsample only newly drawn content, retaining all untouched native pixels.
    channels=ImageChops.difference(im,base).split()
    changed=ImageChops.lighter(ImageChops.lighter(channels[0],channels[1]),channels[2]).resize(SIZE,Image.Resampling.BOX).point(lambda v:255 if v else 0)
    final=Image.composite(im.resize(SIZE,Image.Resampling.LANCZOS),native,changed)
    if monster:native_stats(final,p)
    if native_slot is not None:
        final.paste(native_slot,(159,14))
    return final,{'bodySize':round(actual,1),'lines':len(lines)}

def png(im):
    buf=io.BytesIO(); im.save(buf,format='PNG'); return buf.getvalue()

class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def respond(self,data,status=200,ctype='application/json'):
        if isinstance(data,dict): data=json.dumps(data).encode()
        self.send_response(status); self.send_header('Content-Type',ctype); self.send_header('Content-Length',str(len(data))); self.send_header('Cache-Control','no-store'); self.end_headers(); self.wfile.write(data)
    def do_GET(self):
        if self.path=='/': self.respond((HERE/'index.html').read_bytes(),ctype='text/html; charset=utf-8')
        elif self.path=='/api/catalog': self.respond({'defaults':DEFAULTS,'races':RACES[1:],'attributes':list(SYMBOLS.keys()),'subtypes':{kind:sorted(sub for typ,sub in SUBTYPES if typ==kind) for kind in ('Spell','Trap')}})
        else: self.respond({'error':'Not found'},404)
    def do_POST(self):
        # Accept local same-origin requests only; no remote-host control of local exports.
        origin=self.headers.get('Origin')
        if origin and origin not in ('http://127.0.0.1:8765','http://localhost:8765'):
            return self.respond({'error':'Foreign origin rejected'},403)
        try:
            n=int(self.headers.get('Content-Length','0'))
            if not 0<n<=40_000_000: raise ValueError('Request too large or empty.')
            p=json.loads(self.rfile.read(n))
            im,info=render(p)
            if self.path=='/api/render':
                self.respond({'image':'data:image/png;base64,'+base64.b64encode(png(im)).decode(),**info})
            elif self.path=='/api/export':
                name=str(p.get('filename','')).strip()
                if not re.fullmatch(r'[A-Za-z0-9_-]{1,64}',name): raise ValueError('Filename must contain only letters, numbers, hyphens or underscores.')
                OUT.mkdir(parents=True,exist_ok=True)
                targets=[OUT/(name+'.png'),OUT/(name+'-mini.png'),OUT/(name+'.json')]
                if any(x.exists() for x in targets): raise ValueError('That filename already exists. Choose a new name; existing cards are never overwritten.')
                # Exclusive creation also prevents simultaneous exports overwriting one another.
                created=[]
                try:
                    for target,data in zip(targets,[png(im),png(im.resize((50,72),Image.Resampling.BICUBIC)),json.dumps(p,indent=2).encode()]):
                        with target.open('xb') as out: out.write(data)
                        created.append(target)
                except Exception:
                    for target in created: target.unlink()
                    raise
                self.respond({'files':[str(x) for x in targets],**info})
            else: self.respond({'error':'Not found'},404)
        except (ValueError,KeyError,OSError,TypeError) as e: self.respond({'error':str(e)},400)

class BuilderServer(ThreadingHTTPServer):
    # Windows otherwise allows multiple servers to bind the same port, leaving
    # the browser talking to an older process even after a new one starts.
    allow_reuse_address=False
    def server_bind(self):
        if hasattr(socket,'SO_EXCLUSIVEADDRUSE'):
            self.socket.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1)
        super().server_bind()

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser(); parser.add_argument('--no-browser',action='store_true'); args=parser.parse_args()
    httpd=BuilderServer(('127.0.0.1',8765),Handler)
    print('Card Builder: http://127.0.0.1:8765',flush=True)
    if not args.no_browser: threading.Timer(.7,lambda:webbrowser.open('http://127.0.0.1:8765')).start()
    httpd.serve_forever()

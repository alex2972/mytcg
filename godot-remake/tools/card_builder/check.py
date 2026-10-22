"""Meaningful renderer checks and original-versus-rendered visual comparisons."""
import base64
import hashlib
from pathlib import Path
from PIL import Image, ImageDraw
import server as builder

out=builder.ROOT/'output/card_builder_checks'; out.mkdir(parents=True,exist_ok=True)
before={key:hashlib.sha256((builder.CARDS/(key+'.png')).read_bytes()).hexdigest() for key in builder.DEFAULTS.values()}
sheet=Image.new('RGB',(6*220,640),'#182126')
draw=ImageDraw.Draw(sheet)
for i,(kind,key) in enumerate(builder.DEFAULTS.items()):
    c=builder.CATALOG[key]
    original=builder.source(key)
    art=original.crop(builder.ART)
    p=dict(c,kind=kind,template=key,description=c['description'],code=key,titleSize=16,bodySize=6.3,
           artwork='data:image/png;base64,'+base64.b64encode(builder.png(art)).decode())
    image,info=builder.render(p)
    assert image.size==(200,290)
    assert image.resize((50,72)).size==(50,72)
    assert info['lines']>0
    image.save(out/(kind.lower()+'.png'))
    sheet.paste(original,(i*220+10,30)); sheet.paste(image,(i*220+10,340))
    draw.text((i*220+10,8),kind+' / original',fill='white')
    draw.text((i*220+10,323),'Builder recreation',fill='white')
    # Border pixels well outside the edited regions remain the original palette.
    assert abs(image.getpixel((10,100))[0]-original.getpixel((10,100))[0])<=2
sheet.save(out/'comparison.png')
# Short-description references must retain their clean blank area and divider.
for kind,key in [('Fusion','TP3007'),('Ritual','MRL068')]:
    assert builder.DEFAULTS[kind]==key
    clean=builder.clean_frame(kind)
    assert clean.crop((20,263,181,265)).tobytes()==builder.source(key).crop((20,263,181,265)).tobytes()
for kind in ['Normal','Effect','Fusion','Ritual']:
    clean=builder.clean_frame(kind)
    native=builder.source(builder.DEFAULTS[kind])
    assert clean.crop((181,265,185,273)).tobytes()==native.crop((181,265,185,273)).tobytes(), 'Stat highlight must preserve the border.'
    assert sum(clean.getpixel((150,272)))>=sum(native.getpixel((90,272))), 'Pale highlight below stats was lost.'
for color in ['#000000','#ffffff','#e8cb47']:
    colored,_=builder.render(dict(p,kind='Fusion',level=6,titleColor=color))
    assert colored.size==builder.SIZE

_,info=builder.render(dict(p,description='A fairly long description to exercise automatic wrapping and shrinking. '*8))
assert info['bodySize']<6.3
for attribute in ['LIGHT','DARK','WATER','FIRE','EARTH','WIND']:
    builder.render(dict(p,kind='Ritual',template='zzz038',attribute=attribute,level=12))
for invalid in [dict(p,kind='Invalid'),dict(p,kind='Normal',level=0)]:
    try: builder.render(invalid)
    except ValueError: pass
    else: raise AssertionError('Invalid input accepted')
base=dict(p,kind='Normal',name='Dark Assailant',level=4,passcode='41949033')
im_a,_=builder.render(base)
im_b,_=builder.render(dict(base,passcode='',template='../ignored'))
assert im_a.tobytes()==im_b.tobytes(), 'Obsolete passcode/template inputs must not affect the image.'
assert builder.TITLE_ATLAS and all(ch in builder.TITLE_ATLAS['glyphs'] for ch in 'DarkAssailant')
one,_=builder.render(dict(base,level=1))
four,_=builder.render(dict(base,level=4))
assert max(abs(a-b) for a,b in zip(one.getpixel((121,43)),four.getpixel((121,43))))<=3, 'Star corners must remain transparent.'
native=builder.source(builder.DEFAULTS['Normal'])
for box in [(24,41,119,58),(16,14,158,19),(16,35,158,40),(15,273,88,278),(15,250,20,278)]:
    assert four.crop(box).tobytes()==native.crop(box).tobytes(), f'Native frame pixels changed in {box}'
samples=Image.new('RGB',(3*220,630),'#182126')
for i,key in enumerate(['MRL057','MRL058','MRD023']):
    c=builder.CATALOG[key]; orig=builder.source(key)
    params=dict(c,kind='Normal',name=c['name'],description=c['description'],code=key,
                artwork='data:image/png;base64,'+base64.b64encode(builder.png(orig.crop(builder.ART))).decode())
    rebuilt,_=builder.render(params)
    samples.paste(orig,(i*220+10,10));samples.paste(rebuilt,(i*220+10,325))
samples.save(out/'user-examples-comparison.png')
assert before=={key:hashlib.sha256((builder.CARDS/(key+'.png')).read_bytes()).hexdigest() for key in before}
print('Passed: six card types, artwork crop, palette, symbols, text fitting, invalid input and original preservation.')
print(out/'comparison.png')
if '--http' in __import__('sys').argv:
    import json
    import uuid
    from urllib.request import Request, urlopen
    from urllib.error import HTTPError
    p['filename']='builder-check-'+uuid.uuid4().hex[:8]
    data=json.dumps(p).encode()
    def request():
        return urlopen(Request('http://127.0.0.1:8765/api/export',data,{'Content-Type':'application/json'}))
    result=json.loads(request().read())
    assert Image.open(result['files'][0]).size==(200,290)
    assert Image.open(result['files'][1]).size==(50,72)
    assert json.loads(Path(result['files'][2]).read_text())==p
    try: request()
    except HTTPError as e: assert e.code==400
    else: raise AssertionError('Duplicate export overwrote existing files')
    print('Passed: HTTP export, PNG sizes, project round trip and duplicate protection.')


# DEF's complete label must stay identical for every value and number length.
stat_label=None
for value in [0,50,500,1850,2300,6789,9999]:
    image,_=builder.render(dict(base,atk=value,**{'def':value}))
    label=image.crop((144,265,160,273)).tobytes()
    if stat_label is None:stat_label=label
    assert label==stat_label, 'Stat label changed with the value.'
    assert image.crop((181,266,185,273)).tobytes()==builder.clean_frame('Normal').crop((181,266,185,273)).tobytes()

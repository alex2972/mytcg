"""Extract native stat rows and digit masks from original game cards."""
import base64
import io
import json
from pathlib import Path
from PIL import Image
import server


def encode(mask):
    out=io.BytesIO();mask.save(out,format='PNG')
    return base64.b64encode(out.getvalue()).decode()


def extract(im, box):
    left,top,right,bottom=box
    mask=Image.new('L',(right-left,bottom-top))
    for x in range(left,right):
        # Edge rows contain faint ink too. Estimate the local blank paper from
        # the brightest nearby pixels, never from a row containing the border.
        samples=[im.getpixel((xx,yy)) for xx in range(max(20,x-2),min(180,x+3)) for yy in range(265,273)]
        bg=[max(pixel[channel] for pixel in samples) for channel in range(3)]
        for y in range(top,bottom):
            pixel=im.getpixel((x,y))
            alpha=max(0,min(255,round(255*(1-sum(pixel)/max(1,sum(bg))))))
            mask.putpixel((x-left,y-top),alpha if alpha>12 and y<273 else 0)
    return mask


def main():
    atlas={'digits':{},'leadingDigits':{},'labels':{}}
    # All digits come from the same position in standard four-digit rows.
    # This avoids mixing compressed promotional-card text and raster phases.
    for ch in '0123456789':
        value=1000+int(ch)*100
        candidates=[key for key in sorted(server.CATALOG) if key.startswith(('MRL','MRD','LOB')) and server.CATALOG[key]['kind'] not in ('Spell','Trap') and server.CATALOG[key]['atk']==value]
        if not candidates:raise ValueError('No standard sample for digit '+ch)
        key=next((k for k in candidates if k.startswith('MRL')),candidates[0])
        digit=extract(server.source(key),(125,265,130,274))
        atlas['digits'][ch]={'mask':encode(digit),'source':key}
    # Leading digits sit beside the slash and have a different raster offset.
    # Capture that placement rather than borrowing the second digit's offset.
    for ch in '0123456789':
        candidates=[key for key in sorted(server.CATALOG) if key.startswith(('MRL','MRD','LOB')) and server.CATALOG[key]['kind'] not in ('Spell','Trap') and len(str(server.CATALOG[key]['atk']))==4 and str(server.CATALOG[key]['atk']).startswith(ch)]
        if candidates:
            key=candidates[0]
            digit=extract(server.source(key),(120,265,125,274))
            # The slash occupies the first two columns of this shared boundary.
            for x in (0,1):
                for y in range(9):digit.putpixel((x,y),0)
        else:
            original=Image.open(io.BytesIO(base64.b64decode(atlas['digits'][ch]['mask']))).convert('L')
            digit=Image.new('L',(5,9));digit.paste(original.crop((1,0,5,9)),(1,0))
        atlas['leadingDigits'][ch]=encode(digit)
    for field,left,right in [('atk',102,122),('def',144,162)]:
        atlas['labels'][field]=encode(extract(server.source('MRL058'),(left,265,right,274)))
    if set(atlas['digits'])!=set('0123456789'):
        raise ValueError('Missing native digit samples: '+str(set('0123456789')-set(atlas['digits'])))
    Path(__file__).with_name('stat_glyphs.json').write_text(json.dumps(atlas,indent=2))
    print('Extracted fixed ATK/DEF labels and all ten native digits.')


if __name__=='__main__':main()

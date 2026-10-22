"""Render a folder of artwork and a CSV through the interactive card renderer."""
import argparse
import base64
import csv
import json
import math
import re
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw
import server as builder

FIELDS = ['filename', 'artwork', 'name', 'kind', 'attribute', 'level', 'race',
          'atk', 'def', 'description', 'code', 'edition', 'titleColor', 'subtype',
          'zoom', 'cropX', 'cropY', 'brightness', 'contrast', 'saturation']
NUMBERS = {'level': int, 'atk': int, 'def': int, 'titleSize': float,
           'bodySize': float, 'zoom': float, 'cropX': float, 'cropY': float,
           'brightness': float, 'contrast': float, 'saturation': float}
COLORS = {'black': '#000000', 'white': '#ffffff', 'gold': '#e8cb47'}


def read_rows(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        sample = stream.read(8192)
        stream.seek(0)
        try:
            dialect = csv.Sniffer().sniff(sample, delimiters=',;\t')
        except csv.Error:
            dialect = csv.excel
        reader = csv.DictReader(stream, dialect=dialect)
        if not reader.fieldnames or not {'filename', 'name', 'kind'}.issubset(reader.fieldnames):
            raise ValueError('CSV needs filename, name and kind columns. Use the provided template.')
        return [row for row in reader if any(str(v or '').strip() for v in row.values())]


def prepare(row, artwork_dir):
    if None in row:
        raise ValueError('Extra CSV values: put descriptions containing commas inside double quotes.')
    p = {str(k).strip(): str(v).strip() for k, v in row.items() if v is not None and str(v).strip()}
    name = p.get('filename', '')
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,64}', name):
        raise ValueError('filename needs 1–64 letters, numbers, hyphens or underscores.')
    if not p.get('name'):
        raise ValueError('Card name is missing.')
    p['kind'] = p.get('kind', '').title()
    if p['kind'] not in builder.DEFAULTS:
        raise ValueError('kind must be Normal, Effect, Fusion, Ritual, Spell or Trap.')
    monster = p['kind'] not in ('Spell', 'Trap')
    required = ['attribute', 'level', 'race', 'atk', 'def'] if monster else []
    missing = [field for field in required if field not in p]
    if missing:
        raise ValueError('Missing monster fields: ' + ', '.join(missing))
    for field, convert in NUMBERS.items():
        if field in p:
            try:
                p[field] = convert(p[field])
            except ValueError:
                raise ValueError(f'{field} is not a valid number.') from None
            if not math.isfinite(p[field]):
                raise ValueError(f'{field} must be finite.')
    if monster:
        p['attribute'] = p['attribute'].upper()
        races = {race.lower(): race for race in builder.RACES if race}
        if p['race'].lower() not in races:
            raise ValueError('Unknown monster race: ' + p['race'])
        p['race'] = races[p['race'].lower()]
        if p['atk'] < 0 or p['def'] < 0:
            raise ValueError('ATK and DEF must be zero or greater.')
    color = p.get('titleColor', 'black' if monster else 'white')
    p['titleColor'] = COLORS.get(color.lower(), color)
    p['description'] = p.get('description', '').replace('\\n', '\n')
    relative = p.pop('artwork', name + '.png')
    art = (artwork_dir / relative).resolve()
    if not art.is_relative_to(artwork_dir.resolve()):
        raise ValueError('Artwork must be inside the artwork folder.')
    if not art.is_file():
        raise ValueError('Artwork file not found: ' + relative)
    if art.stat().st_size > 25_000_000:
        raise ValueError('Artwork file is larger than 25 MB.')
    p['artwork'] = 'data:application/octet-stream;base64,' + base64.b64encode(art.read_bytes()).decode()
    return p


def save_card(folder, p, image):
    targets = [folder / (p['filename'] + suffix) for suffix in ('.png', '-mini.png', '.json')]
    data = [builder.png(image), builder.png(image.resize((50, 72), Image.Resampling.BICUBIC)),
            json.dumps(p, ensure_ascii=False, indent=2).encode('utf-8')]
    created = []
    try:
        for target, payload in zip(targets, data):
            with target.open('xb') as stream:
                stream.write(payload)
            created.append(target)
    except Exception:
        for target in created:
            target.unlink()
        raise
    return [str(target) for target in targets]


def preview_pages(folder, cards):
    pages = []
    for offset in range(0, len(cards), 24):
        group = cards[offset:offset + 24]
        sheet = Image.new('RGB', (880, math.ceil(len(group) / 4) * 320), '#182126')
        draw = ImageDraw.Draw(sheet)
        for i, (name, image) in enumerate(group):
            x, y = (i % 4) * 220 + 10, (i // 4) * 320 + 8
            draw.text((x, y), name[:30], fill='white')
            sheet.paste(image, (x, y + 20))
        target = folder / f'preview-{offset // 24 + 1:02d}.png'
        sheet.save(target)
        pages.append(str(target))
    return pages


def run(csv_path, artwork_dir, output_root):
    rows = read_rows(csv_path)
    if not rows:
        raise ValueError('CSV has no card rows.')
    if not artwork_dir.is_dir():
        raise ValueError('Artwork folder not found.')
    # Batch exports belong outside game assets; each run gets its own folder.
    output_root = output_root.resolve()
    assets = (builder.ROOT / 'assets').resolve()
    if output_root.is_relative_to(assets):
        raise ValueError('Choose an output folder outside assets. Review exports before adding them to the game.')
    folder = output_root / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    folder.mkdir(parents=True, exist_ok=False)
    report, previews, seen = [], [], set()
    for number, row in enumerate(rows, 2):
        entry = {'row': number, 'filename': row.get('filename', ''), 'name': row.get('name', '')}
        try:
            p = prepare(row, artwork_dir)
            if p['filename'].lower() in seen:
                raise ValueError('Duplicate filename in this CSV.')
            seen.add(p['filename'].lower())
            image, info = builder.render(p)
            entry.update(status='created', files=save_card(folder, p, image), **info)
            previews.append((p['filename'], image))
            print(f"Created {p['filename']}", flush=True)
        except (ValueError, KeyError, OSError, TypeError, OverflowError) as error:
            entry.update(status='error', error=str(error))
            print(f"Row {number}: {error}", flush=True)
        report.append(entry)
    summary = {'created': len(previews), 'errors': len(rows) - len(previews),
               'input': str(csv_path.resolve()), 'previewPages': preview_pages(folder, previews), 'cards': report}
    (folder / 'report.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    with (folder / 'report.csv').open('w', encoding='utf-8-sig', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=['row', 'filename', 'name', 'status', 'error'])
        writer.writeheader()
        writer.writerows({k: entry.get(k, '') for k in writer.fieldnames} for entry in report)
    print(f"\n{summary['created']} created; {summary['errors']} errors.\nSaved to {folder}")
    return folder, summary


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv', type=Path, help='CSV with one row per new card')
    parser.add_argument('--artwork', type=Path, help='Artwork folder; defaults to artwork beside the CSV')
    parser.add_argument('--output', type=Path, default=builder.ROOT / 'output/card_builder_batches')
    args = parser.parse_args()
    try:
        _, result = run(args.csv, args.artwork or args.csv.parent / 'artwork', args.output)
    except (ValueError, OSError, csv.Error) as error:
        parser.exit(2, str(error) + '\n')
    raise SystemExit(1 if result['errors'] else 0)

"""Exercise real batch files, rendering, partial failures and repeat runs."""
import csv
import json
import tempfile
from pathlib import Path

from PIL import Image
import batch
import server as builder


def main():
    with tempfile.TemporaryDirectory(prefix='batch-check-', dir=builder.ROOT / 'output') as temporary:
        root = Path(temporary)
        art = root / 'artwork'
        art.mkdir()
        builder.source('MRD023').crop(builder.ART).save(art / 'moth.png')
        builder.source('SDY042').crop(builder.ART).save(art / 'spell.jpg')
        rows = [
            dict(filename='moth', artwork='moth.png', name='Petit Moth', kind='Normal',
                 attribute='EARTH', level=1, race='Insect', atk=300, **{'def': 200},
                 description='A small moth, with a quoted "description".', titleColor='gold'),
            dict(filename='spell', artwork='spell.jpg', name='Spell Test', kind='Spell', description='First line.\\nSecond line.'),
            dict(filename='missing', artwork='missing.png', name='Missing Art', kind='Trap'),
            dict(filename='moth', artwork='moth.png', name='Duplicate', kind='Trap'),
            dict(filename='escape', artwork='../outside.png', name='Escaped File', kind='Trap')]
        manifest = root / 'cards.csv'
        with manifest.open('w', encoding='utf-8-sig', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=batch.FIELDS)
            writer.writeheader()
            writer.writerows(rows)
        folder, report = batch.run(manifest, art, root / 'exports')
        assert report['created'] == 2 and report['errors'] == 3
        assert len(report['previewPages']) == 1
        assert (folder / 'report.csv').is_file()
        for name in ['moth', 'spell']:
            image = Image.open(folder / (name + '.png')).convert('RGB')
            assert image.size == (200, 290)
            assert Image.open(folder / (name + '-mini.png')).size == (50, 72)
            project = json.loads((folder / (name + '.json')).read_text(encoding='utf-8'))
            rebuilt, _ = builder.render(project)
            assert image.tobytes() == rebuilt.tobytes()
        before = (folder / 'moth.png').read_bytes()
        second, _ = batch.run(manifest, art, root / 'exports')
        assert second != folder and (folder / 'moth.png').read_bytes() == before
        assert batch.prepare(rows[1], art)['titleColor'] == '#ffffff'
        assert batch.prepare(rows[0], art)['titleColor'] == '#e8cb47'
    print('Passed: batch inputs, comma/quote text, errors, duplicate protection, exports, previews and editable projects.')


if __name__ == '__main__':
    main()

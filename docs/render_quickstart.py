"""Draw the documented directory layouts as SVG and PNG from the same geometry.

Requires Pillow for the PNG export. No application screenshots or image models
are used. Run from any directory: python docs/render_quickstart.py
"""
from html import escape
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent / 'images'
OUT.mkdir(parents=True, exist_ok=True)
INK, MUTED, BORDER, BLUE = '#24292f', '#57606a', '#d0d7de', '#0969da'


def font(size, mono=False, bold=False):
    name = ('consolab.ttf' if bold else 'consola.ttf') if mono else ('arialbd.ttf' if bold else 'arial.ttf')
    candidate = Path('C:/Windows/Fonts') / name
    if candidate.exists():
        return ImageFont.truetype(str(candidate), size)
    family = 'DejaVuSansMono' if mono else 'DejaVuSans'
    return ImageFont.truetype(family + ('-Bold' if bold else '') + '.ttf', size)


class Drawing:
    def __init__(self, width, height, title, description):
        self.width, self.height = width, height
        self.im = Image.new('RGB', (width, height), 'white')
        self.draw = ImageDraw.Draw(self.im)
        self.parts = [
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
            f'<title id="title">{escape(title)}</title><desc id="desc">{escape(description)}</desc>',
            f'<rect width="{width}" height="{height}" fill="white"/>',
        ]

    def rect(self, x, y, w, h, fill='white', stroke=BORDER):
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}"/>')
        self.draw.rectangle((x, y, x+w, y+h), fill=fill, outline=stroke)

    def line(self, points, color=BORDER, width=2):
        coords = ' '.join(f'{x},{y}' for x, y in points)
        self.parts.append(f'<polyline points="{coords}" fill="none" stroke="{color}" stroke-width="{width}"/>')
        self.draw.line(points, fill=color, width=width)

    def text(self, x, y, value, size=23, color=INK, mono=False, bold=False):
        f = font(size, mono, bold)
        bounds = self.draw.textbbox((x, y), value, font=f, anchor='ls')
        assert bounds[0] >= 0 and bounds[2] <= self.width and bounds[3] <= self.height, (value, bounds)
        family = 'Consolas, DejaVu Sans Mono, monospace' if mono else 'Arial, Helvetica, sans-serif'
        weight = '700' if bold else '400'
        self.parts.append(f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" font-weight="{weight}" fill="{color}">{escape(value)}</text>')
        self.draw.text((x, y), value, font=f, fill=color, anchor='ls')

    def folder(self, x, y):
        self.line([(x, y+22), (x, y+3), (x+9, y+3), (x+13, y+7), (x+27, y+7), (x+27, y+22), (x, y+22)], MUTED, 2)

    def file(self, x, y, color=BLUE):
        self.line([(x+3, y+23), (x+3, y+2), (x+18, y+2), (x+24, y+8), (x+24, y+23), (x+3, y+23)], color, 2)
        self.line([(x+18, y+2), (x+18, y+8), (x+24, y+8)], color, 2)

    def row(self, x, y, label, is_file=False, emphasis=False, size=22):
        (self.file if is_file else self.folder)(x, y-23)
        self.text(x+40, y, label, size, BLUE if emphasis else INK, mono=True, bold=emphasis)

    def save(self, name):
        self.parts.append('</svg>')
        (OUT / f'{name}.svg').write_text('\n'.join(self.parts)+'\n', encoding='utf-8')
        self.im.save(OUT / f'{name}.png', optimize=True)


# The uppermost application directory is the destination, regardless of drive.
d = Drawing(1280, 650, 'Where to put the repair files',
            'Copy every extracted repair file into the existing INSPR project root. The CMD must be beside the installed astigmatism or biplane setup folders.')
d.text(32, 45, 'Copy the repair contents into your INSPR project', 29, bold=True)
d.text(32, 83, 'The project can contain either toolbox or both.', 22, MUTED)
d.rect(32, 114, 400, 376)
d.rect(572, 114, 676, 376)
d.text(54, 150, 'Repair repository', 23, bold=True)
d.text(594, 150, 'Existing INSPR project', 23, bold=True)
d.line([(32, 174), (432, 174)], width=1)
d.line([(572, 174), (1248, 174)], width=1)
for y, label, is_file in [(220, 'Start-INSPR.cmd', True), (272, 'deployment/', False),
                          (324, 'runtime/', False), (376, 'docs/', False)]:
    d.row(56, y, label, is_file, emphasis=is_file)
d.text(56, 447, '+ the remaining repository files', 20, MUTED)
d.text(596, 213, 'INSPR-master/', 23, mono=True, bold=True)
d.line([(610, 233), (610, 450)], width=1)
for y, label, is_file in [(260, 'INSPR for astigmatism-based setup/', False),
                          (310, 'INSPR for biplane setup/', False),
                          (360, 'Start-INSPR.cmd', True),
                          (410, 'deployment/', False), (460, 'runtime/', False)]:
    d.line([(610, y-10), (632, y-10)], width=1)
    d.row(638, y, label, is_file, emphasis=is_file, size=21)
d.text(461, 280, 'copy all', 19, MUTED)
d.line([(455, 310), (549, 310)], BLUE, 2)
d.line([(537, 301), (549, 310), (537, 319)], BLUE, 2)
d.text(32, 546, 'Start-INSPR.cmd and the setup folders belong at the same level.', 23, bold=True)
d.text(32, 586, 'Do not leave the repair files inside an extra INSPR-Environment-Repair-main folder.', 22, MUTED)
d.text(32, 625, 'INSPR-master is an example project name. Some files are omitted from this diagram.', 20, MUTED)
d.save('extract-to-project')

# Indentation and continuous branch lines show complete relative entry paths.
d = Drawing(1280, 636, 'INSPR toolbox entry points',
            'Astigmatism: INSPR for astigmatism-based setup / INSPR astigmatism toolbox / main.m. Biplane: INSPR for biplane setup / INSPR toolbox / main.m. Run each toolbox in a separate MATLAB process.')
d.text(32, 45, 'Open the main.m for your toolbox', 29, bold=True)
d.text(32, 83, 'In MATLAB, run the entire script.', 22, MUTED)
d.rect(32, 115, 780, 444)
d.row(58, 163, 'INSPR-master/', size=24)
d.line([(71, 181), (71, 397), (106, 397)], width=1)
d.line([(71, 219), (106, 219)], width=1)
d.row(112, 230, 'INSPR for astigmatism-based setup/', size=23)
d.line([(125, 244), (125, 283), (160, 283)], width=1)
d.row(166, 294, 'INSPR astigmatism toolbox/', size=23)
d.line([(179, 308), (179, 347), (214, 347)], width=1)
d.row(220, 358, 'main.m', True, True, 24)
d.row(112, 408, 'INSPR for biplane setup/', size=23)
d.line([(125, 422), (125, 461), (160, 461)], width=1)
d.row(166, 472, 'INSPR toolbox/', size=23)
d.line([(179, 486), (179, 525), (214, 525)], width=1)
d.row(220, 536, 'main.m', True, True, 24)
d.text(857, 211, 'After the one-time repair', 23, bold=True)
for y, label in [(262, 'Open MATLAB.'), (308, 'Open the chosen main.m.'), (354, 'Click Run.')]:
    d.text(857, y, label, 23)
d.line([(857, 389), (1238, 389)], width=1)
d.text(857, 436, 'Keep deployment/ and', 22, MUTED)
d.text(857, 469, 'runtime/ in the project.', 22, MUTED)
d.text(32, 609, 'Use a separate MATLAB process for each toolbox.', 23, bold=True)
d.save('run-main-in-matlab')
print('Rendered SVG and PNG directory diagrams:', OUT)

"""Render the documentation's folder-layout illustrations (not screenshots)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent / 'images'
OUT.mkdir(parents=True, exist_ok=True)
INK = '#172B4D'
MUTED = '#52647C'
BLUE = '#155EEF'
GREEN = '#087443'
LINE = '#D5DEE9'


def font(size, bold=False, mono=False):
    name = 'consola.ttf' if mono else ('arialbd.ttf' if bold else 'arial.ttf')
    path = Path('C:/Windows/Fonts') / name
    if path.exists():
        return ImageFont.truetype(str(path), size)
    return ImageFont.truetype('DejaVuSansMono.ttf' if mono else
                              ('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf'), size)


def canvas(height):
    im = Image.new('RGB', (1400, height), '#F5F7FB')
    return im, ImageDraw.Draw(im)


def text(d, x, y, value, size=28, color=INK, bold=False, mono=False):
    d.text((x, y), value, font=font(size, bold, mono), fill=color, spacing=10)


def box(d, bounds, fill='white', outline=LINE, radius=16):
    d.rounded_rectangle(bounds, radius=radius, fill=fill, outline=outline, width=2)


def folder(d, x, y):
    d.rounded_rectangle((x, y+3, x+20, y+14), radius=3, fill='#F4C25F')
    d.rounded_rectangle((x, y+10, x+34, y+33), radius=3, fill='#EAAF34')


def file_icon(d, x, y, color=BLUE):
    d.rounded_rectangle((x+3, y+1, x+27, y+32), radius=3, fill='white', outline=color, width=2)
    d.line((x+9, y+13, x+21, y+13), fill=color, width=2)
    d.line((x+9, y+20, x+21, y+20), fill=color, width=2)


def header(d, number, label, title, subtitle):
    box(d, (64, 42, 116, 94), fill=BLUE, outline=BLUE, radius=12)
    text(d, 82, 49, str(number), 30, 'white', True)
    text(d, 135, 53, label, 25, BLUE, True)
    text(d, 64, 116, title, 43, bold=True)
    text(d, 64, 181, subtitle, 25, MUTED)


im, d = canvas(1110)
header(d, 1, 'FIRST-TIME SETUP', 'Copy the repair files into your existing INSPR project',
       'Folder layout illustration. C:\\SMLM\\INSPR-master is an example; your location may differ.')
box(d, (64, 244, 540, 708))
text(d, 90, 270, 'Downloaded repair ZIP', 29, bold=True)
text(d, 90, 322, 'INSPR_Environment_Repair.zip', 22, mono=True)
d.line((90, 367, 514, 367), fill=LINE, width=2)
for y, label, is_folder in [(397, 'Start-INSPR.cmd', False), (455, 'deployment', True),
                             (513, 'runtime', True), (571, 'docs', True)]:
    (folder if is_folder else file_icon)(d, 96, y)
    text(d, 144, y+2, label, 25, mono=True)
text(d, 90, 639, 'Extract, then copy ALL contents.', 23, BLUE, True)
text(d, 90, 674, 'Key items shown above.', 20, MUTED)

d.line((557, 487, 624, 487), fill=BLUE, width=5)
d.polygon([(624, 476), (644, 487), (624, 498)], fill=BLUE)
text(d, 559, 445, 'Copy', 22, BLUE, True)

box(d, (658, 244, 1336, 805))
text(d, 684, 270, 'Your existing INSPR project', 29, bold=True)
box(d, (681, 320, 1313, 371), fill='#ECF2FF', outline='#ECF2FF', radius=8)
text(d, 696, 329, 'C:\\SMLM\\INSPR-master', 27, BLUE, mono=True)
folder(d, 700, 398)
text(d, 748, 402, 'INSPR for astigmatism-based setup', 24, mono=True)
box(d, (683, 451, 1312, 503), fill='#E9F7EF', outline='#B7DCC8', radius=8)
file_icon(d, 700, 461, GREEN)
text(d, 748, 464, 'Start-INSPR.cmd', 26, GREEN, True, True)
text(d, 1165, 469, 'RUN ONCE', 20, GREEN, True)
for y, label, is_folder in [(527, 'deployment', True), (586, 'runtime', True),
                             (645, 'setup_inspr_cuda.m', False), (704, 'docs', True)]:
    (folder if is_folder else file_icon)(d, 700, y)
    text(d, 748, y+3, label, 25, mono=True)
text(d, 684, 764, 'The setup folder and CMD file are at the SAME LEVEL.', 22, GREEN, True)

box(d, (64, 842, 1336, 1021), fill='#FFF3F0', outline='#F0C6BD')
text(d, 90, 866, 'Avoid an extra folder layer', 29, '#A32917', True)
text(d, 90, 919, 'INSPR-master\\INSPR_Environment_Repair\\Start-INSPR.cmd', 27, '#A32917', mono=True)
text(d, 90, 970, 'If your path looks like this, move the repair files one level up.', 27, MUTED)
text(d, 64, 1054, 'After copying: double-click Start-INSPR.cmd in the existing project root.', 26, INK)
im.save(OUT / 'extract-to-project.png', optimize=True)

im, d = canvas(860)
header(d, 2, 'EVERYDAY USE', 'Open the project\'s main.m in MATLAB',
       'After the one-time repair has passed, use this entry point each time you open MATLAB.')
box(d, (64, 245, 844, 655))
text(d, 90, 274, 'Follow this folder path', 29, bold=True)
text(d, 90, 327, 'C:\\SMLM\\INSPR-master', 26, BLUE, mono=True)
for x, y, label in [(124, 388, 'INSPR for astigmatism-based setup'),
                     (164, 455, 'INSPR astigmatism toolbox')]:
    folder(d, x, y)
    text(d, x+48, y+3, label, 25, mono=True)
box(d, (194, 519, 801, 579), fill='#E9F7EF', outline='#B7DCC8', radius=8)
file_icon(d, 211, 531, GREEN)
text(d, 259, 531, 'main.m', 30, GREEN, True, True)
text(d, 90, 611, 'Example drive and root folder; keep the inner folder names.', 22, MUTED)

box(d, (882, 245, 1336, 655))
text(d, 910, 275, 'In MATLAB', 29, bold=True)
text(d, 910, 334, 'Open main.m and\nclick Run.', 30)
text(d, 910, 425, 'Or set Current Folder to the\ntoolbox folder, then type:', 25, MUTED)
box(d, (910, 522, 1308, 589), fill='#ECF2FF', outline='#ECF2FF', radius=8)
text(d, 932, 536, '>> main', 32, BLUE, mono=True)
text(d, 910, 611, 'Illustrated workflow, not a screenshot.', 20, MUTED)

box(d, (64, 695, 1336, 811), fill='#E9F7EF', outline='#B7DCC8')
text(d, 90, 714, 'Run the entire main.m script.', 31, GREEN, True)
text(d, 90, 764, 'It prepares the DLL path automatically. You do not need to rerun the CMD.', 27)
im.save(OUT / 'run-main-in-matlab.png', optimize=True)
print('Rendered two documentation illustrations to', OUT)

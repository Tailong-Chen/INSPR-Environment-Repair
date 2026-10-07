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



im, d = canvas(1140)
header(d, 1, 'FIRST-TIME SETUP', 'Copy the repair files into your existing INSPR project',
       'Folder layout illustration. Your drive and project location may differ from this example.')
box(d, (64, 244, 540, 738))
text(d, 90, 270, 'Downloaded repair ZIP', 29, bold=True)
text(d, 90, 322, 'INSPR_Environment_Repair.zip', 22, mono=True)
d.line((90, 367, 514, 367), fill=LINE, width=2)
for y, label, is_folder in [(397, 'Start-INSPR.cmd', False), (455, 'deployment', True),
                           (513, 'runtime', True), (571, 'docs', True)]:
    (folder if is_folder else file_icon)(d, 96, y)
    text(d, 144, y+2, label, 25, mono=True)
text(d, 90, 652, 'Extract, then copy ALL contents.', 23, BLUE, True)
text(d, 90, 690, 'Key items shown above.', 20, MUTED)
d.line((557, 505, 624, 505), fill=BLUE, width=5)
d.polygon([(624, 494), (644, 505), (624, 516)], fill=BLUE)
text(d, 559, 462, 'Copy', 22, BLUE, True)
box(d, (658, 244, 1336, 846))
text(d, 684, 270, 'Your existing INSPR project', 29, bold=True)
text(d, 684, 323, r'C:\SMLM\INSPR-master', 27, BLUE, mono=True)
for y, label in [(379,'INSPR for astigmatism-based setup'),(431,'INSPR for biplane setup')]:
    folder(d,700,y)
    text(d,748,y+3,label,23,mono=True)
text(d,700,486,'Either setup folder, or both, may be present.',23,MUTED)
box(d, (683, 531, 1312, 587), fill='#E9F7EF', outline='#B7DCC8', radius=8)
file_icon(d,700,543,GREEN)
text(d,748,546,'Start-INSPR.cmd',26,GREEN,True,True)
text(d,1165,550,'RUN ONCE',20,GREEN,True)
for y, label, is_folder in [(613,'deployment',True),(665,'runtime',True),(717,'setup_inspr_cuda.m',False),(769,'docs',True)]:
    (folder if is_folder else file_icon)(d,700,y)
    text(d,748,y+3,label,24,mono=True)
box(d,(64,882,1336,1041),fill='#FFF3F0',outline='#F0C6BD')
text(d,90,903,'Avoid an extra folder layer',29,'#A32917',True)
text(d,90,950,r'INSPR-master\INSPR_Environment_Repair\Start-INSPR.cmd',27,'#A32917',mono=True)
text(d,90,996,'Move the repair contents up so the CMD and setup folders are at the same level.',25,MUTED)
text(d,64,1077,'Double-click the CMD once. Both toolboxes present? Both are repaired and tested.',26)
im.save(OUT/'extract-to-project.png',optimize=True)

im, d = canvas(1110)
header(d,2,'EVERYDAY USE','Run the main.m for the toolbox you want to use',
       'After the one-time repair: open MATLAB normally. Use a separate MATLAB process per toolbox.')
for top,title,setup,toolbox in [
    (244,'ASTIGMATISM','INSPR for astigmatism-based setup','INSPR astigmatism toolbox'),
    (536,'BIPLANE','INSPR for biplane setup','INSPR toolbox')]:
    box(d,(64,top,1336,top+252))
    text(d,90,top+22,title,26,BLUE,True)
    text(d,90,top+74,'Your existing project root',25,MUTED)
    folder(d,124,top+120)
    text(d,170,top+123,setup,26,mono=True)
    folder(d,164,top+178)
    text(d,210,top+181,toolbox,26,mono=True)
    box(d,(905,top+165,1306,top+227),fill='#E9F7EF',outline='#B7DCC8',radius=8)
    file_icon(d,928,top+180,GREEN)
    text(d,972,top+179,'main.m',31,GREEN,True,True)
    d.line((798,top+196,872,top+196),fill=GREEN,width=4)
    d.polygon([(872,top+186),(894,top+196),(872,top+206)],fill=GREEN)
box(d,(64,828,1336,1042),fill='#E9F7EF',outline='#B7DCC8')
text(d,90,850,'In MATLAB: open the chosen main.m and click Run.',32,GREEN,True)
text(d,90,905,'Or set Current Folder to its toolbox folder and type:  main',28)
text(d,90,957,'Run the whole script. It sets both the toolbox paths and the private DLL path.',26)
text(d,90,1002,'Keep deployment and runtime with the project. No need to rerun the CMD each time.',25)
text(d,64,1064,'Folder illustrations, not screenshots. Do not add both toolbox trees to one MATLAB session.',23,MUTED)
im.save(OUT/'run-main-in-matlab.png',optimize=True)
print('Rendered both toolbox paths to',OUT)

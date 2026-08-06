from PIL import Image, ImageDraw, ImageFont
import os, math

BG = (9, 10, 12)
GOLD = (215, 163, 90)
GOLD_LIGHT = (239, 191, 122)
GOLD_DARK = (180, 130, 60)
WHITE = (243, 239, 232)
BLUE = (80, 130, 210)
PURPLE = (120, 80, 170)
DARK_BLUE = (40, 60, 100)

def create_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = size / 100

    # RPG gold frame
    bw = max(2, int(3 * s))
    draw.rectangle([0, 0, size-1, size-1], fill=GOLD)
    draw.rectangle([bw, bw, size-1-bw, size-1-bw], fill=BG)

    # Inner gold line
    iw = max(1, int(1.5 * s))
    draw.rectangle([iw, iw, size-1-iw, size-1-iw], outline=GOLD_DARK, width=1)

    cx, cy = size/2, size/2 - 2*s

    # Gojo face - oval shape
    face_w, face_h = int(30*s), int(36*s)
    face_bbox = [cx-face_w, cy-face_h+int(8*s), cx+face_w, cy+face_h+int(8*s)]
    draw.ellipse(face_bbox, fill=(220, 200, 180))

    # Hair - dark blue messy spiky
    hair_color = DARK_BLUE
    for i in range(7):
        angle = math.radians(-80 + i * 25)
        spike_len = int((28 + (i%3)*8) * s)
        sx = cx + int(face_w * 0.8 * math.cos(angle))
        sy = cy - int(face_h * 0.6) + int(8*s) + int(face_h * 0.5 * math.sin(angle))
        ex = cx + int(spike_len * math.cos(angle - 0.3))
        ey = sy - int(spike_len * 0.6)
        draw.polygon([(sx, sy), (ex, ey), (sx + int(8*s), sy)], fill=hair_color)
    # Hair base
    draw.ellipse([cx-face_w-int(2*s), cy-face_h-int(2*s)+int(8*s), cx+face_w+int(2*s), cy-int(2*s)+int(8*s)], fill=hair_color)

    # Blindfold / eye area
    blind_y = cy + int(4*s)
    blind_h = int(10*s)
    draw.rectangle([cx-face_w+int(6*s), blind_y-blind_h, cx+face_w-int(6*s), blind_y+blind_h], fill=(30, 30, 40))

    # Left eye (partially visible)
    le_x, le_y = cx - int(14*s), blind_y
    draw.ellipse([le_x-int(8*s), le_y-int(6*s), le_x+int(8*s), le_y+int(6*s)], fill=WHITE)
    draw.ellipse([le_x-int(5*s), le_y-int(5*s), le_x+int(5*s), le_y+int(5*s)], fill=BLUE)
    draw.ellipse([le_x-int(2*s), le_y-int(2*s), le_x+int(2*s), le_y+int(2*s)], fill=PURPLE)
    draw.ellipse([le_x-int(1*s), le_y-int(1*s), le_x+int(1*s), le_y+int(1*s)], fill=GOLD)

    # Right eye (partially visible)
    re_x, re_y = cx + int(14*s), blind_y
    draw.ellipse([re_x-int(8*s), re_y-int(6*s), re_x+int(8*s), re_y+int(6*s)], fill=WHITE)
    draw.ellipse([re_x-int(5*s), re_y-int(5*s), re_x+int(5*s), re_y+int(5*s)], fill=BLUE)
    draw.ellipse([re_x-int(2*s), re_y-int(2*s), re_x+int(2*s), re_y+int(2*s)], fill=PURPLE)
    draw.ellipse([re_x-int(1*s), re_y-int(1*s), re_x+int(1*s), re_y+int(1*s)], fill=GOLD)

    # Nose
    draw.polygon([(cx, cy+int(10*s)), (cx-int(2*s), cy+int(16*s)), (cx+int(2*s), cy+int(16*s))], fill=(200, 180, 160))

    # Smile
    smile_y = cy + int(22*s)
    draw.arc([cx-int(10*s), smile_y-int(4*s), cx+int(10*s), smile_y+int(6*s)], 0, 180, fill=(180, 120, 120), width=max(1, int(1.5*s)))

    # RPG corner decorations
    cs = int(7*s)
    for pts in [
        [(0,0),(cs,0),(0,cs)],
        [(size,0),(size-cs,0),(size,cs)],
        [(0,size),(cs,size),(0,size-cs)],
        [(size,size),(size-cs,size),(size,size-cs)],
    ]:
        draw.polygon(pts, fill=GOLD_DARK)

    # "ANIMBOX" text
    try:
        font = ImageFont.truetype("arial.ttf", max(8, int(9*s)))
    except:
        font = ImageFont.load_default()
    text = "ANIMBOX"
    bbox = draw.textbbox((0,0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((cx-tw/2, size - int(14*s)), text, fill=GOLD, font=font)

    return img

android_sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
base_dir = r'C:\Users\fayshal\AnimoBox-Flutter\android\app\src\main\res'
for density, sz in android_sizes.items():
    icon = create_icon(sz)
    d = os.path.join(base_dir, f'mipmap-{density}')
    icon.save(os.path.join(d, 'ic_launcher.png'))
    icon.save(os.path.join(d, 'ic_launcher_round.png'))

web_dir = r'C:\Users\fayshal\AnimoBox-Flutter\web\icons'
os.makedirs(web_dir, exist_ok=True)
create_icon(192).save(os.path.join(web_dir, 'Icon-192.png'))
create_icon(192).save(os.path.join(web_dir, 'Icon-maskable-192.png'))
create_icon(512).save(os.path.join(web_dir, 'Icon-512.png'))
create_icon(512).save(os.path.join(web_dir, 'Icon-maskable-512.png'))
create_icon(32).save(r'C:\Users\fayshal\AnimoBox-Flutter\web\favicon.png')
try:
    wd = r'C:\Users\fayshal\AnimoBox-Flutter\windows\runner\resources'
    os.makedirs(wd, exist_ok=True)
    create_icon(256).save(os.path.join(wd, 'app_icon.ico'), format='ICO', sizes=[(256,256)])
except: pass
print('Done!')

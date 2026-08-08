from PIL import Image, ImageDraw, ImageFont
import os, math

BG = (9, 10, 12)
LIME = (120, 200, 80)
LIME_LIGHT = (160, 230, 110)
LIME_DARK = (80, 150, 50)
SUGAR = (255, 245, 230)
WHITE = (243, 239, 232)
GOLD = (215, 163, 90)

def create_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = size / 100

    # Lime green frame
    bw = max(2, int(3 * s))
    draw.rectangle([0, 0, size-1, size-1], fill=LIME)
    draw.rectangle([bw, bw, size-1-bw, size-1-bw], fill=BG)

    # Inner green line
    iw = max(1, int(1.5 * s))
    draw.rectangle([iw, iw, size-1-iw, size-1-iw], outline=LIME_DARK, width=1)

    cx, cy = size/2, size/2 - 4*s

    # Lime slice - circle
    lime_r = int(28 * s)
    draw.ellipse([cx-lime_r, cy-lime_r, cx+lime_r, cy+lime_r], fill=LIME)

    # Inner lime flesh
    flesh_r = int(22 * s)
    draw.ellipse([cx-flesh_r, cy-flesh_r, cx+flesh_r, cy+flesh_r], fill=LIME_LIGHT)

    # Lime segments (like a citrus slice)
    for i in range(6):
        angle = math.radians(i * 60)
        x1 = cx + int(flesh_r * 0.3 * math.cos(angle))
        y1 = cy + int(flesh_r * 0.3 * math.sin(angle))
        x2 = cx + int(flesh_r * 0.9 * math.cos(angle))
        y2 = cy + int(flesh_r * 0.9 * math.sin(angle))
        draw.line([(x1, y1), (x2, y2)], fill=SUGAR, width=max(1, int(1.5*s)))

    # Center dot
    dot_r = int(4 * s)
    draw.ellipse([cx-dot_r, cy-dot_r, cx+dot_r, cy+dot_r], fill=SUGAR)

    # Sugar crystals scattered
    import random
    random.seed(42)
    for _ in range(12):
        rx = cx + random.randint(-int(18*s), int(18*s))
        ry = cy + random.randint(-int(18*s), int(18*s))
        cr = random.randint(int(1*s), int(2*s))
        draw.ellipse([rx-cr, ry-cr, rx+cr, ry+cr], fill=(255, 255, 255, 180))

    # RPG corner decorations
    cs = int(7*s)
    for pts in [
        [(0,0),(cs,0),(0,cs)],
        [(size,0),(size-cs,0),(size,cs)],
        [(0,size),(cs,size),(0,size-cs)],
        [(size,size),(size-cs,size),(size,size-cs)],
    ]:
        draw.polygon(pts, fill=LIME_DARK)

    # "LIMESUGAR" text
    try:
        font = ImageFont.truetype("arial.ttf", max(7, int(8*s)))
    except:
        font = ImageFont.load_default()
    text = "LIMESUGAR"
    bbox = draw.textbbox((0,0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((cx-tw/2, size - int(14*s)), text, fill=LIME, font=font)

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

"""Recorta la lÃ¡mina de identidad visual en recursos individuales para la app."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops

src = Image.open(sys.argv[1]).convert('RGB')
root = Path(sys.argv[2])
A = root / 'assets'
for d in ['branding', 'icons/modules', 'crops', 'illustrations']:
    (A / d).mkdir(parents=True, exist_ok=True)

def rounded_mask(size, radius):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return m

def knockout(img, lo, hi, metric=min):
    """Fondo claro -> transparente segÃºn el canal mÃ­nimo (blanco/verde muy claro)."""
    img = img.convert('RGBA')
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, _ = px[x, y]
            m = metric((r, g, b))
            a = 255 if m <= lo else 0 if m >= hi else int(255 * (hi - m) / (hi - lo))
            px[x, y] = (r, g, b, a)
    bbox = img.getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
    return img.crop(bbox) if bbox else img

def pad_square(img, margin=0.0):
    side = int(max(img.size) * (1 + margin))
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - img.width) // 2, (side - img.height) // 2), img)
    return canvas

# 1) Icono de app (sin sombra ni bordes de la lÃ¡mina) con esquinas redondeadas.
icon = src.crop((58, 40, 372, 346)).resize((1024, 1024), Image.LANCZOS).convert('RGBA')
icon.putalpha(rounded_mask(icon.size, 220))
icon.resize((512, 512), Image.LANCZOS).save(A / 'branding/app_icon.png', optimize=True)

# Launcher Android (legacy) en todas las densidades.
res = root / 'android/app/src/main/res'
for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    icon.resize((px, px), Image.LANCZOS).save(res / f'mipmap-{folder}/ic_launcher.png', optimize=True)
    # Adaptive icon: arte dentro de la zona segura (66%) sobre lienzo de 108dp.
    fg_px = int(px * 108 / 48)
    art = src.crop((70, 52, 362, 336)).resize((int(fg_px * 0.70),) * 2, Image.LANCZOS).convert('RGBA')
    fg = Image.new('RGBA', (fg_px, fg_px), (0, 0, 0, 0))
    fg.paste(art, ((fg_px - art.width) // 2,) * 2)
    fg.save(res / f'mipmap-{folder}/ic_launcher_foreground.png', optimize=True)

# Splash nativo: icono centrado en lienzo 1152 (Android 12 recorta en cÃ­rculo de 768).
splash = Image.new('RGBA', (1152, 1152), (0, 0, 0, 0))
small = icon.resize((620, 620), Image.LANCZOS)
splash.paste(small, (266, 266), small)
splash.save(A / 'branding/splash_logo.png', optimize=True)

# 2) Logotipo con fondo transparente.
logo = knockout(src.crop((425, 38, 930, 335)), 175, 212, metric=lambda c: sum(c) / 3)
logo.save(A / 'branding/logo.png', optimize=True)

# 3) Iconos de mÃ³dulos (glifo sin el fondo verde claro de la baldosa).
names1 = ['inicio', 'recomendaciones', 'clima', 'historial', 'perfil', 'configuracion', 'seguridad', 'notificaciones']
names2 = ['mapa', 'estadisticas', 'cultivos', 'suelo', 'agua', 'buscar', 'favoritos', 'informacion']
xs = [99, 290, 480, 670, 859, 1047, 1238, 1426]
for names, (y0, y1) in [(names1, (397, 484)), (names2, (553, 642))]:
    for name, x in zip(names, xs):
        g = knockout(src.crop((x - 47, y0, x + 47, y1)), 165, 205)
        pad_square(g, 0.06).resize((144, 144), Image.LANCZOS).save(A / f'icons/modules/{name}.png', optimize=True)

# 4) Ilustraciones / banners (JPEG optimizado).
for name, box in {
    'banner_campo': (962, 36, 1508, 346),
    # Sólo la foto del agricultor (sin el texto incrustado del banner).
    'agricultor_campo': (968, 40, 1218, 346),
    'agricultura_inteligente': (24, 717, 387, 977),
    'paisaje_andino': (408, 717, 753, 977),
    'app_promo': (780, 719, 1193, 977),
}.items():
    src.crop(box).save(A / f'illustrations/{name}.jpg', quality=88, optimize=True)

# 5) Fotos de cultivos identificables con seguridad (el resto mantiene su ilustraciÃ³n SVG).
crops = {'papa': (0, 0), 'kiwicha': (1, 0), 'maiz': (2, 0), 'quinua': (1, 1), 'oca': (2, 1)}
for name, (c, r) in crops.items():
    x0 = [1217, 1319, 1421][c]; y0 = [783, 882][r]
    src.crop((x0, y0, x0 + 93, y0 + 93)).resize((192, 192), Image.LANCZOS).save(
        A / f'crops/{name}.jpg', quality=90, optimize=True)
print('ok')

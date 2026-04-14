"""Generate the CTT Finder app icon using the app's brand colours and fonts."""

from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
CORNER_RADIUS = 220  # rounded-rect radius for the icon shape

# Brand colours
RED_PRIMARY = (223, 0, 36)        # #DF0024
RED_DARK    = (176, 0, 28)        # #B0001C
WHITE       = (255, 255, 255)

FONT_DIR  = os.path.join(os.path.dirname(__file__), '..', 'assets', 'fonts')
BOLD_FONT = os.path.join(FONT_DIR, 'ActoCTT-Bold.ttf')
MED_FONT  = os.path.join(FONT_DIR, 'ActoCTT-Medium.ttf')

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
os.makedirs(OUT_DIR, exist_ok=True)


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    """Create an alpha mask with rounded corners."""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def draw_gradient(img: Image.Image, top_colour: tuple, bottom_colour: tuple):
    """Fill *img* with a vertical linear gradient."""
    draw = ImageDraw.Draw(img)
    w, h = img.size
    for y in range(h):
        ratio = y / h
        r = int(top_colour[0] + (bottom_colour[0] - top_colour[0]) * ratio)
        g = int(top_colour[1] + (bottom_colour[1] - top_colour[1]) * ratio)
        b = int(top_colour[2] + (bottom_colour[2] - top_colour[2]) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b))


def generate_icon():
    # -- base image with gradient ------------------------------------------------
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    gradient = Image.new('RGB', (SIZE, SIZE))
    draw_gradient(gradient, RED_PRIMARY, RED_DARK)

    # Apply rounded-corner mask
    mask = rounded_rect_mask(SIZE, CORNER_RADIUS)
    gradient_rgba = gradient.convert('RGBA')
    gradient_rgba.putalpha(mask)
    img = Image.alpha_composite(img, gradient_rgba)

    draw = ImageDraw.Draw(img)

    # -- Measure all elements to centre them vertically --------------------------
    ctt_font_size = 280
    ctt_font = ImageFont.truetype(BOLD_FONT, ctt_font_size)
    finder_font_size = 130
    finder_font = ImageFont.truetype(MED_FONT, finder_font_size)

    ctt_bbox = draw.textbbox((0, 0), 'CTT', font=ctt_font)
    ctt_w = ctt_bbox[2] - ctt_bbox[0]
    ctt_h = ctt_bbox[3] - ctt_bbox[1]

    finder_bbox = draw.textbbox((0, 0), 'Finder', font=finder_font)
    finder_w = finder_bbox[2] - finder_bbox[0]
    finder_h = finder_bbox[3] - finder_bbox[1]

    env_h_total = 140
    gap_env_ctt = 30
    gap_ctt_finder = 5
    total_h = env_h_total + gap_env_ctt + ctt_h + gap_ctt_finder + finder_h
    top_y = (SIZE - total_h) // 2

    # -- postal icon (envelope) --------------------------------------------------
    env_w, env_body_h = 190, 120
    env_x = (SIZE - env_w) // 2
    env_y = top_y

    draw.rounded_rectangle(
        [env_x, env_y + 20, env_x + env_w, env_y + env_body_h + 20],
        radius=18,
        fill=WHITE,
    )
    draw.polygon(
        [
            (env_x + 4, env_y + 32),
            (env_x + env_w // 2, env_y + env_body_h // 2 + 25),
            (env_x + env_w - 4, env_y + 32),
            (env_x + env_w // 2, env_y + 12),
        ],
        fill=WHITE,
    )

    # -- "CTT" text --------------------------------------------------------------
    ctt_x = (SIZE - ctt_w) // 2 - ctt_bbox[0]
    ctt_y = top_y + env_h_total + gap_env_ctt - ctt_bbox[1]
    draw.text((ctt_x, ctt_y), 'CTT', fill=WHITE, font=ctt_font)

    # -- "Finder" text -----------------------------------------------------------
    finder_x = (SIZE - finder_w) // 2 - finder_bbox[0]
    finder_y = top_y + env_h_total + gap_env_ctt + ctt_h + gap_ctt_finder - finder_bbox[1]
    draw.text((finder_x, finder_y), 'Finder', fill=WHITE, font=finder_font)

    # -- save at multiple resolutions -------------------------------------------
    # 1024 master
    master_path = os.path.join(OUT_DIR, 'app_icon_1024.png')
    img.save(master_path, 'PNG')
    print(f'  Saved {master_path}')

    for target_size in [512, 192, 144, 96, 72, 48]:
        resized = img.resize((target_size, target_size), Image.LANCZOS)
        path = os.path.join(OUT_DIR, f'app_icon_{target_size}.png')
        resized.save(path, 'PNG')
        print(f'  Saved {path}')

    return master_path


if __name__ == '__main__':
    print('Generating CTT Finder icon...')
    p = generate_icon()
    print(f'Done!  Master icon: {p}')

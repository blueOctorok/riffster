"""Turns the icon artwork into every brand file the app and the site use.

There are two drawings of the same dog. The detailed one is the brand mark.
The simple one has the same outline with solid eyes and nose, and stands in
where the icon is too small for fine lines to survive.

Run it from the project root after the artwork changes. It needs Pillow:

    python -m pip install --target build/pytools pillow
    PYTHONPATH=build/pytools python tool/brand/make_brand.py
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
DETAILED_ARTWORK = Path(__file__).with_name("riffster-icon-source.jpg")
SIMPLE_ARTWORK = Path(__file__).with_name("riffster-icon-source-small.jpg")

# The artwork's own dark brown. Everything that differs from it is the drawing.
TILE = (47, 30, 20)

# How far a pixel sits from the tile color: below NOISE it is tile (the JPEG
# is never perfectly flat), and from SOLID up it is fully drawing.
NOISE, SOLID = 8, 150

# The artwork is a rounded tile on white. Only what lies inside this inset
# shape is read, which leaves the white corners out.
SAFE_INSET, SAFE_RADIUS = 40, 190

# Each icon is drawn at four times its size and then shrunk, which is what
# smooths its edges.
OVERSIZE = 4

ICON_SIZES = [16, 24, 32, 48, 64, 256]
FAVICON_SIZES = [16, 32, 48]


def cut_out_mark(artwork: Path) -> Image.Image:
    """The dog alone: gold lines and tongue on a see-through background."""
    art = Image.open(artwork).convert("RGB")
    tile = Image.new("RGB", art.size, TILE)

    # A pixel's opacity is its largest difference from the tile in any channel.
    red, green, blue = ImageChops.difference(art, tile).split()
    distance = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    alpha = distance.point(
        lambda d: max(0, min(255, (d - NOISE) * 255 // (SOLID - NOISE)))
    )

    safe = Image.new("L", art.size, 0)
    ImageDraw.Draw(safe).rounded_rectangle(
        (SAFE_INSET, SAFE_INSET, art.width - SAFE_INSET, art.height - SAFE_INSET),
        radius=SAFE_RADIUS,
        fill=255,
    )
    alpha = ImageChops.multiply(alpha, safe)

    # An edge pixel is the line's color mixed with the tile's. Taking the
    # tile's share back out leaves color-times-opacity, which is exactly what
    # Pillow's "RGBa" mode stores, so converting to "RGBA" finishes the sum.
    # Without this the lines would carry a brown fringe onto other backgrounds.
    see_through = Image.merge("RGB", [ImageChops.invert(alpha)] * 3)
    tile_share = ImageChops.multiply(tile, see_through)
    color_times_alpha = ImageChops.subtract(art, tile_share)
    mark = Image.merge("RGBa", (*color_times_alpha.split(), alpha)).convert("RGBA")

    mark = mark.crop(mark.getbbox())
    side = max(mark.size)
    square = Image.new("RGBA", (side, side))
    square.paste(mark, ((side - mark.width) // 2, (side - mark.height) // 2))
    return square


def icon(detailed: Image.Image, simple: Image.Image, size: int) -> Image.Image:
    """The dog on its rounded tile, at one size.

    The smaller the icon, the simpler the drawing, the thicker its lines,
    and the more of the tile it fills. A line that is right at 256 pixels
    would be a fifth of a pixel wide at 16 and wash out.
    """
    if size >= 128:
        mark, thickening, fill = detailed, 0, 0.80
    elif size >= 48:
        mark, thickening, fill = detailed, 3, 0.84
    elif size >= 24:
        mark, thickening, fill = simple, 5, 0.90
    else:
        mark, thickening, fill = simple, 3, 0.94

    big = size * OVERSIZE
    picture = Image.new("RGB", (big, big), TILE)
    width = round(big * fill)
    dog = mark.resize((width, width), Image.Resampling.LANCZOS)
    picture.paste(dog, ((big - width) // 2,) * 2, dog)
    if thickening:
        # Each pixel takes the brightest value near it. The drawing is
        # brighter than the tile everywhere, so this widens every line.
        picture = picture.filter(ImageFilter.MaxFilter(thickening))

    rounded_corners = Image.new("L", (big, big), 0)
    ImageDraw.Draw(rounded_corners).rounded_rectangle(
        (0, 0, big - 1, big - 1), radius=big * 0.2, fill=255
    )
    picture.putalpha(rounded_corners)
    return picture.resize((size, size), Image.Resampling.LANCZOS)


def save_ico(icons: dict[int, Image.Image], path: Path, sizes: list[int]) -> None:
    largest, *smaller = [icons[size] for size in sorted(sizes, reverse=True)]
    largest.save(
        path,
        sizes=[(size, size) for size in sizes],
        # Pillow would shrink the largest one for each size. These replace
        # its shrunken copies with the ones drawn for that size.
        append_images=smaller,
    )


def save_preview(icons: dict[int, Image.Image], path: Path) -> None:
    """Every size at its real size and blown up, on a dark and a light bar."""
    cell, real_size_row = 276, 80
    sheet = Image.new("RGB", (len(icons) * cell, 2 * (cell + real_size_row)), (32, 32, 32))
    half = sheet.height // 2
    ImageDraw.Draw(sheet).rectangle((0, half, sheet.width, sheet.height), fill=(235, 235, 235))
    for column, image in enumerate(icons.values()):
        blown_up = image.resize((256, 256), Image.Resampling.NEAREST)
        real_size = image if image.width <= 64 else image.resize((64, 64))
        for top in (0, half):
            sheet.paste(real_size, (column * cell + 10, top + 8), real_size)
            sheet.paste(blown_up, (column * cell + 10, top + real_size_row + 10), blown_up)
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


if __name__ == "__main__":
    detailed = cut_out_mark(DETAILED_ARTWORK)
    simple = cut_out_mark(SIMPLE_ARTWORK)

    # The bare mark, for sitting beside the name in the app and on the site.
    bare_mark = detailed.resize((256, 256), Image.Resampling.LANCZOS)
    for folder in ("assets/brand", "riffster-site/public/brand"):
        (ROOT / folder).mkdir(parents=True, exist_ok=True)
        bare_mark.save(ROOT / folder / "riffster-mark.png", optimize=True)

    icons = {size: icon(detailed, simple, size) for size in ICON_SIZES}
    save_ico(icons, ROOT / "windows/runner/resources/app_icon.ico", ICON_SIZES)
    save_ico(icons, ROOT / "riffster-site/src/app/favicon.ico", FAVICON_SIZES)
    save_preview(icons, ROOT / "build/icon/preview.png")

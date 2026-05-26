#!/usr/bin/env python3
"""Upgrade Phase 0 temporary assets with a stronger pixel-art style.

This pass keeps every manifest id/path stable so Godot references survive, but
redraws the temporary art with chunkier silhouettes, top-left lighting, material
facets, rim highlights, cast shadows, and a pseudo-voxel 3/4 read.
"""

from __future__ import annotations

import json
import math
import subprocess
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / "SourceCode"
ASSET_ROOT = SOURCE / "assets" / "temp_pixel"
RAW_ROOT = ASSET_ROOT / "_raw"
MANIFEST_PATH = SOURCE / "data" / "assets" / "temp_asset_manifest.json"
FORGE_SCRIPT = PROJECT / "agent-sprite-forge" / "skills" / "generate2dsprite" / "scripts" / "generate2dsprite.py"

MAGENTA = (255, 0, 255, 255)
TRANSPARENT = (0, 0, 0, 0)
OUTLINE = (13, 16, 19, 255)
INK = (25, 29, 32, 255)
WARM = (222, 146, 70, 255)
COLD = (91, 137, 153, 255)
VOID = (83, 49, 103, 255)
GREEN = (65, 145, 99, 255)


PALETTES: dict[str, dict[str, tuple[int, int, int, int]]] = {
    "protagonist": {"cloth": (76, 83, 86, 255), "armor": (151, 160, 158, 255), "skin": (188, 145, 108, 255), "accent": (169, 55, 48, 255), "hair": (48, 42, 38, 255)},
    "rowan": {"cloth": (126, 54, 45, 255), "armor": (180, 99, 64, 255), "skin": (178, 122, 91, 255), "accent": (224, 74, 42, 255), "hair": (62, 42, 33, 255)},
    "sera": {"cloth": (35, 60, 66, 255), "armor": (80, 136, 139, 255), "skin": (173, 125, 101, 255), "accent": (57, 195, 172, 255), "hair": (24, 30, 36, 255)},
    "eldric": {"cloth": (73, 88, 100, 255), "armor": (164, 175, 169, 255), "skin": (172, 127, 99, 255), "accent": (74, 126, 171, 255), "hair": (196, 191, 165, 255)},
    "bram": {"cloth": (107, 72, 43, 255), "armor": (190, 117, 48, 255), "skin": (194, 139, 98, 255), "accent": (225, 91, 45, 255), "hair": (80, 52, 34, 255)},
    "maren": {"cloth": (88, 98, 90, 255), "armor": (177, 162, 118, 255), "skin": (167, 127, 95, 255), "accent": (214, 165, 76, 255), "hair": (72, 74, 70, 255)},
    "tor": {"cloth": (87, 73, 58, 255), "armor": (147, 139, 116, 255), "skin": (162, 119, 86, 255), "accent": (101, 157, 174, 255), "hair": (49, 39, 35, 255)},
    "lina": {"cloth": (52, 102, 64, 255), "armor": (121, 163, 88, 255), "skin": (181, 133, 97, 255), "accent": (165, 213, 81, 255), "hair": (55, 50, 38, 255)},
    "noa": {"cloth": (50, 58, 114, 255), "armor": (119, 131, 190, 255), "skin": (176, 130, 100, 255), "accent": (225, 207, 108, 255), "hair": (34, 31, 55, 255)},
    "isol": {"cloth": (144, 140, 127, 255), "armor": (219, 210, 176, 255), "skin": (188, 142, 104, 255), "accent": (221, 176, 78, 255), "hair": (222, 217, 194, 255)},
    "kyle": {"cloth": (67, 93, 64, 255), "armor": (156, 137, 68, 255), "skin": (177, 128, 92, 255), "accent": (231, 178, 53, 255), "hair": (44, 40, 32, 255)},
    "enemy": {"cloth": (84, 96, 89, 255), "armor": (135, 152, 128, 255), "skin": (146, 166, 134, 255), "accent": (99, 50, 120, 255), "hair": (42, 48, 45, 255)},
    "boss": {"cloth": (90, 66, 91, 255), "armor": (141, 103, 131, 255), "skin": (154, 116, 139, 255), "accent": (70, 167, 111, 255), "hair": (34, 27, 39, 255)},
}


def clamp(v: int) -> int:
    return max(0, min(255, v))


def shade(color: tuple[int, int, int, int], amount: int) -> tuple[int, int, int, int]:
    return (clamp(color[0] + amount), clamp(color[1] + amount), clamp(color[2] + amount), color[3])


def path_from_res(res_path: str) -> Path:
    return SOURCE / res_path.removeprefix("res://")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def px_rect(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], fill: tuple[int, int, int, int]) -> None:
    draw.rectangle(xy, fill=fill)


def px_poly(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], fill: tuple[int, int, int, int]) -> None:
    draw.polygon(pts, fill=fill)


def px_line(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], fill: tuple[int, int, int, int], width: int = 1) -> None:
    draw.line(pts, fill=fill, width=width)


def px_ellipse(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], fill: tuple[int, int, int, int]) -> None:
    draw.ellipse(xy, fill=fill)


def upscale(img: Image.Image, scale: int) -> Image.Image:
    return img.resize((img.width * scale, img.height * scale), Image.Resampling.NEAREST)


def dither(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int, int], step: int = 4) -> None:
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1, step):
        for x in range(x0 + ((y // step) % 2) * 2, x1 + 1, step):
            px_rect(draw, (x, y, x + 1, y + 1), color)


def draw_shadow(draw: ImageDraw.ImageDraw, cx: int, cy: int, rx: int, ry: int) -> None:
    px_ellipse(draw, (cx - rx, cy - ry, cx + rx, cy + ry), (7, 9, 11, 115))


def draw_token(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, accent: tuple[int, int, int, int], blackened: bool = False) -> None:
    px_rect(draw, (x, y, x + w, y + h), OUTLINE)
    px_rect(draw, (x + 2, y + 1, x + w - 1, y + h - 2), (111, 119, 112, 255))
    px_rect(draw, (x + 4, y + 3, x + w - 3, y + h - 4), (63, 69, 66, 255))
    px_rect(draw, (x + 5, y + 4, x + w - 4, y + 5), shade((111, 119, 112, 255), 42))
    mark = (28, 25, 29, 255) if blackened else accent
    px_ellipse(draw, (x + w // 2 - 4, y + h // 2 - 5, x + w // 2 + 4, y + h // 2 + 3), mark)
    px_line(draw, [(x + w // 2, y + h // 2 - 5), (x + w // 2 - 3, y + h // 2 + 7)], shade(mark, -25), 1)


def palette_key(asset_id: str) -> str:
    for key in ("rowan", "sera", "eldric", "bram", "maren", "tor", "lina", "noa", "isol", "kyle"):
        if key in asset_id:
            return key
    if "boss" in asset_id or "elite" in asset_id or "midboss" in asset_id:
        return "boss"
    if "enemy" in asset_id:
        return "enemy"
    return "protagonist"


def weapon_for(asset_id: str) -> str:
    if "rowan" in asset_id:
        return "spear"
    if "sera" in asset_id:
        return "daggers"
    if "eldric" in asset_id or "guard" in asset_id or "block" in asset_id:
        return "shield"
    if any(k in asset_id for k in ("maren", "lina", "isol", "scholar")):
        return "staff"
    if any(k in asset_id for k in ("noa", "kyle", "merchant")):
        return "book"
    return "sword"


def draw_pixel_humanoid(
    draw: ImageDraw.ImageDraw,
    asset_id: str,
    frame: int,
    action: str,
    big: bool = False,
    corrupted: bool = False,
) -> None:
    key = palette_key(asset_id)
    pal = PALETTES[key]
    bob = [0, -1, 0, 1][frame % 4]
    attack = action == "attack"
    guard = action == "guard"
    hurt = action == "hurt"
    s = 1 if not big else 2
    cx = 32
    top = 12 - (5 if big else 0) + bob
    draw_shadow(draw, cx, 55, 20 + 6 * big, 5)

    cloth = pal["cloth"]
    armor = pal["armor"]
    skin = pal["skin"]
    accent = pal["accent"]
    hair = pal["hair"]
    if corrupted:
        skin = shade(PALETTES["enemy"]["skin"], -10)
        accent = VOID
        cloth = shade(PALETTES["enemy"]["cloth"], -8)
    if hurt:
        accent = (219, 66, 60, 255)

    # Back cape and outline mass.
    px_poly(draw, [(22, top + 18), (39, top + 16), (46, top + 47), (18, top + 49)], OUTLINE)
    px_poly(draw, [(24, top + 19), (38, top + 18), (43, top + 46), (20, top + 47)], shade(cloth, -18))
    dither(draw, (21, top + 26, 42, top + 47), shade(cloth, -42), 5)

    # Legs and boots.
    for lx in (25, 37):
        px_rect(draw, (lx - s, top + 40, lx + 6 + s, top + 55), OUTLINE)
        px_rect(draw, (lx, top + 40, lx + 4 + s, top + 52), shade(cloth, -4))
        px_rect(draw, (lx - 2, top + 53, lx + 8 + s, top + 57), OUTLINE)
        px_rect(draw, (lx, top + 53, lx + 7 + s, top + 55), shade(hair, -5))

    # Torso as a tiny block with top/side planes.
    px_rect(draw, (22 - s, top + 23, 43 + s, top + 43), OUTLINE)
    px_rect(draw, (24 - s, top + 24, 42 + s, top + 42), cloth)
    px_poly(draw, [(24 - s, top + 24), (42 + s, top + 24), (39 + s, top + 28), (26 - s, top + 28)], shade(armor, 18))
    px_rect(draw, (38, top + 27, 42 + s, top + 41), shade(cloth, -35))
    px_rect(draw, (26, top + 26, 29, top + 39), shade(armor, 25))
    px_rect(draw, (31, top + 24, 33, top + 42), OUTLINE)
    px_rect(draw, (30, top + 25, 33, top + 40), shade(accent, -10))

    # Head, hair/helmet, face highlight.
    px_rect(draw, (24 - s, top + 9, 42 + s, top + 23), OUTLINE)
    px_rect(draw, (27 - s, top + 11, 42 + s, top + 22), skin)
    px_rect(draw, (24 - s, top + 8, 42 + s, top + 14), hair)
    px_rect(draw, (27, top + 11, 31, top + 12), shade(skin, 36))
    px_rect(draw, (36, top + 16, 38, top + 18), INK)
    if key in {"eldric", "protagonist"}:
        px_rect(draw, (23 - s, top + 8, 43 + s, top + 12), shade(armor, 8))
        px_rect(draw, (28, top + 6, 37, top + 8), shade(armor, 36))
    if key == "sera":
        px_poly(draw, [(24, top + 8), (44, top + 12), (39, top + 24), (24, top + 21)], shade(cloth, -25))

    # Arms.
    left_arm = [(21, top + 27), (15, top + 40)] if not attack else [(21, top + 27), (10, top + 34)]
    right_arm = [(43, top + 27), (50, top + 39)] if not attack else [(43, top + 27), (57, top + 30)]
    px_line(draw, left_arm, OUTLINE, 3)
    px_line(draw, right_arm, OUTLINE, 3)
    px_line(draw, left_arm, shade(armor, -2), 1)
    px_line(draw, right_arm, shade(armor, -2), 1)

    weapon = weapon_for(asset_id)
    reach = [0, 3, 7, 2][frame % 4] if attack else 0
    if weapon == "spear":
        px_line(draw, [(47, top + 18), (57 + reach, top + 54)], OUTLINE, 3)
        px_line(draw, [(48, top + 18), (58 + reach, top + 53)], shade(accent, 15), 1)
        px_poly(draw, [(57 + reach, top + 53), (63 + reach, top + 61), (55 + reach, top + 60)], shade(armor, 36))
    elif weapon == "daggers":
        px_line(draw, [(16, top + 38), (8 - reach, top + 43)], shade(armor, 45), 2)
        px_line(draw, [(50, top + 37), (59 + reach, top + 43)], shade(armor, 45), 2)
        px_rect(draw, (7 - reach, top + 42, 10 - reach, top + 44), accent)
        px_rect(draw, (58 + reach, top + 42, 61 + reach, top + 44), accent)
    elif weapon == "shield":
        px_poly(draw, [(14, top + 27), (25, top + 31), (23, top + 45), (15, top + 50), (9, top + 43), (9, top + 31)], OUTLINE)
        px_poly(draw, [(15, top + 29), (23, top + 32), (21, top + 43), (15, top + 47), (11, top + 42), (11, top + 32)], shade(accent, -2))
        px_rect(draw, (16, top + 31, 18, top + 45), shade(accent, 36))
        px_line(draw, [(47, top + 27), (54, top + 49)], shade(armor, 34), 2)
    elif weapon == "staff":
        px_line(draw, [(50, top + 15), (53, top + 55)], OUTLINE, 3)
        px_line(draw, [(51, top + 16), (52, top + 54)], shade(armor, 25), 1)
        px_ellipse(draw, (47, top + 10, 56, top + 19), accent)
        px_rect(draw, (50, top + 12, 53, top + 15), shade(accent, 50))
    elif weapon == "book":
        px_rect(draw, (46, top + 29, 58, top + 39), OUTLINE)
        px_rect(draw, (48, top + 31, 56, top + 37), shade(accent, -5))
        px_line(draw, [(52, top + 31), (52, top + 37)], shade(accent, 42), 1)
    else:
        px_line(draw, [(47, top + 23), (56 + reach, top + 43)], OUTLINE, 3)
        px_line(draw, [(48, top + 23), (57 + reach, top + 42)], shade(armor, 42), 1)
        px_rect(draw, (51 + reach, top + 29, 54 + reach, top + 32), accent)

    if guard:
        px_poly(draw, [(17, top + 24), (33, top + 29), (30, top + 51), (18, top + 57), (9, top + 49), (9, top + 30)], OUTLINE)
        px_poly(draw, [(18, top + 27), (31, top + 31), (28, top + 48), (18, top + 53), (12, top + 47), (12, top + 32)], shade(accent, 3))
        px_rect(draw, (19, top + 31, 22, top + 49), shade(accent, 40))

    if corrupted:
        for off in (0, 8, 15):
            px_line(draw, [(41 + off // 3, top + 29 + off), (51 + off // 2, top + 33 + off)], VOID, 2)
        px_rect(draw, (28, top + 18, 31, top + 20), GREEN)


def draw_pixel_creature(draw: ImageDraw.ImageDraw, asset_id: str, frame: int, hurt: bool = False) -> None:
    bob = [0, -1, 0, 1][frame % 4]
    top = 18 + bob
    pal = PALETTES["enemy"]
    accent = (210, 58, 56, 255) if hurt else pal["accent"]
    draw_shadow(draw, 34, 56, 22, 5)
    if "wolf" in asset_id or "packhorse" in asset_id:
        long = "packhorse" in asset_id
        px_rect(draw, (13, top + 22, 49 + (5 if long else 0), top + 39), OUTLINE)
        px_rect(draw, (16, top + 24, 47 + (5 if long else 0), top + 36), pal["cloth"])
        px_poly(draw, [(16, top + 24), (48, top + 24), (43, top + 28), (19, top + 28)], shade(pal["armor"], 18))
        px_rect(draw, (50, top + 16, 61, top + 29), OUTLINE)
        px_rect(draw, (52, top + 18, 60, top + 27), shade(pal["skin"], 10))
        if "wolf" in asset_id:
            px_poly(draw, [(52, top + 17), (56, top + 8), (59, top + 18)], OUTLINE)
            px_poly(draw, [(59, top + 18), (63, top + 22), (59, top + 25)], OUTLINE)
        else:
            px_rect(draw, (58, top + 20, 64, top + 24), OUTLINE)
            px_rect(draw, (11, top + 18, 17, top + 24), accent)
        for lx in (18, 29, 43, 54):
            px_rect(draw, (lx, top + 36, lx + 4, top + 53), OUTLINE)
            px_rect(draw, (lx + 1, top + 37, lx + 3, top + 50), shade(pal["cloth"], -10))
        px_line(draw, [(13, top + 25), (5, top + 18)], accent, 2)
        dither(draw, (20, top + 27, 48, top + 36), VOID, 6)
    elif "rooted" in asset_id:
        px_rect(draw, (24, top + 10, 42, top + 44), OUTLINE)
        px_rect(draw, (27, top + 13, 40, top + 42), (78, 93, 69, 255))
        px_poly(draw, [(27, top + 13), (40, top + 13), (37, top + 18), (29, top + 18)], shade((78, 93, 69, 255), 35))
        for off in (-17, -9, 8, 16):
            px_line(draw, [(33, top + 39), (33 + off, top + 56)], OUTLINE, 3)
            px_line(draw, [(33, top + 39), (33 + off, top + 55)], accent, 1)
        px_line(draw, [(27, top + 20), (10, top + 8)], shade(pal["armor"], 24), 2)
        px_line(draw, [(40, top + 22), (56, top + 8)], shade(pal["armor"], 24), 2)
        px_rect(draw, (30, top + 23, 34, top + 25), GREEN)
    else:
        draw_pixel_humanoid(draw, asset_id, frame, "hurt" if hurt else "idle", corrupted=True)


def draw_pixel_boss(draw: ImageDraw.ImageDraw, asset_id: str, frame: int, hurt: bool = False) -> None:
    pal = PALETTES["boss"]
    bob = [0, -1, 0, 1][frame % 4]
    top = 4 + bob
    draw_shadow(draw, 34, 57, 28, 6)
    px_poly(draw, [(17, top + 24), (48, top + 20), (56, top + 51), (13, top + 56)], OUTLINE)
    px_poly(draw, [(20, top + 25), (46, top + 23), (52, top + 49), (16, top + 53)], pal["cloth"])
    px_poly(draw, [(20, top + 25), (46, top + 23), (41, top + 29), (23, top + 31)], shade(pal["armor"], 26))
    px_rect(draw, (28, top + 8, 45, top + 24), OUTLINE)
    px_rect(draw, (31, top + 10, 43, top + 23), pal["skin"])
    px_rect(draw, (27, top + 6, 46, top + 12), pal["hair"])
    px_rect(draw, (35, top + 16, 39, top + 18), GREEN if not hurt else (230, 58, 52, 255))
    px_line(draw, [(18, top + 31), (6, top + 46)], VOID, 4)
    px_line(draw, [(50, top + 30), (61, top + 47)], VOID, 4)
    if "warlord" in asset_id:
        px_line(draw, [(50, top + 13), (64, top + 54)], OUTLINE, 4)
        px_line(draw, [(51, top + 13), (63, top + 53)], shade(pal["armor"], 44), 2)
        px_rect(draw, (29, top + 3, 44, top + 6), shade(pal["accent"], 14))
    if "guard" in asset_id or "captain" in asset_id:
        px_poly(draw, [(10, top + 26), (28, top + 31), (24, top + 52), (10, top + 57), (3, top + 47), (4, top + 31)], OUTLINE)
        px_poly(draw, [(11, top + 29), (26, top + 33), (22, top + 49), (11, top + 53), (6, top + 46), (7, top + 33)], shade(pal["accent"], -4))
    if "scholar" in asset_id:
        for i in range(3):
            px_line(draw, [(48, top + 22 + i * 4), (63, top + 13 + i * 3)], GREEN, 1)
    if "caravan" in asset_id:
        px_rect(draw, (16, top + 48, 52, top + 56), shade(pal["armor"], 22))
    dither(draw, (19, top + 30, 52, top + 51), shade(VOID, -18), 5)


def make_sprite_sheet(asset: dict[str, Any]) -> None:
    asset_id = asset["id"]
    rows = int(asset.get("rows", 2))
    cols = int(asset.get("cols", 2))
    cell = int(asset.get("frame_size", [128, 128])[0])
    low_cell = cell // 2
    raw_low = Image.new("RGBA", (cols * low_cell, rows * low_cell), MAGENTA)
    action = "idle"
    if asset["category"] == "fx":
        action = "fx"
    elif asset_id.endswith("_hurt"):
        action = "hurt"
    elif asset_id.endswith("_attack"):
        action = "attack"
    elif asset_id.endswith("_guard"):
        action = "guard"

    for frame in range(rows * cols):
        cell_img = Image.new("RGBA", (low_cell, low_cell), MAGENTA)
        d = ImageDraw.Draw(cell_img)
        if asset["category"] == "fx":
            draw_fx_cell(d, asset_id, frame, low_cell)
        elif asset["category"] == "enemies":
            draw_pixel_creature(d, asset_id, frame, hurt=action == "hurt")
        elif asset["category"] == "bosses":
            draw_pixel_boss(d, asset_id, frame, hurt=action == "hurt")
        else:
            draw_pixel_humanoid(d, asset_id, frame, action)
        raw_low.alpha_composite(cell_img, ((frame % cols) * low_cell, (frame // cols) * low_cell))

    raw = upscale(raw_low, 2)
    raw_path = RAW_ROOT / f"{asset_id}_raw.png"
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    raw.save(raw_path)
    prompt = (
        f"Phase0 v2 temporary pixel art for {asset_id}. Pseudo-voxel 3/4 tactical fantasy, "
        "chunky readable silhouette, cold blue-gray world palette with warm fire accents, "
        "top-left light, rim highlights, black outline, solid #FF00FF raw background."
    )
    write_text(raw_path.with_suffix(raw_path.suffix + ".prompt.txt"), prompt)
    out_dir = path_from_res(asset["path"]).parent
    subprocess.run(
        [
            "python3",
            str(FORGE_SCRIPT),
            "process",
            "--input",
            str(raw_path),
            "--target",
            "asset" if asset["category"] == "fx" else "npc",
            "--mode",
            "fx" if asset["category"] == "fx" else ("attack" if action in {"attack", "guard"} else ("hurt" if action == "hurt" else "idle")),
            "--output-dir",
            str(out_dir),
            "--rows",
            str(rows),
            "--cols",
            str(cols),
            "--cell-size",
            str(cell),
            "--align",
            "center" if asset["category"] == "fx" else "bottom",
            "--shared-scale",
            "--component-mode",
            "all",
            "--prompt",
            prompt,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def draw_fx_cell(draw: ImageDraw.ImageDraw, asset_id: str, frame: int, cell: int) -> None:
    cx = cy = cell // 2
    radius = 7 + frame * 4
    if "slash" in asset_id or "pierce" in asset_id:
        color = (236, 222, 175, 255) if "slash" in asset_id else (226, 65, 58, 255)
        px_line(draw, [(15 - frame, 46), (49 + frame, 16)], OUTLINE, 5)
        px_line(draw, [(16 - frame, 45), (48 + frame, 17)], color, 3)
        px_line(draw, [(22, 45), (48, 24)], shade(color, 45), 1)
    elif "poison" in asset_id:
        for i in range(4):
            px_ellipse(draw, (cx - radius + i * 5, cy - radius // 2 - i * 3, cx - radius + 10 + i * 5, cy + radius // 2), (71, 166, 82, 160))
        px_rect(draw, (cx - 2, cy - 2, cx + 2, cy + 2), shade(GREEN, 44))
    elif "heal" in asset_id and "down" not in asset_id:
        px_ellipse(draw, (cx - radius, cy - radius, cx + radius, cy + radius), (226, 207, 151, 150))
        px_rect(draw, (cx - 2, cy - radius - 3, cx + 2, cy + radius + 3), (239, 228, 181, 255))
        px_rect(draw, (cx - radius - 3, cy - 2, cx + radius + 3, cy + 2), (239, 228, 181, 255))
    elif "gold" in asset_id or "glint" in asset_id:
        px_poly(draw, [(cx, cy - radius - 3), (cx + 4, cy - 3), (cx + radius + 4, cy), (cx + 4, cy + 3), (cx, cy + radius + 3), (cx - 4, cy + 3), (cx - radius - 4, cy), (cx - 4, cy - 3)], (232, 181, 66, 255))
        px_rect(draw, (cx - 2, cy - 2, cx + 2, cy + 2), (255, 238, 151, 255))
    else:
        col = GREEN if "guard" in asset_id or "mark" in asset_id else VOID
        px_ellipse(draw, (cx - radius, cy - radius, cx + radius, cy + radius), (*col[:3], 145))
        px_line(draw, [(cx, cy - radius - 2), (cx, cy + radius + 2)], shade(col, 40), 2)
        px_line(draw, [(cx - radius - 2, cy), (cx + radius + 2, cy)], shade(col, 40), 2)


def make_portrait(asset: dict[str, Any]) -> None:
    out = path_from_res(asset["path"])
    prompt = path_from_res(asset["prompt_path"])
    key = palette_key(asset["id"])
    pal = PALETTES[key]
    low = Image.new("RGBA", (48, 48), TRANSPARENT)
    d = ImageDraw.Draw(low)
    px_rect(d, (2, 2, 45, 45), OUTLINE)
    px_rect(d, (4, 4, 43, 43), (37, 48, 52, 255))
    px_rect(d, (4, 31, 43, 43), (47, 43, 39, 255))
    dither(d, (5, 5, 42, 42), (24, 28, 31, 255), 6)
    px_rect(d, (18, 14, 31, 27), OUTLINE)
    px_rect(d, (20, 15, 31, 26), pal["skin"])
    px_rect(d, (18, 12, 32, 17), pal["hair"])
    px_rect(d, (14, 27, 35, 41), OUTLINE)
    px_rect(d, (16, 27, 33, 39), pal["cloth"])
    px_poly(d, [(16, 27), (33, 27), (30, 31), (18, 31)], shade(pal["armor"], 18))
    px_rect(d, (18, 29, 20, 39), shade(pal["armor"], 32))
    px_rect(d, (26, 21, 28, 23), INK)
    draw_token(d, 33, 30, 9, 12, pal["accent"], blackened="kyle" in asset["id"])
    weapon = weapon_for(asset["id"])
    if weapon in {"sword", "spear", "staff"}:
        px_line(d, [(35, 14), (42, 39)], shade(pal["armor"], 40), 1)
    elif weapon == "daggers":
        px_line(d, [(12, 29), (7, 35)], shade(pal["armor"], 45), 1)
        px_line(d, [(35, 29), (42, 35)], shade(pal["armor"], 45), 1)
    elif weapon == "shield":
        px_poly(d, [(9, 25), (17, 27), (15, 39), (9, 42), (5, 38), (5, 28)], pal["accent"])
    img = upscale(low, 2)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    write_text(prompt, f"Phase0 v2 pseudo-voxel pixel portrait for {asset['id']}, readable 96px bust, metal oath token detail.")


def make_icon(asset: dict[str, Any]) -> None:
    if asset["category"] == "equipment":
        make_equipment_icon(asset)
        return
    out = path_from_res(asset["path"])
    prompt = path_from_res(asset["prompt_path"])
    low = Image.new("RGBA", (24, 24), TRANSPARENT)
    d = ImageDraw.Draw(low)
    asset_id = asset["id"]
    color = color_for_icon(asset_id)
    px_ellipse(d, (2, 3, 21, 22), OUTLINE)
    px_ellipse(d, (4, 4, 20, 20), shade(color, -34))
    px_rect(d, (8, 5, 15, 7), shade(color, 45))
    if asset["category"] == "ui/oaths":
        draw_token(d, 5, 5, 14, 14, color, blackened="3" in asset_id)
    elif "helmet" in asset_id:
        px_ellipse(d, (5, 5, 19, 17), shade(color, 18))
        px_rect(d, (6, 13, 18, 17), OUTLINE)
        px_rect(d, (10, 6, 13, 16), shade(color, 48))
    elif "armor" in asset_id:
        px_poly(d, [(8, 5), (16, 5), (20, 11), (17, 21), (7, 21), (4, 11)], shade(color, 12))
        px_rect(d, (11, 7, 13, 20), shade(color, 48))
        px_line(d, [(8, 11), (16, 11)], OUTLINE, 1)
    elif "weapon" in asset_id or "combat" in asset_id:
        px_line(d, [(7, 19), (17, 8)], shade(color, 55), 2)
        px_poly(d, [(17, 4), (20, 10), (14, 8)], shade(color, 35))
        px_rect(d, (6, 17, 9, 20), OUTLINE)
    elif any(k in asset_id for k in ("health", "heal", "inn")) and "down" not in asset_id:
        px_ellipse(d, (5, 7, 12, 14), shade(color, 35))
        px_ellipse(d, (12, 7, 19, 14), shade(color, 35))
        px_poly(d, [(5, 12), (19, 12), (12, 21)], shade(color, 35))
    elif "energy" in asset_id:
        px_poly(d, [(14, 3), (6, 14), (12, 14), (9, 22), (19, 10), (13, 10)], shade(color, 45))
    elif any(k in asset_id for k in ("gold", "shop", "treasure")):
        px_ellipse(d, (6, 5, 18, 18), (234, 181, 59, 255))
        px_rect(d, (11, 7, 13, 16), OUTLINE)
        px_rect(d, (8, 9, 16, 10), shade((234, 181, 59, 255), 45))
    elif any(k in asset_id for k in ("block", "mid_boss")):
        px_poly(d, [(12, 4), (19, 7), (17, 18), (12, 22), (7, 18), (5, 7)], shade(color, 35))
        px_rect(d, (11, 7, 13, 18), shade(color, 68))
    elif any(k in asset_id for k in ("weak", "poison", "elite", "boss")):
        px_rect(d, (7, 6, 17, 17), shade(color, 28))
        px_rect(d, (8, 16, 16, 21), shade(color, 28))
        px_rect(d, (9, 11, 11, 13), OUTLINE)
        px_rect(d, (14, 11, 16, 13), OUTLINE)
    elif any(k in asset_id for k in ("draw", "discard", "exhaust", "contract")):
        px_rect(d, (7, 5, 17, 20), OUTLINE)
        px_rect(d, (8, 6, 16, 19), shade(color, 30))
        px_line(d, [(10, 9), (15, 9)], OUTLINE, 1)
        px_line(d, [(10, 13), (15, 13)], OUTLINE, 1)
    elif any(k in asset_id for k in ("bond", "event", "upgrade")):
        px_poly(d, [(12, 3), (14, 9), (21, 9), (15, 13), (18, 21), (12, 16), (6, 21), (9, 13), (3, 9), (10, 9)], shade(color, 38))
    else:
        px_line(d, [(12, 4), (12, 21)], shade(color, 42), 2)
        px_poly(d, [(12, 4), (20, 8), (12, 13)], shade(color, 42))
    img = upscale(low, 2)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    write_text(prompt, f"Phase0 v2 polished pixel icon for {asset_id}; bevel, outline, readable silhouette.")


def make_equipment_icon(asset: dict[str, Any]) -> None:
    out = path_from_res(asset["path"])
    prompt = path_from_res(asset["prompt_path"])
    low = Image.new("RGBA", (24, 24), TRANSPARENT)
    d = ImageDraw.Draw(low)
    asset_id = asset["id"]
    try:
        idx = int(asset_id.rsplit("_", 1)[1])
    except ValueError:
        idx = 1
    steel = (123 + idx * 5, 132 + idx * 4, 132 + idx * 2, 255)
    brass = (172 + idx * 4, 133 + idx * 4, 73, 255)
    leather = (103, 70 + idx * 3, 48, 255)
    px_ellipse(d, (3, 18, 21, 22), (7, 9, 11, 90))
    if "helmet" in asset_id:
        px_ellipse(d, (4, 5, 20, 19), OUTLINE)
        px_ellipse(d, (6, 6, 18, 17), steel)
        px_rect(d, (6, 13, 18, 18), OUTLINE)
        px_rect(d, (8, 14, 16, 16), shade(steel, -35))
        px_rect(d, (10, 6, 13, 16), shade(steel, 45))
        if idx % 3 == 0:
            px_rect(d, (11, 3, 13, 6), brass)
    elif "armor" in asset_id:
        px_poly(d, [(8, 4), (16, 4), (21, 10), (18, 22), (6, 22), (3, 10)], OUTLINE)
        px_poly(d, [(9, 6), (15, 6), (18, 11), (16, 20), (8, 20), (6, 11)], steel)
        px_rect(d, (11, 6, 13, 21), shade(steel, 48))
        px_line(d, [(7, 12), (17, 12)], shade(leather, -10), 1)
        px_rect(d, (7, 17, 17, 18), shade(leather, 12))
        if idx % 2 == 0:
            px_rect(d, (5, 8, 8, 12), brass)
            px_rect(d, (16, 8, 19, 12), brass)
    else:
        kind = idx % 4
        if kind == 1:
            px_line(d, [(5, 20), (18, 7)], OUTLINE, 4)
            px_line(d, [(6, 19), (17, 8)], shade(steel, 55), 2)
            px_poly(d, [(17, 4), (21, 11), (14, 8)], shade(steel, 30))
            px_rect(d, (4, 18, 8, 22), leather)
        elif kind == 2:
            px_line(d, [(6, 20), (17, 5)], OUTLINE, 3)
            px_line(d, [(7, 19), (16, 6)], brass, 1)
            px_poly(d, [(16, 4), (22, 7), (18, 11), (14, 8)], shade(steel, 40))
            px_poly(d, [(10, 10), (15, 13), (13, 16), (8, 13)], shade(steel, 20))
        elif kind == 3:
            px_line(d, [(12, 4), (12, 21)], OUTLINE, 3)
            px_line(d, [(12, 5), (12, 20)], brass, 1)
            px_poly(d, [(12, 3), (17, 8), (12, 12), (7, 8)], shade(steel, 46))
            px_rect(d, (9, 17, 15, 20), leather)
        else:
            px_line(d, [(5, 19), (18, 6)], OUTLINE, 3)
            px_line(d, [(6, 18), (17, 7)], steel, 1)
            px_rect(d, (14, 4, 21, 10), OUTLINE)
            px_rect(d, (15, 5, 20, 9), shade(steel, 35))
            px_rect(d, (4, 18, 8, 21), leather)
    img = upscale(low, 2)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    write_text(prompt, f"Phase0 v2 equipment pixel icon for {asset_id}; object silhouette, transparent background, readable at 48px.")


def color_for_icon(asset_id: str) -> tuple[int, int, int, int]:
    if any(k in asset_id for k in ("energy", "gold", "treasure", "kyle")):
        return (225, 176, 58, 255)
    if any(k in asset_id for k in ("health", "heal", "inn", "sera")):
        return (216, 80, 76, 255)
    if any(k in asset_id for k in ("block", "armor", "shield", "eldric", "mid")):
        return COLD
    if any(k in asset_id for k in ("poison", "upgrade")):
        return GREEN
    if any(k in asset_id for k in ("boss", "weak", "exhaust", "down")):
        return VOID
    if "rowan" in asset_id or "weapon" in asset_id or "combat" in asset_id:
        return (194, 83, 65, 255)
    return (154, 145, 119, 255)


def make_card(asset: dict[str, Any]) -> None:
    out = path_from_res(asset["path"])
    prompt = path_from_res(asset["prompt_path"])
    low = Image.new("RGBA", (80, 112), TRANSPARENT)
    d = ImageDraw.Draw(low)
    asset_id = asset["id"]
    color = color_for_icon(asset_id)
    px_rect(d, (1, 1, 78, 110), OUTLINE)
    px_rect(d, (4, 4, 75, 107), shade(color, -30))
    px_rect(d, (7, 7, 72, 104), (38, 43, 43, 255))
    px_rect(d, (10, 22, 69, 64), (64, 75, 76, 255))
    px_rect(d, (12, 24, 67, 62), (80, 91, 88, 255))
    dither(d, (13, 25, 66, 61), (49, 59, 60, 255), 5)
    px_ellipse(d, (6, 6, 23, 23), OUTLINE)
    px_ellipse(d, (9, 8, 21, 20), (229, 181, 67, 255))
    draw_card_symbol(d, asset_id, color)
    px_rect(d, (10, 75, 69, 100), OUTLINE)
    px_rect(d, (12, 77, 67, 98), (50, 48, 43, 255))
    for y, w in [(82, 40), (89, 50), (95, 34)]:
        px_line(d, [(18, y), (18 + w, y)], (151, 153, 137, 255), 1)
    px_rect(d, (6, 4, 72, 5), shade(color, 35))
    img = upscale(low, 2)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    write_text(prompt, f"Phase0 v2 pixel card frame/motif for {asset_id}; bevel frame, readable cost coin and art panel.")


def draw_card_symbol(draw: ImageDraw.ImageDraw, asset_id: str, color: tuple[int, int, int, int]) -> None:
    if "sword" in asset_id or "attack" in asset_id:
        px_line(draw, [(27, 56), (53, 31)], shade(color, 55), 3)
        px_poly(draw, [(53, 26), (58, 36), (48, 32)], shade(color, 30))
    elif "shield" in asset_id or "guard" in asset_id or "skill" in asset_id:
        px_poly(draw, [(40, 29), (56, 36), (52, 55), (40, 63), (28, 55), (24, 36)], shade(color, 45))
        px_rect(draw, (38, 34, 42, 56), shade(color, 80))
    elif "oath" in asset_id or "power" in asset_id:
        draw_token(draw, 31, 34, 18, 22, color)
    elif "spear" in asset_id:
        px_line(draw, [(30, 60), (53, 27)], shade(color, 50), 2)
        px_poly(draw, [(54, 25), (60, 34), (50, 32)], shade(color, 42))
    elif "dagger" in asset_id:
        px_line(draw, [(31, 58), (43, 34)], shade(color, 55), 2)
        px_line(draw, [(50, 58), (38, 34)], shade(color, 55), 2)
    else:
        px_poly(draw, [(40, 28), (45, 42), (60, 42), (48, 51), (53, 65), (40, 56), (27, 65), (32, 51), (20, 42), (35, 42)], shade(color, 50))


def make_background(asset: dict[str, Any]) -> None:
    out = path_from_res(asset["path"])
    prompt = path_from_res(asset["prompt_path"])
    asset_id = asset["id"]
    w, h = 320, 180
    low = Image.new("RGBA", (w, h), (30, 43, 49, 255))
    d = ImageDraw.Draw(low)
    for y in range(h):
        band = y // 12
        col = (30 + band * 2, 43 + band, 49 + band // 2, 255)
        px_line(d, [(0, y), (w, y)], col, 1)
    for x in range(-20, w, 35):
        top = 72 + int(10 * math.sin(x * 0.08))
        px_poly(d, [(x, top), (x + 26, top - 18), (x + 70, h), (x - 35, h)], (23, 32, 36, 255))
    px_rect(d, (0, 126, w, h), (47, 46, 43, 255))
    dither(d, (0, 126, w, h), (66, 62, 55, 255), 7)
    px_poly(d, [(0, 165), (95, 132), (210, 150), (320, 116), (320, 180), (0, 180)], (55, 52, 47, 255))

    if "boss_gate" in asset_id:
        draw_castle_gate(d, 119, 28, 82, 108, GREEN)
    elif "outpost" in asset_id:
        draw_ruin_house(d, 50, 83, COLD)
        draw_barricade(d, 190, 118, COLD)
    elif "road_ruin" in asset_id:
        draw_ruin_house(d, 45, 92, (112, 91, 68, 255))
        draw_broken_wagon(d, 185, 118)
        px_ellipse(d, (138, 123, 151, 136), WARM)
    elif "map" in asset_id:
        low = draw_map_background()
        d = ImageDraw.Draw(low)
    elif "shop" in asset_id:
        draw_ruin_house(d, 60, 77, WARM, shop=True)
        draw_token(d, 214, 105, 24, 30, WARM)
    elif "inn" in asset_id:
        draw_inn(d, suspicious="suspicious" in asset_id)
    else:
        draw_ruin_house(d, 45, 91, (132, 89, 70, 255))
        draw_signpost(d, 222, 104)
    img = upscale(low, 4)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    write_text(prompt, f"Phase0 v2 pixel background for {asset_id}; moody survival road movie fantasy, pseudo-voxel ruin depth, UI-safe floor.")


def draw_castle_gate(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, accent: tuple[int, int, int, int]) -> None:
    px_rect(draw, (x, y + 22, x + w, y + h), OUTLINE)
    px_rect(draw, (x + 5, y + 27, x + w - 5, y + h), (44, 45, 52, 255))
    px_rect(draw, (x + 17, y + 52, x + w - 17, y + h), (19, 22, 26, 255))
    px_rect(draw, (x + 11, y + 32, x + 21, y + 50), shade((44, 45, 52, 255), 28))
    px_rect(draw, (x + w - 21, y + 32, x + w - 11, y + 50), shade((44, 45, 52, 255), 28))
    px_ellipse(draw, (x + w // 2 - 13, y + 45, x + w // 2 + 13, y + 70), accent)
    for i in range(4):
        px_line(draw, [(x + 10 + i * 17, y + 29), (x + 3 + i * 17, y + 18)], (33, 34, 39, 255), 3)


def draw_ruin_house(draw: ImageDraw.ImageDraw, x: int, y: int, accent: tuple[int, int, int, int], shop: bool = False) -> None:
    px_rect(draw, (x, y + 24, x + 91, y + 67), OUTLINE)
    px_rect(draw, (x + 4, y + 27, x + 87, y + 65), (70, 61, 53, 255))
    px_poly(draw, [(x - 4, y + 28), (x + 44, y), (x + 96, y + 28)], OUTLINE)
    px_poly(draw, [(x + 2, y + 28), (x + 45, y + 5), (x + 90, y + 28)], shade(accent, -12))
    px_rect(draw, (x + 12, y + 38, x + 32, y + 58), (34, 36, 36, 255))
    px_rect(draw, (x + 54, y + 34, x + 78, y + 65), (38, 31, 27, 255))
    px_rect(draw, (x + 56, y + 36, x + 76, y + 39), shade(accent, 38))
    if shop:
        px_rect(draw, (x + 12, y + 20, x + 80, y + 31), OUTLINE)
        px_rect(draw, (x + 15, y + 22, x + 77, y + 29), shade(accent, 20))


def draw_barricade(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    for i in range(4):
        px_line(draw, [(x + i * 20, y + 25), (x + i * 20 + 34, y)], OUTLINE, 4)
        px_line(draw, [(x + i * 20, y + 25), (x + i * 20 + 34, y)], shade(color, 10), 2)


def draw_broken_wagon(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    px_rect(draw, (x, y, x + 58, y + 20), OUTLINE)
    px_rect(draw, (x + 3, y + 3, x + 54, y + 17), (99, 75, 51, 255))
    px_ellipse(draw, (x + 4, y + 13, x + 20, y + 29), OUTLINE)
    px_ellipse(draw, (x + 39, y + 13, x + 55, y + 29), OUTLINE)
    px_line(draw, [(x + 42, y + 2), (x + 71, y - 16)], OUTLINE, 3)


def draw_inn(draw: ImageDraw.ImageDraw, suspicious: bool = False) -> None:
    fire = GREEN if suspicious else WARM
    px_rect(draw, (42, 42, 278, 142), OUTLINE)
    px_rect(draw, (48, 48, 272, 138), (73, 58, 48, 255))
    px_rect(draw, (68, 78, 112, 122), shade(fire, -20))
    px_ellipse(draw, (79, 86, 103, 118), fire)
    px_rect(draw, (162, 71, 206, 138), (35, 27, 24, 255))
    for x in range(56, 264, 24):
        px_line(draw, [(x, 51), (x + 13, 137)], (91, 75, 62, 255), 1)
    px_rect(draw, (112, 32, 207, 47), OUTLINE)
    px_rect(draw, (116, 35, 203, 44), shade(fire, -25))


def draw_signpost(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    px_rect(draw, (x, y, x + 5, y + 48), OUTLINE)
    px_rect(draw, (x + 1, y, x + 4, y + 47), (99, 78, 55, 255))
    px_poly(draw, [(x - 20, y + 5), (x + 3, y + 2), (x + 25, y + 9), (x + 1, y + 15)], (106, 77, 51, 255))


def draw_map_background() -> Image.Image:
    low = Image.new("RGBA", (320, 180), (138, 118, 83, 255))
    d = ImageDraw.Draw(low)
    dither(d, (0, 0, 319, 179), (112, 94, 68, 255), 6)
    for x in range(0, 320, 40):
        px_line(d, [(x, 0), (x + 32, 180)], (102, 83, 58, 255), 1)
    route = [(20, 136), (76, 105), (131, 126), (178, 82), (242, 96), (296, 52)]
    px_line(d, route, OUTLINE, 5)
    px_line(d, route, (177, 69, 53, 255), 3)
    for x, y in route[1:-1]:
        px_ellipse(d, (x - 6, y - 6, x + 6, y + 6), OUTLINE)
        px_ellipse(d, (x - 4, y - 4, x + 4, y + 4), WARM)
    draw_castle_gate(d, 248, 25, 38, 55, VOID)
    return low


def update_manifest(manifest: dict[str, Any]) -> None:
    manifest["version"] = "0.1.1"
    manifest["style"] = "temp_pixel_voxel_v2"
    manifest["generated_by"] = "tools/phase0_upgrade_pixel_assets.py"
    manifest["source_pipeline"] = "pixel/voxel-style redraw plus agent-sprite-forge magenta cleanup for sprite sheets"
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def update_readme() -> None:
    (ASSET_ROOT / "README.md").write_text(
        """# Temporary Pixel Assets

Generated for Phase 0 as replaceable Godot integration art.

Current pass: `temp_pixel_voxel_v2`

- Stronger 2D pixel-art silhouettes with a pseudo-voxel 3/4 read.
- Cold blue-gray survival palette with warm fire and late-game green/purple corruption accents.
- Sprite sheets keep the same manifest IDs and Godot paths.
- Generated sheets use agent-sprite-forge postprocessing for chroma-key cleanup and frame extraction.
- Final art can replace these files by preserving manifest IDs or updating the manifest.
""",
        encoding="utf-8",
    )


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    for asset in manifest["assets"]:
        if asset["type"] == "sprite_sheet":
            make_sprite_sheet(asset)
        elif asset["type"] == "portrait":
            make_portrait(asset)
        elif asset["type"] == "background":
            make_background(asset)
        elif asset["category"] == "cards":
            make_card(asset)
        else:
            make_icon(asset)
    update_manifest(manifest)
    update_readme()
    print(f"upgraded {len(manifest['assets'])} assets")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate Phase 0 temporary pixel assets and a Godot asset manifest.

The creative goal is intentionally modest: consistent, readable proxy pixel art
that can be replaced by the art director later without changing game code.
Animated sprite sheets are drawn on a magenta background, then passed through
agent-sprite-forge's deterministic processor for chroma-key cleanup, frame
extraction, transparent sheets, GIF previews, and pipeline metadata.
"""

from __future__ import annotations

import json
import math
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / "SourceCode"
ASSET_ROOT = SOURCE / "assets" / "temp_pixel"
RAW_ROOT = ASSET_ROOT / "_raw"
FORGE_SCRIPT = PROJECT / "agent-sprite-forge" / "skills" / "generate2dsprite" / "scripts" / "generate2dsprite.py"
MANIFEST_PATH = SOURCE / "data" / "assets" / "temp_asset_manifest.json"
README_PATH = ASSET_ROOT / "README.md"

MAGENTA = (255, 0, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


@dataclass(frozen=True)
class Palette:
    main: tuple[int, int, int, int]
    dark: tuple[int, int, int, int]
    light: tuple[int, int, int, int]
    accent: tuple[int, int, int, int]


@dataclass(frozen=True)
class AssetRecord:
    id: str
    type: str
    category: str
    path: str
    prompt_path: str
    frame_size: tuple[int, int] | None = None
    frames: int | None = None
    rows: int | None = None
    cols: int | None = None
    anchor: str | None = None
    notes: str | None = None


PALETTES = {
    "protagonist": Palette((83, 89, 93, 255), (32, 35, 37, 255), (156, 164, 165, 255), (142, 38, 38, 255)),
    "rowan": Palette((121, 42, 42, 255), (43, 34, 34, 255), (183, 92, 68, 255), (200, 36, 28, 255)),
    "sera": Palette((34, 47, 52, 255), (18, 23, 28, 255), (85, 122, 128, 255), (47, 169, 158, 255)),
    "eldric": Palette((94, 99, 105, 255), (33, 38, 43, 255), (168, 174, 170, 255), (64, 105, 146, 255)),
    "bram": Palette((111, 73, 43, 255), (43, 32, 25, 255), (206, 122, 44, 255), (226, 91, 37, 255)),
    "maren": Palette((104, 105, 96, 255), (46, 48, 45, 255), (179, 168, 130, 255), (207, 157, 74, 255)),
    "tor": Palette((87, 68, 55, 255), (38, 33, 30, 255), (154, 136, 109, 255), (112, 148, 160, 255)),
    "lina": Palette((56, 101, 64, 255), (28, 49, 33, 255), (116, 156, 82, 255), (159, 199, 71, 255)),
    "noa": Palette((43, 53, 103, 255), (25, 29, 55, 255), (116, 127, 184, 255), (211, 196, 108, 255)),
    "isol": Palette((185, 181, 165, 255), (88, 84, 78, 255), (230, 222, 191, 255), (214, 174, 77, 255)),
    "kyle": Palette((72, 91, 65, 255), (37, 44, 35, 255), (165, 139, 65, 255), (221, 173, 54, 255)),
    "enemy": Palette((83, 92, 88, 255), (34, 40, 40, 255), (132, 149, 126, 255), (81, 44, 94, 255)),
    "boss": Palette((91, 65, 84, 255), (32, 25, 35, 255), (138, 97, 122, 255), (58, 136, 92, 255)),
}


records: list[AssetRecord] = []


def res_path(path: Path) -> str:
    return "res://" + str(path.relative_to(SOURCE)).replace("\\", "/")


def prompt_path_for(path: Path) -> Path:
    return path.with_suffix(path.suffix + ".prompt.txt")


def write_prompt(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    prompt_path_for(path).write_text(text.strip() + "\n", encoding="utf-8")


def add_record(
    asset_id: str,
    asset_type: str,
    category: str,
    path: Path,
    prompt_path: Path,
    frame_size: tuple[int, int] | None = None,
    frames: int | None = None,
    rows: int | None = None,
    cols: int | None = None,
    anchor: str | None = None,
    notes: str | None = None,
) -> None:
    records.append(
        AssetRecord(
            id=asset_id,
            type=asset_type,
            category=category,
            path=res_path(path),
            prompt_path=res_path(prompt_path),
            frame_size=frame_size,
            frames=frames,
            rows=rows,
            cols=cols,
            anchor=anchor,
            notes=notes,
        )
    )


def rect(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], fill: tuple[int, int, int, int]) -> None:
    draw.rectangle(xy, fill=fill)


def poly(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], fill: tuple[int, int, int, int]) -> None:
    draw.polygon(pts, fill=fill)


def ellipse(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], fill: tuple[int, int, int, int]) -> None:
    draw.ellipse(xy, fill=fill)


def line(draw: ImageDraw.ImageDraw, pts: list[tuple[int, int]], fill: tuple[int, int, int, int], width: int = 2) -> None:
    draw.line(pts, fill=fill, width=width)


def draw_humanoid(draw: ImageDraw.ImageDraw, x: int, y: int, pal: Palette, weapon: str, frame: int, action: str) -> None:
    bob = [0, -2, 0, 1][frame % 4]
    reach = [0, 4, 8, 2][frame % 4] if action == "attack" else 0
    guard = action == "guard"
    hurt = action == "hurt"
    yy = y + bob
    outline = pal.dark
    if hurt:
        pal = Palette(pal.main, pal.dark, pal.light, (211, 58, 58, 255))
    ellipse(draw, (x + 36, yy + 15, x + 60, yy + 38), outline)
    rect(draw, (x + 40, yy + 30, x + 56, yy + 62), outline)
    rect(draw, (x + 42, yy + 18, x + 58, yy + 35), pal.light)
    rect(draw, (x + 43, yy + 32, x + 55, yy + 60), pal.main)
    rect(draw, (x + 33, yy + 37, x + 43, yy + 57), outline)
    rect(draw, (x + 54, yy + 37, x + 64, yy + 57), outline)
    rect(draw, (x + 38, yy + 60, x + 47, yy + 82), outline)
    rect(draw, (x + 50, yy + 60, x + 59, yy + 82), outline)
    rect(draw, (x + 39, yy + 61, x + 46, yy + 78), pal.main)
    rect(draw, (x + 51, yy + 61, x + 58, yy + 78), pal.main)
    if weapon == "spear":
        line(draw, [(x + 60, yy + 22), (x + 73 + reach, yy + 73)], pal.accent, 3)
        poly(draw, [(x + 72 + reach, yy + 72), (x + 80 + reach, yy + 84), (x + 68 + reach, yy + 82)], pal.light)
    elif weapon == "daggers":
        line(draw, [(x + 34, yy + 38), (x + 20 - reach, yy + 48)], pal.light, 3)
        line(draw, [(x + 63, yy + 38), (x + 76 + reach, yy + 48)], pal.light, 3)
    elif weapon == "shield":
        rect(draw, (x + 24, yy + 37, x + 40, yy + 63), outline)
        rect(draw, (x + 27, yy + 40, x + 37, yy + 60), pal.accent)
        line(draw, [(x + 61, yy + 32), (x + 73, yy + 65)], pal.light, 3)
    elif weapon == "staff":
        line(draw, [(x + 64, yy + 26), (x + 68, yy + 78)], pal.light, 3)
        ellipse(draw, (x + 60, yy + 20, x + 70, yy + 30), pal.accent)
    elif weapon == "book":
        rect(draw, (x + 62, yy + 38, x + 76, yy + 52), outline)
        rect(draw, (x + 64, yy + 40, x + 74, yy + 50), pal.accent)
    else:
        line(draw, [(x + 62, yy + 31), (x + 77 + reach, yy + 59)], pal.light, 3)
    if guard:
        rect(draw, (x + 20, yy + 30, x + 48, yy + 72), outline)
        rect(draw, (x + 24, yy + 34, x + 44, yy + 68), pal.accent)
    if pal.accent[0] > 150:
        rect(draw, (x + 35, yy + 11, x + 62, yy + 15), pal.accent)


def draw_creature(draw: ImageDraw.ImageDraw, x: int, y: int, pal: Palette, variant: str, frame: int, hurt: bool = False) -> None:
    bob = [0, -1, 1, 0][frame % 4]
    yy = y + bob
    outline = pal.dark
    accent = (200, 54, 54, 255) if hurt else pal.accent
    if variant in {"wolf", "horse"}:
        rect(draw, (x + 24, yy + 44, x + 68, yy + 64), outline)
        rect(draw, (x + 28, yy + 46, x + 64, yy + 60), pal.main)
        ellipse(draw, (x + 62, yy + 32, x + 82, yy + 52), outline)
        ellipse(draw, (x + 65, yy + 35, x + 79, yy + 49), pal.light)
        for lx in (30, 42, 58, 68):
            rect(draw, (x + lx, yy + 60, x + lx + 5, yy + 80), outline)
        line(draw, [(x + 22, yy + 46), (x + 10, yy + 36)], accent, 3)
        if variant == "wolf":
            poly(draw, [(x + 66, yy + 33), (x + 72, yy + 22), (x + 75, yy + 36)], outline)
    elif variant == "root":
        rect(draw, (x + 38, yy + 34, x + 58, yy + 74), outline)
        rect(draw, (x + 41, yy + 38, x + 55, yy + 70), pal.main)
        for off in (-18, -8, 8, 18):
            line(draw, [(x + 48, yy + 62), (x + 48 + off, yy + 84)], accent, 3)
        line(draw, [(x + 40, yy + 42), (x + 20, yy + 28)], pal.light, 3)
        line(draw, [(x + 56, yy + 42), (x + 76, yy + 28)], pal.light, 3)
    else:
        ellipse(draw, (x + 34, yy + 20, x + 62, yy + 47), outline)
        rect(draw, (x + 32, yy + 40, x + 65, yy + 74), outline)
        ellipse(draw, (x + 38, yy + 24, x + 58, yy + 43), pal.light)
        rect(draw, (x + 36, yy + 44, x + 61, yy + 70), pal.main)
        line(draw, [(x + 34, yy + 52), (x + 18, yy + 68)], accent, 3)
        line(draw, [(x + 62, yy + 52), (x + 78, yy + 68)], accent, 3)
        if variant == "scholar":
            rect(draw, (x + 29, yy + 18, x + 66, yy + 22), pal.accent)
            rect(draw, (x + 36, yy + 27, x + 45, yy + 34), outline)
            rect(draw, (x + 51, yy + 27, x + 60, yy + 34), outline)
        elif variant == "merchant":
            rect(draw, (x + 28, yy + 49, x + 40, yy + 62), pal.accent)
        elif variant == "mercenary":
            line(draw, [(x + 64, yy + 34), (x + 82, yy + 68)], pal.light, 3)


def draw_boss(draw: ImageDraw.ImageDraw, x: int, y: int, pal: Palette, variant: str, frame: int) -> None:
    bob = [0, -2, 0, 1][frame % 4]
    yy = y + bob
    outline = pal.dark
    rect(draw, (x + 28, yy + 30, x + 72, yy + 86), outline)
    rect(draw, (x + 34, yy + 36, x + 66, yy + 80), pal.main)
    ellipse(draw, (x + 36, yy + 8, x + 64, yy + 38), outline)
    ellipse(draw, (x + 40, yy + 12, x + 60, yy + 34), pal.light)
    line(draw, [(x + 23, yy + 42), (x + 8, yy + 72)], pal.accent, 5)
    line(draw, [(x + 76, yy + 42), (x + 94, yy + 72)], pal.accent, 5)
    if variant == "warlord":
        line(draw, [(x + 74, yy + 24), (x + 102, yy + 92)], pal.light, 5)
        rect(draw, (x + 41, yy + 4, x + 59, yy + 10), pal.accent)
    elif variant == "guard":
        rect(draw, (x + 10, yy + 42, x + 38, yy + 80), outline)
        rect(draw, (x + 14, yy + 46, x + 34, yy + 76), pal.accent)
    elif variant == "scholar":
        for off in (0, 8, 16):
            line(draw, [(x + 66, yy + 34 + off), (x + 98, yy + 20 + off)], pal.accent, 2)
    elif variant == "caravan":
        rect(draw, (x + 22, yy + 78, x + 78, yy + 92), pal.light)
    rect(draw, (x + 45, yy + 28, x + 53, yy + 34), (20, 10, 20, 255))


def make_sheet(asset_id: str, category: str, palette_key: str, kind: str, action: str, weapon: str = "sword") -> None:
    rows, cols, cell = 2, 2, 128
    raw = Image.new("RGBA", (cols * cell, rows * cell), MAGENTA)
    draw = ImageDraw.Draw(raw)
    pal = PALETTES[palette_key]
    for i in range(4):
        x = (i % cols) * cell + 16
        y = (i // cols) * cell + 18
        if kind == "humanoid":
            draw_humanoid(draw, x, y, pal, weapon, i, action)
        elif kind == "creature":
            draw_creature(draw, x, y, pal, weapon, i, action == "hurt")
        else:
            draw_boss(draw, x, y, pal, weapon, i)
    raw_path = RAW_ROOT / f"{asset_id}_raw.png"
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    raw.save(raw_path)
    prompt = (
        f"Temporary 2D pixel art proxy for {asset_id}. "
        f"Role={kind}, action={action}, palette={palette_key}, solid #FF00FF raw background, "
        "readable tactical fantasy silhouette, replaceable by final art."
    )
    write_prompt(raw_path, prompt)
    out_dir = ASSET_ROOT / category / asset_id
    subprocess.run(
        [
            "python3",
            str(FORGE_SCRIPT),
            "process",
            "--input",
            str(raw_path),
            "--target",
            "asset" if kind != "humanoid" else "npc",
            "--mode",
            "idle" if action not in {"attack", "hurt", "guard"} else ("attack" if action != "hurt" else "hurt"),
            "--output-dir",
            str(out_dir),
            "--rows",
            "2",
            "--cols",
            "2",
            "--cell-size",
            str(cell),
            "--align",
            "bottom",
            "--shared-scale",
            "--component-mode",
            "all",
            "--prompt",
            prompt,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    sheet_path = out_dir / "sheet-transparent.png"
    add_record(asset_id, "sprite_sheet", category, sheet_path, out_dir / "prompt-used.txt", (cell, cell), 4, rows, cols, "bottom")


def make_single_icon(asset_id: str, category: str, draw_fn, size: int = 48, notes: str | None = None) -> None:
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    d = ImageDraw.Draw(img)
    draw_fn(d, size)
    out = ASSET_ROOT / category / f"{asset_id}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    prompt = f"Temporary 2D pixel icon for {asset_id}, clean silhouette, replaceable final art."
    write_prompt(out, prompt)
    add_record(asset_id, "image", category, out, prompt_path_for(out), (size, size), 1, notes=notes)


def make_portrait(asset_id: str, category: str, palette_key: str, weapon: str, notes: str | None = None) -> None:
    size = 96
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    d = ImageDraw.Draw(img)
    pal = PALETTES[palette_key]
    rect(d, (8, 8, 87, 87), (18, 21, 24, 230))
    rect(d, (11, 11, 84, 84), (54, 62, 66, 255))
    draw_humanoid(d, 0, -4, pal, weapon, 0, "idle")
    out = ASSET_ROOT / category / f"{asset_id}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    prompt = f"Temporary 2D pixel portrait for {asset_id}, muted disaster fantasy palette."
    write_prompt(out, prompt)
    add_record(asset_id, "portrait", category, out, prompt_path_for(out), (size, size), 1, notes=notes)


def make_background(asset_id: str, category: str, theme: str, accent: tuple[int, int, int, int]) -> None:
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), (43, 54, 59, 255))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        col = (
            int(35 + 26 * t),
            int(48 + 22 * t),
            int(55 + 18 * t),
            255,
        )
        d.line([(0, y), (w, y)], fill=col)
    for i in range(0, w, 48):
        top = 120 + int(22 * math.sin(i * 0.03))
        poly(d, [(i, top), (i + 36, top - 22), (i + 86, h), (i - 40, h)], (30, 36, 39, 255))
    rect(d, (0, 260, w, h), (50, 48, 45, 255))
    for i in range(0, w, 32):
        line(d, [(i, 290), (i + 42, 360)], (67, 64, 58, 255), 2)
    if "inn" in asset_id:
        rect(d, (115, 86, 485, 270), (76, 61, 49, 255))
        rect(d, (140, 115, 210, 190), accent)
        rect(d, (280, 130, 360, 270), (43, 31, 25, 255))
    elif "shop" in asset_id:
        rect(d, (120, 115, 520, 245), (63, 55, 48, 255))
        rect(d, (155, 90, 465, 125), accent)
        for x in range(170, 450, 55):
            rect(d, (x, 155, x + 30, 190), (94, 91, 83, 255))
    elif "map" in asset_id:
        for x in range(80, 600, 90):
            ellipse(d, (x, 110 + (x % 70), x + 22, 132 + (x % 70)), accent)
        line(d, [(30, 280), (160, 220), (310, 250), (480, 160), (610, 190)], accent, 6)
    elif "boss" in asset_id:
        rect(d, (240, 50, 400, 260), (38, 38, 45, 255))
        ellipse(d, (292, 94, 348, 150), accent)
    else:
        rect(d, (80, 180, 190, 230), (63, 58, 52, 255))
        rect(d, (420, 130, 520, 250), (48, 48, 52, 255))
        ellipse(d, (295, 190, 332, 230), accent)
    out = ASSET_ROOT / category / f"{asset_id}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img = img.resize((w * 2, h * 2), Image.Resampling.NEAREST)
    img.save(out)
    prompt = f"Temporary 2D pixel battle/background scene for {asset_id}: {theme}. UI-safe lower area, replaceable final art."
    write_prompt(out, prompt)
    add_record(asset_id, "background", category, out, prompt_path_for(out), (w * 2, h * 2), 1)


def draw_simple_symbol(kind: str, color: tuple[int, int, int, int]):
    def inner(d: ImageDraw.ImageDraw, size: int) -> None:
        s = size
        dark = (22, 24, 26, 255)
        if kind == "heart":
            ellipse(d, (9, 12, 25, 28), color)
            ellipse(d, (23, 12, 39, 28), color)
            poly(d, [(9, 22), (39, 22), (24, 42)], color)
        elif kind == "coin":
            ellipse(d, (8, 8, s - 8, s - 8), dark)
            ellipse(d, (11, 11, s - 11, s - 11), color)
            rect(d, (22, 15, 27, 34), dark)
        elif kind == "shield":
            poly(d, [(24, 6), (40, 13), (36, 36), (24, 44), (12, 36), (8, 13)], dark)
            poly(d, [(24, 10), (36, 16), (33, 34), (24, 40), (15, 34), (12, 16)], color)
        elif kind == "bolt":
            poly(d, [(27, 4), (12, 27), (23, 27), (18, 44), (37, 20), (26, 20)], color)
        elif kind == "skull":
            ellipse(d, (11, 8, 37, 34), color)
            rect(d, (17, 29, 31, 42), color)
            rect(d, (16, 20, 22, 26), dark)
            rect(d, (27, 20, 33, 26), dark)
        elif kind == "mark":
            line(d, [(24, 5), (24, 42)], color, 4)
            poly(d, [(24, 7), (39, 15), (24, 23)], color)
        elif kind == "card":
            rect(d, (12, 7, 36, 41), dark)
            rect(d, (15, 10, 33, 38), color)
        elif kind == "helmet":
            ellipse(d, (8, 10, 40, 38), color)
            rect(d, (10, 26, 38, 36), dark)
        elif kind == "armor":
            poly(d, [(16, 8), (32, 8), (40, 20), (34, 42), (14, 42), (8, 20)], color)
            rect(d, (21, 12, 27, 42), dark)
        elif kind == "weapon":
            line(d, [(12, 38), (37, 13)], color, 5)
            poly(d, [(36, 7), (42, 18), (31, 13)], color)
        elif kind == "crack":
            ellipse(d, (8, 8, 40, 40), (95, 64, 100, 255))
            line(d, [(26, 9), (19, 23), (29, 29), (20, 42)], dark, 3)
        elif kind == "star":
            poly(d, [(24, 5), (29, 19), (44, 19), (32, 28), (37, 43), (24, 34), (11, 43), (16, 28), (4, 19), (19, 19)], color)
        else:
            rect(d, (10, 10, 38, 38), color)
            rect(d, (16, 16, 32, 32), dark)
    return inner


def make_card_asset(asset_id: str, companion_color: tuple[int, int, int, int] | None = None) -> None:
    w, h = 160, 224
    img = Image.new("RGBA", (w, h), TRANSPARENT)
    d = ImageDraw.Draw(img)
    frame = companion_color or (86, 83, 75, 255)
    rect(d, (4, 4, w - 5, h - 5), (20, 23, 24, 255))
    rect(d, (9, 9, w - 10, h - 10), frame)
    rect(d, (18, 42, w - 19, 136), (49, 56, 58, 255))
    rect(d, (22, 46, w - 23, 132), (74, 83, 82, 255))
    rect(d, (20, 154, w - 21, 204), (31, 34, 35, 255))
    ellipse(d, (12, 12, 42, 42), (33, 38, 40, 255))
    ellipse(d, (18, 18, 36, 36), (218, 183, 86, 255))
    line(d, [(50, 174), (132, 174)], (120, 125, 116, 255), 3)
    line(d, [(50, 188), (118, 188)], (120, 125, 116, 255), 3)
    out = ASSET_ROOT / "cards" / f"{asset_id}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    prompt = f"Temporary 2D pixel card frame or motif for {asset_id}, readable Godot UI proxy."
    write_prompt(out, prompt)
    add_record(asset_id, "card_art", "cards", out, prompt_path_for(out), (w, h), 1)


def make_fx_sheet(asset_id: str, color: tuple[int, int, int, int], shape: str) -> None:
    rows, cols, cell = 2, 2, 96
    raw = Image.new("RGBA", (cols * cell, rows * cell), MAGENTA)
    d = ImageDraw.Draw(raw)
    for i in range(4):
        x = (i % cols) * cell
        y = (i // cols) * cell
        scale = 10 + i * 6
        if shape == "slash":
            line(d, [(x + 24 - i * 2, y + 68), (x + 72 + i * 2, y + 26)], color, 5)
            line(d, [(x + 30, y + 70), (x + 76, y + 34)], (255, 240, 180, 255), 2)
        elif shape == "spark":
            ellipse(d, (x + 48 - scale, y + 48 - scale, x + 48 + scale, y + 48 + scale), color)
            rect(d, (x + 44, y + 20, x + 52, y + 76), color)
            rect(d, (x + 20, y + 44, x + 76, y + 52), color)
        else:
            ellipse(d, (x + 48 - scale, y + 48 - scale, x + 48 + scale, y + 48 + scale), color)
    raw_path = RAW_ROOT / f"{asset_id}_raw.png"
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    raw.save(raw_path)
    prompt = f"Temporary 2D pixel FX sheet for {asset_id}, solid magenta raw background."
    write_prompt(raw_path, prompt)
    out_dir = ASSET_ROOT / "fx" / asset_id
    subprocess.run(
        [
            "python3",
            str(FORGE_SCRIPT),
            "process",
            "--input",
            str(raw_path),
            "--target",
            "asset",
            "--mode",
            "fx",
            "--output-dir",
            str(out_dir),
            "--rows",
            "2",
            "--cols",
            "2",
            "--cell-size",
            str(cell),
            "--align",
            "center",
            "--shared-scale",
            "--component-mode",
            "all",
            "--prompt",
            prompt,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    add_record(asset_id, "sprite_sheet", "fx", out_dir / "sheet-transparent.png", out_dir / "prompt-used.txt", (cell, cell), 4, rows, cols, "center")


def make_json_manifest() -> None:
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "version": "0.1.0",
        "style": "temp_pixel",
        "generated_by": "tools/phase0_generate_temp_pixel_assets.py",
        "source_pipeline": "agent-sprite-forge magenta cleanup and frame extraction for sheets",
        "assets": [
            {
                **{
                    "id": r.id,
                    "type": r.type,
                    "category": r.category,
                    "path": r.path,
                    "prompt_path": r.prompt_path,
                },
                **({"frame_size": list(r.frame_size)} if r.frame_size else {}),
                **({"frames": r.frames} if r.frames is not None else {}),
                **({"rows": r.rows} if r.rows is not None else {}),
                **({"cols": r.cols} if r.cols is not None else {}),
                **({"anchor": r.anchor} if r.anchor else {}),
                **({"notes": r.notes} if r.notes else {}),
            }
            for r in records
        ],
    }
    MANIFEST_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def make_readme() -> None:
    README_PATH.write_text(
        """# Temporary Pixel Assets

Generated for Phase 0. These are replaceable proxy assets for Godot integration,
not final production art.

- Source manifest: `res://data/assets/temp_asset_manifest.json`
- Generated sheets use agent-sprite-forge postprocessing where applicable.
- Each asset has a `.prompt.txt` file or a prompt entry in its pipeline metadata.
- Final art can replace files by preserving manifest IDs or updating the manifest.
""",
        encoding="utf-8",
    )


def generate_all() -> None:
    for directory in [
        ASSET_ROOT,
        RAW_ROOT,
        SOURCE / "data" / "assets",
    ]:
        directory.mkdir(parents=True, exist_ok=True)

    make_sheet("protagonist_mercenary_idle", "actors", "protagonist", "humanoid", "idle", "sword")
    make_sheet("protagonist_mercenary_attack", "actors", "protagonist", "humanoid", "attack", "sword")
    make_sheet("protagonist_mercenary_guard", "actors", "protagonist", "humanoid", "guard", "shield")
    make_portrait("protagonist_portrait", "actors", "protagonist", "sword")

    companions = [
        ("rowan", "spear"),
        ("sera", "daggers"),
        ("eldric", "shield"),
    ]
    for name, weapon in companions:
        make_sheet(f"companion_{name}_idle", "companions", name, "humanoid", "idle", weapon)
        make_sheet(f"companion_{name}_{'guard' if name == 'eldric' else 'attack'}", "companions", name, "humanoid", "guard" if name == "eldric" else "attack", weapon)
        make_portrait(f"companion_{name}_portrait", "companions", name, weapon)
        for idx in range(1, 4):
            make_single_icon(
                f"companion_{name}_oath_{idx}",
                "ui/oaths",
                draw_simple_symbol(["mark", "shield", "star"][idx - 1], PALETTES[name].accent),
                48,
                f"oath icon {idx}",
            )

    for name, weapon in [
        ("bram", "sword"),
        ("maren", "staff"),
        ("tor", "shield"),
        ("lina", "staff"),
        ("noa", "book"),
        ("isol", "staff"),
        ("kyle", "book"),
    ]:
        make_portrait(f"companion_{name}_portrait", "companions", name, weapon, "reserve companion portrait")

    for enemy_id, variant in [
        ("enemy_act1_mutated_merchant", "merchant"),
        ("enemy_act1_mutated_scholar", "scholar"),
        ("enemy_act1_mutated_mercenary", "mercenary"),
        ("enemy_act1_twisted_wolf", "wolf"),
        ("enemy_act1_broken_packhorse", "horse"),
        ("enemy_act1_rooted_scavenger", "root"),
    ]:
        make_sheet(f"{enemy_id}_idle", "enemies", "enemy", "creature", "idle", variant)
        make_sheet(f"{enemy_id}_hurt", "enemies", "enemy", "creature", "hurt", variant)

    for boss_id, variant in [
        ("elite_act1_blackprint_captain", "guard"),
        ("elite_act1_armored_caravan_guard", "caravan"),
        ("elite_act1_excavation_scholar", "scholar"),
        ("midboss_act1_blackened_guard", "guard"),
        ("boss_act1_blackprint_warlord", "warlord"),
    ]:
        make_sheet(f"{boss_id}_idle", "bosses", "boss", "boss", "idle", variant)
        make_sheet(f"{boss_id}_hurt", "bosses", "boss", "boss", "hurt", variant)

    for bg_id, theme, accent in [
        ("bg_battle_act1_road_ruin", "collapsed road with ruined caravan traces", (172, 107, 58, 255)),
        ("bg_battle_act1_outpost", "abandoned outpost and cold iron barricades", (99, 133, 147, 255)),
        ("bg_battle_act1_boss_gate", "ancient road gate with black fingerprint omen", (88, 155, 105, 255)),
        ("bg_map_act1_route", "parchment-like route map over ruined roads", (185, 121, 62, 255)),
        ("bg_shop_act1_rusty_trader", "rusty roadside trader shelter", (195, 155, 72, 255)),
        ("bg_inn_act1_warm_common", "warm common inn with firelight", (220, 148, 72, 255)),
        ("bg_inn_act1_suspicious", "suspicious inn with strange green shadows", (76, 145, 102, 255)),
        ("bg_event_act1_generic", "generic event backdrop with broken signs", (137, 87, 65, 255)),
    ]:
        make_background(bg_id, "backgrounds", theme, accent)

    ui_defs = [
        ("icon_energy", "bolt", (223, 178, 74, 255)),
        ("icon_health", "heart", (196, 56, 65, 255)),
        ("icon_gold", "coin", (223, 181, 60, 255)),
        ("icon_block", "shield", (107, 145, 166, 255)),
        ("icon_draw_pile", "card", (167, 169, 154, 255)),
        ("icon_discard_pile", "card", (109, 117, 118, 255)),
        ("icon_exhaust_pile", "card", (83, 69, 89, 255)),
        ("icon_tactical_mark", "mark", (210, 60, 48, 255)),
        ("icon_vulnerable", "crack", (198, 66, 54, 255)),
        ("icon_weak", "skull", (124, 104, 142, 255)),
        ("icon_poison", "skull", (83, 165, 78, 255)),
        ("icon_heal", "heart", (226, 204, 148, 255)),
        ("icon_healing_down", "crack", (70, 38, 78, 255)),
        ("icon_helmet_slot", "helmet", (148, 154, 151, 255)),
        ("icon_armor_slot", "armor", (130, 143, 151, 255)),
        ("icon_weapon_slot", "weapon", (181, 174, 144, 255)),
        ("icon_bond_30", "star", (128, 153, 149, 255)),
        ("icon_bond_60", "star", (177, 157, 100, 255)),
        ("icon_bond_100", "star", (224, 190, 86, 255)),
        ("node_combat", "weapon", (171, 91, 75, 255)),
        ("node_elite", "skull", (160, 74, 91, 255)),
        ("node_mid_boss", "shield", (92, 112, 144, 255)),
        ("node_boss", "skull", (112, 46, 92, 255)),
        ("node_shop", "coin", (204, 159, 60, 255)),
        ("node_inn", "heart", (210, 139, 79, 255)),
        ("node_event", "star", (143, 130, 104, 255)),
        ("node_treasure", "coin", (226, 188, 79, 255)),
        ("node_companion_trace", "mark", (177, 70, 61, 255)),
        ("node_companion_contract", "card", (172, 55, 51, 255)),
        ("node_upgrade", "star", (92, 165, 112, 255)),
    ]
    for asset_id, shape, color in ui_defs:
        make_single_icon(asset_id, "ui", draw_simple_symbol(shape, color), 48)

    for asset_id, color in [
        ("card_frame_protagonist_attack_common", (112, 72, 62, 255)),
        ("card_frame_protagonist_skill_common", (72, 94, 108, 255)),
        ("card_frame_protagonist_power_common", (91, 78, 118, 255)),
        ("card_frame_companion_attack_common", (130, 69, 61, 255)),
        ("card_frame_companion_skill_common", (65, 105, 92, 255)),
        ("card_frame_companion_power_common", (106, 83, 126, 255)),
        ("card_motif_attack_sword", (135, 83, 72, 255)),
        ("card_motif_skill_guard", (75, 103, 119, 255)),
        ("card_motif_power_oath", (108, 79, 124, 255)),
        ("card_motif_rowan_spear", PALETTES["rowan"].accent),
        ("card_motif_sera_dagger", PALETTES["sera"].accent),
        ("card_motif_eldric_shield", PALETTES["eldric"].accent),
    ]:
        make_card_asset(asset_id, color)

    for i in range(1, 9):
        make_single_icon(f"equip_helmet_{i:02d}", "equipment", draw_simple_symbol("helmet", (120 + i * 8, 128, 125, 255)), 48)
        make_single_icon(f"equip_armor_{i:02d}", "equipment", draw_simple_symbol("armor", (104, 115 + i * 7, 130, 255)), 48)
        make_single_icon(f"equip_weapon_{i:02d}", "equipment", draw_simple_symbol("weapon", (155, 132 + i * 5, 92, 255)), 48)

    for asset_id, color, shape in [
        ("fx_slash_small", (225, 220, 178, 255), "slash"),
        ("fx_pierce_red", (217, 55, 47, 255), "slash"),
        ("fx_guard_flash", (115, 158, 184, 255), "spark"),
        ("fx_tactical_mark_pin", (210, 56, 48, 255), "spark"),
        ("fx_oath_token_glint", (213, 170, 78, 255), "spark"),
        ("fx_heal_low", (225, 210, 155, 255), "pulse"),
        ("fx_healing_down_black_crack", (72, 38, 83, 255), "spark"),
        ("fx_poison_puff", (83, 171, 76, 255), "pulse"),
        ("fx_gold_spark", (231, 181, 65, 255), "spark"),
        ("fx_card_draw_wisp", (139, 151, 192, 255), "pulse"),
    ]:
        make_fx_sheet(asset_id, color, shape)

    make_json_manifest()
    make_readme()


if __name__ == "__main__":
    generate_all()
    print(f"generated {len(records)} assets")
    print(MANIFEST_PATH)

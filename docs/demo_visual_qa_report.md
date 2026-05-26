# Demo Visual QA Report

Date: 2026-05-27

## Scope

This pass checked the current playable Godot screens as a showable demo path, not as debug tooling.

Screens captured:

- Main menu
- Act map
- Combat
- Card reward
- Shop and shop service picker
- Inn
- Event
- Companion contract
- Oath tactic selection
- Upgrade selection

Viewports:

- 1280x720
- 1920x1080

Capture folder:

```txt
/tmp/deckbuilder_qa/
```

## Result

The current build passes the minimum "real game screen" gate:

- The normal loop no longer exposes debug-only screens or buttons.
- Combat has readable player/enemy positions, enemy intent, hand cards, energy, end turn, targeting, and wave state.
- The map is scrollable, route-like, and does not force all nodes into one cramped flat panel.
- Reward, shop, inn, event, companion, oath, and upgrade screens all show a clear primary decision.
- 1280x720 and 1920x1080 captures do not show accidental vertical text stacking, blank screens, or catastrophic overlap.

## Asset Status

The project is using stable asset IDs through:

```txt
SourceCode/data/assets/asset_manifest.json
SourceCode/assets/temp_pixel/
SourceCode/assets/vendor/kenney_ui/
```

Kenney UI assets are present under `SourceCode/assets/vendor/kenney_ui/` with CC0 license text included in:

```txt
SourceCode/assets/vendor/kenney_ui/licenses/LICENSE.txt
```

Current art is still temporary, but the visual language is coherent enough for continued implementation:

- Cold blue-gray backgrounds
- Warm rust/gold UI accents
- Metal-token route and oath motifs
- Pixel/voxel-like actor silhouettes
- Kenney-derived readable card and button foundations

## Remaining Visual Risks

These are not blockers for the next development bundle, but should be handled before a public playtest:

1. Some large desktop screens leave too much empty space on non-combat pages.
2. Temporary monster sprites reuse Act 1 silhouettes for later Acts.
3. Combat card hand is readable, but the bottom fan should eventually get final frame art and stronger hover depth.
4. Event/inn/shop screens are functional but still feel more like strong UI mockups than fully art-directed rooms.
5. Full Korean localization is incomplete outside the main menu/settings path.

## Verification Commands

```txt
/Applications/Godot.app/Contents/MacOS/Godot --headless --path SourceCode --quit-after 1
python3 tools/balance_run_simulator.py --runs 300 --policies novice,balanced,safe,greedy --enemy-profiles current
python3 -m py_compile tools/balance_run_simulator.py
git diff --check
```

Visual captures were generated with:

```txt
/Applications/Godot.app/Contents/MacOS/Godot --resolution 1280x720 --path SourceCode --script res://tools/visual_capture.gd -- --scene <scene> --mode <mode> --out <png>
/Applications/Godot.app/Contents/MacOS/Godot --resolution 1920x1080 --path SourceCode --script res://tools/visual_capture.gd -- --scene <scene> --mode <mode> --out <png>
```


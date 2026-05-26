# Asset Replacement Guide

## Purpose

This project currently uses temporary 2D pixel assets so the Godot implementation can stay playable while final art is produced.
Phase 10 makes the replacement path explicit: gameplay code should use stable asset IDs, and art can be swapped by updating the manifest.

## Files

Primary manifest:

```txt
SourceCode/data/assets/asset_manifest.json
```

Temporary reference manifest:

```txt
SourceCode/data/assets/temp_asset_manifest.json
```

Temporary art folder:

```txt
SourceCode/assets/temp_pixel/
```

The primary manifest currently points at the temporary assets.
Final art can replace paths in `asset_manifest.json` without changing gameplay data IDs.

## Replacement Rule

Each art entry has a stable `id`.
Gameplay data should reference this ID through fields such as:

```txt
asset_id
portrait_asset_id
sprite_asset_id
```

Scenes and scripts should ask `DataRegistry.get_temp_asset_path(asset_id)` or `AssetRegistry.get_asset(asset_id)` for the actual file path.
Do not hardcode final art file paths inside combat, map, shop, inn, event, or companion scene scripts.

## Sprite Sheet Contract

When replacing a sprite sheet, preserve:

```txt
frame_size
frames
rows
cols
anchor
transparent background
```

Current actor and enemy sheets use:

```txt
frame_size: 128 x 128
frames: 4
rows: 2
cols: 2
anchor: bottom
```

Current portraits use:

```txt
frame_size: 96 x 96
frames: 1
```

Current oath/UI icons use:

```txt
frame_size: 48 x 48
frames: 1
```

## Recommended Final Folder Layout

Final art can be introduced without touching temporary assets:

```txt
SourceCode/assets/final_pixel/actors/
SourceCode/assets/final_pixel/companions/
SourceCode/assets/final_pixel/enemies/
SourceCode/assets/final_pixel/bosses/
SourceCode/assets/final_pixel/backgrounds/
SourceCode/assets/final_pixel/ui/
SourceCode/assets/final_pixel/fx/
SourceCode/assets/final_pixel/cards/
```

Then update only `asset_manifest.json` paths.

## Art Direction Anchors

The final art should preserve these identity signals:

- World: ruined road movie survival fantasy inside a collapsing magical disaster.
- Oath tokens: metal tags with blood fingerprints, sometimes blackened.
- Early enemies: warped merchants, scholars, mercenaries, animals, and plants.
- Late enemies: less human, less readable, more dimensional and core-corrupted.
- Palette: cold blue-gray survival base, warm fire accents, late dark purple and deep green corruption.
- Main character: worn, grounded mercenary rather than heroic fantasy champion.

## Handoff Checklist

For each replacement asset:

1. Keep the same asset `id`, or update all data references deliberately.
2. Match the manifest type: `sprite_sheet`, `portrait`, `background`, `image`, or `card_motif`.
3. Match frame metadata.
4. Confirm the file imports in Godot.
5. Open the Asset Gallery scene.
6. Open the scene that uses the asset.
7. Check that the image is not cropped, tiny, blurry, or offset.

## Validation

Phase 10 validation checks:

```txt
Godot loads the project with asset_manifest.json.
Asset Gallery can load the production-facing manifest.
DataRegistry still resolves existing asset IDs.
Temporary manifest remains available as fallback/reference.
```

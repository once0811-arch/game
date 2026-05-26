# Temporary Pixel Assets

Generated for Phase 0 as replaceable Godot integration art.

Current pass: `temp_pixel_voxel_v2`

- Stronger 2D pixel-art silhouettes with a pseudo-voxel 3/4 read.
- Cold blue-gray survival palette with warm fire and late-game green/purple corruption accents.
- Sprite sheets keep the same manifest IDs and Godot paths.
- Generated sheets use agent-sprite-forge postprocessing for chroma-key cleanup and frame extraction.
- Final art can replace these files by preserving manifest IDs or updating the manifest.

Phase 10 replacement rule:

- Game code should request art by `asset_id`, not by direct file path.
- `SourceCode/data/assets/asset_manifest.json` is the production-facing manifest.
- `SourceCode/data/assets/temp_asset_manifest.json` remains the temporary source/reference manifest.
- Final art may either overwrite the temp paths during early production or point `asset_manifest.json` to a new final-art folder.
- Preserve frame sizes, row/column counts, anchors, and transparent backgrounds unless a scene is deliberately updated.

# Phase 10 Asset Pipeline Report

## Result

Phase 10 makes temporary art replaceable without changing gameplay data.
The project now has a production-facing asset manifest and a written handoff guide for the art director.

## Implemented Scope

- Added `SourceCode/data/assets/asset_manifest.json`.
- Updated `DataRegistry` to load `asset_manifest.json` as the default asset source.
- Updated `AssetRegistry` so the Asset Gallery uses the production-facing manifest and falls back to the temporary manifest.
- Updated `SourceCode/assets/temp_pixel/README.md` with replacement rules.
- Added `docs/asset_replacement_guide.md`.
- Advanced project balance phase to 10.

## Pipeline Rule

Gameplay and content data should reference art by stable asset IDs.
The manifest owns the file path.

This means final art can move from:

```txt
SourceCode/assets/temp_pixel/
```

to:

```txt
SourceCode/assets/final_pixel/
```

by changing `asset_manifest.json`, not by rewriting scene scripts.

## Review

What works:

- Existing scenes still load through asset IDs.
- Asset Gallery can read the new production-facing manifest.
- The temporary manifest remains as fallback/reference.
- The art director has one guide for naming, frame metadata, palette direction, and validation.

Risks:

- Some scripts still call `get_temp_asset_path` by name, even though the implementation now loads the production manifest.
  This is a naming cleanup issue, not a functional blocker.
- Final animation sheets must preserve frame metadata unless scenes are updated deliberately.
- Asset Gallery is still a debug inspection tool, not a full art QA dashboard.

Improvement applied in this phase:

- The manifest boundary is now explicit.
- Temp assets can be replaced path-by-path.
- Direct file path coupling did not increase during implementation.

## Validation

Automated checks performed:

```txt
asset_manifest.json parses: pass
asset_manifest asset count matches temp manifest: pass
required asset IDs resolve: pass
Godot headless project load: pass
Godot headless Asset Gallery load: pass
Godot headless map/combat/shop screen load: pass
git diff --check: pass
```

## Next Work

The planned phase list is now implemented through Phase 10.
The next practical work should be hands-on Godot playthrough QA, followed by telemetry-driven balance patches and UI polish.

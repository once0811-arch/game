# Kenney UI Asset Integration Pass

Date: 2026-05-27

## Source Assets

- Kenney UI Pack
  - Source: https://kenney.nl/assets/ui-pack
  - License: CC0 1.0 Universal, copied into `SourceCode/assets/vendor/kenney_ui/licenses/LICENSE.txt`
- Kenney Playing Cards Pack
  - Source: https://kenney.nl/assets/playing-cards-pack
  - License: CC0 1.0 Universal, already recorded in `SourceCode/assets/temp_pixel/vendor_licenses/Kenney_Playing_Cards_Pack_LICENSE.txt`

## Integrated Files

The UI pass now uses real Kenney assets instead of only procedural `StyleBoxFlat` surfaces.

- `SourceCode/assets/vendor/kenney_ui/buttons/button_primary.png`
- `SourceCode/assets/vendor/kenney_ui/buttons/button_default.png`
- `SourceCode/assets/vendor/kenney_ui/buttons/button_success.png`
- `SourceCode/assets/vendor/kenney_ui/buttons/button_danger.png`
- `SourceCode/assets/vendor/kenney_ui/buttons/button_blue.png`
- `SourceCode/assets/vendor/kenney_ui/buttons/input_panel.png`
- `SourceCode/assets/vendor/kenney_ui/fonts/Kenney_Future.ttf`
- `SourceCode/assets/vendor/kenney_ui/fonts/Kenney_Future_Narrow.ttf`

## Applied Screens

- Global buttons now use Kenney texture-backed `StyleBoxTexture` states.
- Global labels and buttons now use the Kenney Future font when available.
- Shop cards now show card/equipment/service icons from the asset manifest.
- Inn rooms now show rest/recovery icons.
- Event choices now show effect-type icons.
- Upgrade choices now show upgrade/health/companion icons.
- Companion and oath selection panels can use the shared asset-backed panel style.

## Current QA Notes

- Shop 1280 layout was changed to six columns to avoid the third row clipping after icon assets were added.
- Reward and companion card screens still need a dedicated large-card presentation pass; they use real Kenney card frames, but long rules text can still be clipped or too dense.
- Next high-leverage art task: replace the remaining generated character/background placeholders with curated CC0 sprite/environment packs or handoff-quality generated sheets.

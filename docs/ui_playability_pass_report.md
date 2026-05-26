# UI Playability Pass Report

## Why This Pass Happened

The previous screens were functional debug panels, not playable game UI.
The Act route screen in particular exposed test buttons, weak hierarchy, and flat default controls, which made the project look broken even when systems were connected.

## Changed Screens

- Main menu
- Act route map
- Combat
- Card reward
- Companion recruitment
- Oath tactic selection
- Companion card selection
- Shop
- Inn
- Event
- Upgrade selection
- Ending

## Main Improvements

- Added a shared UI style helper at `SourceCode/scripts/ui/ui_style.gd`.
- Replaced default-looking panels/buttons with consistent dark parchment panels, warm borders, card-like buttons, and clearer disabled states.
- Removed debug navigation buttons from the normal main menu and route map.
- Rebuilt the route screen around a readable header, route panel, party panel, and equipment panel.
- Rebuilt combat around a clearer player/enemy/log/hand layout.
- Added combat feedback toasts for oath triggers, bond gains, Kyle wagers, victory, and defeat.
- Replaced the combat companion text line with compact companion tiles showing portrait, oath, bond, and base attack.
- Upgraded companion recruitment and oath selection from plain buttons into contract-style cards with portraits and readable role/rules text.
- Restyled reward and choice screens so options read as deliberate cards rather than plain buttons.
- Kept layout constraints simple enough to remain readable at the current project window size.

## Current Design Direction

The UI is now using broad deckbuilder readability conventions:

- Clear route progression.
- Card-shaped choices.
- Strong end-turn and continue actions.
- Compact run resources.
- Persistent warm/cold survival palette.

It does not attempt to copy another game's exact visual trade dress.

## Remaining UI Risks

- This is still procedural Godot UI, not a final authored scene layout.
- Card text can still become crowded as effects get longer.
- Combat still needs full attack/block/heal animation and sound.
- Shop and upgrade services still need card picker UI instead of automatic targets.
- Pixel art quality remains temporary and will strongly affect perceived polish.

## Validation

Godot headless scene loads passed for:

```txt
main
map
combat
shop
inn
event
card reward
companion reward
oath tactic select
companion card select
upgrade select
ending
```

`git diff --check` also passed.

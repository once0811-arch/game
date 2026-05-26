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

## Reference-Based UI Pass

The follow-up pass compared the project against Slay the Spire-style route and battle screens instead of only fixing overlaps.
Reference points used:

- Slay the Spire map screen: parchment route, icon-only nodes, dotted connection lines, right-side legend, only reachable next rooms emphasized.
- Slay the Spire combat screen: full battlefield composition, player left, enemies center/right, hand arced along the bottom, end-turn button near the battlefield instead of a debug control row.
- Godot deckbuilder references: map rooms expose `next_rooms`, and only legal next locations become interactable.

Implemented changes:

- Added generated `next_ids` to map nodes and made `MapState.get_node_state()` respect actual route reachability.
- Replaced the route grid buttons with compact icon tokens, dashed path lines, and a legend.
- Replaced weak temporary node and card motif art with Kenney Board Game Icons CC0 assets.
- Rebuilt combat out of the three-column debug-panel layout into a battlefield-first layout with player, enemy, companion tile, compact last-move log, and bottom hand.
- Added `SourceCode/tools/visual_capture.gd` so Codex can render Godot scenes to PNG and visually inspect map/combat output during implementation.

## Latest Visual QA Pass

The current pass focused on making the normal playable loop showable inside the Godot editor without debug navigation:

- Combat now uses a bottom card fan, readable enemy intent, clickable enemy panels, invalid-action feedback, and compact companion tiles.
- The route map now reads bottom-to-top like a climb toward the Act boss, with icon-only nodes, subdued future paths, and highlighted reachable/cleared route state.
- Shop layout responds to wide screens so products do not sit in a narrow debug-looking column.
- Oath tactic selection now captures the actual companion-selected state and displays the selected companion, fixed oath clauses, and readable contract rules.
- Card reward and companion card selection use the same card component as combat, with tighter card text spacing to avoid clipping.
- Visual captures passed at 1280x720 for main, map, combat, reward, companion recruitment, oath tactic, companion card selection, shop, inn, event, and upgrade.
- Visual captures passed at 1920x1080 for map, combat, and shop.

## Scene-First Rework After Screenshot Review

The next review found that the screens were still too information-panel driven.
The correction target is now closer to Slay the Spire's screen grammar without copying its exact art or trade dress.

Combat rules from this pass:

- The battlefield is the screen, not a panel inside the screen.
- The player and enemies stand directly on the scene.
- Enemy UI is limited to intent, name, HP bar, and HP value.
- Enemy target frames are hidden during idle state and should only appear during card targeting feedback.
- Companion data is collapsed into small contract/relic-style icons with hover text instead of a readable info card.
- The top HUD shows only run-critical resources.
- The hand is the dominant interactive object at the bottom, with energy and End Turn placed like permanent combat affordances.
- Long logs and raw pile details are not part of the normal combat view.

Map rules from this pass:

- The parchment route is the screen's main object.
- The route can be taller than the viewport; do not compress all 12 floors into one screen.
- On entry, the map should auto-scroll to the currently available floor so the next decision is readable first.
- Node labels stay hidden until hover/tooltip.
- The default footer prompt must stay short.
- Future paths remain quiet; reachable paths use warm contract-token emphasis.
- The side legend is allowed, but party/equipment/debug panels are not part of the route screen.

Implemented in this pass:

- Replaced the Act 1 battle background with a darker ruined-stage composition that provides a horizon, floor plane, warm torches, and readable actor silhouettes.
- Replaced the map background with a darker table/route motif so the parchment reads as a physical map rather than a UI card on flat color.
- Removed idle enemy panel framing from combat.
- Increased combat card size and art area so cards read more like game cards than text buttons.
- Reduced combat/map explanatory text and moved companion details into compact icon tooltips.
- Converted the Act route into a vertical scroll map so nearby route choices stay large instead of compressing the full act into a dense chart.
- Captured and inspected combat and map at 1280x720 and 1920x1080 after the rework.

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
- Very long card text can still become crowded as effects get more complex.
- Combat still needs full attack/block/heal animation and sound.
- Shop and upgrade services still need card picker UI instead of automatic targets.
- Actor/background pixel art quality remains temporary and will strongly affect perceived polish.

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

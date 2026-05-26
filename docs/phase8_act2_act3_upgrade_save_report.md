# Phase 8 Act 2/3, Upgrade, and Save Report

## Result

Phase 8 adds the first complete 3-act run skeleton.
The game can now move from Act 1 into Act 2, trigger the Act 2 midpoint upgrade, branch Act 2 boss rewards into a major upgrade, enter Act 3, and route the Act 3 boss victory to an ending screen.

## Implemented Scope

- Added Act 2 and Act 3 encounter data with 12 nodes each.
- Added Act 2 and Act 3 enemy data.
- Added Act 2 and Act 3 boss data in `data/bosses/bosses.json`.
- Generalized map generation from Act 1 only to Act 1/2/3.
- Added Act transition support to `MapState`.
- Added protagonist/companion upgrade service.
- Added upgrade state and upgrade selection screen.
- Added ending screen after Act 3 boss victory.
- Extended save snapshots with protagonist upgrade level and run completion state.
- Kept existing map snapshot save/load path compatible with equipment and act data.

## Act Flow

Current high-level progression:

```txt
Act 1 depth 6 midboss -> first companion contract node
Act 1 boss -> second companion contract -> Act 2
Act 2 depth 6 upgrade node -> minor upgrade
Act 2 boss -> major protagonist/companion/armory upgrade -> Act 3
Act 3 boss -> ending screen
```

This keeps the user's requested companion pacing intact:

- First companion after Act 1 midpoint boss.
- Second companion after Act 1 boss.
- Act 2 midpoint is upgrade timing, not a new companion.
- Act 2 boss reward is a major upgrade choice.

## New Data

Added:

```txt
data/enemies/enemies_act2.json
data/enemies/enemies_act3.json
data/bosses/bosses.json
data/encounters/act2_encounters.json
data/encounters/act3_encounters.json
```

Act 2 introduces Healing Down enemies so the Phase 7 healing counter-system becomes visible.
Act 3 uses more non-human, reality-bent enemy names while still reusing temporary Phase 0 assets.

## Upgrade Rules

Act 2 midpoint upgrade options:

- Field Conditioning: max HP +5 and heal 5.
- Shared Watch: all companions gain 10 bond.
- Sharpen the Plan: upgrade the first unupgraded card.

Act 2 boss major upgrade options:

- Mercenary Promotion: max HP +10, heal 10, and upgrade a card.
- Shared Command: all companions gain 20 bond and +1 basic attack.
- Regent's Armory: gain a random rare equipment.

Current limitation:

Card upgrades still use automatic target selection.
This is acceptable for the run skeleton, but shop and upgrade services should share a real card-picker screen in a future pass.

## Save/Load

Run snapshots now include:

```txt
act
depth
gold
current/max HP
protagonist upgrade level
run completion state
party
deck
combat
equipment inventory and equipped gear
map snapshot
```

Map snapshots include the current act, nodes, selected node, selected enemy, and current depth.

## Balance Review

What works:

- The long-term structure now matches the design: companion systems open early, then upgrades deepen the build instead of adding more party members.
- Healing Down appears in Act 2/3 enemy data, giving inns and weak healing cards clearer boundaries.
- Major upgrades are deliberately chunky enough to feel like boss rewards without adding removed systems like relics or potions.
- Act 3 has a functional endpoint, which lets playtesting measure full-run pacing.

Risks:

- Enemy numbers are still first-pass estimates and need Phase 9 telemetry.
- Act 2/3 enemy art reuses Act 1 temporary assets, so visual readability is placeholder-only.
- Act transition flow is functional, but it needs hands-on Godot clicking to confirm the whole user journey feels smooth.
- Upgrade choices need better UI targeting before they become a satisfying build-defining system.

Improvement applied in this phase:

- Act progression is now data-driven by encounter files instead of hardcoded Act 1 assumptions.
- Boss reward routing now differs by act.
- Companion attack upgrades are connected to the Phase 6 companion combat system.
- Save data now covers the new long-run state added by Phase 7 and Phase 8.

## Godot Check

Manual check path:

1. Open the Godot project at `SourceCode`.
2. Start a new run and clear Act 1 boss.
3. Recruit the second companion and confirm the map advances to Act 2.
4. Reach Act 2 depth 6 and choose an upgrade.
5. Clear Act 2 boss and choose a major upgrade.
6. Confirm the map advances to Act 3.
7. Clear Act 3 boss and confirm the ending screen appears.
8. Save on the map, return to main menu, and continue the saved run.

## Validation

Automated checks performed:

```txt
Godot headless project load: pass
Godot headless map screen load: pass
Godot headless combat screen load: pass
Godot headless shop screen load: pass
Godot headless inn screen load: pass
Godot headless event screen load: pass
Godot headless upgrade screen load: pass
Godot headless ending screen load: pass
Phase 8 data validation: pass
git diff --check: pass
```

## Next Phase

Phase 9 should add telemetry and balance notes.
The first metrics should track turn count, HP loss, card reward pick/skip, shop purchases, inn usage, companion choice, oath trigger counts, and bond score at boss checkpoints.

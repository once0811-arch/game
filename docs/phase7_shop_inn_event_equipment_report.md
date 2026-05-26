# Phase 7 Shop, Inn, Event, and Equipment Report

## Result

Phase 7 adds the first playable non-combat decision layer.
The run now has equipment inventory, shop purchases, inn rooms, Act 1 events, combat gold rewards, and map routing for shop/inn/event nodes.

## Implemented Scope

- Added `data/equipment/equipment.json` with 9 equipment items across helmet, armor, and weapon slots.
- Added `data/events/events_act1.json` with 4 Act 1 event templates and 3 choices each.
- Added equipment inventory state to `RunState` and save snapshots.
- Added map-screen equipment display and cycle-equipping.
- Added shop screen with cards, companion cards, equipment, and card services.
- Added inn screen with normal/event inn room generation.
- Added event screen with effect resolution.
- Added combat gold rewards by node type.
- Added Healing Down status support for future enemies.
- Connected shop, inn, and event nodes from the Act 1 map.

## Equipment Rules

Equipment slots:

```txt
helmet
armor
weapon
```

Each valid wearer has all 3 slots:

```txt
protagonist: 3 slots
each recruited companion: +3 slots
```

Current effects:

| Effect | Use |
| --- | --- |
| `attack_damage` | Adds damage to protagonist attack cards when worn by protagonist. |
| `block_card_bonus` | Adds block to protagonist block cards when worn by protagonist. |
| `start_block` | Team starts combat with extra block. |
| `companion_attack_damage` | Companion basic attacks deal extra damage. |
| `shop_discount_percent` | Shop prices are reduced. |

Equipment is not sold back.
The map screen is the current equipment management point, so the player can change gear between nodes.

## Economy

Combat now grants gold:

| Node Type | Gold |
| --- | ---: |
| Combat | 22 |
| Elite | 45 |
| Midboss | 40 |
| Boss | 80 |
| Debug Combat | 0 |

This makes the first Act 1 shop meaningful without requiring the player to skip every card reward.
Expected first-shop gold is now enough for one meaningful purchase and possibly one modest service, while still making inn spending relevant.

## Shop

The shop currently generates:

- 4 protagonist card products.
- Up to 2 owned-companion card products.
- 3 equipment products.
- 4 services: remove, upgrade, transform, copy.

Companion cards only come from recruited companions and exclude cards already in the deck.
Card removal starts at 75 gold and rises by 25 after a successful removal.

Current limitation:

The card services choose an automatic target.
This keeps the phase playable, but a later UI pass should allow the player to pick the exact card.

## Inn

Inn generation:

```txt
normal inn weight: 2
event inn weight: 1
room options: 3
```

Normal inn rooms are predictable healing choices.
Event inn rooms are positive-variance rooms with possible card upgrade or equipment discovery.

The inn is now the main large-heal node.
This preserves the earlier balance rule that combat healing cards should remain weaker or more conditional than inn recovery.

## Events

Current Act 1 events:

- Broken Wagon
- Black Fingerprint
- Lost Smith
- Companion Trace

Effects currently supported:

```txt
gain gold
pay gold
lose HP without killing the player
heal flat amount
heal percentage
gain random equipment
upgrade card
remove card
transform card
copy card
gain companion bond
prepare Healing Down status
```

Events stay short and systemic.
They express the world through contract tags, black fingerprints, field smiths, and road traces without turning the game into a story-heavy flow.

## Balance Review

What works:

- Gold now has real pressure because it can become cards, services, gear, healing, or event choices.
- Equipment gives build identity without adding artifact/potion systems that were removed from our design.
- Inns and healing cards have different jobs: inns give larger route-level recovery, cards give smaller in-combat stability.
- Companion cards in shops strengthen the companion system without forcing random deck pollution.

Risks:

- Auto-target card services are functional but less satisfying than direct card selection.
- Equipment effects are simple numeric hooks, so visual feedback should be added later.
- The first shop may become too generous if the player receives many event gold rewards before depth 10.
- Healing Down exists in the resolver but needs Act 2 enemies to make it strategically visible.

Improvement applied in this phase:

- Shop discounts are equipment-driven rather than a separate relic-like system.
- Companion attack equipment plugs into the Phase6 companion combat loop.
- Event losses are capped so they cannot kill the player or ruin a run outright.
- Inn event variance is positive or mixed-light, matching the design rule that event inns are not hidden traps.

## Godot Check

Manual check path:

1. Open the Godot project at `SourceCode`.
2. Start a run and enter the Act 1 map.
3. Use the Event, Inn, and Shop map nodes or debug buttons to inspect each screen.
4. Buy equipment in the shop, return to the map, and equip it from the equipment panel.
5. Enter combat and confirm equipment bonuses affect attack, block, start block, or companion attacks.
6. Use an inn room and confirm gold/HP changes.
7. Use an event choice and confirm its result is reflected in run state.

## Validation

Automated checks performed:

```txt
Godot headless project load: pass
Godot headless map screen load: pass
Godot headless combat screen load: pass
Godot headless card reward screen load: pass
Godot headless shop screen load: pass
Godot headless inn screen load: pass
Godot headless event screen load: pass
JSON validation: pass
Phase 7 data validation: pass
git diff --check: pass
```

## Next Phase

Phase 8 should expand the run toward Act 2/3, save coverage, and major upgrade timing.
The most important follow-up is replacing automatic card service targets with a real card selection UI before shop decisions become too central.

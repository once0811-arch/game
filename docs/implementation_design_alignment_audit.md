# Implementation / Design Alignment Audit

Date: 2026-05-26

## Goal

Compare the current Godot project against the design documents and fix whichever side is wrong: update docs when they describe a future target, update implementation when the playable build fails the core promise.

The core promise remains:

```txt
A real playable roguelike deckbuilder where the player drafts companions, chooses one oath tactic per companion, uses cards by click/drag targeting, and builds a survival party through a dying road.
```

## External References Used

- [Kenney Playing Cards Pack](https://kenney.nl/assets/playing-cards-pack): free CC0 card/UI-adjacent assets, 270 files.
- [Kenney UI Pack](https://kenney.nl/assets/ui-pack): free CC0 UI assets, 430 files.
- [Godot AtlasTexture documentation](https://docs.godotengine.org/en/4.2/classes/class_atlastexture.html): used to crop sprite sheets into a single visible frame for TextureRect usage.
- [Godot 4.6 feature documentation](https://docs.godotengine.org/en/4.6/about/list_of_features.html): confirms Control UI, Theme, StyleBoxFlat, and texture-based theming are engine-native paths.

## Main Findings

| Area | Document Promise | Previous Implementation | Decision |
|---|---|---|---|
| Starting run numbers | 76 HP, 99 gold | 75 HP, 80 gold | Implementation updated to 76/99. |
| Starting deck | 5 attacks, 4 guards, 1 tactical card | 4 attacks, 4 guards, Tactical Prep, Heavy Cut | Implementation updated to 5/4/1. Heavy Cut moved to reward pool. |
| Companion roster | 10 companions | 5 companions | Implementation updated to 10 companions. |
| Companion cards | Final target 8 per companion | 3 per 5 companions | Implementation updated to 3 per 10 companions; docs clarify 8 each is content-complete target. |
| Oath tactics | 3 selectable per companion, chosen oath is fixed | Rowan/Sera/Eldric had hooks; Bram/Maren were mostly text only | Implementation updated so all 30 current oath tactics have combat/economy hooks. |
| Kyle economy | Random wager option, not fixed per-combat income | Design-only | Implementation added 5-win wager with baseline, clean-exit, and loaded-coin variants. |
| Companion reward | 3 candidates | First candidates in data order | Implementation updated to random 3 candidates excluding owned companions. |
| Main menu | Player-facing title screen | Debug counts exposed cards/assets/enemies | Implementation removed debug counts from normal UI. |
| Combat sprites | Character should appear as one actor | Sprite sheets could appear as whole sheets | Implementation added AtlasTexture frame extraction for sprite-sheet assets. |
| Art direction docs | MVP 3 companions in several places | Godot now exposes 10 candidates | Docs updated to "initial validation companions" plus 10-companion playable roster. |

## Balance Changes Applied

The current implementation favors clarity over final content volume.

```txt
Energy / draw: 4 energy, 6 draw remains.
Intent: more choice per turn, not "play every card every turn".
Starter deck: low-cost baseline plus one 0-cost tactical card.
Companion cards: 3 per companion for the playable slice.
Oath tactics: mostly +1 draw, +1 energy once, +2~4 oath damage, +1~5 block, or heal 1~2.
Bond: 30/60/100 stays mild, because two companions can be active.
Kyle: average payout should be modest; jackpot is allowed to make a run easier.
```

## Current Playable Companion Slice

| Companion | Base Attack | Play Pattern |
|---|---:|---|
| Rowan | 5 | Marked-target pressure. |
| Sera | 4 | Tempo, 0-cost cards, second-card triggers. |
| Eldric | 3 | Defensive consistency. |
| Bram | 6 | Self-damage risk for damage/energy. |
| Maren | 2 | Weak healing plus block and refund utility. |
| Tor | 4 | Heavy block and low-HP survival. |
| Lina | 4 | Tactical Mark amplification and skill triggers. |
| Noa | 3 | Draw and card-count rhythm. |
| Isol | 2 | Crisis healing and protection. |
| Kyle | 3 | Delayed random wager economy. |

## Remaining Gaps

These are not blockers for the current playable build, but they are the next places where "real game" feel can break.

1. Companion and enemy art still needs stronger silhouettes and animation polish.
2. Current companion cards are 3 per companion; final variety needs 8 per companion.
3. Oath tactics currently show mostly through logs and numbers. They need compact icon flashes, metal-tag reactions, and clearer battlefield feedback.
4. Combat telemetry records oath trigger counts but not value gained per trigger.
5. Card pool is still too small to judge long-term deck variety.
6. The route map and reward screens are playable, but they still need the same quality pass as combat cards and main UI.

## Next Build Priority

```txt
1. Verify all current scenes load in Godot after the data expansion.
2. Play through Act 1 and record whether first companion choice changes card decisions immediately.
3. Add visible oath trigger feedback beyond text logs.
4. Upgrade enemy/companion silhouettes with better free or generated temporary art.
5. Expand protagonist cards from 12 toward the 40-card target only after combat readability is stable.
```

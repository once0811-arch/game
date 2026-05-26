# Phase 6 Companion Combat and Bond Report

## Result

Phase 6 adds the first playable version of companion combat behavior, oath tactics, and bond progression.
The goal of this phase is not to make companions a passive stat bonus, but to make them change turn rhythm and target priorities inside combat.

## Implemented Scope

- Companions perform one basic attack after the player ends the turn.
- Companion attacks prefer enemies with the highest Tactical Mark.
- Companion base attack values are defined in `data/companions/companions.json`.
- All 10 current companions have three selectable oath tactics with combat hooks.
- Kyle's economy is a 5-win wager payout, not a fixed reward after every battle.
- Bond score rises after combat victory and stays in the 0-100 range.
- Bond bonuses at 30, 60, and 100 points are applied in combat.
- The combat screen now shows a compact companion panel with oath and bond status.

## Combat Rules

Companion attacks happen after the player discards their hand and before enemies act.
This keeps companions visible without taking over the card-play portion of the turn.

Current base attacks:

| Companion | Base Attack |
| --- | ---: |
| Rowan | 5 |
| Sera | 4 |
| Eldric | 3 |
| Bram | 6 |
| Maren | 2 |
| Tor | 4 |
| Lina | 4 |
| Noa | 3 |
| Isol | 2 |
| Kyle | 3 |

The current target rule is simple and readable:

1. Choose a living enemy.
2. Prefer the enemy with the highest Tactical Mark.
3. If marks are tied, use the first living enemy.

This makes mark cards and Rowan-style tactics matter without adding a manual companion targeting UI yet.

## Oath Tactics

The selected oath tactic is fixed after recruitment and has no upgrade path.
Only the recruited companion's selected oath is active.

Implemented hooks:

| Companion | Oath | Current Effect |
| --- | --- | --- |
| Rowan | Red Pursuit | Companion attack deals bonus damage to a marked target. |
| Rowan | First Blood | First marked-target companion hit in a combat gains bonus damage. |
| Rowan | Spear Line | Companion attack applies Tactical Mark. |
| Sera | Second Cut | The second played card each turn deals oath damage. |
| Sera | Quick Claim | First 0-cost card each combat applies Tactical Mark. |
| Sera | Smoke Step | Combat start grants block based on opening hand size. |
| Eldric | Oathwall | Combat start reduces incoming enemy attack damage. |
| Eldric | Shared Guard | Block cards grant additional block. |
| Eldric | Last Stand | Block cards grant more block while player HP is low. |
| Bram | Blood Wager | Self-damage cards deal extra oath damage. |
| Bram | Hard Bargain | First self-damage card each combat refunds energy. |
| Bram | Red Laugh | First kill assisted by Bram each combat heals HP. |
| Maren | Measured Care | Healing cards also grant block. |
| Maren | No Free Debt | First healing card each combat refunds energy. |
| Maren | Clean Bandage | First block card each turn heals 1. |
| Tor | Shield Rent | Block cards grant more block. |
| Tor | Low Stance | Low-HP combat start grants block. |
| Tor | Mark Break | Marked target companion hit deals extra oath damage. |
| Lina | Green Pin | Tactical Mark cards apply an extra Mark. |
| Lina | Bitter Dose | First skill card each turn deals small oath damage. |
| Lina | Last Leaf | Healing cards also apply Tactical Mark. |
| Noa | Star Count | Third card each turn draws a card. |
| Noa | First Read | Combat start draws a card. |
| Noa | Zero Map | First 0-cost card each combat grants energy. |
| Isol | White Guard | First healing card each combat grants block. |
| Isol | Lantern | Low-HP combat start heals. |
| Isol | Mercy Line | First block card each turn heals 1. |
| Kyle | Five Hand | Every 5 combat wins pays a random wager reward. |
| Kyle | Clean Exit | High-HP victories count double toward the wager. |
| Kyle | Loaded Coin | Wager average is worse but jackpot is larger. |

The effects are intentionally modest.
The oath should open a tactical lane, not replace deckbuilding.

## Bond Progression

Bond is a 0-100 score.
It increases from combat outcomes and eventually should also rise from events, inns, and companion choices.

Current victory gains:

| Node Type | Bond Gain |
| --- | ---: |
| Debug Combat | 6 |
| Combat | 8 |
| Elite | 12 |
| Midboss | 12 |
| Boss | 20 |

Current thresholds:

| Bond | Bonus |
| ---: | --- |
| 30 | Companion basic attack gains +1 damage. |
| 60 | Start of player turn grants +2 block. |
| 100 | Companion action applies +1 Tactical Mark. |

These values are deliberately small because the party can have two companions.
The system should create a sense of attachment and build identity without making one early companion snowball the whole run.

## Balance Review

What works:

- Companion turns now create an end-turn payoff, so the player cares about whether an enemy is marked before ending.
- Bond thresholds give a soft long-term reward without forcing grind behavior.
- Oath tactics are tied to card usage, marks, or defense timing, which keeps them inside the deckbuilder loop.
- All current companions now read differently in combat instead of being cosmetic roster entries.

Risks:

- There is no manual companion targeting UI yet, so target logic must stay transparent.
- Some oath tactics are still numeric hooks rather than distinct animations or bespoke feedback.
- Bond bonuses are intentionally mild; if playtests feel flat, the 60 or 100 thresholds may need more visible effects.
- Healing and injury pressure are not fully tested until inn, event, and enemy status systems exist.
- Kyle's wager needs telemetry follow-up because rare jackpot outcomes are intentionally allowed to make a run easier.

Improvement applied in this phase:

- Companion attacks do not simply hit the first enemy forever.
  They key off Tactical Mark, so existing combat choices influence companion behavior.
- Bond 30/60/100 bonuses are functional now instead of only documented.
- Enemy attack reduction from oath protection is resolved inside the enemy turn, so defensive oath tactics can be felt immediately.

## Godot Check

Manual check path:

1. Open the Godot project at `SourceCode`.
2. Start a run and reach the Act 1 midboss companion reward flow.
3. Recruit a companion and choose one oath tactic.
4. Enter combat and confirm the companion panel appears.
5. End the turn and confirm companion attack logs appear before enemy actions.
6. Apply Tactical Mark to an enemy and confirm companions prefer that target.
7. Win combat and confirm bond score increases.

## Validation

Automated checks performed:

```txt
Godot headless project load: pass
Godot headless combat screen load: pass
Godot headless map screen load: pass
Godot headless companion reward screen load: pass
Data validation phase=6: pass
Companion base_attack/oath count validation: pass
git diff --check: pass
```

## Next Phase

Phase 7 is the next work item.
It should implement equipment, shop, inn, and event screens so non-combat choices start changing the direction of the run.

Phase 7 should prioritize:

- Equipment inventory and slot rules.
- Shop products, purchase flow, and card services.
- Normal inn and event inn room choices.
- Companion trace events.
- Heal reduction status pressure so healing cards and inns do not collapse into the same role.

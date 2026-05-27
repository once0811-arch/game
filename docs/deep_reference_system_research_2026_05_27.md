# Deep Reference System Research - 2026-05-27

## Purpose

This document records a reference-based audit of the current Godot deckbuilder. The goal is to avoid gut-feel tuning and identify what still blocks the project from feeling like a real, replayable roguelike deckbuilder.

The key question:

```txt
What systems are still too thin compared with proven deckbuilding roguelikes, and what should we build next without violating our own design constraints?
```

## Sources

External gameplay references:

- [Slay the Spire - Steam](https://store.steampowered.com/app/646570/Slay_the_Spire/)
- [Slay the Spire - Gameplay wiki](https://slay-the-spire.fandom.com/wiki/Gameplay)
- [Slay the Spire - Cards wiki](https://slay-the-spire.fandom.com/wiki/Cards)
- [Slay the Spire - Intent wiki](https://slay-the-spire.fandom.com/wiki/Intent)
- [Slay the Spire - Map locations wiki](https://slay-the-spire.fandom.com/wiki/Map_locations)
- [Slay the Spire - Rest Site wiki](https://slay-the-spire.fandom.com/wiki/Rest_Site)
- [Slay the Spire - Bosses wiki](https://slay-the-spire.fandom.com/wiki/Bosses)
- [Slay the Spire - Lagavulin wiki](https://slay-the-spire.fandom.com/wiki/Lagavulin)
- [Slay the Spire - Hexaghost wiki](https://slay-the-spire.fandom.com/wiki/Hexaghost)
- [Analysis of Uncertainty in Procedural Maps in Slay the Spire](https://arxiv.org/abs/2504.03918)
- [STS Tracker - Slay the Spire 2 run stats](https://ststracker.app/)
- [Monster Train - Steam](https://store.steampowered.com/app/1102190/Monster_Train/)
- [Monster Train - Merchants wiki](https://monster-train.fandom.com/wiki/Merchants)
- [Monster Train - Champions wiki](https://monster-train.fandom.com/wiki/Champions)
- [Monster Train - Artifacts wiki](https://monster-train.fandom.com/wiki/Artifacts)
- [Wildfrost - Companions wiki](https://wildfrostwiki.com/Companions)
- [Wildfrost - Charms wiki](https://wildfrostwiki.com/Charms)
- [Griftlands - Grafts wiki](https://griftlands.fandom.com/wiki/Grafts)
- [Griftlands - Negotiation wiki](https://griftlands.fandom.com/wiki/Negotiation)

Reference repositories mined:

- [guladam/deck_builder_tutorial](https://github.com/guladam/deck_builder_tutorial) - MIT
- [DesirePathGames/Slay-The-Robot](https://github.com/DesirePathGames/Slay-The-Robot) - MIT
- [chun92/card-framework](https://github.com/chun92/card-framework) - MIT
- [statico/godot-roguelike-example](https://github.com/statico/godot-roguelike-example) - MIT

Local sources:

- `docs/godot_deckbuilder_master_spec.md`
- `docs/playtest_balance_notes.md`
- `docs/implementation_design_alignment_audit.md`
- `docs/slay_the_spire_uiux_element_analysis.md`
- `SourceCode/data/balance_constants.json`
- `SourceCode/data/cards/protagonist_cards.json`
- `SourceCode/data/cards/companion_cards.json`
- `SourceCode/data/companions/companions.json`
- `SourceCode/data/enemies/enemies_act1.json`
- `SourceCode/data/enemies/enemies_act2.json`
- `SourceCode/data/enemies/enemies_act3.json`
- `SourceCode/data/bosses/bosses.json`
- `SourceCode/data/events/events_act1.json`
- `SourceCode/data/equipment/equipment.json`
- `SourceCode/data/playtest_logs/balance_run_simulation_latest.json`
- `SourceCode/scripts/combat/combat_screen.gd`
- `SourceCode/scripts/combat/card_effect_resolver.gd`
- `SourceCode/scripts/combat/enemy_ai_resolver.gd`

## Design Constraints To Preserve

The master spec intentionally removes some Slay the Spire systems:

```txt
No relics.
No potions.
No curses.
No status cards.
No combat card generation.
No ascension mode for now.
No daily/custom/leaderboard/meta score systems.
No user-facing seed input.
```

This means the answer is not "copy Slay the Spire systems back in." The answer is to provide equivalent decision pressure through our own pillars:

```txt
Companions
Oath tactics
Bond score
Equipment slots
Contract/token consequences
Route attrition
Inn/shop/event tradeoffs
Enemy roles and boss tests
```

## Benchmark Findings

### Slay the Spire

Slay the Spire's public Steam page advertises 350+ implemented cards, 200+ items, 50+ combat encounters, and 50+ events. That content scale matters, but the more important design pattern is how every screen supports a run decision:

- Combat baseline: 5 cards drawn, 3 energy, discard at turn end.
- Card rewards: choose 1 of 3 after combat.
- Elite reward: harder fight plus an extra high-impact reward.
- Shop: fixed categories, one sale card, card removal cost starts at 75 and rises by 25.
- Rest Site: one choice, normally heal 30% max HP or upgrade one card.
- Boss: strong unique mechanics, major reward, and full heal after Act 1/2 bosses.
- Intent: enemy next action is exposed before the player acts.

Useful system lesson:

```txt
The game is not hard because every enemy has high HP.
It is hard because enemy patterns ask different deck questions:
Can you burst before scaling?
Can you survive multi-hit attacks?
Can you handle deck pollution?
Can you race a timer?
Can you absorb debuffs?
Can you path to enough upgrades without dying?
```

Important enemy examples:

- Lagavulin starts asleep, grants itself block, then attacks twice and debuffs strength/dexterity. This is a setup window plus a race.
- Hexaghost has a deterministic flame cycle, uses current-HP-based opening damage, adds Burns, and becomes a timer fight.

Implication for us:

```txt
Our enemies should not remain "attack/block/healing_down loop" variants.
Each notable enemy needs a deck test and a route purpose.
```

### Monster Train

Monster Train emphasizes route-side specialization and permanent card modification:

- Steam page highlights route choices that grant different benefits: champion upgrade, unit recruitment, card upgrade, passive bonuses, card duplication.
- It has 220+ cards, 5 clans, 10 starter decks, multiple champion upgrades, and any card can be upgraded twice.
- Merchants split upgrade roles: unit upgrades, spell upgrades, artifact/trinket shopping, and card removal.
- Card removal cost rises across the run.

Useful system lesson:

```txt
A run becomes memorable when upgrades change what the deck is, not just make numbers larger.
```

Implication for us:

```txt
Act 2 midpoint and boss upgrades should become build-defining.
Current protagonist/companion upgrades are still mostly maintenance: HP, bond, attack, upgrade card, rare equipment.
```

### Wildfrost

Wildfrost is the strongest comparison for our companion pillar:

- Companions are persistent battlefield assets rather than disposable cards.
- Companion recruitment is a choice among candidates.
- Charms modify a single card for the run, up to a limit, and attachment order matters.
- The strongest companion/card can become a win condition through focused modification.

Useful system lesson:

```txt
Companion identity becomes exciting when the player can say:
"This run is my Rowan run" or "This run is my Kyle gamble run."
```

Implication for us:

```txt
Three companion cards and one fixed oath tactic are a good demo start, but not enough long-term texture.
Bond thresholds and Act 2 upgrades must visibly specialize the chosen companions.
```

### Griftlands

Griftlands shows an alternate route for "relic-like" long-term power:

- Grafts are installed effects with rarity and upgrades.
- It has separate battle and negotiation systems.
- Keywords such as Draw, Replenish, Improvise, Discard, Expend, Destroy, Incept, and Evoke create tactical texture.

Useful system lesson:

```txt
Long-term passive power can be limited and characterful without becoming Slay-style relic spam.
```

Implication for us:

```txt
Equipment should carry more rule-changing effects.
It can be our controlled replacement for relics if slot limits and tradeoffs stay strict.
```

### Procedural Map Research

The Slay the Spire map uncertainty paper analyzes 20,000 runs and reports that victorious runs are associated with higher normalized path entropy, suggesting successful players take meaningful risks rather than always choosing the safest line.

Implication for us:

```txt
The map should not only offer safe healing.
It should offer route-risk choices where the better long-term line sometimes costs short-term HP.
```

## Current Project Snapshot

### Content Counts

Current implementation:

| Area | Current Count | Reference Read |
| --- | ---: | --- |
| Protagonist cards | 20 | Playable slice, but below the 40-card design target. |
| Companion cards | 30 | 3 per companion. Enough to prove recruitment, not enough for final identity. |
| Companions | 10 | Good roster size for demo. |
| Oath tactics | 30 | Correct structure: 3 per companion, choose 1, no upgrades. |
| Enemies + bosses | 21 | Enough for one pass, but role variety is too narrow. |
| Equipment | 9 | Too small and too stat-focused to replace relics. |
| Events | 4 | Only Act 1 exists; Act 2/3 event texture is missing. |
| Shop services | 4 | Good start: remove, upgrade, transform, copy. |
| Inn options | heal/shop-like room options | Needs sharper rest-vs-growth decisions. |

### Card Shape

Protagonist cards:

```txt
20 total
7 attacks
12 skills
1 power
3 starter / 8 common / 6 uncommon / 3 rare
Cost spread: 0-cost 3, 1-cost 7, 2-cost 5, 3-cost 5
```

Companion cards:

```txt
30 total
3 per companion
Cost spread: 0-cost 3, 1-cost 10, 2-cost 13, 3-cost 4
```

Current effect vocabulary:

```txt
damage
damage_all
block
draw
tactical_mark
gain_energy
lose_hp
heal
gain_gold
power_tactical_mark_bonus
```

Read:

```txt
The game has a working tactical mark core, but the card system is still a narrow arithmetic resolver.
There are almost no conditional cards, no retained cards, no exhaust-like one-combat removal, no innate/opening setup, no on-kill, no overkill, no "if marked" branch, no per-turn trigger cards beyond one power.
```

The spec says no combat card generation/status/curse cards, so we should not add those. But we still need more play texture through allowed mechanics:

```txt
If target is marked
If HP is below threshold
If this is the first/second/third card this turn
If companion attacked this turn
If block was gained this turn
If oath triggered this combat
End of turn trigger
Start of combat trigger
Once per combat
Retain-like holdover if balanced carefully
Exhaust-like "spent for this combat" if named differently in fiction
```

### Enemy Shape

Current enemy intent types across 21 enemies:

```txt
attack: 36
block: 21
healing_down: 8
```

Current enemy patterns are mostly:

```txt
attack/block/attack
attack/attack/block
block/healing_down/attack
healing_down/attack/block
```

Read:

```txt
This is the biggest gameplay-system gap.
Most enemies differ by number and name, not by behavior.
```

Missing enemy roles:

- Setup timer enemy.
- Scaling enemy.
- Multi-hit enemy.
- Summoner or reinforcement enemy.
- Guard/protector enemy.
- Gold thief or route-tax enemy.
- Mark punisher enemy.
- Healing suppressor with counterplay window.
- Companion punisher or oath-corruptor.
- Low-HP swarm enemy.
- High-block armor enemy.
- Boss minion wave controller.

### Current Simulation Read

Latest automatic simulation, 300 runs per policy:

| Policy | Act 1 Boss Clear | Act 2 Boss Clear | Act 3 Boss Clear / Win | Inn HP Before | Inn HP After | Avg Final Deck | Avg Oath Triggers |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| novice | 75% | 25% | 7% | 51% | 76% | 24 | 36 |
| balanced | 100% | 90% | 54% | 35% | 71% | 25 | 115 |
| safe | 100% | 99% | 84% | 51% | 91% | 19 | 86 |
| greedy | 97% | 65% | 32% | 23% | 73% | 25 | 97 |

This superficially matches the user's rough novice target:

```txt
Act 1 boss clear around 70%
Act 2 boss clear around 20-30%
Act 3 boss clear below 10%
```

But this does not mean balance is solved.

Reasons:

1. The automatic runner is not a real player.
2. Content pool is still small.
3. Enemy patterns are too simple.
4. It cannot evaluate visual clarity, target mistakes, excitement, or boredom.
5. It records oath trigger count, but not value gained per trigger.
6. Safe policy win rate is very high, meaning safe routes may still be too stable for skilled play.

Combat pressure details:

```txt
Normal combat avg HP loss: 6.05
Elite avg HP loss: 7.47
Midboss avg HP loss: 8.01
Boss avg HP loss: 15.77
```

Red flags:

```txt
Elites are only about 23% more HP loss than normal combat and have lower defeat rate in the sim.
Midboss has 0% defeat rate, so it may not feel like a meaningful gate.
Two-wave fights currently lose less HP on average than one-wave fights.
Three-wave fights are dangerous enough, but must stay rare and hand-authored.
```

Interpretation:

```txt
The current macro clear-rate target is close for novice simulation.
The actual combat content is still too flat.
Next balance work should add enemy roles and boss mechanics before further global HP/attack inflation.
```

### Code Architecture Read

Current screen/code size:

```txt
combat_screen.gd: 1718 lines
map_screen.gd: 815 lines
shop_screen.gd: 490 lines
inn_screen.gd: 241 lines
event_screen.gd: 128 lines
card_effect_resolver.gd: 111 lines
enemy_ai_resolver.gd: 67 lines
```

Important observation:

```txt
The large file is the screen, while the rules engines are still small.
That is the opposite of where a deckbuilder wants to go.
```

`EnemyAIResolver` currently cycles through listed intents. It has no conditional action, weighted action, phase transition, cooldown, summon, protect, "cannot repeat", or HP-threshold behavior.

`CardEffectResolver` handles simple effect arrays but does not yet have:

- Validators.
- Triggers.
- Keywords.
- Target filters.
- Dynamic card values.
- Card state flags.
- Action queue.
- Per-card play hooks.
- Per-combat temporary card state beyond generic upgrade.

This is acceptable for a prototype. It is not enough for a proud demo with real deckbuilder depth.

## Reference Repo Mining

### guladam/deck_builder_tutorial

License: MIT.

Useful files:

```txt
scenes/enemy/enemy_action.gd
scenes/enemy/enemy_action_picker.gd
scenes/enemy/enemy.gd
custom_resources/intent.gd
```

Transferable pattern:

```txt
Enemy actions are nodes/resources with intent, chance weight, conditional checks, and perform_action.
Enemy UI updates from the selected action.
Damage feedback uses tween/shake/flash, not just text logs.
```

Project decision:

```txt
Adapt the pattern, but keep our JSON data source.
Introduce EnemyPatternAction dictionaries/resources and a resolver that can handle conditional and weighted actions.
```

### DesirePathGames/Slay-The-Robot

License: MIT.

Useful files:

```txt
data/prototype/CardData.gd
autoload/ActionHandler.gd
scripts/ui/Hand.gd
scripts/actions/*
scripts/validators/*
scripts/card_listeners/*
```

Transferable pattern:

```txt
Cards are data-rich objects with play actions, discard actions, end-turn actions, draw actions, exhaust actions, validators, glow validators, listeners, tags, cost shadows, and upgrade definitions.
Actions are queued and can be asynchronous.
```

Project decision:

```txt
Do not copy the whole framework.
Build a smaller "CardAction + CardCondition + CardTrigger" layer compatible with our JSON.
```

### chun92/card-framework

License: MIT.

Useful files:

```txt
addons/card-framework/hand.gd
addons/card-framework/card.gd
addons/card-framework/card_container.gd
addons/card-framework/drop_zone.gd
```

Transferable pattern:

```txt
The hand is a dedicated component with a fixed layout box, fan curves, hover distance, drag state, drop zones, and z-order behavior.
```

Project decision:

```txt
Our combat hand should become a component.
Card layout should not be hand-coded inside combat_screen.gd long term.
```

### statico/godot-roguelike-example

License: MIT.

Useful files:

```txt
assets/data/monsters.csv
src/monster_factory.gd
src/monster_ai.gd
src/combat.gd
```

Transferable pattern:

```txt
Monster data includes species, faction, behavior, stats, sight, intelligence, body flags, and factory setup.
Enemy identity is more than HP and a move list.
```

Project decision:

```txt
Add enemy role/faction/behavior fields to our JSON so encounter generation and art direction can reason about enemy identity.
```

## Main Gaps

### 1. Enemy Design Is Too Flat

Current enemies create attrition, but rarely force a distinct deckbuilding answer.

Priority fix:

```txt
Create an enemy role matrix before adding many more enemies.
Each enemy must have:
role
primary test
counterplay
act purpose
visual silhouette note
intent pattern
budget band
```

Recommended first roles:

| Role | Example Mechanic | Why It Matters |
| --- | --- | --- |
| Bruiser | High visible attack every 2 turns | Forces block planning. |
| Rusher | Low HP, high early damage | Forces early damage picks. |
| Armored | Builds block, vulnerable to mark | Makes Tactical Mark matter. |
| Suppressor | Healing Down with setup tell | Pressures recovery without invalidating heal builds. |
| Corrupter | Reduces bond/oath value for a turn | Makes companion strategy interact with enemies. |
| Taxer | Steals gold unless killed quickly | Gives economic stakes to combat. |
| Caller | Adds next wave or minion if ignored | Makes target priority matter. |
| Splitter | Changes form at HP threshold | Creates burst timing. |
| Timer | Scales after N turns | Punishes slow decks. |
| Protector | Blocks or shields another enemy | Supports multi-enemy targeting. |

### 2. Bosses Need Act-Specific Tests

Current bosses are mostly larger attack/block/healing_down loops.

Recommended boss identities:

```txt
Act 1 Blackprint Warlord:
Tests first companion and Tactical Mark.
Phase 1 summons or protects a blackened guard.
Phase 2 punishes unmarked attacks or rewards marked bursts.

Act 2 Oathless Regent:
Tests recovery economy and companion growth.
Uses contract denial, heal suppression windows, and gold/bond pressure.
Should make Act 2 upgrade choices feel necessary.

Act 3 Unbound Core:
Tests final build coherence.
Has phases that represent dimensional collapse:
human contract logic -> distorted battlefield -> core rupture.
Should pressure oath, block, and damage in different windows.
```

### 3. Equipment Is Not Yet a Relic Replacement

Current equipment mostly provides:

```txt
attack_damage
block_card_bonus
companion_attack_damage
shop_discount_percent
start_block
```

This is too passive and numeric.

Recommended equipment categories:

| Category | Example |
| --- | --- |
| Opening plan | Start combat with block, mark, or companion charge. |
| Card rule bend | First skill each combat costs 1 less. |
| Oath amplifier | First oath trigger each combat repeats at 50% value. |
| Risk economy | Gain gold after flawless or high-HP win; lose value if low HP. |
| Attrition tool | After 3 combats without resting, gain a small bonus. |
| Companion specialization | Rowan attacks marked enemies harder, Maren heals after block threshold, Kyle wager odds shift. |
| Contract drawback | Strong bonus but blackens a temporary contract if condition fails. |

Keep slot limits strict:

```txt
helmet
armor
weapon
possibly one token/keepsake slot later, only if needed
```

### 4. Events Are Far Too Few

Only Act 1 has 4 events. Slay the Spire's Steam page advertises 50+ events, and its gameplay loop relies on events that may help or harm the player.

We do not need 50 now, but a demo run needs enough events that repeats do not immediately reveal the prototype.

Recommended vertical-slice target:

```txt
Act 1: 8 events
Act 2: 8 events
Act 3: 6 events
```

Event themes should use our world:

- Blackened fingerprint dispute.
- Broken token holder refused by an inn.
- Corpse of a royal academy surveyor.
- Merchant survivor slowly mutating.
- Mercenary contract loophole.
- Companion-specific oath test.
- Castle approach weather/terrain hazard.
- Core echo offering power with future cost.

Each event should include at least one real tradeoff:

```txt
HP for upgrade
gold for equipment
bond for risk
deck consistency for immediate survival
oath/token consequence for strong reward
```

### 5. Inn Needs Better Strategic Tension

Current inns heal. They are useful, but not yet as sharp as Slay's Rest vs Smith choice.

Recommended inn choices:

```txt
Rest: heal moderate HP.
Repair gear: upgrade or reroll equipment modifier.
Drill: upgrade a protagonist or companion card.
Share watch: gain bond, small heal, no card upgrade.
Quiet bargain: cheaper heal with contract drawback.
Treat blackened wound: remove a temporary debuff or heal-down scar if we add those.
```

Important balance rule:

```txt
An inn should not fully reset the route.
It should ask whether the player needs survival now or scaling later.
```

### 6. Act 2 Upgrade Timing Is Too Modest

The user's structure is good:

```txt
Act 1 midboss: first companion.
Act 1 boss: second companion.
Act 2 midpoint: strengthening timing.
Act 2 boss: choose protagonist or companion major strengthening.
```

But the current implementation is still close to stat maintenance.

Recommended upgrade model:

```txt
Act 2 midpoint:
Choose 1 of 3 focused training packages.
Each package changes play incentives, not only stats.

Act 2 boss:
Choose one major identity upgrade:
Protagonist doctrine.
Companion oath mastery, without upgrading the oath tactic itself.
Equipment/token breakthrough.
```

Important distinction:

```txt
Oath tactics themselves do not upgrade.
But the companion, bond bonus, or protagonist doctrine may interact with that fixed oath more strongly.
```

### 7. Shop Is Structurally Good But Needs Better Stock Logic

Current shop already has protagonist cards, companion cards, equipment, and services.

Reference lessons:

- Slay's shop has predictable categories and a rising remove cost.
- Monster Train separates upgrade merchants so route choice determines what kind of power is available.

Recommended changes:

```txt
Guarantee category readability:
2 attacks / 1 skill / 1 power-or-utility protagonist card if possible.
1 owned-companion card and 1 cross-companion/neutral contract option.
3 equipment, with at least one affordable item and one expensive build-around.
Services stay limited and priced so the player cannot buy everything.
```

Add one risky contract service later:

```txt
"Blood Notary" equivalent without formal notary lore:
Gain a strong discount or copy effect, but accept a contract condition.
If the condition fails, the token blackens and future shops/inns may reject the player or raise prices.
```

This uses our world without adding curses.

### 8. Card Pool Needs Archetypes, Not Just More Cards

The design target is 40 protagonist cards and eventually 8 companion cards per companion. The next expansion should not be random filler.

Recommended protagonist packages:

| Package | Cards To Add | Purpose |
| --- | --- | --- |
| Mark assault | 4-5 | Make Tactical Mark a real win path. |
| Guard/reflect | 4-5 | Let block decks win without passive turtling. |
| Blood bargain | 4-5 | Make HP-for-tempo risky and exciting. |
| Contract economy | 4-5 | Let gold/shop/route choices affect combat. |
| Oath command | 4-5 | Interact with companion attacks and oath triggers. |

Recommended minimum before next broad balance patch:

```txt
Protagonist cards: 20 -> 32
Powers: 1 -> 5 or 6
Companion cards: keep 3 each until enemy/card engine supports richer mechanics, then expand selected companions to 5 each.
```

### 9. Telemetry Needs Value Metrics

Current telemetry is a good start, but it records several count-only values.

Add:

```txt
oath_damage_added
oath_block_added
oath_heal_added
oath_energy_added
bond_bonus_value_by_companion
card_damage_prevented
card_hp_healed
enemy_damage_dealt_by_enemy_id
enemy_turns_alive_by_enemy_id
death_cause_node_type
death_cause_enemy_id
card_reward_offer_name
card_reward_pick_or_skip
shop_stock_seen
shop_stock_bought
inn_choice_seen
inn_choice_taken
```

Without these, we can see that an oath triggered 100 times but not whether it mattered.

### 10. UI/Combat Feel Still Needs System Support

The user-facing problem is visual, but the system cause is also architectural.

Reference repo lessons:

- Card hand should be a real hand component.
- Card play should go through an action queue so VFX can attach to each action.
- Enemy action should be an object/data item with intent and animation metadata.
- Combat screen should orchestrate, not own all rules.

Recommended refactor sequence:

```txt
1. Add CombatActionQueue.
2. Convert card effects into actions: damage, block, heal, mark, draw, energy, self_damage.
3. Add animation metadata per action.
4. Split HandView from combat_screen.gd.
5. Split EnemyView/IntentView from combat_screen.gd.
6. Add EnemyPatternResolver with conditions and phases.
```

This should happen before trying to add 50 more cards.

## Recommended Next Phases

### Phase A - Enemy Role And Boss Pattern Pass

Goal:

```txt
Make combat interesting before increasing raw content volume.
```

Tasks:

1. Add enemy fields: `role`, `faction`, `behavior_tags`, `budget`, `counterplay_note`.
2. Replace pure intent cycling with conditional/weighted/phase-capable enemy pattern resolution.
3. Add at least 8 new enemy mechanics using existing card constraints.
4. Rework Act 1 midboss, Act 1 boss, Act 2 boss, Act 3 boss around clear tests.
5. Run simulator and compare elite HP loss, midboss defeat rate, and wave pressure.

Acceptance:

```txt
Elite avg HP loss should be meaningfully above normal combat.
Midboss should sometimes punish poor decks but not block most novice runs.
Every boss should have a named mechanic visible in UI.
```

### Phase B - Card Action/Condition Framework

Goal:

```txt
Let cards express deckbuilder decisions beyond flat arithmetic.
```

Tasks:

1. Add JSON-supported `conditions`.
2. Add `triggers`.
3. Add per-combat flags: once_per_combat, first_card, card_count, target_marked.
4. Add action queue for card effects and enemy effects.
5. Add VFX hooks per action type.

Acceptance:

```txt
At least 10 existing cards can be rewritten using the framework with no behavior regression.
At least 8 new cards use conditions/triggers.
```

### Phase C - Equipment As Contract Relic Replacement

Goal:

```txt
Make equipment the build-warping long-term reward system.
```

Tasks:

1. Expand equipment 9 -> 24.
2. Add rule-changing effects, not only stats.
3. Add companion-specific equipment hooks.
4. Add at least 4 contract-drawback items.
5. Update shop and event rewards to surface equipment choices.

Acceptance:

```txt
A player can describe a run by its equipment, not only by cards.
```

### Phase D - Event/Inn/Shop Route Pressure

Goal:

```txt
Make route planning the core survival pleasure.
```

Tasks:

1. Act 1 events 4 -> 8.
2. Add Act 2 events 8.
3. Add Act 3 events 6.
4. Rework inn into survival-vs-growth choices.
5. Add shop stock guarantees and one risky contract service.
6. Make route nodes display risk/reward clearly.

Acceptance:

```txt
Player reaches inns around 35-60% HP on average routes.
Shop purchases average 1-2 meaningful buys per visit.
Events repeat less often during a 3-act run.
```

### Phase E - Companion Identity Expansion

Goal:

```txt
Make each companion feel like a real run-defining partner.
```

Tasks:

1. Add companion-specific combat hooks that are not just flat attack.
2. Add bond value telemetry.
3. Expand selected 4 companions from 3 cards to 5 cards first.
4. Add companion-specific events.
5. Rework Act 2 upgrade packages around companion identity.

Acceptance:

```txt
After first companion recruitment, the next two card reward decisions should visibly change.
At 30/60/100 bond, bonuses should be mild but noticeable.
```

## Balance Direction

Do not globally raise enemy HP right now.

Better direction:

```txt
Raise attack pressure where route attrition needs it.
Raise elite and midboss identity pressure.
Keep normal fight HP efficient.
Make 2-wave fights compositionally different, not automatically bigger.
Keep 3-wave fights rare set pieces.
Make inns less full-reset and more choice-driven.
Make equipment/events provide run direction.
```

Why:

```txt
The simulator already puts novice win near the target.
The problem is not only difficulty.
The problem is that the decisions are not yet varied enough.
```

## Most Important Conclusion

The project has a playable skeleton and the high-level survival curve is close enough to continue.

The next "deep" work should not be more visual polish alone and should not be blind number tuning. The next work should be:

```txt
Enemy roles
Boss mechanics
Card condition/action framework
Equipment as the relic replacement
Events/inn/shop route tradeoffs
Telemetry value metrics
```

This is how the game can become both prettier and genuinely more fun. The UI will improve when the underlying decisions are sharper, because the screen will finally have better things to communicate.

## Phase A Implementation Record

Implemented after this audit:

1. Enemy intent data now supports role fields, faction tags, counterplay notes, conditional patterns, one-time phase flags, attack scaling, attack+block, attack+healing-down, guard-all, attack buffs, and gold theft.
2. Godot combat intent preview keeps the current turn's announced enemy action stable. HP/mark threshold changes affect the next enemy action, preserving the Slay-the-Spire-style promise that the player can trust visible intent.
3. Act 1, Act 2, Act 3, and Act 2/3 bosses now have explicit combat roles rather than generic attack/block loops.
4. The simulator now reads the same pattern data and fixed-turn intent model, including multi-wave fights, companion growth, bond bonuses, card upgrades, equipment, shop, inn, events, and enemy pattern flags.
5. The latest 300-run simulation is written to `SourceCode/data/playtest_logs/balance_run_simulation_latest.json` and summarized in `docs/playtest_balance_notes.md`.

Latest sanity result:

```txt
novice   win 6.3%, Act1 boss 75.3%, Act2 boss 38.0%, Act3 reach 37.7%
balanced win 30.0%
safe     win 78.3%
greedy   win 21.0%
```

Reading:

```txt
The novice curve now sits inside the internal final-win target and near the Act 1/Act 2 bands.
The safe and greedy policies are inside their sanity bands.
The balanced policy is still below the 35-55% internal sanity band, so the next balance work should improve player agency and deck-quality decisions rather than simply nerfing enemies.
```

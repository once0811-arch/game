# Playtest Balance Notes

## Phase 9 Result

Phase 9 adds the first telemetry loop for balance work.
The game now records run events to JSON so future tuning can compare numbers instead of relying only on feel.

Runtime log path:

```txt
user://telemetry_last_run.json
```

macOS observed path:

```txt
~/Library/Application Support/Godot/app_userdata/deckbuilding/telemetry_last_run.json
```

Monte Carlo run simulation:

```txt
tools/balance_run_simulator.py
docs/balance_run_simulation_report.md
SourceCode/data/playtest_logs/balance_run_simulation_latest.json
```

Use the simulator before broad enemy/card tuning. It models current JSON data, card upgrades, companion recruitment, bond bonuses, equipment, shops, inns, events, and several enemy HP/attack profiles. It does not replace human playtests, but it is good at finding obvious imbalance directions before spending time in Godot.

## Recorded Metrics

Current counters:

| Metric | Purpose |
| --- | --- |
| `combats_started` / `combats_won` / `combats_lost` | Tracks encounter survival and completion. |
| `cards_played` | Helps estimate hand/energy pressure. |
| `card_rewards_picked` / `card_rewards_skipped` | Tracks deck growth versus economy. |
| `companions_recruited` | Confirms companion pacing. |
| `oath_triggers` | Shows whether oath tactics are actually visible. |
| `healing_down_applied` | Tracks anti-heal pressure. |
| `shop_purchases` | Tracks gold sink strength. |
| `inn_rooms_used` | Tracks recovery node value. |
| `event_choices` | Tracks event engagement. |
| `upgrades_taken` | Tracks Act 2 upgrade usage. |
| `act_2_reached` / `act_3_reached` / `run_completed` | Tracks macro progression. |
| `combat_wave_count` / `combat_wave_index` | Checks whether 2-3 wave nodes are too frequent or too exhausting. |
| `hp_lost_by_wave` / `turns_by_wave` | Separates fair multi-wave pressure from bloated total HP. |

Event records also include act, depth, gold, HP, max HP, timestamp, and type.
Combat end records include turns, HP lost, cards played, outcome, and average bond.

## First Balance Questions

Use the first 5-10 manual runs to answer:

1. Does Act 1 before the first companion still feel too long?
2. Does the first shop leave the player choosing between one big purchase and one service?
3. Are inns used because they matter, or skipped because combat healing is enough?
4. Do oath tactics trigger at least several times per act after recruitment?
5. Does Healing Down meaningfully pressure healing cards without making Maren-style utility feel bad?
6. Do Act 2 midpoint upgrades change the build, or feel like small stat maintenance?
7. Does average bond reach 30 before Act 2, 60 around Act 2/3, and 100 only in strong companion-focused runs?
8. Do 2-wave normal fights feel like a rhythm change rather than an elite fight?
9. Do 3-wave fights appear rarely enough that players remember them as set pieces, not chores?
10. Does any route produce back-to-back long fights without a visible safe branch?

## Initial Targets

These are starting targets, not final truth:

| Checkpoint | Target |
| --- | --- |
| Act 1 midboss victory | Player HP 35-65% in average run. |
| First companion recruitment | Always reached in a viable run. |
| Act 1 boss victory | 1 companion build identity should be visible. |
| First shop | 1-2 meaningful purchases, not everything. |
| Act 2 depth 6 | At least one companion near or above 30 bond. |
| Act 2 boss | Major upgrade should feel run-defining. |
| Act 3 boss | Victory should require coherent deck, companion, and equipment choices. |
| 2-wave normal combat | HP loss no more than 15-25% above same-tier 1-wave combat. |
| 3-wave normal combat | Appears at most once in Act 2 route and twice in Act 3 route. |
| Multi-wave combat turn count | 2-wave normal 4-6 turns, 3-wave normal 5-7 turns. |
| Inn entry HP | Average route should reach inns around 35-60% HP, not at full safety. |
| Inn exit HP | A paid inn should leave the party around 60-85% HP, not fully reset every time. |
| Boss entry HP | Act 1 55-80%, Act 2 45-75%, Act 3 40-70% before the boss. |

## Current Risks

- Card service targets are automatic, so telemetry can show usage but not whether the choice felt satisfying.
- Temporary art reuse may distort perceived difficulty because enemies are not visually distinct enough yet.
- Combat logs count oath triggers, but not the value gained from each trigger.
- Kyle's gambling economy is now implemented as a 5-win wager payout. It needs focused testing because normal outcomes should be below average, while jackpot outcomes are allowed to make a run easier.
- The current playable card pool is 20 protagonist cards and 30 companion cards. It is still smaller than the final 40 protagonist / 80 companion target, so early balance should judge pacing and system clarity before judging final build variety.
- Act 1 now has a Healing Down enemy pattern through Mutated Scholar. Verify that it pressures Maren/Isol healing without making healing cards feel like trap picks.
- Combat now has visible oath/bond/wager/victory feedback. Verify that the toast timing helps rather than covering important card or enemy information.
- Multi-wave combat is now implemented for selected normal nodes. The current danger is no longer a missing system, but 2-3 wave nodes becoming too frequent or too low-pressure after the simultaneous-attack burst is removed.
- Enemy total HP targets were raised by about 6%; do not also raise multi-wave frequency in the same tuning patch without telemetry.
- The core route fun is attrition: HP should be gradually shaved down by normal and elite nodes, then stabilized by reaching an inn, event, shop, or upgrade at the right time. Prefer modest enemy attack pressure and recovery economy tuning over blunt HP inflation.

## Next Tuning Loop

After each tuning patch:

1. Export or copy `telemetry_last_run.json` into `SourceCode/data/playtest_logs/` with a short filename.
2. Record build commit, run seed, companion choices, and death/victory point.
3. Compare turn count, HP loss, shop purchases, inn usage, oath triggers, and bond score.
4. Compare wave count, HP lost by wave, and whether a safe branch existed before/after 3-wave nodes.
5. Change one balance cluster at a time: enemy HP/damage, wave frequency, economy prices, bond gains, or card numbers.

## Simulation Pass - 2026-05-26

Command:

```txt
python3 tools/balance_run_simulator.py --runs 300 --policies balanced,safe,greedy --enemy-profiles current,plus6,spec_mid,spec_mid_attack10
```

Main findings:

| Profile | Balanced win | Safe win | Greedy win | Read |
| --- | ---: | ---: | ---: | --- |
| current | 58.3% | 96.0% | 31.3% | Baseline is playable, but safe routes are too reliable. |
| plus6 | 49.7% | 95.7% | 27.0% | Global +6% HP pressures balanced/greedy but barely touches safe. |
| spec_mid | 21.0% | 74.3% | 7.3% | Full document HP midpoint is too steep if applied all at once. |
| spec_mid_attack10 | 13.7% | 57.3% | 4.3% | Use as pressure-test or higher-difficulty reference, not baseline. |

Tuning read:

```txt
Do not globally push every enemy to document midpoint HP yet.
Raise Act 1 boss, Act 2+ single-enemy nodes, and late bosses in smaller steps.
Safe route economy is too strong; tune inns/events/shops and safe-route rewards.
Elites rarely cause direct defeats, so their reward and threat identity need work.
Card rewards over-select Road Cleave, Breakthrough, and Sweeping Order while many utility cards are ignored.
```

## Balance Patch - 2026-05-27

Command:

```txt
python3 tools/balance_run_simulator.py --runs 500 --policies novice,balanced,safe,greedy --enemy-profiles current
```

Main result after the attrition patch:

| Policy | Act 1 boss | Act 2 boss | Act 3 reach | Win | Inn in/out | Read |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| novice | 71.2% | 21.6% | 21.4% | 6.0% | 50/75% | Close to early-run target; Act 2 is still harsh but acceptable for the current small card pool. |
| balanced | 98.6% | 76.4% | 76.4% | 39.2% | 33/67% | Inside automatic sanity band; skilled routing survives, but final boss and late Act 3 still matter. |
| safe | 99.6% | 96.2% | 96.2% | 69.6% | 49/90% | Safe routing preserves HP but loses enough deck pressure to sit near the lower edge of target. |
| greedy | 94.2% | 49.4% | 49.0% | 20.6% | 22/71% | Greedy routing is dangerous but viable, which fits the route-risk fantasy. |

Patch direction:

```txt
Raised enemy attack intent more than HP so the main pressure is route attrition.
Reduced safe-route free value through lower skip gold, weaker event gold, pricier gear/services, and less generous inns.
Lowered bond gain pace so 100 bond is a strong investment outcome rather than a default Act 3 state.
Reduced dominant high-cost attacks and improved mark/draw/utility cards so deckbuilding is less one-note.
```

## Multi-Wave Patch - 2026-05-27

Command:

```txt
python3 tools/balance_run_simulator.py --runs 300 --policies novice,balanced,safe,greedy --enemy-profiles current
```

Result after implementing selected 2-3 wave nodes:

| Policy | Act 1 boss | Act 2 boss | Act 3 reach | Win | Read |
| --- | ---: | ---: | ---: | ---: | --- |
| novice | 75.3% | 25.3% | 25.0% | 7.0% | Inside the early-player target; 3-wave nodes are dangerous enough to notice. |
| balanced | 99.7% | 89.7% | 89.7% | 54.0% | Upper edge of the automatic sanity band, so future content should add pressure carefully. |
| safe | 100.0% | 98.7% | 98.7% | 84.3% | Safe routing remains viable but still inside the target ceiling. |
| greedy | 97.0% | 65.0% | 64.7% | 32.0% | Risky pathing is dangerous but not a trap. |

Implementation read:

```txt
Act 1 keeps 3-wave combat banned and only uses two selected 2-wave normal nodes.
Act 2 adds one 3-wave set-piece normal node with nearby safe branches.
Act 3 adds two 3-wave normal set pieces and several 2-wave rhythm changes.
Telemetry now records wave starts, wave count, HP lost by wave, and turns by wave.
The simulator reads EncounterData.waves and reports combat pressure by wave count.
```

## Phase 9 Validation

Automated checks performed:

```txt
Godot headless project load: pass
Godot headless combat screen load: pass
Godot headless shop screen load: pass
Godot headless ending screen load: pass
Telemetry JSON generation through ending screen: pass
git diff --check: pass
```

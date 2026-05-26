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

## Current Risks

- Card service targets are automatic, so telemetry can show usage but not whether the choice felt satisfying.
- Temporary art reuse may distort perceived difficulty because enemies are not visually distinct enough yet.
- Combat logs count oath triggers, but not the value gained from each trigger.
- Kyle's gambling economy is now implemented as a 5-win wager payout. It needs focused testing because normal outcomes should be below average, while jackpot outcomes are allowed to make a run easier.
- The current playable card pool is 20 protagonist cards and 30 companion cards. It is still smaller than the final 40 protagonist / 80 companion target, so early balance should judge pacing and system clarity before judging final build variety.
- Act 1 now has a Healing Down enemy pattern through Mutated Scholar. Verify that it pressures Maren/Isol healing without making healing cards feel like trap picks.
- Combat now has visible oath/bond/wager/victory feedback. Verify that the toast timing helps rather than covering important card or enemy information.

## Next Tuning Loop

After each tuning patch:

1. Export or copy `telemetry_last_run.json` into `SourceCode/data/playtest_logs/` with a short filename.
2. Record build commit, run seed, companion choices, and death/victory point.
3. Compare turn count, HP loss, shop purchases, inn usage, oath triggers, and bond score.
4. Change one balance cluster at a time: enemy HP/damage, economy prices, bond gains, or card numbers.

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

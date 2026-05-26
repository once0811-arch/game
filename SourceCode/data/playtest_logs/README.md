# Playtest Logs

Runtime telemetry is written by Godot to:

```txt
user://telemetry_last_run.json
```

On macOS this usually resolves to:

```txt
~/Library/Application Support/Godot/app_userdata/deckbuilding/telemetry_last_run.json
```

The repository keeps this folder as the intended home for curated exported playtest logs.
Do not commit raw every-run logs by default; copy only useful balance snapshots here when comparing tuning changes.

Current schema:

```txt
run_id
seed
act
depth
complete
counters
average_bond
events
```

Primary counters:

```txt
combats_started / combats_won / combats_lost
cards_played
card_rewards_picked / card_rewards_skipped
companions_recruited
oath_triggers
healing_down_applied
shop_purchases
inn_rooms_used
event_choices
upgrades_taken
act_2_reached / act_3_reached
run_completed
```

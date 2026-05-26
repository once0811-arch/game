# 04. 데이터 스키마

초기 구현은 JSON 기반을 추천한다. Codex가 텍스트로 수정하기 쉽고, Godot 에디터 연결 문제를 줄일 수 있다.

## 1. CardData

```json
{
  "id": "basic_strike",
  "name_ko": "기본 공격",
  "owner_type": "protagonist",
  "owner_id": "protagonist",
  "card_type": "attack",
  "rarity": "starter",
  "cost": 1,
  "upgraded_cost": 1,
  "target": "enemy",
  "keywords": [],
  "synergy_tags": ["basic", "single_target"],
  "command_tags": ["sets_tactical_mark"],
  "effects": [
    {"type": "damage", "amount": 6, "target": "enemy"}
  ],
  "upgraded_effects": [
    {"type": "damage", "amount": 9, "target": "enemy"}
  ],
  "description_ko": "피해 6을 줍니다.",
  "upgraded_description_ko": "피해 9를 줍니다."
}
```

### 필드

```txt
id: 고유 ID
name_ko: 한국어 카드명
owner_type: protagonist / companion / common
owner_id: protagonist 또는 companion_id
card_type: attack / skill / power
rarity: starter / common / uncommon / rare
cost: 기본 비용
upgraded_cost: 강화 비용. 변하지 않으면 같은 값.
target: self / enemy / all_enemies / none
keywords: retain, exhaust, innate 등
synergy_tags: reward/filter/balance용 태그. 예: single_target, aoe, block, draw, companion_order, heal
command_tags: 전술 표식, 동료 즉시 공격 등 지휘 계열 처리 태그
 effects: 기본 효과 배열
upgraded_effects: 강화 효과 배열
description_ko: 표시 설명
upgraded_description_ko: 강화 표시 설명
```

전술 표식 규칙:

```txt
단일 대상 공격 카드는 기본적으로 전술 표식을 갱신한다.
피해가 없는 지휘 카드가 표식을 갱신해야 하면 command_tags에 sets_tactical_mark를 둔다.
광역 공격만 있는 카드는 전술 표식을 갱신하지 않는다.
```

## 2. CardInstance

런 중 실제 카드 인스턴스.

```json
{
  "instance_id": "card_000012",
  "card_id": "basic_strike",
  "is_upgraded": false,
  "source": "starter_deck",
  "owner_type": "protagonist",
  "owner_id": "protagonist"
}
```

동료 카드는 중복 획득 불가이므로 `card_id` 기준으로 보유 여부를 검사한다.

## 3. CompanionData

```json
{
  "id": "companion_rowan",
  "name_ko": "붉은창 로완",
  "class_type": "attacker",
  "design_role_ko": "단일 대상 표식 딜러",
  "visual_concept_ko": "붉은 망토를 두른 창병 용병",
  "personality_ko": "말수가 적지만 한 번 정한 표적은 끝까지 추격한다.",
  "combat_hook_ko": "전술 표식 대상에게 강하고, 같은 적을 연속 공격할수록 빛난다.",
  "base_attack_damage": 8,
  "passive": {
    "id": "rowan_focus_target",
    "name_ko": "집중 추격",
    "description_ko": "플레이어가 같은 적을 연속 공격하면 로완의 기본 공격 피해가 증가합니다.",
    "base_values": {"bonus_damage": 3},
    "bond_60_values": {"bonus_damage": 5}
  },
  "oath_tactics": [
    {
      "id": "rowan_oath_red_pursuit",
      "name_ko": "붉은 추격",
      "trigger_ko": "한 턴에 같은 적을 2회 이상 공격하고 대상이 살아 있습니다.",
      "timing": "after_card_play",
      "limit": "once_per_turn",
      "effects": [
        {
          "type": "oath_attack",
          "target": "tactical_mark",
          "damage_multiplier": 0.75,
          "min_damage": 3,
          "apply_passive_bonus": false,
          "apply_equipment_basic_attack_bonus": false
        }
      ]
    },
    {
      "id": "rowan_oath_spearpoint_lock",
      "name_ko": "창끝 고정",
      "trigger_ko": "전술 표식 대상에게 취약을 부여합니다.",
      "timing": "after_status_apply",
      "limit": "once_per_turn",
      "effects": [
        {"type": "gain_block", "amount": 4}
      ]
    },
    {
      "id": "rowan_oath_execution_order",
      "name_ko": "처형 명령",
      "trigger_ko": "전술 표식 대상이 처치됩니다.",
      "timing": "after_enemy_defeated",
      "limit": "once_per_turn",
      "effects": [
        {"type": "draw", "amount": 1}
      ]
    }
  ],
  "bond_bonuses": {
    "30": [{"type": "companion_basic_attack_damage_add", "amount": 1}],
    "60": [{"type": "passive_value_override", "key": "bonus_damage", "amount": 5}],
    "100": [{"type": "first_tactical_mark_attack_damage_add", "amount": 2}]
  },
  "card_pool": [
    "rowan_piercing_lunge",
    "rowan_spear_wall"
  ],
  "equipment_affinity": ["weapon", "armor"],
  "foreshadow_event_ids": ["event_rowan_red_banner_trace"],
  "synergy_tags": ["single_target", "vulnerable", "tactical_mark"]
}
```

## 4. CompanionInstance

```json
{
  "companion_id": "companion_rowan",
  "is_recruited": true,
  "recruited_act": 1,
  "selected_oath_tactic_id": "rowan_oath_red_pursuit",
  "bond_score": 18,
  "runtime_counters": {
    "kyle_wager_count": 0
  },
  "owned_card_ids": [
    "rowan_piercing_lunge",
    "rowan_spear_wall"
  ],
  "available_card_ids": [
    "rowan_red_charge",
    "rowan_long_reach"
  ],
  "upgraded_card_ids": []
}
```

`bond_score`는 0~100 범위다. 30/60/100 보너스는 점수 기준으로 자동 적용하며, 서약 전술은 런 중 변경하거나 업그레이드하지 않는다. 세계관상 서약 전술은 동료와 증표에 맺은 전투 조항이지만, 기본 전투 데이터에는 계약 실패/검은 지문 패널티를 넣지 않는다. 검은 지문은 이벤트, 동료 후보, UI 연출용 소재로 사용한다.

`runtime_counters`는 동료별 특수 런 상태를 저장한다. 현재 필수 사용처는 카일의 `kyle_wager_count`이며, 다른 동료는 빈 객체로 둬도 된다.

## 5. EquipmentData

```json
{
  "id": "steel_vanguard_helmet",
  "name_ko": "선봉대 철투구",
  "slot": "helmet",
  "rarity": "common",
  "scope": "team_passive",
  "valid_owner_classes": ["any"],
  "effects": [
    {"type": "companion_basic_attack_damage_add", "amount": 1}
  ],
  "description_ko": "모든 동료의 기본 공격 피해가 1 증가합니다.",
  "price": 95
}
```

장비 필드:

```txt
slot: helmet / armor / weapon
scope: team_passive / owner_only
valid_owner_classes: any / attacker / defender / utility / reward / protagonist
price: 상점 기본 가격
effects: 장비 효과 배열
```

## 6. EquipmentInstance

```json
{
  "instance_id": "equip_000031",
  "equipment_id": "steel_vanguard_helmet",
  "acquired_from": "shop",
  "equipped_to": null
}
```

`equipped_to`는 다음 중 하나다.

```txt
null
protagonist
companion_rowan
companion_sera
```

## 7. InventoryState

```json
{
  "equipment_inventory": [
    {"instance_id": "equip_000031", "equipment_id": "steel_vanguard_helmet", "equipped_to": "companion_rowan"}
  ],
  "gear_slots_by_character": {
    "protagonist": {
      "helmet": null,
      "armor": null,
      "weapon": null
    },
    "companion_rowan": {
      "helmet": "equip_000031",
      "armor": null,
      "weapon": null
    }
  }
}
```

## 8. ProtagonistUpgradeData

```json
{
  "id": "upgrade_attack_damage_all_1",
  "name_ko": "날카로운 전술",
  "category": "combat",
  "rarity": "common",
  "effects": [
    {"type": "all_attack_card_damage_add", "amount": 1}
  ],
  "description_ko": "모든 공격 카드의 피해가 1 증가합니다."
}
```

주인공 강화 카테고리:

```txt
combat
defense
economy
companion_support
card_manipulation
combo
```

## 9. CompanionGrowthRewardData

```json
{
  "id": "reward_companion_bond_10",
  "type": "bond_score_add",
  "target": "companion",
  "amount": 10,
  "description_ko": "선택한 동료의 유대 점수를 10 올립니다."
}
```

동료 카드 강화:

```json
{
  "id": "upgrade_companion_card",
  "type": "companion_card_upgrade",
  "target": "owned_companion_card",
  "description_ko": "보유한 동료 카드 1장을 강화합니다."
}
```

## 10. MapNodeData

```json
{
  "id": "act1_node_05",
  "act": 1,
  "depth": 5,
  "node_type": "combat",
  "connected_to": ["act1_node_06_a", "act1_node_06_b"],
  "payload_id": "encounter_act1_bandits"
}
```

node_type:

```txt
combat
event
shop
inn
treasure
elite
mid_boss
boss
companion_foreshadow
companion_contract
upgrade
```

`companion_foreshadow`는 Act 1 depth 2~5에서 동료 후보를 미리 보여주는 이벤트성 노드다. 구현상 normal event로 처리해도 되지만, 맵 생성 가중치와 저장에서 구분할 수 있으면 좋다.

`mid_boss`는 Act 1 depth 6의 중간 보스처럼 Act 보스보다 짧은 필수 전투를 표현한다.

`companion_contract`는 중간 보스 승리 후 첫 동료 선택과 Act 1 보스 승리 후 두 번째 동료 선택 화면을 표현한다.

`upgrade`는 Act 2 depth 6 중간 강화 노드처럼 전투 없이 주인공/동료 강화 선택을 제공하는 노드다.

## 11. EnemyData

```json
{
  "id": "act1_mutated_mercenary_grunt",
  "name_ko": "변이 용병 졸개",
  "max_hp": 32,
  "block": 0,
  "intent_patterns": [
    {"type": "attack", "damage": 7, "weight": 60},
    {"type": "block", "block": 6, "weight": 30},
    {"type": "debuff", "status": "weak", "amount": 1, "weight": 10},
    {"type": "debuff", "status": "healing_down", "amount": 50, "duration": 2, "weight": 0}
  ]
}
```

`healing_down`은 받는 회복량을 비율로 줄이는 상태 효과다. Act 1 일반 적은 기본 weight 0으로 두고, Act 2 이후 특정 적에게만 명시적으로 가중치를 준다.

## 11.1 BossData

보스는 일반 적보다 패턴 의도가 중요하므로 별도 스키마를 둔다.

```json
{
  "id": "boss_act1_blackprint_captain",
  "name_ko": "검은 지문을 가진 용병대장",
  "act": 1,
  "max_hp": 240,
  "design_goal_ko": "첫 동료와 서약 전술을 배운 뒤, 두 번째 동료를 받을 자격이 있는지 시험합니다.",
  "phase_thresholds": [],
  "intent_sequence": [
    {"turn": 1, "type": "attack", "damage": 10},
    {"turn": 2, "type": "block_or_support", "block": 12},
    {"turn": 3, "type": "multi_attack", "damage": 6, "hits": 2},
    {"turn": 4, "type": "debuff_attack", "status": "weak", "amount": 1, "damage": 8}
  ],
  "repeats_from_turn": 1,
  "notes_ko": "상태 카드나 저주 카드를 덱에 넣지 않습니다."
}
```

보스 설계 금지:

```txt
상태 카드 삽입
저주 카드 삽입
포션/유물 보상 연동
동료를 직접 제거하거나 영구 약화
```

## 12. EventData

```json
{
  "id": "event_abandoned_cart",
  "name_ko": "버려진 마차",
  "act_scope": [1, 2],
  "event_type": "normal",
  "description_ko": "길가에 버려진 마차가 놓여 있습니다.",
  "choices": [
    {
      "id": "search_cart",
      "text_ko": "마차를 뒤진다.",
      "conditions": [],
      "results": [
        {"type": "gain_gold", "amount": 35},
        {"type": "chance", "probability": 0.25, "result": {"type": "combat", "encounter_id": "act1_rat_pack"}}
      ]
    }
  ]
}
```

금지 결과:

```txt
gain_relic
gain_potion
add_curse
add_status_card
```

## 13. InnData

여관은 매번 절차적으로 생성해도 된다.

```json
{
  "inn_type": "event",
  "keeper_mood": "suspicious",
  "rooms": [
    {
      "id": "room_free_creaking",
      "name_ko": "삐걱거리는 공짜 방",
      "price": 0,
      "visible_description_ko": "공짜입니다. 너무 공짜라서 수상합니다.",
      "results": [
        {"type": "heal_percent", "amount": 15},
        {"type": "chance", "probability": 0.25, "result": {"type": "full_heal"}}
      ]
    }
  ]
}
```

## 14. ShopState

```json
{
  "shop_id": "shop_act1_04",
  "cards_for_sale": ["quick_slash", "guard_line"],
  "companion_cards_for_sale": ["rowan_piercing_lunge"],
  "equipment_for_sale": ["steel_vanguard_helmet"],
  "services": ["remove_card", "upgrade_normal_card", "transform_normal_card", "duplicate_normal_card", "upgrade_companion_card"]
}
```

## 15. SaveData

```json
{
  "version": "0.1.0",
  "run_state": {
    "seed": 123456789,
    "act_index": 1,
    "current_node_id": "act1_node_06_a",
    "seen_companion_ids": ["companion_rowan"],
    "player_hp": 58,
    "player_max_hp": 76,
    "gold": 121,
    "deck": [],
    "party_state": {},
    "inventory_state": {},
    "map_state": {},
    "protagonist_upgrades": [],
    "run_flags": {},
    "telemetry": {}
  }
}
```

## 16. BalanceConstants

초기 수치는 코드에 흩뿌리지 않고 JSON으로 관리한다.

```json
{
  "version": "0.1.0",
  "combat": {
    "base_energy": 4,
    "base_draw_per_turn": 6,
    "target_normal_turns": [3, 5],
    "target_elite_turns": [5, 7],
    "target_boss_turns": [8, 11]
  },
  "run_structure": {
    "acts": 3,
    "nodes_per_act": 12,
    "act1_mid_boss_depth": 6,
    "act2_upgrade_depth": 6,
    "act1_mid_boss_reward": "first_companion_contract",
    "act1_boss_reward": "second_companion_contract",
    "act2_mid_reward": "minor_protagonist_or_companion_upgrade",
    "act2_boss_reward": "major_protagonist_or_companion_upgrade"
  },
  "card_cost_distribution_target": {
    "zero_cost_percent": [10, 12],
    "one_cost_percent": [40, 45],
    "two_cost_percent": [32, 38],
    "three_or_x_cost_percent": [8, 12],
    "target_cards_played_per_turn": [3, 4]
  },
  "card_rewards": {
    "rarity_weights_by_act": {
      "1": {"common": 62, "uncommon": 35, "rare": 3},
      "2": {"common": 55, "uncommon": 37, "rare": 8},
      "3": {"common": 48, "uncommon": 40, "rare": 12}
    },
    "shop_rarity_weights": {"common": 50, "uncommon": 38, "rare": 12},
    "rare_pity": {
      "initial_offset": -3,
      "common_roll_bonus": 1,
      "max_bonus": 10
    },
    "upgraded_reward_chance_by_act": {"1": 0, "2": 20, "3": 40},
    "skip_gold_by_act": {"1": 8, "2": 10, "3": 12}
  },
  "bond": {
    "max_score": 100,
    "thresholds": [30, 60, 100],
    "target_pace": {
      "first_companion_normal_act2_mid": 30,
      "first_companion_normal_act3_start": [50, 70],
      "first_companion_normal_act3_late": [70, 90],
      "second_companion_normal_act2_late": 30,
      "second_companion_normal_act3_mid": [50, 70],
      "second_companion_normal_act3_late": [70, 90]
    },
    "gain": {
      "normal_combat_win": 3,
      "elite_combat_win": 7,
      "boss_combat_win": 12,
      "companion_card_pick": 3,
      "companion_card_upgrade": 5,
      "equipped_companion_combat_win": 1,
      "elite_reward_bond_add": 10,
      "companion_event_min": 8,
      "companion_event_max": 12,
      "act2_mid_upgrade_pick": 10,
      "act2_boss_companion_upgrade_pick": 20
    }
  },
  "oath_tactics": {
    "oath_attack_damage_multiplier": 0.75,
    "oath_attack_min_damage": 3,
    "oath_attack_applies_passive_bonus": false,
    "oath_attack_applies_equipment_basic_attack_bonus": false,
    "per_turn_attack_damage_budget": [4, 8],
    "per_combat_attack_damage_budget": [8, 14],
    "block_budget": [4, 6],
    "heal_budget": [2, 3],
    "normal_combat_gold_budget": [3, 6]
  },
  "gold_rewards": {
    "normal_combat": [12, 20],
    "elite_combat": [30, 45],
    "boss_combat": [90, 105],
    "event": [20, 85],
    "treasure": [50, 110]
  },
  "shop_prices": {
    "common_card": [45, 60],
    "uncommon_card": [70, 95],
    "rare_card": [135, 175],
    "companion_card": [85, 140],
    "common_equipment": [95, 130],
    "uncommon_equipment": [150, 220],
    "rare_equipment": [240, 330],
    "remove_card_base": 75,
    "remove_card_increment": 25,
    "upgrade_normal_card": 90,
    "upgrade_companion_card": 120
  },
  "healing": {
    "healing_down_multiplier": 0.5,
    "healing_down_duration_turns": [1, 2],
    "act1_common_enemy_healing_down": false
  },
  "kyle_wager": {
    "threshold": 5,
    "normal_win_add": 1,
    "healthy_win_hp_percent": 70,
    "healthy_win_add": 2,
    "elite_or_boss_win_add": 2,
    "max_add_per_combat": 2,
    "reward_weights": {"low": 55, "mid": 30, "high": 12, "jackpot": 3},
    "bond_60_reward_weight_delta": {"low": -10, "mid": 7, "high": 3, "jackpot": 0}
  },
  "inn_prices": {
    "small_room": {"gold": 35, "heal_percent": 22},
    "good_room": {"gold": 80, "heal_percent": 45},
    "noble_room": {"gold": 125, "heal_percent": 70}
  },
  "difficulty_presets": {
    "traveler": {
      "starting_max_hp": 84,
      "act1_normal_enemy_hp_multiplier": 0.9,
      "act1_enemy_intent_add": -1,
      "boss_hp_multiplier": 0.92,
      "inn_price_multiplier": 0.9
    },
    "standard": {
      "starting_max_hp": 76,
      "enemy_hp_multiplier": 1.0,
      "enemy_intent_add": 0,
      "gold_reward_multiplier": 1.0,
      "inn_price_multiplier": 1.0
    },
    "veteran": {
      "starting_max_hp": 70,
      "enemy_hp_multiplier": 1.08,
      "act2_plus_enemy_intent_add": 1,
      "event_treasure_gold_multiplier": 0.9,
      "inn_price_multiplier": 1.1
    }
  }
}
```

## 17. RunTelemetry

플레이테스트용 지표다. 게임 내 통계 화면은 만들지 않는다.

```json
{
  "combat_turn_counts": [],
  "combat_hp_losses": [],
  "bond_score_gains": {},
  "mid_boss_reached_count": 0,
  "mid_boss_clear_count": 0,
  "oath_tactic_pick_counts": {},
  "oath_tactic_trigger_counts": {},
  "healing_down_applied_counts": {},
  "kyle_wager_reward_counts": {},
  "card_reward_seen_counts": {},
  "card_reward_pick_counts": {},
  "card_reward_skip_count": 0,
  "companion_seen_counts": {},
  "companion_pick_counts": {},
  "equipment_purchase_counts": {},
  "inn_room_pick_counts": {},
  "event_choice_counts": {},
  "death_node_id": null
}
```

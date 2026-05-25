# 03. Godot 기술 구조

## 1. 목표

Godot 4.x + GDScript에서 Codex가 자연어 지시로 안정적으로 작업할 수 있도록 구조를 작게 나눈다.

가장 중요한 원칙:

```txt
게임 규칙은 순수 로직.
씬은 표시, 입력, 애니메이션.
데이터는 JSON 또는 Resource.
```

## 2. 권장 폴더 구조

```txt
res://
  docs/
    design/

  data/
    cards/
      protagonist_cards.json
      companion_cards.json
    companions/
      companions.json
    equipment/
      equipment.json
    upgrades/
      protagonist_upgrades.json
      companion_upgrades.json
    enemies/
      enemies.json
      bosses.json
    events/
      events.json
      inns.json
      treasures.json
    maps/
      map_node_weights.json
    balance/
      balance_constants.json

  scenes/
    app/
      main.tscn
    combat/
      combat_screen.tscn
      enemy_view.tscn
      player_panel.tscn
      companion_panel.tscn
    cards/
      card_view.tscn
      hand_view.tscn
      deck_pile_view.tscn
    map/
      map_screen.tscn
      map_node_view.tscn
    reward/
      card_reward_screen.tscn
      companion_reward_screen.tscn
      elite_upgrade_screen.tscn
      treasure_reward_screen.tscn
    shop/
      shop_screen.tscn
    inn/
      inn_screen.tscn
      inn_room_option.tscn
    event/
      event_screen.tscn
    inventory/
      equipment_inventory_screen.tscn

  scripts/
    autoload/
      game.gd
      data_registry.gd
      save_service.gd
      rng_service.gd
      scene_router.gd

    core/
      run_state.gd
      map_state.gd
      party_state.gd
      inventory_state.gd
      reward_state.gd
      run_telemetry.gd
      constants.gd

    combat/
      combat_state.gd
      turn_manager.gd
      combat_controller.gd
      card_effect_resolver.gd
      enemy_ai_resolver.gd
      damage_resolver.gd
      status_effect_system.gd
      companion_combat_system.gd

    cards/
      card_data.gd
      card_instance.gd
      deck_state.gd
      card_reward_generator.gd
      card_upgrade_service.gd

    companions/
      companion_data.gd
      companion_instance.gd
      companion_manager.gd
      companion_reward_generator.gd
      companion_upgrade_service.gd

    equipment/
      equipment_data.gd
      equipment_instance.gd
      equipment_inventory.gd
      equipment_effect_resolver.gd

    map/
      map_generator.gd
      map_node_data.gd
      map_navigation_service.gd

    rewards/
      elite_reward_generator.gd
      treasure_reward_generator.gd
      combat_reward_generator.gd

    shop/
      shop_generator.gd
      shop_service.gd

    inn/
      inn_generator.gd
      inn_room_generator.gd
      inn_result_resolver.gd

    events/
      event_data.gd
      event_condition_checker.gd
      event_result_resolver.gd

    ui/
      tooltip_service.gd
      drag_service.gd
      input_adapter.gd
      ui_formatters.gd

  tests/
    combat_test_runner.gd
    card_test_runner.gd
    reward_test_runner.gd
```

## 3. Autoload 설계

### Game

전역 런 상태를 들고 있는 루트 서비스.

```txt
Game.current_run: RunState
Game.start_new_run()
Game.end_run()
Game.goto_next_node(node_id)
```

### DataRegistry

모든 데이터 파일을 로드하고 조회한다.

```txt
DataRegistry.get_card(card_id)
DataRegistry.get_companion(companion_id)
DataRegistry.get_equipment(equipment_id)
DataRegistry.get_enemy(enemy_id)
DataRegistry.get_event(event_id)
DataRegistry.get_balance_value(key)
```

### SaveService

저장/불러오기 담당.

```txt
SaveService.save_run(run_state)
SaveService.load_run()
SaveService.clear_run()
SaveService.save_settings(settings)
```

### RngService

런 시드 기반 랜덤 담당.

```txt
RngService.set_seed(seed)
RngService.randi_range(min, max)
RngService.pick_weighted(items)
RngService.chance(probability)
```

유저에게 시드 입력/공유 UI는 제공하지 않는다.

### SceneRouter

씬 전환 담당.

```txt
SceneRouter.goto_map()
SceneRouter.goto_combat(encounter_id)
SceneRouter.goto_reward(reward_state)
SceneRouter.goto_shop(shop_state)
SceneRouter.goto_inn(inn_state)
SceneRouter.goto_event(event_id)
```

## 4. 핵심 상태 클래스

### RunState

```txt
run_id
seed
act_index
current_node_id
seen_companion_ids
player_hp
player_max_hp
gold
deck_state
party_state
inventory_state
map_state
protagonist_upgrades
run_flags
telemetry
completed_nodes
```

`seen_companion_ids`는 Act 1 동료 예고 이벤트에서 본 후보를 저장한다. Act 1 보스 후 동료 3택은 이 목록에서 최소 1명을 포함한다.

`run_flags`는 이벤트, 상점 거래, 여관 결과처럼 다음 노드 또는 다음 전투까지만 유지되는 작은 플래그를 저장한다.

### CombatState

```txt
turn_number
energy
draw_pile
hand
discard_pile
exhaust_pile
player_hp
player_block
player_statuses
enemies
active_powers
companions
last_player_attack_target_id
combat_log
```

`last_player_attack_target_id`는 디자인상 **전술 표식**이다. 단일 대상 공격 또는 지휘 카드가 갱신하고, 동료 기본 공격의 우선 대상을 결정한다.

### PartyState

```txt
protagonist_id
recruited_companions
max_companions = 2
```

### CompanionInstance

```txt
companion_id
passive_level
reward_bonus_level
owned_card_ids
available_card_ids
upgraded_card_ids
is_recruited
recruited_act
```

### InventoryState

```txt
equipment_inventory
gear_slots_by_character
```

장비 슬롯 예시:

```txt
gear_slots_by_character = {
  "protagonist": {
    "helmet": null,
    "armor": null,
    "weapon": null
  },
  "companion_rowan": {
    "helmet": null,
    "armor": null,
    "weapon": null
  }
}
```

## 5. 전투 구현 흐름

### 전투 시작

```txt
1. RunState에서 덱 복사
2. draw_pile 셔플
3. CombatState 생성
4. 적 데이터 로드
5. 전투 시작 파워/장비/동료 패시브 적용
6. 첫 턴 시작
```

### 플레이어 턴 시작

```txt
1. energy = 4 + 장비/강화 보정
2. 카드 6장 드로우 + 보정
3. 턴 시작 효과 처리
4. 적 의도 표시 갱신
```

### 카드 사용

```txt
CardView 클릭/드래그
→ CombatController.request_play_card(card_instance, target_id)
→ 카드 사용 가능 여부 검사
→ energy 차감
→ CardEffectResolver.resolve(card, target)
→ 단일 대상 공격/지휘 카드라면 전술 표식 갱신
→ CombatState 갱신
→ UI 갱신
```

### 턴 종료

```txt
1. 손패 버림
2. 플레이어 턴 종료 효과 처리
3. CompanionCombatSystem.perform_end_turn_attacks()
4. 적 턴 처리
5. 방어도 제거
6. 다음 턴 시작
```

## 6. 동료 전투 시스템

`CompanionCombatSystem`이 담당한다.

```txt
perform_end_turn_attacks(combat_state)
resolve_companion_attack(companion, target)
select_target_for_companion(combat_state)
```

대상 선택:

```txt
1. combat_state.last_player_attack_target_id가 살아 있으면 해당 대상.
2. 아니면 HP가 가장 낮은 적.
3. 동률이면 가장 앞쪽 적.
```

동료는 체력이 없으므로 EnemyAI는 동료를 직접 타겟팅하지 않는다.

## 7. 카드 효과 처리 방식

카드 효과는 데이터의 `effects` 배열을 읽고 처리한다.

예:

```json
{
  "id": "basic_strike",
  "type": "attack",
  "cost": 1,
  "effects": [
    {"type": "damage", "amount": 6, "target": "enemy"}
  ]
}
```

`CardEffectResolver`는 effect type별로 처리한다.

허용 effect type 예시:

```txt
damage
block
draw
discard
exhaust
heal
apply_status
gain_energy
reduce_cost_this_combat
splash_damage
combo_marker
upgrade_card
remove_card
transform_card
```

금지 effect type:

```txt
create_card
add_status_card
add_curse
potion_effect
relic_trigger
```

## 8. 장비 효과 처리 방식

장비 효과는 `EquipmentEffectResolver`가 처리한다.

효과 범위:

```txt
team_passive
owner_only
```

예:

```json
{
  "id": "healer_silver_charm",
  "slot": "helmet",
  "scope": "owner_only",
  "effects": [
    {"type": "healing_done_multiplier", "value": 1.2}
  ]
}
```

힐러가 장착하면 의미가 있고, 딜러가 장착하면 힐 카드가 없어서 사실상 의미가 없을 수 있다.

## 9. 장비 교체 타이밍

장비는 다음 노드 선택 화면에서 자유롭게 교체 가능하다.

구현:

```txt
MapScreen에서 EquipmentInventoryScreen을 열 수 있다.
전투 중에는 장비 교체 불가.
이벤트 선택지 중에는 기본적으로 장비 교체 불가.
상점에서는 구매 후 즉시 인벤토리에 들어가며, 다음 노드 선택 화면에서 장착 가능.
```

## 10. 보상 생성 흐름

### 일반 전투

```txt
gold_reward
card_reward_3
card_reward_skip_gold
10% chance treasure/special event
```

### 엘리트

```txt
gold_reward
card_reward_3
elite_upgrade_reward_3
```

### 보스

```txt
Act 1/2: companion_reward_3
Act 3: ending
```

## 11. 여관 구현 흐름

```txt
InnGenerator.generate_inn()
→ 일반/이벤트 판정
→ 방 3개 생성
→ InnScreen 표시
→ 방 선택
→ 골드 지불 가능 여부 확인
→ InnResultResolver.resolve(room)
→ RunState 갱신
```

일반 여관은 정직한 결과만.

이벤트 여관은 가격/효과 변동 가능. 단, 결과는 긍정적 변동성 원칙을 지킨다.

## 12. 모바일/PC 입력

PC와 모바일 모두 가로 화면이다.

입력은 `InputAdapter`가 추상화한다.

```txt
마우스 클릭 = 터치 탭
마우스 드래그 = 터치 드래그
롱프레스 = 툴팁 표시
우클릭/상세보기 = 모바일에서는 길게 누르기
```

## 13. 해상도/레이아웃

기본 설계는 16:9 가로를 기준으로 한다.

```txt
기준 해상도: 1920x1080
모바일 최소 대응: 1280x720 가로
UI는 Control 노드 anchor/container 기반
카드 텍스트는 모바일에서 읽힐 크기를 유지
```

## 14. Codex 구현 순서

아래 순서로 구현한다.

```txt
1. DataRegistry와 기본 JSON 로딩
2. balance_constants.json과 기본 수치 조회
3. 카드 데이터/덱/카드 이동
4. CombatState와 TurnManager
5. 카드 사용, 전술 표식, 적 처치
6. 보상 생성과 카드 보상 스킵
7. 맵 1Act 흐름과 Act 1 동료 예고 이벤트
8. 동료 영입
9. 동료 전투 공격
10. 엘리트 강화
11. 상점/여관/이벤트
12. 장비 인벤토리
13. 저장/로드
```

## 15. 플레이테스트 지표

첫 구현부터 아래 지표를 `RunTelemetry`에 쌓을 수 있게 준비한다. UI로 보여줄 필요는 없고, 개발 로그 또는 저장 데이터에 남겨도 된다.

```txt
전투별 턴 수
전투별 체력 손실
카드별 보상 등장 횟수
카드별 선택 횟수
카드 보상 스킵 횟수
동료별 후보 등장/선택 횟수
동료별 승리 런 포함 횟수
장비 구매/장착 횟수
여관 방 선택 횟수
상점 서비스 구매 횟수
이벤트 선택지 선택 횟수
런 사망 노드
```

수동 밸런스 조정 단계에서는 이 지표를 표로 뽑아 카드, 동료, 이벤트의 죽은 선택지를 찾는다.

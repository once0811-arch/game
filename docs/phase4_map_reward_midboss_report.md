# Phase 4 맵, 보상, Act 1 중간 보스 보고

작성일: 2026-05-26

## 결과 요약

Act 1의 12노드 맵 흐름을 만들고, depth 6 중간 보스 고정, 전투 승리 후 카드 보상, 보상 후 다음 노드 이동을 연결했다.

```txt
맵 데이터: res://data/encounters/act1_encounters.json
맵 화면: res://scenes/map/map_screen.tscn
전투 화면: res://scenes/combat/combat_screen.tscn
보상 화면: res://scenes/reward/card_reward_screen.tscn
```

## 구현 범위

| 영역 | 파일 | 내용 |
|---|---|---|
| 인카운터 데이터 | `data/encounters/act1_encounters.json` | Act 1 12노드, depth 6 midboss 고정 |
| 맵 생성 | `scripts/map/map_generator.gd` | encounter 데이터 기반 선형 Act 1 맵 생성 |
| 맵 상태 | `scripts/map/map_state.gd` | 현재 depth, 선택 노드, 완료 노드, 저장 snapshot |
| 보상 상태 | `scripts/rewards/reward_state.gd` | 전투 보상 완료 후 맵 노드 완료 처리 |
| 맵 UI | `scripts/ui/map_screen.gd` | 노드 버튼, 잠김/완료/진행 가능 표시 |
| 전투 연결 | `scripts/combat/combat_screen.gd` | 선택된 맵 노드의 enemy_id로 전투 시작 |
| 보상 연결 | `scripts/rewards/card_reward_screen.gd` | 카드 선택/스킵 후 맵 진행 완료 |

## 현재 Act 1 맵 규칙

```txt
총 노드 수: 12
현재 구조: 선형 진행
다음 노드만 선택 가능
depth 6: midboss / Blackened Guard 고정
depth 7: companion_contract 자리 고정, 실제 동료 영입은 Phase 5에서 구현
depth 12: boss 자리 고정, 실제 Act 1 보스 흐름은 후속 Phase에서 강화
```

비전투 노드인 event, inn, shop, companion_contract는 현재 선택 즉시 완료되는 placeholder다. 이들은 Phase 5~7에서 실제 화면과 보상으로 확장한다.

## Godot 확인 절차

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. 실행 버튼을 누른다.
3. New Run을 누르면 Act 1 Route에 12개 노드가 보이는지 확인한다.
4. depth 6이 midboss / Blackened Guard인지 확인한다.
5. depth 1 combat 노드를 누르면 Combat Test가 선택 노드의 적으로 시작되는지 확인한다.
6. 전투에서 승리한 뒤 Claim Reward를 누른다.
7. Card Reward에서 카드 선택 또는 Skip을 한다.
8. Continue로 맵에 돌아오면 depth 1이 Done, depth 2가 선택 가능해졌는지 확인한다.
9. Save Snapshot 후 Continue로 맵 진행도가 복원되는지 확인한다.
```

## 검증

```txt
Godot 4.6.3 headless main scene run 통과
Godot 4.6.3 headless map_screen scene run 통과
Godot 4.6.3 headless combat_screen scene run 통과
Godot 4.6.3 headless card_reward_screen scene run 통과
Act 1 노드 12개 검증 통과
depth 6 midboss 고정 검증 통과
노드 enemy_id가 enemies_act1.json에 존재하는지 검증 통과
적 asset_id가 Phase 0 manifest에 존재하는지 검증 통과
git diff --check 통과
```

## 페이즈 반성

잘 된 점:

```txt
1. 전투가 독립 테스트에서 맵의 한 칸으로 연결되었다.
2. 전투 승리 -> 카드 보상 -> 맵 진행 완료의 로그라이크 기본 순환이 생겼다.
3. depth 6 중간 보스를 데이터로 고정해 Phase 5의 첫 동료 영입 위치가 준비되었다.
4. MapState도 저장 snapshot에 포함해 Continue가 진행도를 잃지 않게 했다.
```

부족한 점:

```txt
1. 맵은 아직 선형이라 경로 선택의 재미가 없다.
2. 비전투 노드가 즉시 완료 placeholder라 여관/상점/이벤트의 역할이 없다.
3. 중간 보스 이후 companion_contract 노드는 자리만 있고 실제 동료 영입은 없다.
4. 전투 승리 보상은 카드 보상만 있어 골드/장비/이벤트 보상 다양성이 부족하다.
```

반영한 개선:

```txt
1. 전투 보상 완료 시 RewardState가 MapState.complete_selected_node를 호출하게 해 진행 루프를 닫았다.
2. Save Snapshot에 MapState를 포함해 맵 진행 저장/복원이 가능해졌다.
3. depth 7 companion_contract를 미리 배치해 다음 Phase의 핵심 재미가 정확한 위치에 붙을 수 있게 했다.
```

## 다음 단계

Phase 5에서는 depth 6 중간 보스 처치 후 depth 7에서 첫 동료 영입, 서약 전술 3택 중 1개 선택, 동료 카드 선택을 구현한다. 여기서 핵심 재미는 `동료가 단순 보상 카드가 아니라 이후 전투 방향을 바꾸는 계약 선택으로 느껴지는가`다.

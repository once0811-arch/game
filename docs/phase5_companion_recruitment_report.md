# Phase 5 동료 영입과 두 번째 동료 보고

작성일: 2026-05-26

## 결과 요약

Act 1 중간 보스 이후 첫 동료, Act 1 보스 이후 두 번째 동료를 영입할 수 있는 계약 흐름을 구현했다.

```txt
동료 데이터: res://data/companions/companions.json
동료 카드 데이터: res://data/cards/companion_cards.json
동료 선택 화면: res://scenes/companion/companion_reward_screen.tscn
서약 전술 선택 화면: res://scenes/companion/oath_tactic_select_screen.tscn
동료 카드 선택 화면: res://scenes/companion/companion_card_select_screen.tscn
```

## 구현 범위

| 영역 | 파일 | 내용 |
|---|---|---|
| 동료 데이터 | `data/companions/companions.json` | 동료 10명, 각 서약 전술 3개 |
| 동료 카드 | `data/cards/companion_cards.json` | 동료별 카드 3장, 총 30장 |
| 파티 상태 | `scripts/state/party_state.gd` | 동료 중복 방지, 파티 요약 표시 |
| 동료 관리 | `scripts/systems/companion_manager.gd` | 선택 동료/서약/카드, 최종 영입 처리 |
| 동료 보상 생성 | `scripts/rewards/companion_reward_generator.gd` | 이미 영입한 동료 제외, 3택 생성 |
| 영입 UI | `scripts/companion/*.gd` | 동료 선택, 서약 전술 선택, 카드 2장 선택 |
| 맵 연결 | `scripts/ui/map_screen.gd` | companion_contract 노드에서 동료 영입 진입 |
| 보스 연결 | `scripts/combat/combat_screen.gd` | boss 전투 승리 후 두 번째 동료 영입 진입 |

## 현재 영입 규칙

```txt
최대 동료 수: 2명
동료 후보: 10명
동료 선택지: 최대 3명
동료 선택지 생성: 이미 영입한 동료 제외 후 랜덤 3택
동료마다 서약 전술: 3개
서약 전술 선택: 1개
동료 카드 후보: 3장
동료 카드 선택: 2장
선택한 동료 카드는 discard pile에 추가
이미 영입한 동료는 다음 3택에서 제외
동료 카드는 일반 카드 보상 풀에서 제외
```

## Godot 확인 절차

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. New Run으로 Act 1 맵에 들어간다.
3. depth 6 midboss를 처치하고 보상을 받아 depth 7을 연다.
4. depth 7 companion_contract를 누른다.
5. 동료 3택이 보이는지 확인한다.
6. 동료 하나를 선택하고 서약 전술 3개 중 1개를 선택한다.
7. 동료 카드 3장 중 2장을 선택하고 Sign Contract를 누른다.
8. 맵으로 돌아와 동료 패널에 동료와 서약 이름이 표시되는지 확인한다.
9. Act 1 boss를 처치한 뒤 같은 흐름으로 두 번째 동료를 영입한다.
```

## 검증

```txt
Godot 4.6.3 headless main scene run 통과
Godot 4.6.3 headless companion_reward scene run 통과
Godot 4.6.3 headless oath_tactic_select scene run 통과
Godot 4.6.3 headless companion_card_select scene run 통과
동료 10명 검증 통과
각 동료 서약 전술 3개 검증 통과
각 동료 카드 3장 검증 통과
동료/카드 asset_id manifest 참조 검증 통과
동료 카드가 일반 카드 보상 풀에서 제외되는지 검증 통과
git diff --check 통과
```

## 페이즈 반성

잘 된 점:

```txt
1. 동료가 단순 카드 보상이 아니라 계약 선택, 서약 전술 선택, 카드 선택의 3단계 보상으로 분리되었다.
2. 영입 시 서약 전술을 3개 중 1개로 고정하고 업그레이드하지 않는 기존 기획을 코드 구조에 반영했다.
3. 동료 카드 3장 중 2장을 고르게 해서 영입 순간에도 덱 방향 선택이 생겼다.
4. 이미 영입한 동료를 제외하므로 두 번째 동료 선택이 중복되지 않는다.
5. 맵 화면에 동료 패널이 표시되어 현재 계약 상태를 확인할 수 있다.
```

부족한 점:

```txt
1. 동료 선택 UI는 아직 캐릭터 매력과 초상 활용을 더 키워야 한다.
2. 동료별 최종 목표 카드 8장 중 현재 플레이 가능 구현은 3장이다.
3. 개별 패시브는 아직 별도 시스템이 아니라 서약 전술과 유대 보너스가 역할을 대신한다.
```

반영한 개선:

```txt
1. 3명만 만들면 두 번째 동료 때 3택이 깨지므로 동료 후보를 10명으로 확장했다.
2. 동료 카드는 일반 카드 보상 풀에서 제외해 영입 전 카드 보상에 섞이지 않게 했다.
3. 동료 카드 선택은 toggle 방식으로 처리해 같은 카드를 중복 선택할 수 없게 했다.
4. 동료 후보 3택은 항상 같은 순서가 나오지 않도록 랜덤 후보로 바꿨다.
```

## 다음 단계

Phase 6 이후에는 동료 기본 공격, 서약 전술 발동, 유대 점수 0~100 및 30/60/100 보너스가 실제 전투에 연결되었다. 다음 개선의 핵심은 `동료를 데려온 뒤 전투 판단이 더 선명하고 더 예쁘게 보이는가`다.

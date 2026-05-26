# Phase 3 최소 전투 보고

작성일: 2026-05-26

## 결과 요약

주인공과 Act 1 적 1마리가 싸우는 최소 전투를 구현했다. 카드 사용, 에너지 소비, 피해/방어, 전술 표식, 적 의도, 턴 종료, 승리/패배 판정, 임시 보상 화면 진입까지 연결했다.

```txt
전투 씬: res://scenes/combat/combat_screen.tscn
카드 보상 씬: res://scenes/reward/card_reward_screen.tscn
적 데이터: res://data/enemies/enemies_act1.json
메인 메뉴 버튼: Combat Test
맵 화면 버튼: Combat Test
```

## 구현 범위

| 영역 | 파일 | 내용 |
|---|---|---|
| 적 데이터 | `data/enemies/enemies_act1.json` | Act 1 일반 적 2종, HP, 에셋, 의도 패턴 |
| 턴 진행 | `scripts/combat/turn_manager.gd` | 전투 시작, 카드 사용, 턴 종료, 승패 판정 |
| 카드 효과 | `scripts/combat/card_effect_resolver.gd` | 피해, 방어, 드로우, 에너지, 체력 교환, 전술 표식 |
| 적 행동 | `scripts/combat/enemy_ai_resolver.gd` | 공격/방어 의도 순환 및 실행 |
| 전투 상태 | `scripts/state/combat_state.gd` | 에너지, 블록, 표식 보너스, outcome 저장 |
| 전투 화면 | `scripts/combat/combat_screen.gd` | 임시 에셋 표시, 손패, 적 의도, 로그, 보상 버튼 |
| 보상 화면 | `scripts/rewards/card_reward_screen.gd` | 전투 승리 후 3택/스킵 골드 |

## 현재 전투 규칙

```txt
턴 에너지: 4
턴 드로우: 6
기본 테스트 적: Mutated Merchant, HP 42
공격 카드는 피해 후 적이 살아 있으면 Tactical Mark 1 부여
피해는 대상의 Tactical Mark 수치만큼 증가
방어는 플레이어 블록 또는 적 블록으로 처리
턴 종료 시 적 의도 실행 후 다음 턴 6장 드로우
```

전술 표식은 아직 단순하다. 하지만 `표식을 쌓으면 이후 공격 피해가 올라간다`는 최소 감각은 생겼다.

## Godot 확인 절차

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. 실행 버튼을 누른다.
3. Main Menu에서 Combat Test를 누른다.
4. 손패 6장, 에너지 4, 적 HP와 의도가 보이는지 확인한다.
5. Strike 또는 Heavy Cut을 누르면 적 HP가 줄고 Mark가 증가하는지 확인한다.
6. Guard를 누르면 플레이어 Block이 증가하는지 확인한다.
7. End Turn을 누르면 적 의도가 실행되고 다음 턴 손패가 다시 채워지는지 확인한다.
8. 적 HP를 0으로 만들면 Claim Reward 버튼이 보이는지 확인한다.
9. Claim Reward를 눌러 Card Reward 화면에서 카드 선택/스킵 골드가 동작하는지 확인한다.
```

## 검증

```txt
Godot 4.6.3 headless main scene run 통과
Godot 4.6.3 headless combat_screen scene run 통과
Godot 4.6.3 headless card_reward_screen scene run 통과
Godot 4.6.3 headless deck_debug scene run 재확인 통과
카드 12종 / 시작 덱 10장 검증 통과
적 2종 검증 통과
카드/적 asset_id가 Phase 0 manifest에 존재하는지 검증 통과
git diff --check 통과
```

## 페이즈 반성

잘 된 점:

```txt
1. 카드가 드디어 실제 적 상태를 바꾸기 시작했다.
2. 4에너지/6드로우 구조에서 2~3코스트 카드가 실제로 선택 압박을 만든다.
3. 공격 카드가 전술 표식을 쌓고, 표식이 다음 피해를 키우는 기본 시너지가 생겼다.
4. 적 의도가 보여서 턴 종료 전에 방어할지 공격할지 판단할 최소 정보가 생겼다.
5. 승리 후 보상 선택까지 이어져 로그라이크 덱빌딩의 한 사이클이 보이기 시작했다.
```

부족한 점:

```txt
1. 타겟팅은 아직 첫 번째 적 자동 대상이라 손맛이 약하다.
2. 적이 1마리뿐인 테스트 전투라 광역/다중 대상 판단이 없다.
3. 보상 화면은 Phase 4용 임시 연결이며, 맵 노드/전투 결과와 아직 완전히 묶이지 않았다.
4. 카드 UI가 버튼 중심이라 시각적 카드 촉감은 여전히 약하다.
```

반영한 개선:

```txt
1. Phase 3 요구에는 없던 얇은 카드 보상 화면을 추가해 전투 승리 후 흐름이 끊기지 않게 했다.
2. 공격 카드에 Tactical Mark 자동 부여를 넣어 첫 전투부터 우리 게임의 전술 표식 축이 보이게 했다.
3. 메인/맵에서 Combat Test로 바로 들어갈 수 있게 해 Godot 확인 동선을 짧게 만들었다.
```

## 다음 단계

Phase 4에서는 맵 노드, 전투 승리 후 보상, 다음 노드 이동, Act 1 중간 보스 고정을 연결한다. 여기서 재미 검증의 핵심은 `전투 하나가 독립 테스트가 아니라 여정의 한 칸으로 느껴지는가`다.

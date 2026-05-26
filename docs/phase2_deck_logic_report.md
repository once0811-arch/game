# Phase 2 카드와 덱 로직 보고

작성일: 2026-05-26

## 결과 요약

전투 없이 카드 데이터, 시작 덱, 드로우/버림/셔플, 카드 보상 3택과 스킵 골드를 확인할 수 있는 Phase 2를 구현했다.

```txt
카드 데이터: res://data/cards/protagonist_cards.json
덱 디버그 씬: res://scenes/debug/deck_debug.tscn
메인 메뉴 버튼: Deck Debug
맵 화면 버튼: Deck Debug
```

## 구현 범위

| 영역 | 파일 | 내용 |
|---|---|---|
| 카드 데이터 | `data/cards/protagonist_cards.json` | 주인공 카드 12종, 시작 덱 10장 |
| 카드 유틸 | `scripts/data/card_data.gd` | 비용, 이름, 타입, 희귀도, 보상 후보 판정 |
| 카드 인스턴스 | `scripts/state/card_instance.gd` | 덱 안의 개별 카드 식별자 |
| 덱 상태 | `scripts/state/deck_state.gd` | 시작 덱 생성, 드로우, 사용 후 버림, 손패 버림, 셔플 |
| 보상 생성 | `scripts/systems/card_reward_generator.gd` | 희귀도 가중치 기반 3택 보상, 스킵 골드 |
| 디버그 화면 | `scripts/debug/deck_debug.gd` | 손패 버튼, 에너지, pile 수량, 로그, 보상 선택 |

## 현재 카드 밸런스 의도

```txt
턴 에너지: 4
턴 드로우: 6
시작 덱: 10장
보상 선택지: 3장
스킵 골드: 15
```

카드 비용 분포는 4에너지/6드로우가 모든 카드를 다 쓰는 구조가 되지 않도록 잡았다.

```txt
0코스트: 2종
1코스트: 3종
2코스트: 4종
3코스트: 3종
```

현재 의도는 매턴 손패는 넓게 보이되, 2~3코스트 카드 때문에 실제 선택은 압축되게 만드는 것이다. 특히 `Risk Advance`, `Blood Price`, `Last Light`는 회복/자원/체력 교환 카드의 초기 방향성을 확인하기 위한 씨앗이다.

## Godot 확인 절차

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. 실행 버튼을 누른다.
3. Main Menu에서 Deck Debug를 누른다.
4. 손패가 6장 표시되는지 확인한다.
5. 에너지가 충분한 카드를 누르면 discard로 이동하고 에너지가 줄어드는지 확인한다.
6. End Turn을 누르면 남은 손패가 버려지고 다시 6장을 드로우하는지 확인한다.
7. Draw 6을 반복해 draw pile이 부족할 때 discard가 섞이는 로그가 뜨는지 확인한다.
8. Reward Options에서 카드 하나를 고르면 discard에 추가되는지 확인한다.
9. Skip Reward를 누르면 골드가 15 증가하는지 확인한다.
```

## 검증

```txt
Godot 4.6.3 headless main scene run 통과
Godot 4.6.3 headless deck_debug scene run 통과
protagonist_cards.json / balance_constants.json JSON 검증 통과
시작 덱 10장 검증 통과
시작 덱 카드 ID 누락 0개
draw_per_turn 6 검증 통과
energy_per_turn 4 검증 통과
reward_options 3 검증 통과
보상 후보 카드 8장 검증 통과
git diff --check 통과
```

## 페이즈 반성

잘 된 점:

```txt
1. 이제 게임의 핵심 루프인 카드 선택의 최소 단위가 화면에서 보인다.
2. 4에너지/6드로우가 과한 자원으로 느껴지지 않도록 2~3코스트 카드 비중을 의도적으로 높였다.
3. 카드 보상 3택과 스킵 골드가 들어가면서 로그라이크 덱빌딩의 성장 선택 자리가 생겼다.
4. 덱 상태를 RunState 안에 넣어 이후 전투/보상/저장과 이어질 수 있게 했다.
```

부족한 점:

```txt
1. 아직 적, 피해, 방어, 전술 표식 대상이 없어서 카드 효과의 재미는 텍스트와 비용 감각에 머문다.
2. 카드 보상은 희귀도 가중치만 있고, 현재 덱/동료/체력 상황을 반영하지 않는다.
3. 카드 UI는 버튼 기반이라 카드 게임의 촉감과 시각적 만족은 아직 부족하다.
```

반영한 개선:

```txt
1. Deck Debug 진입 시 보상 3택도 즉시 생성해 보상 시스템이 실제로 로딩되는지 검증되게 했다.
2. Skip Reward 버튼에 획득 골드를 표시해 선택 결과가 보이게 했다.
3. 시작 덱에 2코스트 카드를 포함해 첫 턴부터 모든 카드를 무조건 쓰는 감각을 줄였다.
```

## 다음 단계

Phase 3에서는 이 카드들이 실제 적에게 피해/방어/전술 표식을 적용하도록 최소 전투를 만든다. 여기서 가장 중요한 재미 검증은 `비용 높은 카드가 답답한가, 아니면 6장 손패 속 선택의 무게로 작동하는가`다.

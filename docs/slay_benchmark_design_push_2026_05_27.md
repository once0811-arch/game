# Slay Benchmark Design Push - 2026-05-27

## Goal

이번 패스의 목표는 새 시스템을 늘리는 것이 아니라, 이미 구현된 전투/지도/보상 루프가 더 즉시 플레이 가능한 게임처럼 읽히게 만드는 것이다. 기준은 `Docs/slay_the_spire_uiux_element_analysis.md`의 핵심 원칙이다.

```txt
플레이어가 지금 무엇을 결정해야 하는가?
그 결정을 위해 가장 먼저 읽혀야 하는 정보는 무엇인가?
반복되는 정보는 짧고 안정적인 위치에 있는가?
```

## Applied Changes

### Combat

- 상단 HUD에 `Incoming N -> HP M` 전투 예보를 추가했다.
- 적 의도 위에 있는 개별 공격 수치와 별개로, 플레이어가 이번 턴 총 위험을 한 번에 읽을 수 있게 했다.
- 차단이 충분한 경우 파란색, 실제 체력 손실이 예상되는 경우 붉은색으로 표시한다.
- 더미 정보는 `Turn / Draw / Discard / Exhaust`로 짧게 유지해 카드 순환 판단에 필요한 숫자만 보여준다.

### Map

- 우측 패널을 단순 범례에서 `Legend + Next Contract` 작전서 패널로 확장했다.
- 기본 상태에서도 첫 선택 후보의 노드 종류, 이름, 깊이, 가치/위험 요약을 보여준다.
- hover 시 해당 노드의 웨이브, 적 구성, 위험/보상 목적이 패널에 들어간다.
- 한 화면에 모든 정보를 밀어 넣지 않고, 스크롤 지도에서 현재 선택 후보를 크게 읽는 방향을 유지한다.

### Reward

- 스킵 골드를 하단 보조 버튼에서 네 번째 전리품 카드로 승격했다.
- 카드 추가와 골드 획득이 같은 급의 선택처럼 보이게 했다.
- 보상 화면 상단에 현재 `HP / Gold / Deck` 요약을 추가해, 덱을 키울지 경제를 택할지 판단이 쉬워지게 했다.

## Visual QA

Generated captures:

```txt
/tmp/deckbuilder_push/combat_1280.png
/tmp/deckbuilder_push/combat_1920.png
/tmp/deckbuilder_push/map_1280.png
/tmp/deckbuilder_push/map_1920.png
/tmp/deckbuilder_push/reward_1280.png
/tmp/deckbuilder_push/reward_1920.png
```

Checks passed:

- 전투 1280x720, 1920x1080에서 카드 fan, 에너지, End Turn, 적 의도, 전투 예보가 겹치지 않는다.
- 지도 1280x720에서 우측 작전서 패널이 범례와 다음 선택 요약을 함께 보여준다.
- 보상 1280x720, 1920x1080에서 카드 3장과 골드 선택지가 한 줄 선택지로 읽힌다.

Known follow-up:

- 지도 우측 패널은 동작 면에서는 좋아졌지만, 최종 아트 단계에서는 실제 작전서/금속 증표 물성으로 더 강하게 묶는 것이 좋다.
- 보상 화면은 선택 구조가 좋아졌으나, 카드 프레임/아이콘 아트가 더 좋아지면 전리품 감각이 크게 오른다.
- 전투 배경과 캐릭터는 아직 임시 픽셀 에셋이므로, 애니메이션과 타격감 패스가 계속 필요하다.

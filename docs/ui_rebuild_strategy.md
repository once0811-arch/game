# Godot UI Rebuild Strategy

작성일: 2026-05-26

목적: 지금부터의 UI 작업은 임시로 보기 좋게 고치는 방식이 아니라, 실제 출시 가능한 덱빌딩 로그라이크 화면을 만들기 위한 구조 재개발로 진행한다. 기준은 Slay the Spire식 정보 위계, Godot의 Control/Theme 정석, 검증된 오픈소스 Godot 덱빌더 구조다.

## 결론

현재 프로젝트는 게임 규칙과 데이터는 꽤 쌓였지만, UI는 아직 `화면별 절차형 스크립트가 직접 모든 노드를 만드는 구조`에 가깝다. 이 방식은 빠르게 MVP를 만들기에는 좋지만, 진짜 게임 화면처럼 보이게 만드는 데에는 한계가 있다.

다음 UI 작업은 새 버튼을 더 붙이는 것이 아니라 아래 방향으로 간다.

```txt
화면별 거대 스크립트
→ 재사용 가능한 UI 컴포넌트
→ Theme/StyleBox 기반 공통 스킨
→ 카드 상태머신과 타겟 셀렉터
→ 화면 캡처 기반 시각 QA
→ 전투, 맵, 보상, 상점, 여관, 이벤트 순서로 완성도 고정
```

## 조사한 자료

### Godot 공식 문서

- [Godot UI documentation](https://docs.godotengine.org/en/4.4/tutorials/ui/index.html)
- [Godot Control class](https://docs.godotengine.org/en/4.0/classes/class_control.html)
- [Godot GUI skinning and themes](https://docs.godotengine.org/en/4.3/tutorials/ui/gui_skinning.html)
- [Godot CanvasLayer](https://docs.godotengine.org/en/4.6/tutorials/2d/canvas_layers.html)

핵심 적용:

- UI는 `Control` 노드 중심으로 만들고, 배치와 크기는 Container/anchor/custom minimum size를 명확히 사용한다.
- 전역 룩은 개별 버튼마다 즉석 스타일을 넣기보다 `Theme`, `StyleBox`, 공통 helper로 통일한다.
- 전투 HUD, 드래그 프리뷰, 말풍선 피드백, 모달은 `CanvasLayer` 또는 레이어 규칙으로 전장/카드/팝업의 z-order를 안정화한다.
- 드래그는 `Control._get_drag_data`, `_can_drop_data`, `_drop_data` 정석 API를 검토하되, Slay식 카드 타겟팅은 별도 TargetSelector가 더 명확하다.

### guladam/deck_builder_tutorial

- 레포: [guladam/deck_builder_tutorial](https://github.com/guladam/deck_builder_tutorial)
- 로컬 확인 파일:
  - `/tmp/deckbuilder_ui_refs/guladam/scenes/battle/battle.gd`
  - `/tmp/deckbuilder_ui_refs/guladam/scenes/ui/battle_ui.gd`
  - `/tmp/deckbuilder_ui_refs/guladam/scenes/ui/hand.gd`
  - `/tmp/deckbuilder_ui_refs/guladam/scenes/card_ui/card_ui.gd`
  - `/tmp/deckbuilder_ui_refs/guladam/scenes/card_target_selector/card_target_selector.gd`
  - `/tmp/deckbuilder_ui_refs/guladam/scenes/map/map.gd`
  - `/tmp/deckbuilder_ui_refs/guladam/scenes/map/map_room.gd`
  - `/tmp/deckbuilder_ui_refs/guladam/global/events.gd`

가져올 점:

- `Battle`은 게임 진행을 조정하고, `BattleUI`는 UI만 맡는다.
- `Hand`, `CardUI`, `CardStateMachine`, `CardTargetSelector`가 분리되어 있다.
- 카드 조준 arc는 별도 씬이 처리한다. 카드 자체가 적 판정과 선 그리기를 모두 떠안지 않는다.
- 맵은 `MapRoom` 노드와 `MapLine` 노드로 구성되고, 선택 가능 상태는 노드 애니메이션으로 표현한다.
- 전역 signal bus가 있어 화면 요소들이 서로 직접 참조하지 않는다.

우리 적용:

- `combat_screen.gd`를 계속 키우지 않는다.
- `CombatScreen` 아래에 `BattleHud`, `BattlefieldView`, `EnemyView`, `PlayerView`, `CompanionStrip`, `HandView`, `TargetSelector`, `CombatFeedbackLayer`를 분리한다.
- `map_screen.gd`는 `MapNodeView`, `MapLineView`, `RouteTooltip`, `RunHud`로 나눈다.

### DesirePathGames/Slay-The-Robot

- 레포: [DesirePathGames/Slay-The-Robot](https://github.com/DesirePathGames/Slay-The-Robot)
- 로컬 확인 파일:
  - `/tmp/deckbuilder_ui_refs/slay_robot/scenes/ui/Card.tscn`
  - `/tmp/deckbuilder_ui_refs/slay_robot/data/CardPlayRequest.gd`
  - `/tmp/deckbuilder_ui_refs/slay_robot/scripts/actions/BaseAction.gd`
  - `/tmp/deckbuilder_ui_refs/slay_robot/scripts/validators/card_plays/ValidatorCardPlayEnergyInput.gd`

가져올 점:

- 카드 플레이를 `CardPlayRequest`라는 데이터 payload로 다룬다.
- 실제 효과는 `Action`으로 실행하고, 플레이 가능 여부는 `Validator`가 판단한다.
- UI가 “이 카드를 쓸 수 있는가”를 직접 계산하지 않고, 규칙 계층에 묻는다.
- 카드 씬은 이름, 비용, 설명, 키워드 컨테이너, 애니메이션을 한 컴포넌트로 가진다.

우리 적용:

- 지금의 `CardPlayRules.requires_enemy_target()`는 너무 작다. 단기적으로는 `CardPlayRules`를 확장해 `can_play_card()`, `validate_target()`, `failure_message()`까지 제공하게 한다.
- 중기적으로는 `CardPlayRequest`와 `ActionResult`를 도입해 카드 사용, 서약 발동, 장비 효과, 적 의도를 같은 파이프라인에서 미리보기/실행한다.
- UI는 검증 결과를 받아 카드 비활성, 타겟 가능 표시, 에너지 부족 말풍선만 표현한다.

### chun92/card-framework

- 레포: [chun92/card-framework](https://github.com/chun92/card-framework)
- Asset Library: [Card Framework](https://godotengine.org/asset-library/asset/3616)
- 로컬 확인 파일:
  - `/tmp/deckbuilder_ui_refs/card_framework/addons/card-framework/hand.gd`
  - `/tmp/deckbuilder_ui_refs/card_framework/addons/card-framework/card_container.gd`
  - `/tmp/deckbuilder_ui_refs/card_framework/addons/card-framework/card.gd`

가져올 점:

- `Hand`가 수학적 곡선으로 카드 fan layout을 계산한다.
- 카드 컨테이너는 drop zone, reorder, hover, holding state를 독립적으로 관리한다.
- 손패는 고정된 layout box 안에서 대칭적으로 퍼지며, 카드 수가 바뀌어도 중심이 흔들리지 않는다.
- 프레임워크는 MIT이고 Kenney 카드 에셋을 CC0로 사용한다.

우리 적용:

- 프레임워크 전체 import는 당장 하지 않는다. 현재 RunState/DeckState/CombatState와 충돌 위험이 있다.
- 대신 `Hand`의 핵심 원칙을 이식한다: 고정 layout box, 카드 수 기반 fan spread, hover distance, z-index, 중앙 정렬.
- 카드 드래그/hover는 지금처럼 임시 tween만 두지 말고 카드 상태를 `IDLE`, `HOVER`, `SELECTED`, `DRAGGING`, `DISABLED`, `PLAYED`로 분리한다.

### statico/godot-roguelike-example

- 레포: [statico/godot-roguelike-example](https://github.com/statico/godot-roguelike-example)
- 로컬 확인 파일:
  - `/tmp/deckbuilder_ui_refs/statico/src/modals.gd`
  - `/tmp/deckbuilder_ui_refs/statico/scenes/ui/hud.gd`
  - `/tmp/deckbuilder_ui_refs/statico/scenes/ui/inventory_modal.gd`
  - `/tmp/deckbuilder_ui_refs/statico/assets/ui/styles/*.tres`

가져올 점:

- 모달 stack을 관리하고 fade in/out을 통일한다.
- HUD, inventory, equipment UI가 전투 로직과 분리되어 있다.
- `.tres` StyleBox/Theme 자산으로 UI 스타일을 관리한다.
- 디버그 도구와 실제 게임 UI가 분리되어 있다.

우리 적용:

- 보상, 상점, 여관, 이벤트, 카드 상세보기는 같은 `ModalStack` 패턴으로 통일한다.
- 장비 UI는 전투/맵 사이드 패널에 무작정 텍스트로 붙이지 않고, 장착 슬롯 컴포넌트와 tooltip으로 분리한다.
- 개발용 화면은 `scenes/debug`로 격리하고 일반 루프에서는 접근하지 않게 한다.

### 추가 Godot 레퍼런스

아래 레포는 작업 환경 준비 단계에서 추가로 조사했다.

| 레포 | 라이선스 판단 | 가져올 점 |
|---|---|---|
| [cyanglaz/gcard_layout](https://github.com/cyanglaz/gcard_layout) | MIT | Control 카드 손패 곡선 배치, hover padding, drag signal, 카드 수 기반 radius 계산 |
| [insideout-andrew/deckbuilder-framework](https://github.com/insideout-andrew/deckbuilder-framework) | MIT | 단순하고 읽기 쉬운 카드/덱 구조, target position으로 부드럽게 복귀하는 카드 움직임 |
| [db0/godot-card-game-framework](https://github.com/db0/godot-card-game-framework) | AGPL | 코드 복사 금지. target, card viewer, deck builder, test structure는 설계 참고만 |
| [ShayanMasoudzadeh/Slot-based-Inventory-System](https://github.com/ShayanMasoudzadeh/Slot-based-Inventory-System) | 라이선스 파일 없음 | 코드 복사 금지. 장비 슬롯 UI와 grabbed item preview UX 참고만 |

라이선스 정책:

```txt
MIT/CC0: 패턴 적용 가능, 필요 시 출처 기록.
AGPL: 코드 복사 금지. 구조 아이디어 참고만.
라이선스 없음: 코드 복사 금지. 화면/UX 참고만.
```

### 무료 에셋

- [Kenney Board Game Icons](https://kenney-assets.itch.io/board-game-icons)
- [Kenney Board Game Icons on kenney.nl](https://kenney.nl/assets/board-game-icons)
- [Kenney Playing Cards Pack on OpenGameArt](https://opengameart.org/content/playing-cards-pack)

가져올 점:

- Kenney Board Game Icons는 CC0이고, 250개 이상의 보드게임/카드게임 아이콘을 제공한다.
- Playing Cards Pack도 CC0이며 카드 back/front, dice, colored cards가 있어 카드 프레임/아이콘 임시 기반으로 좋다.
- 단, 그대로 붙이면 “에셋 조립 느낌”이 날 수 있으므로 우리 팔레트와 금속패/작전서 물성으로 tint와 프레임을 통일한다.

## 현재 프로젝트의 UI 문제 진단

### 구조 문제

- `combat_screen.gd`가 전투 레이아웃, 카드 UI 생성, 적 UI 생성, 드래그 arc, 로그, 보상 전환까지 모두 담당한다.
- `map_screen.gd`가 지도 생성, 선 그리기, 노드 버튼, 설명, 장비 패널, 저장 버튼까지 모두 담당한다.
- `CombatCardView`는 카드 컴포넌트로 분리되어 있지만, 카드 상태와 카드 플레이 검증이 아직 약하다.
- Theme 자산이 아니라 `UIStyleScript`의 즉석 StyleBox 생성에 많이 의존한다.

### 화면 문제

- 전투 화면에서 최종 플레이어가 봐야 할 것은 손패, 에너지, 적 intent, 대상 선택인데, 로그/패널/텍스트가 아직 남아 있다.
- 지도는 Slay식 경로 UI로 가는 중이지만, 작전서/노선도 물성과 선택 상태 연출이 더 필요하다.
- 보상/상점/여관/이벤트는 아직 같은 UI 언어로 묶이지 않았다.
- 화면 캡처 검증이 도구화되어 있지 않아, 깨진 화면이 다시 들어올 위험이 높다.

## 개발 전략

### 원칙 1. 화면을 먼저 설계하고 에셋을 끼운다

개별 스프라이트를 더 만들기 전에, 전투와 맵의 완성 화면 합성부터 고정한다.

```txt
1280x720 기준 전투 화면
1920x1080 기준 전투 화면
1280x720 기준 맵 화면
1920x1080 기준 맵 화면
```

각 화면은 Godot headless 캡처로 저장하고 직접 확인한다. 캡처가 실패하면 UI 작업을 진행하지 않는다.

### 원칙 2. 실제 게임 화면에서 개발용 UI를 제거한다

최종 루프에는 아래가 없어야 한다.

```txt
Debug 버튼
Asset Gallery 버튼
Deck Debug 버튼
Combat Test 버튼
Seed 원문
raw id
긴 전투 로그 패널
Locked 같은 개발 상태 텍스트가 노드 내부에 들어간 UI
```

디버그 화면은 `scenes/debug`로 유지할 수 있지만, 플레이 화면에서 연결하지 않는다.

### 원칙 3. 전투 UI는 Slay식 정보 위계를 따른다

전투 화면 우선순위:

```txt
1. 하단 손패
2. 에너지와 End Turn
3. 적 intent와 HP
4. 플레이어 HP/Block
5. 동료/서약/유대 상태
6. 짧은 현장 피드백
7. 로그는 숨김 또는 상세 버튼
```

전투 화면 컴포넌트 목표:

```txt
CombatScreen
├─ BattleBackdrop
├─ RunHud
├─ BattlefieldView
│  ├─ PlayerView
│  ├─ CompanionStrip
│  └─ EnemyView[]
├─ HandView
│  └─ CombatCardView[]
├─ EnergyOrb
├─ EndTurnButton
├─ TargetSelector
└─ CombatFeedbackLayer
```

### 원칙 4. 카드 사용은 상태머신으로 다룬다

카드 상태:

```txt
IDLE: 손패에 있음
HOVER: 커서가 올라가 확대/상승
SELECTED: 클릭으로 선택됨
DRAGGING: 드래그 중, arc 표시
TARGETING: 유효 대상 위에 있음
DISABLED: 에너지 부족/전투 종료
PLAYED: 사용 연출 후 제거
```

각 상태는 시각 규칙을 가져야 한다.

```txt
HOVER: 카드 상승 + z-index 상승 + tooltip 준비
DRAGGING: 원본 자리 반투명, 프리뷰 카드가 커서 추적
TARGETING: 적 테두리/바닥 원 밝아짐
DISABLED: 채도 낮춤, 비용 빨강/회색
```

### 원칙 5. 타겟팅은 카드가 아니라 TargetSelector가 담당한다

카드가 적 판정, arc, 선택 가능 표시를 모두 처리하면 유지보수가 무너진다.

```txt
CardView: 드래그 시작/종료 signal만 보냄
TargetSelector: arc, 마우스 위치, 적 hover, 유효 target 결정
CombatScreen: CardPlayRequest를 만들고 TurnManager에 전달
```

### 원칙 6. 카드 플레이 검증은 UI에서 분리한다

단기:

```txt
CardPlayRules.can_play_card(card, combat_state)
CardPlayRules.requires_enemy_target(card)
CardPlayRules.validate_target(card, target)
CardPlayRules.failure_message(card, target)
```

중기:

```txt
CardPlayRequest
ActionResult
CardActionPreview
Validator
```

이렇게 해야 카드가 복잡해져도 UI가 망가지지 않는다.

### 원칙 7. 맵은 Node2D 경로 UI로 재구성한다

지금처럼 Control 버튼으로도 가능하지만, Slay식 지도는 아이콘, 선, 애니메이션이 핵심이라 `MapCanvas`는 Node2D 방식이 더 자연스럽다.

목표 구조:

```txt
MapScreen
├─ RunHud
├─ RouteMapView
│  ├─ MapLineView[]
│  └─ MapNodeView[]
├─ MapLegend
├─ RouteTooltip
└─ PartySummary
```

맵 요구:

- 노드 내부 텍스트 없음.
- 선택 가능 노드만 밝게 pulse.
- 완료 경로는 따뜻한 선.
- 잠긴 경로는 흐린 선.
- hover 시 하단 tooltip만 바뀜.

### 원칙 8. 보상/상점/여관/이벤트는 같은 Modal 언어로 묶는다

각 화면을 새 페이지처럼 만들지 말고, 세계 배경 위에 뜨는 선택 모달 체계로 통일한다.

```txt
RewardModal
CardChoiceModal
ShopModal
InnModal
EventModal
CardDetailModal
```

공통 요구:

- 중앙 선택지가 가장 밝다.
- 배경은 장소감을 주되 낮은 대비.
- 선택 불가 조건은 버튼 비활성 + 짧은 이유.
- 텍스트는 선택 결과 중심.

### 원칙 9. StyleBox/Theme를 먼저 만든다

반복해서 쓸 스타일:

```txt
panel_dark
panel_paper
panel_token
button_primary
button_danger
button_disabled
card_attack
card_skill
card_power
enemy_intent_attack
enemy_intent_block
tooltip
modal_backdrop
```

`UIStyleScript`는 유지하되, 장기적으로 `.tres` Theme/StyleBox 자산으로 옮긴다.

### 원칙 10. 캡처 QA를 작업 조건으로 둔다

각 UI 변경 후 아래 캡처가 자동 생성되어야 한다.

```txt
/tmp/deckbuilder_combat_1280.png
/tmp/deckbuilder_combat_1920.png
/tmp/deckbuilder_map_1280.png
/tmp/deckbuilder_map_after_first_1280.png
/tmp/deckbuilder_reward_1280.png
```

검수 기준:

- 카드 6장이 모두 화면 안에 있다.
- 카드 이름/비용/본문이 잘리지 않는다.
- 적 intent가 적 위에 보인다.
- End Turn이 우측에서 명확하다.
- 로그 패널이 화면 주인공이 아니다.
- 맵 노드 내부에 긴 텍스트가 없다.
- 개발용 버튼이 없다.
- 배경과 UI가 겹쳐 읽기 어려운 곳이 없다.

## 단계별 작업 계획

### Phase UI-0. 레퍼런스 고정과 캡처 도구 복구

목표:

- headless 캡처가 안정적으로 돌아가게 한다.
- 전투/맵/보상 기준 스크린샷을 계속 저장한다.
- 현재 UI 문제를 스크린샷 단위로 추적한다.

산출물:

- `SourceCode/tools/visual_capture.gd` 안정화
- `docs/ui_rebuild_strategy.md`
- 현재 전투/맵 baseline 캡처

### Phase UI-1. 공통 UI 기반

목표:

- 공통 Theme/StyleBox helper를 정리한다.
- HUD, tooltip, modal, icon label, stat bar 같은 작은 컴포넌트를 만든다.

작업 파일 후보:

- `SourceCode/scripts/ui/ui_style.gd`
- `SourceCode/scripts/ui/common/`
- `SourceCode/scenes/ui/common/`

### Phase UI-2. 전투 화면 재구성

목표:

- `combat_screen.gd`를 거대한 절차형 스크립트에서 컴포넌트 조립자로 축소한다.
- 손패, 적, 플레이어, 동료, target selector를 분리한다.

최소 완료 조건:

- 클릭으로 카드 선택 후 적 클릭 사용.
- 드래그로 카드에서 적에게 arc 연결 후 사용.
- 에너지 부족/대상 없음 피드백.
- 전투 로그는 접거나 작은 최근 행동 표시만 남김.

### Phase UI-3. 맵 화면 재구성

목표:

- 텍스트 버튼형 맵을 완전히 제거한다.
- 작전서 위의 아이콘 경로 화면으로 만든다.

최소 완료 조건:

- 선택 가능 노드 pulse.
- 완료 경로/잠긴 경로 색 분리.
- hover 설명.
- 클릭과 드래그 선택 지원.

### Phase UI-4. 보상/카드 선택/상점/여관/이벤트 통합

목표:

- 모든 선택 화면을 같은 modal 언어로 통일한다.
- 카드 보상 3장 선택, skip, 장비/골드/유대 변화가 실제 보상 화면처럼 보인다.

### Phase UI-5. 무료 에셋 정리와 시각 통일

목표:

- Kenney 아이콘/카드/프레임을 우리 팔레트로 일괄 tint 또는 wrapper 처리한다.
- 현재 임시 에셋 중 너무 조잡한 것은 제거하거나 교체한다.

주의:

- Kenney CC0 에셋을 쓰더라도 그대로 조립하면 싸게 보인다.
- 금속패, 피 지문, 작전서, 모닥불빛, 청회색 세계 팔레트가 UI 전체를 묶어야 한다.

### Phase UI-6. 플레이 가능한 데모 검증

목표:

- 사용자가 Godot에서 플레이했을 때 디버그 화면을 보지 않고도 Act 1 루프를 진행한다.

완료 조건:

- Main Menu → Map → Combat → Reward → Map 루프가 실제 게임 화면만으로 돈다.
- Act 1 중간보스 후 동료 영입 화면이 보인다.
- Act 1 보스 후 두 번째 동료 영입 화면이 보인다.
- 전투에서 카드 클릭/드래그/대상 선택이 자연스럽다.
- 지도에서 다음 노드 선택이 명확하다.

## 당장 하지 않을 것

- `card-framework` 전체 import: 현재 상태 시스템과 충돌 위험이 있어 보류.
- Slay-The-Robot 전체 구조 이식: 너무 큰 프레임워크라 우선 패턴만 사용.
- 에셋 대량 생성: 레이아웃과 Theme가 안정되기 전에는 낭비가 크다.
- 새 게임 시스템 추가: UI가 게임처럼 보이기 전까지는 시스템 확장보다 판독성과 조작감이 우선이다.

## 바로 다음 실행 순서

1. `visual_capture.gd`를 먼저 안정화한다.
2. 전투/맵 baseline 캡처를 생성한다.
3. 캡처를 보고 `combat_screen.gd`를 컴포넌트 분리 대상으로 나눈다.
4. `HandView`와 `TargetSelector`부터 만든다.
5. 전투 화면이 통과되면 맵 화면으로 넘어간다.

# Project Skill Registry

작성일: 2026-05-26

목적: 이 프로젝트를 “바이브코딩으로 대충 만든 프로토타입”이 아니라, 게임 아트 전문가에게 보여줄 수 있는 실제 데모로 만들기 위해 사용할 Codex skill과 레퍼런스 레포를 고정한다.

## 등록한 신규 프로젝트 스킬

아래 스킬은 `~/.codex/skills/`에 등록했다. Codex가 새 스킬 메타데이터를 자동 인식하려면 Codex 재시작이 필요할 수 있다.

| Skill | 위치 | 사용할 때 |
|---|---|---|
| `godot-deckbuilder-ui-director` | `/Users/gimgibeom/.codex/skills/godot-deckbuilder-ui-director/SKILL.md` | 전투/맵/보상/상점/여관/이벤트 등 최종 Godot UI를 게임답게 설계/구현/리뷰할 때 |
| `godot-card-combat-ux` | `/Users/gimgibeom/.codex/skills/godot-card-combat-ux/SKILL.md` | 카드 손패, hover, drag, target arc, 적 클릭, 카드 상태머신, 전투 조작감을 만들 때 |
| `godot-visual-qa` | `/Users/gimgibeom/.codex/skills/godot-visual-qa/SKILL.md` | Godot 화면 캡처, 시각 검수, UI 겹침/잘림/빈 화면을 잡을 때 |
| `game-asset-curator` | `/Users/gimgibeom/.codex/skills/game-asset-curator/SKILL.md` | 무료/CC0/MIT 에셋 탐색, 라이선스 확인, 에셋 매니페스트 정리, 임시 아트 품질을 올릴 때 |
| `godot-roguelike-map-ui` | `/Users/gimgibeom/.codex/skills/godot-roguelike-map-ui/SKILL.md` | Slay식 루트맵, 노드 아이콘, 연결선, 선택 가능 상태, hover tooltip을 만들 때 |
| `indie-demo-readiness` | `/Users/gimgibeom/.codex/skills/indie-demo-readiness/SKILL.md` | 데모가 자랑스럽게 보여줄 수준인지 냉정하게 평가할 때 |
| `reference-repo-mining` | `/Users/gimgibeom/.codex/skills/reference-repo-mining/SKILL.md` | 외부 GitHub 레포를 조사하고, 라이선스/패턴/도입 여부를 판단할 때 |

최소 5개 요구보다 넓게 잡아 7개를 등록했다. 실제 작업에서는 한 번에 전부 켜는 느낌이 아니라, 단계별로 필요한 것만 사용한다.

## 이미 설치되어 있고 적극 활용할 기존 스킬

| Skill | 사용할 때 |
|---|---|
| `generate2dsprite` | 동료/적/VFX 임시 스프라이트를 생성하고 정리할 때 |
| `generate2dmap` | 전투 배경, 맵 배경, 장소 컬러키를 만들 때 |
| `imagegen` | bitmap mockup, 배경, 키 비주얼, 카드 모티프를 생성할 때 |
| `playwright` | 웹 기반 자료, 로컬 웹 미리보기, UI 레퍼런스 캡처 자동화가 필요할 때 |
| `ui` | 디자인 토큰, 색/타이포/컴포넌트 기준을 정리할 때 |
| `repo-refresh-run-verify` | 변경 후 실행/검증 루틴을 정리할 때 |
| `karpathy-guidelines` | 과설계와 큰 리팩터링을 피하고, 좁고 검증 가능한 변경을 할 때 |

## 레퍼런스 레포 조사 결과

| Repo | License 판단 | 쓰임 |
|---|---|---|
| [guladam/deck_builder_tutorial](https://github.com/guladam/deck_builder_tutorial) | MIT | BattleUI, Hand, CardUI, CardTargetSelector, MapRoom 구조 참고 |
| [DesirePathGames/Slay-The-Robot](https://github.com/DesirePathGames/Slay-The-Robot) | MIT | CardPlayRequest, Action, Validator, 카드/전투 규칙 분리 참고 |
| [chun92/card-framework](https://github.com/chun92/card-framework) | MIT | fan hand layout, card container, drop zone, Kenney 카드 에셋 사용 방식 참고 |
| [statico/godot-roguelike-example](https://github.com/statico/godot-roguelike-example) | 코드 MIT, 일부 에셋 별도 | HUD, ModalStack, inventory/equipment UI, StyleBox 자산 관리 참고 |
| [cyanglaz/gcard_layout](https://github.com/cyanglaz/gcard_layout) | MIT | Godot Control 카드 손패 곡선 배치, hover padding, drag signal 참고 |
| [insideout-andrew/deckbuilder-framework](https://github.com/insideout-andrew/deckbuilder-framework) | MIT | 단순 카드/덱 구조, 목표 위치로 부드럽게 복귀하는 카드 움직임 참고 |
| [db0/godot-card-game-framework](https://github.com/db0/godot-card-game-framework) | AGPL | 코드 복사 금지. target/test/card viewer 설계 아이디어 참고만 가능 |
| [ShayanMasoudzadeh/Slot-based-Inventory-System](https://github.com/ShayanMasoudzadeh/Slot-based-Inventory-System) | 라이선스 파일 없음 | 코드 복사 금지. 장비 슬롯/잡은 아이템 프리뷰 UX 참고만 가능 |

## 에셋 소스

| Source | License/상태 | 쓰임 |
|---|---|---|
| [Kenney Board Game Icons](https://kenney-assets.itch.io/board-game-icons) | CC0 | 노드, 상태, 카드 모티프, 장비, 전술 표식 아이콘 |
| [Kenney Board Game Icons on kenney.nl](https://kenney.nl/assets/board-game-icons) | CC0 | 위와 동일, 원출처 확인용 |
| [Kenney Playing Cards Pack on OpenGameArt](https://opengameart.org/content/playing-cards-pack) | CC0 | 카드 프레임/카드 뒷면/임시 카드 패키지 참고 |

## 작업 시 스킬 조합

### 전투 UI 재개발

```txt
godot-deckbuilder-ui-director
+ godot-card-combat-ux
+ godot-visual-qa
+ reference-repo-mining
```

절차:

1. reference-repo-mining으로 참고할 파일을 좁힌다.
2. godot-deckbuilder-ui-director로 화면 정보 위계를 정한다.
3. godot-card-combat-ux로 HandView/CardView/TargetSelector 구조를 잡는다.
4. godot-visual-qa로 캡처를 만들고 실제 이미지 검수 후 반복한다.

### 맵 UI 재개발

```txt
godot-roguelike-map-ui
+ godot-deckbuilder-ui-director
+ godot-visual-qa
```

절차:

1. 노드 텍스트를 제거하고 아이콘/선/tooltip 구조를 고정한다.
2. 선택 가능/완료/잠김 상태를 색과 pulse로 구분한다.
3. 캡처로 `다음 갈 곳`이 2초 안에 보이는지 확인한다.

### 에셋 업그레이드

```txt
game-asset-curator
+ generate2dsprite
+ generate2dmap
+ imagegen
+ godot-visual-qa
```

절차:

1. 먼저 무료/CC0/MIT 에셋을 찾는다.
2. 라이선스를 기록한다.
3. 부족한 부분만 생성형 임시 에셋으로 보완한다.
4. 팔레트/프레임/명명 규칙으로 하나의 게임처럼 묶는다.

### 데모 완성도 평가

```txt
indie-demo-readiness
+ godot-visual-qa
+ karpathy-guidelines
```

절차:

1. 실제 플레이 흐름을 첫 10분 기준으로 본다.
2. 자랑스럽게 보여줄 수 없는 화면을 blocker로 분류한다.
3. 가장 큰 세 가지 수정만 골라 다음 구현 범위로 만든다.

## 환경 원칙

- 구현 전에 레퍼런스와 스킬을 선택한다.
- AGPL/무라이선스 레포 코드는 복사하지 않는다.
- Godot 화면 작업 후 반드시 캡처 검수를 한다.
- 무료 에셋을 쓰더라도 출처와 라이선스를 남긴다.
- 최종 플레이 루프에는 개발용 버튼과 디버그 화면을 노출하지 않는다.
- “예쁘다”는 단품 에셋 기준이 아니라 실제 게임 화면 합성 기준으로 판단한다.


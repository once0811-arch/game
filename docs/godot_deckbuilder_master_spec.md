# MASTER SPEC - Godot 동료 덱빌딩 로그라이크

# FILE: README.md

# Godot 덱빌딩 로그라이크 기획/개발 문서 패키지

이 문서 묶음은 **Godot 4.x + GDScript + Codex 바이브코딩**으로 개발하기 위한 작업 기준서다.

현재 게임은 다음 한 문장으로 정의한다.

> **중세 판타지 세계에서 균형형 주인공이 동료를 영입하고 강화하며 3막을 돌파하는, 동료 시스템 중심의 싱글플레이 2D 로그라이크 덱빌딩 게임.**

기획상의 핵심 약속은 다음과 같다.

> **플레이어는 균형형 주인공의 덱을 다듬으며, 길 위에서 만난 동료와 장비를 조합해 매 런 다른 전술 부대를 완성한다.**

## 사용 방법

Codex에게 작업을 시킬 때는 먼저 이 폴더 전체를 프로젝트 루트 또는 `docs/design/`에 넣는다.

권장 위치:

```txt
res://docs/design/
  README.md
  00_codex_rules.md
  01_gdd_overview.md
  02_systems_spec.md
  03_godot_architecture.md
  04_data_schemas.md
  05_companion_roster.md
  06_cards_equipment_balance.md
  07_events_inn_shop_treasure.md
  08_mvp_roadmap_and_codex_prompts.md
  09_design_upgrade_research_and_balance.md
```

Codex에게 첫 작업을 지시할 때는 다음처럼 말한다.

```txt
이 프로젝트는 Godot 4.x + GDScript 기반 2D 로그라이크 덱빌딩 게임이다.
res://docs/design/ 폴더의 Markdown 문서들을 먼저 읽어라.
특히 00_codex_rules.md, 02_systems_spec.md, 03_godot_architecture.md, 09_design_upgrade_research_and_balance.md를 기준으로 구현해라.
한 번에 전체 게임을 만들지 말고, 08_mvp_roadmap_and_codex_prompts.md의 Milestone 순서대로 실행 가능한 상태를 유지하며 진행해라.
```

## 문서 구성

| 파일 | 용도 |
|---|---|
| `00_codex_rules.md` | Codex 작업 규칙, 금지 시스템, 구현 원칙 |
| `01_gdd_overview.md` | 게임 전체 기획서 요약 |
| `02_systems_spec.md` | 런, 전투, 동료, 보상, 장비 등 시스템 명세 |
| `03_godot_architecture.md` | Godot 프로젝트 구조, 씬/스크립트/오토로드 설계 |
| `04_data_schemas.md` | 카드, 동료, 장비, 이벤트, 저장 데이터 스키마 |
| `05_companion_roster.md` | 동료 10명 초안, 패시브, 기본 공격력, 전용 카드 방향 |
| `06_cards_equipment_balance.md` | 주인공 카드 40장 초안, 시작 덱, 장비, 주인공 강화 |
| `07_events_inn_shop_treasure.md` | 이벤트, 여관, 상점, 보물/특수보상 명세 |
| `08_mvp_roadmap_and_codex_prompts.md` | MVP 개발 순서와 Codex 프롬프트 템플릿 |
| `09_design_upgrade_research_and_balance.md` | 외부 레퍼런스 분석, 재미 축, 런/전투/경제 수치 기준 |

## 확정된 큰 방향

- 플랫폼: PC + 모바일, 둘 다 가로 화면.
- 과금: 인앱결제 없음. 게임 구매형.
- 엔진: Godot 4.x.
- 언어: GDScript 우선.
- 장르: 싱글플레이 2D 로그라이크 덱빌딩.
- 세계관: 중세 판타지. 세부 설정은 추후 확정.
- 주인공: 균형형.
- 고유 시스템: 동료 영입/강화 시스템.
- 기본 전투: 에너지 4, 매턴 드로우 6, 파워 카드 유지.
- 런 구조: 3막, Act당 12노드 + 보스 1종.
- 주인공 카드: 총 40장. 공격 16, 스킬 16, 파워 8.
- 동료: 총 10명, 런 중 최대 2명.
- 유물/포션/저주/상태카드/카드 생성 없음.
- 기획 기준: 동료는 빌드 문이자 캐릭터이며, 장비는 제한된 슬롯 퍼즐이다.
- 밸런스 기준: 일반 전투 3~5턴, 엘리트 5~7턴, 보스 8~11턴을 1차 목표로 한다.

## 금지된 원작식 시스템

아래는 개발 중 Codex가 임의로 다시 추가하면 안 된다.

```txt
유물
포션
저주 카드
상태 카드
전투 중 카드 생성
4막 / 진엔딩 키
승천 난이도
일일 도전
커스텀 모드
무한 모드
점수 시스템
통계 화면
리더보드
모드 지원
시드 입력/공유 UI
```

내부 랜덤 재현을 위한 시드는 사용할 수 있지만, 유저가 직접 시드를 입력하거나 공유하는 기능은 만들지 않는다.

# FILE: 00_codex_rules.md

# 00. Codex 개발 규칙

이 문서는 Codex가 반드시 따라야 하는 개발 규칙이다.

## 1. 개발 방식

이 프로젝트는 **Godot 4.x + GDScript** 기반이다.

핵심 목표는 자연어 지시만으로 장기간 유지보수 가능한 구조를 만드는 것이다. 따라서 Codex는 다음 원칙을 지켜야 한다.

```txt
1. 한 번에 큰 기능을 만들지 않는다.
2. 매 단계마다 실행 가능한 상태를 유지한다.
3. UI와 게임 규칙을 분리한다.
4. 카드/동료/장비/이벤트 데이터는 가능한 한 데이터 파일로 관리한다.
5. 전투 규칙은 씬이 아니라 순수 로직 클래스에서 처리한다.
6. Godot 씬은 입력, 표시, 애니메이션, 연결만 담당한다.
7. 버그 수정 시 관련 없는 파일을 넓게 건드리지 않는다.
8. 새 시스템을 추가하기 전에 현재 시스템과 데이터 구조를 먼저 점검한다.
9. 밸런스 수치를 바꿀 때는 09_design_upgrade_research_and_balance.md의 기준을 먼저 확인한다.
```

## 2. 강제 금지 시스템

아래 시스템은 기획상 삭제되었다. 사용자가 다시 요청하기 전까지 구현하지 않는다.

```txt
유물 시스템
포션 시스템
저주 카드
상태 카드
전투 중 카드 생성
선택적 4막 / 진엔딩
특수 키
승천 난이도
일일 도전
커스텀 모드
무한 모드
점수 시스템
런 기록 화면
통계 화면
리더보드
모드 지원
시드 입력/공유 기능
```

주의:

```txt
내부 랜덤 시드 저장은 허용된다.
유저가 시드를 입력하거나 공유하는 UI는 금지된다.
```

## 3. 코드 구조 원칙

### 3.1 UI와 로직 분리

나쁜 구조:

```txt
CardView.gd 안에서 데미지 계산, 에너지 차감, 버프 적용, 카드 이동을 모두 처리.
```

좋은 구조:

```txt
CardView.gd = 표시와 클릭/드래그 입력만 담당.
CardEffectResolver.gd = 카드 효과 처리.
CombatState.gd = 전투 상태 보관.
TurnManager.gd = 턴 흐름 처리.
```

### 3.2 데이터 기반 설계

카드, 동료, 장비, 이벤트, 적, 보스는 하드코딩하지 않는다.

권장 구조:

```txt
res://data/cards/protagonist_cards.json
res://data/cards/companion_cards.json
res://data/companions/companions.json
res://data/equipment/equipment.json
res://data/events/events.json
res://data/enemies/enemies.json
```

초기에는 JSON으로 관리한다. 이후 필요하면 Godot Resource로 전환할 수 있다.

### 3.3 상태 객체 우선

전투 상태는 씬 트리에 흩어지면 안 된다.

권장 상태 객체:

```txt
RunState
CombatState
DeckState
MapState
PartyState
InventoryState
RewardState
```

### 3.4 자동 저장 기준

런 진행 저장은 노드 이동 단위로 한다.

```txt
노드 진입 전 저장
노드 클리어 후 저장
보상 선택 후 저장
다음 노드 선택 시 저장
```

## 4. 네이밍 규칙

파일명은 snake_case를 사용한다.

```txt
combat_state.gd
card_effect_resolver.gd
companion_manager.gd
equipment_inventory.gd
inn_room_generator.gd
```

클래스명은 PascalCase를 사용한다.

```txt
CombatState
CardEffectResolver
CompanionManager
EquipmentInventory
InnRoomGenerator
```

ID는 snake_case 문자열로 관리한다.

```txt
strike
steady_guard
companion_rowan
rowan_piercing_lunge
iron_helmet_common
```

## 5. 구현 우선순위

항상 아래 순서로 개발한다.

```txt
1. 순수 전투 로직
2. 카드 데이터와 덱 흐름
3. 최소 전투 UI
4. 보상 UI와 카드 보상 스킵
5. 맵 흐름과 Act 1 동료 예고
6. 동료 영입
7. 동료 전투 행동과 전술 표식 표시
8. 장비/상점/여관/이벤트
9. 세이브/로드
10. 플레이테스트 지표 기록
11. 연출과 아트 적용
```

## 6. Codex 작업 시 응답 기준

Codex는 작업할 때 다음을 명시해야 한다.

```txt
- 어떤 파일을 만들거나 수정했는가
- 어떤 시스템을 구현했는가
- 테스트 방법은 무엇인가
- 아직 미구현인 것은 무엇인가
- Godot 에디터에서 수동 연결이 필요한 것이 있는가
```

## 7. 테스트 기준

최소한 아래 시나리오는 항상 작동해야 한다.

```txt
새 런 시작
전투 진입
카드 사용
에너지 감소
카드 드로우/버림/셔플
전술 표식 갱신
적 처치
전투 보상 선택
카드 보상 스킵
다음 맵 노드 이동
Act 1 동료 예고 이벤트
Act 1 보스 처치 후 동료 선택
동료 전투 참여
저장 후 이어하기
```

## 8. 불확실한 부분 처리

문서에 명시되지 않은 부분은 임의로 복잡하게 만들지 않는다.

기본 처리:

```txt
1. 가장 단순한 구현을 선택한다.
2. 값은 임시 밸런스 테이블에 둔다.
3. TODO 주석으로 남긴다.
4. 시스템 확장 여지를 막지 않는다.
```

수치가 불확실할 때:

```txt
1. 09_design_upgrade_research_and_balance.md의 예산 범위 안에서 임시값을 둔다.
2. 카드/적/이벤트 수치는 JSON 또는 balance_constants.json에 둔다.
3. 특정 카드나 동료가 완전 상위호환이 되지 않게 한다.
4. 전투 턴 수와 체력 손실을 기준으로 다시 조정한다.
```

## 9. 절대 피해야 할 구조

```txt
- 하나의 GameManager가 모든 것을 처리하는 구조
- UI 노드가 전투 규칙을 직접 계산하는 구조
- 카드 효과를 각 카드 씬에 하드코딩하는 구조
- 동료별 로직을 if companion_id == ... 로 무한 분기하는 구조
- 장비 효과를 전역 변수로 흩뿌리는 구조
- 저장 데이터에 씬 노드 참조를 넣는 구조
```

## 10. 개발 중 변경 불가 핵심

아래는 기획 핵심이므로 사용자가 명시적으로 바꾸기 전까지 변경하지 않는다.

```txt
기본 에너지 4
매턴 드로우 6
3막 구조
Act당 12노드
Act 1/2 보스 후 동료 선택
동료 최대 2명
동료 총 10명
동료별 카드 8장
동료 영입 시 카드 3장 표시, 2장 선택
동료 카드 중복 획득 불가
장비는 캐릭터별 투구/갑옷/무기 슬롯
여관은 일반/이벤트 모두 방 3개
동료는 빌드 방향을 바꾸는 핵심 시스템
장비는 유물 대체물이 아니라 제한된 슬롯 퍼즐
```

# FILE: 01_gdd_overview.md

# 01. 게임 디자인 개요

## 1. 한 줄 설명

중세 판타지 세계에서 균형형 주인공이 동료를 영입하고 강화하며 3막을 돌파하는, **동료 시스템 중심의 싱글플레이 2D 로그라이크 덱빌딩 게임**.

## 2. 플랫폼과 과금

```txt
플랫폼: PC + 모바일
화면 방향: 둘 다 가로 화면
과금: 게임 구매형
인앱결제: 없음
광고: 없음
멀티플레이: 없음
```

## 3. 엔진과 개발 방식

```txt
엔진: Godot 4.x
언어: GDScript
개발 방식: Codex 기반 자연어 바이브코딩
아트워크: 전문가 제작 예정
```

## 4. 세계관

```txt
장르: 중세 판타지
세부 세계관: 서약의 길을 따라 무너진 변경 왕국을 돌파하는 로드 판타지
주인공 설정: 몰락한 왕국의 전술 장교 또는 호위대장
```

현재 세계관은 시스템을 지지하기 위한 1차 기준이다. 고유명사는 추후 바꿀 수 있지만, 아래 정서는 유지한다.

```txt
길 위의 동료
위험한 여관과 낡은 상점
버려진 장비와 전장의 흔적
왕국을 구하는 영웅담보다, 끝까지 함께 살아남는 전술 부대의 이야기
```

### 4.1 Act별 분위기

```txt
Act 1: 무너진 변경길
- 산적, 탈영병, 굶주린 짐승, 버려진 초소.
- 플레이어는 아직 혼자지만, 동료 후보들의 흔적을 발견한다.

Act 2: 오염이 번진 접경지
- 마녀 숲, 폐광, 타락한 기사단, 수상한 상단.
- 첫 동료와의 시너지가 본격화되고, 두 번째 동료 또는 기존 동료 강화 선택이 런의 방향을 가른다.

Act 3: 왕성으로 가는 검은 관문
- 왕국 몰락의 원인, 최종 군세, 동료들의 서약이 수렴한다.
- 두 동료와 장비 조합을 완성해 보스 패턴을 돌파한다.
```

## 5. 주인공

```txt
주인공 타입: 균형형
전투 정체성: 공격, 방어, 유틸을 모두 다루는 기본형
고유 카드 수: 40장
```

주인공은 동료 시스템의 중심축이다. 주인공 자체가 너무 특이하면 동료 시스템이 흐려지므로, 기본 캐릭터는 균형형으로 둔다.

## 6. 핵심 차별점

일반적인 덱빌딩 로그라이크는 다음 축을 가진다.

```txt
카드 + 유물 + 포션 + 이벤트
```

본 게임은 다음 축을 가진다.

```txt
카드 + 동료 + 장비 + 이벤트 + 여관
```

가장 중요한 차별점은 **유물과 포션을 제거하고, 그 자리를 동료와 장비, 이벤트형 보상으로 대체한다**는 점이다.

따라서 재미의 중심은 "강한 유물을 먹어서 이겼다"가 아니라 아래 감각이어야 한다.

```txt
로완을 골랐기 때문에 표적 고정 덱이 됐다.
세라를 골랐기 때문에 0비용/연타 덱이 됐다.
엘드릭을 골랐기 때문에 방어도 기반 반격 덱이 됐다.
두 번째 동료를 누구로 받을지에 따라 장비, 카드 보상, 상점 구매가 달라졌다.
```

## 7. 디자인 기둥

### 7.1 동료가 런의 방향을 바꾼다

동료는 단순 보너스가 아니다.

동료를 영입하면 다음이 동시에 바뀐다.

```txt
- 전투 중 매 턴 동료 기본 공격 추가
- 동료 고유 패시브 적용
- 동료 전용 카드풀 해금
- 동료 장비 슬롯 3개 추가
- 동료 관련 이벤트 가능성 증가
```

동료는 반드시 두 층의 의미를 동시에 가진다.

```txt
전술적 의미: 카드 보상과 전투 행동을 바꾸는 빌드 축.
정서적 의미: 이벤트와 여정에서 기억되는 캐릭터.
```

동료가 전투에서 방치되는 느낌을 줄이기 위해, 단일 대상 공격이나 지휘 카드는 그 턴의 **전술 표식** 대상을 만든다. 동료는 턴 종료 후 전술 표식 대상을 우선 공격한다.

### 7.2 이벤트가 런의 변수를 만든다

유물과 포션이 없으므로, 런의 변동성은 이벤트가 크게 담당한다.

```txt
일반 이벤트
이벤트 여관
보물/특수보상 방
일반 전투 후 10% 특수보상
상점 이벤트성 거래
```

### 7.3 골드는 생존 자원이다

골드는 단순 구매 재화가 아니다.

```txt
상점에서 카드/장비/강화 구매
여관에서 회복
이벤트 선택지 비용
카드 제거/복제/변화 비용
```

골드를 어떻게 쓰느냐가 생존과 덱 완성도를 동시에 결정한다.

### 7.4 장비는 동료 영입의 가치를 높인다

장비 슬롯은 주인공과 동료에게 나뉜다.

```txt
주인공 기본 장비 슬롯: 3개
동료 1명당 추가 장비 슬롯: 3개
최대 동료 2명
최대 장비 슬롯: 9개
```

따라서 Act 2에서 새 동료를 영입할지, 기존 동료를 강화할지의 선택은 다음 의미를 갖는다.

```txt
새 동료 영입 = 전투 인원 증가 + 카드풀 증가 + 패시브 증가 + 장비 슬롯 증가
기존 동료 강화 = 슬롯은 늘지 않지만 기존 시너지 강화
```

장비는 유물처럼 무제한 누적되는 보너스가 아니다. 장비는 아래 질문을 만들기 위한 제한된 슬롯 퍼즐이다.

```txt
이 장비를 주인공에게 줄 것인가, 동료에게 줄 것인가?
팀 전체 효과가 좋은가, 특정 동료 전용 효과가 좋은가?
두 번째 동료를 받으면 장비 슬롯 3개가 늘어나는데, 지금 장비 인벤토리가 그 가치를 살릴 수 있는가?
```

### 7.5 골드가 선택을 날카롭게 만든다

골드는 항상 세 방향으로 압박해야 한다.

```txt
체력 보존: 여관
덱 품질: 카드 제거/강화/복제/변화
런 정체성: 동료 카드/장비/이벤트 거래
```

상점과 여관은 쉬어가는 화면이 아니라, 다음 3~4노드의 위험을 계산하는 전략 화면이다.

### 7.6 Act 1에서도 동료의 맛을 보여준다

정식 영입은 Act 1 보스 후에 진행하지만, 게임의 차별점이 너무 늦게 드러나면 안 된다.

따라서 Act 1 중반에는 동료 후보를 예고하는 이벤트를 1회 이상 제공한다.

```txt
동료 후보의 흔적, 전투 스타일, 장비 궁합을 보여준다.
정식 영입, 동료 카드 추가, 동료 슬롯 점유는 하지 않는다.
다음 전투 1회성 보정 정도만 제공한다.
Act 1 보스 후 후보 3택에는 예고로 본 동료가 최소 1명 포함된다.
```

## 8. 삭제된 시스템

아래 시스템은 본 게임에 없다.

```txt
유물
포션
저주 카드
상태 카드
전투 중 카드 생성
선택적 4막
진엔딩 키
승천 난이도
일일 도전
커스텀 모드
무한 모드
점수 시스템
통계 화면
리더보드
모드 지원
시드 입력/공유
```

## 9. 기본 게임 루프

```txt
런 시작
→ 맵 노드 선택
→ 전투 / 이벤트 / 상점 / 여관 / 보물 / 엘리트 진행
→ 보상 선택
→ 다음 노드 선택
→ Act 보스전
→ Act 1/2 보스 후 동료 영입 또는 기존 동료 강화
→ Act 3 보스 처치 시 엔딩
```

## 10. 전투 루프

```txt
전투 시작
→ 플레이어 턴 시작
→ 카드 6장 드로우
→ 에너지 4 획득
→ 카드 사용 및 전술 표식 지정
→ 턴 종료
→ 동료들이 전술 표식 또는 최저 체력 적을 순서대로 기본 공격
→ 적 턴
→ 다음 턴 반복
```

## 11. 승리/패배 조건

```txt
전투 승리: 모든 적 처치
런 클리어: Act 3 보스 처치
전투 패배: 주인공 체력 0
런 패배: 주인공 체력 0
```

동료는 별도 체력이 없다. 주인공과 체력을 공유한다.

## 12. MVP 목표

MVP는 아래를 목표로 한다.

```txt
1명의 주인공
동료 3명 임시 구현
Act 1만 구현
기본 전투
카드 보상
동료 영입
여관/상점/이벤트 최소 구현
세이브/로드 최소 구현
```

정식 1차 목표는 다음이다.

```txt
3막 전체
동료 10명
주인공 카드 40장
동료 카드 80장
장비 시스템
이벤트/여관/상점/보물 시스템
보스 3종
```

## 13. 재미 검증 목표

첫 내부 플레이테스트 전 기준 목표는 다음이다.

```txt
일반 전투는 3~5턴 안에 끝난다.
엘리트 전투는 위험하지만 보상이 탐난다.
Act 1 보스 처치 후 동료 3택은 "누가 제일 강한가"가 아니라 "이번 덱에 누가 맞는가"로 고민하게 한다.
동료 기본 공격은 전체 피해의 15~35% 사이에서 존재감이 있다.
카드 보상 스킵은 덱 품질을 위한 정상 선택지다.
이벤트는 손해 뽑기가 아니라 위험한 기회로 느껴진다.
```

# FILE: 02_systems_spec.md

# 02. 시스템 명세

## 1. 런 구조

```txt
총 막 수: 3막
Act당 선택 노드 수: 12개
Act당 보스 수: 1종
Act 1 보스 후: 동료 영입
Act 2 보스 후: 동료 영입 또는 기존 동료 강화
Act 3 보스 후: 엔딩
```

보스 노드는 12개 일반 선택 노드 뒤에 고정 배치한다.

```txt
Act 1: 12노드 → Act 1 보스 → 동료 선택
Act 2: 12노드 → Act 2 보스 → 동료 선택/강화
Act 3: 12노드 → Act 3 보스 → 엔딩
```

## 2. 맵 노드 비중

보스 노드를 제외한 일반 맵 노드는 아래 비중으로 생성한다.

```txt
일반 전투: 40%
이벤트: 20%
상점: 10%
여관: 10%
보물/특수보상: 5%
엘리트: 15%
```

맵은 분기형 구조다. 플레이어는 다음 노드를 선택한다.

단순 비중만으로는 좋은 경로가 보장되지 않으므로, 각 Act는 아래 체감 구조를 우선한다.

```txt
일반 전투: 4~6개
이벤트: 2~3개
상점: 1개
여관: 1개
보물/특수보상: 0~1개
엘리트: 1~2개
```

맵 생성 제약:

```txt
depth 1은 일반 전투 권장.
depth 1~3에는 상점/여관/보물만 연속으로 나오지 않게 한다.
depth 4~9 사이에는 첫 엘리트 선택지를 배치한다.
보스 전 마지막 2 depth 안에는 최소 1개의 회복/상점/이벤트 안정화 경로를 둔다.
모든 주요 경로에는 최소 1회 이상의 덱 개선 기회가 있어야 한다.
```

Act 1은 동료가 정식 합류하기 전이므로, depth 3~8 사이에 **동료의 흔적** 계열 이벤트 1회 노출을 권장한다.

## 3. 전투 기본값

```txt
기본 에너지: 4
매턴 드로우: 6장
시작 손패: 6장
턴 종료 시 손패: 전부 버림
방어도: 턴 종료 시 제거
카드 타입: 공격 / 스킬 / 파워
파워 카드: 유지
```

## 4. 카드 더미

전투 중 카드는 아래 더미를 가진다.

```txt
draw_pile
hand
discard_pile
exhaust_pile
```

상태 카드, 저주 카드, 전투 중 카드 생성은 없다.

주의:

```txt
상태 카드 금지와 상태 효과 금지는 다르다.
취약, 약화, 독, 일시 피해 감소 같은 상태 효과는 사용할 수 있다.
단, 상태 효과는 전투 상태값이며 덱에 카드를 추가하지 않는다.
```

카드 이동 규칙:

```txt
카드 사용 → discard_pile 또는 exhaust_pile
턴 종료 손패 → discard_pile
뽑을 카드 부족 → discard_pile을 섞어 draw_pile로 이동
소멸 카드 → exhaust_pile
```

## 5. 카드 타입

### 5.1 공격 카드

피해를 주는 카드.

### 5.2 스킬 카드

방어, 드로우, 회복, 디버프, 카드 조작, 에너지 조작 등을 담당한다.

### 5.3 파워 카드

한 전투 동안 지속되는 효과를 부여한다. 사용 후 해당 전투에서는 다시 사용되지 않는다.

## 6. 주인공 카드풀

```txt
총 40장
공격 카드: 16장
스킬 카드: 16장
파워 카드: 8장
```

주인공 카드는 중복 획득 가능하다.

## 7. 시작 상태

초기값은 Slay the Spire류 구조를 참고하되 현재 게임의 4에너지/6드로우 구조에 맞춰 조정한다.

```txt
시작 최대 체력: 76
시작 현재 체력: 76
시작 골드: 99
기본 에너지: 4
매턴 드로우: 6
```

시작 덱:

```txt
5x 기본 공격
4x 기본 방어
1x 전술 정비
```

초기 카드:

```txt
기본 공격
- 비용 1
- 피해 6
- 강화: 피해 9

기본 방어
- 비용 1
- 방어도 5
- 강화: 방어도 8

전술 정비
- 비용 0
- 카드 1장 드로우 후 카드 1장 버림
- 강화: 카드 2장 드로우 후 카드 1장 버림
```

## 8. 동료 시스템 개요

동료 시스템은 이 게임의 핵심 고유 시스템이다.

```txt
동료 총수: 10명
런 중 최대 동료 수: 2명
동료 클래스: 공격형 3명 / 방어형 3명 / 디버프·유틸·힐러형 3명 / 보상형 1명
동료별 전용 카드: 8장
동료별 패시브: 1개
동료별 기본 공격력: 고정
```

동료는 별도 체력이 없다. 주인공과 체력을 공유한다.

동료는 디자인상 다음 세 역할을 동시에 가진다.

```txt
전투 역할: 매 턴 기본 공격과 패시브로 전투 흐름에 개입.
덱 역할: 전용 카드풀을 열어 보상 후보를 바꿈.
런 역할: 장비 슬롯, 이벤트, 강화 선택지를 바꿈.
```

기존 구현 필드 `passive_level`은 디자인상 **유대 단계**로 취급한다.

```txt
유대 0: 영입 직후 기본 패시브.
유대 1: 보스 후 기존 동료 강화, 엘리트 강화, 개인 이벤트 등으로 도달.
유대 2: 해당 동료 빌드를 강하게 밀었다는 보상.
```

MVP에서는 유대 단계가 패시브 수치만 바꿔도 된다. 정식 1차에서는 개인 이벤트, 장비 힌트, 동료 카드 강화 가중치와 연결한다.

## 8.1 Act 1 동료 예고

Act 1 보스 후 동료를 영입하는 구조는 유지한다. 다만 게임의 차별점을 초반에 보여주기 위해 Act 1 중반에 동료 후보를 예고한다.

```txt
Act 1 depth 3~8 사이에 동료 예고 이벤트 1회 권장.
이 이벤트는 동료를 영입하지 않는다.
동료 카드를 덱에 추가하지 않는다.
동료 슬롯을 차지하지 않는다.
후보의 성격, 전투 스타일, 장비 궁합을 보여준다.
다음 전투 1회성 보정은 허용한다.
Act 1 보스 후 3택에는 예고로 본 후보가 최소 1명 포함된다.
```

## 9. 보스 후 동료 선택

보스 처치 후에는 주인공 강화 선택지가 나오지 않는다.

보스 보상은 다음 둘 중 하나다.

```txt
신규 동료 영입
기존 동료 강화
```

### Act 1 보스 후

Act 1 보스 후에는 3개의 신규 동료 후보가 나온다.

```txt
[신규 동료 A] [신규 동료 B] [신규 동료 C]
```

플레이어는 반드시 1명을 선택한다.

### Act 2 보스 후

Act 2 보스 후에는 기존 동료가 1/4 확률로 다시 등장할 수 있다.

```txt
기존 동료 재등장 확률: 25%
```

기존 동료가 재등장하면 3택 중 하나가 기존 동료 강화가 된다.

```txt
25%:
[기존 동료 강화] [신규 동료 B] [신규 동료 C]

75%:
[신규 동료 B] [신규 동료 C] [신규 동료 D]
```

기존 동료를 선택해도 중복 영입은 되지 않는다. 해당 동료가 강화된다.

기존 동료 강화 선택 시:

```txt
해당 동료의 유대 단계 +1
패시브 수치 갱신
동료 카드 강화 후보 1회 제공 여부는 엘리트/이벤트 보상과 겹치지 않도록 후순위
```

## 10. 동료 영입 시 카드 선택

각 동료는 전용 카드 8장을 가진다.

동료 영입 시:

```txt
1. 해당 동료의 카드 8장 중 3장을 표시한다.
2. 플레이어는 3장 중 2장을 선택한다.
3. 선택한 2장은 즉시 덱에 추가된다.
4. 선택하지 않은 1장과 미공개 5장은 이후 카드 보상 후보가 된다.
```

동료 카드는 중복 획득할 수 없다.

```txt
주인공 카드: 중복 가능
동료 카드: 중복 불가
```

## 11. 카드 보상 생성 규칙

### 동료가 없을 때

```txt
카드 보상 3장 = 주인공 카드풀 3장
```

### 동료가 있을 때

```txt
카드 보상 3장 = 주인공 카드 2장 + 보유 동료 카드 1장
```

동료가 2명일 경우:

```txt
1. 보유 동료 중 하나를 무작위 선택한다.
2. 해당 동료의 아직 획득하지 않은 카드 중 1장을 뽑는다.
3. 후보가 없으면 주인공 카드로 대체한다.
```

보유 동료 카드 후보가 없어서 주인공 카드로 대체될 때는 rare 확률을 약간 올려 보상 체감이 죽지 않게 한다.

```txt
대체 주인공 카드 rare 확률 보정: +5%
```

### 카드 희귀도 가중치

첫 구현은 고정 확률로 시작한다.

```txt
Act 1 카드 보상: common 62%, uncommon 35%, rare 3%
Act 2 카드 보상: common 55%, uncommon 37%, rare 8%
Act 3 카드 보상: common 48%, uncommon 40%, rare 12%
상점 카드: common 50%, uncommon 38%, rare 12%
```

정식 1차에서는 rare 미등장 보정을 추가한다.

```txt
rare 확률은 런 시작 시 -3% 보정으로 시작
카드 보상에서 common이 나올 때마다 rare 확률 +1%
rare가 등장하면 기본 확률로 초기화
보정 후 rare 확률 최대 +10%
Act 1 보상 카드 강화 확률 0%
Act 2 보상 카드 강화 확률 20%
Act 3 보상 카드 강화 확률 40%
```

### 카드 보상 스킵

카드 보상은 선택하지 않고 스킵할 수 있다.

```txt
Act 1 스킵 보상: 골드 8
Act 2 스킵 보상: 골드 10
Act 3 스킵 보상: 골드 12
```

스킵 보상은 작게 유지한다. 목적은 덱 품질을 지키는 선택권이지 골드 파밍이 아니다.

## 12. 동료 전투 행동

동료는 플레이어 턴 종료 후 기본 공격을 한다.

행동 순서:

```txt
플레이어 카드 사용
→ 턴 종료
→ 동료 1 기본 공격
→ 동료 2 기본 공격
→ 적 턴
```

동료가 2명일 경우 영입 순서대로 행동한다.

## 13. 동료 공격 대상

동료 공격 대상 규칙의 디자인 명칭은 **전술 표식**이다.

```txt
전술 표식 = combat_state.last_player_attack_target_id
```

단일 대상 공격 카드와 지휘 카드가 전술 표식을 갱신한다. 광역 공격만 사용했다면 전술 표식은 없음으로 처리한다.

```txt
1. 플레이어가 이번 턴 마지막으로 공격한 대상이 살아 있으면 그 대상을 공격한다.
2. 대상이 없거나 죽었으면 체력이 가장 낮은 적을 공격한다.
3. 체력이 가장 낮은 적이 여러 명이면 가장 앞쪽 적을 공격한다.
4. 광역 공격만 사용했다면 마지막 단일 대상 없음으로 처리한다.
```

UI 요구:

```txt
전술 표식 대상 적에게 작은 깃발/화살표 아이콘을 표시한다.
표식은 턴 종료 후 동료 공격이 끝나면 사라진다.
```

## 14. 엘리트 보상

엘리트 승리 시 유물 대신 강화 3택을 제공한다.

```txt
엘리트 승리 보상:
- 골드
- 카드 보상 3택
- 강화 3택
```

강화 3택 후보:

```txt
주인공 강화
동료 패시브 강화
동료 카드 강화
보상형 동료 보상 강화
```

동료가 없으면 주인공 강화만 나온다.

동료가 있으면 주인공 강화와 동료 강화가 섞여 나온다.

권장 생성 규칙:

```txt
1번 슬롯: 주인공 강화 확정
2~3번 슬롯: 주인공 강화 / 동료 패시브 강화 / 동료 카드 강화 중 추첨
```

## 15. 주인공 강화

주인공 강화는 엘리트 보상, 일부 이벤트, 보물/특수보상에서 얻을 수 있다.

주인공 강화 예시:

```txt
전체 공격 카드 피해 +1
전체 스킬 카드 방어도 +1
특정 카드 비용 -1
전투 시작 시 방어도 +6
첫 턴 드로우 +1
첫 턴 에너지 +1
공격 카드에 스플래시 피해 추가
콤보 공격 해금
동료 기본 공격 피해 +1
카드 보상에서 희귀 카드 확률 증가
여관 가격 할인
상점 카드 제거 비용 감소
```

주인공 강화는 다양하고 다채롭게 설계한다. 단, 한 강화가 런을 단독으로 망가뜨리지 않게 한다.

## 16. 동료 강화

동료 강화는 세 종류다.

```txt
동료 패시브 강화
동료 카드 강화
보상형 동료 보상 강화
```

동료 패시브는 기본 1단계에서 강화 1~2단계까지 확장 가능하게 만든다.

권장 기본값:

```txt
동료 패시브 최대 강화 단계: 2단계
동료 카드 강화: 각 카드 1회
```

## 17. 장비 시스템

장비는 캐릭터별 슬롯에 장착하지만, 효과는 다음 두 종류가 섞인다.

```txt
팀 전체 패시브
장착 캐릭터 전용 패시브
```

예:

```txt
힐량 20% 증가 장비는 힐러에게 장착해야 의미가 있다.
암살 딜러에게 장착하면 효과가 거의 없거나 없다.
```

### 장비 슬롯

```txt
주인공 슬롯 3개:
- 투구
- 갑옷
- 무기

동료 1명 영입 시 추가 슬롯 3개:
- 해당 동료의 투구
- 해당 동료의 갑옷
- 해당 동료의 무기
```

최대 동료 2명이므로 최대 장비 슬롯은 9개다.

```txt
주인공 3개 + 동료 1 3개 + 동료 2 3개 = 최대 9개
```

### 장비 인벤토리

장비는 전용 인벤토리에 모인다.

```txt
장비 인벤토리 필요
장착 장비와 미장착 장비를 구분
장비는 팔 수 없음
장비는 다음 노드를 선택할 때 자유롭게 교체 가능
```

### 장비 획득처

```txt
획득 가능:
- 상점
- 이벤트
- 보물/특수보상 방
- 일반 전투 후 10% 특수보상 이벤트

획득 불가:
- 일반 전투 직접 보상
- 엘리트 전투 직접 보상
- 보스 전투 직접 보상
```

## 18. 상점 시스템

상점 구성:

```txt
주인공 카드 구매
일반 카드 제거
일반 카드 강화
일반 카드 변화
일반 카드 복제
동료 카드 구매
동료 카드 강화
장비 구매
이벤트성 거래
```

상점에서 동료 카드는 보유한 동료의 미획득 카드만 등장한다.

상점에서 동료 카드 강화도 가능하다.

## 19. 여관 시스템

캠프파이어는 없다. 여관이 회복 노드를 대체한다.

여관은 일반 여관과 이벤트 여관으로 나뉜다.

```txt
일반 여관: 2/3
이벤트 여관: 1/3
```

두 종류 모두 항상 방 3개를 제시한다.

### 일반 여관

```txt
정직함
가격과 효과가 명확함
방 3개
표시된 회복량 그대로 적용
```

### 이벤트 여관

```txt
주인이 수상함
가격이 변동됨
공짜 방 가능
싼데 매우 좋은 방 가능
비싼데 평범한 방 가능
싼 방에서 체력 완전 회복 가능
해프닝은 있어도 런을 망치지 않음
```

이벤트 여관은 부정적 함정이 아니라 긍정적 변동성이다.

## 20. 보물/특수보상 방

보물/특수보상 방은 짧은 이벤트형 보상방이다.

가능한 보상:

```txt
골드
주인공 카드 강화
주인공 카드 제거
주인공 카드 변화
희귀 카드 선택
동료 카드 후보 발견
동료 카드 강화
장비 획득
장비 할인권
상점 할인
여관 무료 숙박권
```

## 21. 일반 전투 후 10% 특수보상

일반 전투 후 10% 확률로 짧은 보물/특수보상 이벤트가 발생한다.

```txt
일반 전투: 적용
엘리트 전투: 제외
보스 전투: 제외
```

흐름:

```txt
일반 전투 승리
→ 골드
→ 카드 보상
→ 10% 확률로 특수보상 이벤트
```

## 22. 저장 시스템

저장 대상:

```txt
현재 Act
현재 맵
현재 노드
주인공 체력
골드
덱
보유 동료
동료 강화 상태
동료 카드 획득 상태
장비 인벤토리
장착 장비
보유 주인공 강화
랜덤 시드
```

저장 타이밍:

```txt
런 시작
노드 선택 직후
노드 클리어 직후
보상 선택 후
장비 교체 후
Act 전환 후
```

## 23. 런 페이스와 전투 목표

첫 내부 플레이테스트 전 기준 목표는 다음과 같다.

```txt
MVP Act 1 플레이 시간: 20~30분
정식 3막 플레이 시간: 75~100분
일반 전투: 3~5턴
엘리트 전투: 5~7턴
보스 전투: 8~11턴
```

동료의 전투 기여 목표:

```txt
Act 2 동료 1명 보유 시 동료 기여: 전체 피해의 15~25%
Act 3 동료 2명 보유 시 동료 기여: 전체 피해의 20~35%
```

동료 기여가 10% 아래로 자주 내려가면 동료가 장식처럼 느껴진다. 40%를 자주 넘으면 플레이어 카드 선택보다 자동 공격이 중심이 된다.

## 24. 적 수치 기준

첫 데이터 작성 기준선:

```txt
Act 1 초반 일반 전투 적 총 HP: 38~70
Act 1 후반 일반 전투 적 총 HP: 60~95
Act 1 일반 적 공격 의도: 6~11
Act 1 엘리트 총 HP: 95~135
Act 1 보스 HP: 190~240

Act 2 일반 전투 총 HP: 100~160
Act 2 일반 적 공격 의도: 10~18
Act 2 엘리트 총 HP: 180~250
Act 2 보스 HP: 300~380

Act 3 일반 전투 총 HP: 170~260
Act 3 일반 적 공격 의도: 14~24
Act 3 엘리트 총 HP: 280~370
Act 3 보스 HP: 450~540
```

4에너지/6드로우 구조라 일반적인 3에너지/5드로우 덱빌더보다 플레이어의 초반 처리량이 높다. 대신 유물/포션이 없으므로 HP를 올리되, 공격 의도는 플레이테스트 전까지 보수적으로 유지한다.

## 25. 보스 설계 초안

보스는 단순 체력 높은 적이 아니라 해당 Act에서 배운 선택을 시험해야 한다.

### Act 1 보스: 무너진 성문의 탈영대장

목표:

```txt
동료 영입 직전의 최종 관문.
기본 공격/방어/드로우/카드 보상으로 만든 덱 품질을 시험한다.
전술 표식과 대상 우선순위의 필요성을 예고한다.
```

수치/패턴 초안:

```txt
HP: 200~220
1턴: 공격 10
2턴: 방어도 12 + 졸개 1명 지원 또는 자기 강화
3턴: 공격 6 x 2
4턴: 약화 1 + 공격 8
반복
```

### Act 2 보스: 쌍서약 기사단

목표:

```txt
동료 1명과의 시너지를 시험한다.
방어형/공격형/유틸형 동료마다 다른 해법이 보이게 한다.
Act 2 보스 후 새 동료와 기존 동료 강화 선택의 무게를 만든다.
```

수치/패턴 초안:

```txt
총 HP: 300~340, 두 적으로 분리 가능
방패 기사: 방어도, 피해 감소, 아군 보호
검 기사: 강한 단일 공격, 취약 대상 추가 피해
한쪽이 쓰러지면 남은 쪽이 강화되지만 즉시 폭주하지는 않음
```

### Act 3 보스: 검은 관문의 섭정

목표:

```txt
주인공 덱, 동료 2명, 장비 슬롯, 경제 선택의 최종 검증.
전술 표식, 광역, 방어, 회복, 장비 궁합 중 최소 두 축이 필요하게 만든다.
```

수치/패턴 초안:

```txt
HP: 460~500
페이즈 1: 공격과 방어를 번갈아 사용
페이즈 2: 표식 없는 턴에 작은 패널티, 표식 대상 공격 시 보상
페이즈 3: 강한 공격 의도와 방어/회복 압박
소환물은 가능하지만 덱에 상태 카드나 저주 카드를 넣지 않는다.
```

## 26. 골드 경제 기준

골드는 회복, 덱 품질, 장비/동료 투자를 동시에 압박한다.

획득 기준:

```txt
일반 전투 골드: 12~20
엘리트 전투 골드: 30~45
보스 전투 골드: 90~105
이벤트 골드 보상: 20~85
보물/특수보상 골드: 50~110
```

소비 기준:

```txt
Act 1 상점 방문 전 기대 골드: 130~190
상점 1회에서 의미 있는 선택: 카드 1장 + 서비스 1개 또는 장비 1개
여관 1회에서 의미 있는 선택: 싼 회복으로 버티기 또는 비싼 회복으로 안정화
카드 제거는 반복 구매 시 비용 상승으로 억제
```

## 27. 난이도 단계 기준

기본 밸런스는 표준 난이도 기준이다. 난이도는 핵심 규칙을 바꾸지 않고 수치 보정만 적용한다.

```txt
여행자:
- 시작 최대 체력 84
- Act 1 일반 전투 총 HP -10%
- Act 1 적 공격 의도 -1
- 보스 HP -8%
- 일반 여관 가격 -10%

표준:
- 기준 수치 그대로 사용
- 첫 플레이테스트와 공개 데모의 기준

숙련자:
- 시작 최대 체력 70
- 일반/엘리트/보스 HP +8%
- Act 2부터 적 공격 의도 +1
- 이벤트/보물 골드 보상 -10%
- 일반 여관 가격 +10%
```

클리어 후 단계형 난이도인 원정 규율은 정식 1차 이후 고려한다.

```txt
규율 1: 보스 HP +5%
규율 2: 엘리트 HP +8%
규율 3: 일반 적 공격 의도 +1
규율 4: 일반 여관 가격 +10%
규율 5: 이벤트 비용 +10%, 이벤트 골드 보상 -10%
규율 6: 시작 최대 체력 -6
규율 7: 카드 보상 강화 확률 절반
```

# FILE: 03_godot_architecture.md

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

# FILE: 04_data_schemas.md

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
    "levels": [
      {"level": 0, "bonus_damage": 3},
      {"level": 1, "bonus_damage": 5},
      {"level": 2, "bonus_damage": 7}
    ]
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
  "passive_level": 0,
  "bond_level": 0,
  "reward_bonus_level": 0,
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

`bond_level`은 디자인 명칭인 유대 단계다. 구현을 단순화하려면 MVP에서는 `passive_level`과 같은 값으로 유지해도 된다.

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

## 9. CompanionUpgradeData

```json
{
  "id": "upgrade_companion_passive",
  "type": "passive_level_up",
  "target": "companion",
  "description_ko": "선택한 동료의 패시브를 1단계 강화합니다."
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
boss
companion_foreshadow
```

`companion_foreshadow`는 Act 1에서 동료 후보를 미리 보여주는 이벤트성 노드다. 구현상 normal event로 처리해도 되지만, 맵 생성 가중치와 저장에서 구분할 수 있으면 좋다.

## 11. EnemyData

```json
{
  "id": "act1_bandit_grunt",
  "name_ko": "산적 졸개",
  "max_hp": 32,
  "block": 0,
  "intent_patterns": [
    {"type": "attack", "damage": 7, "weight": 60},
    {"type": "block", "block": 6, "weight": 30},
    {"type": "debuff", "status": "weak", "amount": 1, "weight": 10}
  ]
}
```

## 11.1 BossData

보스는 일반 적보다 패턴 의도가 중요하므로 별도 스키마를 둔다.

```json
{
  "id": "boss_act1_oathbreaker_captain",
  "name_ko": "무너진 성문의 탈영대장",
  "act": 1,
  "max_hp": 210,
  "design_goal_ko": "동료 영입 전 덱 품질과 전술 표식의 필요성을 시험합니다.",
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

# FILE: 05_companion_roster.md

# 05. 동료 10명 로스터 초안

이 문서는 동료 10명의 임시 확정 초안이다. 이름과 비주얼은 나중에 세계관 확정 후 수정할 수 있지만, 역할 구조와 시스템 기능은 현재 기준으로 확정한다.

## 공통 규칙

```txt
동료 총수: 10명
런 중 최대 동료 수: 2명
동료별 기본 공격력: 고정
동료별 패시브: 1개
동료별 전용 카드: 8장
동료 영입 시 카드 3장 표시, 2장 선택
동료 카드는 중복 획득 불가
동료는 별도 체력 없음
동료는 주인공과 체력 공유
동료는 매 턴 종료 시 기본 공격 1회
```

동료 클래스 분포:

```txt
공격형: 3명
방어형: 3명
디버프/유틸/힐러형: 3명
보상형: 1명
```

## 동료 설계 기준

각 동료는 반드시 아래 세 가지가 한 문장으로 설명되어야 한다.

```txt
1. 전투에서 무엇을 잘하는가?
2. 어떤 덱을 하고 싶게 만드는가?
3. 길 위에서 어떤 사람으로 기억되는가?
```

동료는 숫자 보너스가 아니라 "이번 런의 빌드 문"이다. 영입 화면에서는 아래 정보를 짧게 보여준다.

```txt
역할
기본 공격력
패시브 요약
추천 카드 방향
추천 장비 방향
성격 한 줄
```

## MVP 우선 동료 3명

MVP에서는 로완, 세라, 엘드릭을 먼저 구현한다.

```txt
로완: 전술 표식/취약/단일 대상. 동료 시스템의 조종감을 보여준다.
세라: 0비용/연타/드로우. 덱 회전과 공격 템포를 보여준다.
엘드릭: 방어도/피해 감소/반격. 생존형 동료도 재미있다는 것을 보여준다.
```

이 세 명은 공격형 2명과 방어형 1명이라 초반 테스트에서 덱 방향 차이가 선명하다.

## 동료별 한 줄 캐릭터 기준

| 동료 | 전투 역할 | 성격/몰입 포인트 | Act 1 예고 방식 |
|---|---|---|---|
| 로완 | 전술 표식 단일 딜러 | 말수 적은 추격자. 표적을 정하면 끝까지 간다. | 붉은 깃발과 창 자국 |
| 세라 | 0비용 연타 암살자 | 장난스럽지만 계산이 빠른 척후병. | 암호 표식과 얇은 단검 |
| 브람 | 광역 폭발 기술자 | 크게 웃고 크게 터뜨리는 위험한 장인. | 그을린 돌과 화약 냄새 |
| 엘드릭 | 안정 방어 기사 | 낡은 맹세를 아직 지키는 고집 센 기사. | 부서진 방패 문장 |
| 마렌 | 회복/지속 생존 수도승 | 조용히 상처를 돌보는 순례자. | 회색 천 조각과 약초 냄새 |
| 토르 | 큰 방어/약화 전사 | 거칠지만 먼저 맞아주는 북방 전사. | 큰 발자국과 찢긴 갑옷 |
| 리나 | 독/디버프 약초술사 | 부드럽게 말하지만 독을 잘 아는 떠돌이. | 초록 병과 말라붙은 잎 |
| 노아 | 드로우/손패 조작 점성술사 | 불길한 예언을 농담처럼 말하는 별읽기. | 별무늬 카드 조각 |
| 이솔 | 보호/위기 회복 사제 | 끝까지 희망을 버리지 않는 백사제. | 작은 은종 소리 |
| 카일 | 골드/상점 보상형 | 늘 웃지만 손익 계산이 빠른 거래꾼. | 은화가 든 찢어진 주머니 |

## 유대 단계 공통 기준

```txt
유대 0: 영입 직후. 패시브 기본 수치.
유대 1: 그 동료의 방향을 확실히 밀 때 도달. 패시브 수치 강화.
유대 2: 런의 중심 동료가 되었을 때 도달. 패시브 추가 조건 또는 보너스 해금.
```

동료별 강화 2단계는 단순 수치만 올리기보다, 가능하면 플레이 패턴을 선명하게 만드는 작은 조건을 붙인다.

---

# 공격형 동료 3명

## 1. 붉은창 로완

```txt
ID: companion_rowan
클래스: 공격형 / 단일 대상 딜러
비주얼: 붉은 망토를 두른 창병 용병
기본 공격력: 8
핵심 키워드: 집중 공격, 관통, 취약, 같은 대상 추격
```

### 패시브: 집중 추격

```txt
기본: 플레이어가 이번 턴에 같은 적을 2회 이상 공격했다면, 로완의 기본 공격 피해 +3.
강화 1: 추가 피해 +5.
강화 2: 추가 피해 +7, 취약 상태의 적에게는 추가로 +2.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 관통 찌르기 | 공격 | 1 | 피해 8. 대상에게 취약 1 부여. 강화: 피해 11. |
| 긴 사거리 | 공격 | 1 | 피해 6. 이번 턴 동료 기본 공격 피해 +2. 강화: +4. |
| 붉은 돌격 | 공격 | 2 | 피해 14. 대상을 전술 표식으로 고정. 강화: 피해 18. |
| 창벽 전술 | 스킬 | 1 | 방어도 7. 다음 동료 기본 공격 피해 +2. 강화: 방어도 10. |
| 약점 겨냥 | 스킬 | 1 | 취약 2 부여. 카드 1장 드로우. 강화: 비용 0. |
| 추격 명령 | 스킬 | 0 | 이번 턴 동료 기본 공격이 한 번 더 강하게 계산됨. 피해 +3. 강화: +5. |
| 전장의 눈 | 파워 | 1 | 플레이어가 같은 적을 연속 공격하면 첫 번째마다 방어도 3 획득. 강화: 방어도 5. |
| 붉은 깃발 | 파워 | 2 | 취약 상태의 적에게 주는 공격 카드 피해 +2. 강화: +3. |

---

## 2. 검은매 세라

```txt
ID: companion_sera
클래스: 공격형 / 연타·암살 딜러
비주얼: 짧은 검 두 자루를 쓰는 여성 척후병
기본 공격력: 6
핵심 키워드: 저비용, 콤보, 드로우, 연속 공격
```

### 패시브: 선제 베기

```txt
기본: 매 전투 첫 번째 공격 카드 피해 +4.
강화 1: 피해 +7.
강화 2: 첫 번째와 두 번째 공격 카드 피해 +5.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 빠른 베기 | 공격 | 0 | 피해 4. 강화: 피해 6. |
| 그림자 찌르기 | 공격 | 1 | 피해 7. 이번 턴 두 번째 공격 카드라면 카드 1장 드로우. 강화: 피해 9. |
| 쌍검 연속 | 공격 | 1 | 피해 3을 2회. 강화: 피해 4를 2회. |
| 약탈자의 발놀림 | 스킬 | 0 | 방어도 3. 이번 턴 공격 카드를 사용할 때마다 방어도 1. 강화: 방어도 5. |
| 틈새 파고들기 | 스킬 | 1 | 카드 2장 드로우 후 카드 1장 버림. 강화: 버리지 않음. |
| 암살 신호 | 스킬 | 1 | 이번 턴 동료 기본 공격 피해 +4. 강화: +6. |
| 밤의 규칙 | 파워 | 1 | 비용 0 공격 카드를 사용할 때마다 방어도 2. 강화: 방어도 3. |
| 검은매의 궤적 | 파워 | 2 | 한 턴에 공격 카드를 3장 이상 사용하면 카드 1장 드로우. 턴당 1회. 강화: 턴당 2회. |

---

## 3. 화약장이 브람

```txt
ID: companion_bram
클래스: 공격형 / 광역 피해
비주얼: 폭약 주머니를 든 드워프 기술자
기본 공격력: 7
핵심 키워드: 광역, 스플래시, 폭발, 높은 비용
```

### 패시브: 불씨 확산

```txt
기본: 전투당 1회, 첫 광역 공격 카드 피해 +5.
강화 1: +8.
강화 2: 전투당 2회 적용.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 작은 폭약 | 공격 | 1 | 모든 적에게 피해 5. 강화: 피해 7. |
| 파편탄 | 공격 | 1 | 대상에게 피해 8, 다른 적들에게 피해 3. 강화: 11/4. |
| 대형 폭발 | 공격 | 3 | 모든 적에게 피해 18. 강화: 피해 24. |
| 도화선 당기기 | 스킬 | 0 | 다음 공격 카드에 스플래시 피해 3 추가. 강화: 5. |
| 연막 주머니 | 스킬 | 1 | 방어도 8. 모든 적에게 약화 1. 강화: 방어도 11. |
| 재장전 | 스킬 | 1 | 카드 2장 드로우. 다음 광역 공격 비용 -1. 강화: 비용 0. |
| 화약 냄새 | 파워 | 1 | 광역 공격 카드를 사용할 때마다 무작위 적에게 피해 2. 강화: 피해 4. |
| 흔들리는 지반 | 파워 | 2 | 모든 적에게 피해를 줄 때 방어도 3 획득. 강화: 방어도 5. |

---

# 방어형 동료 3명

## 4. 방패기사 엘드릭

```txt
ID: companion_eldric
클래스: 방어형 / 안정 방어
비주얼: 낡은 문장 방패를 든 중갑 기사
기본 공격력: 5
핵심 키워드: 방어도, 반격, 피해 감소
```

### 패시브: 첫 방패

```txt
기본: 전투 시작 시 방어도 6 획득.
강화 1: 방어도 10.
강화 2: 방어도 10 + 첫 턴 받는 피해 2 감소.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 방패 밀치기 | 공격 | 1 | 피해 5. 현재 방어도가 10 이상이면 추가 피해 5. 강화: 피해 7/7. |
| 단단한 일격 | 공격 | 2 | 피해 12. 방어도 6 획득. 강화: 피해 15, 방어도 8. |
| 수호 자세 | 스킬 | 1 | 방어도 10. 강화: 방어도 13. |
| 엄호 | 스킬 | 1 | 방어도 7. 다음 동료 기본 공격 전까지 받는 피해 2 감소. 강화: 방어도 10. |
| 전열 유지 | 스킬 | 2 | 방어도 16. 카드 1장 드로우. 강화: 방어도 20. |
| 반격 준비 | 스킬 | 1 | 이번 턴 방어도를 얻을 때마다 다음 공격 피해 +1. 강화: +2. |
| 기사단 규율 | 파워 | 1 | 턴 시작 시 방어도 3 획득. 강화: 5. |
| 철벽의 맹세 | 파워 | 2 | 한 전투에서 처음 체력이 50% 이하가 되면 방어도 18 획득. 강화: 25. |

---

## 5. 수도승 마렌

```txt
ID: companion_maren
클래스: 방어형 / 지속 회복 보조
비주얼: 회색 수도복과 철제 지팡이를 든 수도승
기본 공격력: 4
핵심 키워드: 회복, 방어, 안정성
```

### 패시브: 조용한 간호

```txt
기본: 전투 종료 시 체력 3 회복.
강화 1: 체력 5 회복.
강화 2: 체력 5 회복 + 엘리트 전투 승리 시 추가 3 회복.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 지팡이 밀기 | 공격 | 1 | 피해 6. 약화 1 부여. 강화: 피해 8. |
| 절제된 일격 | 공격 | 1 | 피해 7. 이번 턴 회복했다면 피해 +5. 강화: 피해 10. |
| 짧은 기도 | 스킬 | 1 | 체력 3 회복, 방어도 5. 강화: 회복 5, 방어도 7. |
| 상처 돌보기 | 스킬 | 2 | 체력 8 회복. 강화: 체력 11 회복. |
| 침착한 호흡 | 스킬 | 0 | 방어도 4. 카드 1장 드로우. 강화: 방어도 6. |
| 고통 나누기 | 스킬 | 1 | 이번 턴 받는 피해 25% 감소. 강화: 35% 감소. |
| 순례자의 인내 | 파워 | 1 | 전투 중 처음 회복할 때 추가로 3 회복. 강화: 5. |
| 수도원의 밤 | 파워 | 2 | 턴 종료 시 손패가 0장이면 체력 2 회복. 강화: 체력 3. |

---

## 6. 철갑 곰지기 토르

```txt
ID: companion_tor
클래스: 방어형 / 피해 흡수·둔화
비주얼: 거대한 곰가죽 갑옷을 입은 북방 전사
기본 공격력: 6
핵심 키워드: 큰 방어도, 첫 피해 감소, 적 약화
```

### 패시브: 두꺼운 가죽

```txt
기본: 한 전투에서 처음 받는 피해 5 감소.
강화 1: 피해 8 감소.
강화 2: 피해 8 감소 + 같은 턴에 방어도 4 획득.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 곰손 타격 | 공격 | 2 | 피해 14. 약화 1 부여. 강화: 피해 18. |
| 땅울림 | 공격 | 1 | 모든 적에게 피해 4, 약화 1. 강화: 피해 6. |
| 두꺼운 가죽 | 스킬 | 1 | 방어도 9. 이번 턴 첫 피해 2 감소. 강화: 방어도 12. |
| 북방의 버팀 | 스킬 | 2 | 방어도 18. 강화: 방어도 24. |
| 짓누르기 | 스킬 | 1 | 대상에게 약화 2. 방어도 5. 강화: 약화 3. |
| 위협의 포효 | 스킬 | 1 | 모든 적에게 약화 1. 카드 1장 드로우. 강화: 비용 0. |
| 겨울가죽 | 파워 | 1 | 턴 시작 시 이전 턴에 피해를 받았다면 방어도 5. 강화: 7. |
| 곰의 영역 | 파워 | 2 | 방어도가 15 이상일 때 동료 기본 공격 피해 +3. 강화: +5. |

---

# 디버프 / 유틸 / 힐러형 동료 3명

## 7. 독초술사 리나

```txt
ID: companion_lina
클래스: 디버프/유틸 / 독·약화
비주얼: 약초 가방과 초록 망토를 가진 떠돌이 약초술사
기본 공격력: 4
핵심 키워드: 독, 약화, 취약, 디버프 증폭
```

### 패시브: 약효 증폭

```txt
기본: 플레이어가 디버프를 부여한 적에게 리나의 기본 공격 피해 +3.
강화 1: +5.
강화 2: +5, 디버프가 2종 이상이면 추가 +2.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 독침 | 공격 | 1 | 피해 5. 독 3 부여. 강화: 독 5. |
| 쓴 약병 | 공격 | 1 | 피해 6. 약화 1 부여. 강화: 피해 8, 약화 2. |
| 부식성 가루 | 스킬 | 1 | 취약 1, 독 2 부여. 강화: 취약 2. |
| 해독 연고 | 스킬 | 1 | 체력 4 회복. 약화/취약 중 하나 제거. 강화: 회복 6. |
| 풀잎 연막 | 스킬 | 0 | 모든 적에게 약화 1. 강화: 방어도 4 추가. |
| 농축 추출물 | 스킬 | 1 | 대상의 독 수치 +4. 강화: +6. |
| 독초 지식 | 파워 | 1 | 독을 부여할 때마다 방어도 2. 강화: 방어도 3. |
| 느린 죽음 | 파워 | 2 | 독 피해가 적용될 때 추가 피해 1. 강화: 추가 피해 2. |

---

## 8. 별읽는 노아

```txt
ID: companion_noa
클래스: 유틸 / 드로우·카드 조작
비주얼: 별무늬 로브를 입은 젊은 점성술사
기본 공격력: 3
핵심 키워드: 드로우, 손패 조작, 예지, 보존
```

### 패시브: 첫 별빛

```txt
기본: 첫 턴에 카드 1장 추가 드로우.
강화 1: 첫 턴에 카드 2장 추가 드로우.
강화 2: 첫 턴에 카드 2장 추가 드로우 + 에너지 1 획득.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 별빛 화살 | 공격 | 1 | 피해 6. 카드 1장 드로우. 강화: 피해 8. |
| 궤도 타격 | 공격 | 2 | 피해 12. 손패가 6장 이상이면 피해 +6. 강화: 15/+8. |
| 별점 보기 | 스킬 | 0 | 카드 2장 드로우 후 카드 1장 버림. 강화: 카드 3장 드로우 후 1장 버림. |
| 손패 정렬 | 스킬 | 1 | 카드 2장 드로우. 이번 턴 다음 카드 비용 -1. 강화: 비용 0. |
| 미래 붙잡기 | 스킬 | 1 | 손패 카드 1장을 보존한다. 방어도 5. 강화: 방어도 8. |
| 별자리 기록 | 스킬 | 1 | 이번 턴 사용한 카드 타입 수만큼 카드 드로우. 강화: +1장. |
| 별의 리듬 | 파워 | 1 | 매 턴 첫 번째 드로우 카드 사용 시 방어도 2. 강화: 4. |
| 예언자의 밤 | 파워 | 2 | 턴 시작 시 손패가 4장 이하라면 카드 1장 추가 드로우. 강화: 조건 5장 이하. |

---

## 9. 백사제 이솔

```txt
ID: companion_isol
클래스: 힐러 / 보호·회복
비주얼: 흰 사제복과 작은 종을 든 성직자
기본 공격력: 3
핵심 키워드: 회복, 보호, 정화, 위기 대응
```

### 패시브: 마지막 축복

```txt
기본: 전투 중 처음 체력이 30% 이하가 되면 체력 6 회복.
강화 1: 체력 10 회복.
강화 2: 체력 10 회복 + 방어도 8 획득.
```

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 성광 | 공격 | 1 | 피해 5. 체력 2 회복. 강화: 피해 7, 회복 3. |
| 심판의 종 | 공격 | 2 | 피해 13. 취약 상태의 적에게 피해 +5. 강화: 피해 17. |
| 보호 기도 | 스킬 | 1 | 방어도 8. 체력 2 회복. 강화: 방어도 11, 회복 3. |
| 정화 | 스킬 | 1 | 약화/취약/부상 중 하나 제거. 카드 1장 드로우. 강화: 비용 0. |
| 빛의 장막 | 스킬 | 2 | 방어도 14. 다음 턴 시작 시 체력 4 회복. 강화: 방어도 18. |
| 성수 한 방울 | 스킬 | 0 | 체력 2 회복. 이번 턴 회복량 +20%. 강화: 회복 3. |
| 신성한 보호 | 파워 | 1 | 매 전투 첫 회복 시 방어도 6 획득. 강화: 방어도 9. |
| 종소리의 맹세 | 파워 | 2 | 체력이 50% 이하일 때 사용하는 스킬 카드 효과 +2. 강화: +3. |

---

# 보상형 동료 1명

## 10. 은주머니 카일

```txt
ID: companion_kyle
클래스: 보상형
비주얼: 웃는 얼굴의 상인 겸 도박꾼
기본 공격력: 2
핵심 키워드: 골드, 상점, 보상, 위험 거래
```

### 보상 효과: 눈썰미 좋은 거래꾼

```txt
기본: 전투 승리 시 골드 +15%.
강화 1: 골드 +25%.
강화 2: 골드 +25%, 상점 서비스 비용 10% 감소.
```

보상형 동료는 전투 중 패시브가 없다. 기본 공격은 한다.

### 전용 카드 8장

| 카드 | 타입 | 비용 | 효과 |
|---|---|---:|---|
| 동전 던지기 | 공격 | 0 | 피해 3. 이번 전투에서 골드 보상 +2. 강화: 피해 5. |
| 계산된 일격 | 공격 | 1 | 피해 7. 보유 골드가 150 이상이면 피해 +5. 강화: 피해 10. |
| 흥정 | 스킬 | 0 | 방어도 4. 다음 상점 서비스 비용 5% 감소. 전투당 1회만 누적. 강화: 방어도 6. |
| 비상금 | 스킬 | 1 | 골드 10을 잃고 방어도 12 획득. 강화: 방어도 16. |
| 위험 거래 | 스킬 | 1 | 체력 3 손실. 카드 2장 드로우. 강화: 체력 2 손실. |
| 보상 예감 | 스킬 | 1 | 이번 전투 승리 시 10% 특수보상 확률 +10%. 강화: +15%. |
| 장사꾼의 감 | 파워 | 1 | 전투 승리 시 골드 +5. 강화: +8. |
| 황금 계산서 | 파워 | 2 | 상점에 도달할 때까지 보유 골드 100당 공격 카드 피해 +1, 최대 +3. 강화: 최대 +5. |

---

# 동료별 장비 궁합 메모

| 동료 | 추천 장비 방향 | 의미 없는 장비 예시 |
|---|---|---|
| 로완 | 무기 피해, 취약 시너지, 단일 대상 강화 | 힐량 증가 |
| 세라 | 비용 0 카드, 연타, 첫 공격 강화 | 광역 피해 강화 |
| 브람 | 광역, 스플래시, 고비용 공격 보조 | 단일 연속 공격 강화 |
| 엘드릭 | 방어도, 피해 감소, 반격 | 독 피해 증가 |
| 마렌 | 회복량, 전투 후 회복, 방어 | 순수 암살 피해 강화 |
| 토르 | 첫 피해 감소, 약화, 큰 방어 | 드로우 전용 장비 |
| 리나 | 독, 약화, 취약, 디버프 증폭 | 순수 방어 장비 |
| 노아 | 드로우, 비용 감소, 손패 보존 | 회복량 증가 |
| 이솔 | 힐량, 보호, 위기 회복 | 독 증폭 |
| 카일 | 골드, 상점 할인, 보상 확률 | 기본 공격 피해 대폭 강화 |

# FILE: 06_cards_equipment_balance.md

# 06. 주인공 카드, 장비, 강화 밸런스 초안

## 1. 시작 상태

```txt
주인공 타입: 균형형
시작 최대 체력: 76
시작 현재 체력: 76
시작 골드: 99
기본 에너지: 4
매턴 드로우: 6
```

## 2. 시작 덱

```txt
5x 기본 공격
4x 기본 방어
1x 전술 정비
```

시작 덱 의도:

```txt
기본 공격 5장: Act 1 초반 전투가 지나치게 늘어지지 않게 한다.
기본 방어 4장: 4에너지/6드로우 구조에서 매턴 방어 선택지를 확보한다.
전술 정비 1장: 초반부터 손패 조작의 재미를 보여주되, 덱을 과하게 빠르게 만들지 않는다.
```

| 카드 | 타입 | 비용 | 효과 | 강화 |
|---|---|---:|---|---|
| 기본 공격 | 공격 | 1 | 피해 6 | 피해 9 |
| 기본 방어 | 스킬 | 1 | 방어도 5 | 방어도 8 |
| 전술 정비 | 스킬 | 0 | 카드 1장 드로우 후 카드 1장 버림 | 카드 2장 드로우 후 카드 1장 버림 |

## 3. 주인공 카드풀 규모

```txt
총 40장
공격 16장
스킬 16장
파워 8장
```

아래 목록은 1차 구현용 초안이다. 수치는 테스트 후 조정한다.

## 4. 카드 수치 기준

기본 전투값은 에너지 4, 드로우 6이다. 따라서 카드 한 장의 가치는 아래 기준으로 맞춘다.

### 피해 카드 기준

```txt
0비용 공격: 피해 3~5
1비용 공격: 피해 7~9
2비용 공격: 피해 14~18
3비용 공격: 피해 24~32
광역 피해는 같은 비용 단일 피해의 60~75% 수준
드로우, 취약, 약화, 동료 피해 증가가 붙으면 피해를 10~30% 낮춘다.
```

### 방어/유틸 카드 기준

```txt
0비용 방어: 방어도 3~5 또는 작은 보조 효과
1비용 방어: 방어도 7~10
2비용 방어: 방어도 15~20
카드 1장 드로우는 약 0.5 에너지 가치
에너지 1 획득은 조건부 또는 1회성 권장
전투 중 회복은 강하므로 피해/방어보다 낮은 수치로 시작
```

### 파워 카드 기준

```txt
1비용 파워: 매 턴 작지만 확실한 이득
2비용 파워: 특정 빌드를 열거나 중간 규모 누적 이득
3비용 파워: 희귀하고 강한 빌드 중심축. 사용 턴이 위험해야 함
```

### 동료 카드 기준

```txt
동료 기본 공격 피해 +2는 1턴 한정이면 작은 보너스
동료 기본 공격 피해 +4 이상은 조건부 또는 비용 1 이상 권장
모든 동료 즉시 공격은 희귀 카드 또는 높은 비용 카드로 제한
동료 카드는 주인공 일반 카드의 완전 상위호환이 되면 안 됨
```

---

# 주인공 공격 카드 16장

| ID | 이름 | 비용 | 희귀도 | 효과 |
|---|---|---:|---|---|
| p_strike | 기본 공격 | 1 | starter | 피해 6. 강화: 9. |
| p_clean_cut | 깔끔한 베기 | 1 | common | 피해 8. 강화: 11. |
| p_wide_swing | 넓은 휘두르기 | 1 | common | 모든 적에게 피해 5. 강화: 7. |
| p_counter_slash | 반격 베기 | 1 | common | 피해 6. 이번 턴 방어도를 얻었다면 피해 +5. 강화: 8/+7. |
| p_guard_break | 방패 깨기 | 1 | common | 피해 7, 취약 1. 강화: 피해 9, 취약 2. |
| p_double_cut | 이중 베기 | 1 | common | 피해 4를 2회. 강화: 피해 5를 2회. |
| p_heavy_blade | 무거운 검격 | 2 | uncommon | 피해 16. 강화: 21. |
| p_sweeping_order | 소탕 명령 | 2 | uncommon | 모든 적에게 피해 10. 선택한 적을 전술 표식으로 지정. 강화: 13. |
| p_pommel_draw | 손잡이 타격 | 1 | uncommon | 피해 7, 카드 1장 드로우. 강화: 피해 10. |
| p_last_target | 표적 고정 | 1 | uncommon | 피해 6. 대상을 전술 표식으로 지정하고 이번 턴 동료 기본 공격 피해 +3. 강화: 피해 8, +5. |
| p_splash_blade | 파편 검격 | 2 | uncommon | 대상에게 피해 13, 다른 적에게 피해 4. 강화: 17/6. |
| p_combo_starter | 연계 시작 | 0 | uncommon | 피해 4. 콤보 1 획득. 강화: 피해 6. |
| p_combo_finisher | 연계 마무리 | 2 | rare | 피해 12 + 콤보당 피해 4. 콤보 소모. 강화: 16/+5. |
| p_decisive_blow | 결단의 일격 | 3 | rare | 피해 28. 강화: 36. |
| p_command_strike | 지휘 타격 | 2 | rare | 피해 15. 모든 동료가 즉시 기본 공격. 강화: 피해 19. |
| p_breakthrough | 돌파 | 2 | rare | 피해 12. 적 처치 시 에너지 1 회복. 강화: 피해 16. |

---

# 주인공 스킬 카드 16장

| ID | 이름 | 비용 | 희귀도 | 효과 |
|---|---|---:|---|---|
| p_defend | 기본 방어 | 1 | starter | 방어도 5. 강화: 8. |
| p_tactical_maintenance | 전술 정비 | 0 | starter | 카드 1장 드로우 후 1장 버림. 강화: 2장 드로우 후 1장 버림. |
| p_guard | 경계 | 1 | common | 방어도 8. 강화: 11. |
| p_quick_step | 빠른 발놀림 | 0 | common | 방어도 3. 카드 1장 드로우. 강화: 방어도 5. |
| p_rally | 집결 | 1 | common | 방어도 6. 다음 동료 기본 공격 피해 +2. 강화: 방어도 8, +3. |
| p_focus | 집중 | 1 | common | 다음 공격 카드 피해 +5. 강화: +8. |
| p_patch_wound | 상처 봉합 | 1 | common | 체력 4 회복. 강화: 6. |
| p_shield_line | 방어진 | 2 | uncommon | 방어도 15. 강화: 20. |
| p_draw_two | 전술 독해 | 1 | uncommon | 카드 2장 드로우. 강화: 비용 0. |
| p_order_change | 명령 변경 | 1 | uncommon | 손패 카드 1장의 비용을 이번 턴 0으로 만든다. 강화: 카드 2장 중 1장 선택. |
| p_disarm_motion | 무장 해제 | 1 | uncommon | 적에게 약화 2. 강화: 약화 3, 카드 1장 드로우. |
| p_hold_position | 위치 사수 | 1 | uncommon | 방어도 7. 손패 1장을 보존. 강화: 방어도 10. |
| p_battlefield_scan | 전장 파악 | 0 | rare | 카드 3장 드로우 후 2장 버림. 강화: 3장 드로우 후 1장 버림. |
| p_emergency_order | 긴급 명령 | 2 | rare | 에너지 2 획득. 카드 1장 드로우. 강화: 비용 1. |
| p_mass_guard | 집단 엄호 | 2 | rare | 방어도 10. 동료 수만큼 추가 방어도 5. 강화: 추가 7. |
| p_reset_plan | 작전 재정비 | 1 | rare | 손패를 모두 버리고 같은 수만큼 드로우. 강화: 비용 0. |

---

# 주인공 파워 카드 8장

| ID | 이름 | 비용 | 희귀도 | 효과 |
|---|---|---:|---|---|
| p_steady_command | 안정된 지휘 | 1 | common | 매 턴 첫 번째 스킬 카드 사용 시 방어도 3. 강화: 5. |
| p_sharp_orders | 날카로운 명령 | 1 | common | 매 턴 첫 번째 공격 카드 피해 +3. 강화: +5. |
| p_companion_sync | 동료 연계 | 1 | uncommon | 동료 기본 공격 피해 +1. 강화: +2. |
| p_battle_rhythm | 전투 리듬 | 2 | uncommon | 한 턴에 카드 3장 사용 시 카드 1장 드로우. 턴당 1회. 강화: 비용 1. |
| p_defensive_formation | 방어 진형 | 2 | uncommon | 턴 시작 시 방어도 4. 강화: 6. |
| p_splash_training | 파편 전술 | 2 | rare | 단일 공격 카드가 다른 적 하나에게 피해 2를 준다. 강화: 피해 4. |
| p_combo_doctrine | 연계 교리 | 2 | rare | 한 턴에 공격 카드를 연속 사용하면 콤보 1 획득. 강화: 첫 턴에 콤보 1. |
| p_commanders_oath | 지휘관의 맹세 | 3 | rare | 매 턴 종료 시 모든 동료 기본 공격 피해 +2. 강화: +3. |

---

# 주인공 강화 목록 초안

주인공 강화는 엘리트 보상, 일부 이벤트, 보물/특수보상에서 등장한다. 보스 보상에는 등장하지 않는다.

## 공격 강화

| 이름 | 효과 |
|---|---|
| 검날 연마 | 모든 공격 카드 피해 +1 |
| 날카로운 전술 | 모든 공격 카드 피해 +2, 희귀 |
| 파편 훈련 | 단일 공격 카드가 다른 적 하나에게 스플래시 피해 2 |
| 넓은 검로 | 광역 공격 카드 피해 +2 |
| 표적 지시 | 전술 표식 대상에게 동료 기본 공격 피해 +1 |
| 결정타 훈련 | 적 체력이 30% 이하일 때 공격 카드 피해 +3 |

## 비용/카드 조작 강화

| 이름 | 효과 |
|---|---|
| 경량화 | 무작위 주인공 카드 1장의 비용 -1. 최소 0. |
| 개선된 손놀림 | 첫 턴 드로우 +1 |
| 정비 습관 | 전투 시작 시 카드 1장 드로우 후 1장 버림 |
| 빠른 판단 | 매 전투 첫 번째 스킬 카드 비용 -1 |
| 전술 압축 | 카드 보상에서 스킵 시 골드 +15 |

## 방어 강화

| 이름 | 효과 |
|---|---|
| 두꺼운 견갑 | 전투 시작 시 방어도 6 |
| 안정된 자세 | 매 턴 첫 번째 방어도 획득량 +2 |
| 상처 관리 | 전투 종료 시 체력 2 회복 |
| 굳은 의지 | 전투당 1회, 체력이 40% 이하가 되면 방어도 10 |
| 갑옷 손질 | 받는 첫 피해 3 감소 |

## 콤보/해금 강화

| 이름 | 효과 |
|---|---|
| 콤보 공격 해금 | 콤보 카운터 시스템 활성화. 일부 카드가 콤보를 사용한다. |
| 연계 속도 | 콤보 2 이상일 때 공격 카드 피해 +2 |
| 마무리 훈련 | 콤보를 소모하는 카드 피해 +5 |
| 동료 연계술 | 동료 기본 공격 후 콤보 1 획득. 턴당 1회. |

## 경제/탐험 강화

| 이름 | 효과 |
|---|---|
| 여관 단골 | 일반 여관 방 가격 10% 감소 |
| 흥정술 | 상점 서비스 비용 10% 감소 |
| 보물 감각 | 일반 전투 후 특수보상 확률 +3% |
| 장비 관리 | 장비 구매 가격 10% 감소 |
| 안전한 여행 | 이벤트에서 체력 손실 선택지의 손실량 15% 감소 |

---

# 장비 시스템

## 장비 슬롯

```txt
각 캐릭터는 투구 / 갑옷 / 무기 슬롯을 가진다.
주인공은 시작부터 3슬롯.
동료는 영입 시 3슬롯 추가.
최대 장비 슬롯은 9개.
```

## 장비 효과 범위

```txt
team_passive: 팀 전체에 적용
owner_only: 장착 캐릭터에게만 적용
```

## 장비 교체

```txt
다음 노드를 선택하는 맵 화면에서 자유롭게 교체 가능.
전투 중 교체 불가.
장비 판매 불가.
미장착 장비는 장비 인벤토리에 보관.
```

## 장비 예시 24개

| 이름 | 슬롯 | 범위 | 효과 | 가격 |
|---|---|---|---|---:|
| 선봉대 철투구 | 투구 | 팀 | 모든 동료 기본 공격 피해 +1 | 95 |
| 전술가의 모자 | 투구 | 장착자 | 장착자가 주인공이면 첫 턴 드로우 +1 | 120 |
| 치유사의 은관 | 투구 | 장착자 | 장착자의 회복 효과 +20% | 110 |
| 매의 두건 | 투구 | 장착자 | 장착자가 공격형이면 첫 공격 피해 +3 | 100 |
| 낡은 기사갑 | 갑옷 | 팀 | 전투 시작 시 방어도 +4 | 100 |
| 순례자의 망토 | 갑옷 | 장착자 | 장착자의 회복 관련 카드 비용이 1 낮아질 확률 20% | 130 |
| 두꺼운 가죽갑옷 | 갑옷 | 팀 | 한 전투에서 첫 피해 2 감소 | 120 |
| 별무늬 로브 | 갑옷 | 장착자 | 장착자가 유틸형이면 첫 턴 드로우 +1 | 115 |
| 지휘검 | 무기 | 팀 | 모든 공격 카드 피해 +1 | 140 |
| 용병의 창 | 무기 | 장착자 | 장착자의 기본 공격 피해 +2 | 100 |
| 사제의 종 | 무기 | 장착자 | 장착자가 힐러이면 회복 시 방어도 2 획득 | 110 |
| 폭약 주머니 | 무기 | 장착자 | 장착자가 광역형이면 광역 피해 +2 | 125 |
| 은 상단 배지 | 투구 | 팀 | 상점 카드 가격 10% 감소 | 150 |
| 여행자의 장화끈 | 갑옷 | 팀 | 여관 가격 10% 감소 | 95 |
| 보물지도 조각 | 투구 | 팀 | 일반 전투 후 특수보상 확률 +2% | 130 |
| 결속의 목깃 | 갑옷 | 팀 | 동료가 2명일 때 전투 시작 방어도 +6 | 150 |
| 암살자의 단검 | 무기 | 장착자 | 장착자가 공격형이면 비용 0 공격 피해 +2 | 130 |
| 철벽 방패끈 | 갑옷 | 장착자 | 장착자가 방어형이면 방어 카드 효과 +2 | 120 |
| 독초 주머니 | 무기 | 장착자 | 장착자가 디버프형이면 독 부여량 +1 | 125 |
| 금화 주머니 | 투구 | 장착자 | 장착자가 보상형이면 전투 골드 +5% | 140 |
| 전령의 뿔 | 무기 | 팀 | 동료 기본 공격 대상이 취약이면 피해 +2 | 130 |
| 군의관 가방 | 갑옷 | 팀 | 전투 종료 시 체력 1 회복 | 160 |
| 수상한 열쇠 | 투구 | 팀 | 이벤트 선택지에서 보물 결과 확률 소폭 증가 | 170 |
| 무거운 대검 | 무기 | 장착자 | 장착자의 기본 공격 피해 +4, 첫 턴 드로우 -1 | 95 |

## 장비 설계 주의

장비가 유물처럼 무제한 누적되면 안 된다. 장비는 슬롯 제한과 장착 캐릭터 궁합으로 제어한다.

```txt
장비는 많아도 동시에 장착 가능한 수가 제한된다.
장비 효과 일부는 장착 캐릭터 전용이라 궁합이 중요하다.
팔 수 없으므로 구매 선택이 중요하다.
```

장비가 재미있는 선택이 되려면 아래 중 최소 하나를 만족해야 한다.

```txt
현재 보유 동료와 강한 궁합이 있다.
앞으로 영입할 동료를 상상하게 만든다.
팀 전체에 작지만 안정적인 이득을 준다.
상점/여관/보물 같은 비전투 선택을 바꾼다.
강한 효과와 작은 페널티가 함께 있어 장착 대상을 고민하게 만든다.
```

장비 밸런스 경고:

```txt
팀 전체 공격 피해 +2 이상은 매우 강하므로 희귀 장비 또는 조건부로 둔다.
첫 턴 드로우 +1은 강한 효과이므로 가격을 높이거나 장착자 조건을 둔다.
회복량 증가는 힐러/수도승 계열에게만 의미 있게 만들어 장비 궁합을 살린다.
골드/상점 할인 장비는 전투력을 직접 올리지 않으므로 중반 이후에도 선택할 이유를 추가한다.
```

# FILE: 07_events_inn_shop_treasure.md

# 07. 이벤트, 여관, 상점, 보물/특수보상

## 1. 이벤트의 역할

본 게임은 유물과 포션이 없다. 따라서 이벤트가 런의 변동성을 크게 담당한다.

이벤트의 역할:

```txt
1. 골드 소비/획득
2. 체력 손실/회복
3. 카드 제거/강화/변화/복제
4. 장비 획득
5. 동료 관련 선택
6. 일반 전투 외 위험 선택
7. 여관/상점과 연결되는 서사 선택
8. 보상형 동료와 시너지
```

이벤트의 핵심 감각:

```txt
모른 채 당하는 함정이 아니라, 위험을 알고도 손을 뻗고 싶은 기회.
숫자 손익만 있는 선택이 아니라, 이번 런의 방향을 바꾸는 선택.
동료가 있으면 같은 사건도 다르게 읽히는 선택.
```

## 2. 이벤트 금지 결과

아래 결과는 만들지 않는다.

```txt
유물 획득
포션 획득
저주 카드 추가
상태 카드 추가
동료 상실
장비 강제 삭제
즉사
체력 0으로 강제 감소
영구 디버프
런을 망치는 대형 손실
```

## 3. 이벤트 권장 결과

```txt
체력 손실
체력 회복
최대 체력 증가/감소
골드 획득/손실
주인공 카드 강화
주인공 카드 제거
주인공 카드 변화
주인공 카드 복제
동료 카드 강화
장비 획득
상점 할인
여관 무료 숙박권
일반 전투 발생
약한 특수 전투 발생
주인공 강화 획득
```

기대값 기준:

```txt
체력 5~8 손실: 카드 강화 또는 골드 45~70 상당.
체력 10~14 손실: 장비, 희귀 카드 후보, 주인공 강화급 보상.
골드 40~60 비용: 일반 장비/카드 강화/보상 확률 상승.
전투 발생 선택지: 일반 전투보다 보상이 확실히 좋아야 함.
```

## 4. 이벤트 타입

```txt
normal_event: 일반 이벤트
companion_event: 보유 동료 관련 이벤트
inn_event: 이벤트 여관 내부 결과
treasure_event: 보물/특수보상 방
shop_event: 상점 이벤트성 거래
combat_event: 이벤트로 발생하는 전투
```

## 5. 이벤트 수량 권장

MVP:

```txt
공통 이벤트 10개
Act 1 이벤트 4개
Act 1 동료 예고 이벤트 3개 이상
여관 이벤트 결과 9개
보물/특수보상 이벤트 6개
```

정식 1차:

```txt
공통 이벤트 20개
Act별 이벤트 각 8개
여관 이벤트 결과 18개
보물/특수보상 이벤트 12개
동료 전용 이벤트 동료당 1개 이상
```

## 5.1 Act 1 동료 예고 이벤트

Act 1 보스 후 동료를 정식 영입하기 전에, 플레이어가 동료 시스템의 맛을 볼 수 있게 한다.

공통 규칙:

```txt
Act 1 depth 3~8 사이에 1회 노출 권장.
동료를 영입하지 않는다.
동료 카드를 덱에 추가하지 않는다.
동료 슬롯을 차지하지 않는다.
다음 전투 1회성 보정 또는 정보 보상을 제공한다.
Act 1 보스 후 동료 후보에는 예고로 본 동료가 최소 1명 포함된다.
```

예시:

### 붉은 깃발의 흔적

```txt
상황:
부러진 창대에 붉은 천이 묶여 있다. 주변 적들은 모두 같은 방향으로 쓰러져 있다.

선택지:
1. 흔적을 따라간다.
   - 로완이 Act 1 보스 후 후보에 등장할 확률 크게 증가.
   - 다음 전투에서 첫 전술 표식 대상에게 추가 피해 3.

2. 창날을 챙긴다.
   - 골드 25 획득.
   - 다음 전투 보정 없음.

3. 조심스럽게 지나간다.
   - 효과 없음.
```

### 검은매의 암호

```txt
상황:
낡은 이정표 뒤에 빠른 손놀림으로 새긴 암호가 있다.

선택지:
1. 암호를 해독한다.
   - 세라가 Act 1 보스 후 후보에 등장할 확률 크게 증가.
   - 다음 전투 첫 공격 카드 피해 +3.

2. 표시된 은닉처를 뒤진다.
   - 골드 35 획득.
   - 20% 확률로 약한 전투.

3. 모르는 척한다.
   - 효과 없음.
```

### 낡은 방패 문장

```txt
상황:
버려진 초소 벽에 오래된 기사단 문장이 남아 있다.

선택지:
1. 문장을 정비한다.
   - 엘드릭이 Act 1 보스 후 후보에 등장할 확률 크게 증가.
   - 다음 전투 시작 방어도 5.

2. 초소를 수색한다.
   - 카드 보상 스킵 골드 +5. 다음 카드 보상 1회에만 적용.

3. 지나간다.
   - 효과 없음.
```

---

# 여관 시스템

## 6. 여관 기본 구조

캠프파이어는 존재하지 않는다. 여관이 회복 노드 역할을 한다.

```txt
여관 노드 비중: 10%
일반 여관 확률: 2/3
이벤트 여관 확률: 1/3
일반/이벤트 여관 모두 방 3개 표시
```

## 7. 일반 여관

일반 여관은 정직하고 예측 가능하다.

```txt
방 3개
가격 고정
효과 명확
표시된 회복량 그대로 적용
해프닝 없음
```

일반 여관 방 예시:

| 방 | 가격 | 효과 |
|---|---:|---|
| 작은 방 | 35골드 | 최대 체력 22% 회복 |
| 좋은 방 | 80골드 | 최대 체력 45% 회복 |
| 귀족 방 | 125골드 | 최대 체력 70% 회복 |

방 이름은 여관마다 바꿔도 된다.

## 8. 이벤트 여관

이벤트 여관은 처음부터 수상하게 연출된다.

```txt
주인이 수상함
가격 변동 가능
공짜 방 가능
싼데 매우 좋은 방 가능
비싼데 평범한 방 가능
싼 방에서 체력 완전 회복 가능
비정상적 상황은 해프닝 수준
전체 경험은 긍정적 변동성
```

이벤트 여관은 함정이 아니다. 체력이 낮을 때만 도박처럼 느껴져야 한다.

금지:

```txt
즉사
강제 치명 손실
대량 골드 손실
덱 오염
동료 상실
장비 삭제
영구 디버프
```

허용:

```txt
약한 괴물 조우
소량 골드 손실
소량 체력 손실
다음 전투 첫 턴 드로우 -1
대신 더 큰 보상 가능
체력 완전 회복
숨겨진 장비 발견
카드 강화
상점 할인
```

## 9. 이벤트 여관 방 결과 예시

| 방 | 가격 | 표시 문구 | 실제 결과 예시 |
|---|---:|---|---|
| 삐걱거리는 공짜 방 | 0 | 너무 공짜라서 수상하다 | 20% 회복, 25% 확률 완전 회복, 15% 확률 약한 전투 |
| 붉은 커튼 방 | 25 | 싸지만 향이 독하다 | 15% 회복, 카드 1장 강화 가능성 |
| 주인이 추천한 방 | 60 | 묘하게 따뜻하다 | 35% 회복, 보물 발견 가능성 |
| 비단 침대 방 | 120 | 비싸지만 평범해 보인다 | 45% 회복. 추가 효과 없을 수도 있음 |
| 잠긴 옆방 | 45 | 안쪽에서 소리가 난다 | 조사 시 전투, 승리 시 장비/골드 |
| 창문 없는 방 | 10 | 잠만 자기엔 나쁘지 않다 | 10% 회복, 30% 확률 완전 회복 |
| 연회장 침상 | 90 | 손님이 너무 많다 | 60% 회복, 다음 전투 첫 턴 드로우 -1 |
| 고양이가 있는 방 | 30 | 고양이가 침대를 차지하고 있다 | 25% 회복, 20% 확률 장비 발견 |
| 주인의 개인실 | 150 | 왜 이 방을 내주는지 모르겠다 | 완전 회복 또는 희귀 보상 가능 |

## 10. 여관 생성 규칙

### 일반 여관 생성

```txt
1. 일반 여관 방 풀에서 3개 선택.
2. 가격과 효과를 명확히 표시.
3. 골드가 부족하면 선택 불가 표시.
```

### 이벤트 여관 생성

```txt
1. 이벤트 여관 방 풀에서 3개 선택.
2. 가격을 변동시킨다.
3. 표시 문구는 수상하게 만든다.
4. 실제 결과는 긍정적 변동성 원칙을 지킨다.
```

## 11. 여관 UI 요구사항

```txt
방 카드 3개 표시
가격 표시
예상 효과 또는 수상한 문구 표시
현재 체력/최대 체력 표시
현재 골드 표시
선택 불가 시 명확한 표시
떠나기 버튼 제공
```

---

# 상점 시스템

## 12. 상점 구성

상점은 유물/포션을 팔지 않는다.

상점에서 가능한 것:

```txt
주인공 카드 구매
일반 카드 제거
일반 카드 강화
일반 카드 변화
일반 카드 복제
동료 카드 구매
동료 카드 강화
장비 구매
이벤트성 거래
```

## 13. 상점 상품 구성 권장

한 상점에서 표시할 상품:

```txt
주인공 카드 4장
동료 카드 1~2장
장비 3개
서비스 4개
이벤트성 거래 0~1개
```

동료가 없으면 동료 카드 상품은 주인공 카드 또는 장비로 대체한다.

상점의 목표는 "전부 사고 싶지만 하나나 둘만 살 수 있는 상태"다.

```txt
Act 1 첫 상점 도착 기대 골드: 130~190.
보통 카드 1장 + 서비스 1개 또는 장비 1개를 살 수 있어야 한다.
상점 방문 후에도 여관 비용을 남길지 고민하게 해야 한다.
```

## 14. 상점 가격 초안

| 항목 | 가격 |
|---|---:|
| 일반 카드 | 45~60골드 |
| 비범 카드 | 70~95골드 |
| 희귀 카드 | 135~175골드 |
| 동료 카드 | 85~140골드 |
| 일반 카드 제거 | 75골드, 사용 시 +25 |
| 일반 카드 강화 | 90골드 |
| 일반 카드 변화 | 70골드 |
| 일반 카드 복제 | 100골드 |
| 동료 카드 강화 | 120골드 |
| 일반 장비 | 95~130골드 |
| 비범 장비 | 150~220골드 |
| 희귀 장비 | 240~330골드 |

카드 제거 비용은 구매할 때마다 증가한다.

```txt
기본 제거 비용: 75골드
제거 1회마다: +25골드
```

## 15. 상점 동료 카드 규칙

```txt
보유한 동료의 미획득 카드만 등장.
이미 획득한 동료 카드는 등장하지 않음.
영입하지 않은 동료의 카드는 등장하지 않음.
```

## 16. 상점 장비 규칙

```txt
장비는 상점의 주요 상품.
장비는 구매 후 인벤토리에 들어감.
장비는 즉시 장착해도 되지만, 기본적으로 다음 노드 선택 화면에서 자유 교체 가능.
장비는 팔 수 없음.
```

## 17. 상점 이벤트성 거래 예시

| 이름 | 효과 |
|---|---|
| 수상한 보증서 | 50골드 지불. 다음 보물/특수보상 방에서 장비 등장 확률 증가. |
| 여관 추천장 | 40골드 지불. 다음 여관 방 하나 무료. |
| 낡은 지도 | 60골드 지불. 다음 맵 노드 중 하나의 타입 공개. |
| 용병 계약서 | 80골드 지불. 다음 동료 카드 보상 확률 증가. |
| 대장장이 예약권 | 70골드 지불. 다음 노드 후 일반 카드 강화 가능. |

---

# 보물/특수보상 방

## 18. 기본 정의

보물/특수보상 방은 짧은 이벤트형 보상방이다.

```txt
노드 비중: 5%
유물 상자 없음
포션 없음
장비, 골드, 카드 조작, 특수 보상을 제공
```

## 19. 보상 예시

```txt
골드 60 획득
주인공 카드 1장 강화
주인공 카드 1장 제거
주인공 카드 1장 변화
희귀 카드 3택
동료 카드 1장 발견
동료 카드 1장 강화
장비 1개 획득
상점 할인권 획득
여관 무료 숙박권 획득
주인공 강화 획득
```

## 20. 보물/특수보상 이벤트 예시

### 버려진 무기고

```txt
선택지 1: 무기를 챙긴다.
- 무기 장비 1개 획득.

선택지 2: 조심스럽게 살핀다.
- 골드 40 획득.
- 25% 확률로 추가 장비 발견.

선택지 3: 오래된 검술서를 읽는다.
- 주인공 공격 카드 1장 강화.
```

### 잠긴 금고

```txt
선택지 1: 힘으로 연다.
- 체력 5 손실.
- 골드 80 획득.

선택지 2: 시간을 들여 연다.
- 다음 노드 선택 전까지 장비 교체 불가.
- 장비 1개 획득.

선택지 3: 포기한다.
- 효과 없음.
```

### 여행자의 묘비

```txt
선택지 1: 기도한다.
- 체력 10 회복.

선택지 2: 검을 가져간다.
- 무기 장비 1개 획득.
- 다음 전투 첫 턴 드로우 -1.

선택지 3: 이름을 기록한다.
- 주인공 강화 후보 2개 중 1개 선택.
```

## 21. 일반 전투 후 10% 특수보상

일반 전투 후 10% 확률로 짧은 보물/특수보상 이벤트가 발생한다.

```txt
일반 전투: 적용
엘리트: 제외
보스: 제외
```

이 이벤트는 전투 직접 보상이 아니라 별도 후속 이벤트다.

```txt
일반 전투 승리
→ 골드
→ 카드 보상
→ 10% 판정
→ 성공 시 짧은 특수보상 이벤트
```

---

# 일반 이벤트 예시

## 22. 버려진 마차

```txt
상황:
길가에 부서진 마차가 있다.

선택지:
1. 짐을 뒤진다.
   - 골드 35 획득.
   - 20% 확률로 약한 전투.

2. 부서진 장비를 수리한다.
   - 40골드 지불.
   - 무작위 장비 1개 획득.

3. 그냥 지나간다.
   - 효과 없음.
```

## 23. 길 잃은 대장장이

```txt
선택지:
1. 대장장이를 돕는다.
   - 체력 6 손실.
   - 주인공 카드 1장 강화.

2. 돈을 내고 수리를 맡긴다.
   - 75골드 지불.
   - 장비 1개 강화 효과 부여 또는 주인공 카드 강화.

3. 떠난다.
   - 효과 없음.
```

## 24. 낯선 용병단

```txt
선택지:
1. 훈련에 참가한다.
   - 전투 발생.
   - 승리 시 주인공 강화 1개 선택.

2. 정보를 산다.
   - 40골드 지불.
   - 다음 엘리트 위치 공개 또는 보상 증가.

3. 술을 나눈다.
   - 체력 10 회복.
   - 20% 확률로 골드 20 손실.
```

## 25. 동료의 흔적

보유 동료가 있을 때 등장 가능.

```txt
선택지:
1. 흔적을 따라간다.
   - 해당 동료 카드 1장 보상 후보.

2. 동료에게 맡긴다.
   - 해당 동료 패시브 강화 후보 등장 가능.

3. 무시한다.
   - 효과 없음.
```

# FILE: 08_mvp_roadmap_and_codex_prompts.md

# 08. MVP 로드맵과 Codex 프롬프트

## 1. 개발 목표

Godot 4.x + GDScript 기반으로, 매 단계마다 실행 가능한 상태를 유지한다.

최종 목표:

```txt
3막 구조
동료 10명
주인공 카드 40장
동료 카드 80장
장비/여관/상점/이벤트/보물 시스템
PC/모바일 가로 화면 대응
```

MVP 목표:

```txt
Act 1 플레이 가능
전투 가능
카드 보상 가능
동료 3명 임시 영입 가능
여관/상점/이벤트 최소 구현
세이브/로드 최소 구현
```

MVP 개발 전 기획 기준:

```txt
09_design_upgrade_research_and_balance.md를 수치 기준으로 사용한다.
일반 전투 3~5턴, 엘리트 5~7턴, 보스 8~11턴을 1차 목표로 한다.
동료는 자동 공격 보너스가 아니라 덱/장비/이벤트 방향을 바꾸는 빌드 축이어야 한다.
Act 1에서는 정식 영입 전 동료 예고 이벤트를 통해 게임의 차별점을 미리 보여준다.
난이도는 우선 표준 기준만 구현하고, 여행자/숙련자/원정 규율은 밸런스 지표가 쌓인 뒤 확장한다.
```

---

# Milestone 0. 프로젝트 뼈대

## 목표

Godot 프로젝트의 기본 폴더, 오토로드, 데이터 로더, 빈 화면 전환 구조를 만든다.

## 산출물

```txt
DataRegistry
RngService
SaveService
SceneRouter
RunState
balance_constants.json
기본 Main 씬
```

## Codex 프롬프트

```txt
res://docs/design/의 문서를 읽고, Godot 4.x + GDScript 프로젝트의 기본 구조를 만들어라.
우선 03_godot_architecture.md의 폴더 구조를 따른다.
DataRegistry, RngService, SaveService, SceneRouter, RunState를 만든다.
09_design_upgrade_research_and_balance.md의 기본 수치를 담은 balance_constants.json을 만든다.
아직 전투는 만들지 말고, 새 런 시작 버튼과 빈 맵 화면으로 이동하는 흐름만 구현해라.
모든 파일 역할을 주석으로 간단히 설명해라.
```

## 완료 기준

```txt
프로젝트 실행 가능
새 런 시작 가능
빈 맵 화면 표시 가능
오류 없음
```

---

# Milestone 1. 카드와 덱 로직

## 목표

카드 데이터, 카드 인스턴스, 덱/손패/버림/셔플 로직을 구현한다.

## 산출물

```txt
CardData
CardInstance
DeckState
protagonist_cards.json 일부
기본 시작 덱
카드 보상 스킵 수치
```

## Codex 프롬프트

```txt
카드와 덱 로직을 구현해라.
06_cards_equipment_balance.md의 시작 덱을 기준으로 기본 공격, 기본 방어, 전술 정비 카드를 JSON 데이터로 만든다.
DeckState는 draw_pile, hand, discard_pile, exhaust_pile을 가져야 한다.
카드 6장 드로우, 카드 사용 후 버림, 턴 종료 시 손패 버림, draw_pile이 부족할 때 discard_pile 셔플을 구현해라.
UI는 아직 단순 텍스트 로그로 충분하다.
카드 보상 스킵 골드는 balance_constants.json에서 읽을 수 있게 준비해라.
```

## 완료 기준

```txt
새 전투 덱 생성 가능
카드 6장 드로우 가능
카드 사용/버림 가능
셔플 가능
```

---

# Milestone 2. 최소 전투

## 목표

플레이어와 적 1마리의 턴제 전투를 만든다.

## 산출물

```txt
CombatState
TurnManager
CombatController
CardEffectResolver
EnemyData
EnemyAIResolver
CombatScreen
CardView
전술 표식 표시
```

## Codex 프롬프트

```txt
최소 전투를 구현해라.
기본 에너지는 4, 매턴 드로우는 6이다.
플레이어는 기본 공격과 기본 방어를 사용할 수 있어야 한다.
적 1마리는 단순히 매턴 피해 6을 준다.
카드 효과 처리는 CardEffectResolver에 둔다.
단일 대상 공격은 combat_state.last_player_attack_target_id를 갱신한다.
CombatScreen은 현재 체력, 방어도, 에너지, 손패, 적 체력을 표시한다.
전술 표식 대상 적에는 작은 표시를 보여준다.
UI 코드가 데미지 계산을 직접 하지 않게 해라.
```

## 완료 기준

```txt
카드 사용 가능
에너지 감소
피해/방어 처리
전술 표식 갱신
적 턴 처리
승리/패배 판정
```

---

# Milestone 3. 카드 보상과 맵 흐름

## 목표

전투 승리 후 카드 3택을 만들고, 맵 노드로 돌아간다.

## 산출물

```txt
CardRewardGenerator
CardRewardScreen
MapState
MapGenerator
MapScreen
```

## Codex 프롬프트

```txt
전투 승리 후 카드 보상 3택을 구현해라.
동료가 없을 때는 주인공 카드 3장이 나온다.
카드를 선택하면 덱에 추가되고 맵 화면으로 돌아간다.
보상 스킵을 구현하고, Act 1 스킵 시 골드 8을 준다.
Act 1의 임시 맵은 12노드로 만들고, 일반 전투 노드만 있어도 된다.
이 단계에서는 동료 예고 이벤트 없이 일반 전투만으로도 된다.
```

## 완료 기준

```txt
전투 승리 후 카드 선택 가능
카드 보상 스킵 가능
선택 카드가 덱에 추가됨
다음 노드 선택 가능
```

---

# Milestone 4. Act 1 보스와 동료 영입

## 목표

Act 1 보스 처치 후 동료 3택과 동료 카드 선택을 구현한다.

## 산출물

```txt
CompanionData
CompanionInstance
CompanionManager
CompanionRewardGenerator
CompanionRewardScreen
CompanionCardSelectScreen
Act 1 동료 예고 이벤트
```

## Codex 프롬프트

```txt
Act 1 보스 처치 후 동료 영입 시스템을 구현해라.
05_companion_roster.md에서 동료 3명만 먼저 구현한다: 로완, 세라, 엘드릭.
Act 1 보스는 02_systems_spec.md의 "무너진 성문의 탈영대장" 초안을 사용한다.
Act 1 중반에는 동료의 흔적 이벤트를 1회 보여주고, 본 후보가 보스 후 3택에 최소 1명 포함되게 해라.
보스 처치 후 신규 동료 3명을 표시하고 하나를 선택하게 한다.
동료를 선택하면 해당 동료 카드 8장 중 3장을 표시하고, 그중 2장을 선택해 즉시 덱에 추가한다.
선택하지 않은 카드와 미공개 카드는 이후 카드 보상 후보가 된다.
동료 카드는 중복 획득 불가다.
```

## 완료 기준

```txt
Act 1 보스 처치 가능
동료 예고 이벤트 작동
동료 3택 표시
동료 선택 가능
동료 카드 3장 중 2장 선택 가능
선택 카드 덱 추가
```

---

# Milestone 5. 동료 전투 행동

## 목표

동료가 전투 중 매 턴 기본 공격을 하게 한다.

## 산출물

```txt
CompanionCombatSystem
last_player_attack_target 추적
CompanionPanel
```

## Codex 프롬프트

```txt
동료 전투 행동을 구현해라.
동료는 플레이어 턴 종료 후 영입 순서대로 기본 공격을 1회 한다.
대상은 전술 표식, 즉 플레이어가 이번 턴 마지막으로 단일 공격 또는 지휘 카드로 지정한 살아있는 적이다.
대상이 없으면 체력이 가장 낮은 적을 공격한다.
동료는 별도 체력이 없고 주인공과 체력을 공유한다.
동료는 적의 직접 타겟이 되지 않는다.
```

## 완료 기준

```txt
동료가 턴 종료 후 공격
마지막 공격 대상 추적
대상 없을 때 최저 체력 적 공격
다수 적 전투에서 동작
```

---

# Milestone 6. 엘리트 강화 보상

## 목표

엘리트 승리 시 강화 3택을 구현한다.

## 산출물

```txt
EliteRewardGenerator
EliteUpgradeScreen
ProtagonistUpgradeService
CompanionUpgradeService
```

## Codex 프롬프트

```txt
엘리트 승리 보상을 구현해라.
엘리트 승리 시 골드, 카드 보상, 강화 3택을 제공한다.
동료가 없으면 주인공 강화만 나온다.
동료가 있으면 주인공 강화, 동료 패시브 강화, 동료 카드 강화가 섞여 나온다.
동료 카드는 일반 카드 강화로 강화할 수 없다.
동료 카드 강화 선택지는 보유한 동료 카드 중 하나를 고르게 해야 한다.
```

## 완료 기준

```txt
엘리트 전투 구분 가능
강화 3택 표시
주인공 강화 적용
동료 패시브 강화 적용
동료 카드 강화 적용
```

---

# Milestone 7. 여관

## 목표

일반/이벤트 여관을 구현한다.

## 산출물

```txt
InnGenerator
InnRoomGenerator
InnResultResolver
InnScreen
```

## Codex 프롬프트

```txt
여관 시스템을 구현해라.
여관은 일반 여관 2/3, 이벤트 여관 1/3 확률로 생성된다.
일반/이벤트 모두 방 3개를 표시한다.
일반 여관은 가격과 효과가 명확하고 그대로 적용된다.
이벤트 여관은 수상한 주인과 변동 가격/효과를 가진다.
이벤트 여관은 함정이 아니라 긍정적 변동성이다. 즉사, 대형 손실, 덱 오염, 동료 상실은 만들지 마라.
```

## 완료 기준

```txt
여관 노드 진입 가능
방 3개 표시
골드 지불
체력 회복
이벤트 방 변동 결과 처리
```

---

# Milestone 8. 상점과 장비

## 목표

상점, 장비 인벤토리, 장착 교체를 구현한다.

## 산출물

```txt
EquipmentData
EquipmentInstance
EquipmentInventory
EquipmentEffectResolver
ShopGenerator
ShopScreen
EquipmentInventoryScreen
```

## Codex 프롬프트

```txt
상점과 장비 시스템을 구현해라.
장비는 투구/갑옷/무기 슬롯을 가진다.
주인공은 3슬롯, 동료 1명당 3슬롯이 추가된다.
장비 효과는 팀 전체 패시브와 장착 캐릭터 전용 효과가 섞인다.
장비는 인벤토리에 보관되고, 다음 노드 선택 화면에서 자유롭게 교체할 수 있다.
장비는 팔 수 없다.
상점은 주인공 카드, 일반 카드 제거/강화/변화/복제, 동료 카드 구매/강화, 장비를 제공한다.
```

## 완료 기준

```txt
장비 구매 가능
장비 인벤토리 표시
장비 장착/해제 가능
장비 효과 적용
상점 서비스 작동
```

---

# Milestone 9. 보물/특수보상과 이벤트

## 목표

보물/특수보상 노드와 일반 전투 후 10% 특수보상을 구현한다.

## Codex 프롬프트

```txt
보물/특수보상 방을 구현해라.
보물/특수보상 방은 짧은 이벤트형 보상방이다.
장비, 골드, 주인공 카드 강화/제거/변화, 동료 카드 강화, 주인공 강화 등을 제공할 수 있다.
일반 전투 후에는 10% 확률로 특수보상 이벤트가 발생한다.
엘리트와 보스 전투 후에는 이 10% 보상이 발생하지 않는다.
```

## 완료 기준

```txt
보물 노드 작동
특수보상 선택지 작동
일반 전투 후 10% 판정 작동
엘리트/보스 제외 확인
```

---

# Milestone 10. Act 2/3와 저장

## 목표

3막 구조와 저장/로드를 구현한다.

## Codex 프롬프트

```txt
3막 구조와 저장/로드를 구현해라.
각 Act는 12노드 후 보스 1종으로 끝난다.
Act 1과 Act 2 보스 후에는 동료 선택/강화 3택이 나온다.
Act 2에서는 기존 동료가 1/4 확률로 재등장해 강화 선택지가 된다.
Act 3 보스 처치 후에는 엔딩 화면으로 이동한다.
보스 초안은 02_systems_spec.md의 Act 1/2/3 보스 설계 기준을 따른다.
런 상태, 덱, 동료, 장비 인벤토리, 장착 장비, 골드, 체력, 맵 상태를 저장/로드한다.
```

## 완료 기준

```txt
Act 1~3 진행 가능
Act 2 기존 동료 1/4 재등장
Act 3 클리어 가능
저장/로드 가능
```

---

# 개발 중 Codex에게 자주 줄 수 있는 지시문

## 구조 점검

```txt
현재 구현이 docs/design 문서와 충돌하는 부분이 있는지 점검해라.
특히 유물, 포션, 저주, 상태 카드, 카드 생성이 들어가 있으면 제거해라.
UI가 게임 규칙을 직접 처리하는 곳이 있으면 순수 로직 클래스로 분리해라.
```

## 버그 수정

```txt
이 에러 로그를 기준으로 원인을 찾아 수정해라.
관련 없는 리팩토링은 하지 마라.
수정한 파일과 이유를 설명해라.
수정 후 재현 테스트 방법을 알려줘라.
```

## 새 카드 추가

```txt
06_cards_equipment_balance.md의 형식에 맞춰 주인공 카드 데이터를 추가해라.
카드 효과는 CardEffectResolver가 처리 가능한 effect type만 사용해라.
새로운 effect type이 필요하면 먼저 CardEffectResolver에 작은 단위로 추가하고 테스트 카드 1장으로 검증해라.
```

## 새 동료 추가

```txt
05_companion_roster.md의 형식에 맞춰 새 동료 데이터를 추가해라.
동료는 기본 공격력, 패시브, 카드 8장을 가져야 한다.
동료 카드는 중복 획득 불가 규칙을 따라야 한다.
```

## 밸런스 조정

```txt
현재 수치를 밸런스 조정해라.
단, 구조를 바꾸지 말고 JSON 데이터의 숫자만 조정해라.
변경 전후 수치를 표로 요약해라.
```

## 모바일 UI 점검

```txt
PC와 모바일 모두 가로 화면 기준으로 UI를 점검해라.
카드 텍스트, 손패, 적 의도, 동료 패널, 장비 인벤토리가 1280x720에서도 읽히는지 확인해라.
고정 픽셀 배치를 줄이고 Control 노드의 anchor/container를 사용해라.
```

# FILE: 09_design_upgrade_research_and_balance.md

# 09. 기획 업그레이드: 레퍼런스, 재미 축, 밸런스 기준

이 문서는 기존 기획 문서를 실제 개발 전 한 번 더 단단하게 만들기 위한 기준서다.

목표는 단순히 유명한 덱빌더를 따라 하는 것이 아니다. 검증된 재미 구조는 가져오되, 본 게임의 핵심인 **동료 영입/강화/장비/이벤트**가 매 런의 정체성을 바꾸도록 설계한다.

---

## 1. 외부 레퍼런스에서 가져올 것

### Slay the Spire

참고:

- Steam 소개: https://store.steampowered.com/app/646570/Slay_the_Spire/
- Gameplay Wiki: https://slay-the-spire.fandom.com/wiki/Gameplay
- 밸런스/지표 인터뷰: https://www.gamedeveloper.com/design/how-i-slay-the-spire-i-s-devs-use-data-to-balance-their-roguelike-deck-builder

가져올 점:

```txt
작은 카드 선택이 누적되어 큰 빌드가 된다.
맵 경로 선택은 안전/위험/보상의 명확한 거래다.
카드 제거/강화/보상 스킵은 덱 품질 관리의 핵심이다.
밸런스는 감으로 시작하되, 픽률/승리덱 포함률/피해량 같은 지표로 검증한다.
```

주의할 점:

```txt
우리 게임은 유물, 포션, 저주 카드, 상태 카드를 쓰지 않는다.
따라서 유물의 폭발적인 런 변동성은 동료, 장비, 이벤트, 여관이 나눠 맡아야 한다.
```

### Monster Train

참고:

- 공식 사이트: https://www.themonstertrain.com/
- Steam 소개: https://store.steampowered.com/app/1102190/Monster_Train/

가져올 점:

```txt
장르의 기본 문법 위에 강한 구조적 비틀림 하나를 둔다.
클랜 조합처럼, 두 축을 결합하면 매 런의 해석이 달라진다.
카드 업그레이드와 유닛/클랜 조합이 "이번 런은 이 방향"이라는 감각을 빠르게 만든다.
```

우리 게임의 대응:

```txt
Monster Train의 다층 전장은 본 게임의 동료 조합으로 대응한다.
주인공 덱 + 동료 A + 동료 B + 장비 궁합이 매 런의 조합 축이다.
```

### Across the Obelisk / Gordian Quest / Roguebook

참고:

- Across the Obelisk 공식 소개: https://www.paradoxinteractive.com/games/across-the-obelisk/about
- Across the Obelisk Steam: https://store.steampowered.com/app/1385380/Across_the_Obelisk/
- Gordian Quest 정보: https://steambase.io/games/gordian-quest/info
- Roguebook 기사: https://www.pcgamer.com/roguebook-is-a-deckbuilder-with-a-touch-of-magic/

가져올 점:

```txt
파티 기반 덱빌더는 조합을 만드는 재미가 강하다.
영웅별 카드 풀이 분리되면 캐릭터 정체성이 분명해진다.
두 영웅 또는 여러 영웅이 하나의 전투 계획 안에서 맞물릴 때 차별성이 생긴다.
```

주의할 점:

```txt
파티원이 너무 많으면 전투와 보상 판단이 느려진다.
캐릭터별 체력, 위치, 스킬트리, 장비, 덱을 모두 깊게 만들면 MVP가 무거워진다.
본 게임은 동료 최대 2명, 공유 체력, 자동 기본 공격으로 판단량을 제한한다.
```

### Griftlands

참고:

- Klei 공식 소개: https://www.klei.com/games/griftlands
- Klei FAQ: https://support.klei.com/hc/en-us/articles/360044519912-What-is-Griftlands
- Steam 소개: https://store.steampowered.com/app/601840/Griftlands/

가져올 점:

```txt
카드 보상만으로는 세계가 기억에 남기 어렵다.
친구, 적, 선택의 결과가 런마다 작은 서사를 만든다.
동료와 이벤트가 연결되면 "내 덱"뿐 아니라 "내 일행"에 애착이 생긴다.
```

우리 게임의 대응:

```txt
동료는 단순 전투 보너스가 아니라 이벤트, 장비 궁합, 카드 보상, 보스 후 선택에 영향을 준다.
동료별 개인 이벤트는 정식 1차 목표에서 각 1개 이상 필요하다.
MVP에서도 로완, 세라, 엘드릭은 전투 역할뿐 아니라 짧은 성격/동기 문구를 가진다.
```

---

## 1.1 레퍼런스 정확 수치 벤치마크

아래 수치는 공개 위키/가이드에서 확인한 실제 게임 수치다. 그대로 복제하지 않고, 본 게임의 4에너지/6드로우/동료/장비 구조에 맞춰 환산 기준으로 사용한다.

### Slay the Spire 수치

출처:

- Gameplay: https://slay-the-spire.fandom.com/wiki/Gameplay
- Gold: https://slaythespire.wiki.gg/wiki/Gold
- Merchant: https://slay-the-spire.fandom.com/wiki/Merchant
- Ironclad/Silent/Defect/Watcher: https://slay-the-spire.fandom.com/wiki/Ironclad
- Monsters/Elites/Bosses: https://slay-the-spire.fandom.com/wiki/Monsters

핵심 수치:

```txt
기본 전투: 매턴 드로우 5, 에너지 3.
기본 카드 보상: 전투 후 카드 3택.
시작 골드: 99.
시작 체력: Ironclad 80, Silent 70, Defect 75, Watcher 72.
시작 덱: Ironclad 10장, Defect 10장, Watcher 10장, Silent 12장.
```

보상/상점 수치:

```txt
일반 전투 골드: 10~20.
엘리트 전투 골드: 25~35.
보스 전투 골드: 95~105.
상점 일반 카드: 45~55.
상점 비범 카드: 68~82.
상점 희귀 카드: 135~165.
카드 제거: 75, 사용할 때마다 +25.
휴식 회복: 최대 체력의 30%.
```

카드 희귀도:

```txt
비상점 카드 보상: common 60%, uncommon 37%, rare 3%.
상점 카드: common 54%, uncommon 37%, rare 9%.
rare 확률은 처음에는 표시값보다 5% 낮게 시작하고, common이 나올 때마다 +1% 보정된다.
Act 1 보상 카드는 강화되어 나오지 않는다.
Act 2 보상 카드 강화 확률: 25%.
Act 3 보상 카드 강화 확률: 50%.
```

Act 1 적 기준:

```txt
초반 일반 전투 후보: Cultist 25%, Jaw Worm 25%, 2 Louses 25%, Small Slimes 25%.
Act 1 엘리트 HP:
- Gremlin Nob 82~86.
- Lagavulin 109~111.
- 3 Sentries는 각 38~42, 총 114~126.

Act 1 보스 HP:
- Slime Boss 140.
- The Guardian 240.
- Hexaghost 250.
```

해석:

```txt
Slay the Spire는 3에너지/5드로우인데도 Act 1 보스 HP가 140~250이다.
대신 유물, 포션, 휴식, 강화, 보스 후 완전 회복, 강한 상태 카드/저주 리스크가 함께 존재한다.
우리 게임은 4에너지/6드로우라 턴당 선택량이 크지만, 유물/포션이 없고 Act 1 보스 후 동료가 붙는다.
따라서 Act 1 보스 HP는 190~240이 적정 출발점이며, 보스 보상 골드는 StS와 비슷한 90~105로 둔다.
```

### Monster Train 수치

출처:

- Pyre: https://monster-train.fandom.com/wiki/Pyre
- Ember: https://monster-train.fandom.com/wiki/Ember
- Starter Deck: https://monster-train.fandom.com/wiki/Starter_Deck

핵심 수치:

```txt
기본 에너지 자원 Ember: 매턴 3.
Pyre 시작 체력: 80.
Major Boss 처치마다 Pyre 체력 +30, 최대 140.
Pyre 기본 공격: 20, 보스 처치마다 +10.
Covenant 0 시작 덱: 챔피언 + 주 클랜 스타터 5장 + 보조 클랜 스타터 5장 + Train Steward 4장 = 15장.
상위 난이도는 Deadweight 같은 약한 카드를 시작 덱에 추가해 17~22장까지 커진다.
```

해석:

```txt
Monster Train은 시작 덱이 15장으로 크지만, 두 클랜 조합과 유닛 배치가 런 정체성을 바로 만든다.
우리 게임은 시작 덱 10장으로 얇게 시작하되, 동료 카드 2장 추가 시점부터 조합 정체성이 생긴다.
동료 영입 후 덱이 12장 이상이 되는 순간부터 카드 보상 스킵과 제거 서비스가 중요해진다.
```

### Across the Obelisk 수치

출처:

- Review with battle resource summary: https://mgn.gg/across-the-obelisk-game-review/
- Hero stat examples: https://ato.fandom.com/wiki/Laia

핵심 수치:

```txt
파티는 4영웅 구조.
영웅마다 개별 덱을 가진다.
전투에서 영웅들은 4에너지로 시작하고 매턴 3에너지를 얻으며, 남은 에너지를 다음 턴으로 저장할 수 있다.
예시 영웅 Laia: HP 98, Speed 13, 시작 덱 15장.
```

해석:

```txt
AtO는 파티 조합과 개별 덱이 깊지만 판단량이 크다.
우리 게임은 동료 최대 2명, 공유 체력, 자동 기본 공격으로 판단량을 낮춘다.
다만 에너지 4 시작 구조는 AtO처럼 큰 선택 폭을 주므로, 일반 전투가 2턴 안에 끝나지 않게 적 총 HP를 보정해야 한다.
```

### Griftlands 수치

출처:

- Sal: https://griftlands.fandom.com/wiki/Sal

핵심 수치:

```txt
Sal은 전투 덱과 협상 덱을 따로 가진다.
Sal 전투 시작 덱: 11장.
Sal 협상 시작 덱: 10장.
Sal의 전투 핵심은 Combo/Finisher, 협상 핵심은 Influence/Dominance.
카드 세트는 전투 카드 3장 + 협상 카드 3장 묶음으로 해금된다.
```

해석:

```txt
Griftlands는 카드 보상과 캐릭터 서사가 연결될수록 런이 기억에 남는다는 좋은 사례다.
우리 게임은 덱을 둘로 나누지 않지만, 동료 이벤트와 전용 카드풀로 "내 일행의 이야기"를 만들어야 한다.
```

### Roguebook 수치

출처:

- Talents: https://roguebook.fandom.com/wiki/Talents

핵심 수치:

```txt
시작 덱 10장을 기준으로, 카드 4장을 추가할 때마다 재능 선택지가 열린다.
재능은 덱 일관성 손실을 보상하는 구조다.
최대 6개 행까지 해금된다.
```

해석:

```txt
보통 덱빌더는 덱이 커질수록 일관성이 떨어진다.
Roguebook은 덱 증가를 성장 보상으로 전환한다.
우리 게임은 같은 방식의 재능 시스템을 만들지 않지만, 동료 카드가 덱을 키우는 부담을 유대/장비/동료 패시브가 보상해야 한다.
```

---

## 2. 본 게임의 재미 핵심

### 핵심 문장

```txt
플레이어는 균형형 주인공의 덱을 다듬으며, 길 위에서 만난 동료와 장비를 조합해 매 런 다른 전술 부대를 완성한다.
```

### 플레이어가 매 런 해야 하는 질문

```txt
1. 지금 덱은 다음 전투를 버틸 수 있는가?
2. 이번 동료는 내 덱의 어떤 약점을 메우거나 어떤 강점을 폭발시키는가?
3. 골드를 회복, 카드 품질, 장비, 동료 카드 중 어디에 투자할 것인가?
4. 위험한 노드로 가서 성장할 것인가, 안전한 노드로 체력을 지킬 것인가?
5. 두 번째 동료를 새로 받을 것인가, 첫 동료를 강화해 한 축을 밀 것인가?
```

### 5대 설계 법칙

```txt
1. 모든 동료는 "빌드 문"이자 "사람"이어야 한다.
2. 동료의 영향은 매 전투 보이되, 플레이어 카드 선택으로 조종 가능해야 한다.
3. 장비는 무제한 유물이 아니라 제한된 슬롯 퍼즐이어야 한다.
4. 이벤트는 런을 망치는 함정이 아니라 위험한 기회를 줘야 한다.
5. 좋은 선택지는 항상 덱, 체력, 골드, 동료 성장 중 둘 이상을 동시에 흔들어야 한다.
```

---

## 3. 동료 시스템을 더 재미있게 만드는 기준

### 3.1 전술 표식

동료 공격 대상 규칙은 단순하지만, 플레이어가 조종하는 느낌이 있어야 한다.

따라서 단일 대상 공격 또는 지휘 카드가 지정한 적은 그 턴의 **전술 표식** 대상이 된다.

```txt
전술 표식 = combat_state.last_player_attack_target_id의 디자인 명칭.
광역 공격만 사용한 턴에는 전술 표식이 없다.
전술 표식 대상이 살아 있으면 동료는 그 대상을 공격한다.
전술 표식 대상이 없으면 체력이 가장 낮은 적을 공격한다.
```

UI 표시:

```txt
전술 표식 대상 적에게 작은 깃발/화살표 아이콘을 표시한다.
모바일에서도 읽히도록 텍스트보다 아이콘 우선.
```

재미 효과:

```txt
플레이어는 "어떤 카드를 먼저/마지막으로 쓰는가"를 고민한다.
동료 기본 공격이 자동이지만 방치되는 느낌이 줄어든다.
로완, 세라, 브람 같은 공격 동료의 정체성이 살아난다.
```

### 3.2 유대 단계

기존 `passive_level`은 디자인상 **유대 단계**로 부른다.

```txt
유대 0: 영입 직후 기본 패시브.
유대 1: 보스 후 기존 동료 강화, 엘리트 강화, 개인 이벤트 등으로 도달.
유대 2: 해당 동료 빌드를 밀었다는 강한 보상. 런당 1명만 유대 2에 도달해도 충분히 강해야 한다.
```

유대 단계가 올랐을 때 바뀌는 것:

```txt
패시브 수치 상승
일부 개인 이벤트 선택지 해금
동료 카드 강화 후보 가중치 증가
동료 장비 궁합 힌트 표시
```

MVP에서는 유대 단계가 패시브 수치만 바꿔도 된다. 정식 1차에서는 개인 이벤트와 연결한다.

### 3.3 Act 1 동료 예고

동료가 Act 1 보스 후에 정식 영입되면, 게임의 차별점이 너무 늦게 드러날 수 있다.

따라서 Act 1 중반에는 정식 영입 전이라도 동료 후보를 짧게 보여주는 **동료의 흔적** 계열 이벤트를 1회 이상 노출한다.

```txt
Act 1 depth 3~8 사이에 동료 예고 이벤트 1회 보장 권장.
이 이벤트는 동료를 영입하지 않는다.
동료 카드를 덱에 추가하지 않는다.
동료 슬롯을 차지하지 않는다.
대신 후보의 성격, 전투 스타일, 장비 궁합을 미리 보여준다.
Act 1 보스 후 3택에는 예고로 본 후보가 최소 1명 포함된다.
```

선택 보상 예시:

```txt
로완의 깃발을 발견한다: 다음 전투에서 첫 전술 표식 대상에게 추가 피해 3.
세라의 암호를 해독한다: 다음 전투 첫 공격 카드 피해 +3.
엘드릭의 방패 흔적을 따라간다: 다음 전투 시작 방어도 +5.
```

이 보상은 일회성 전투 보정이며, 유물/포션/카드 생성으로 취급하지 않는다.

---

## 4. 런 페이스와 전투 수치 목표

### 전체 플레이 시간 목표

```txt
MVP Act 1: 20~30분
정식 3막 전체: 75~100분
Act 1: 20~28분
Act 2: 25~35분
Act 3: 30~40분
```

### 전투 턴 수 목표

```txt
일반 전투: 3~5턴
엘리트 전투: 5~7턴
보스 전투: 8~11턴
```

전투가 이 범위를 자주 벗어나면 다음을 의심한다.

```txt
2턴 이하 일반 전투가 많다: 적 체력 부족, 보상 과다, 공격 카드 효율 과다.
6턴 이상 일반 전투가 많다: 적 체력 과다, 방어 카드 효율 과다, 덱 회전 느림.
엘리트가 보스보다 피곤하다: 엘리트 보상/위험 비율 재조정.
보스가 12턴 이상 간다: 보스 패턴이 반복 피로를 만든다.
```

### 전투력 예산

기본값은 에너지 4, 드로우 6이므로 일반적인 3에너지/5드로우 덱빌더보다 플레이어의 선택 폭이 넓다. 대신 적의 체력과 의도도 조금 더 적극적이어야 한다.

```txt
Act 1 초반 주인공 평균 카드 출력: 턴당 피해 12~22 또는 방어도 10~18.
Act 1 후반 주인공 평균 카드 출력: 턴당 피해 20~32 또는 방어도 14~24.
Act 2 동료 1명 보유 시 동료 기여: 전체 피해의 15~25%.
Act 3 동료 2명 보유 시 동료 기여: 전체 피해의 20~35%.
```

동료 기여가 낮으면 동료가 장식처럼 느껴진다. 동료 기여가 40%를 넘으면 플레이어 카드 선택보다 자동 공격이 중심이 된다.

### 적 수치 초안

```txt
Act 1 초반 일반 전투 적 총 HP: 38~70
Act 1 후반 일반 전투 적 총 HP: 60~95
Act 1 일반 적 공격 의도: 6~11
Act 1 엘리트 총 HP: 95~135
Act 1 보스 HP: 190~240

Act 2 일반 전투 총 HP: 100~160
Act 2 일반 적 공격 의도: 10~18
Act 2 엘리트 총 HP: 180~250
Act 2 보스 HP: 300~380

Act 3 일반 전투 총 HP: 170~260
Act 3 일반 적 공격 의도: 14~24
Act 3 엘리트 총 HP: 280~370
Act 3 보스 HP: 450~540
```

Slay the Spire의 Act 1 보스가 3에너지/5드로우 기준 140~250 HP임을 감안하면, 본 게임의 4에너지/6드로우 기준 Act 1 보스는 190~240 HP에서 출발한다. 단, 유물/포션이 없으므로 체력만 올리고 공격 의도까지 동시에 올리지는 않는다.

수치는 첫 플레이테스트 전 기준선이다. 실제 테스트에서는 평균 전투 턴 수, 플레이어 체력 손실, 보상 선택률을 보고 조정한다.

---

## 5. 카드 보상과 희귀도 기준

### 보상 3택 기본

```txt
일반 전투: 카드 3택 + 골드.
엘리트 전투: 카드 3택 + 골드 + 강화 3택.
보스 전투: Act 1/2는 동료 3택, Act 3은 엔딩.
```

### 희귀도 가중치

```txt
Act 1 카드 보상: common 62%, uncommon 35%, rare 3%
Act 2 카드 보상: common 55%, uncommon 37%, rare 8%
Act 3 카드 보상: common 48%, uncommon 40%, rare 12%
상점 카드: common 50%, uncommon 38%, rare 12%
```

희귀 카드 보정:

```txt
rare 확률은 런 시작 시 -3% 보정으로 시작한다.
카드 보상에서 common이 나올 때마다 rare 확률 +1%.
rare가 등장하면 기본 확률로 초기화.
보정 후 rare 확률은 최대 +10%까지만 적용한다.
MVP에서는 보정 없이 위 고정 확률로 시작해도 된다.
Act 1 보상 카드는 강화되어 나오지 않는다.
Act 2 보상 카드 강화 확률: 20%.
Act 3 보상 카드 강화 확률: 40%.
```

### 보상 스킵

카드를 무조건 추가하는 게임은 덱이 쉽게 흐려진다. 보상 스킵은 초반부터 필요하다.

```txt
Act 1 카드 보상 스킵: 골드 8
Act 2 카드 보상 스킵: 골드 10
Act 3 카드 보상 스킵: 골드 12
```

스킵 골드는 작아야 한다. 목적은 보상이 아니라 덱 품질 선택권이다.

### 동료 카드 보상

동료 카드 슬롯은 "빌드를 열어주는 보상"이므로 너무 자주 비어 있으면 안 된다.

```txt
동료 1명 이상 보유: 카드 보상 3장 중 1장은 동료 카드 후보.
동료가 2명일 때: 미획득 카드가 더 많은 동료를 약간 우선한다.
보유 동료 카드 후보가 없으면 주인공 카드로 대체하고 rare 확률 +5%.
동료 카드가 보상에 나왔지만 선택되지 않으면 이후 다시 등장 가능.
동료 카드는 획득 후 중복 등장하지 않는다.
```

---

## 6. 골드 경제 기준

골드는 생존과 덱 완성도를 동시에 압박해야 한다.

### 획득 기준

```txt
일반 전투 골드: 12~20
엘리트 전투 골드: 30~45
보스 전투 골드: 90~105
이벤트 골드 보상: 20~85
보물/특수보상 골드: 50~110
```

### 소비 기준

```txt
Act 1 상점 방문 전 기대 골드: 130~190
상점 1회에서 의미 있는 선택: 카드 1장 + 서비스 1개 또는 장비 1개.
여관 1회에서 의미 있는 선택: 싼 회복으로 버티기 또는 비싼 회복으로 안정화.
카드 제거는 항상 강하지만, 반복 구매 시 비용 상승으로 억제한다.
```

### 가격 기준

```txt
일반 카드: 45~60
비범 카드: 70~95
희귀 카드: 135~175
동료 카드: 85~140
일반 장비: 95~130
비범 장비: 150~220
희귀 장비: 240~330
카드 제거: 75, 구매할 때마다 +25
카드 강화: 90
동료 카드 강화: 120
```

Slay the Spire의 실제 상점 카드 가격은 일반 45~55, 비범 68~82, 희귀 135~165이다. 본 게임은 유물/포션 대신 장비가 상점의 장기 성장축이므로, 카드는 비슷하게 두고 장비 가격을 카드보다 약간 무겁게 둔다.

---

## 7. 맵 생성 기준

단순 비율만으로는 재미있는 경로가 보장되지 않는다. 각 Act는 아래의 체감 구조를 목표로 한다.

```txt
Act당 선택 노드 12개 + 보스 1개.
depth 1은 일반 전투 권장.
depth 1~3에는 상점/여관/보물만 연속으로 나오지 않게 한다.
depth 4~9 사이에 첫 엘리트 선택지를 배치한다.
보스 전 마지막 2 depth 안에는 최소 1개의 회복/상점/이벤트 안정화 경로를 둔다.
모든 주요 경로에는 최소 1회 이상의 덱 개선 기회가 있어야 한다.
```

Act별 체감 노드 목표:

```txt
일반 전투: 4~6개
이벤트: 2~3개
상점: 1개
여관: 1개
보물/특수보상: 0~1개
엘리트: 1~2개
```

Act 1은 동료를 아직 정식 보유하지 않으므로, 이벤트 중 하나는 동료 예고 이벤트가 되도록 가중한다.

---

## 8. 카드 수치 기준

### 피해 카드

```txt
0비용 공격: 피해 3~5
1비용 공격: 피해 7~9
2비용 공격: 피해 14~18
3비용 공격: 피해 24~32
광역 피해는 같은 비용 단일 피해의 60~75% 수준
드로우, 취약, 약화, 동료 피해 증가가 붙으면 피해를 10~30% 낮춘다.
```

### 방어/유틸 카드

```txt
0비용 방어: 방어도 3~5 또는 작은 보조 효과.
1비용 방어: 방어도 7~10.
2비용 방어: 방어도 15~20.
카드 1장 드로우는 약 0.5 에너지 가치로 본다.
에너지 1 획득은 조건부 또는 1회성으로 제한한다.
전투 중 회복은 강한 효과이므로 피해/방어보다 낮은 수치로 시작한다.
```

### 파워 카드

파워 카드는 보통 2~4턴 안에 비용을 회수해야 한다.

```txt
1비용 파워: 매 턴 작지만 확실한 이득.
2비용 파워: 특정 빌드를 열거나 중간 규모 누적 이득.
3비용 파워: 희귀하고 강한 빌드 중심축. 첫 사용 턴이 위험해야 한다.
```

### 동료 관련 카드

동료 카드는 주인공 카드보다 더 좁고 더 선명해야 한다.

```txt
동료 기본 공격 피해 +2는 1턴 한정이면 작은 보너스.
동료 기본 공격 피해 +4 이상은 조건부 또는 비용 1 이상 권장.
모든 동료 즉시 공격은 희귀 카드 또는 높은 비용 카드로 제한한다.
동료 카드가 주인공 일반 카드의 완전 상위호환이 되면 안 된다.
```

---

## 9. 이벤트 설계 기준

이벤트는 "나쁜 일이 랜덤으로 터지는 곳"이 아니라, 플레이어가 위험을 보고 선택하는 곳이다.

### 좋은 이벤트 선택지

```txt
체력 6을 잃고 카드 강화.
40골드를 내고 장비 획득.
다음 전투가 조금 위험해지지만 보상 상승.
보유 동료와 관련된 특별 보상 후보.
덱을 얇게 만들 기회.
```

### 피해야 할 이벤트 선택지

```txt
결과가 안 보이는 대형 손실.
덱 오염.
동료 상실.
장비 강제 삭제.
즉사 또는 체력 0 고정.
선택했는데 재미있는 변화 없이 숫자만 손해.
```

### 이벤트 보상 기대값

```txt
체력 5~8 손실: 카드 강화 또는 골드 45~70 상당.
체력 10~14 손실: 장비, 희귀 카드 후보, 주인공 강화급 보상.
골드 40~60 비용: 일반 장비/카드 강화/보상 확률 상승.
전투 발생 선택지: 일반 전투보다 보상이 확실히 좋아야 한다.
```

---

## 10. 난이도 단계 설계

기본 밸런스는 **표준** 난이도에 맞춘다. 쉬움/어려움은 같은 게임 규칙 위에서 일부 수치만 조정해야 하며, 에너지 4/드로우 6/동료 최대 2명 같은 핵심 규칙은 난이도별로 바꾸지 않는다.

### 10.1 초기 난이도 프리셋

```txt
여행자:
- 시작 최대 체력 84.
- Act 1 일반 전투 총 HP -10%.
- Act 1 적 공격 의도 -1.
- 보스 HP -8%.
- 일반 여관 가격 -10%.

표준:
- 본 문서의 기준 수치 그대로 사용.
- 첫 플레이테스트와 공개 데모의 기준 난이도.

숙련자:
- 시작 최대 체력 70.
- 일반/엘리트/보스 HP +8%.
- Act 2부터 적 공격 의도 +1.
- 이벤트/보물 골드 보상 -10%.
- 일반 여관 가격 +10%.
```

여행자는 학습용 안전망이다. 희귀 카드 확률을 올리거나 강한 장비를 더 자주 주면 게임 이해보다 운 좋은 보상에 의존하게 되므로 피한다.

숙련자는 체력, 전투 길이, 경제 압박을 조금씩 동시에 올린다. 단, Act 1 첫 3전투에서 갑자기 죽는 구조는 만들지 않는다.

### 10.2 클리어 후 단계형 난이도

첫 정식 버전에서는 Slay the Spire의 Ascension처럼 한 번에 하나씩 불리한 조건을 더하는 **원정 규율**을 고려한다.

```txt
규율 1: 보스 HP +5%.
규율 2: 엘리트 HP +8%.
규율 3: 일반 적 공격 의도 +1.
규율 4: 일반 여관 가격 +10%.
규율 5: 이벤트 비용 +10%, 이벤트 골드 보상 -10%.
규율 6: 시작 최대 체력 -6.
규율 7: 카드 보상 강화 확률 절반.
```

MVP에서는 원정 규율을 구현하지 않는다. 표준 난이도의 전투 턴 수와 골드 경제가 안정된 뒤 추가한다.

### 10.3 난이도 조정 우선순위

플레이테스트에서 난이도가 맞지 않을 때는 아래 순서로 조정한다.

```txt
일반 전투가 너무 쉽다: 일반 전투 총 HP +5~10%, 공격 의도는 유지.
일반 전투가 너무 아프다: 공격 의도 -1 또는 방어 턴 빈도 증가.
엘리트 선택률이 낮다: 엘리트 골드/강화 후보 품질 조정, HP 하향은 후순위.
보스 처치율이 낮다: 보스 HP -5~8% 또는 위험 패턴 빈도 감소.
골드가 남아돈다: 이벤트/보물 골드부터 낮추고, 일반 전투 골드는 마지막에 조정.
덱이 너무 빨리 완성된다: rare 확률보다 카드 강화 확률과 상점 서비스 가격을 먼저 조정.
```

난이도는 불투명한 벌칙보다 예측 가능한 압박이어야 한다. 플레이어가 무엇 때문에 졌는지 설명할 수 있으면 좋은 실패에 가깝다.

---

## 11. 플레이테스트 전 검증 지표

구현 후 첫 내부 테스트부터 아래 값을 기록한다.

```txt
전투별 턴 수
전투별 체력 손실
카드별 보상 등장 횟수
카드별 선택률
카드별 승리덱 포함률
동료별 선택률
동료별 승률
동료 카드 선택률
장비 구매율
여관 방 선택률
상점 서비스 구매율
이벤트 선택지 선택률
런 포기/사망 노드
```

초기 목표:

```txt
MVP 첫 10회 내부 런에서 Act 1 보스 도달률 45~65%.
Act 1 보스 처치율 25~45%.
카드 보상 스킵률 10~25%.
엘리트 선택 경로 진입률 25~45%.
여관 방문 시 방 구매율 60% 이상.
동료 3택에서 특정 동료 선택률이 60%를 넘으면 후보 밸런스 의심.
```

이 수치는 정답이 아니라 알람이다. 재미가 좋다면 수치는 조정될 수 있지만, 특정 카드/동료/노드가 계속 버려지면 그 선택지는 사실상 존재하지 않는 것이다.

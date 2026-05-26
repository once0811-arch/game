# Godot 바이브코딩 개발 페이즈 계획

작성일: 2026-05-26
목적: 자연어 지시만으로 Codex가 Godot 4.x 기반 게임을 끝까지 구현하기 위한 단계별 실행 계획.
원칙: 모든 구현은 `docs/godot_deckbuilder_spec/`의 기획 문서를 기준으로 하며, 임시 아트는 `agent-sprite-forge`를 사용해 2D 픽셀아트로 먼저 확보한다.

---

## 0. 전체 개발 원칙

이 프로젝트는 주인공 덱, 동료 2명, 서약 전술, 유대 점수, 장비, 여관/상점/이벤트가 맞물리는 2D 로그라이크 덱빌딩 게임이다.

개발은 아래 원칙을 지킨다.

```txt
1. 매 페이즈는 실행 가능한 Godot 프로젝트 상태로 끝난다.
2. UI와 게임 규칙을 분리한다.
3. 카드, 동료, 장비, 이벤트, 적 데이터는 JSON 중심으로 관리한다.
4. 임시 아트라도 Godot에서 바로 읽을 수 있는 경로, 크기, 메타데이터를 갖춘다.
5. 아트디렉터가 나중에 교체할 수 있도록 파일명과 역할을 명확히 둔다.
6. agent-sprite-forge 자체는 외부 스킬 폴더로 취급하고, 결과물만 프로젝트에 넣는다.
7. 생성 프롬프트와 후처리 메타데이터를 에셋 옆에 남긴다.
8. 큰 시스템은 작게 만들고 검증한 뒤 다음 시스템으로 넘어간다.
```

작업 대상 Godot 프로젝트:

```txt
SourceCode/
```

임시 에셋 출력 기준:

```txt
SourceCode/assets/temp_pixel/
  actors/
  companions/
  enemies/
  bosses/
  backgrounds/
  ui/
  cards/
  equipment/
  props/
  fx/
  manifests/
```

## 0.1 Godot 직접 확인 원칙

사용자는 매 페이즈가 끝날 때 Godot 에디터를 직접 열어 결과를 확인할 수 있어야 한다.

현재 `SourceCode/project.godot`에는 프로젝트명만 설정되어 있고, 실행 메인 씬은 아직 없다. 따라서 Phase 0에서는 에셋 갤러리 씬을 만들고, Phase 1에서는 메인 씬을 `project.godot`의 실행 씬으로 등록한다.

확인 방식은 아래처럼 고정한다.

```txt
Phase 0: Godot에서 scenes/debug/asset_gallery.tscn을 열어 생성 에셋 확인
Phase 1: Godot 실행 버튼으로 main.tscn 실행, 새 런 버튼 확인
Phase 2: deck_debug 또는 main 화면에서 드로우/버림/셔플 로그 확인
Phase 3: combat_screen에서 기본 전투 1회 직접 플레이
Phase 4: map_screen에서 Act 1 depth 6 중간 보스까지 진행 확인
Phase 5: 동료 영입/서약 전술/동료 카드 선택 화면 확인
Phase 6: 동료 기본 공격, 서약 발동, 유대 점수 상승 확인
Phase 7: 상점/여관/이벤트/장비 화면 확인
Phase 8: Act 1~3 진행, 저장/로드, 엔딩 확인
Phase 9: 플레이테스트 로그 JSON 생성 확인
Phase 10: 임시 에셋 교체 가이드와 asset id 기반 로딩 확인
```

각 페이즈 완료 보고에는 반드시 아래 정보를 포함한다.

```txt
1. Godot에서 열어볼 씬 경로
2. 사용자가 눌러볼 버튼/흐름
3. 정상 동작 기준
4. 아직 임시 처리인 부분
5. 다음 페이즈에서 이어질 지점
```

가능하면 CLI 검증도 병행한다. 단, 사용자의 로컬에 Godot 실행 파일 경로가 없을 수 있으므로, CLI 검증은 보조 수단이고 최종 기준은 Godot 에디터에서 직접 열어보는 것이다.

---

## Phase 0. 임시 픽셀 에셋 생성

목표: 실제 구현을 시작하기 전에 MVP와 Act 1 플레이에 필요한 임시 2D 픽셀아트 에셋을 모두 준비한다.

사용 도구:

```txt
agent-sprite-forge/skills/generate2dsprite
agent-sprite-forge/skills/generate2dmap
Godot 4.x import pipeline
```

아트 방향:

```txt
스타일: 2D pixel art + 가벼운 2D 복셀풍, readable tactical fantasy, muted apocalypse palette
시점: 전투는 side/3-4 hybrid보다 3/4 실루엣을 조금 더 강하게 사용, 맵/노드는 UI icon 중심
배경: 16:9 가로 화면용, 카드 UI가 올라가도 방해하지 않는 낮은 대비
캐릭터: 작은 크기에서도 실루엣 구분
색감: Act 1은 차가운 청회색 + 모닥불색, 위험 표시는 마른 피 색
후반용 예비 팔레트: 어두운 보라 + 진녹색
현재 임시 패스: temp_pixel_voxel_v2
```

### 0.1 에셋 생성 규칙

```txt
raw 생성 이미지는 agent-sprite-forge 원칙에 따라 solid #FF00FF 배경을 사용한다.
후처리 결과는 투명 PNG로 저장한다.
임시 아트라도 단순 도형 프록시처럼 보이면 안 되며, 검은 외곽선, 상단 좌측 조명, 림라이트, 바닥 그림자로 게임 화면에서 견딜 수 있는 품질을 맞춘다.
애니메이션은 처음부터 복잡하게 만들지 않는다.
전투용 캐릭터는 idle 4프레임, attack 4프레임, hurt 1~2프레임을 기본으로 한다.
동료와 적의 실제 전투 연출은 첫 구현에서 짧은 이동/깜빡임/VFX로 보강한다.
카드 일러스트는 초기에 개별 120장을 만들지 않고, 타입/소유자/동료별 모티프 카드 아트로 시작한다.
```

### 0.2 Phase 0 산출물

#### 주인공

| ID | 출력 | 용도 |
|---|---|---|
| `protagonist_mercenary_idle` | 4프레임 idle sheet | 전투 좌측 스탠딩 |
| `protagonist_mercenary_attack` | 4프레임 attack sheet | 기본 공격/단일 공격 |
| `protagonist_mercenary_guard` | 4프레임 guard sheet | 방어 카드 |
| `protagonist_portrait` | 1장 | UI, 대화, 보상 화면 |

#### MVP 동료 3명

| 동료 | 출력 | 핵심 실루엣 |
|---|---|---|
| 로완 | idle, attack, portrait, oath icon 3개 | 붉은 천, 긴 창, 표식 추격 |
| 세라 | idle, attack, portrait, oath icon 3개 | 짧은 쌍검, 검은 가죽, 빠른 잔상 |
| 엘드릭 | idle, guard/attack, portrait, oath icon 3개 | 낡은 방패, 중갑, 긁힌 증표 |

#### 정식 동료 예비 초상 7명

정식 구현 전까지 보상 후보와 UI 테스트에 쓰는 저비용 초상이다.

```txt
브람 portrait
마렌 portrait
토르 portrait
리나 portrait
노아 portrait
이솔 portrait
카일 portrait
```

카일 초상은 골드 고정 보상 상인이 아니라 판돈 장부를 들고 있는 도박형 거래꾼으로 만든다.

#### Act 1 일반 적 6종

| ID | 방향 |
|---|---|
| `enemy_act1_mutated_merchant` | 변이 상단원 |
| `enemy_act1_mutated_scholar` | 변이 왕립 학자 |
| `enemy_act1_mutated_mercenary` | 변이 용병 |
| `enemy_act1_twisted_wolf` | 뒤틀린 늑대 |
| `enemy_act1_broken_packhorse` | 뒤틀린 말/짐승 |
| `enemy_act1_rooted_scavenger` | 식물과 인간 흔적이 섞인 변이체 |

각 적은 idle 4프레임과 hurt 1프레임을 기본으로 한다.

#### Act 1 엘리트 3종, 중간 보스, 보스

| ID | 방향 |
|---|---|
| `elite_act1_blackprint_captain` | 검은 지문 용병대장 |
| `elite_act1_armored_caravan_guard` | 장비와 융합한 상단 경호원 |
| `elite_act1_excavation_scholar` | 발굴 도구를 든 변이 학자 |
| `midboss_act1_blackened_guard` | 첫 동료 계약 전 관문 |
| `boss_act1_blackprint_warlord` | 첫 동료 시너지 검증 보스 |

중간 보스는 Act 보스보다 작고, 보스는 화면 오른쪽을 강하게 점유하는 큰 실루엣으로 만든다.

#### 전투 배경과 장소 배경

| ID | 용도 |
|---|---|
| `bg_battle_act1_road_ruin` | Act 1 일반 전투 배경 |
| `bg_battle_act1_outpost` | Act 1 엘리트/중간 보스 배경 |
| `bg_battle_act1_boss_gate` | Act 1 보스 배경 |
| `bg_map_act1_route` | Act 1 맵 화면 |
| `bg_shop_act1_rusty_trader` | 상점 화면 |
| `bg_inn_act1_warm_common` | 일반 여관 |
| `bg_inn_act1_suspicious` | 이벤트 여관 |
| `bg_event_act1_generic` | 이벤트/보물 공통 배경 |

배경은 `generate2dmap`의 `baked_scene_mode` 또는 `scene_mode`로 만들되, 전투용 배경은 카드와 UI가 올라갈 하단 영역을 비워둔다.

#### UI 아이콘

필수 아이콘은 작은 픽셀 아이콘으로 먼저 만든다.

```txt
energy
health
gold
block
draw_pile
discard_pile
exhaust_pile
tactical_mark
vulnerable
weak
poison
heal
healing_down
helmet_slot
armor_slot
weapon_slot
bond_30
bond_60
bond_100
```

노드 아이콘:

```txt
combat
elite
mid_boss
boss
shop
inn
event
treasure
companion_trace
companion_contract
upgrade
```

#### 카드와 장비 임시 아트

초기 카드 아트는 아래처럼 묶어 만든다.

```txt
card_frame_protagonist_attack_common
card_frame_protagonist_skill_common
card_frame_protagonist_power_common
card_frame_companion_attack_common
card_frame_companion_skill_common
card_frame_companion_power_common
card_motif_attack_sword
card_motif_skill_guard
card_motif_power_oath
card_motif_rowan_spear
card_motif_sera_dagger
card_motif_eldric_shield
```

장비 아이콘은 MVP 기준 24개를 모두 개별 생성하거나, 최소한 아래 슬롯별 8개씩 만든다.

```txt
helmet icons 8
armor icons 8
weapon icons 8
```

#### VFX

```txt
fx_slash_small
fx_pierce_red
fx_guard_flash
fx_tactical_mark_pin
fx_oath_token_glint
fx_heal_low
fx_healing_down_black_crack
fx_poison_puff
fx_gold_spark
fx_card_draw_wisp
```

### 0.3 Phase 0 Godot 연결 작업

에셋 생성 후 바로 Godot에서 사용할 수 있도록 아래 파일을 만든다.

```txt
SourceCode/data/assets/temp_asset_manifest.json
SourceCode/scripts/resources/asset_registry.gd
SourceCode/scenes/debug/asset_gallery.tscn
SourceCode/scripts/debug/asset_gallery.gd
```

`temp_asset_manifest.json` 예시:

```json
{
  "version": "0.1.0",
  "style": "temp_pixel",
  "assets": [
    {
      "id": "protagonist_mercenary_idle",
      "path": "res://assets/temp_pixel/actors/protagonist_mercenary_idle.png",
      "type": "sprite_sheet",
      "frame_size": [96, 96],
      "frames": 4,
      "anchor": "bottom"
    }
  ]
}
```

Phase 0 완료 기준:

```txt
1. 모든 MVP 필수 임시 에셋이 SourceCode/assets/temp_pixel/ 아래에 존재한다.
2. 각 생성 에셋 옆에 prompt.txt 또는 manifest metadata가 존재한다.
3. Godot에서 asset_gallery.tscn을 열면 주요 에셋을 한 화면에서 확인할 수 있다.
4. 에셋 파일명과 manifest id가 데이터 문서의 ID 규칙과 충돌하지 않는다.
5. agent-sprite-forge 폴더 자체는 프로젝트 커밋 대상에 포함하지 않는다.
```

Godot 확인 절차:

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. scenes/debug/asset_gallery.tscn을 연다.
3. Actors / Companions / Enemies / Bosses / Backgrounds / UI / Cards / Equipment / FX 탭을 확인한다.
4. 누락된 에셋은 회색 placeholder가 아니라 명확한 missing 상태로 표시되어야 한다.
5. 각 에셋은 manifest id와 실제 PNG 경로가 함께 보인다.
```

---

## Phase 1. Godot 프로젝트 뼈대

목표: 실행 가능한 빈 Godot 프로젝트를 게임 구조에 맞게 정리한다.

산출물:

```txt
autoloads/
  data_registry.gd
  rng_service.gd
  save_service.gd
  scene_router.gd
scripts/state/
  run_state.gd
  deck_state.gd
  combat_state.gd
  party_state.gd
data/balance_constants.json
scenes/main/main.tscn
scenes/map/map_screen.tscn
```

완료 기준:

```txt
프로젝트 실행 가능
새 런 시작 버튼 표시
빈 맵 화면으로 이동 가능
DataRegistry가 JSON을 로드할 수 있음
project.godot에 main.tscn이 실행 메인 씬으로 등록됨
```

Godot 확인 절차:

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. 실행 버튼을 누른다.
3. main.tscn이 실행되고 새 런 시작 버튼이 보인다.
4. 버튼을 누르면 빈 map_screen으로 이동한다.
5. 오류 출력이 없어야 한다.
```

---

## Phase 2. 카드와 덱 로직

목표: 전투 없이 카드 데이터, 덱, 손패, 버림/셔플을 구현한다.

산출물:

```txt
data/cards/protagonist_cards.json
scripts/data/card_data.gd
scripts/state/card_instance.gd
scripts/state/deck_state.gd
scripts/systems/card_reward_generator.gd
```

완료 기준:

```txt
시작 덱 10장 생성
매턴 6장 드로우
카드 사용 후 버림
draw_pile 부족 시 discard_pile 셔플
카드 보상 3택과 스킵 골드 동작
```

Godot 확인 절차:

```txt
1. debug deck 화면 또는 main의 테스트 버튼으로 덱 테스트를 실행한다.
2. 시작 덱 10장이 표시된다.
3. 드로우 버튼을 누르면 6장이 손패로 이동한다.
4. 카드 사용/턴 종료/셔플 로그가 화면에 표시된다.
```

---

## Phase 3. 최소 전투

목표: 주인공과 적 1마리의 전투를 만든다.

산출물:

```txt
scripts/combat/turn_manager.gd
scripts/combat/card_effect_resolver.gd
scripts/combat/enemy_ai_resolver.gd
scenes/combat/combat_screen.tscn
scenes/combat/card_view.tscn
scenes/combat/enemy_view.tscn
data/enemies/enemies_act1.json
```

완료 기준:

```txt
기본 공격/방어/전술 정비 사용 가능
에너지 4, 드로우 6 적용
전술 표식 갱신
적 의도 표시
승리/패배 판정
Phase 0 임시 에셋 표시
```

Godot 확인 절차:

```txt
1. combat_screen 테스트 전투를 실행한다.
2. 기본 공격으로 적을 클릭하면 전술 표식이 붙는다.
3. 턴 종료 시 적 의도와 피해/방어 처리가 보인다.
4. 전투 승리 후 카드 보상 화면으로 넘어간다.
```

---

## Phase 4. 맵, 보상, Act 1 중간 보스

목표: Act 1 맵 흐름과 중간 보스/계약 노드를 구현한다.

산출물:

```txt
scripts/map/map_generator.gd
scripts/map/map_state.gd
scripts/rewards/reward_state.gd
scenes/reward/card_reward_screen.tscn
data/encounters/act1_encounters.json
```

완료 기준:

```txt
Act 1 12노드 생성
depth 6 중간 보스 고정
전투 승리 후 카드 보상
보상 후 다음 노드 이동
```

Godot 확인 절차:

```txt
1. map_screen에서 Act 1 맵을 본다.
2. depth 6에 중간 보스/계약 노드가 고정 표시되는지 확인한다.
3. 일반 전투 승리 후 카드 보상과 다음 노드 이동을 확인한다.
```

---

## Phase 5. 동료 영입과 두 번째 동료

목표: Act 1 중간 보스 후 첫 동료, Act 1 보스 후 두 번째 동료를 구현한다.

산출물:

```txt
data/companions/companions.json
data/cards/companion_cards.json
scripts/systems/companion_manager.gd
scripts/rewards/companion_reward_generator.gd
scenes/companion/companion_reward_screen.tscn
scenes/companion/oath_tactic_select_screen.tscn
scenes/companion/companion_card_select_screen.tscn
```

완료 기준:

```txt
동료 3택 표시
서약 전술 3개 중 1개 선택
동료 카드 3장 중 2장 선택
동료 카드 중복 획득 방지
동료 패널 표시
```

Godot 확인 절차:

```txt
1. Act 1 중간 보스를 처치한다.
2. 첫 동료 3택, 서약 전술 3택, 동료 카드 2장 선택을 확인한다.
3. Act 1 보스를 처치한다.
4. 두 번째 동료도 같은 흐름으로 영입되는지 확인한다.
```

---

## Phase 6. 동료 전투, 서약 전술, 유대 점수

목표: 동료가 실제 전투 리듬을 바꾸게 한다.

산출물:

```txt
scripts/combat/companion_combat_system.gd
scripts/combat/oath_tactic_resolver.gd
scripts/systems/bond_system.gd
```

완료 기준:

```txt
턴 종료 후 동료 기본 공격
전술 표식 대상 우선 공격
로완/세라/엘드릭 서약 전술 발동
전투/엘리트/보스 승리 후 유대 점수 증가
30/60/100 보너스 적용
```

---

## Phase 7. 장비, 상점, 여관, 이벤트

목표: 전투 외 선택이 런의 방향을 바꾸게 한다.

산출물:

```txt
data/equipment/equipment.json
data/events/events_act1.json
scripts/systems/equipment_inventory.gd
scripts/systems/shop_generator.gd
scripts/systems/inn_room_generator.gd
scripts/systems/event_resolver.gd
scenes/shop/shop_screen.tscn
scenes/inn/inn_screen.tscn
scenes/event/event_screen.tscn
```

완료 기준:

```txt
상점 상품 표시와 구매
카드 제거/강화/변화/복제
장비 구매와 장착
일반 여관과 이벤트 여관
동료 흔적 이벤트
치유 감소 상태 효과
```

---

## Phase 8. Act 2/3, 강화, 세이브

목표: 3막 전체 흐름과 저장/로드를 구현한다.

산출물:

```txt
data/enemies/enemies_act2.json
data/enemies/enemies_act3.json
data/bosses/bosses.json
scripts/systems/protagonist_upgrade_service.gd
scripts/systems/save_service.gd
scenes/upgrade/upgrade_select_screen.tscn
```

완료 기준:

```txt
Act 2 depth 6 강화 노드
Act 2 보스 후 주인공/동료 대강화
Act 3 보스와 엔딩
런 저장/로드
```

---

## Phase 9. 플레이테스트 지표와 밸런스 루프

목표: 감이 아니라 지표로 밸런스를 조정한다.

산출물:

```txt
scripts/telemetry/run_telemetry.gd
data/playtest_logs/
docs/playtest_balance_notes.md
```

기록 지표:

```txt
전투별 턴 수
전투별 체력 손실
카드 선택률/스킵률
동료 선택률
서약 전술 발동 횟수
유대 점수 평균
중간 보스 도달/처치율
Act 1 보스 도달/처치율
카일 판돈 보상 결과
치유 감소 적용 횟수
여관/상점 선택률
```

완료 기준:

```txt
테스트 런 후 JSON 로그 생성
밸런스 조정 전후 수치 비교 가능
```

---

## Phase 10. 데모 폴리시와 교체 가능한 아트 파이프라인

목표: 임시 픽셀 에셋으로 플레이 가능한 데모를 만들고, 아트디렉터 작업물로 쉽게 교체할 수 있게 한다.

산출물:

```txt
docs/asset_replacement_guide.md
SourceCode/assets/temp_pixel/README.md
SourceCode/data/assets/asset_manifest.json
```

완료 기준:

```txt
임시 에셋과 정식 에셋 교체 규칙 문서화
Godot 씬이 직접 파일 경로에 과하게 묶이지 않음
asset id 기반 로딩 가능
```

---

## 우선 실행 순서

즉시 실행할 작업은 아래 순서다.

```txt
1. Phase 0 에셋 폴더 구조 생성.
2. Phase 0 asset_manifest 초안 작성.
3. 주인공, MVP 동료 3명, Act 1 적/보스, UI 아이콘, 배경 순서로 픽셀 에셋 생성.
4. 생성 프롬프트와 후처리 결과를 에셋 옆에 저장.
5. Godot asset_gallery로 모든 임시 에셋을 확인.
6. Phase 1 프로젝트 뼈대 구현 시작.
```

Codex는 이후 작업에서 이 문서를 체크리스트처럼 사용한다.

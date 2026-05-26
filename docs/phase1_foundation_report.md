# Phase 1 Godot 프로젝트 뼈대 보고

작성일: 2026-05-26

## 결과 요약

Phase 1의 목표였던 실행 가능한 Godot 앱 골격을 만들었다.

```txt
실행 메인 씬: res://scenes/main/main.tscn
빈 맵 화면: res://scenes/map/map_screen.tscn
에셋 갤러리: res://scenes/debug/asset_gallery.tscn
밸런스 상수: res://data/balance_constants.json
```

프로젝트 실행 버튼을 누르면 메인 메뉴가 뜨고, `New Run`을 누르면 빈 Act 1 맵 화면으로 이동한다. `Asset Gallery`는 메인 메뉴와 맵 화면에서 접근할 수 있고, 갤러리에도 메인 메뉴 복귀 버튼을 추가했다.

## 구현 범위

| 영역 | 파일 | 내용 |
|---|---|---|
| 데이터 로딩 | `autoloads/data_registry.gd` | 밸런스 JSON과 임시 에셋 manifest 로드 |
| 난수 | `autoloads/rng_service.gd` | 런 seed와 기본 랜덤 서비스 |
| 저장 | `autoloads/save_service.gd` | Phase 1용 run snapshot 저장/읽기 |
| 씬 전환 | `autoloads/scene_router.gd` | 메인, 맵, 에셋 갤러리 이동 |
| 런 상태 | `scripts/state/run_state.gd` | 새 런 시작, snapshot 복원 |
| 상태 객체 | `deck_state.gd`, `combat_state.gd`, `party_state.gd` | Phase 2 이후 시스템이 사용할 기본 상태 컨테이너 |
| UI | `scripts/ui/main_menu.gd`, `scripts/ui/map_screen.gd` | 실행 첫 화면과 빈 맵 화면 |

## Godot 확인 절차

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. 실행 버튼을 누른다.
3. 메인 메뉴에서 New Run을 누른다.
4. Act 1 Route 화면으로 이동하는지 확인한다.
5. Save Snapshot을 누른 뒤 Main Menu로 돌아간다.
6. Continue가 활성화되고 다시 맵 화면으로 돌아가는지 확인한다.
7. Asset Gallery 버튼으로 Phase 0 에셋 갤러리에 들어갔다가 Main Menu로 복귀한다.
```

## 검증

```txt
Godot 4.6.3 headless project load 통과
Godot 4.6.3 headless main scene run 통과
balance_constants.json / temp_asset_manifest.json JSON 검증 통과
project.godot main_scene / autoload / scene resource 경로 검증 통과
git diff --check 통과
```

## 페이즈 반성

잘 된 점:

```txt
1. 이제 프로젝트가 에셋 갤러리에서 실제 앱 진입점으로 넘어갔다.
2. 메인 메뉴, 새 런, 맵 화면, 저장 snapshot, 에셋 갤러리 이동이 하나의 흐름으로 묶였다.
3. DataRegistry와 RunState가 생겨 Phase 2의 카드/덱 로직이 붙을 자리가 생겼다.
4. Godot headless 검증을 통해 autoload 컴파일 문제를 실제로 잡고 수정했다.
```

부족했던 점:

```txt
1. 아직 플레이어가 재미를 느낄 핵심 선택지는 없다.
2. 맵 노드는 현재 시각적 자리만 있고 실제 진행/보상/위험 선택이 없다.
3. 메인 화면에 임시 제목과 개발자용 Phase 문구가 노출되어 게임 톤을 해쳤다.
```

반영한 개선:

```txt
1. Continue가 보이는 순간 실제 snapshot 복원이 되도록 RunState.load_snapshot을 추가했다.
2. 메인 화면에서 임의의 최종 게임명처럼 보이는 문구를 제거하고, 프로토타입 표기로 낮췄다.
3. 화면 안의 Phase 설명 문구를 줄이고 세계관 톤의 짧은 문장으로 바꿨다.
```

## 다음 단계

Phase 2에서는 카드와 덱 로직을 붙인다. 이 단계의 재미 기준은 `4에너지/6드로우`가 단순히 카드를 많이 쓰는 구조가 아니라, 손패 안에서 고비용 카드와 상황 대응 카드 중 무엇을 고를지 판단하게 만드는 것이다.

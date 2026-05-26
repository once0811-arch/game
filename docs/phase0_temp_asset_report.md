# Phase 0 임시 픽셀 에셋 생성 보고

작성일: 2026-05-26

## 결과 요약

Phase 0 임시 픽셀 에셋 생성을 완료했다.

```txt
생성 에셋 수: 135개
에셋 루트: SourceCode/assets/temp_pixel/
manifest: SourceCode/data/assets/temp_asset_manifest.json
Godot 확인 씬: SourceCode/scenes/debug/asset_gallery.tscn
현재 실행 메인 씬: res://scenes/debug/asset_gallery.tscn
```

`agent-sprite-forge`는 프로젝트에 커밋하지 않는 외부 스킬 폴더로 유지한다. 생성된 애니메이션 시트는 `agent-sprite-forge/skills/generate2dsprite/scripts/generate2dsprite.py process`를 통해 magenta cleanup, 프레임 분리, 투명 sheet, GIF preview, pipeline metadata를 생성했다.

## 생성 범위

| 카테고리 | 개수 | 내용 |
|---|---:|---|
| actors | 4 | 주인공 idle/attack/guard/portrait |
| companions | 16 | MVP 동료 3명 시트/초상 + 예비 동료 7명 초상 |
| ui/oaths | 9 | MVP 동료 3명 x 서약 전술 아이콘 3개 |
| enemies | 12 | Act 1 일반 적 6종 idle/hurt |
| bosses | 10 | Act 1 엘리트 3종, 중간 보스, 보스 idle/hurt |
| backgrounds | 8 | 전투/맵/상점/여관/이벤트 배경 |
| ui | 30 | 상태, 자원, 장비 슬롯, 맵 노드 아이콘 |
| cards | 12 | 카드 프레임과 카드 모티프 |
| equipment | 24 | 투구/갑옷/무기 아이콘 각 8개 |
| fx | 10 | 공격, 방어, 회복, 독, 골드, 드로우 VFX |

## Godot에서 확인하는 법

```txt
1. Godot에서 SourceCode/project.godot을 연다.
2. 실행 버튼을 누른다.
3. Phase 0 Temp Pixel Asset Gallery가 뜨는지 확인한다.
4. 탭별로 actors, companions, enemies, bosses, backgrounds, ui, cards, equipment, fx를 확인한다.
5. 누락 에셋은 붉게 표시되므로 manifest 경로를 점검한다.
```

직접 씬을 열고 싶다면 아래 파일을 연다.

```txt
SourceCode/scenes/debug/asset_gallery.tscn
```

## 교체 원칙

이번 에셋은 전부 임시 픽셀아트다. 정식 아트가 들어오면 아래 중 하나로 교체한다.

```txt
1. 같은 manifest id와 같은 역할의 파일을 덮어쓴다.
2. 파일명이 바뀌면 SourceCode/data/assets/temp_asset_manifest.json의 path만 수정한다.
3. 코드와 씬은 가능한 한 asset id를 통해 에셋을 참조한다.
```

## 다음 단계

Phase 1에서는 실제 게임 실행용 `main.tscn`을 만들고, `project.godot`의 `run/main_scene`을 `asset_gallery.tscn`에서 `main.tscn`으로 교체한다.

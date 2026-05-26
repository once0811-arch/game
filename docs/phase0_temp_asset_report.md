# Phase 0 임시 픽셀 에셋 생성 보고

작성일: 2026-05-26

## 결과 요약

Phase 0 임시 픽셀 에셋 생성을 완료했고, 1차 프록시 에셋의 시각 품질이 너무 낮아 `temp_pixel_voxel_v2` 아트 패스를 추가로 적용했다. 이후 카드/핵심 UI는 Kenney CC0 팩을 실제 파이프라인에 연결해 `temp_pixel_voxel_v2_kenney_cc0`로 갱신했다.

```txt
생성 에셋 수: 135개
에셋 루트: SourceCode/assets/temp_pixel/
manifest: SourceCode/data/assets/temp_asset_manifest.json
Godot 확인 씬: SourceCode/scenes/main/main.tscn, SourceCode/scenes/map/map_screen.tscn, SourceCode/scenes/combat/combat_screen.tscn
현재 실행 메인 씬: res://scenes/main/main.tscn
현재 스타일: temp_pixel_voxel_v2_kenney_cc0
```

`agent-sprite-forge`는 프로젝트에 커밋하지 않는 외부 스킬 폴더로 유지한다. 생성된 애니메이션 시트는 `agent-sprite-forge/skills/generate2dsprite/scripts/generate2dsprite.py process`를 통해 magenta cleanup, 프레임 분리, 투명 sheet, GIF preview, pipeline metadata를 생성했다.

v2 패스는 아래 기준을 적용했다.

```txt
1. 도형 프록시처럼 보이던 캐릭터를 2D 픽셀/가벼운 복셀풍 3/4 실루엣으로 교체
2. 작은 해상도에서 먼저 그리고 NEAREST 업스케일해 도트 질감 유지
3. 검은 외곽선, 상단 좌측 조명, 림라이트, 바닥 그림자 적용
4. Act 1의 차가운 청회색 + 모닥불색, 재난/후반 암시용 보라 + 진녹색 유지
5. 장비 아이콘은 원형 UI 배지가 아니라 실제 물건 실루엣으로 분리
6. 배경은 단순 테스트 패턴이 아니라 로드무비형 폐허/상점/여관/성문 장소감이 보이도록 재작성
```

Kenney 갱신 패스는 아래 기준을 적용했다.

```txt
1. Kenney Playing Cards Pack(CC0)에서 카드 프레임/카드 모티프를 복사 및 리사이즈
2. Kenney UI Pack(CC0)에서 핵심 자원 아이콘과 맵 노드 아이콘을 복사 및 리사이즈
3. 원본 PNG의 투명 여백을 크롭한 뒤 NEAREST로 확대해 픽셀 선명도 유지
4. SourceCode/data/assets/asset_manifest.json과 temp_asset_manifest.json 모두 외부 출처/라이선스 메타데이터 기록
5. SourceCode/assets/temp_pixel/vendor_licenses/에 Kenney 라이선스 노트 보관
```

프리뷰:

```txt
docs/art/phase0_temp_pixel_v2_preview.png
```

재생성 스크립트:

```txt
tools/phase0_upgrade_pixel_assets.py
```

## 생성 범위

| 카테고리 | 개수 | 내용 |
|---|---:|---|
| actors | 4 | 주인공 idle/attack/guard/portrait |
| companions | 16 | 초기 검증 동료 3명 시트/초상 + 예비 동료 7명 초상 |
| ui/oaths | 9 | 초기 검증 동료 3명 x 서약 전술 아이콘 3개 |
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
3. 메인 메뉴에서 새 런을 시작한다.
4. Route 화면에서 노드 아이콘과 버튼 가독성을 확인한다.
5. 전투 화면에서 Kenney 카드 프레임, 카드 모티프, 클릭/드래그 타겟팅을 확인한다.
6. 누락 에셋은 manifest 경로와 SourceCode/assets/temp_pixel/ 하위 파일을 점검한다.
```

## 교체 원칙

이번 에셋은 전부 임시 픽셀아트다. v2 패스는 개발 중 보기 좋은 수준까지 끌어올리기 위한 것이며, 정식 아트가 들어오면 아래 중 하나로 교체한다.

```txt
1. 같은 manifest id와 같은 역할의 파일을 덮어쓴다.
2. 파일명이 바뀌면 SourceCode/data/assets/temp_asset_manifest.json의 path만 수정한다.
3. 코드와 씬은 가능한 한 asset id를 통해 에셋을 참조한다.
```

## 다음 단계

Phase 1에서는 실제 게임 실행용 `main.tscn`을 만들고, `project.godot`의 `run/main_scene`을 `asset_gallery.tscn`에서 `main.tscn`으로 교체한다.

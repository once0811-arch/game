# Balance Run Simulation Report

이 리포트는 `tools/balance_run_simulator.py`가 현재 JSON 데이터와 핵심 GDScript 전투 규칙을 근사해 반복 실행한 결과다.
인간 플레이테스트를 대체하지 않고, 카드/적/성장 수치의 위험 구간을 찾기 위한 자동 러너다.

## Assumptions

- 카드 효과, 업그레이드 보정, 동료 기본 공격, 유대 30/60/100 보너스, 장비 보너스, 상점/여관/이벤트를 반영했다.
- 보상 선택은 합리적 자동 정책으로 처리한다. 실제 플레이어의 실수, 선호, 장기 빌드 해석은 반영하지 않는다.
- 현재 구현처럼 카드 업그레이드는 `first unupgraded` 방식으로 처리한다. 이는 플레이어 선택형 업그레이드보다 약하고 거칠다.
- 현재 구현처럼 일반 카드 보상은 주로 주인공 카드에서 나온다. 동료 카드는 영입/상점 중심으로 들어간다.

## Summary

| Policy | Enemy profile | Runs | A1 Boss | A2 Boss | A3 Reach | Win | Inn in/out | Boss HP A1/A2/A3 | Waves 1/2/3 | Avg deck | Avg HP | Avg gold | Avg bond | Picked | Skipped | Upgraded | Removed | Gear | Oath triggers |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| novice | current | 300 | 75.3% | 25.3% | 25.0% | 7.0% | 51/76% | 50/52/55% | 3414/554/122 | 23.9 | 2.1 | 169.3 | 39.1 | 10.0 | 1.7 | 1.3 | 1.4 | 0.5 | 35.5 |
| balanced | current | 300 | 99.7% | 89.7% | 89.7% | 54.0% | 35/71% | 82/70/57% | 6390/931/412 | 24.7 | 13.7 | 267.2 | 90.8 | 8.0 | 14.9 | 1.7 | 2.7 | 0.2 | 115.2 |
| safe | current | 300 | 100.0% | 98.7% | 98.7% | 84.3% | 51/91% | 74/89/88% | 4526/945/429 | 19.3 | 31.6 | 559.3 | 95.8 | 5.3 | 11.3 | 2.6 | 0.0 | 2.5 | 85.8 |
| greedy | current | 300 | 97.0% | 65.0% | 64.7% | 32.0% | 23/73% | 76/55/54% | 6198/971/453 | 24.7 | 6.1 | 742.4 | 77.7 | 10.6 | 12.2 | 1.1 | 0.2 | 0.1 | 97.2 |

## Key Findings

- 신규 플레이어에 가까운 novice 자동 정책은 Act 1 보스 75.3%, Act 2 보스 25.3%, 최종 승리 7.0%다. 사람의 실수와 학습 비용은 더 크므로, 이 값은 신규 목표의 상한선으로 본다.
- 현재 구현 데이터는 경로 성향에 따라 크게 갈린다. balanced 54.0%, safe 84.3%, greedy 32.0%다.
- 웨이브 노드는 1웨이브보다 긴 턴 수를 만들지만 즉시 동시 공격 압박은 낮춘다. 2웨이브는 리듬 변화, 3웨이브는 기억나는 세트피스로 보고 빈도를 먼저 관리한다.
- 이번 패치는 보스 HP만 올리는 방향을 피하고, 일반/엘리트의 공격 의도와 회복 경제를 조정해 길 위에서 체력이 점진적으로 깎이는 곡선을 만든다.
- safe 정책은 체력을 보존하지만 덱 품질과 최종 화력이 약해지도록 두고, greedy 정책은 강한 덱을 만들 수 있지만 여관 진입 체력이 낮아지는 구조로 본다.

## Target Bands

| Target profile | Act 1 boss clear | Act 2 boss clear | Act 3 reach | Act 3 boss clear | Use |
| --- | ---: | ---: | ---: | ---: | --- |
| Early general player | 65-75% | 25-35% | 12-18% | 6-10% | 신규/초기 런 체감 목표. 자동 러너와 직접 비교하지 않는다. |
| Automatic runner sanity | novice 75-90% | novice 30-45% | novice 25-45% | novice 6-12%, balanced 35-55%, safe 70-90%, greedy 20-40% | 수치 패치가 너무 쉬운지/가파른지 보는 내부 안전장치. |

Steam achievements show many lifetime players eventually beat at least one character, while high Ascension completion is much rarer. 그래서 기본 난이도의 장기 목표를 10% 미만으로 두지 않고, 신규/초기 플레이어 목표와 숙련 플레이어 목표를 분리한다.

체력 곡선은 별도 목표로 본다. 평균 여관 진입 체력은 35-60% 사이, 여관 퇴장 체력은 60-85% 사이가 좋다. 보스 진입 체력은 Act 1 55-80%, Act 2 45-75%, Act 3 40-70%를 1차 목표로 둔다. 이 값이 높게 고정되면 경로 선택의 긴장이 약하고, 너무 낮으면 여관을 못 찾은 런이 즉사한다.

## Combat Pressure

### novice / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2529 | 3.78 | 5 | 7.2 | 15 | 2.9% |
| Act 2 | 1109 | 4.04 | 7 | 7.4 | 18 | 13.1% |
| Act 3 | 452 | 5.00 | 8 | 8.7 | 18 | 11.5% |
| boss | 417 | 5.43 | 7 | 15.8 | 28 | 22.5% |
| combat | 2731 | 3.71 | 6 | 6.1 | 13 | 5.4% |
| elite | 642 | 3.90 | 5 | 7.5 | 14 | 4.5% |
| midboss | 300 | 4.63 | 6 | 8.0 | 14 | 0.0% |
| 1-wave | 3414 | 3.69 | 5 | 7.6 | 17 | 6.5% |
| 2-wave | 554 | 4.97 | 6 | 5.7 | 11 | 4.3% |
| 3-wave | 122 | 7.67 | 10 | 9.5 | 18 | 21.3% |

Top deaths: A1D12 Gate Warlord 54, A2D8 Red Receipt 42, A2D12 Oathless Regent 26, win 21, A2D10 Causeway Toll 18

### balanced / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2979 | 4.41 | 6 | 2.3 | 8 | 0.0% |
| Act 2 | 2413 | 4.37 | 7 | 4.8 | 15 | 1.2% |
| Act 3 | 2341 | 5.27 | 9 | 6.2 | 18 | 4.4% |
| boss | 824 | 6.53 | 8 | 16.0 | 34 | 11.2% |
| combat | 4716 | 4.35 | 7 | 2.4 | 7 | 0.9% |
| elite | 1893 | 4.53 | 6 | 4.1 | 12 | 0.0% |
| midboss | 300 | 5.15 | 6 | 2.6 | 9 | 0.0% |
| 1-wave | 6390 | 4.24 | 6 | 4.6 | 14 | 1.9% |
| 2-wave | 931 | 5.58 | 7 | 1.8 | 6 | 0.3% |
| 3-wave | 412 | 9.03 | 11 | 4.2 | 11 | 2.7% |

Top deaths: win 162, A3D12 Unbound Core 86, A2D8 Red Receipt 15, A2D12 Oathless Regent 7, A2D10 Causeway Toll 5

### safe / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2324 | 3.93 | 6 | 2.9 | 9 | 0.0% |
| Act 2 | 1690 | 5.18 | 7 | 7.6 | 23 | 0.2% |
| Act 3 | 1886 | 5.42 | 8 | 9.0 | 25 | 2.3% |
| boss | 864 | 6.09 | 7 | 19.6 | 43 | 1.7% |
| combat | 3302 | 4.66 | 7 | 3.5 | 11 | 1.0% |
| elite | 1434 | 4.18 | 5 | 4.8 | 14 | 0.0% |
| midboss | 300 | 4.81 | 5 | 3.6 | 9 | 0.0% |
| 1-wave | 4526 | 4.27 | 6 | 6.8 | 20 | 0.4% |
| 2-wave | 945 | 5.54 | 6 | 3.3 | 10 | 1.9% |
| 3-wave | 429 | 8.21 | 10 | 6.2 | 16 | 3.0% |

Top deaths: win 253, A3D12 Unbound Core 13, A3D10 Core Approach 9, A3D9 Core Echo 9, A3D2 Folded Gallery 8

### greedy / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3300 | 4.08 | 6 | 2.7 | 9 | 0.3% |
| Act 2 | 2653 | 4.46 | 7 | 6.5 | 19 | 3.5% |
| Act 3 | 1669 | 5.01 | 9 | 6.8 | 19 | 5.5% |
| boss | 669 | 6.16 | 7 | 16.8 | 34 | 12.7% |
| combat | 5184 | 4.17 | 7 | 3.5 | 10 | 2.1% |
| elite | 1469 | 4.37 | 5 | 5.0 | 14 | 0.0% |
| midboss | 300 | 5.00 | 6 | 3.7 | 10 | 0.0% |
| 1-wave | 6198 | 4.02 | 6 | 5.3 | 16 | 2.3% |
| 2-wave | 971 | 5.19 | 6 | 2.6 | 8 | 2.0% |
| 3-wave | 453 | 8.27 | 10 | 4.7 | 13 | 6.6% |

Top deaths: win 96, A3D12 Unbound Core 51, A2D8 Red Receipt 41, A2D12 Oathless Regent 28, A2D10 Causeway Toll 18


## Card Balance Signals

기준 표본: `balanced / current`

### High Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Oath Focus | power | 1 | 382 | 362 | 94.8% | 3812 | 14.6 |
| Marked Riposte | skill | 1 | 1711 | 785 | 45.9% | 10211 | 9.9 |
| Sweeping Order | attack | 3 | 899 | 334 | 37.2% | 3896 | 14.1 |
| Desperate Stand | skill | 3 | 355 | 98 | 27.6% | 1756 | 20.9 |
| Quick Step | skill | 1 | 1802 | 497 | 27.6% | 8459 | 10.0 |
| Wide Swing | attack | 2 | 1736 | 415 | 23.9% | 4353 | 10.1 |
| Heavy Cut | attack | 2 | 1815 | 414 | 22.8% | 4563 | 16.6 |
| Road Cleave | attack | 3 | 1712 | 342 | 20.0% | 4190 | 19.3 |
| Breakthrough | attack | 3 | 943 | 187 | 19.8% | 1238 | 20.0 |
| Contract Mark | skill | 1 | 1766 | 223 | 12.6% | 1644 | 11.0 |

### Low Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Blood Price | skill | 0 | 892 | 5 | 0.6% | 56 | 10.0 |
| Clean Cut | attack | 1 | 1812 | 29 | 1.6% | 247 | 12.5 |
| Field Medicine | skill | 2 | 897 | 31 | 3.5% | 439 | 13.1 |
| Shield Line | skill | 2 | 888 | 41 | 4.6% | 673 | 14.0 |
| Brace | skill | 2 | 1725 | 90 | 5.2% | 766 | 13.1 |
| Last Light | skill | 3 | 363 | 33 | 9.1% | 591 | 15.8 |
| Risk Advance | skill | 0 | 903 | 101 | 11.2% | 1320 | 8.3 |
| Contract Mark | skill | 1 | 1766 | 223 | 12.6% | 1644 | 11.0 |
| Breakthrough | attack | 3 | 943 | 187 | 19.8% | 1238 | 20.0 |
| Road Cleave | attack | 3 | 1712 | 342 | 20.0% | 4190 | 19.3 |

### High Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Debt Cleave | attack | 3 | 0 | 154 | 0.0% | 2450 | 21.9 |
| Desperate Stand | skill | 3 | 355 | 98 | 27.6% | 1756 | 20.9 |
| Breakthrough | attack | 3 | 943 | 187 | 19.8% | 1238 | 20.0 |
| Road Cleave | attack | 3 | 1712 | 342 | 20.0% | 4190 | 19.3 |
| Spear Finish | attack | 3 | 0 | 54 | 0.0% | 679 | 18.9 |
| Bad Omen | skill | 2 | 0 | 26 | 0.0% | 197 | 17.5 |
| Back Cut | attack | 2 | 0 | 113 | 0.0% | 824 | 16.8 |
| Heavy Cut | attack | 2 | 1815 | 414 | 22.8% | 4563 | 16.6 |
| Pinning Thrust | attack | 2 | 0 | 136 | 0.0% | 1052 | 16.6 |
| Broadhead | attack | 2 | 0 | 81 | 0.0% | 635 | 16.3 |

### Low Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Guard | skill | 1 | 0 | 0 | 0.0% | 16555 | 5.0 |
| Tactical Prep | skill | 0 | 0 | 0 | 0.0% | 11520 | 7.6 |
| Knife Feint | skill | 0 | 0 | 85 | 0.0% | 1629 | 8.0 |
| Smoke Pocket | skill | 1 | 0 | 49 | 0.0% | 436 | 8.0 |
| Risk Advance | skill | 0 | 903 | 101 | 11.2% | 1320 | 8.3 |
| Bell Break | attack | 2 | 0 | 46 | 0.0% | 287 | 9.1 |
| Strike | attack | 1 | 0 | 0 | 0.0% | 16383 | 9.8 |
| Marked Riposte | skill | 1 | 1711 | 785 | 45.9% | 10211 | 9.9 |
| Red Banner | skill | 1 | 0 | 114 | 0.0% | 1574 | 9.9 |
| Snare Line | skill | 1 | 0 | 81 | 0.0% | 833 | 10.0 |

## Reading

- 낮은 픽률 카드는 보상 후보를 흐리는 카드다. 높은 출력 카드는 코스트 대비 과한지 실제 카드 텍스트를 따로 검토한다.
- 현재 자동 정책은 공격적으로 강한 카드를 선호하므로, 방어/유틸 카드의 실제 인간 가치가 과소평가될 수 있다. 그래도 0%에 가까운 픽률은 경고로 본다.
- 승률 목표는 자동 러너 기준 novice 6~12%, balanced 35~55%, safe 70~90%, greedy 20~40% 정도가 1차 기준으로 적당하다. safe 95% 이상은 너무 쉽고, balanced 25% 이하는 너무 가파르다.

## Next Balance Actions

1. 적 HP를 문서 목표까지 일괄 상향하지 말고, Act 1 보스/Act 2 이후 단일 적/후반 보스부터 단계적으로 올린다.
2. safe 경로가 너무 안정적이므로 여관/이벤트/상점 경제와 안전 경로 보상을 함께 조정한다.
3. 엘리트는 패배율보다 보상 차별화가 먼저 문제다. 엘리트 전용 강화 보상을 실제 구현하고, 그 뒤 위험도를 다시 측정한다.
4. 업그레이드가 `first unupgraded`인 현재 구현은 플레이어 선택감을 죽이고 시뮬레이션도 왜곡하므로, 카드 선택형 업그레이드 UI/로직으로 바꾼다.
5. Road Cleave / Breakthrough / Sweeping Order 쏠림을 낮추고, Contract Mark / Oath Focus / Risk Advance / Field Medicine 계열의 선택 이유를 강화한다.

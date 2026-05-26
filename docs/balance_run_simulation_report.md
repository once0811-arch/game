# Balance Run Simulation Report

이 리포트는 `tools/balance_run_simulator.py`가 현재 JSON 데이터와 핵심 GDScript 전투 규칙을 근사해 반복 실행한 결과다.
인간 플레이테스트를 대체하지 않고, 카드/적/성장 수치의 위험 구간을 찾기 위한 자동 러너다.

## Assumptions

- 카드 효과, 업그레이드 보정, 동료 기본 공격, 유대 30/60/100 보너스, 장비 보너스, 상점/여관/이벤트를 반영했다.
- 보상 선택은 합리적 자동 정책으로 처리한다. 실제 플레이어의 실수, 선호, 장기 빌드 해석은 반영하지 않는다.
- 현재 구현처럼 카드 업그레이드는 `first unupgraded` 방식으로 처리한다. 이는 플레이어 선택형 업그레이드보다 약하고 거칠다.
- 현재 구현처럼 일반 카드 보상은 주로 주인공 카드에서 나온다. 동료 카드는 영입/상점 중심으로 들어간다.

## Summary

| Policy | Enemy profile | Runs | A1 Boss | A2 Boss | A3 Reach | Win | Inn in/out | Boss HP A1/A2/A3 | Avg deck | Avg HP | Avg gold | Avg bond | Picked | Skipped | Upgraded | Removed | Gear | Oath triggers |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| novice | current | 500 | 71.2% | 21.6% | 21.4% | 6.0% | 50/75% | 48/51/55% | 23.4 | 1.5 | 160.5 | 35.0 | 9.6 | 1.4 | 1.1 | 1.3 | 0.5 | 32.6 |
| balanced | current | 500 | 98.6% | 76.4% | 76.4% | 39.2% | 33/67% | 75/67/54% | 24.3 | 9.5 | 199.6 | 80.8 | 7.8 | 12.9 | 1.5 | 2.6 | 0.2 | 98.8 |
| safe | current | 500 | 99.6% | 96.2% | 96.2% | 69.6% | 49/90% | 72/89/88% | 19.2 | 28.5 | 488.5 | 91.3 | 5.2 | 10.4 | 2.6 | 0.1 | 2.6 | 82.9 |
| greedy | current | 500 | 94.2% | 49.4% | 49.0% | 20.6% | 22/71% | 71/54/53% | 24.5 | 4.5 | 614.7 | 65.5 | 10.4 | 9.7 | 1.1 | 0.3 | 0.1 | 84.8 |

## Key Findings

- 신규 플레이어에 가까운 novice 자동 정책은 Act 1 보스 71.2%, Act 2 보스 21.6%, 최종 승리 6.0%다. 사람의 실수와 학습 비용은 더 크므로, 이 값은 신규 목표의 상한선으로 본다.
- 현재 구현 데이터는 경로 성향에 따라 크게 갈린다. balanced 39.2%, safe 69.6%, greedy 20.6%다.
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
| Act 1 | 4185 | 3.77 | 5 | 7.6 | 15 | 3.4% |
| Act 2 | 1692 | 3.79 | 6 | 8.1 | 19 | 14.1% |
| Act 3 | 527 | 4.70 | 7 | 9.3 | 20 | 14.2% |
| boss | 630 | 5.33 | 7 | 15.0 | 27 | 21.6% |
| combat | 4325 | 3.53 | 5 | 6.9 | 15 | 6.4% |
| elite | 949 | 3.88 | 5 | 7.4 | 14 | 4.7% |
| midboss | 500 | 4.67 | 6 | 8.2 | 14 | 0.2% |

Top deaths: A1D12 Gate Warlord 91, A2D8 Red Receipt 42, A2D12 Oathless Regent 39, A2D2 Broken Milestone 36, win 30

### balanced / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 4962 | 4.46 | 6 | 2.9 | 10 | 0.1% |
| Act 2 | 3733 | 4.21 | 7 | 5.8 | 17 | 2.9% |
| Act 3 | 2999 | 4.95 | 7 | 7.2 | 21 | 6.1% |
| boss | 1179 | 6.55 | 8 | 14.4 | 31 | 9.2% |
| combat | 7409 | 4.14 | 6 | 4.0 | 12 | 2.6% |
| elite | 2606 | 4.52 | 6 | 3.8 | 12 | 0.0% |
| midboss | 500 | 5.15 | 6 | 2.7 | 9 | 0.0% |

Top deaths: win 196, A3D12 Unbound Core 93, A3D10 Core Approach 50, A2D8 Red Receipt 39, A2D10 Causeway Toll 32

### safe / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3888 | 3.94 | 6 | 3.0 | 10 | 0.1% |
| Act 2 | 2593 | 4.88 | 6 | 9.5 | 23 | 0.7% |
| Act 3 | 2808 | 5.21 | 7 | 9.7 | 26 | 4.7% |
| boss | 1356 | 6.10 | 7 | 18.1 | 40 | 2.1% |
| combat | 5233 | 4.34 | 7 | 5.4 | 17 | 2.3% |
| elite | 2200 | 4.18 | 5 | 4.0 | 12 | 0.0% |
| midboss | 500 | 4.80 | 5 | 3.9 | 9 | 0.0% |

Top deaths: win 348, A3D10 Core Approach 47, A3D2 Folded Gallery 38, A3D12 Unbound Core 21, A3D9 Core Echo 18

### greedy / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 5497 | 4.09 | 6 | 3.1 | 10 | 0.5% |
| Act 2 | 3815 | 4.23 | 6 | 7.5 | 21 | 5.7% |
| Act 3 | 1971 | 4.73 | 7 | 7.1 | 19 | 7.2% |
| boss | 923 | 6.21 | 8 | 13.9 | 28 | 10.9% |
| combat | 7823 | 3.94 | 6 | 4.6 | 14 | 3.6% |
| elite | 2037 | 4.37 | 5 | 4.3 | 12 | 0.0% |
| midboss | 500 | 5.01 | 6 | 3.6 | 10 | 0.0% |

Top deaths: win 103, A2D8 Red Receipt 59, A2D10 Causeway Toll 58, A3D10 Core Approach 45, A3D12 Unbound Core 40


## Card Balance Signals

기준 표본: `balanced / current`

### High Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Oath Focus | power | 1 | 539 | 498 | 92.4% | 4534 | 14.4 |
| Marked Riposte | skill | 1 | 2666 | 1267 | 47.5% | 15172 | 9.6 |
| Sweeping Order | attack | 3 | 1340 | 572 | 42.7% | 5626 | 14.0 |
| Quick Step | skill | 1 | 2643 | 815 | 30.8% | 12625 | 10.0 |
| Desperate Stand | skill | 3 | 534 | 141 | 26.4% | 2432 | 21.0 |
| Heavy Cut | attack | 2 | 2659 | 675 | 25.4% | 6474 | 16.0 |
| Wide Swing | attack | 2 | 2664 | 672 | 25.2% | 6385 | 10.2 |
| Breakthrough | attack | 3 | 1336 | 308 | 23.1% | 1721 | 18.8 |
| Road Cleave | attack | 3 | 2525 | 540 | 21.4% | 5812 | 18.8 |
| Contract Mark | skill | 1 | 2641 | 347 | 13.1% | 2139 | 10.7 |

### Low Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Blood Price | skill | 0 | 1359 | 6 | 0.4% | 84 | 10.0 |
| Clean Cut | attack | 1 | 2720 | 55 | 2.0% | 443 | 12.3 |
| Field Medicine | skill | 2 | 1347 | 46 | 3.4% | 656 | 13.1 |
| Shield Line | skill | 2 | 1419 | 80 | 5.6% | 1164 | 14.0 |
| Brace | skill | 2 | 2669 | 152 | 5.7% | 1241 | 13.1 |
| Risk Advance | skill | 0 | 1362 | 152 | 11.2% | 1601 | 7.8 |
| Last Light | skill | 3 | 546 | 61 | 11.2% | 1083 | 16.1 |
| Contract Mark | skill | 1 | 2641 | 347 | 13.1% | 2139 | 10.7 |
| Road Cleave | attack | 3 | 2525 | 540 | 21.4% | 5812 | 18.8 |
| Breakthrough | attack | 3 | 1336 | 308 | 23.1% | 1721 | 18.8 |

### High Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Debt Cleave | attack | 3 | 0 | 252 | 0.0% | 3214 | 21.2 |
| Desperate Stand | skill | 3 | 534 | 141 | 26.4% | 2432 | 21.0 |
| Road Cleave | attack | 3 | 2525 | 540 | 21.4% | 5812 | 18.8 |
| Breakthrough | attack | 3 | 1336 | 308 | 23.1% | 1721 | 18.8 |
| Spear Finish | attack | 3 | 0 | 93 | 0.0% | 926 | 18.4 |
| Last Light | skill | 3 | 546 | 61 | 11.2% | 1083 | 16.1 |
| Broadhead | attack | 2 | 0 | 137 | 0.0% | 885 | 16.0 |
| Iron Bulwark | skill | 3 | 0 | 23 | 0.0% | 321 | 16.0 |
| Pinning Thrust | attack | 2 | 0 | 232 | 0.0% | 1493 | 16.0 |
| Heavy Cut | attack | 2 | 2659 | 675 | 25.4% | 6474 | 16.0 |

### Low Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Guard | skill | 1 | 0 | 0 | 0.0% | 26786 | 5.0 |
| Tactical Prep | skill | 0 | 0 | 0 | 0.0% | 17735 | 7.5 |
| Knife Feint | skill | 0 | 0 | 131 | 0.0% | 2145 | 7.5 |
| Risk Advance | skill | 0 | 1362 | 152 | 11.2% | 1601 | 7.8 |
| Smoke Pocket | skill | 1 | 0 | 78 | 0.0% | 656 | 8.0 |
| Bell Break | attack | 2 | 0 | 74 | 0.0% | 412 | 9.1 |
| Strike | attack | 1 | 0 | 0 | 0.0% | 26233 | 9.5 |
| Marked Riposte | skill | 1 | 2666 | 1267 | 47.5% | 15172 | 9.6 |
| Red Banner | skill | 1 | 0 | 196 | 0.0% | 2268 | 9.6 |
| Snare Line | skill | 1 | 0 | 137 | 0.0% | 1297 | 9.7 |

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

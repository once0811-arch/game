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
| novice | current | 300 | 75.3% | 38.0% | 37.7% | 6.3% | 56/81% | 57/54/56% | 3690/608/141 | 24.6 | 1.6 | 175.7 | 47.0 | 10.6 | 2.1 | 1.3 | 1.3 | 0.6 | 47.2 |
| balanced | current | 300 | 97.3% | 91.3% | 91.3% | 30.0% | 33/69% | 84/68/58% | 6230/811/376 | 24.3 | 5.8 | 231.7 | 88.3 | 8.1 | 13.8 | 1.6 | 2.6 | 0.2 | 109.3 |
| safe | current | 300 | 97.3% | 96.3% | 96.3% | 78.3% | 52/92% | 73/91/88% | 4658/855/366 | 19.3 | 24.1 | 575.2 | 94.8 | 5.3 | 11.4 | 2.7 | 0.0 | 2.5 | 79.7 |
| greedy | current | 300 | 95.7% | 74.7% | 74.7% | 21.0% | 23/73% | 79/55/58% | 6314/930/459 | 24.6 | 3.6 | 728.3 | 80.4 | 10.5 | 12.5 | 1.1 | 0.3 | 0.1 | 107.2 |

## Key Findings

- 신규 플레이어에 가까운 novice 자동 정책은 Act 1 보스 75.3%, Act 2 보스 38.0%, 최종 승리 6.3%다. 사람의 실수와 학습 비용은 더 크므로, 이 값은 신규 목표의 상한선으로 본다.
- 현재 구현 데이터는 경로 성향에 따라 크게 갈린다. balanced 30.0%, safe 78.3%, greedy 21.0%다.
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
| Act 1 | 2575 | 3.96 | 6 | 7.0 | 15 | 2.9% |
| Act 2 | 1244 | 4.26 | 7 | 6.0 | 15 | 8.4% |
| Act 3 | 620 | 5.27 | 8 | 9.9 | 23 | 15.2% |
| boss | 478 | 5.61 | 7 | 19.0 | 35 | 24.9% |
| combat | 2958 | 3.91 | 6 | 5.6 | 13 | 4.4% |
| elite | 703 | 4.40 | 6 | 6.4 | 12 | 3.3% |
| midboss | 300 | 4.80 | 6 | 5.3 | 12 | 0.0% |
| 1-wave | 3690 | 3.97 | 6 | 6.9 | 17 | 5.5% |
| 2-wave | 608 | 4.97 | 7 | 7.4 | 14 | 6.1% |
| 3-wave | 141 | 7.96 | 11 | 12.4 | 27 | 24.1% |

Top deaths: A1D12 Gate Warlord 61, A3D12 Unbound Core 34, A2D12 Oathless Regent 25, win 19, A2D8 Red Receipt 19

### balanced / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3039 | 4.53 | 6 | 3.0 | 10 | 0.3% |
| Act 2 | 2366 | 4.45 | 7 | 3.9 | 13 | 0.8% |
| Act 3 | 2012 | 5.42 | 9 | 8.1 | 22 | 9.1% |
| boss | 763 | 6.59 | 8 | 19.9 | 40 | 14.0% |
| combat | 4579 | 4.40 | 7 | 3.0 | 10 | 2.2% |
| elite | 1775 | 4.78 | 6 | 3.1 | 10 | 0.0% |
| midboss | 300 | 5.13 | 6 | 1.5 | 7 | 0.0% |
| 1-wave | 6230 | 4.37 | 6 | 4.7 | 15 | 2.4% |
| 2-wave | 811 | 5.65 | 7 | 2.7 | 8 | 1.5% |
| 3-wave | 376 | 9.06 | 12 | 9.2 | 22 | 12.5% |

Top deaths: A3D12 Unbound Core 95, win 90, A3D7 Room Vein 24, A3D10 Core Approach 18, A3D1 Inside the Wall 15

### safe / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2331 | 4.14 | 6 | 3.8 | 13 | 0.3% |
| Act 2 | 1609 | 5.22 | 7 | 4.9 | 16 | 0.2% |
| Act 3 | 1939 | 5.29 | 7 | 9.4 | 32 | 2.8% |
| boss | 849 | 5.99 | 7 | 21.7 | 47 | 3.9% |
| combat | 3195 | 4.71 | 7 | 3.3 | 11 | 1.0% |
| elite | 1535 | 4.41 | 6 | 3.5 | 11 | 0.0% |
| midboss | 300 | 4.57 | 6 | 1.7 | 7 | 0.0% |
| 1-wave | 4658 | 4.34 | 6 | 6.1 | 20 | 0.7% |
| 2-wave | 855 | 5.92 | 7 | 3.5 | 11 | 0.9% |
| 3-wave | 366 | 8.16 | 10 | 9.3 | 26 | 6.3% |

Top deaths: win 235, A3D12 Unbound Core 25, A3D10 Core Approach 20, A1D12 Gate Warlord 8, A3D9 Core Echo 6

### greedy / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3300 | 4.31 | 6 | 3.4 | 10 | 0.4% |
| Act 2 | 2651 | 4.60 | 7 | 4.8 | 15 | 2.2% |
| Act 3 | 1752 | 5.13 | 8 | 7.3 | 21 | 9.1% |
| boss | 662 | 6.36 | 8 | 20.2 | 38 | 13.3% |
| combat | 5183 | 4.33 | 7 | 3.3 | 11 | 2.8% |
| elite | 1558 | 4.66 | 6 | 3.7 | 11 | 0.0% |
| midboss | 300 | 5.03 | 6 | 1.8 | 7 | 0.0% |
| 1-wave | 6314 | 4.21 | 6 | 4.8 | 15 | 2.2% |
| 2-wave | 930 | 5.30 | 7 | 3.1 | 9 | 4.1% |
| 3-wave | 459 | 8.51 | 11 | 8.0 | 22 | 11.8% |

Top deaths: win 63, A3D12 Unbound Core 59, A3D10 Core Approach 34, A3D1 Inside the Wall 21, A3D9 Core Echo 18


## Card Balance Signals

기준 표본: `balanced / current`

### High Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Oath Focus | power | 1 | 342 | 324 | 94.7% | 3221 | 14.5 |
| Marked Riposte | skill | 1 | 1661 | 766 | 46.1% | 9618 | 9.9 |
| Sweeping Order | attack | 3 | 865 | 331 | 38.3% | 4076 | 11.5 |
| Quick Step | skill | 1 | 1680 | 461 | 27.4% | 6896 | 10.0 |
| Desperate Stand | skill | 3 | 337 | 89 | 26.4% | 1524 | 20.8 |
| Wide Swing | attack | 2 | 1725 | 407 | 23.6% | 3902 | 8.7 |
| Heavy Cut | attack | 2 | 1699 | 398 | 23.4% | 4520 | 15.2 |
| Breakthrough | attack | 3 | 906 | 197 | 21.7% | 1442 | 17.0 |
| Road Cleave | attack | 3 | 1603 | 306 | 19.1% | 4190 | 16.8 |
| Contract Mark | skill | 1 | 1734 | 207 | 11.9% | 1567 | 10.9 |

### Low Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Blood Price | skill | 0 | 886 | 6 | 0.7% | 83 | 10.0 |
| Clean Cut | attack | 1 | 1671 | 32 | 1.9% | 321 | 12.3 |
| Field Medicine | skill | 2 | 872 | 27 | 3.1% | 385 | 13.0 |
| Brace | skill | 2 | 1641 | 100 | 6.1% | 712 | 13.1 |
| Shield Line | skill | 2 | 825 | 60 | 7.3% | 783 | 14.1 |
| Risk Advance | skill | 0 | 864 | 93 | 10.8% | 1187 | 8.0 |
| Last Light | skill | 3 | 342 | 37 | 10.8% | 552 | 16.1 |
| Contract Mark | skill | 1 | 1734 | 207 | 11.9% | 1567 | 10.9 |
| Road Cleave | attack | 3 | 1603 | 306 | 19.1% | 4190 | 16.8 |
| Breakthrough | attack | 3 | 906 | 197 | 21.7% | 1442 | 17.0 |

### High Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Desperate Stand | skill | 3 | 337 | 89 | 26.4% | 1524 | 20.8 |
| Debt Cleave | attack | 3 | 0 | 153 | 0.0% | 2651 | 18.9 |
| Breakthrough | attack | 3 | 906 | 197 | 21.7% | 1442 | 17.0 |
| Road Cleave | attack | 3 | 1603 | 306 | 19.1% | 4190 | 16.8 |
| Rent Strike | attack | 2 | 0 | 59 | 0.0% | 943 | 16.4 |
| Spear Finish | attack | 3 | 0 | 52 | 0.0% | 703 | 16.4 |
| Shield Bash | attack | 2 | 0 | 34 | 0.0% | 450 | 16.3 |
| Iron Bulwark | skill | 3 | 0 | 17 | 0.0% | 238 | 16.1 |
| Last Light | skill | 3 | 342 | 37 | 10.8% | 552 | 16.1 |
| Bad Omen | skill | 2 | 0 | 26 | 0.0% | 183 | 15.7 |

### Low Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Guard | skill | 1 | 0 | 0 | 0.0% | 14824 | 5.0 |
| Tactical Prep | skill | 0 | 0 | 0 | 0.0% | 11302 | 7.6 |
| Knife Feint | skill | 0 | 0 | 76 | 0.0% | 1479 | 7.8 |
| Risk Advance | skill | 0 | 864 | 93 | 10.8% | 1187 | 8.0 |
| Smoke Pocket | skill | 1 | 0 | 49 | 0.0% | 415 | 8.1 |
| Bell Break | attack | 2 | 0 | 42 | 0.0% | 268 | 8.5 |
| Wide Swing | attack | 2 | 1725 | 407 | 23.6% | 3902 | 8.7 |
| Strike | attack | 1 | 0 | 0 | 0.0% | 17813 | 9.4 |
| Rust Hook | attack | 2 | 0 | 153 | 0.0% | 685 | 9.6 |
| Snare Line | skill | 1 | 0 | 71 | 0.0% | 652 | 9.8 |

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

# Balance Run Simulation Report

이 리포트는 `tools/balance_run_simulator.py`가 현재 JSON 데이터와 핵심 GDScript 전투 규칙을 근사해 반복 실행한 결과다.
인간 플레이테스트를 대체하지 않고, 카드/적/성장 수치의 위험 구간을 찾기 위한 자동 러너다.

## Assumptions

- 카드 효과, 업그레이드 보정, 동료 기본 공격, 유대 30/60/100 보너스, 장비 보너스, 상점/여관/이벤트를 반영했다.
- 보상 선택은 합리적 자동 정책으로 처리한다. 실제 플레이어의 실수, 선호, 장기 빌드 해석은 반영하지 않는다.
- 현재 구현처럼 카드 업그레이드는 `first unupgraded` 방식으로 처리한다. 이는 플레이어 선택형 업그레이드보다 약하고 거칠다.
- 현재 구현처럼 일반 카드 보상은 주로 주인공 카드에서 나온다. 동료 카드는 영입/상점 중심으로 들어간다.

## Summary

| Policy | Enemy profile | Runs | Win | Avg deck | Avg HP | Avg gold | Avg bond | Picked | Skipped | Upgraded | Removed | Gear | Oath triggers |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| balanced | current | 300 | 58.3% | 17.3 | 21.6 | 297.3 | 93.2 | 4.0 | 17.3 | 3.3 | 2.7 | 0.3 | 81.3 |
| safe | current | 300 | 96.0% | 16.8 | 48.1 | 862.9 | 99.8 | 2.9 | 14.1 | 2.7 | 0.1 | 2.7 | 62.2 |
| greedy | current | 300 | 31.3% | 21.9 | 9.7 | 820.6 | 87.7 | 8.2 | 13.6 | 1.0 | 0.4 | 0.1 | 67.0 |
| balanced | plus6 | 300 | 49.7% | 17.3 | 17.4 | 280.2 | 92.5 | 4.0 | 17.0 | 3.2 | 2.7 | 0.2 | 81.5 |
| safe | plus6 | 300 | 95.7% | 16.9 | 46.1 | 837.7 | 99.0 | 3.0 | 13.8 | 2.6 | 0.1 | 2.6 | 66.7 |
| greedy | plus6 | 300 | 27.0% | 22.0 | 9.0 | 772.5 | 86.4 | 8.3 | 13.1 | 1.0 | 0.5 | 0.1 | 73.2 |
| balanced | spec_mid | 300 | 21.0% | 17.1 | 7.5 | 233.8 | 76.8 | 3.9 | 12.9 | 2.3 | 2.2 | 0.2 | 109.0 |
| safe | spec_mid | 300 | 74.3% | 16.9 | 25.7 | 677.0 | 95.9 | 3.0 | 12.2 | 2.5 | 0.1 | 2.5 | 101.0 |
| greedy | spec_mid | 300 | 7.3% | 21.0 | 2.1 | 575.8 | 61.3 | 7.8 | 7.5 | 0.5 | 0.2 | 0.1 | 62.2 |
| balanced | spec_mid_attack10 | 300 | 13.7% | 16.8 | 3.9 | 251.7 | 63.0 | 3.9 | 10.3 | 1.6 | 1.8 | 0.1 | 81.0 |
| safe | spec_mid_attack10 | 300 | 57.3% | 16.7 | 16.9 | 596.6 | 89.9 | 2.9 | 10.8 | 2.3 | 0.0 | 2.3 | 90.1 |
| greedy | spec_mid_attack10 | 300 | 4.3% | 20.4 | 1.3 | 522.4 | 50.6 | 7.6 | 5.8 | 0.3 | 0.1 | 0.0 | 48.0 |

## Key Findings

- 현재 구현 데이터는 경로 성향에 따라 크게 갈린다. balanced 58.3%, safe 96.0%, greedy 31.3%다.
- 단순 +6% HP는 balanced를 49.7%까지 낮추지만, safe는 여전히 매우 높다. 즉 전체 HP 상향만으로는 안전 경로 문제를 해결하지 못한다.
- 문서 목표 HP 중간값을 전부 적용하면 balanced 21.0%, safe 74.3%가 된다. 문서 목표는 최종 목표선으로는 쓸 수 있지만, 현재 구현에 즉시 일괄 적용하면 너무 가파르다.
- 문서 목표 HP에 공격력 +10%까지 얹은 압박 테스트는 balanced 13.7%다. 이 수치는 상위 난이도나 후반 튜닝 검증용이지 기본 난이도 기준으로 쓰면 안 된다.
- 엘리트 전투의 직접 패배율은 거의 0%에 가깝다. 엘리트는 길게 만들 수는 있지만, 현재 구조에서는 위험/보상 거래가 충분히 날카롭지 않다.
- safe 정책은 많은 골드와 장비를 남긴 채 높은 승률을 낸다. 안전 경로의 상점/여관/이벤트 경제가 너무 편하거나, 위험 경로 보상이 충분히 차별화되지 않은 신호다.

## Combat Pressure

### balanced / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2965 | 3.85 | 5 | 3.1 | 9 | 0.1% |
| Act 2 | 2207 | 3.52 | 5 | 5.2 | 14 | 2.2% |
| Act 3 | 2074 | 4.30 | 6 | 7.4 | 19 | 3.4% |
| boss | 762 | 5.19 | 6 | 12.3 | 25 | 5.5% |
| combat | 4488 | 3.67 | 6 | 4.2 | 12 | 1.8% |
| elite | 1696 | 3.72 | 5 | 4.1 | 12 | 0.0% |
| midboss | 300 | 4.49 | 5 | 3.1 | 8 | 0.0% |

Top deaths: win 175, A3D12 Unbound Core 36, A2D8 Red Receipt 23, A3D10 Core Approach 18, A2D10 Causeway Toll 14

### safe / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2340 | 3.37 | 5 | 2.6 | 8 | 0.0% |
| Act 2 | 1682 | 3.97 | 5 | 6.6 | 16 | 0.1% |
| Act 3 | 1972 | 4.08 | 5 | 7.5 | 20 | 0.6% |
| boss | 887 | 4.66 | 5 | 11.8 | 26 | 0.0% |
| combat | 3139 | 3.71 | 5 | 4.5 | 13 | 0.4% |
| elite | 1668 | 3.37 | 4 | 3.7 | 10 | 0.0% |
| midboss | 300 | 4.03 | 5 | 3.0 | 8 | 0.0% |

Top deaths: win 288, A3D10 Core Approach 11, A2D4 Witness Road 1

### greedy / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3300 | 3.68 | 5 | 3.4 | 10 | 0.2% |
| Act 2 | 2433 | 3.64 | 5 | 6.8 | 18 | 3.9% |
| Act 3 | 1605 | 3.94 | 6 | 7.8 | 19 | 6.4% |
| boss | 618 | 4.84 | 6 | 12.5 | 24 | 5.3% |
| combat | 5034 | 3.56 | 5 | 4.8 | 13 | 3.4% |
| elite | 1386 | 3.61 | 4 | 4.8 | 13 | 0.0% |
| midboss | 300 | 4.69 | 5 | 5.2 | 12 | 0.0% |

Top deaths: win 94, A3D10 Core Approach 46, A2D10 Causeway Toll 31, A2D2 Broken Milestone 25, A2D8 Red Receipt 15

### balanced / plus6

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2974 | 4.04 | 6 | 3.4 | 10 | 0.1% |
| Act 2 | 2182 | 3.73 | 6 | 5.4 | 15 | 2.2% |
| Act 3 | 1999 | 4.52 | 7 | 7.7 | 20 | 4.8% |
| boss | 740 | 5.42 | 7 | 12.6 | 25 | 6.5% |
| combat | 4547 | 3.89 | 6 | 4.4 | 13 | 2.2% |
| elite | 1568 | 3.90 | 5 | 4.2 | 12 | 0.0% |
| midboss | 300 | 4.68 | 5 | 3.6 | 9 | 0.0% |

Top deaths: win 149, A3D12 Unbound Core 45, A3D10 Core Approach 24, A2D8 Red Receipt 23, A3D9 Core Echo 18

### safe / plus6

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2331 | 3.53 | 5 | 2.8 | 9 | 0.0% |
| Act 2 | 1657 | 4.21 | 5 | 6.9 | 17 | 0.3% |
| Act 3 | 1943 | 4.32 | 6 | 8.3 | 22 | 0.4% |
| boss | 883 | 4.87 | 5 | 13.0 | 28 | 0.1% |
| combat | 3138 | 3.96 | 6 | 4.9 | 14 | 0.4% |
| elite | 1610 | 3.48 | 4 | 3.9 | 11 | 0.0% |
| midboss | 300 | 4.24 | 5 | 3.6 | 8 | 0.0% |

Top deaths: win 287, A3D10 Core Approach 5, A2D4 Witness Road 4, A3D2 Folded Gallery 1, A3D12 Unbound Core 1

### greedy / plus6

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3300 | 3.86 | 5 | 3.5 | 11 | 0.1% |
| Act 2 | 2371 | 3.81 | 6 | 7.4 | 19 | 4.1% |
| Act 3 | 1535 | 4.07 | 6 | 8.1 | 19 | 7.7% |
| boss | 608 | 5.05 | 6 | 13.0 | 24 | 4.8% |
| combat | 4964 | 3.71 | 6 | 5.1 | 14 | 3.8% |
| elite | 1334 | 3.78 | 5 | 5.2 | 13 | 0.0% |
| midboss | 300 | 4.89 | 6 | 5.3 | 12 | 0.0% |

Top deaths: win 81, A3D10 Core Approach 52, A2D2 Broken Milestone 34, A2D10 Causeway Toll 24, A3D2 Folded Gallery 18

### balanced / spec_mid

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2956 | 4.95 | 7 | 4.7 | 13 | 1.2% |
| Act 2 | 1672 | 6.15 | 9 | 7.6 | 20 | 6.6% |
| Act 3 | 1129 | 7.91 | 11 | 8.7 | 23 | 7.9% |
| boss | 570 | 9.77 | 13 | 20.1 | 37 | 15.4% |
| combat | 3706 | 4.92 | 7 | 4.6 | 13 | 3.9% |
| elite | 1181 | 7.17 | 10 | 5.8 | 17 | 0.0% |
| midboss | 300 | 5.23 | 6 | 3.8 | 10 | 0.0% |

Top deaths: win 63, A3D12 Unbound Core 35, A1D12 Gate Warlord 34, A2D8 Red Receipt 30, A2D12 Oathless Regent 19

### safe / spec_mid

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2362 | 4.70 | 8 | 4.2 | 12 | 0.2% |
| Act 2 | 1516 | 6.37 | 10 | 11.4 | 26 | 0.9% |
| Act 3 | 1536 | 7.09 | 9 | 14.2 | 37 | 3.5% |
| boss | 821 | 9.14 | 10 | 26.3 | 52 | 2.7% |
| combat | 2911 | 4.73 | 7 | 5.3 | 15 | 1.8% |
| elite | 1382 | 6.45 | 8 | 7.7 | 20 | 0.0% |
| midboss | 300 | 4.91 | 5 | 4.4 | 9 | 0.0% |

Top deaths: win 223, A3D2 Folded Gallery 28, A3D10 Core Approach 13, A3D12 Unbound Core 11, A2D12 Oathless Regent 7

### greedy / spec_mid

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3298 | 4.79 | 7 | 5.1 | 13 | 3.0% |
| Act 2 | 1321 | 5.69 | 8 | 8.4 | 21 | 9.2% |
| Act 3 | 548 | 6.80 | 9 | 10.2 | 24 | 10.4% |
| boss | 433 | 8.54 | 11 | 21.0 | 37 | 30.3% |
| combat | 3595 | 4.48 | 6 | 4.7 | 13 | 4.0% |
| elite | 839 | 6.64 | 8 | 7.0 | 17 | 0.1% |
| midboss | 300 | 5.57 | 7 | 6.4 | 13 | 0.0% |

Top deaths: A1D12 Gate Warlord 97, A2D12 Oathless Regent 25, A2D1 Split Causeway 25, A2D8 Red Receipt 22, win 22

### balanced / spec_mid_attack10

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2958 | 5.03 | 7 | 5.8 | 15 | 2.9% |
| Act 2 | 1209 | 6.24 | 9 | 8.0 | 21 | 8.7% |
| Act 3 | 737 | 8.04 | 11 | 10.1 | 27 | 8.7% |
| boss | 487 | 9.41 | 12 | 22.9 | 39 | 26.3% |
| combat | 3202 | 4.84 | 7 | 5.0 | 13 | 4.0% |
| elite | 915 | 7.30 | 10 | 6.3 | 18 | 0.1% |
| midboss | 300 | 5.37 | 6 | 4.4 | 9 | 0.0% |

Top deaths: A1D12 Gate Warlord 87, win 41, A2D1 Split Causeway 31, A3D12 Unbound Core 25, A2D8 Red Receipt 17

### safe / spec_mid_attack10

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 2317 | 4.73 | 8 | 5.4 | 15 | 1.0% |
| Act 2 | 1362 | 6.35 | 10 | 13.8 | 33 | 1.4% |
| Act 3 | 1272 | 6.97 | 9 | 16.9 | 40 | 6.7% |
| boss | 756 | 9.03 | 10 | 31.5 | 59 | 6.7% |
| combat | 2677 | 4.61 | 7 | 6.1 | 17 | 2.9% |
| elite | 1218 | 6.42 | 8 | 9.2 | 24 | 0.0% |
| midboss | 300 | 4.92 | 5 | 4.6 | 9 | 0.0% |

Top deaths: win 172, A3D2 Folded Gallery 45, A1D12 Gate Warlord 24, A3D12 Unbound Core 16, A3D10 Core Approach 14

### greedy / spec_mid_attack10

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 3277 | 4.73 | 6 | 5.9 | 15 | 4.9% |
| Act 2 | 865 | 5.82 | 8 | 8.5 | 21 | 10.2% |
| Act 3 | 342 | 6.86 | 9 | 9.1 | 23 | 11.1% |
| boss | 366 | 7.77 | 11 | 20.7 | 36 | 44.3% |
| combat | 3148 | 4.40 | 6 | 4.8 | 13 | 3.9% |
| elite | 670 | 6.67 | 8 | 7.2 | 15 | 0.1% |
| midboss | 300 | 5.66 | 7 | 6.9 | 14 | 0.0% |

Top deaths: A1D12 Gate Warlord 141, A2D1 Split Causeway 20, A2D2 Broken Milestone 18, A1D11 Castle Ditch 17, A2D8 Red Receipt 15


## Card Balance Signals

기준 표본: `balanced / spec_mid_attack10`

### High Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Road Cleave | attack | 3 | 1104 | 673 | 61.0% | 6064 | 22.9 |
| Breakthrough | attack | 3 | 576 | 340 | 59.0% | 1853 | 22.9 |
| Sweeping Order | attack | 3 | 566 | 316 | 55.8% | 3986 | 13.2 |
| Desperate Stand | skill | 3 | 249 | 51 | 20.5% | 1981 | 21.5 |
| Wide Swing | attack | 2 | 1149 | 102 | 8.9% | 925 | 9.7 |
| Heavy Cut | attack | 2 | 1108 | 46 | 4.2% | 490 | 15.9 |
| Quick Step | skill | 1 | 1132 | 18 | 1.6% | 535 | 9.5 |
| Blood Price | skill | 0 | 524 | 0 | 0.0% | 241 | 4.0 |
| Brace | skill | 2 | 1091 | 0 | 0.0% | 207 | 11.2 |
| Clean Cut | attack | 1 | 1072 | 0 | 0.0% | 223 | 15.9 |

### Low Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Blood Price | skill | 0 | 524 | 0 | 0.0% | 241 | 4.0 |
| Brace | skill | 2 | 1091 | 0 | 0.0% | 207 | 11.2 |
| Clean Cut | attack | 1 | 1072 | 0 | 0.0% | 223 | 15.9 |
| Contract Mark | skill | 1 | 1083 | 0 | 0.0% | 195 | 0.0 |
| Field Medicine | skill | 2 | 587 | 0 | 0.0% | 286 | 10.9 |
| Last Light | skill | 3 | 232 | 0 | 0.0% | 247 | 14.1 |
| Marked Riposte | skill | 1 | 1082 | 0 | 0.0% | 137 | 5.2 |
| Oath Focus | power | 2 | 221 | 0 | 0.0% | 0 | 0.0 |
| Risk Advance | skill | 0 | 527 | 0 | 0.0% | 315 | 0.0 |
| Shield Line | skill | 2 | 564 | 0 | 0.0% | 161 | 15.2 |

### High Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Debt Cleave | attack | 3 | 0 | 135 | 0.0% | 1994 | 23.0 |
| Breakthrough | attack | 3 | 576 | 340 | 59.0% | 1853 | 22.9 |
| Road Cleave | attack | 3 | 1104 | 673 | 61.0% | 6064 | 22.9 |
| Desperate Stand | skill | 3 | 249 | 51 | 20.5% | 1981 | 21.5 |
| Spear Finish | attack | 3 | 0 | 127 | 0.0% | 280 | 20.6 |
| Rent Strike | attack | 2 | 0 | 53 | 0.0% | 1018 | 16.7 |
| Shield Bash | attack | 2 | 0 | 26 | 0.0% | 501 | 16.2 |
| Back Cut | attack | 2 | 0 | 74 | 0.0% | 505 | 16.1 |
| Heavy Cut | attack | 2 | 1108 | 46 | 4.2% | 490 | 15.9 |
| Clean Cut | attack | 1 | 1072 | 0 | 0.0% | 223 | 15.9 |

### Low Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Contract Mark | skill | 1 | 1083 | 0 | 0.0% | 195 | 0.0 |
| Risk Advance | skill | 0 | 527 | 0 | 0.0% | 315 | 0.0 |
| Blood Price | skill | 0 | 524 | 0 | 0.0% | 241 | 4.0 |
| Tactical Prep | skill | 0 | 0 | 0 | 0.0% | 11358 | 4.0 |
| Guard | skill | 1 | 0 | 0 | 0.0% | 24890 | 5.0 |
| Green Path | skill | 1 | 0 | 69 | 0.0% | 384 | 8.0 |
| Smoke Pocket | skill | 1 | 0 | 74 | 0.0% | 1312 | 8.1 |
| Rust Hook | attack | 2 | 0 | 135 | 0.0% | 407 | 9.3 |
| Quick Step | skill | 1 | 1132 | 18 | 1.6% | 535 | 9.5 |
| Wide Swing | attack | 2 | 1149 | 102 | 8.9% | 925 | 9.7 |

## Reading

- 낮은 픽률 카드는 보상 후보를 흐리는 카드다. 높은 출력 카드는 코스트 대비 과한지 실제 카드 텍스트를 따로 검토한다.
- 현재 자동 정책은 공격적으로 강한 카드를 선호하므로, 방어/유틸 카드의 실제 인간 가치가 과소평가될 수 있다. 그래도 0%에 가까운 픽률은 경고로 본다.
- 승률 목표는 자동 러너 기준 balanced 45~65%, safe 70~85%, greedy 25~45% 정도가 1차 기준으로 적당하다. safe 95% 이상은 너무 쉽고, balanced 20% 이하는 너무 가파르다.

## Next Balance Actions

1. 적 HP를 문서 목표까지 일괄 상향하지 말고, Act 1 보스/Act 2 이후 단일 적/후반 보스부터 단계적으로 올린다.
2. safe 경로가 너무 안정적이므로 여관/이벤트/상점 경제와 안전 경로 보상을 함께 조정한다.
3. 엘리트는 패배율보다 보상 차별화가 먼저 문제다. 엘리트 전용 강화 보상을 실제 구현하고, 그 뒤 위험도를 다시 측정한다.
4. 업그레이드가 `first unupgraded`인 현재 구현은 플레이어 선택감을 죽이고 시뮬레이션도 왜곡하므로, 카드 선택형 업그레이드 UI/로직으로 바꾼다.
5. Road Cleave / Breakthrough / Sweeping Order 쏠림을 낮추고, Contract Mark / Oath Focus / Risk Advance / Field Medicine 계열의 선택 이유를 강화한다.

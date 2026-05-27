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
| novice | current | 600 | 65.7% | 26.3% | 26.3% | 2.5% | 43/69% | 47/50/48% | 6532/1170/184 | 24.8 | 0.6 | 170.7 | 36.1 | 10.7 | 0.6 | 1.1 | 1.1 | 2.2 | 23.0 |
| balanced | current | 600 | 88.7% | 72.2% | 72.2% | 12.8% | 29/57% | 67/64/53% | 9862/1859/603 | 25.3 | 3.1 | 177.8 | 69.5 | 8.8 | 9.1 | 1.4 | 2.0 | 3.6 | 51.5 |
| safe | current | 600 | 91.5% | 67.3% | 67.3% | 13.5% | 34/79% | 63/88/78% | 6303/1582/934 | 20.9 | 3.8 | 428.4 | 62.0 | 7.1 | 5.0 | 2.7 | 0.0 | 4.3 | 40.8 |
| greedy | current | 600 | 93.2% | 72.3% | 72.2% | 11.0% | 36/68% | 69/70/64% | 10014/1810/686 | 23.8 | 3.0 | 167.2 | 68.8 | 7.5 | 10.7 | 1.3 | 1.9 | 3.4 | 51.8 |

## Key Findings

- 신규 플레이어에 가까운 novice 자동 정책은 Act 1 보스 65.7%, Act 2 보스 26.3%, 최종 승리 2.5%다. 사람의 실수와 학습 비용은 더 크므로, 이 값은 신규 목표의 상한선으로 본다.
- 현재 구현 데이터는 경로 성향에 따라 크게 갈린다. balanced 12.8%, safe 13.5%, greedy 11.0%다.
- 웨이브 노드는 1웨이브보다 긴 턴 수를 만들지만 즉시 동시 공격 압박은 낮춘다. 2웨이브는 리듬 변화, 3웨이브는 기억나는 세트피스로 보고 빈도를 먼저 관리한다.
- 이번 패치는 보스 HP만 올리는 방향을 피하고, 일반/엘리트의 공격 의도와 회복 경제를 조정해 길 위에서 체력이 점진적으로 깎이는 곡선을 만든다.
- safe 정책은 체력을 보존하지만 덱 품질과 최종 화력이 약해지도록 두고, greedy 정책은 강한 덱을 만들 수 있지만 여관 진입 체력이 낮아지는 구조로 본다.

## Target Bands

| Target profile | Act 1 boss clear | Act 2 boss clear | Act 3 reach | Act 3 boss clear | Use |
| --- | ---: | ---: | ---: | ---: | --- |
| Early general player | 65-75% | 25-35% | 12-18% | 6-10% | 신규/초기 런 체감 목표. 자동 러너와 직접 비교하지 않는다. |
| Current hard-mode runner | novice 55-70%, skilled routes 85-95% | skilled routes 60-75% | skilled routes 60-75% | greedy 8-12%, safe 12-18% | 이번 패치의 자동 러너 기준. Act 3 진입은 비교적 잦지만 최종 클리어는 Act 3 노드/보스에서 걸러지도록 본다. |

Steam achievements show many lifetime players eventually beat at least one character, while high Ascension completion is much rarer. 그래서 기본 난이도의 장기 목표와 신규/초기 플레이어 목표를 분리하고, 현재 자동 러너는 사용자가 지정한 hard-mode 체감 목표를 우선한다.

체력 곡선은 별도 목표로 본다. 평균 여관 진입 체력은 35-60% 사이, 여관 퇴장 체력은 60-85% 사이가 좋다. 보스 진입 체력은 Act 1 55-80%, Act 2 45-75%, Act 3 40-70%를 1차 목표로 둔다. 이 값이 높게 고정되면 경로 선택의 긴장이 약하고, 너무 낮으면 여관을 못 찾은 런이 즉사한다.

## Combat Pressure

### novice / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 5227 | 3.52 | 5 | 7.6 | 16 | 3.9% |
| Act 2 | 2005 | 3.58 | 6 | 5.3 | 13 | 11.4% |
| Act 3 | 654 | 4.29 | 7 | 7.6 | 19 | 21.3% |
| boss | 782 | 4.83 | 6 | 17.4 | 30 | 27.5% |
| combat | 5434 | 3.29 | 5 | 5.8 | 14 | 5.6% |
| elite | 1070 | 3.90 | 5 | 7.6 | 15 | 5.0% |
| midboss | 600 | 4.28 | 5 | 3.3 | 9 | 0.0% |
| 1-wave | 6532 | 3.36 | 5 | 6.8 | 15 | 6.4% |
| 2-wave | 1170 | 4.48 | 6 | 7.6 | 15 | 8.4% |
| 3-wave | 184 | 6.54 | 9 | 10.1 | 22 | 28.3% |

Top deaths: A1D12 Gate Warlord 154, A2D12 Oathless Regent 39, A1D11 Castle Ditch 34, A2D2 Broken Milestone 29, A2D1 Split Causeway 23

### balanced / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 6104 | 3.92 | 6 | 4.4 | 13 | 1.1% |
| Act 2 | 3837 | 3.79 | 6 | 4.6 | 14 | 2.6% |
| Act 3 | 2383 | 4.52 | 8 | 6.4 | 18 | 14.8% |
| boss | 1186 | 5.56 | 7 | 18.2 | 31 | 12.1% |
| combat | 8501 | 3.70 | 6 | 3.2 | 10 | 4.4% |
| elite | 2037 | 4.18 | 5 | 4.7 | 13 | 0.0% |
| midboss | 600 | 4.49 | 6 | 2.3 | 8 | 0.0% |
| 1-wave | 9862 | 3.62 | 6 | 4.7 | 15 | 2.7% |
| 2-wave | 1859 | 4.98 | 6 | 4.4 | 12 | 5.8% |
| 3-wave | 603 | 7.12 | 10 | 8.2 | 20 | 24.0% |

Top deaths: win 77, A1D12 Gate Warlord 66, A3D12 Unbound Core 66, A3D7 Room Vein 61, A3D10 Core Approach 55

### safe / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 4833 | 3.70 | 5 | 4.9 | 15 | 1.1% |
| Act 2 | 2272 | 4.55 | 7 | 7.1 | 20 | 6.3% |
| Act 3 | 1714 | 5.42 | 9 | 8.4 | 20 | 18.7% |
| boss | 1105 | 5.39 | 7 | 20.0 | 34 | 6.4% |
| combat | 5939 | 4.11 | 7 | 4.1 | 12 | 7.5% |
| elite | 1175 | 3.99 | 5 | 5.2 | 14 | 0.1% |
| midboss | 600 | 4.13 | 5 | 2.1 | 9 | 0.0% |
| 1-wave | 6303 | 3.67 | 5 | 5.9 | 19 | 1.8% |
| 2-wave | 1582 | 5.01 | 6 | 5.1 | 13 | 12.0% |
| 3-wave | 934 | 6.92 | 10 | 9.0 | 20 | 22.9% |

Top deaths: A3D7 Room Vein 108, A3D10 Core Approach 104, A2D4 Witness Road 82, win 81, A3D9 Core Echo 69

### greedy / current

| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Act 1 | 6406 | 3.78 | 5 | 5.0 | 15 | 0.6% |
| Act 2 | 3847 | 3.90 | 7 | 6.0 | 18 | 3.2% |
| Act 3 | 2257 | 4.60 | 8 | 7.1 | 18 | 16.0% |
| boss | 1162 | 5.69 | 7 | 21.9 | 37 | 8.9% |
| combat | 8851 | 3.67 | 6 | 3.6 | 11 | 4.8% |
| elite | 1897 | 4.14 | 5 | 6.2 | 15 | 0.0% |
| midboss | 600 | 4.43 | 6 | 2.9 | 9 | 0.0% |
| 1-wave | 10014 | 3.57 | 5 | 5.4 | 17 | 2.3% |
| 2-wave | 1810 | 4.98 | 6 | 5.7 | 14 | 6.5% |
| 3-wave | 686 | 7.08 | 10 | 9.0 | 19 | 25.9% |

Top deaths: A3D7 Room Vein 74, win 66, A3D10 Core Approach 63, A3D9 Core Echo 51, A2D10 Causeway Toll 42


## Card Balance Signals

기준 표본: `balanced / current`

### High Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Oath Focus | power | 1 | 581 | 473 | 81.4% | 2284 | 13.8 |
| Sweeping Order | attack | 3 | 1373 | 1082 | 78.8% | 7980 | 12.8 |
| Wide Swing | attack | 2 | 2727 | 1629 | 59.7% | 13789 | 10.3 |
| Heavy Cut | attack | 2 | 2805 | 1103 | 39.3% | 5875 | 17.3 |
| Breakthrough | attack | 3 | 1432 | 485 | 33.9% | 1642 | 19.4 |
| Marked Riposte | skill | 1 | 2666 | 866 | 32.5% | 6027 | 10.1 |
| Road Cleave | attack | 3 | 2769 | 830 | 30.0% | 4530 | 19.2 |
| Quick Step | skill | 1 | 2843 | 617 | 21.7% | 5309 | 10.5 |
| Desperate Stand | skill | 3 | 585 | 105 | 17.9% | 1173 | 21.5 |
| Contract Mark | skill | 1 | 2849 | 315 | 11.1% | 983 | 10.5 |

### Low Pick

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Blood Price | skill | 0 | 1364 | 5 | 0.4% | 49 | 10.0 |
| Clean Cut | attack | 1 | 2791 | 81 | 2.9% | 686 | 13.1 |
| Field Medicine | skill | 2 | 1354 | 41 | 3.0% | 450 | 13.3 |
| Brace | skill | 2 | 2798 | 159 | 5.7% | 742 | 13.5 |
| Last Light | skill | 3 | 590 | 42 | 7.1% | 503 | 16.6 |
| Shield Line | skill | 2 | 1338 | 97 | 7.2% | 957 | 14.5 |
| Risk Advance | skill | 0 | 1424 | 104 | 7.3% | 743 | 7.5 |
| Contract Mark | skill | 1 | 2849 | 315 | 11.1% | 983 | 10.5 |
| Desperate Stand | skill | 3 | 585 | 105 | 17.9% | 1173 | 21.5 |
| Quick Step | skill | 1 | 2843 | 617 | 21.7% | 5309 | 10.5 |

### High Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Debt Cleave | attack | 3 | 0 | 315 | 0.0% | 3707 | 21.8 |
| Desperate Stand | skill | 3 | 585 | 105 | 17.9% | 1173 | 21.5 |
| Breakthrough | attack | 3 | 1432 | 485 | 33.9% | 1642 | 19.4 |
| Road Cleave | attack | 3 | 2769 | 830 | 30.0% | 4530 | 19.2 |
| Spear Finish | attack | 3 | 0 | 152 | 0.0% | 725 | 19.2 |
| Heavy Cut | attack | 2 | 2805 | 1103 | 39.3% | 5875 | 17.3 |
| Back Cut | attack | 2 | 0 | 228 | 0.0% | 674 | 17.0 |
| Pinning Thrust | attack | 2 | 0 | 254 | 0.0% | 782 | 16.7 |
| Broadhead | attack | 2 | 0 | 146 | 0.0% | 458 | 16.7 |
| Last Light | skill | 3 | 590 | 42 | 7.1% | 503 | 16.6 |

### Low Output

| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Guard | skill | 1 | 0 | 0 | 0.0% | 25049 | 5.3 |
| Tactical Prep | skill | 0 | 0 | 0 | 0.0% | 14351 | 7.2 |
| Knife Feint | skill | 0 | 0 | 137 | 0.0% | 1355 | 7.4 |
| Risk Advance | skill | 0 | 1424 | 104 | 7.3% | 743 | 7.5 |
| Smoke Pocket | skill | 1 | 0 | 112 | 0.0% | 711 | 8.6 |
| Snare Line | skill | 1 | 0 | 146 | 0.0% | 354 | 9.6 |
| Strike | attack | 1 | 0 | 0 | 0.0% | 27696 | 10.0 |
| Marked Riposte | skill | 1 | 2666 | 866 | 32.5% | 6027 | 10.1 |
| Red Banner | skill | 1 | 0 | 165 | 0.0% | 939 | 10.1 |
| Wide Swing | attack | 2 | 2727 | 1629 | 59.7% | 13789 | 10.3 |

## Reading

- 낮은 픽률 카드는 보상 후보를 흐리는 카드다. 높은 출력 카드는 코스트 대비 과한지 실제 카드 텍스트를 따로 검토한다.
- 현재 자동 정책은 공격적으로 강한 카드를 선호하므로, 방어/유틸 카드의 실제 인간 가치가 과소평가될 수 있다. 그래도 0%에 가까운 픽률은 경고로 본다.
- 이번 기준 승률은 자동 러너 기준 greedy 8~12%, safe 12~18%를 우선한다. greedy가 5% 아래면 위험 보상이 부족하고, safe가 20%를 넘으면 체력 보존 루트가 지나치게 안정적이다.

## Next Balance Actions

1. 적 HP를 문서 목표까지 일괄 상향하지 말고, Act 1 보스/Act 2 이후 단일 적/후반 보스부터 단계적으로 올린다.
2. safe 경로가 너무 안정적이므로 여관/이벤트/상점 경제와 안전 경로 보상을 함께 조정한다.
3. 엘리트는 패배율보다 보상 차별화가 먼저 문제다. 엘리트 전용 강화 보상을 실제 구현하고, 그 뒤 위험도를 다시 측정한다.
4. 업그레이드가 `first unupgraded`인 현재 구현은 플레이어 선택감을 죽이고 시뮬레이션도 왜곡하므로, 카드 선택형 업그레이드 UI/로직으로 바꾼다.
5. Road Cleave / Breakthrough / Sweeping Order 쏠림을 낮추고, Contract Mark / Oath Focus / Risk Advance / Field Medicine 계열의 선택 이유를 강화한다.

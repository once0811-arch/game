#!/usr/bin/env python3
"""Monte Carlo run simulator for the Godot deckbuilder balance pass.

This intentionally models the current JSON/GDScript gameplay rules closely enough
for tuning signals: combat, map pathing, rewards, companion recruitment, bond,
card upgrades, equipment, shops, inns, events, and enemy HP/attack profiles.
"""
from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ROOT = Path.cwd() if (Path.cwd() / "SourceCode").exists() else Path(__file__).resolve().parents[1]
SOURCE = ROOT / "SourceCode"

TARGET_HP_MIDPOINTS = {
    (1, "combat_early"): (40 + 74) / 2,
    (1, "combat_late"): (64 + 101) / 2,
    (1, "elite"): (101 + 143) / 2,
    (1, "midboss"): (85 + 111) / 2,
    (1, "boss"): (233 + 286) / 2,
    (2, "combat"): (117 + 186) / 2,
    (2, "elite"): (201 + 286) / 2,
    (2, "boss"): (350 + 445) / 2,
    (3, "combat"): (180 + 276) / 2,
    (3, "elite"): (297 + 392) / 2,
    (3, "boss"): (477 + 572) / 2,
}

CARD_RARITY_WEIGHTS = {"common": 70, "uncommon": 25, "rare": 5}
BOND_GAINS = {"combat": 4, "elite": 7, "midboss": 8, "boss": 12, "combat_fallback": 3}
STARTER_IDS: set[str] = set()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def mean(values: list[float]) -> float:
    return statistics.mean(values) if values else 0.0


def percentile(values: list[float], ratio: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = max(0, min(len(ordered) - 1, math.ceil(len(ordered) * ratio) - 1))
    return float(ordered[index])


@dataclass
class CardInstance:
    card_id: str
    upgraded: bool = False


@dataclass
class CompanionState:
    companion_id: str
    name: str
    oath_id: str
    bond: int = 0
    attack_bonus: int = 0
    wager_wins: int = 0


@dataclass
class EquipmentInstance:
    equipment_id: str
    instance_id: int


@dataclass
class RunState:
    rng: random.Random
    max_hp: int = 76
    hp: int = 76
    gold: int = 99
    act: int = 1
    deck: list[CardInstance] = field(default_factory=list)
    companions: list[CompanionState] = field(default_factory=list)
    equipment: list[EquipmentInstance] = field(default_factory=list)
    equipped: dict[str, dict[str, int]] = field(default_factory=dict)
    next_equipment_id: int = 1
    remove_count: int = 0
    protagonist_upgrade_level: int = 0
    stats: dict[str, Any] = field(default_factory=lambda: defaultdict(int))
    card_stats: dict[str, Counter] = field(default_factory=lambda: defaultdict(Counter))
    combat_summaries: list[dict[str, Any]] = field(default_factory=list)
    node_history: list[dict[str, Any]] = field(default_factory=list)


class BalanceSimulator:
    def __init__(self, root: Path):
        self.root = root
        self.source = root / "SourceCode"
        self.balance = load_json(self.source / "data/balance_constants.json")
        self.cards, self.starter_deck = self._load_cards()
        self.companions = self._load_index("data/companions/companions.json", "companions")
        self.enemies = self._load_enemies()
        self.equipment = self._load_index("data/equipment/equipment.json", "equipment")
        self.events = self._load_events()
        self.maps = {act: self._load_map(act) for act in (1, 2, 3)}
        global STARTER_IDS
        STARTER_IDS = set(self.starter_deck)

    def _load_cards(self) -> tuple[dict[str, dict[str, Any]], list[str]]:
        protagonist = load_json(self.source / "data/cards/protagonist_cards.json")
        companion_cards = load_json(self.source / "data/cards/companion_cards.json")
        cards = {card["id"]: card for card in protagonist.get("cards", [])}
        for card in companion_cards.get("cards", []):
            cards[card["id"]] = card
        return cards, [str(card_id) for card_id in protagonist.get("starting_deck", [])]

    def _load_index(self, rel: str, key: str) -> dict[str, dict[str, Any]]:
        data = load_json(self.source / rel)
        return {str(item["id"]): item for item in data.get(key, [])}

    def _load_enemies(self) -> dict[str, dict[str, Any]]:
        enemies: dict[str, dict[str, Any]] = {}
        for act in (1, 2, 3):
            data = load_json(self.source / f"data/enemies/enemies_act{act}.json")
            for enemy in data.get("enemies", []):
                enemies[str(enemy["id"])] = enemy
        # Some older boss data exists separately; keep it available if referenced later.
        boss_path = self.source / "data/bosses/bosses.json"
        if boss_path.exists():
            for boss in load_json(boss_path).get("bosses", []):
                enemies.setdefault(str(boss["id"]), boss)
        return enemies

    def _load_events(self) -> list[dict[str, Any]]:
        result: list[dict[str, Any]] = []
        for path in sorted((self.source / "data/events").glob("events_act*.json")):
            result.extend(load_json(path).get("events", []))
        return result

    def _load_map(self, act: int) -> list[dict[str, Any]]:
        data = load_json(self.source / f"data/encounters/act{act}_encounters.json")
        nodes: list[dict[str, Any]] = []
        lane_counts: dict[int, int] = defaultdict(int)
        for raw in data.get("nodes", []):
            node = dict(raw)
            depth = int(node.get("depth", len(nodes) + 1))
            lane_count = lane_counts[depth]
            lane_counts[depth] += 1
            lane = int(node.get("lane", lane_count))
            node["depth"] = depth
            node["lane"] = lane
            node["act"] = act
            node["id"] = f"act{act}_depth_{depth:02d}_lane_{lane}"
            node["next_ids"] = []
            nodes.append(node)
        nodes.sort(key=lambda n: (int(n["depth"]), int(n["lane"])))
        by_depth: dict[int, list[dict[str, Any]]] = defaultdict(list)
        for node in nodes:
            by_depth[int(node["depth"])].append(node)
        for depth in range(1, 12):
            for node in by_depth.get(depth, []):
                node["next_ids"] = self._pick_next_ids(node, by_depth.get(depth + 1, []))
        return nodes

    def _pick_next_ids(self, node: dict[str, Any], next_nodes: list[dict[str, Any]]) -> list[str]:
        if len(next_nodes) <= 1:
            return [str(candidate["id"]) for candidate in next_nodes]
        lane = int(node.get("lane", 1))
        next_ids: list[str] = []
        self._add_next_if_lane_exists(next_ids, next_nodes, lane)
        branch_lane = lane + (1 if (int(node.get("depth", 0)) + lane) % 2 == 0 else -1)
        if not self._add_next_if_lane_exists(next_ids, next_nodes, branch_lane):
            if not self._add_next_if_lane_exists(next_ids, next_nodes, lane + 1):
                self._add_next_if_lane_exists(next_ids, next_nodes, lane - 1)
        return next_ids

    @staticmethod
    def _add_next_if_lane_exists(next_ids: list[str], next_nodes: list[dict[str, Any]], lane: int) -> bool:
        for candidate in next_nodes:
            if int(candidate.get("lane", 0)) == lane:
                node_id = str(candidate.get("id", ""))
                if node_id and node_id not in next_ids:
                    next_ids.append(node_id)
                return True
        return False

    def simulate_many(self, runs: int, policy: str, enemy_profile: str, seed: int) -> dict[str, Any]:
        aggregate = AggregateStats(policy=policy, enemy_profile=enemy_profile)
        for run_index in range(runs):
            state = self._new_run(random.Random(seed + run_index * 7919))
            result = self.simulate_run(state, policy, enemy_profile)
            aggregate.add_run(result, state)
        return aggregate.to_report()

    def _new_run(self, rng: random.Random) -> RunState:
        max_hp = int(self.balance.get("run", {}).get("starting_max_hp", 76))
        state = RunState(rng=rng, max_hp=max_hp, hp=max_hp, gold=int(self.balance.get("run", {}).get("starting_gold", 99)))
        state.deck = [CardInstance(card_id) for card_id in self.starter_deck]
        return state

    def simulate_run(self, state: RunState, policy: str, enemy_profile: str) -> dict[str, Any]:
        previous_node_id = ""
        for act in (1, 2, 3):
            state.act = act
            nodes = self.maps[act]
            completed_by_depth: dict[int, str] = {}
            for depth in range(1, 13):
                available = self._available_nodes(nodes, depth, previous_node_id)
                if not available:
                    available = [node for node in nodes if int(node["depth"]) == depth]
                node = self._choose_node(state, available, policy)
                previous_node_id = str(node["id"])
                completed_by_depth[depth] = previous_node_id
                hp_before = state.hp
                max_hp_before = state.max_hp
                node_result = self._process_node(state, node, policy, enemy_profile)
                state.node_history.append({
                    "act": act,
                    "depth": depth,
                    "type": node.get("type"),
                    "label": node.get("label"),
                    "hp_before": hp_before,
                    "hp_after": state.hp,
                    "max_hp_before": max_hp_before,
                    "max_hp_after": state.max_hp,
                    **node_result,
                })
                if state.hp <= 0 or node_result.get("defeat"):
                    return {"won": False, "death_act": act, "death_depth": depth, "death_node": node.get("label", "?")}
                if str(node.get("type")) == "boss":
                    if act == 1:
                        self._recruit_companion(state, policy)
                    elif act == 2:
                        self._apply_major_upgrade(state, policy)
                    else:
                        return {"won": True, "death_act": 0, "death_depth": 0, "death_node": ""}
                    break
        return {"won": False, "death_act": state.act, "death_depth": 12, "death_node": "no_ending"}

    def _available_nodes(self, nodes: list[dict[str, Any]], depth: int, previous_node_id: str) -> list[dict[str, Any]]:
        candidates = [node for node in nodes if int(node["depth"]) == depth]
        if depth <= 1 or not previous_node_id:
            return candidates
        previous = next((node for node in nodes if str(node["id"]) == previous_node_id), None)
        if not previous:
            return candidates
        next_ids = set(map(str, previous.get("next_ids", [])))
        return [node for node in candidates if str(node["id"]) in next_ids]

    def _choose_node(self, state: RunState, nodes: list[dict[str, Any]], policy: str) -> dict[str, Any]:
        scored = [(self._node_score(state, node, policy) + state.rng.uniform(-0.7, 0.7), node) for node in nodes]
        scored.sort(key=lambda item: item[0], reverse=True)
        if policy == "novice" and len(scored) > 1 and state.rng.random() < 0.35:
            return scored[min(len(scored) - 1, state.rng.randint(1, 2))][1]
        return scored[0][1]

    def _node_score(self, state: RunState, node: dict[str, Any], policy: str) -> float:
        node_type = str(node.get("type", "combat"))
        hp_ratio = state.hp / max(1, state.max_hp)
        missing_hp = state.max_hp - state.hp
        base = {
            "combat": 10,
            "elite": 14,
            "midboss": 100,
            "boss": 100,
            "companion_contract": 100,
            "upgrade": 100,
            "event": 9,
            "shop": 8,
            "inn": 4 + missing_hp / 7,
            "treasure": 11,
        }.get(node_type, 7)
        if policy == "safe":
            if node_type == "elite":
                base -= 6 if hp_ratio < 0.75 else 2
            if node_type == "inn":
                base += 5 if hp_ratio < 0.75 else 0
            if node_type == "event":
                base += 2
        elif policy == "greedy":
            if node_type == "elite":
                base += 6 if hp_ratio > 0.45 else -8
            if node_type == "combat":
                base += 2
            if node_type == "inn":
                base -= 2 if hp_ratio > 0.35 else 0
        else:
            if node_type == "elite" and hp_ratio < 0.55:
                base -= 8
            if node_type == "shop" and state.gold >= 120:
                base += 3
        return base

    def _process_node(self, state: RunState, node: dict[str, Any], policy: str, enemy_profile: str) -> dict[str, Any]:
        node_type = str(node.get("type", ""))
        if node_type in {"combat", "elite", "midboss", "boss"}:
            combat = self._simulate_combat(state, node, policy, enemy_profile)
            if combat["outcome"] == "defeat":
                return {"defeat": True, **combat}
            if node_type == "boss":
                state.stats[f"boss_clear_act_{int(node.get('act', state.act))}"] += 1
            self._grant_combat_rewards(state, node_type)
            if node_type != "boss":
                self._card_reward(state, policy, source=node_type)
            return combat
        if node_type == "companion_contract":
            self._recruit_companion(state, policy)
            return {"defeat": False}
        if node_type == "upgrade":
            self._apply_minor_upgrade(state, policy)
            return {"defeat": False}
        if node_type == "shop":
            self._visit_shop(state, policy)
            return {"defeat": False}
        if node_type == "inn":
            self._visit_inn(state, policy)
            return {"defeat": False}
        if node_type == "event":
            self._resolve_event(state, policy)
            return {"defeat": False}
        return {"defeat": False}

    def _grant_combat_rewards(self, state: RunState, node_type: str) -> None:
        gold_table = self.balance.get("rewards", {}).get("gold_by_node_type", {})
        state.gold += int(gold_table.get(node_type, 0))
        state.stats[f"gold_from_{node_type}"] += int(gold_table.get(node_type, 0))
        if state.companions:
            gain = int(BOND_GAINS.get(node_type, BOND_GAINS["combat"]))
            for companion in state.companions:
                before = companion.bond
                companion.bond = min(100, companion.bond + gain)
                state.stats["bond_gained"] += companion.bond - before
                self._award_kyle_wager(state, companion)

    def _award_kyle_wager(self, state: RunState, companion: CompanionState) -> None:
        if companion.companion_id != "kyle" or not companion.oath_id.startswith("kyle_"):
            return
        steps = 2 if companion.oath_id == "kyle_clean_exit" and state.hp * 100 >= state.max_hp * 70 else 1
        companion.wager_wins += steps
        while companion.wager_wins >= 5:
            companion.wager_wins -= 5
            roll = state.rng.randint(1, 100)
            if companion.oath_id == "kyle_loaded_coin":
                if roll <= 55:
                    state.gold += 8
                elif roll <= 80:
                    state.hp = min(state.max_hp, state.hp + 4)
                elif roll <= 97:
                    state.gold += 35
                else:
                    state.gold += 130
            else:
                if roll <= 45:
                    state.gold += 18
                elif roll <= 70:
                    state.hp = min(state.max_hp, state.hp + 5)
                elif roll <= 92:
                    if not self._upgrade_first_unupgraded(state):
                        state.gold += 20
                else:
                    state.gold += 70
            state.stats["kyle_payouts"] += 1

    def _enemy_ids_for_node(self, node: dict[str, Any]) -> list[str]:
        if "enemy_ids" in node:
            return [str(enemy_id) for enemy_id in node.get("enemy_ids", [])]
        enemy_id = str(node.get("enemy_id", ""))
        return [enemy_id] if enemy_id else []

    def _node_target_key(self, node: dict[str, Any]) -> tuple[int, str] | None:
        act = int(node.get("act", 1))
        node_type = str(node.get("type", "combat"))
        if node_type == "combat":
            if act == 1:
                return (1, "combat_early" if int(node.get("depth", 1)) <= 5 else "combat_late")
            return (act, "combat")
        if node_type == "elite":
            return (act, "elite")
        if node_type == "midboss":
            return (1, "midboss")
        if node_type == "boss":
            return (act, "boss")
        return None

    def _enemy_scales(self, node: dict[str, Any], enemy_profile: str, enemy_ids: list[str]) -> tuple[float, float]:
        hp_scale = 1.0
        attack_scale = 1.0
        if enemy_profile == "plus6":
            hp_scale = 1.06
        elif enemy_profile in {"spec_mid", "spec_mid_attack10"}:
            key = self._node_target_key(node)
            base_total = sum(int(self.enemies[eid].get("max_hp", 1)) for eid in enemy_ids if eid in self.enemies)
            if key in TARGET_HP_MIDPOINTS and base_total > 0:
                hp_scale = TARGET_HP_MIDPOINTS[key] / base_total
            if enemy_profile == "spec_mid_attack10":
                attack_scale = 1.10
        return hp_scale, attack_scale

    def _simulate_combat(self, state: RunState, node: dict[str, Any], policy: str, enemy_profile: str) -> dict[str, Any]:
        enemy_ids = self._enemy_ids_for_node(node)
        hp_scale, attack_scale = self._enemy_scales(node, enemy_profile, enemy_ids)
        enemies = []
        for enemy_id in enemy_ids:
            data = self.enemies.get(enemy_id)
            if not data:
                continue
            enemies.append({
                "id": enemy_id,
                "name": data.get("name", enemy_id),
                "max_hp": int(math.ceil(int(data.get("max_hp", 1)) * hp_scale)),
                "hp": int(math.ceil(int(data.get("max_hp", 1)) * hp_scale)),
                "block": 0,
                "mark": 0,
                "intents": data.get("intents", []) or [{"type": "attack", "damage": 5, "label": "Attack"}],
                "intent_index": 0,
            })
        combat = {
            "hp": state.hp,
            "max_hp": state.max_hp,
            "block": self._equipment_bonus(state, "start_block") + self._bond_start_block(state),
            "energy": int(self.balance.get("combat", {}).get("energy_per_turn", 4)),
            "healing_down_turns": 0,
            "healing_down_percent": 0,
            "enemy_attack_reduction": 0,
            "turn": 1,
            "cards_played_this_turn": 0,
            "oath_flags": {},
            "attack_scale": attack_scale,
            "tactical_mark_bonus": 0,
        }
        draw_pile = state.deck[:]
        discard_pile: list[CardInstance] = []
        hand: list[CardInstance] = []
        state.rng.shuffle(draw_pile)
        self._draw_cards(state, draw_pile, discard_pile, hand, 6)
        self._apply_combat_start_oaths(state, combat, draw_pile, discard_pile, hand)
        start_hp = state.hp
        total_cards_played = 0
        for turn in range(1, 41):
            combat["turn"] = turn
            combat["energy"] = int(self.balance.get("combat", {}).get("energy_per_turn", 4))
            combat["cards_played_this_turn"] = 0
            if turn > 1:
                combat["block"] = self._bond_start_block(state)
            played = self._play_player_turn(state, combat, enemies, draw_pile, discard_pile, hand, policy)
            total_cards_played += played
            if not self._alive_indices(enemies):
                state.hp = combat["hp"]
                return self._combat_result(state, node, "victory", turn, start_hp, total_cards_played, hp_scale, attack_scale)
            self._companion_attacks(state, combat, enemies)
            if not self._alive_indices(enemies):
                state.hp = combat["hp"]
                return self._combat_result(state, node, "victory", turn, start_hp, total_cards_played, hp_scale, attack_scale)
            self._enemy_turn(state, combat, enemies)
            if combat["hp"] <= 0:
                state.hp = 0
                return self._combat_result(state, node, "defeat", turn, start_hp, total_cards_played, hp_scale, attack_scale)
            if combat["healing_down_turns"] > 0:
                combat["healing_down_turns"] -= 1
                if combat["healing_down_turns"] <= 0:
                    combat["healing_down_percent"] = 0
            discard_pile.extend(hand)
            hand.clear()
            self._draw_cards(state, draw_pile, discard_pile, hand, 6)
        state.hp = combat["hp"]
        return self._combat_result(state, node, "timeout", 40, start_hp, total_cards_played, hp_scale, attack_scale)

    def _combat_result(self, state: RunState, node: dict[str, Any], outcome: str, turns: int, start_hp: int, cards_played: int, hp_scale: float, attack_scale: float) -> dict[str, Any]:
        result = {
            "outcome": outcome,
            "defeat": outcome != "victory",
            "turns": turns,
            "hp_lost": max(0, start_hp - state.hp),
            "cards_played": cards_played,
            "hp_scale": hp_scale,
            "attack_scale": attack_scale,
            "act": int(node.get("act", state.act)),
            "depth": int(node.get("depth", 0)),
            "node_type": str(node.get("type", "")),
            "node_label": str(node.get("label", "")),
        }
        state.combat_summaries.append(result)
        state.stats["combats"] += 1
        state.stats[f"combats_{outcome}"] += 1
        state.stats["combat_turns"] += turns
        state.stats["combat_hp_lost"] += result["hp_lost"]
        return result

    def _draw_cards(self, state: RunState, draw_pile: list[CardInstance], discard_pile: list[CardInstance], hand: list[CardInstance], count: int) -> int:
        drawn = 0
        for _ in range(count):
            if not draw_pile:
                if not discard_pile:
                    break
                draw_pile.extend(discard_pile)
                discard_pile.clear()
                state.rng.shuffle(draw_pile)
            if not draw_pile:
                break
            hand.append(draw_pile.pop())
            drawn += 1
        return drawn

    def _alive_indices(self, enemies: list[dict[str, Any]]) -> list[int]:
        return [i for i, enemy in enumerate(enemies) if int(enemy.get("hp", 0)) > 0]

    def _incoming_damage(self, combat: dict[str, Any], enemies: list[dict[str, Any]]) -> int:
        total = 0
        for enemy in enemies:
            if int(enemy.get("hp", 0)) <= 0:
                continue
            intent = self._enemy_intent(enemy)
            if str(intent.get("type", "attack")) == "attack":
                total += max(int(round(int(intent.get("damage", 0)) * combat.get("attack_scale", 1.0))) - int(combat.get("enemy_attack_reduction", 0)), 0)
        return total

    def _enemy_intent(self, enemy: dict[str, Any]) -> dict[str, Any]:
        intents = enemy.get("intents", [])
        if not intents:
            return {"type": "attack", "damage": 5, "label": "Attack"}
        return intents[int(enemy.get("intent_index", 0)) % len(intents)]

    def _best_target_index(self, enemies: list[dict[str, Any]], preferred: int | None = None) -> int | None:
        live = self._alive_indices(enemies)
        if not live:
            return None
        if preferred is not None and preferred in live:
            return preferred
        best_index = live[0]
        best_key = (-999, -999, 9999)
        for index in live:
            enemy = enemies[index]
            intent = self._enemy_intent(enemy)
            key = (int(enemy.get("mark", 0)), 1 if intent.get("type") == "attack" else 0, -int(enemy.get("hp", 0)))
            if key > best_key:
                best_key = key
                best_index = index
        return best_index

    def _play_player_turn(self, state: RunState, combat: dict[str, Any], enemies: list[dict[str, Any]], draw_pile: list[CardInstance], discard_pile: list[CardInstance], hand: list[CardInstance], policy: str) -> int:
        played = 0
        safety = 0
        while hand and self._alive_indices(enemies) and safety < 40:
            safety += 1
            affordable = [(idx, inst, self.cards[inst.card_id]) for idx, inst in enumerate(hand) if self._card_cost(self.cards[inst.card_id]) <= int(combat.get("energy", 0))]
            if not affordable:
                break
            incoming = self._incoming_damage(combat, enemies)
            need_block = max(0, incoming - int(combat.get("block", 0)))
            choice = self._choose_card_to_play(affordable, enemies, need_block, policy)
            if choice is None:
                break
            hand_index, instance, card = choice
            hand.pop(hand_index)
            combat["energy"] -= self._card_cost(card)
            combat["cards_played_this_turn"] += 1
            target = self._best_target_index(enemies)
            metrics = self._apply_card_effects(state, combat, enemies, card, instance, target, draw_pile, discard_pile, hand)
            discard_pile.append(instance)
            played += 1
            self._record_card_play(state, instance.card_id, metrics)
            self._apply_card_play_oaths(state, combat, enemies, card, target, draw_pile, discard_pile, hand)
        return played

    def _choose_card_to_play(self, affordable: list[tuple[int, CardInstance, dict[str, Any]]], enemies: list[dict[str, Any]], need_block: int, policy: str) -> tuple[int, CardInstance, dict[str, Any]] | None:
        target = self._best_target_index(enemies)
        lethal: list[tuple[int, CardInstance, dict[str, Any]]] = []
        if target is not None:
            for item in affordable:
                _, inst, card = item
                dmg, aoe, *_ = self._card_effect_values(card, inst.upgraded)
                if dmg + int(enemies[target].get("mark", 0)) >= int(enemies[target].get("hp", 0)):
                    lethal.append(item)
                elif aoe and all(enemy["hp"] <= 0 or aoe + int(enemy.get("mark", 0)) >= enemy["hp"] for enemy in enemies):
                    lethal.append(item)
        if lethal:
            return max(lethal, key=lambda item: self._card_tactical_value(item[2], item[1].upgraded))
        zero_utility = [item for item in affordable if self._card_cost(item[2]) == 0 and self._has_any_effect(item[2], {"draw", "gain_energy"})]
        if zero_utility:
            return max(zero_utility, key=lambda item: self._card_tactical_value(item[2], item[1].upgraded))
        if policy == "novice" and need_block < 8:
            attacks = [item for item in affordable if self._has_any_effect(item[2], {"damage", "damage_all", "tactical_mark"})]
            if attacks:
                return max(attacks, key=lambda item: self._card_tactical_value(item[2], item[1].upgraded))
        if need_block > 0:
            blockers = [item for item in affordable if self._has_any_effect(item[2], {"block", "heal"})]
            if blockers:
                return max(blockers, key=lambda item: (self._card_effect_values(item[2], item[1].upgraded)[2], self._card_tactical_value(item[2], item[1].upgraded)))
        attacks = [item for item in affordable if self._has_any_effect(item[2], {"damage", "damage_all", "tactical_mark"})]
        if attacks:
            return max(attacks, key=lambda item: self._card_tactical_value(item[2], item[1].upgraded))
        utility = [item for item in affordable if self._has_any_effect(item[2], {"draw", "gain_energy", "block", "heal"})]
        if utility:
            return max(utility, key=lambda item: self._card_tactical_value(item[2], item[1].upgraded))
        return None

    def _apply_card_effects(self, state: RunState, combat: dict[str, Any], enemies: list[dict[str, Any]], card: dict[str, Any], instance: CardInstance, target: int | None, draw_pile: list[CardInstance], discard_pile: list[CardInstance], hand: list[CardInstance]) -> Counter:
        metrics: Counter = Counter()
        attack_bonus = self._equipment_bonus(state, "attack_damage", "protagonist")
        block_bonus = self._equipment_bonus(state, "block_card_bonus", "protagonist")
        for effect in card.get("effects", []):
            effect_type = str(effect.get("type", ""))
            amount = int(effect.get("amount", 0))
            if effect_type == "damage" and target is not None:
                amount += attack_bonus + (2 if instance.upgraded else 0)
                metrics["damage"] += self._deal_damage(enemies[target], amount)
                if str(card.get("type", "")) == "attack" and enemies[target]["hp"] > 0:
                    enemies[target]["mark"] = int(enemies[target].get("mark", 0)) + 1 + int(combat.get("tactical_mark_bonus", 0))
            elif effect_type == "damage_all":
                amount += attack_bonus + (1 if instance.upgraded else 0)
                for enemy in enemies:
                    if enemy["hp"] > 0:
                        metrics["damage"] += self._deal_damage(enemy, amount)
            elif effect_type == "block":
                gained = amount + block_bonus + (2 if instance.upgraded else 0)
                combat["block"] += gained
                metrics["block"] += gained
            elif effect_type == "draw":
                drawn = self._draw_cards(state, draw_pile, discard_pile, hand, amount)
                metrics["draw"] += drawn
            elif effect_type == "tactical_mark" and target is not None and enemies[target]["hp"] > 0:
                applied_mark = amount + int(combat.get("tactical_mark_bonus", 0))
                enemies[target]["mark"] = int(enemies[target].get("mark", 0)) + applied_mark
                metrics["mark"] += applied_mark
            elif effect_type == "gain_energy":
                combat["energy"] += amount
                metrics["energy"] += amount
            elif effect_type == "gain_gold":
                state.gold += amount
                metrics["gold"] += amount
            elif effect_type == "lose_hp":
                combat["hp"] = max(0, int(combat["hp"]) - amount)
                metrics["self_damage"] += amount
            elif effect_type == "heal":
                heal_amount = amount + (1 if instance.upgraded else 0)
                if int(combat.get("healing_down_turns", 0)) > 0:
                    heal_amount = int(round(heal_amount * (100 - int(combat.get("healing_down_percent", 50))) / 100.0))
                before = int(combat["hp"])
                combat["hp"] = min(state.max_hp, int(combat["hp"]) + heal_amount)
                metrics["heal"] += int(combat["hp"]) - before
            elif effect_type == "power_tactical_mark_bonus":
                combat["tactical_mark_bonus"] = int(combat.get("tactical_mark_bonus", 0)) + amount
                metrics["power"] += amount
        return metrics

    @staticmethod
    def _deal_damage(enemy: dict[str, Any], amount: int) -> int:
        total = amount + int(enemy.get("mark", 0))
        blocked = min(int(enemy.get("block", 0)), total)
        enemy["block"] = int(enemy.get("block", 0)) - blocked
        final = max(total - blocked, 0)
        enemy["hp"] = max(0, int(enemy.get("hp", 0)) - final)
        return final

    def _record_card_play(self, state: RunState, card_id: str, metrics: Counter) -> None:
        stat = state.card_stats[card_id]
        stat["played"] += 1
        for key, value in metrics.items():
            stat[key] += int(value)

    def _apply_combat_start_oaths(self, state: RunState, combat: dict[str, Any], draw_pile: list[CardInstance], discard_pile: list[CardInstance], hand: list[CardInstance]) -> None:
        for companion in state.companions:
            if companion.oath_id == "sera_smoke_step":
                combat["block"] += len(hand)
                state.stats["oath_triggers"] += 1
            elif companion.oath_id == "eldric_oathwall":
                combat["enemy_attack_reduction"] += 2
                state.stats["oath_triggers"] += 1
            elif companion.oath_id == "tor_low_stance" and combat["hp"] * 100 <= state.max_hp * 50:
                combat["block"] += 6
                state.stats["oath_triggers"] += 1
            elif companion.oath_id == "noa_first_read":
                self._draw_cards(state, draw_pile, discard_pile, hand, 1)
                state.stats["oath_triggers"] += 1
            elif companion.oath_id == "isol_lantern" and combat["hp"] * 100 <= state.max_hp * 50:
                combat["hp"] = min(state.max_hp, combat["hp"] + 2)
                state.stats["oath_triggers"] += 1

    def _apply_card_play_oaths(self, state: RunState, combat: dict[str, Any], enemies: list[dict[str, Any]], card: dict[str, Any], target: int | None, draw_pile: list[CardInstance], discard_pile: list[CardInstance], hand: list[CardInstance]) -> None:
        for companion in state.companions:
            oath = companion.oath_id
            best = self._best_target_index(enemies, target)
            if best is None:
                continue
            if oath == "sera_second_cut" and int(combat.get("cards_played_this_turn", 0)) == 2:
                enemies[best]["hp"] = max(0, enemies[best]["hp"] - 3)
                state.stats["oath_triggers"] += 1
            elif oath == "sera_quick_claim" and self._card_cost(card) == 0 and self._consume_flag(combat, "sera_quick_claim_used"):
                enemies[best]["mark"] = int(enemies[best].get("mark", 0)) + 1
                state.stats["oath_triggers"] += 1
            elif oath == "eldric_shared_guard" and self._has_any_effect(card, {"block"}):
                combat["block"] += 2
                state.stats["oath_triggers"] += 1
            elif oath == "eldric_last_stand" and self._has_any_effect(card, {"block"}) and combat["hp"] * 100 <= state.max_hp * 40:
                combat["block"] += 2
                state.stats["oath_triggers"] += 1
            elif oath == "bram_blood_wager" and self._has_any_effect(card, {"lose_hp"}):
                enemies[best]["hp"] = max(0, enemies[best]["hp"] - 4)
                state.stats["oath_triggers"] += 1
            elif oath == "bram_hard_bargain" and self._has_any_effect(card, {"lose_hp"}) and self._consume_flag(combat, "bram_hard_bargain_used"):
                combat["energy"] += 1
                state.stats["oath_triggers"] += 1
            elif oath == "maren_measured_care" and self._has_any_effect(card, {"heal"}):
                combat["block"] += 2
                state.stats["oath_triggers"] += 1
            elif oath == "maren_no_free_debt" and self._has_any_effect(card, {"heal"}) and self._consume_flag(combat, "maren_no_free_debt_used"):
                combat["energy"] += 1
                state.stats["oath_triggers"] += 1
            elif oath == "maren_clean_bandage" and self._has_any_effect(card, {"block"}) and self._consume_flag(combat, self._turn_key(oath, companion, combat)):
                combat["hp"] = min(state.max_hp, combat["hp"] + 1)
                state.stats["oath_triggers"] += 1
            elif oath == "tor_shield_rent" and self._has_any_effect(card, {"block"}):
                combat["block"] += 3
                state.stats["oath_triggers"] += 1
            elif oath == "lina_green_pin" and self._has_any_effect(card, {"tactical_mark"}):
                enemies[best]["mark"] = int(enemies[best].get("mark", 0)) + 1
                state.stats["oath_triggers"] += 1
            elif oath == "lina_bitter_dose" and str(card.get("type")) == "skill" and self._consume_flag(combat, self._turn_key(oath, companion, combat)):
                enemies[best]["hp"] = max(0, enemies[best]["hp"] - 2)
                state.stats["oath_triggers"] += 1
            elif oath == "lina_last_leaf" and self._has_any_effect(card, {"heal"}):
                enemies[best]["mark"] = int(enemies[best].get("mark", 0)) + 1
                state.stats["oath_triggers"] += 1
            elif oath == "noa_star_count" and int(combat.get("cards_played_this_turn", 0)) == 3 and self._consume_flag(combat, self._turn_key(oath, companion, combat)):
                self._draw_cards(state, draw_pile, discard_pile, hand, 1)
                state.stats["oath_triggers"] += 1
            elif oath == "noa_zero_map" and self._card_cost(card) == 0 and self._consume_flag(combat, "noa_zero_map_used"):
                combat["energy"] += 1
                state.stats["oath_triggers"] += 1
            elif oath == "isol_white_guard" and self._has_any_effect(card, {"heal"}) and self._consume_flag(combat, "isol_white_guard_used"):
                combat["block"] += 5
                state.stats["oath_triggers"] += 1
            elif oath == "isol_mercy_line" and self._has_any_effect(card, {"block"}) and self._consume_flag(combat, self._turn_key(oath, companion, combat)):
                combat["hp"] = min(state.max_hp, combat["hp"] + 1)
                state.stats["oath_triggers"] += 1

    @staticmethod
    def _consume_flag(combat: dict[str, Any], key: str) -> bool:
        flags = combat.setdefault("oath_flags", {})
        if flags.get(key):
            return False
        flags[key] = True
        return True

    @staticmethod
    def _turn_key(oath_id: str, companion: CompanionState, combat: dict[str, Any]) -> str:
        return f"{oath_id}_{companion.companion_id}_turn_{combat.get('turn', 0)}"

    def _companion_attacks(self, state: RunState, combat: dict[str, Any], enemies: list[dict[str, Any]]) -> None:
        for companion in state.companions:
            target = self._best_target_index(enemies)
            if target is None:
                break
            data = self.companions[companion.companion_id]
            damage = int(data.get("base_attack", 3)) + companion.attack_bonus + self._bond_damage_bonus(companion) + self._equipment_bonus(state, "companion_attack_damage", companion.companion_id)
            enemies[target]["hp"] = max(0, enemies[target]["hp"] - damage)
            if companion.bond >= 100 and enemies[target]["hp"] > 0:
                enemies[target]["mark"] = int(enemies[target].get("mark", 0)) + 1
            self._apply_companion_attack_oaths(state, companion, enemies, target, combat)

    def _apply_companion_attack_oaths(self, state: RunState, companion: CompanionState, enemies: list[dict[str, Any]], target: int, combat: dict[str, Any]) -> None:
        if target < 0 or target >= len(enemies):
            return
        oath = companion.oath_id
        if oath == "rowan_red_pursuit" and int(enemies[target].get("mark", 0)) > 0 and enemies[target]["hp"] > 0:
            enemies[target]["hp"] = max(0, enemies[target]["hp"] - 2)
            state.stats["oath_triggers"] += 1
        elif oath == "rowan_first_blood" and int(enemies[target].get("mark", 0)) > 0 and enemies[target]["hp"] > 0 and self._consume_flag(combat, f"rowan_first_blood_{companion.companion_id}"):
            enemies[target]["hp"] = max(0, enemies[target]["hp"] - 3)
            state.stats["oath_triggers"] += 1
        elif oath == "rowan_spear_line" and enemies[target]["hp"] > 0:
            enemies[target]["mark"] = int(enemies[target].get("mark", 0)) + 1
            state.stats["oath_triggers"] += 1
        elif oath == "bram_red_laugh" and enemies[target]["hp"] <= 0 and self._consume_flag(combat, f"bram_red_laugh_{companion.companion_id}"):
            combat["hp"] = min(state.max_hp, combat["hp"] + 2)
            state.stats["oath_triggers"] += 1
        elif oath == "tor_mark_break" and int(enemies[target].get("mark", 0)) > 0 and enemies[target]["hp"] > 0:
            enemies[target]["hp"] = max(0, enemies[target]["hp"] - 2)
            state.stats["oath_triggers"] += 1

    def _enemy_turn(self, state: RunState, combat: dict[str, Any], enemies: list[dict[str, Any]]) -> None:
        for enemy in enemies:
            if int(enemy.get("hp", 0)) <= 0:
                continue
            intent = self._enemy_intent(enemy)
            intent_type = str(intent.get("type", "attack"))
            if intent_type == "attack":
                damage = max(int(round(int(intent.get("damage", 0)) * combat.get("attack_scale", 1.0))) - int(combat.get("enemy_attack_reduction", 0)), 0)
                combat["enemy_attack_reduction"] = 0
                blocked = min(int(combat.get("block", 0)), damage)
                combat["block"] = int(combat.get("block", 0)) - blocked
                combat["hp"] = max(0, int(combat.get("hp", 0)) - max(damage - blocked, 0))
            elif intent_type == "block":
                enemy["block"] = int(enemy.get("block", 0)) + int(intent.get("block", 0))
            elif intent_type == "healing_down":
                combat["healing_down_percent"] = int(intent.get("percent", 50))
                combat["healing_down_turns"] = int(intent.get("turns", 2))
            enemy["intent_index"] = int(enemy.get("intent_index", 0)) + 1

    def _card_reward(self, state: RunState, policy: str, source: str) -> None:
        options = self._generate_card_options(state, 3)
        for option in options:
            state.card_stats[option["id"]]["offered"] += 1
        pick = self._choose_reward_card(state, options, policy)
        if pick is None:
            skip_gold = int(self.balance.get("rewards", {}).get("skip_gold", 15))
            state.gold += skip_gold
            state.stats["card_rewards_skipped"] += 1
        else:
            state.deck.append(CardInstance(str(pick["id"])))
            state.card_stats[str(pick["id"])]["picked"] += 1
            state.stats["card_rewards_picked"] += 1

    def _generate_card_options(self, state: RunState, count: int) -> list[dict[str, Any]]:
        eligible = [card for card in self.cards.values() if self._reward_eligible(card)]
        options: list[dict[str, Any]] = []
        used: set[str] = set()
        while len(options) < count and len(used) < len(eligible):
            rarity = self._roll_rarity(state.rng)
            pool = [card for card in eligible if str(card.get("rarity", "")) == rarity]
            if not pool:
                pool = eligible
            card = state.rng.choice(pool)
            card_id = str(card.get("id", ""))
            if not card_id or card_id in used:
                continue
            used.add(card_id)
            options.append(card)
        return options

    @staticmethod
    def _roll_rarity(rng: random.Random) -> str:
        total = sum(CARD_RARITY_WEIGHTS.values())
        roll = rng.randint(1, total)
        cursor = 0
        for rarity, weight in CARD_RARITY_WEIGHTS.items():
            cursor += weight
            if roll <= cursor:
                return rarity
        return "common"

    def _reward_eligible(self, card: dict[str, Any]) -> bool:
        return bool(card.get("reward_pool", True)) and str(card.get("rarity", "common")) != "starter"

    def _choose_reward_card(self, state: RunState, options: list[dict[str, Any]], policy: str) -> dict[str, Any] | None:
        if not options:
            return None
        deck_size = len(state.deck)
        scored = [(self._reward_card_score(state, card, policy), card) for card in options]
        scored.sort(key=lambda item: item[0], reverse=True)
        threshold = 20 if deck_size < 16 else 26 if deck_size < 22 else 33
        if policy == "greedy":
            threshold -= 4
        elif policy == "safe":
            threshold += 2
        elif policy == "novice":
            threshold -= 8
        if scored[0][0] < threshold:
            return None
        return scored[0][1]

    def _reward_card_score(self, state: RunState, card: dict[str, Any], policy: str) -> float:
        score = self._card_tactical_value(card, False)
        cost = self._card_cost(card)
        deck_attack = sum(1 for inst in state.deck if str(self.cards[inst.card_id].get("type")) == "attack")
        deck_block = sum(1 for inst in state.deck if self._has_any_effect(self.cards[inst.card_id], {"block"}))
        if str(card.get("type")) == "attack" and deck_attack < deck_block:
            score += 5
        if self._has_any_effect(card, {"block", "heal"}) and deck_block <= deck_attack:
            score += 8
        if self._has_any_effect(card, {"draw", "gain_energy"}):
            score += 5
        if self._has_any_effect(card, {"tactical_mark"}):
            score += 3 + (6 if state.companions else 0)
        if self._has_any_effect(card, {"power_tactical_mark_bonus"}):
            score += 6 + (6 if state.companions else 0)
        if cost >= 3 and len([inst for inst in state.deck if self._card_cost(self.cards[inst.card_id]) >= 3]) >= 3:
            score -= 8
        return score

    def _visit_shop(self, state: RunState, policy: str) -> None:
        products = self._generate_shop_products(state)
        bought_any = True
        purchases = 0
        while bought_any and purchases < 3:
            bought_any = False
            affordable = [p for p in products if not p.get("bought") and int(p.get("price", 0)) <= state.gold]
            if not affordable:
                break
            best = max(affordable, key=lambda p: self._shop_product_value(state, p, policy) - int(p.get("price", 0)) * 0.18)
            if self._shop_product_value(state, best, policy) - int(best.get("price", 0)) * 0.18 < 6:
                break
            state.gold -= int(best.get("price", 0))
            best["bought"] = True
            self._apply_shop_product(state, best)
            purchases += 1
            bought_any = True
            state.stats["shop_purchases"] += 1

    def _generate_shop_products(self, state: RunState) -> list[dict[str, Any]]:
        products: list[dict[str, Any]] = []
        protagonist_pool = [card for card in self.cards.values() if self._reward_eligible(card)]
        state.rng.shuffle(protagonist_pool)
        for card in protagonist_pool[: int(self.balance.get("shop", {}).get("protagonist_cards", 4))]:
            products.append({"type": "card", "card_id": card["id"], "price": self._price_card(state, card)})
        companion_pool: list[dict[str, Any]] = []
        owned_ids = {inst.card_id for inst in state.deck}
        for companion in state.companions:
            for card in self.cards.values():
                if str(card.get("owner", "")) == companion.companion_id and str(card.get("id")) not in owned_ids:
                    companion_pool.append(card)
        state.rng.shuffle(companion_pool)
        for index, card in enumerate(companion_pool[: int(self.balance.get("shop", {}).get("companion_cards", 2))]):
            products.append({"type": "card", "card_id": card["id"], "price": self._discounted(state, 85 + index * 15)})
        eq_pool = list(self.equipment.values())
        state.rng.shuffle(eq_pool)
        for item in eq_pool[: int(self.balance.get("shop", {}).get("equipment_items", 3))]:
            products.append({"type": "equipment", "equipment_id": item["id"], "price": self._discounted(state, int(item.get("price", 100)))})
        remove_price = int(self.balance.get("shop", {}).get("remove_base_cost", 75)) + state.remove_count * int(self.balance.get("shop", {}).get("remove_cost_growth", 25))
        products.extend([
            {"type": "service", "service": "remove", "price": self._discounted(state, remove_price)},
            {"type": "service", "service": "upgrade", "price": self._discounted(state, int(self.balance.get("shop", {}).get("service_upgrade_cost", 110)))},
            {"type": "service", "service": "transform", "price": self._discounted(state, int(self.balance.get("shop", {}).get("service_transform_cost", 85)))},
            {"type": "service", "service": "copy", "price": self._discounted(state, int(self.balance.get("shop", {}).get("service_copy_cost", 125)))},
        ])
        return products

    def _price_card(self, state: RunState, card: dict[str, Any]) -> int:
        rarity = str(card.get("rarity", "common"))
        if rarity == "rare":
            price = state.rng.randint(135, 175)
        elif rarity == "uncommon":
            price = state.rng.randint(70, 95)
        else:
            price = state.rng.randint(45, 60)
        return self._discounted(state, price)

    def _discounted(self, state: RunState, price: int) -> int:
        discount = self._equipment_bonus(state, "shop_discount_percent")
        return max(int(round(price * (100 - discount) / 100.0)), 0)

    def _shop_product_value(self, state: RunState, product: dict[str, Any], policy: str) -> float:
        if product["type"] == "card":
            return self._reward_card_score(state, self.cards[str(product["card_id"])], policy)
        if product["type"] == "equipment":
            return self._equipment_value(state, str(product["equipment_id"]))
        service = str(product.get("service", ""))
        if service == "remove":
            starter_count = sum(1 for inst in state.deck if inst.card_id in STARTER_IDS)
            return 34 if starter_count >= 5 else 22 if starter_count >= 3 else 8
        if service == "upgrade":
            return 28 if any(not inst.upgraded for inst in state.deck) else 0
        if service == "transform":
            return 22 if any(inst.card_id in STARTER_IDS for inst in state.deck) else 0
        if service == "copy":
            best_nonstarter = max((self._card_tactical_value(self.cards[inst.card_id], inst.upgraded) for inst in state.deck if inst.card_id not in STARTER_IDS), default=0)
            return max(0, best_nonstarter - 10)
        return 0

    def _apply_shop_product(self, state: RunState, product: dict[str, Any]) -> None:
        if product["type"] == "card":
            card_id = str(product["card_id"])
            state.deck.append(CardInstance(card_id))
            state.card_stats[card_id]["bought"] += 1
        elif product["type"] == "equipment":
            self._gain_equipment(state, str(product["equipment_id"]))
        elif product["type"] == "service":
            service = str(product.get("service", ""))
            if service == "remove":
                if self._remove_first_starter(state):
                    state.remove_count += 1
                    state.stats["cards_removed"] += 1
            elif service == "upgrade":
                self._upgrade_first_unupgraded(state)
            elif service == "transform":
                self._transform_first_starter(state)
            elif service == "copy":
                self._copy_best_nonstarter(state)

    def _visit_inn(self, state: RunState, policy: str) -> None:
        missing = state.max_hp - state.hp
        rooms = self._generate_inn_rooms(state)
        affordable = [room for room in rooms if int(room.get("price", 0)) <= state.gold]
        if not affordable:
            return
        best = max(affordable, key=lambda room: self._room_value(state, room, missing) - int(room.get("price", 0)) * 0.12)
        if missing < 8 and self._room_value(state, best, missing) < int(best.get("price", 0)) * 0.12:
            return
        state.gold -= int(best.get("price", 0))
        self._apply_effects(state, best.get("effects", []), allow_death=False)
        state.stats["inn_rooms_used"] += 1

    def _generate_inn_rooms(self, state: RunState) -> list[dict[str, Any]]:
        normal = int(self.balance.get("inn", {}).get("normal_weight", 2))
        event = int(self.balance.get("inn", {}).get("event_weight", 1))
        inn_type = "event" if state.rng.randint(1, max(normal + event, 1)) > normal else "normal"
        pool = self._event_rooms() if inn_type == "event" else self._normal_rooms()
        shuffled = pool[:]
        state.rng.shuffle(shuffled)
        return shuffled[: int(self.balance.get("inn", {}).get("room_options", 3))]

    @staticmethod
    def _normal_rooms() -> list[dict[str, Any]]:
        return [
            {"id": "small_room", "price": 40, "effects": [{"type": "heal_percent", "percent": 20}]},
            {"id": "good_room", "price": 90, "effects": [{"type": "heal_percent", "percent": 35}]},
            {"id": "noble_room", "price": 145, "effects": [{"type": "heal_percent", "percent": 55}]},
        ]

    @staticmethod
    def _event_rooms() -> list[dict[str, Any]]:
        return [
            {"id": "free_creaking_room", "price": 0, "effects": [{"type": "heal_percent", "percent": 14}, {"type": "heal_percent", "percent": 100, "chance": 10}]},
            {"id": "red_curtain_room", "price": 35, "effects": [{"type": "heal_percent", "percent": 12}, {"type": "upgrade_card", "chance": 35}]},
            {"id": "locked_side_room", "price": 60, "effects": [{"type": "heal_percent", "percent": 18}, {"type": "gain_equipment", "chance": 25, "rarities": ["common", "uncommon"]}]},
            {"id": "banquet_bed", "price": 105, "effects": [{"type": "heal_percent", "percent": 45}]},
        ]

    def _room_value(self, state: RunState, room: dict[str, Any], missing: int) -> float:
        value = 0.0
        for effect in room.get("effects", []):
            chance = int(effect.get("chance", 100)) / 100.0
            if effect.get("type") == "heal_percent":
                value += min(missing, round(state.max_hp * int(effect.get("percent", 0)) / 100.0)) * 1.3 * chance
            elif effect.get("type") == "upgrade_card":
                value += 22 * chance
            elif effect.get("type") == "gain_equipment":
                value += 24 * chance
        return value

    def _resolve_event(self, state: RunState, policy: str) -> None:
        if not self.events:
            return
        event = state.rng.choice(self.events)
        choices = event.get("choices", [])
        if not choices:
            return
        payable = [choice for choice in choices if self._can_pay_effects(state, choice.get("effects", []))]
        if not payable:
            payable = choices
        best = max(payable, key=lambda choice: self._effects_value(state, choice.get("effects", []), policy))
        self._apply_effects(state, best.get("effects", []), allow_death=False)
        state.stats["event_choices"] += 1

    def _can_pay_effects(self, state: RunState, effects: list[dict[str, Any]]) -> bool:
        for effect in effects:
            if effect.get("type") == "lose_gold" and state.gold < int(effect.get("amount", 0)):
                return False
        return True

    def _effects_value(self, state: RunState, effects: list[dict[str, Any]], policy: str) -> float:
        value = 0.0
        for effect in effects:
            effect_type = str(effect.get("type", ""))
            amount = int(effect.get("amount", effect.get("percent", 0)))
            chance = int(effect.get("chance", 100)) / 100.0
            if effect_type == "gain_gold":
                value += amount * 0.45 * chance
            elif effect_type == "lose_gold":
                value -= amount * 0.45 * chance
            elif effect_type == "lose_hp":
                value -= amount * (2.0 if state.hp < state.max_hp * 0.45 else 1.1) * chance
            elif effect_type == "heal_amount":
                value += min(state.max_hp - state.hp, amount) * 1.2 * chance
            elif effect_type == "heal_percent":
                heal = round(state.max_hp * amount / 100.0)
                value += min(state.max_hp - state.hp, heal) * 1.2 * chance
            elif effect_type == "gain_equipment":
                value += 26 * chance
            elif effect_type == "upgrade_card":
                value += 24 * chance
            elif effect_type == "bond_gain":
                value += len(state.companions) * amount * 0.8 * chance
        return value

    def _apply_effects(self, state: RunState, effects: list[dict[str, Any]], allow_death: bool) -> None:
        for effect in effects:
            if int(effect.get("chance", 100)) < 100 and state.rng.randint(1, 100) > int(effect.get("chance", 100)):
                continue
            effect_type = str(effect.get("type", ""))
            if effect_type == "gain_gold":
                state.gold += int(effect.get("amount", 0))
            elif effect_type == "lose_gold":
                state.gold -= min(state.gold, int(effect.get("amount", 0)))
            elif effect_type == "lose_hp":
                loss = int(effect.get("amount", 0))
                state.hp = max(0 if allow_death else 1, state.hp - loss)
            elif effect_type == "heal_amount":
                state.hp = min(state.max_hp, state.hp + int(effect.get("amount", 0)))
            elif effect_type == "heal_percent":
                state.hp = min(state.max_hp, state.hp + round(state.max_hp * int(effect.get("percent", 0)) / 100.0))
            elif effect_type == "gain_equipment":
                self._gain_random_equipment(state, effect.get("rarities", []))
            elif effect_type == "upgrade_card":
                self._upgrade_first_unupgraded(state)
            elif effect_type == "remove_card":
                self._remove_first_starter(state)
            elif effect_type == "transform_card":
                self._transform_first_starter(state)
            elif effect_type == "copy_card":
                self._copy_best_nonstarter(state)
            elif effect_type == "bond_gain":
                for companion in state.companions:
                    companion.bond = min(100, companion.bond + int(effect.get("amount", 0)))

    def _apply_minor_upgrade(self, state: RunState, policy: str) -> None:
        options = ["minor_protagonist", "minor_companion_bond", "minor_card_refine"]
        choice = self._choose_upgrade_option(state, options, policy)
        if choice == "minor_protagonist":
            state.max_hp += 5
            state.hp = min(state.max_hp, state.hp + 5)
            state.protagonist_upgrade_level += 1
        elif choice == "minor_companion_bond":
            for companion in state.companions:
                companion.bond = min(100, companion.bond + 6)
        else:
            self._upgrade_first_unupgraded(state)
        state.stats["upgrades_taken"] += 1

    def _apply_major_upgrade(self, state: RunState, policy: str) -> None:
        options = ["major_protagonist", "major_companions", "major_armory"]
        choice = self._choose_upgrade_option(state, options, policy)
        if choice == "major_protagonist":
            state.max_hp += 10
            state.hp = min(state.max_hp, state.hp + 10)
            self._upgrade_first_unupgraded(state)
            state.protagonist_upgrade_level += 1
        elif choice == "major_companions":
            for companion in state.companions:
                companion.bond = min(100, companion.bond + 12)
                companion.attack_bonus += 1
        else:
            rare_ids = [item_id for item_id, item in self.equipment.items() if str(item.get("rarity")) == "rare"]
            if rare_ids:
                self._gain_equipment(state, state.rng.choice(rare_ids))
        state.stats["upgrades_taken"] += 1

    def _choose_upgrade_option(self, state: RunState, options: list[str], policy: str) -> str:
        scores = {}
        for option in options:
            if option.endswith("protagonist"):
                scores[option] = 30 + (10 if state.hp < state.max_hp * 0.45 else 0)
            elif "companion" in option:
                scores[option] = 20 + len(state.companions) * 12 + sum(1 for c in state.companions if c.bond >= 20) * 4
            elif "card" in option or "refine" in option:
                scores[option] = 28 + sum(1 for inst in state.deck if not inst.upgraded and inst.card_id not in STARTER_IDS) * 2
            elif "armory" in option:
                scores[option] = 32 if len(state.equipment) < 4 else 18
        return max(options, key=lambda option: scores.get(option, 0))

    def _recruit_companion(self, state: RunState, policy: str) -> None:
        if len(state.companions) >= int(self.balance.get("run", {}).get("max_companions", 2)):
            return
        pool = [companion for companion_id, companion in self.companions.items() if companion_id not in {c.companion_id for c in state.companions}]
        state.rng.shuffle(pool)
        options = pool[: int(self.balance.get("rewards", {}).get("companion_options", 3))]
        if not options:
            return
        chosen = max(options, key=lambda companion: self._companion_value(companion, state, policy))
        oath = max(chosen.get("oath_tactics", []), key=lambda oath_data: self._oath_value(str(oath_data.get("id", "")), policy))
        cards = [card for card in self.cards.values() if str(card.get("owner", "")) == str(chosen["id"])]
        cards.sort(key=lambda card: self._reward_card_score(state, card, policy), reverse=True)
        picks = cards[: int(self.balance.get("rewards", {}).get("companion_card_picks", 2))]
        state.companions.append(CompanionState(companion_id=str(chosen["id"]), name=str(chosen.get("name", chosen["id"])), oath_id=str(oath.get("id", ""))))
        for card in picks:
            state.deck.append(CardInstance(str(card["id"])))
            state.card_stats[str(card["id"])]["picked"] += 1
        state.stats["companions_recruited"] += 1

    def _companion_value(self, companion: dict[str, Any], state: RunState, policy: str) -> float:
        cid = str(companion.get("id", ""))
        base = int(companion.get("base_attack", 0)) * 4
        role_bonus = {"rowan": 9, "sera": 8, "bram": 7, "lina": 7, "tor": 5, "eldric": 4, "noa": 4, "maren": 3, "isol": 3, "kyle": 1}.get(cid, 0)
        if policy == "safe" and cid in {"eldric", "tor", "maren", "isol"}:
            role_bonus += 5
        return base + role_bonus

    @staticmethod
    def _oath_value(oath_id: str, policy: str) -> float:
        values = {
            "rowan_red_pursuit": 12, "rowan_first_blood": 8, "rowan_spear_line": 7,
            "sera_second_cut": 12, "sera_smoke_step": 7, "sera_quick_claim": 6,
            "eldric_shared_guard": 9, "eldric_oathwall": 5, "eldric_last_stand": 4,
            "bram_blood_wager": 10, "bram_hard_bargain": 8, "bram_red_laugh": 5,
            "maren_measured_care": 6, "maren_no_free_debt": 7, "maren_clean_bandage": 8,
            "tor_shield_rent": 10, "tor_low_stance": 5, "tor_mark_break": 7,
            "lina_green_pin": 8, "lina_bitter_dose": 9, "lina_last_leaf": 5,
            "noa_star_count": 8, "noa_first_read": 7, "noa_zero_map": 8,
            "isol_white_guard": 7, "isol_lantern": 4, "isol_mercy_line": 7,
            "kyle_five_hand": 4, "kyle_clean_exit": 5, "kyle_loaded_coin": 3,
        }
        return values.get(oath_id, 0)

    def _upgrade_first_unupgraded(self, state: RunState) -> bool:
        for inst in state.deck:
            if not inst.upgraded:
                inst.upgraded = True
                state.card_stats[inst.card_id]["upgraded"] += 1
                state.stats["cards_upgraded"] += 1
                return True
        return False

    def _remove_first_starter(self, state: RunState) -> bool:
        for index, inst in enumerate(state.deck):
            if inst.card_id in STARTER_IDS:
                state.card_stats[inst.card_id]["removed"] += 1
                del state.deck[index]
                return True
        return False

    def _transform_first_starter(self, state: RunState) -> bool:
        reward_pool = [card for card in self.cards.values() if self._reward_eligible(card)]
        if not reward_pool:
            return False
        for inst in state.deck:
            if inst.card_id in STARTER_IDS:
                old = inst.card_id
                card = state.rng.choice(reward_pool)
                inst.card_id = str(card["id"])
                inst.upgraded = False
                state.card_stats[old]["transformed_from"] += 1
                state.card_stats[inst.card_id]["transformed_to"] += 1
                state.stats["cards_transformed"] += 1
                return True
        return False

    def _copy_best_nonstarter(self, state: RunState) -> bool:
        candidates = [inst for inst in state.deck if inst.card_id not in STARTER_IDS]
        if not candidates:
            return False
        best = max(candidates, key=lambda inst: self._card_tactical_value(self.cards[inst.card_id], inst.upgraded))
        state.deck.append(CardInstance(best.card_id, best.upgraded))
        state.card_stats[best.card_id]["copied"] += 1
        state.stats["cards_copied"] += 1
        return True

    def _gain_random_equipment(self, state: RunState, rarities: Any) -> None:
        pool = list(self.equipment.values())
        if isinstance(rarities, list) and rarities:
            pool = [item for item in pool if str(item.get("rarity", "")) in rarities]
        if pool:
            self._gain_equipment(state, str(state.rng.choice(pool)["id"]))

    def _gain_equipment(self, state: RunState, equipment_id: str) -> None:
        instance = EquipmentInstance(equipment_id=equipment_id, instance_id=state.next_equipment_id)
        state.next_equipment_id += 1
        state.equipment.append(instance)
        self._auto_equip(state, instance)
        state.stats["equipment_gained"] += 1

    def _auto_equip(self, state: RunState, instance: EquipmentInstance) -> None:
        item = self.equipment.get(instance.equipment_id, {})
        slot = str(item.get("slot", ""))
        if not slot:
            return
        wearers = ["protagonist"] + [companion.companion_id for companion in state.companions]
        best_wearer = max(wearers, key=lambda wearer: self._equipment_value_for_wearer(item, wearer))
        state.equipped.setdefault(best_wearer, {})
        current_id = state.equipped[best_wearer].get(slot)
        if current_id is None:
            state.equipped[best_wearer][slot] = instance.instance_id
            return
        current = next((owned for owned in state.equipment if owned.instance_id == current_id), None)
        current_value = self._equipment_value_for_wearer(self.equipment.get(current.equipment_id, {}) if current else {}, best_wearer)
        new_value = self._equipment_value_for_wearer(item, best_wearer)
        if new_value > current_value:
            state.equipped[best_wearer][slot] = instance.instance_id

    def _equipment_value(self, state: RunState, equipment_id: str) -> float:
        item = self.equipment.get(equipment_id, {})
        wearers = ["protagonist"] + [companion.companion_id for companion in state.companions]
        return max((self._equipment_value_for_wearer(item, wearer) for wearer in wearers), default=0)

    @staticmethod
    def _equipment_value_for_wearer(item: dict[str, Any], wearer: str) -> float:
        score = 0.0
        rarity_bonus = {"common": 0, "uncommon": 2, "rare": 4}.get(str(item.get("rarity", "common")), 0)
        for effect in item.get("effects", []):
            effect_type = str(effect.get("type", ""))
            amount = int(effect.get("amount", 0))
            scope = str(effect.get("scope", "team"))
            applies = scope == "team" or (scope == "wearer" and wearer == "protagonist")
            if not applies:
                continue
            if effect_type == "start_block":
                score += amount * 5
            elif effect_type == "block_card_bonus":
                score += amount * 13
            elif effect_type == "shop_discount_percent":
                score += amount * 2.0
            elif effect_type == "companion_attack_damage":
                score += amount * 18
            elif effect_type == "attack_damage":
                score += amount * 16
        return score + rarity_bonus

    def _equipment_bonus(self, state: RunState, effect_type: str, wearer_id: str = "protagonist") -> int:
        total = 0
        equipped_ids = {instance_id for slots in state.equipped.values() for instance_id in slots.values()}
        for instance in state.equipment:
            if instance.instance_id not in equipped_ids:
                continue
            item = self.equipment.get(instance.equipment_id, {})
            equipped_wearer = next((wearer for wearer, slots in state.equipped.items() if instance.instance_id in slots.values()), "")
            for effect in item.get("effects", []):
                if str(effect.get("type", "")) != effect_type:
                    continue
                scope = str(effect.get("scope", "team"))
                if scope == "team" or (scope == "wearer" and equipped_wearer == wearer_id):
                    total += int(effect.get("amount", 0))
        return total

    @staticmethod
    def _bond_damage_bonus(companion: CompanionState) -> int:
        if companion.bond >= 100:
            return 2
        if companion.bond >= 30:
            return 1
        return 0

    @staticmethod
    def _bond_start_block(state: RunState) -> int:
        return sum(2 for companion in state.companions if companion.bond >= 60)

    @staticmethod
    def _card_cost(card: dict[str, Any]) -> int:
        return int(card.get("cost", 0))

    def _card_effect_values(self, card: dict[str, Any], upgraded: bool) -> tuple[int, int, int, int, int, int, int, int]:
        damage = aoe = block = draw = energy = heal = lose_hp = mark = 0
        for effect in card.get("effects", []):
            effect_type = str(effect.get("type", ""))
            amount = int(effect.get("amount", 0))
            if effect_type == "damage":
                damage += amount + (2 if upgraded else 0)
            elif effect_type == "damage_all":
                aoe += amount + (1 if upgraded else 0)
            elif effect_type == "block":
                block += amount + (2 if upgraded else 0)
            elif effect_type == "draw":
                draw += amount
            elif effect_type == "gain_energy":
                energy += amount
            elif effect_type == "heal":
                heal += amount + (1 if upgraded else 0)
            elif effect_type == "lose_hp":
                lose_hp += amount
            elif effect_type == "tactical_mark":
                mark += amount
        return damage, aoe, block, draw, energy, heal, lose_hp, mark

    def _card_tactical_value(self, card: dict[str, Any], upgraded: bool) -> float:
        damage, aoe, block, draw, energy, heal, lose_hp, mark = self._card_effect_values(card, upgraded)
        cost = self._card_cost(card)
        power = sum(int(effect.get("amount", 0)) for effect in card.get("effects", []) if str(effect.get("type", "")) == "power_tactical_mark_bonus")
        return damage * 2.0 + aoe * 4.0 + block * 1.35 + draw * 5.0 + energy * 8.0 + heal * 2.4 + mark * 4.5 + power * 12.0 - lose_hp * 2.1 - cost * 3.0

    @staticmethod
    def _has_any_effect(card: dict[str, Any], effect_types: set[str]) -> bool:
        return any(str(effect.get("type", "")) in effect_types for effect in card.get("effects", []))


@dataclass
class AggregateStats:
    policy: str
    enemy_profile: str
    runs: int = 0
    wins: int = 0
    deaths: Counter = field(default_factory=Counter)
    reached_acts: Counter = field(default_factory=Counter)
    totals: Counter = field(default_factory=Counter)
    combat_rows: list[dict[str, Any]] = field(default_factory=list)
    node_rows: list[dict[str, Any]] = field(default_factory=list)
    final_deck_sizes: list[int] = field(default_factory=list)
    final_hp: list[int] = field(default_factory=list)
    final_gold: list[int] = field(default_factory=list)
    final_bond: list[float] = field(default_factory=list)
    card_stats: dict[str, Counter] = field(default_factory=lambda: defaultdict(Counter))

    def add_run(self, result: dict[str, Any], state: RunState) -> None:
        self.runs += 1
        self.wins += 1 if result.get("won") else 0
        death_key = "win" if result.get("won") else f"A{result.get('death_act')}D{result.get('death_depth')} {result.get('death_node')}"
        self.deaths[death_key] += 1
        max_act = max([row.get("act", 1) for row in state.combat_summaries] + [state.act])
        for act in range(1, max_act + 1):
            self.reached_acts[act] += 1
        self.final_deck_sizes.append(len(state.deck))
        self.final_hp.append(state.hp)
        self.final_gold.append(state.gold)
        self.final_bond.append(mean([companion.bond for companion in state.companions]))
        for key, value in state.stats.items():
            self.totals[key] += value
        self.combat_rows.extend(state.combat_summaries)
        self.node_rows.extend(state.node_history)
        for card_id, counter in state.card_stats.items():
            self.card_stats[card_id].update(counter)

    def to_report(self) -> dict[str, Any]:
        combats = self.combat_rows
        by_node_type: dict[str, list[dict[str, Any]]] = defaultdict(list)
        by_act: dict[int, list[dict[str, Any]]] = defaultdict(list)
        for row in combats:
            by_node_type[str(row.get("node_type", ""))].append(row)
            by_act[int(row.get("act", 0))].append(row)
        return {
            "policy": self.policy,
            "enemy_profile": self.enemy_profile,
            "runs": self.runs,
            "win_rate": self.wins / max(1, self.runs),
            "act_reach_rate": {str(act): self.reached_acts[act] / max(1, self.runs) for act in (1, 2, 3)},
            "boss_clear_rate": {str(act): self.totals[f"boss_clear_act_{act}"] / max(1, self.runs) for act in (1, 2, 3)},
            "top_deaths": self.deaths.most_common(8),
            "avg_final_deck_size": mean(self.final_deck_sizes),
            "avg_final_hp": mean(self.final_hp),
            "avg_final_gold": mean(self.final_gold),
            "avg_final_bond": mean(self.final_bond),
            "avg_cards_picked": self.totals["card_rewards_picked"] / max(1, self.runs),
            "avg_cards_skipped": self.totals["card_rewards_skipped"] / max(1, self.runs),
            "avg_cards_upgraded": self.totals["cards_upgraded"] / max(1, self.runs),
            "avg_cards_removed": self.totals["cards_removed"] / max(1, self.runs),
            "avg_equipment_gained": self.totals["equipment_gained"] / max(1, self.runs),
            "avg_shop_purchases": self.totals["shop_purchases"] / max(1, self.runs),
            "avg_inn_rooms": self.totals["inn_rooms_used"] / max(1, self.runs),
            "avg_oath_triggers": self.totals["oath_triggers"] / max(1, self.runs),
            "route_hp": self._route_hp_summary(self.node_rows),
            "combat_by_type": {kind: self._combat_summary(rows) for kind, rows in by_node_type.items()},
            "combat_by_act": {str(act): self._combat_summary(rows) for act, rows in by_act.items()},
            "card_stats": {card_id: dict(counter) for card_id, counter in sorted(self.card_stats.items())},
        }

    @staticmethod
    def _combat_summary(rows: list[dict[str, Any]]) -> dict[str, float]:
        return {
            "count": len(rows),
            "avg_turns": mean([float(row.get("turns", 0)) for row in rows]),
            "p90_turns": percentile([float(row.get("turns", 0)) for row in rows], 0.9),
            "avg_hp_loss": mean([float(row.get("hp_lost", 0)) for row in rows]),
            "p90_hp_loss": percentile([float(row.get("hp_lost", 0)) for row in rows], 0.9),
            "defeat_rate": sum(1 for row in rows if row.get("outcome") != "victory") / max(1, len(rows)),
        }

    @staticmethod
    def _route_hp_summary(rows: list[dict[str, Any]]) -> dict[str, Any]:
        def _ratio(row: dict[str, Any], hp_key: str, max_key: str) -> float:
            return float(row.get(hp_key, 0)) / max(1.0, float(row.get(max_key, 1)))

        inn_rows = [row for row in rows if str(row.get("type", "")) == "inn"]
        boss_rows = [row for row in rows if str(row.get("type", "")) == "boss"]
        return {
            "avg_inn_hp_before": mean([float(row.get("hp_before", 0)) for row in inn_rows]),
            "avg_inn_hp_after": mean([float(row.get("hp_after", 0)) for row in inn_rows]),
            "avg_inn_hp_ratio_before": mean([_ratio(row, "hp_before", "max_hp_before") for row in inn_rows]),
            "avg_inn_hp_ratio_after": mean([_ratio(row, "hp_after", "max_hp_after") for row in inn_rows]),
            "avg_boss_hp_ratio_before_by_act": {
                str(act): mean([_ratio(row, "hp_before", "max_hp_before") for row in boss_rows if int(row.get("act", 0)) == act])
                for act in (1, 2, 3)
            },
        }


def card_balance_tables(sim: BalanceSimulator, report: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    rows = []
    for card_id, stats in report.get("card_stats", {}).items():
        card = sim.cards.get(card_id, {"name": card_id})
        played = int(stats.get("played", 0))
        offered = int(stats.get("offered", 0))
        picked = int(stats.get("picked", 0)) + int(stats.get("bought", 0))
        output = (
            int(stats.get("damage", 0))
            + int(stats.get("block", 0))
            + int(stats.get("heal", 0)) * 2
            + int(stats.get("draw", 0)) * 4
            + int(stats.get("energy", 0)) * 6
            + int(stats.get("mark", 0)) * 3
            + int(stats.get("power", 0)) * 10
            - int(stats.get("self_damage", 0)) * 2
        )
        rows.append({
            "id": card_id,
            "name": str(card.get("name", card_id)),
            "type": str(card.get("type", "")),
            "rarity": str(card.get("rarity", "")),
            "cost": int(card.get("cost", 0)),
            "offered": offered,
            "picked_or_bought": picked,
            "pick_rate": picked / offered if offered else 0.0,
            "played": played,
            "output_per_play": output / played if played else 0.0,
            "upgraded": int(stats.get("upgraded", 0)),
            "removed": int(stats.get("removed", 0)),
        })
    high_pick = sorted([row for row in rows if row["offered"] >= max(10, report["runs"] * 0.1)], key=lambda row: row["pick_rate"], reverse=True)[:10]
    low_pick = sorted([row for row in rows if row["offered"] >= max(10, report["runs"] * 0.1)], key=lambda row: row["pick_rate"])[:10]
    high_output = sorted([row for row in rows if row["played"] >= max(20, report["runs"] * 0.5)], key=lambda row: row["output_per_play"], reverse=True)[:10]
    low_output = sorted([row for row in rows if row["played"] >= max(20, report["runs"] * 0.5)], key=lambda row: row["output_per_play"])[:10]
    return {"high_pick": high_pick, "low_pick": low_pick, "high_output": high_output, "low_output": low_output}


def write_report(sim: BalanceSimulator, reports: list[dict[str, Any]], output_json: Path, output_md: Path) -> None:
    payload = {"reports": reports}
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    lines = [
        "# Balance Run Simulation Report",
        "",
        "이 리포트는 `tools/balance_run_simulator.py`가 현재 JSON 데이터와 핵심 GDScript 전투 규칙을 근사해 반복 실행한 결과다.",
        "인간 플레이테스트를 대체하지 않고, 카드/적/성장 수치의 위험 구간을 찾기 위한 자동 러너다.",
        "",
        "## Assumptions",
        "",
        "- 카드 효과, 업그레이드 보정, 동료 기본 공격, 유대 30/60/100 보너스, 장비 보너스, 상점/여관/이벤트를 반영했다.",
        "- 보상 선택은 합리적 자동 정책으로 처리한다. 실제 플레이어의 실수, 선호, 장기 빌드 해석은 반영하지 않는다.",
        "- 현재 구현처럼 카드 업그레이드는 `first unupgraded` 방식으로 처리한다. 이는 플레이어 선택형 업그레이드보다 약하고 거칠다.",
        "- 현재 구현처럼 일반 카드 보상은 주로 주인공 카드에서 나온다. 동료 카드는 영입/상점 중심으로 들어간다.",
        "",
        "## Summary",
        "",
        "| Policy | Enemy profile | Runs | A1 Boss | A2 Boss | A3 Reach | Win | Inn in/out | Boss HP A1/A2/A3 | Avg deck | Avg HP | Avg gold | Avg bond | Picked | Skipped | Upgraded | Removed | Gear | Oath triggers |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for report in reports:
        boss_clear = report.get("boss_clear_rate", {})
        act_reach = report.get("act_reach_rate", {})
        route_hp = report.get("route_hp", {})
        boss_hp = route_hp.get("avg_boss_hp_ratio_before_by_act", {})
        inn_ratio = f"{float(route_hp.get('avg_inn_hp_ratio_before', 0))*100:.0f}/{float(route_hp.get('avg_inn_hp_ratio_after', 0))*100:.0f}%"
        boss_ratio = f"{float(boss_hp.get('1', 0))*100:.0f}/{float(boss_hp.get('2', 0))*100:.0f}/{float(boss_hp.get('3', 0))*100:.0f}%"
        lines.append(
            f"| {report['policy']} | {report['enemy_profile']} | {report['runs']} | "
            f"{float(boss_clear.get('1', 0))*100:.1f}% | {float(boss_clear.get('2', 0))*100:.1f}% | {float(act_reach.get('3', 0))*100:.1f}% | {report['win_rate']*100:.1f}% | {inn_ratio} | {boss_ratio} | "
            f"{report['avg_final_deck_size']:.1f} | {report['avg_final_hp']:.1f} | {report['avg_final_gold']:.1f} | {report['avg_final_bond']:.1f} | "
            f"{report['avg_cards_picked']:.1f} | {report['avg_cards_skipped']:.1f} | {report['avg_cards_upgraded']:.1f} | {report['avg_cards_removed']:.1f} | "
            f"{report['avg_equipment_gained']:.1f} | {report['avg_oath_triggers']:.1f} |"
        )
    def _find(policy: str, profile: str) -> dict[str, Any]:
        return next((item for item in reports if item["policy"] == policy and item["enemy_profile"] == profile), {})

    current_novice = _find("novice", "current")
    current_balanced = _find("balanced", "current")
    current_safe = _find("safe", "current")
    current_greedy = _find("greedy", "current")
    plus_balanced = _find("balanced", "plus6")
    spec_balanced = _find("balanced", "spec_mid")
    spec_safe = _find("safe", "spec_mid")
    spec_attack_balanced = _find("balanced", "spec_mid_attack10")

    lines.extend(["", "## Key Findings", ""])
    if current_novice:
        lines.append(f"- 신규 플레이어에 가까운 novice 자동 정책은 Act 1 보스 {current_novice.get('boss_clear_rate', {}).get('1', 0)*100:.1f}%, Act 2 보스 {current_novice.get('boss_clear_rate', {}).get('2', 0)*100:.1f}%, 최종 승리 {current_novice.get('win_rate', 0)*100:.1f}%다. 사람의 실수와 학습 비용은 더 크므로, 이 값은 신규 목표의 상한선으로 본다.")
    if current_balanced or current_safe or current_greedy:
        lines.append(f"- 현재 구현 데이터는 경로 성향에 따라 크게 갈린다. balanced {current_balanced.get('win_rate', 0)*100:.1f}%, safe {current_safe.get('win_rate', 0)*100:.1f}%, greedy {current_greedy.get('win_rate', 0)*100:.1f}%다.")
    if plus_balanced:
        lines.append(f"- 단순 +6% HP는 balanced를 {plus_balanced.get('win_rate', 0)*100:.1f}%까지 낮춘다. 전체 HP 상향은 최후 보정 수단으로만 쓴다.")
    if spec_balanced or spec_safe:
        lines.append(f"- 문서 목표 HP 중간값을 전부 적용하면 balanced {spec_balanced.get('win_rate', 0)*100:.1f}%, safe {spec_safe.get('win_rate', 0)*100:.1f}%가 된다. 문서 목표는 최종 목표선으로는 쓸 수 있지만, 현재 구현에 즉시 일괄 적용하면 너무 가파르다.")
    if spec_attack_balanced:
        lines.append(f"- 문서 목표 HP에 공격력 +10%까지 얹은 압박 테스트는 balanced {spec_attack_balanced.get('win_rate', 0)*100:.1f}%다. 이 수치는 상위 난이도나 후반 튜닝 검증용이지 기본 난이도 기준으로 쓰면 안 된다.")
    lines.extend([
        "- 이번 패치는 보스 HP만 올리는 방향을 피하고, 일반/엘리트의 공격 의도와 회복 경제를 조정해 길 위에서 체력이 점진적으로 깎이는 곡선을 만든다.",
        "- safe 정책은 체력을 보존하지만 덱 품질과 최종 화력이 약해지도록 두고, greedy 정책은 강한 덱을 만들 수 있지만 여관 진입 체력이 낮아지는 구조로 본다.",
    ])
    lines.extend([
        "",
        "## Target Bands",
        "",
        "| Target profile | Act 1 boss clear | Act 2 boss clear | Act 3 reach | Act 3 boss clear | Use |",
        "| --- | ---: | ---: | ---: | ---: | --- |",
        "| Early general player | 65-75% | 25-35% | 12-18% | 6-10% | 신규/초기 런 체감 목표. 자동 러너와 직접 비교하지 않는다. |",
        "| Automatic runner sanity | novice 75-90% | novice 30-45% | novice 25-45% | novice 6-12%, balanced 35-55%, safe 70-90%, greedy 20-40% | 수치 패치가 너무 쉬운지/가파른지 보는 내부 안전장치. |",
        "",
        "Steam achievements show many lifetime players eventually beat at least one character, while high Ascension completion is much rarer. 그래서 기본 난이도의 장기 목표를 10% 미만으로 두지 않고, 신규/초기 플레이어 목표와 숙련 플레이어 목표를 분리한다.",
        "",
        "체력 곡선은 별도 목표로 본다. 평균 여관 진입 체력은 35-60% 사이, 여관 퇴장 체력은 60-85% 사이가 좋다. 보스 진입 체력은 Act 1 55-80%, Act 2 45-75%, Act 3 40-70%를 1차 목표로 둔다. 이 값이 높게 고정되면 경로 선택의 긴장이 약하고, 너무 낮으면 여관을 못 찾은 런이 즉사한다.",
    ])

    lines.extend(["", "## Combat Pressure", ""])
    for report in reports:
        lines.extend([
            f"### {report['policy']} / {report['enemy_profile']}",
            "",
            "| Segment | Count | Avg turns | P90 turns | Avg HP loss | P90 HP loss | Defeat |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
        ])
        for label, summary in sorted(report.get("combat_by_act", {}).items()):
            lines.append(f"| Act {label} | {summary['count']} | {summary['avg_turns']:.2f} | {summary['p90_turns']:.0f} | {summary['avg_hp_loss']:.1f} | {summary['p90_hp_loss']:.0f} | {summary['defeat_rate']*100:.1f}% |")
        for label, summary in sorted(report.get("combat_by_type", {}).items()):
            lines.append(f"| {label} | {summary['count']} | {summary['avg_turns']:.2f} | {summary['p90_turns']:.0f} | {summary['avg_hp_loss']:.1f} | {summary['p90_hp_loss']:.0f} | {summary['defeat_rate']*100:.1f}% |")
        lines.append("")
        lines.append("Top deaths: " + ", ".join([f"{name} {count}" for name, count in report.get("top_deaths", [])[:5]]))
        lines.append("")
    chosen = next((r for r in reports if r["enemy_profile"] == "current" and r["policy"] == "balanced"), reports[-1])
    tables = card_balance_tables(sim, chosen)
    lines.extend(["", "## Card Balance Signals", "", f"기준 표본: `{chosen['policy']} / {chosen['enemy_profile']}`", ""])
    for title, key in [("High Pick", "high_pick"), ("Low Pick", "low_pick"), ("High Output", "high_output"), ("Low Output", "low_output")]:
        lines.extend([f"### {title}", "", "| Card | Type | Cost | Offered | Picked/Bought | Pick rate | Played | Output/play |", "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |"])
        for row in tables[key]:
            lines.append(f"| {row['name']} | {row['type']} | {row['cost']} | {row['offered']} | {row['picked_or_bought']} | {row['pick_rate']*100:.1f}% | {row['played']} | {row['output_per_play']:.1f} |")
        lines.append("")
    lines.extend([
        "## Reading",
        "",
        "- 낮은 픽률 카드는 보상 후보를 흐리는 카드다. 높은 출력 카드는 코스트 대비 과한지 실제 카드 텍스트를 따로 검토한다.",
        "- 현재 자동 정책은 공격적으로 강한 카드를 선호하므로, 방어/유틸 카드의 실제 인간 가치가 과소평가될 수 있다. 그래도 0%에 가까운 픽률은 경고로 본다.",
        "- 승률 목표는 자동 러너 기준 novice 6~12%, balanced 35~55%, safe 70~90%, greedy 20~40% 정도가 1차 기준으로 적당하다. safe 95% 이상은 너무 쉽고, balanced 25% 이하는 너무 가파르다.",
        "",
        "## Next Balance Actions",
        "",
        "1. 적 HP를 문서 목표까지 일괄 상향하지 말고, Act 1 보스/Act 2 이후 단일 적/후반 보스부터 단계적으로 올린다.",
        "2. safe 경로가 너무 안정적이므로 여관/이벤트/상점 경제와 안전 경로 보상을 함께 조정한다.",
        "3. 엘리트는 패배율보다 보상 차별화가 먼저 문제다. 엘리트 전용 강화 보상을 실제 구현하고, 그 뒤 위험도를 다시 측정한다.",
        "4. 업그레이드가 `first unupgraded`인 현재 구현은 플레이어 선택감을 죽이고 시뮬레이션도 왜곡하므로, 카드 선택형 업그레이드 UI/로직으로 바꾼다.",
        "5. Road Cleave / Breakthrough / Sweeping Order 쏠림을 낮추고, Contract Mark / Oath Focus / Risk Advance / Field Medicine 계열의 선택 이유를 강화한다.",
    ])
    output_md.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runs", type=int, default=400)
    parser.add_argument("--seed", type=int, default=260526)
    parser.add_argument("--policies", default="novice,balanced,safe,greedy")
    parser.add_argument("--enemy-profiles", default="current,plus6,spec_mid,spec_mid_attack10")
    parser.add_argument("--json-output", default="SourceCode/data/playtest_logs/balance_run_simulation_latest.json")
    parser.add_argument("--md-output", default="docs/balance_run_simulation_report.md")
    args = parser.parse_args()

    sim = BalanceSimulator(ROOT)
    reports = []
    for enemy_profile in [part.strip() for part in args.enemy_profiles.split(",") if part.strip()]:
        for policy in [part.strip() for part in args.policies.split(",") if part.strip()]:
            report = sim.simulate_many(args.runs, policy, enemy_profile, args.seed + len(reports) * 1000003)
            reports.append(report)
            print(f"{policy:8s} {enemy_profile:18s} runs={args.runs} win={report['win_rate']*100:5.1f}% deck={report['avg_final_deck_size']:.1f} hp={report['avg_final_hp']:.1f} turnsA3={report.get('combat_by_act', {}).get('3', {}).get('avg_turns', 0):.2f}")
    write_report(sim, reports, ROOT / args.json_output, ROOT / args.md_output)
    print(f"Wrote {args.json_output}")
    print(f"Wrote {args.md_output}")


if __name__ == "__main__":
    main()

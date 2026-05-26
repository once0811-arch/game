# Demo Vertical Slice Phase Plan

Date: 2026-05-26

Goal: make the current Godot project presentable as a 15-25 minute Act 1 demo, not a debug prototype.

## Phase 1: Combat Readability

Target:

```txt
Cards, targets, enemy intent, companion contribution, oath triggers, and victory feedback must be readable without opening logs.
```

Tasks:

- Add visible toast feedback for oath triggers, bond gains, Kyle wagers, victory, and defeat.
- Replace the single companion text line with compact companion tiles showing portrait, oath, and bond.
- Keep card click/drag targeting intact.

Done when:

- Playing a card that triggers an oath creates visible feedback on the battle screen.
- Recruited companions are visible as party members, not just text.

## Phase 2: Companion Contract Presentation

Target:

```txt
The first companion recruitment should feel like the demo's first major reward moment.
```

Tasks:

- Upgrade companion candidate cards with portrait, role, base attack, and oath count.
- Upgrade oath selection cards with companion context and readable rules.
- Keep the existing 3-candidate / 3-oath / 2-card recruitment flow.

Done when:

- A new player can understand the difference between candidates before clicking.
- Oath tactics look like permanent contract clauses, not temporary menu buttons.

## Phase 3: Act 1 Variety Pass

Target:

```txt
Act 1 should show enough card and enemy variety that the run does not feel like a system test.
```

Tasks:

- Expand the protagonist reward pool from 12 to 20 cards using currently implemented effect types.
- Add at least one Act 1 enemy Healing Down pattern so healing/inn balance has pressure.
- Keep numbers conservative because 4 energy / 6 draw already gives high option density.

Done when:

- Early card rewards repeat less often.
- Healing is useful but visibly countered by at least one enemy pattern.

## Phase 4: Demo Documentation and Verification

Target:

```txt
The repo should say what is demo-ready, what remains temporary, and how to verify the slice.
```

Tasks:

- Update balance/playtest docs with this demo slice scope.
- Run JSON validation.
- Run Godot headless project and scene-load checks.
- Commit and push after all checks pass.

Done when:

- The repo is pushed with all code and docs in sync.

## Execution Notes

Implemented in this pass:

- Phase 1 combat readability: visible battle toasts and companion combat tiles.
- Phase 2 companion presentation: portrait-based companion contract cards and oath clause cards.
- Phase 3 Act 1 variety: protagonist card pool expanded to 20 cards; Mutated Scholar now applies Healing Down.
- Phase 4 documentation: updated playtest, UI, implementation-alignment, and design-count references.

Still deferred beyond this pass:

- Real sound effects.
- Final authored animation timings for attacks, blocks, healing, and companion strikes.
- Higher-quality character/enemy/background art replacement.
- Exported desktop demo build.

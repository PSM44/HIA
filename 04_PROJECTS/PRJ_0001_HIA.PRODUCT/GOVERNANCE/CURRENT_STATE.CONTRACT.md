# CURRENT_STATE Contract

## Purpose

- `CURRENT_STATE.json` is the primary machine-readable operational state source for `PRJ_0001_HIA.PRODUCT`.
- `BATON` and `BACKLOG` remain audit, continuity, and fallback sources; they are not the primary machine-readable state once `CURRENT_STATE.json` is present and valid.

## Source Precedence

1. Primary: `04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json` when present and valid.
2. Fallback: `BATON` / `BACKLOG` / CLI-derived parsing only if `CURRENT_STATE.json` is missing or invalid.
3. Any fallback path must expose explicit status and warning fields to make degraded operation visible.

## CURRENT_STATE Schema v1

Required fields:

- `schema`
- `project_id`
- `generated_local`
- `generated_utc`
- `generator`
- `current_objective`
- `next_action.id`
- `next_action.title`
- `next_action.status`
- `next_action.raw`
- `next_action.source`
- `evidence.state`
- `evidence.consistency`
- `evidence.captured_utc`
- `session.status`
- `session.last_session_id`
- `git.branch`
- `git.head_short`
- `git.head_message`
- `policy.precedence`
- `policy.fallback_allowed`

## Consumers

| Consumer | Current source | Expected source | Fallback behavior | Remaining debt |
| --- | --- | --- | --- | --- |
| `hia project continue` | `CURRENT_STATE.json` via `Get-HIAProjectPortfolioSnapshot` | `CURRENT_STATE.json` | Falls back to `BATON/BACKLOG`; prints `CURRENT_STATE_STATUS` and `NEXT_ACTION_WARNING` | `TD_BATON_APPEND_ONLY_STATE_001/P1` |
| `hia project status` | `CURRENT_STATE.json` via `Get-HIAProjectPortfolioSnapshot` | `CURRENT_STATE.json` | Falls back to `BATON/BACKLOG`; prints `CURRENT_STATE_STATUS` and `NEXT_ACTION_WARNING` | `TD_BATON_APPEND_ONLY_STATE_001/P1` |
| `hia project review` | `CURRENT_STATE.json` for handoff/sync context | `CURRENT_STATE.json` | Falls back to `BATON`; exposes fallback in `REVIEW_HANDOFF` | `TD_CURRENT_STATE_CONSUMER_MIGRATION_001/P1` |
| `HIA_CONTROL_TOWER_STATE_GENERATOR.ps1` | `CURRENT_STATE.json` primary | `CURRENT_STATE.json` | Falls back to CLI-derived state and exposes `CURRENT_STATE_SOURCE`, `CURRENT_STATE_STATUS`, `FALLBACK_WARNING` | `TD_GENERATED_STATE_SNAPSHOT_DIRTY_001/P2` |
| `hia.state.js / Control Tower Shell` | Generated snapshot from generator | Generated snapshot from generator | Surface must show `CURRENT_STATE_PRIMARY` or fallback markers | `TD_GENERATED_STATE_SNAPSHOT_DIRTY_001/P2` |
| Portfolio snapshot (`Get-HIAProjects -Mode status`) | `Get-HIAProjectPortfolioSnapshot` | `CURRENT_STATE.json` through snapshot helper | Falls back through snapshot helper to `BATON/BACKLOG` | `TD_CURRENT_STATE_CONSUMER_MIGRATION_001/P1` |

## Snapshot Policy

- `hia.state.js` is a generated read-only snapshot.
- `hia.state.js` is not canonical.
- `CURRENT_STATE.json` is canonical.
- Regenerating `hia.state.js` may change timestamps and git head metadata and produce a diff.
- Regenerate `hia.state.js` only when intentionally refreshing visible Control Tower state.
- If only timestamp/head changes, commit the refresh only when operationally required.

## Fallback Contract

- Missing `CURRENT_STATE.json` -> fallback allowed with warning.
- Invalid `CURRENT_STATE.json` -> fallback allowed with warning.
- Conflicting `CURRENT_STATE` vs `BATON/BACKLOG` -> valid `CURRENT_STATE` wins, but a sync warning should be exposed.
- `BATON/BACKLOG` parsing remains fallback and audit support; it is not removed by this contract.

## Known Debts

- `TD_BATON_APPEND_ONLY_STATE_001/P1`: partially mitigated, remains fallback debt.
- `TD_TASK_EVIDENCE_TRACKING_POLICY_001/P2`: decide versioning policy for `ARTIFACTS/TASKS`.
- `TD_CURRENT_STATE_CONSUMER_MIGRATION_001/P1`: migrate remaining consumers to `CURRENT_STATE` where safe.
- `TD_GENERATED_STATE_SNAPSHOT_DIRTY_001/P2`: `hia.state.js` regeneration dirties repo due to timestamp/head updates.

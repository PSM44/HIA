# Evidence Versioning Policy

## Purpose

- Define canonical evidence versus runtime-local evidence for `PRJ_0001_HIA.PRODUCT`.
- Preserve auditability without committing transient operational noise.
- Prevent accidental loss of decision-relevant summaries while keeping raw runtime output local unless explicitly promoted.

## Evidence Classes

### A. Canonical delivery evidence

- Canonical completion summaries for MiniBattles and deliverables.
- Stored under `04_PROJECTS/PRJ_0001_HIA.PRODUCT/DELIVERY/`.

### B. Task evidence

- Working evidence created during execution, review, or diagnostics.
- Typically stored under `04_PROJECTS/PRJ_0001_HIA.PRODUCT/ARTIFACTS/TASKS/`.

### C. Runtime logs

- Raw command logs, smoke outputs, replay traces, and execution logs.
- Typically stored under `04_PROJECTS/PRJ_0001_HIA.PRODUCT/ARTIFACTS/LOGS/`.

### D. Generated UI snapshots

- Generated read-only state snapshots for user interfaces.
- Example: `01_UI/web/control-tower-shell/assets/hia.state.js`.

### E. Temporary, debug, and backup files

- Ad hoc backups, `.bak`, `.tmp`, and temporary diagnostics.
- Includes generated local repair copies and exploratory outputs.

## Versioning Policy

- `DELIVERY` reports are tracked by default.
- `GOVERNANCE` documents are tracked by default.
- `STATE/CURRENT_STATE.json` is tracked by default.
- `BATON` and `BACKLOG` are tracked by default.
- `ARTIFACTS/LOGS` are runtime-local by default unless explicitly promoted.
- `ARTIFACTS/TASKS` are runtime-local by default, with selective promotion allowed.
- `hia.state.js` is tracked as a generated snapshot but it is not canonical state.
- Generated temporary backups are not tracked.

### ARTIFACTS/TASKS Rule

- Compact, decision-relevant task evidence for a completed MiniBattle may be promoted to Git when it adds durable audit value.
- Large, raw, iterative, or noisy task evidence remains runtime-local.
- If task evidence is not promoted, the corresponding `DELIVERY` file must contain the canonical summary of what was decided, validated, and shipped.

## Decision Table

| Artifact type | Example path | Track in Git? | Reason | Promotion rule | Owner/consumer |
| --- | --- | --- | --- | --- | --- |
| Canonical delivery evidence | `04_PROJECTS/PRJ_0001_HIA.PRODUCT/DELIVERY/PRJPB_009S.EVIDENCE_VERSIONING_POLICY.<timestamp>.txt` | Yes | Canonical audit summary for completed work | Track by default | Repo governance, reviewers, future maintainers |
| Governance policy | `04_PROJECTS/PRJ_0001_HIA.PRODUCT/GOVERNANCE/EVIDENCE.VERSIONING.POLICY.md` | Yes | Durable operational contract | Track by default | Repo governance, maintainers |
| Canonical machine-readable state | `04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json` | Yes | Canonical operational state for CLI and generators | Track by default | CLI, Control Tower generator, future consumers |
| Continuity records | `04_PROJECTS/PRJ_0001_HIA.PRODUCT/BATON/04.0_PROJECT.BATON.txt` | Yes | Append-only audit and fallback continuity | Track by default | Humans, fallback parsers |
| Planning ledger | `04_PROJECTS/PRJ_0001_HIA.PRODUCT/AGILE/PROJECT.BACKLOG.txt` | Yes | Backlog continuity and next-action history | Track by default | Humans, fallback parsers |
| Task evidence | `04_PROJECTS/PRJ_0001_HIA.PRODUCT/ARTIFACTS/TASKS/PRJPB_008D-2.RADAR_BASELINE_EVIDENCE.20260529_123032.txt` | Usually no | Often raw or iterative | Promote only if compact and decision-relevant | Engineers, auditors when promoted |
| Runtime logs | `04_PROJECTS/PRJ_0001_HIA.PRODUCT/ARTIFACTS/LOGS/PRJPB_008D-2.RADAR_BASELINE_EVIDENCE.20260529_123032.log` | No by default | High-noise runtime output | Promote only by explicit exception | Local operators |
| Generated UI snapshot | `01_UI/web/control-tower-shell/assets/hia.state.js` | Yes | Visible snapshot used by Control Tower | Regenerate intentionally when visible state refresh is needed | Control Tower Shell |
| Temporary/debug/backup | `02_TOOLS/HIA_PROJECT_ENGINE.ps1.before_PRJPB_009P_20260605_155445.bak` | No | Transient recovery aid | Never track unless explicitly reclassified | Local operator only |

## .gitignore Contract

- `04_PROJECTS/**` remains ignored by default to avoid broad runtime churn.
- The repo explicitly allowlists canonical continuity paths for `PRJ_0001_HIA.PRODUCT`.
- `DELIVERY` remains allowlisted and tracked by default.
- `GOVERNANCE/*.md` is allowlisted and tracked by default.
- `STATE/CURRENT_STATE.json` is allowlisted and tracked by default.
- `ARTIFACTS/TASKS` and `ARTIFACTS/LOGS` remain ignored by default.
- Promotion of ignored task evidence or logs requires explicit force-add on a case-by-case basis; do not unignore broad runtime folders.

## Promotion Workflow

1. Create runtime evidence under `ARTIFACTS/TASKS` or `ARTIFACTS/LOGS` during execution.
2. Summarize the durable outcome in a tracked `DELIVERY` report.
3. If a task evidence file is compact and materially improves auditability, promote that specific file explicitly.
4. Prefer curated summaries in `DELIVERY` or `GOVERNANCE` over committing raw logs.
5. Do not mass-add runtime folders.

## Validation Workflow

- `git status --short`
- `git check-ignore -v <path>`
- `git ls-files <path>`
- `Get-ChildItem 04_PROJECTS/PRJ_0001_HIA.PRODUCT/ARTIFACTS/TASKS | Select-Object -First 10 Name`
- `Get-ChildItem 04_PROJECTS/PRJ_0001_HIA.PRODUCT/ARTIFACTS/LOGS | Select-Object -First 10 Name`

## Remaining Debt

- `TD_TASK_EVIDENCE_TRACKING_POLICY_001/P2`: resolved at policy level; monitor whether it can be downgraded after sustained use.
- `TD_GENERATED_STATE_SNAPSHOT_DIRTY_001/P2`: `hia.state.js` refreshes dirty the repo by design.
- `TD_BATON_APPEND_ONLY_STATE_001/P1`: `BATON` and `BACKLOG` remain fallback and audit support.
- `TD_CURRENT_STATE_CONSUMER_MIGRATION_001/P1`: migrate remaining safe consumers to `CURRENT_STATE`.

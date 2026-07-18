==========
TECH_DEBT.ACCUMULATED
==========
TD-001 Line ending normalization policy addressed by BATCH-0016 scoped .gitattributes. Status: MITIGATION_IN_PROGRESS_UNTIL_COMMIT.
TD-002 DeveFact still depends on this chat as Orchestrator/Control Tower.
TD-003 DEVF.NEW_RUN.v1.ps1 tested with real run in BATCH-0015.
TD-004 Repo-wide .gitattributes remains undecided; current policy is intentionally scoped to DeveFact only.

==========
BATCH-0018 RECOVERY APPEND - TECH_DEBT.ACCUMULATED
==========
SOURCE: REGISTERS/RECOVERY/* generated from Git history in BATCH-0017.
POLICY: This block appends missing historical IDs. It does not replace prior accumulated content.
RECOVERY_NOTE: latest_line is Git-derived evidence, not an invented summary.

## TD-005
- recovery_status: RESTORED_FROM_GIT_LEDGER
- first_seen_commit: fad1649
- first_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- latest_seen_commit: fad1649
- latest_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- restored_line: TD-005 Source rebuilt for v2/v1 apply; later should reconcile with original full preview if needed.

## TD-006
- recovery_status: RESTORED_FROM_GIT_LEDGER
- first_seen_commit: fad1649
- first_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- latest_seen_commit: fad1649
- latest_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- restored_line: TD-006 Need BATCH_0001.TASKS.yaml executable after base structure exists.

## TD-007
- recovery_status: RESTORED_FROM_GIT_LEDGER
- first_seen_commit: fad1649
- first_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- latest_seen_commit: fad1649
- latest_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- restored_line: TD-007 Apply v1 failed because it did not create target parent directories before Copy-Item.

## TD-008
- recovery_status: RESTORED_FROM_GIT_LEDGER
- first_seen_commit: fad1649
- first_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- latest_seen_commit: fad1649
- latest_seen_subject: 20260706.1742_DeveFact_Batch0001_Base
- restored_line: TD-008 Finalize runner writes expanded Q&A based on chat memory, not original uploaded bundle; review required.

==========
SESSION_CLOSE_20260709_TECH_DEBT_APPEND
==========
## TD-009
- status: OPEN
- type: CONTINUITY_VALIDATION
- priority: P1
- title: Formal close readiness not executed inside local repo by assistant.
- cause: assistant cannot directly access local repo runtime; closure relies on user-run TOVS.
- impact: closure is operationally updated but strict clean-close depends on local readiness/RADAR execution.
- next_action: run local readiness/RADAR or accept WARN.

## TD-010
- status: OPEN
- type: PRODUCTIZATION
- priority: P1
- title: Management demo is documentation-first, not yet a single runnable/visible demo surface.
- cause: BATCH-0020 created demo layer documents; no unified entrypoint/UI/launcher yet.
- impact: gerencia can read the demo, but it is not yet a polished visible product demo.
- next_action: BATCH-0021 should create the visible demo entrypoint.

==========
SESSION_CLOSE_20260710_1853 TECH_DEBT_APPEND
==========
## TD-DEVF-20260710-001
- status: OPEN
- type: RADAR_GAP
- priority: P1
- title: No dedicated DeveFact RADAR.ps1.
- cause: BATCH-0027 checkpoint used internal RADAR-style scan because no executable RADAR candidate was found.
- impact: strict RADAR v1.4 evidence and six-output contract are not available for DeveFact module.
- next_action: BATCH-0028 dedicated RADAR.ps1.

## TD-DEVF-20260710-002
- status: OPEN
- type: PRODUCTIZATION
- priority: P1
- title: Management deliverable remains documentation-first.
- impact: useful for controlled development, less persuasive for executive adoption.
- next_action: package management bundle into visible HTML/PDF/PPT.

## TD-DEVF-20260710-003
- status: OPEN
- type: VALIDATION_RIGOR
- priority: P2
- title: Validation is custom per batch, not yet centralized.
- next_action: create reusable DeveFact validation harness.

==========
SESSION_CLOSE_20260716_2348 TECH_DEBT_APPEND
==========
## TD-DEVF-20260716-001
- status: OPEN
- type: RADAR_GAP
- priority: P1
- title: Strict RADAR v1.4 not yet confirmed for DeveFact.
- evidence: RADAR candidates found: 0.
- next_action: BATCH-0028.

## TD-DEVF-20260716-002
- status: OPEN
- type: PRODUCTIZATION_GAP
- priority: P1
- title: Management value still needs a visible artifact.
- next_action: package demo into visible artifact.

==========
SESSION_CLOSE_20260718_1228 TECH_DEBT_APPEND
==========
## TD-DEVF-20260718-001
- status: OPEN
- type: DOCUMENT_AUTHORITY
- priority: P0
- title: HUMAN root naming and precedence conflict.
- cause: three HUMAN documents were eligible at equal precedence; HUMAN.README was not recognized as root.
- impact: Session Continue blocked by HARD_CONFLICT.
- mitigation: DEVF-CIS-HUMAN-ROOT-0001.

## TD-DEVF-20260718-002
- status: OPEN
- type: EXECUTION_TOOLING
- priority: P0
- title: Three failed APPLY launchers for the same objective.
- cause: Git root/subtree assumptions and brittle dirty-set gates.
- impact: execution delay and escalation requirement.
- mitigation: structural launcher rebuilt from scratch; independent V3 audit pending.

## TD-DEVF-20260718-003
- status: OPEN
- type: RADAR_GAP
- priority: P1
- title: No dedicated DeveFact RADAR.ps1 confirmed.
- impact: strict close/readiness evidence is incomplete.
- mitigation: BATCH-0028 after document repair.

## TD-DEVF-20260718-004
- status: OPEN
- type: PRODUCTIZATION
- priority: P1
- title: Product value is still documentation-heavy.
- impact: gerencia cannot yet experience a concise functional vertical slice in one surface.
- mitigation: prioritize BATCH-0030 visible management artifact.

## TD-DEVF-20260718-005
- status: OPEN
- type: ARCHITECTURE
- priority: P2
- title: HUMAN folder mixes canonical doctrine with demos, playbooks and operational artifacts.
- impact: authority discovery and maintenance become ambiguous.
- mitigation: separate canon, product surface and operational evidence in a later CIS; no broad restructure now.

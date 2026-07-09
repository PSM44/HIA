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



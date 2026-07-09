==========
REGISTER_INTEGRITY_AUDIT.v1
==========
STATUS: GENERATED_BY_BATCH_0017

PURPOSE:
Detect and preserve register history from Git without overwriting current accumulated registers.

CURRENT_REGISTER_ID_COUNTS:
- BACKLOG.ACCUMULATED.md current BL count: 7
- DECISION_REGISTER.md current DEC count: 15
- TECH_DEBT.ACCUMULATED.md current TD count: 4

RECOVERY_LEDGER_ID_COUNTS:
- BACKLOG recovery unique BL count: 59
- DECISION recovery unique DEC count: 49
- TECH_DEBT recovery unique TD count: 8

FINDING:
Current accumulated registers may contain compressed/range entries.
Recovery ledgers preserve IDs and latest known lines from Git history.

NEXT REPAIR STEP:
Append or reconstruct missing detailed entries in accumulated registers using recovery ledgers.
Do not replace accumulated registers with summaries.

NO DB MODIFICATION.
NO PUSH.
NO BUILD.
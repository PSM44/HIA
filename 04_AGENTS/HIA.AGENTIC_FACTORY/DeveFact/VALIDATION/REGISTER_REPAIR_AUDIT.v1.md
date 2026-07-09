==========
REGISTER_REPAIR_AUDIT.v1
==========
STATUS: GENERATED_BY_BATCH_0018

PURPOSE:
Append missing historical register IDs from BATCH-0017 recovery ledgers into accumulated registers.

POLICY:
- No accumulated register was replaced wholesale.
- Current content was preserved.
- Missing IDs were appended under BATCH-0018 recovery sections.
- Recovery evidence is Git-derived latest_line.

COUNTS:
- BACKLOG ledger IDs: 59
- BACKLOG existing IDs before repair: 7
- BACKLOG missing IDs appended/planned: 52

- DECISION ledger IDs: 49
- DECISION existing IDs before repair: 15
- DECISION missing IDs appended/planned: 34

- TECH_DEBT ledger IDs: 8
- TECH_DEBT existing IDs before repair: 4
- TECH_DEBT missing IDs appended/planned: 4

NO DB MODIFICATION.
NO PUSH.
NO BUILD.
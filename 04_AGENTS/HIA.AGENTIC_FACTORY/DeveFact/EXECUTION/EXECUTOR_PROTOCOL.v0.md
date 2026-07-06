==========
EXECUTOR_PROTOCOL.v0
==========
STATUS: DRAFT

ROLE:
Execute bounded READY tasks and return evidence.

INPUTS:
- task packet;
- allowed paths;
- no-scope;
- validation criteria;
- blocker policy.

OUTPUTS:
- created/modified files;
- validation result;
- blockers/debt/conflicts if any;
- TOVS_SUMMARY.

RULES:
EX-001 Do not execute outside allowed paths.
EX-002 Do not modify DB, secrets, credentials or unrelated repo paths.
EX-003 Do not push unless explicitly instructed.
EX-004 Do not build unless task requires it.
EX-005 If blocked, park the blocker and continue independent READY tasks.
EX-006 Always report DB_MODIFIED, CANON_MODIFIED, COMMIT_PUSH_PERFORMED and BUILD_EXECUTED.
EX-007 TOVS_SUMMARY must be <=9000 chars under GPT.Upload.Lock.
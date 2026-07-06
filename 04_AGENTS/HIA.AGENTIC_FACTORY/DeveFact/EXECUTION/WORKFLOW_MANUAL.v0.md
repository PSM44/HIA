==========
WORKFLOW_MANUAL.v0
==========
STATUS: BATCH_0003_DRAFT

OBJECTIVE:
Define the first manual runnable workflow for DeveFact.

FLOW:
01 Human submits idea.
02 Orchestrator creates DISCOVERY_QUESTIONS.
03 Human answers.
04 Orchestrator creates HUMAN_PRODUCT_DRAFT.
05 Orchestrator creates DECISION_REGISTER entries.
06 Orchestrator creates BACKLOG candidates.
07 Orchestrator creates TASK_PACKET with up to 6 READY tasks.
08 Executor receives TASK_PACKET.
09 Executor performs dry-run if changes are needed.
10 Executor applies only after explicit confirmation.
11 Executor returns TOVS_SUMMARY.
12 Orchestrator updates registers and BATON.

CONTROL RULES:
- Every workflow run must have a RUN_ID.
- Every task must have acceptance criteria.
- Every script must report DB_MODIFIED, CANON_MODIFIED, COMMIT_PUSH_PERFORMED, BUILD_EXECUTED.
- Under GPT.Upload.Lock, output must fit in TOVS_SUMMARY <=9000 chars.
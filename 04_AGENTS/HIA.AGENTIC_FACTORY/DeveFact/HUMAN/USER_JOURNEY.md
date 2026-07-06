==========
HUMAN.USER_JOURNEY
==========
STATUS: BATCH_0002_DRAFT

ACTORS:
- Human: person with idea, pain, operational need or desired solution.
- IA Orchestrator: converts unclear intent into structured definition.
- IA Executor: executes bounded READY tasks and returns evidence.

FLOW:
01 Human describes idea or need in natural language.
02 Orchestrator asks targeted questions.
03 Orchestrator records Q&A and decisions.
04 Orchestrator detects conflicts, scope creep, risks and blockers.
05 Orchestrator updates HUMAN only when functional meaning changes.
06 Orchestrator creates/updates backlog, blockers, conflicts and tech debt.
07 Orchestrator produces a batch of up to 6 READY tasks.
08 Executor executes only READY tasks.
09 Executor parks blocked tasks and continues independent tasks.
10 Executor returns TOVS_SUMMARY and evidence.
11 Orchestrator updates registers and decides next batch.
12 Human reviews decisions and approves next step.

NON_NEGOTIABLE:
No blind execution.
No secrets.
No uncontrolled root changes.
No push without explicit instruction.
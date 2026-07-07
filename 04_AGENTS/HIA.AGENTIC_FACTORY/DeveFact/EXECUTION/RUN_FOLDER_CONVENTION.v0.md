==========
RUN_FOLDER_CONVENTION.v0
==========
STATUS: BATCH_0007_DRAFT

ROOT:
EXECUTION/RUNS/<RUN_ID>/

RUN_ID FORMAT:
DEVF-RUN-YYYYMMDD-HHMM
or for simulations:
DEVF-SIM-RUN-0001

REQUIRED FILES:
- RUN.INTAKE.md
- RUN.DISCOVERY_QUESTIONS.md
- RUN.DISCOVERY_ANSWERS.md
- RUN.ORCHESTRATOR_OUTPUT.md
- RUN.EXECUTOR_TASK_PACKET.yaml
- RUN.TOVS.EXPECTED.txt
- RUN.TOVS.ACTUAL.txt, when execution has occurred
- RUN.VALIDATION.md, when verification has occurred

RULE:
A run folder is evidence, not source of truth by itself.
Registers and BATON must still be updated when the run changes project state.
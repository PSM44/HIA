==========
RUN_GENERATOR_VALIDATION.v0
==========
STATUS: BATCH_0007_DRAFT

VALIDATION OBJECTIVE:
Confirm that DEVF.NEW_RUN.v0.ps1 can safely plan and create a new run folder.

CHECKS:
- Script exists.
- Script emits EXECUTION_VERDICT.
- Dry-run returns OK_TO_APPLY.
- Apply requires CREATE_DEVF_RUN confirmation.
- Generated folder stays under EXECUTION/RUNS/<RUN_ID>.
- Generated run contains RUN.INTAKE.md, RUN.DISCOVERY_QUESTIONS.md, RUN.ORCHESTRATOR_STUB.md, RUN.EXECUTOR_TASK_PACKET.STUB.yaml and RUN.TOVS.EXPECTED.txt.
- No DB modification.
- No commit/push.
- No build.

RECOMMENDED TEST RUN:
RunId: DEVF-RUN-TEST-0001
Idea: "I need a controlled way to turn a vague operational need into executable AI tasks."
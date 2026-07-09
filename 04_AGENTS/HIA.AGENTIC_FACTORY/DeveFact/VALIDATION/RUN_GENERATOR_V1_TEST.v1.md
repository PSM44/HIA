==========
RUN_GENERATOR_V1_TEST.v1
==========
STATUS: BATCH_0015_GENERATED
RUN_ID: DEVF-RUN-TEST-V1-0015

EXPECTED:
- DEVF.NEW_RUN.v1.ps1 dry-run returns OK_TO_APPLY.
- DEVF.NEW_RUN.v1.ps1 apply returns OK_TO_REVIEW.
- Generated run folder exists under EXECUTION/RUNS/DEVF-RUN-TEST-V1-0015.
- RUN.INTAKE.md exists.
- RUN.DISCOVERY_QUESTIONS.md exists.
- RUN.ORCHESTRATOR_STUB.md exists.
- RUN.EXECUTOR_TASK_PACKET.STUB.yaml exists.
- RUN.TOVS.EXPECTED.txt exists.
- RUN.VALIDATION.md exists.
- Duplicate run without -OverwriteExisting fails safely.
- No DB modification.
- No push.
- No build.

OBSERVED:
- dry_run_ok_to_apply: 1
- dry_run_safe_to_proceed: 1
- dry_run_db_modified_no: 1
- dry_run_no_push: 1
- dry_run_no_build: 1
- apply_ok_to_review: 1
- duplicate_fails_safely: 1
- run_root_exists: 1
- intake_exists: 1
- questions_exists: 1
- orchestrator_stub_exists: 1
- packet_stub_exists: 1
- expected_tovs_exists: 1
- validation_exists: 1

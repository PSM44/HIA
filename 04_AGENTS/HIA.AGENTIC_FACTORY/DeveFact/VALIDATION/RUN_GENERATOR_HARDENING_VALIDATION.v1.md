==========
RUN_GENERATOR_HARDENING_VALIDATION.v1
==========
STATUS: BATCH_0014_DRAFT

VALIDATION CHECKS:
- DEVF.NEW_RUN.v1.ps1 exists.
- v1 contains CREATE_DEVF_RUN.
- v1 contains IntakeFile support.
- v1 contains OverwriteExisting protection.
- v1 emits EXECUTION_VERDICT.
- v1 emits SAFE_TO_PROCEED.
- v1 contains no-push/no-build/no-DB markers.
- v1 does not overwrite DEVF.NEW_RUN.v0.ps1.
- BATCH_0014 has 6 task_id entries.

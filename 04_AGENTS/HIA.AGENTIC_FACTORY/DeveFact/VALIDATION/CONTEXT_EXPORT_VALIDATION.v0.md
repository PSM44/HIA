==========
CONTEXT_EXPORT_VALIDATION.v0
==========
STATUS: BATCH_0012_DRAFT

VALIDATION OBJECTIVE:
Confirm that DEVF.EXPORT_CONTEXT.v0.ps1 can safely export a compact context package.

CHECKS:
- Exporter exists.
- Exporter emits EXECUTION_VERDICT.
- Exporter dry-run returns OK_TO_APPLY.
- Exporter apply requires EXPORT_DEVF_CONTEXT.
- Exporter writes under C:\Users\aazcl\Downloads\Temp.DeveFactory.
- Exporter does not modify repo.
- Exporter creates EXPORT.MANIFEST.txt.
- Exporter does not push.
- Exporter does not build.
- Exporter does not modify DB.
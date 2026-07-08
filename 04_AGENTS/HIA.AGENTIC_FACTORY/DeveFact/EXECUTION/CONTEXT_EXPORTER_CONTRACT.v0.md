==========
CONTEXT_EXPORTER_CONTRACT.v0
==========
STATUS: BATCH_0012_DRAFT

PURPOSE:
Define a safe local exporter for DeveFact context packages.

EXPORTER:
TOOLS/DEVF.EXPORT_CONTEXT.v0.ps1

OUTPUT LOCATION:
C:\Users\aazcl\Downloads\Temp.DeveFactory\<PACKAGE_NAME>

PACKAGE CONTENT:
- HUMAN
- CONTEXT
- BATON
- REGISTERS
- selected EXECUTION files
- selected VALIDATION files
- selected TOOLS files

SAFETY:
- No repo modification.
- No DB modification.
- No push.
- No build.
- No secrets intentionally included.
- Output is outside the repo under Temp.DeveFactory.

SUCCESS:
Exporter dry-run returns OK_TO_APPLY.
Exporter apply returns OK_TO_REVIEW and creates EXPORT.MANIFEST.txt.
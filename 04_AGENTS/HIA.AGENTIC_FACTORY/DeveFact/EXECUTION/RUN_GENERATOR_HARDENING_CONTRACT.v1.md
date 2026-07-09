==========
RUN_GENERATOR_HARDENING_CONTRACT.v1
==========
STATUS: BATCH_0014_DRAFT

TARGET:
TOOLS/DEVF.NEW_RUN.v1.ps1

DESIGN DECISION:
Create v1 side-by-side. Do not overwrite v0.

IMPROVEMENTS:
- Supports -IntakeFile.
- Blocks duplicate run IDs by default.
- Allows overwrite only with -OverwriteExisting and explicit confirmation.
- Emits complete TOVS.
- Keeps no-push/no-build/no-DB guarantees.
- Writes only under EXECUTION/RUNS/<RunId>.

SAFETY:
- No external AI call.
- No DB modification.
- No commit.
- No push.
- No build.
- No write outside DeveFact run folder.

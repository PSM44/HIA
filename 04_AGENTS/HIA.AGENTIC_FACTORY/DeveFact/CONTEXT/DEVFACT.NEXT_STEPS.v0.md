==========
DEVFACT.NEXT_STEPS.v0
==========
RECOMMENDED NEXT DECISION:
Choose BATCH-0011 direction.

OPTION A - HARDEN GENERATOR
Improve DEVF.NEW_RUN.v0.ps1 with:
- input file support;
- safer duplicate run behavior;
- richer validation output;
- better TOVS persistence;
- configurable run root.

OPTION B - HUMAN QUICKSTART
Create HUMAN/QUICKSTART.md and a minimal user journey:
- how to write an idea;
- how to generate a run;
- how to answer discovery;
- how to verify;
- how to commit.

OPTION C - CONTEXT EXPORTER
Create TOOLS/DEVF.EXPORT_CONTEXT.v0.ps1 to export a compact package for upload/migration:
- HUMAN;
- key EXECUTION files;
- current RUN;
- REGISTERS;
- BATON;
- commit log.

EXPERT RECOMMENDATION:
Option B first.
Reason: before hardening automation, the human operating path must be easy and unambiguous.
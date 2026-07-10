==========
DEMO_FUNCTIONALITY_F01_RUN_CREATION.v0.1
==========

FUNCTIONALITY:
F01 - RUN CREATION

OBJECTIVE:
Demonstrate that DeveFact can create a controlled run from a raw idea.

CURRENT EVIDENCE:
- TOOLS/DEVF.NEW_RUN.v1.ps1
- EXECUTION/RUNS/DEVF-RUN-TEST-V1-0015/
- VALIDATION/RUN_GENERATOR_V1_TEST.v1.md
- BATCH-0015 commit

WHAT F01 DEMONSTRATES:
- Raw idea intake.
- Discovery question generation.
- Orchestrator stub generation.
- Executor task packet stub generation.
- Expected TOVS generation.
- Run validation placeholder.
- Duplicate run protection.

WHY THIS MATTERS:
A development factory must begin by controlling the entry point.
If the run is not structured, later execution by humans or agents becomes unreliable.

MANAGEMENT INTERPRETATION:
This is the first basic functionality of DeveFact:
"Turn an ambiguous idea into a controlled run folder with evidence requirements."

NOT YET DEMONSTRATED:
- autonomous agent execution,
- full code generation,
- UI,
- deploy,
- external user workflow.

NEXT FUNCTIONALITY CANDIDATES:
- F02 Discovery Questions hardening.
- F03 Task Packet generation.
- F10 Management Demo Layer.

==========
DEVFACT.CONTEXT.PACKAGE.v0
==========
PROJECT:
DeveFact / HIA.AGENTIC_FACTORY

ROOT:
C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\04_AGENTS\HIA.AGENTIC_FACTORY\DeveFact

PURPOSE:
DeveFact is a Development Factory module for converting vague human ideas or operational needs into clarified, bounded, executable AI task packets.

OPERATING MODEL:
Human idea
-> discovery questions
-> discovery answers
-> Orchestrator output
-> Executor task packet
-> validation loop
-> TOVS
-> local commit only when explicitly approved.

CURRENT MODE:
HYBRID.
TOVS remains the control signal.
Uploads/context packages may be used when useful for audit or migration.

SAFETY:
- No secrets.
- No DB changes unless explicitly approved.
- No push unless explicitly requested.
- No build unless required.
- No deploy.
- No external AI call from local scripts.
- Writes must remain under the approved DeveFact module path.

CURRENT CAPABILITY:
- Local run generator exists: TOOLS/DEVF.NEW_RUN.v0.ps1.
- Test run exists: EXECUTION/RUNS/DEVF-RUN-TEST-0001.
- Test run has discovery answers, Orchestrator output and final executor task packet.
- Blocker, validation and retry policies exist.
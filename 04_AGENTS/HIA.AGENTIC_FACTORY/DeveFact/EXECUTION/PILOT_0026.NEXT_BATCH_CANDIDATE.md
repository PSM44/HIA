==========
PILOT_0026.NEXT_BATCH_CANDIDATE
==========
PILOT_ID:
PILOT-DEVF-HIA-001

PILOT_RESULT:
A candidate next batch contract was produced under the BATCH-0025 pilot contract.

CANDIDATE NEXT BATCH:
BATCH-0027

CANDIDATE FUNCTIONALITY:
Context Intake Checklist.

FUNCTIONAL PROBLEM:
Before each batch, the system needs a consistent way to decide whether current BATON, registers, demo docs and git state are enough to continue, or whether additional context/RADAR/upload is required.

WHY THIS IS THE RIGHT NEXT FUNCTIONALITY:
- It reduces context-loss risk.
- It supports future multi-agent execution.
- It improves session continuity.
- It is small enough for controlled execution.
- It avoids UI, DB, deploy or external-agent complexity.

OBJECTIVE:
Create a reusable context intake checklist for DeveFact batches.

IN_SCOPE:
- Define required input context for a new batch.
- Define when BATON is sufficient.
- Define when RADAR/readiness is required.
- Define when user upload is required.
- Define when execution must stop.
- Produce a human-readable checklist and validation checklist.

NO_SCOPE:
- No automatic RADAR execution.
- No file upload automation.
- No external agents.
- No DB.
- No build.
- No deploy.
- No push.

PROPOSED OUTPUTS:
- HUMAN/CONTEXT_INTAKE_CHECKLIST.v0.1.md
- VALIDATION/CONTEXT_INTAKE_ACCEPTANCE.v0.1.md
- EXECUTION/BATCH_0027.TASKS.yaml

ACCEPTANCE CRITERIA:
- Checklist defines minimum context.
- Checklist defines BATON-sufficient condition.
- Checklist defines RADAR-required condition.
- Checklist defines upload-required condition.
- Checklist defines hard-stop conditions.
- Validation file is testable.
- No DB/push/build/deploy.

HUMAN DECISION REQUIRED:
Approve, revise or reject BATCH-0027 candidate.
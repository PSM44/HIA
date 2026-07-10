==========
PILOT_RISK_REGISTER_0025.v0.1
==========
PILOT_ID:
PILOT-DEVF-HIA-001

RISK-001: Recursive planning without delivery.
Severity: MEDIUM
Mitigation: BATCH-0026 must produce one concrete next-batch contract only.

RISK-002: Scope creep into automation.
Severity: HIGH
Mitigation: no external agents, no autonomous execution, no build/deploy.

RISK-003: Excess documentation without product value.
Severity: MEDIUM
Mitigation: BATCH-0026 must support a real next functionality decision.

RISK-004: Confusion between demo and pilot.
Severity: MEDIUM
Mitigation: BATCH-0025 is pilot contract only; BATCH-0026 is pilot execution.

RISK-005: Git side effects.
Severity: LOW
Mitigation: no push; commit only after verify.
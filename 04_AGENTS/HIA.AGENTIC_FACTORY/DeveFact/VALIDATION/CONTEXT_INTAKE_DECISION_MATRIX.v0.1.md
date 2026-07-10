==========
CONTEXT_INTAKE_DECISION_MATRIX.v0.1
==========

SCENARIO: local docs-only batch, clean git, fresh BATON.
DECISION: CONTEXT_SUFFICIENT

SCENARIO: user asks "corrobora estatus actual, no uses memoria".
DECISION: RADAR_REQUIRED or upload/RADAR evidence required.

SCENARIO: named file is referenced but not present.
DECISION: UPLOAD_REQUIRED

SCENARIO: session close requested.
DECISION: READINESS_REQUIRED if strict clean close is expected.

SCENARIO: push requested.
DECISION: READINESS_REQUIRED before push, then explicit authorization.

SCENARIO: deploy/build/DB/external agents requested.
DECISION: HARD_STOP unless explicitly authorized and acceptance/safety criteria exist.

SCENARIO: git dirty before starting a new batch.
DECISION: HARD_STOP unless dirty state is expected and bounded.

SCENARIO: BATON points to next action and TOVS confirms clean git.
DECISION: CONTEXT_SUFFICIENT

SCENARIO: broad repo impact or unknown filesystem state.
DECISION: RADAR_REQUIRED
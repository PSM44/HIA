==========
PILOT_EVIDENCE_REQUIREMENTS_0025.v0.1
==========
PILOT_ID:
PILOT-DEVF-HIA-001

REQUIRED EVIDENCE FOR BATCH-0026:
1. Input context file list.
2. Pilot planning output.
3. Acceptance checklist.
4. Evidence map.
5. TOVS summary.
6. Git status before and after.
7. No-scope confirmation.
8. Human decision request.

MINIMUM PASS:
- All required outputs exist.
- No unauthorized side effects.
- TOVS emitted.
- Next action is singular.

FAIL CONDITIONS:
- Any push.
- Any DB change.
- Any build/deploy.
- Scope expansion beyond pilot contract.
- Output not understandable by non-technical reviewer.
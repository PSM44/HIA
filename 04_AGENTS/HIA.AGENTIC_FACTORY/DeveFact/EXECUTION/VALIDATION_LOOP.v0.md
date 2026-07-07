==========
VALIDATION_LOOP.v0
==========
STATUS: BATCH_0004_DRAFT

PURPOSE:
Define how a task moves from attempted execution to verified closure.

VALIDATION STATES:
- NOT_STARTED
- DRYRUN_READY
- DRYRUN_PASS
- APPLY_READY
- APPLY_PASS
- VERIFY_READY
- VERIFY_PASS
- COMMIT_READY
- COMMITTED
- BLOCKED
- PARKED
- FAILED

LOOP:
01 Executor performs dry-run.
02 Orchestrator reviews TOVS.
03 If clean, human authorizes apply.
04 Executor applies.
05 Orchestrator requires verify.
06 Verify runner checks acceptance criteria.
07 If verify passes, human authorizes commit.
08 Commit is local unless push is explicitly requested.
09 If any stage fails, create Blocker Packet.
10 If issue is minor, retry with corrected runner.
11 If issue is material, park task or request human decision.

VALIDATION PRINCIPLES:
- No apply without dry-run unless explicitly accepted.
- No commit without verification.
- No push without explicit instruction.
- Build only if task requires it.
- Every failure must leave an evidence trail.
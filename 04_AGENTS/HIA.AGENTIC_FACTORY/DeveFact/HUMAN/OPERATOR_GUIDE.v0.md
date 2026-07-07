==========
OPERATOR_GUIDE.v0
==========
ROLE:
The operator is the human control tower.

OPERATOR RESPONSIBILITIES:
- Define the initial idea.
- Answer discovery questions.
- Approve or reject scope.
- Read TOVS summaries.
- Decide when to apply.
- Decide when to commit.
- Decide when to push.

TOVS DECISION RULES:
OK_TO_APPLY:
The plan is safe to apply, but not yet committed.

OK_TO_VERIFY:
The apply step ran and must be verified.

OK_TO_COMMIT:
Verification passed. Local commit is allowed.

COMMITTED:
Local commit completed.

NEEDS_REVIEW:
Do not proceed until warnings are resolved.

FAILED / BLOCKED:
Do not proceed. Diagnose and create or review a blocker packet.

HUMAN CONFIRMATION:
Any apply/commit action must require explicit confirmation text.
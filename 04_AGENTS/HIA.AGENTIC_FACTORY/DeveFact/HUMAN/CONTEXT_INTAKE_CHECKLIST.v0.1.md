==========
CONTEXT_INTAKE_CHECKLIST.v0.1
==========
PURPOSE:
Define the minimum context intake decision before starting any DeveFact batch.

WHEN TO USE:
At the beginning of every batch before creating or modifying files.

PRIMARY QUESTION:
Is the available context sufficient to execute the next batch safely?

DECISION OUTCOMES:
1. CONTEXT_SUFFICIENT
2. BATON_REQUIRED
3. RADAR_REQUIRED
4. UPLOAD_REQUIRED
5. READINESS_REQUIRED
6. HARD_STOP

MINIMUM CONTEXT REQUIRED:
- Current project root.
- Current module root.
- Current branch.
- Current git status.
- Last committed batch.
- Current BATON state.
- Intended next batch objective.
- No-scope.
- Allowed file/folder scope.
- Acceptance criteria.
- Safety constraints.

BATON IS SUFFICIENT WHEN:
- BATON points to the intended next action.
- Git status is clean or expected dirty state is explicitly explained.
- Last commit is known.
- No new external or sensitive source is required.
- The batch is local/docs-only or otherwise bounded.
- Acceptance criteria can be written without additional evidence.

BATON IS NOT SUFFICIENT WHEN:
- The requested action depends on unseen files.
- The current filesystem state is uncertain.
- The user asks to corroborate status and not rely on memory.
- There are possible uncommitted changes not explained by TOVS.
- The next batch changes runtime code, automation, DB, deploy, credentials, or external integrations.

RADAR REQUIRED WHEN:
- The user requests current verified project status.
- There is a risk of stale BATON.
- The batch depends on broad repository state.
- The batch may touch runtime, automation, build, DB, deploy or agent orchestration.
- The last known state predates material filesystem changes.

UPLOAD REQUIRED WHEN:
- The needed evidence is not available in the conversation or local TOVS.
- The user references files not present in current context.
- The next decision depends on exact content of documents not yet available.
- A new IA instance needs context transfer.

READINESS REQUIRED WHEN:
- Closing session.
- Before push.
- Before release/demo handoff.
- Before changing automation that affects future batches.
- Before declaring clean close.

HARD STOP WHEN:
- Git root is ambiguous.
- Git status is dirty and not expected.
- Scope includes secrets or credentials.
- The action would push, deploy, modify DB, or run external agents without explicit authorization.
- Required context is missing and cannot be inferred safely.
- Acceptance criteria cannot be tested.
- The user request conflicts with established no-scope.

DEFAULT RULE:
If unsure, stop and request the smallest missing context or run the narrowest verification.
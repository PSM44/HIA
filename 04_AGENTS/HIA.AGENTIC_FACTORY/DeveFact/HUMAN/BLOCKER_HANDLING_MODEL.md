==========
HUMAN.BLOCKER_HANDLING_MODEL
==========
STATUS: BATCH_0004_DRAFT

PURPOSE:
Explain how DeveFact behaves when a task cannot continue safely or cleanly.

CORE IDEA:
A blocked task is not a failure by itself. It becomes a controlled decision point.

WHEN A TASK IS BLOCKED:
1. Executor stops only the blocked task.
2. Executor continues other independent READY tasks if safe.
3. Executor creates a Blocker Packet.
4. Orchestrator converts the blocker into a Human Decision Packet.
5. Human chooses one option or requests a new recommendation.
6. Orchestrator updates registers.
7. Executor retries, revises, parks or closes the task.

STANDARD OPTIONS:
- Option A: Conservative / safest path.
- Option B: Balanced / recommended path.
- Option C: Aggressive / faster but higher risk.
- Option D: Park task and continue other work, if applicable.

EXPERT RECOMMENDATION:
Every blocker should include a clear recommendation, not just alternatives.

CLOSE CONDITIONS:
A blocker can be closed only when:
- human decision is recorded; or
- technical issue is resolved and validated; or
- task is explicitly parked/de-scoped; or
- task is converted into technical debt/backlog.
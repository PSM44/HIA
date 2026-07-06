==========
HUMAN.PILOT_SCENARIO.v0
==========
STATUS: BATCH_0003_DRAFT
PURPOSE:
Define the first manual/runnable pilot for DeveFact.

PILOT_NAME:
Tiny App Idea -> DeveFact Task Packet

SCENARIO:
The human wants to create a small internal utility but does not yet know how to specify it.

The Orchestrator must:
1. Ask enough questions to clarify purpose, user, input, output, no-scope and constraints.
2. Produce a short HUMAN product definition.
3. Produce a task packet with up to 6 READY tasks.
4. Hand the packet to an Executor.
5. Receive TOVS_SUMMARY.
6. Update registers and recommend the next batch.

SUCCESS:
A new product idea can be transformed into:
- HUMAN draft;
- decision register entries;
- backlog entries;
- executable task packet;
- validation criteria;
- next action.

NO_SCOPE:
- No real app build yet.
- No UI.
- No API.
- No deploy.
- No push.
- No secrets.
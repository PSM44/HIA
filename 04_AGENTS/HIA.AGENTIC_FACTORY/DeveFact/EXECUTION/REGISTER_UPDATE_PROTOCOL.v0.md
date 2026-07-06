==========
REGISTER_UPDATE_PROTOCOL.v0
==========
STATUS: BATCH_0003_DRAFT

PURPOSE:
Define how Orchestrator updates registers after every execution.

INPUT:
- TOVS_SUMMARY
- human decision
- known project state

UPDATE_RULES:
BACKLOG:
- DONE when objective is achieved and verified.
- READY when task has all READY criteria.
- BLOCKED when human or technical blocker remains.
- CANDIDATE for future ideas not yet executable.

TECH_DEBT:
Register fragile scripts, incomplete docs, missing tests, incomplete prompts, pending decisions and process defects.

BLOCKERS:
Register blocker ID, status, impact, options and recommendation.

CONFLICTS:
Register business, architecture, filesystem, security, cost, dependency, human criteria, validation, scope creep, tool limitation, prompt ambiguity, repo state and canon contradiction.

DECISIONS:
Every meaningful human or system decision must have a DEC ID.

BATON:
Always update current state and next action after material change.
==========
REGISTER_INTEGRITY_POLICY.v1
==========
STATUS: ACTIVE_FROM_BATCH_0017

HARD RULE:
ACCUMULATED registers are canonical detailed history.
They must never be overwritten by summaries.

CANONICAL DETAILED REGISTERS:
- REGISTERS/BACKLOG.ACCUMULATED.md
- REGISTERS/DECISION_REGISTER.md
- REGISTERS/TECH_DEBT.ACCUMULATED.md
- REGISTERS/BLOCKERS.ACCUMULATED.md
- REGISTERS/CONFLICTS.ACCUMULATED.md
- REGISTERS/QUESTIONS_ANSWERS.ACCUMULATED.md
- REGISTERS/IDEAS.RELATED.ACCUMULATED.md
- REGISTERS/IDEAS.UNRELATED.ACCUMULATED.md
- REGISTERS/SKILL_GRC_OPPORTUNITIES.ACCUMULATED.md

SUMMARY RULE:
Summaries must be stored as separate derived artifacts.
Valid summary names include:
- *.SUMMARY.md
- CONTEXT/*.SNAPSHOT.md
- BATON/BATON.STATE.txt

FORBIDDEN:
- Replacing detailed accumulated history with compressed entries.
- Collapsing item ranges such as "BL-001..BL-048" inside accumulated canonical registers as a substitute for details.
- Deleting historical IDs from accumulated registers without explicit recovery/audit batch.

REPAIR APPROACH:
BATCH-0017 creates recovery ledgers derived from Git history.
The ledgers are not a replacement for accumulated registers.
A later repair batch may append missing detailed entries back into accumulated registers based on these ledgers.
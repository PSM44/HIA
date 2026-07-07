==========
RETRY_POLICY.v0
==========
STATUS: BATCH_0004_DRAFT

PURPOSE:
Define when DeveFact should retry, revise, park or escalate.

RETRY_ALLOWED:
- syntax error in runner;
- missing target directory;
- safe path correction;
- read-only verification defect;
- incomplete TOVS output;
- deterministic script defect with clear fix.

RETRY_NOT_ALLOWED_WITHOUT_HUMAN:
- destructive action risk;
- dirty repo with unrelated changes;
- ambiguity about root path;
- secret/credential exposure risk;
- DB/schema modification;
- deploy/push/merge;
- paid tool decision;
- irreversible external side effect;
- repeated failure after 3 attempts.

MAX_ATTEMPTS:
3 attempts per blocker before escalation.

AFTER 3 FAILED ATTEMPTS:
Create Blocker Packet and Human Decision Packet with A/B/C options and recommendation.

PARKING:
A task may be parked if independent READY tasks remain and parking does not hide risk.

ESCALATION:
Escalate when a decision affects architecture, cost, security, legal exposure, data integrity, or product scope.
==========
FIRST_RUN_PLAYBOOK.v0
==========
OBJECTIVE:
Run a first controlled DeveFact cycle from idea to task packet.

STEP 01 - CREATE IDEA:
Write one plain-language need.

Example:
"I need a controlled way to turn a vague operational need into executable AI tasks."

STEP 02 - GENERATE RUN DRY-RUN:
Run DEVF.NEW_RUN.v0.ps1 without -Apply.

STEP 03 - APPLY RUN GENERATION:
Run DEVF.NEW_RUN.v0.ps1 with:
-Apply
-ConfirmText CREATE_DEVF_RUN

STEP 04 - ANSWER DISCOVERY:
Fill A001-A010.

STEP 05 - ORCHESTRATE:
Create Orchestrator output with:
- product name;
- purpose;
- first user;
- no-scope;
- recommendation.

STEP 06 - CREATE EXECUTOR PACKET:
Create a task packet with:
- allowed paths;
- forbidden paths;
- expected TOVS;
- blocker policy.

STEP 07 - VERIFY:
Run the verification script for the current batch.

STEP 08 - COMMIT:
Commit locally only after OK_TO_COMMIT.

STEP 09 - PUSH:
Push only after explicit separate decision.
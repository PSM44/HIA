==========
SIMULATOR_CONTRACT.v0
==========
STATUS: BATCH_0005_DRAFT

PURPOSE:
Define the first local simulator for DeveFact.

The simulator does not build a real application.
It verifies that the DeveFact process can transform a sample idea into controlled artifacts.

SIMULATOR INPUT:
- sample idea;
- discovery questions;
- answers, if available;
- current task packet template;
- current TOVS contract;
- blocker packet template;
- validation loop.

SIMULATOR OUTPUT:
- simulated RUN_ID;
- simulated discovery status;
- simulated task packet status;
- simulated blocker status;
- simulated validation state;
- TOVS_SUMMARY.

NO_SCOPE:
- No external AI call.
- No autonomous agent execution.
- No DB write.
- No build.
- No push.
- No real app generation.
- No secrets.

SUCCESS:
Running the simulator produces a compact TOVS_SUMMARY with:
- EXECUTION_VERDICT;
- SAFE_TO_PROCEED;
- HUMAN_ACTION_REQUIRED;
- DB/CANON/GIT/BUILD flags;
- findings;
- next action.
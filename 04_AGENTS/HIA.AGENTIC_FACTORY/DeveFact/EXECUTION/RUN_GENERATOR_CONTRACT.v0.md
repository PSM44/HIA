==========
RUN_GENERATOR_CONTRACT.v0
==========
STATUS: BATCH_0007_DRAFT

PURPOSE:
Define a reusable local run generator for DeveFact.

The generator creates a controlled run folder from a human idea.
It does not call external AI and does not execute product-building tasks.

INPUTS:
- run_id;
- raw_human_idea;
- first_user;
- output_type;
- no_scope list;
- optional tags.

OUTPUTS:
- RUN.INTAKE.md;
- RUN.DISCOVERY_QUESTIONS.md;
- RUN.ORCHESTRATOR_STUB.md;
- RUN.EXECUTOR_TASK_PACKET.STUB.yaml;
- RUN.TOVS.EXPECTED.txt.

SAFETY:
- No DB write.
- No push.
- No build.
- No external AI call.
- No secrets.
- Writes only under EXECUTION/RUNS/<RUN_ID> unless explicitly changed.

SUCCESS:
A generated run folder can be reviewed by the Orchestrator and then filled with real discovery answers and task packet details.
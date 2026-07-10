==========
SUCCESS_METRICS.v0.1
==========

PRIMARY SUCCESS METRIC v0.1:
Given a minimal controlled case, DeveFact must create, execute, validate and export a complete run with TOVS evidence, no unauthorized push, no secrets, no loss of context and a management-readable explanation.

MEASURE 1 - SPEED:
Time from raw idea to validated run.
Initial target: measurable baseline first; later target <= 30 minutes for minimal case.

MEASURE 2 - DEVELOPMENT VELOCITY:
Number of useful controlled batches completed per work session or overnight cycle.

MEASURE 3 - HUMAN INTERVENTION:
Number of manual confirmations, clarifications and corrections required per run.
Initial tolerance: high.
Direction: trend toward near-zero repetitive manual work.

MEASURE 4 - OVERNIGHT / ASYNC CAPABILITY:
Ability to prepare tasks that other agents/tools can execute while preserving safety and evidence.

MEASURE 5 - TRACEABILITY COMPLETENESS:
Percentage of outputs with:
- objective,
- task ID,
- files created/modified,
- validation,
- TOVS,
- blocker/debt/decision notes,
- next action.

MEASURE 6 - MANAGEMENT UNDERSTANDABILITY:
A non-technical manager should understand in 10 minutes:
- what problem was addressed,
- what was produced,
- how risk was controlled,
- what remains,
- what decision is needed.

FAILURE CONDITIONS:
- Not understandable to management.
- Not functional end to end.
- Loss of context.
- Uncontrolled tool action.
- Unauthorized push/deploy.
- Summarized accumulated registers replacing detailed history.

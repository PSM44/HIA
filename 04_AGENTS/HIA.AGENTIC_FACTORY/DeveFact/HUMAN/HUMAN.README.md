==========
HUMAN.README
==========
STATUS: CANON_DRAFT
PRODUCT_NAME: DeveFact
HIA_MODULE: HIA.AGENTIC_FACTORY
OUTPUT_TYPE: DELIVERABLE_DONE

01.00_QUE_ES_DEVEFACT
DeveFact is a development factory for turning a human technology idea into a developable solution through guided iteration with an IA Orchestrator.

It is based on:
- human intent;
- Spec-Driven definition;
- vibe coding as execution style;
- controlled IA execution;
- accumulated memory;
- blockers and human resolution loops.

02.00_QUE_RESUELVE
A user may have an application idea or technology need but may not know how to transform it into a clear product, specification, development path, executable tasks and controlled implementation.

DeveFact helps define:
- what should be created;
- why it matters;
- what problem it resolves;
- who it is for;
- how it should be used;
- how it should function;
- what the development path is;
- what tasks the IA Executor can execute.

03.00_USUARIO
Initial user: Pablo as technical-functional operator.
Future user: any person with minimum computer literacy.

The system must not assume the user is a developer, architect, Git expert or API operator.

04.00_COMO_FUNCIONA
The human explains the idea, need or expected solution.
The IA Orchestrator asks questions until the functional definition is clear.
The IA Orchestrator generates HUMAN explanation, Q&A, decisions, backlog, development path and a batch of up to 6 tasks.
The IA Executor works sequentially on READY tasks.
If a task is blocked, it is parked, the blocker is registered, independent READY tasks continue, and a human resolution packet is prepared.
The loop repeats until product delivery.

05.00_INTERACCION_USUARIO
The user interacts in natural language.
The system must ask clear questions, explain tradeoffs, detect conflicts, avoid uncontrolled execution, show decisions and impacts, propose expert recommendations and keep accumulated registers separated.

06.00_NO_SCOPE_INICIAL
- UI
- API
- autonomous execution
- multiuser
- API keys or credentials
- GitHub Actions
- deploy
- automatic merge/push
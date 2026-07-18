==========
00.00_METADATA
==========

ID_UNICO..........: HUMAN.DEVEFACT.0001
NOMBRE_SUGERIDO...: HUMAN.DEVEFACT.md
VERSION...........: v0.2-CANON_DRAFT
FECHA.............: 2026-07-18
UBICACION_SISTEMA.: HUMAN
AUTOR_HUMANO......: PABLO
DOCUMENT_ROLE.....: HUMAN_ROOT
STATUS............: CANON_DRAFT
PRODUCT_NAME......: DeveFact
HIA_MODULE........: HIA.AGENTIC_FACTORY
OUTPUT_TYPE.......: DELIVERABLE_DONE

ALCANCE...........:
Define la identidad, proposito, usuario, funcionamiento general, interaccion y
jerarquia documental HUMAN de DeveFact.

NO_CUBRE..........:
No reemplaza los HUMAN especializados, los contratos tecnicos, BATON, WHOAMI,
registros, validaciones, herramientas ni evidencia de ejecucion.

==========
00.10_PURPOSE_AND_AUTHORITY
==========

Este archivo es el HUMAN root unico de DeveFact.

Gobierna:
- identidad y proposito general;
- alcance funcional superior;
- navegacion del canon HUMAN;
- precedencia entre documentos HUMAN;
- interpretacion conceptual cuando no existe una regla mas especifica.

No debe usarse como backlog, BATON, changelog tecnico ni repositorio de evidencia.

==========
00.20_CANONICAL_HUMAN_STRUCTURE
==========

1. HUMAN.DEVEFACT.md
   HUMAN root. Gobierna identidad, proposito, alcance general, navegacion y precedencia.

2. HUMAN.PRODUCT_DEFINITION.md
   HUMAN hijo. Gobierna la definicion funcional detallada del producto.

3. HUMAN.OPERATING_PRINCIPLES.md
   HUMAN hijo. Gobierna los principios de interaccion y operacion humano-IA.

4. HUMAN.OUT_OF_SCOPE.md
   HUMAN hijo. Gobierna exclusiones, limites y materias fuera de alcance.

Los demas archivos bajo HUMAN pueden ser guias, demos, playbooks, artefactos
gerenciales o documentacion especializada. No adquieren autoridad de HUMAN root
solo por estar ubicados en esta carpeta.

==========
00.30_PRECEDENCE_AND_CONFLICT_RULE
==========

PRECEDENCE:

1. HUMAN.DEVEFACT.md gobierna identidad, proposito, alcance general y navegacion.
2. HUMAN.PRODUCT_DEFINITION.md gobierna la definicion funcional detallada.
3. HUMAN.OPERATING_PRINCIPLES.md gobierna los principios de operacion humano-IA.
4. HUMAN.OUT_OF_SCOPE.md gobierna exclusiones y limites.
5. Un HUMAN hijo no puede contradecir al HUMAN root.
6. Las contradicciones no se resuelven por inferencia silenciosa.
7. Toda contradiccion debe registrarse y elevarse a decision humana.
8. BATON y WHOAMI reflejan HUMAN; no lo reemplazan.

==========
00.40_CHANGE_POLICY
==========

Modificar este HUMAN root solo cuando cambie:
- la identidad o proposito de DeveFact;
- el alcance general;
- la estructura canonica HUMAN;
- la precedencia documental;
- una decision humana rectora.

Los cambios operativos normales deben registrarse en BATON, registros, ejecucion
o validacion, segun corresponda.

==========
01.00_FUNCTIONAL_CANON
==========

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

==========
07.00_KEY_DECISIONS
==========

- DeveFact se desarrolla como modulo HIA.AGENTIC_FACTORY.
- La interaccion principal es humano + IA Orchestrator.
- El usuario no debe necesitar conocimientos avanzados de desarrollo, Git o APIs.
- La ejecucion autonoma, deploy, multiusuario y manejo de credenciales permanecen fuera del alcance inicial.
- HUMAN.DEVEFACT.md es el unico HUMAN root.
- Los HUMAN especializados permanecen separados para conservar modularidad y trazabilidad.

==========
08.00_CHANGELOG
==========

2026-07-18, v0.2-CANON_DRAFT
- Renombrado desde HUMAN.README.md a HUMAN.DEVEFACT.md.
- Declarado como HUMAN root unico.
- Agregada jerarquia documental y regla de precedencia.
- Conservado el contenido funcional existente sin cambio de sentido.
- CIS: DEVF-CIS-HUMAN-ROOT-0001.

Version anterior:
- HUMAN.README.md, STATUS=CANON_DRAFT.
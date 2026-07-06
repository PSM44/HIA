==========
QUESTIONS_ANSWERS.ACCUMULATED
==========
QSET_ID: HIA_AGF_QSET_0001
STATUS: EXPANDED_V1
DATE: 2026-07-06
MODE: GPT.Upload.Lock

FORMAT_RULE:
Each Q&A must preserve ID, date, status and derived decision. Conflicts must be registered, not silently resolved.

QA-001
QUESTION: Nombre operativo del producto.
ANSWER: DeveFact, por Development Factory.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-001 PRODUCT_NAME = DeveFact.

QA-002
QUESTION: Definicion en una frase.
ANSWER: Orquestacion de desarrollo de aplicaciones o soluciones tecnologicas con foco en vibe coding y Spec-Driven. La base es iterar lo que se quiere con el humano y luego desarrollar con IA.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-002 DeveFact = orquestacion de desarrollo con Spec-Driven vibe coding.

QA-003
QUESTION: Problema principal.
ANSWER: El usuario tiene una idea de desarrollo TI. El usuario plantea necesidad y solucion con IA. La IA lo hace posible. El aprendizaje tecnologico del usuario puede ocurrir, pero no es el foco. La IA debe iterar preguntas hasta entender que, como, por que, como se usa y que se espera; luego orquesta tareas secuenciales, aparca conflictos o dudas, continua otras tareas y genera loop hasta lograr producto.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-003 Valor primario = orquestacion de desarrollo; aprendizaje = secundario.

QA-004
QUESTION: Usuario principal.
ANSWER: Primera instancia Pablo. Despues cualquier persona que sepa lo minimo de uso de computador.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-004 Initial user Pablo; future user basic computer literacy.

QA-005
QUESTION: Resultado esperado.
ANSWER: Lo explicado en Q003, avanzando desde lo facil a lo dificil.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-005 Desarrollo incremental facil-a-dificil.

QA-006
QUESTION: Primer output.
ANSWER: Desarrollo correcto de que, como, para que, que resuelve, como se usa, diagramas basicos para explicar y tareas para indicar a la IA como comenzar.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-006 FIRST_OUTPUT_CONTRACT funcional-documental.

QA-007
QUESTION: Output type.
ANSWER: No se. Recomendacion IA aceptada luego: DELIVERABLE_DONE.
ANSWER_STATUS: RESOLVED_BY_RECOMMENDATION
DECISION_DERIVED: DEC-007 OUTPUT_TYPE = DELIVERABLE_DONE.

QA-008
QUESTION: Primer contrato de entrega.
ANSWER: Explicacion de lo que se va a crear, como, por que, que resuelve, como se usa, para quien esta dirigido y path de desarrollo.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-008 First output contract.

QA-009
QUESTION: Must-have minimo.
ANSWER: No se. IA propone must-have v0.1: discovery guiado, HUMAN canon, Q&A register, registros separados, batch max 6, READY criteria, blocker parking A/B/C, Human Resolution Packet, autonomia L1-L2, DONE evidence.
ANSWER_STATUS: RESOLVED_BY_RECOMMENDATION
DECISION_DERIVED: DEC-009 MUST_HAVE_V0.1.

QA-010
QUESTION: No-scope inicial.
ANSWER: UI, API, ejecucion autonoma, multiusuario, claves y credenciales, GitHub Actions.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-010 NO_SCOPE_INITIAL.

QA-011
QUESTION: HUMAN root.
ANSWER: La carpeta HUMAN contiene todo el texto enfocado en explicar a humanos y es canon. Lo fuera de HUMAN es prioritariamente para entendimiento IA/maquinas y secundariamente para humanos.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-011 HUMAN = canon funcional humano.

QA-012
QUESTION: Contenido HUMAN obligatorio.
ANSWER: Todo lo necesario para que cualquier persona externa entienda que es, para que sirve, que resuelve, como se usa y path de desarrollo.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-012 HUMAN muy explicativo.

QA-013
QUESTION: Nivel de detalle HUMAN.
ANSWER: Muy explicativo.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-013 HUMAN_DETAIL = VERY_EXPLANATORY.

QA-014
QUESTION: Decisiones humanas en HUMAN vs Decision Register.
ANSWER: No se. Regla provisional: HUMAN resume decision funcional canon; DECISION_REGISTER conserva granularidad operativa.
ANSWER_STATUS: PROVISIONAL
DECISION_DERIVED: DEC-014 HUMAN + DECISION_REGISTER dual.

QA-015
QUESTION: Actualizacion HUMAN.
ANSWER: Lo minimo posible, porque puede cambiar el sentido del desarrollo drasticamente.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-015 HUMAN_CHANGE_CONTROL minimal.

QA-016
QUESTION: Backlog acumulado.
ANSWER: Tambien ideas futuras aun inmaduras.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-016 Backlog includes executable and immature future ideas.

QA-017
QUESTION: Deuda tecnica.
ANSWER: Codigo malo, documentacion insuficiente, decisiones pendientes, scripts fragiles, falta de tests, prompts incompletos.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-017 TECH_DEBT taxonomy.

QA-018
QUESTION: Ideas relacionadas.
ANSWER: Tambien ideas para SkillsMachine, CloseReport, Nightshift, OpenCode.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-018 RELATED_IDEAS scope broad.

QA-019
QUESTION: Ideas no relacionadas.
ANSWER: Dentro del modulo.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-019 unrelated ideas captured inside module as capture-only.

QA-020
QUESTION: Q&A acumuladas.
ANSWER: Con ID, fecha, estado y decision derivada.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-020 Q&A register format.

QA-021
QUESTION: IA Orquestadora.
ANSWER: Lo mas sencillo posible primero.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-021 Orchestrator v0 simple conversational.

QA-022
QUESTION: IA Ejecutora.
ANSWER: Lo mas sencillo posible primero.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-022 Executor v0 simple/manual-assisted.

QA-023
QUESTION: Batch de 6 tareas.
ANSWER: OK. Maximo 6, no necesariamente llenar 6.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-023 Batch max 6.

QA-024
QUESTION: Criterio READY.
ANSWER: No se. IA propone: task_id, objetivo, output, scope, no-scope, files_allowed, dependencies, acceptance criteria, validation, blocker policy, autonomy level, controlled risk.
ANSWER_STATUS: RESOLVED_BY_RECOMMENDATION
DECISION_DERIVED: DEC-024 READY_CRITERIA.

QA-025
QUESTION: Tareas bloqueadas.
ANSWER: Tambien proponer opciones A/B/C con recomendacion en rol experto e industria especializada.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-025 Blocker options A/B/C with expert recommendation.

QA-026
QUESTION: Tipos de conflicto.
ANSWER: OK a negocio, arquitectura, filesystem, seguridad, costo, dependencia, criterio humano, validacion.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-026 Conflict types.

QA-027
QUESTION: Resolucion humana.
ANSWER: Recomendacion ejecutiva con impacto; si se pide, iterar y profundizar.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-027 Human resolution packet style.

QA-028
QUESTION: HUMAN vs Skill.
ANSWER: Iremos iterando y profundizando. Regla provisional: HUMAN manda en intencion funcional; Skills mandan en metodo tecnico/seguridad/gobernanza; conflicto se declara.
ANSWER_STATUS: PROVISIONAL
DECISION_DERIVED: DEC-028 HUMAN vs SKILL precedence provisional.

QA-029
QUESTION: Velocidad vs gobernanza.
ANSWER: Se bloquea; no correremos con los ojos cerrados.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-029 No blind execution.

QA-030
QUESTION: Stop-loss.
ANSWER: Riesgo de borrar archivos, ambiguedad de root, seguridad, costo, repo sucio y cualquier otro riesgo material segun experto/industria.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-030 Stop-loss.

QA-031
QUESTION: Carpeta TOOLS.
ANSWER: Debe seguir convencion interna de Skills, si no hay de HIA.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-031 TOOLS convention follows Skills unless HIA convention exists.

QA-032
QUESTION: RADAR outputs.
ANSWER: RADAR/ACTIVE y RADAR/HISTORY.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-032 RADAR output folders.

QA-033
QUESTION: RADAR.ps1 unico.
ANSWER: Dejalo asi.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-033 RADAR.ps1 fixed name.

QA-034
QUESTION: Frecuencia RADAR.
ANSWER: Cuando sea necesario.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-034 RADAR on demand.

QA-035
QUESTION: RADAR y costo IA.
ANSWER: OK a LITE/INDEX por defecto, CORE por modulo, FULL solo auditoria.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-035 RADAR context policy.

QA-036
QUESTION: Autonomia inicial.
ANSWER: OK a L1-L2.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-036 Autonomy L1-L2.

QA-037
QUESTION: Uso API/costo.
ANSWER: Si; avisar si herramientas pagas aceleran el desarrollo.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-037 FREE_FIRST with paid-tool escalation.

QA-038
QUESTION: Secrets.
ANSWER: Confirmado; nada que pase a GitHub debe tener API keys o riesgo.
ANSWER_STATUS: CONFIRMED
DECISION_DERIVED: DEC-038 No secrets.

QA-039
QUESTION: Validacion DONE.
ANSWER: No se. IA propone DONE evidence: task_id, objetivo, archivos, hash/evidencia, diff/resumen, validacion, OK/FAIL, blockers/deuda/decision humana, AI_TAIL/TOVS, next action.
ANSWER_STATUS: RESOLVED_BY_RECOMMENDATION
DECISION_DERIVED: DEC-039 DONE_EVIDENCE.

QA-040
QUESTION: Primer piloto real.
ANSWER: OK a construir estructura propia / integrarlo a HIA como piloto.
ANSWER_STATUS: CONFIRMED_BY_CONTEXT
DECISION_DERIVED: DEC-040 First pilot = HIA.AGENTIC_FACTORY/DeveFact.
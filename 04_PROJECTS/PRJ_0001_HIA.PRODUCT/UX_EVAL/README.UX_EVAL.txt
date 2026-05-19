==========
00.00_METADATA
==========

ID_UNICO..........: UX_EVAL.README
PROJECT_ID........: PRJ_0001_HIA.PRODUCT
CREATED_LOCAL.....: 2026-05-19 19:42:42
CREATED_UTC.......: 2026-05-19T23:42:42.3390624Z
ROOT..............: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA
PROJECT_ROOT......: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\04_PROJECTS\PRJ_0001_HIA.PRODUCT
PURPOSE...........: Definir el sistema mínimo de registro para evaluación funcional UX/UI de HIA.

==========
01.00_PURPOSE
==========

UX_EVAL contiene la evaluación versionable de UX/UI del proyecto HIA.

Este directorio existe para evitar que la evaluación visual/funcional quede dispersa en:
- chat,
- terminal,
- comentarios sueltos,
- screenshots sin criterio,
- runtime artifacts ignorados por Git.

==========
02.00_RULES
==========

02.10_VERSIONABLE_CONTENT

Debe versionarse aquí:
- criterios de evaluación,
- hallazgos,
- issues UX/UI,
- decisiones,
- cambios de scope,
- estado de madurez,
- acciones siguientes.

02.20_RUNTIME_CONTENT

Debe quedar en ARTIFACTS\UX_EVAL:
- screenshots,
- videos,
- logs largos,
- exports temporales,
- evidencia pesada.

02.30_NO_HYPE_RULE

La evaluación UX/UI debe distinguir:
- funcionalidad realmente lista,
- funcionalidad simulada o estática,
- brecha conocida,
- mejora deseable,
- deuda técnica.

==========
03.00_FILES
==========

UX_UI.EVALUATION.LOG.txt:
Bitácora acumulativa de evaluaciones UX/UI.

UX_UI.EVALUATION.CHECKLIST.txt:
Checklist de criterios de evaluación.

UX_UI.ISSUES.BACKLOG.txt:
Backlog específico de problemas UX/UI.

UX_UI.DECISIONS.LOG.txt:
Registro de decisiones de diseño/UX/UI.

==========
04.00_CURRENT_UI_UNDER_EVALUATION
==========

UI_VERSION........: HIA Management Dashboard v0.1
UI_PATH...........: 01_UI\web\HIA.MANAGEMENT.DASHBOARD.v0.1.html
RUNNER............: 02_TOOLS\Run-PRJPB-008C.ps1
STATUS............: static local HTML
KNOWN_LIMITATION..: no live data binding yet

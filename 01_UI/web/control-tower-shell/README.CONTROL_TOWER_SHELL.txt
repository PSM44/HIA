===============================================================================
FILE..............: README.CONTROL_TOWER_SHELL.txt
PROJECT...........: PRJ_0001_HIA.PRODUCT
PURPOSE...........: Documentar Control Tower shell.
===============================================================================

01.00_ARCHITECTURE

Esta shell separa tres niveles:

01. HIA Control Tower global.
02. Portfolio multi-proyecto.
03. Project Workspace por proyecto.

02.00_AI_COST_MODEL

La UI separa:
- AI Control Tower global.
- Project AI.
- Cost Center global.
- Project Costs.

03.00_SCOPE

Esta versión no pretende conectar todos los datos reales.
Sirve para validar arquitectura de información y navegación.

04.00_NEXT

PRJPB_009N:
Conectar hia.state.js a Control Tower / Portfolio / Project Workspace.
===============================================================================

===============================================================================
PRJPB_009M_B_STITCH_BASED_CONTROL_TOWER_V02
===============================================================================
FECHA_LOCAL.......: 2026-06-04 17:32:50 -0400
STATUS............: DONE
PURPOSE...........: Evolucionar Control Tower Shell usando Stitch como UX reference baseline.

01.00_DECISION
- Stitch se usa como baseline conceptual de UX.
- Figma queda como referencia secundaria.
- No se copian datos fake como reales.
- Todo dato sin fuente se marca como pendiente/demo/backend pendiente.

02.00_VIEWS
- Torre de Control HIA.
- Portafolio.
- Control de IA.
- Centro de Costos.
- Workspace / Vista General.
- IA / Chat del Proyecto.
- Costos del Proyecto.
- Evidencia del Proyecto.
- Informes.
- Colaboración.
- Integraciones.
- Bóveda / Conocimiento.
- Configuración Global.

03.00_NEXT
- PRJPB_009N: conectar hia.state.js fino a shell v0.2.
===============================================================================

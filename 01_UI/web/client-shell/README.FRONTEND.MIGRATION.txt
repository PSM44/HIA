===============================================================================
FILE..............: README.FRONTEND.MIGRATION.txt
PROJECT...........: PRJ_0001_HIA.PRODUCT
PURPOSE...........: Documentar base front-end migrable a Vite/React/Next/PWA.
===============================================================================

01.00_CURRENT_APPROACH

La app shell actual usa HTML/CSS/JS sin build para validar UX rápido.

Rutas:
- index.html
- assets/app.css
- assets/app.js
- manifest.webmanifest
- sw.js

02.00_DESIGN_DECISION

Se evita npm/build en esta fase para reducir fricción.
La estructura queda PWA-ready y migrable.

03.00_MIGRATION_TO_VITE_REACT

Ruta sugerida:
- Mantener index.html.
- Mover assets/app.css a src/styles/app.css.
- Convertir assets/app.js en src/main.jsx.
- Extraer STATE y ROUTES a src/state y src/routes.
- Convertir render functions a componentes React.
- Mantener manifest.webmanifest y sw.js bajo public/.

04.00_MIGRATION_TO_NEXT

Ruta sugerida:
- Crear app/ o pages/ según versión seleccionada.
- Convertir cada route de app.js en página o componente.
- Mantener STATE como data layer inicial.
- Crear API route futura para leer estado desde JSON generado por CLI.

05.00_PWA_NOTES

Para instalación en celulares/computadores:
- manifest.webmanifest es obligatorio.
- service worker es obligatorio.
- Requiere HTTPS o localhost.
- file:// no es suficiente para PWA real.

06.00_NEXT_TECHNICAL_STEP

PRJPB_009K:
Generar estado real desde CLI/BATON/BACKLOG/RADAR hacia un archivo JSON o JS state consumible por la app shell.
===============================================================================

===============================================================================
07.00_PORTFOLIO_SCOPE_UPDATE_PRJPB_009J_B
===============================================================================

La app shell ya no debe modelar solo un proyecto.
Debe modelar dos niveles:

01. HIA SYSTEM / PORTFOLIO
- múltiples proyectos
- reportes
- colaboración
- integraciones
- estado global

02. PROJECT DETAIL
- proyecto activo seleccionado
- estado operativo
- evidencia
- backlog / MiniBattles
- próxima acción

La futura migración a Vite/React/Next debe respetar esta separación:
- /portfolio
- /projects/:projectId
- /reports
- /collaboration
- /integrations
- /evidence
- /tech-debt
===============================================================================

===============================================================================
08.00_AI_OPERATING_LAYER_UPDATE_PRJPB_009K_B
===============================================================================

La app shell incorpora AI Operating Layer como capa de producto.

Nuevas vistas:
- AI Cockpit.
- Chat IA.
- Selector IA.
- Costos / Tokens.
- Contexto activo.

Estado actual:
- UI preparada.
- Backend pendiente.
- No se simulan llamadas reales a modelos.
- No se inventan tokens ni costos reales.

Migración futura:
- Convertir cada vista AI en componente.
- Crear AI provider registry.
- Crear model routing policy.
- Crear cost/token telemetry.
- Conectar chat workbench a backend seguro.
===============================================================================

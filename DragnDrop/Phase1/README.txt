HIA_DRAGNDROP_README
DATE......: 2026-03-11
TIME......: 17:25
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: v1.1-DRAFT
PHASE: Phase1
INCLUDE_RADAR: Index
GENERATED.: 20260311_172537
RULES.....: GENERATED-ONLY. NO EDITAR MANUALMENTE.
RULES.....: PROHIBIDO EDITAR A MANO.

FILES_INCLUDED (copiados desde HUMAN.README y/o framework):
 - 04.0_HUMAN.BATON.txt
 - 05.0_HUMAN.CIS.txt
 - 06.0_HUMAN.PF0.txt
 - 08.0_HUMAN.SYNC.MANIFEST.txt
 - Radar.Index.ACTIVE.txt

CLOUD_CONTRACT:
- Responde PRIMERO: acuso leído
- Luego lista exacta de archivos leídos (uno por línea)
- Si falta un requerido: FAIL determinista
- Si inventa un archivo: FAIL (alucinación)

IF_MISSING: si falta un archivo esperado, re-ejecuta el tool (no copies a mano).

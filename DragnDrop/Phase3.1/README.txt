HIA_DRAGNDROP_README
DATE......: 2026-03-07
TIME......: 01:00
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: v1.1-DRAFT
PHASE: Phase3.1
PHASE.....: Phase3.1
GENERATED.: 20260307_010001
RULES.....: GENERATED-ONLY. NO EDITAR MANUALMENTE.
RULES.....: PROHIBIDO EDITAR A MANO.
INCLUDE_RADAR: None

FILES_INCLUDED (copiados desde HUMAN.README y/o RADAR toggle):
 - 04.0_HUMAN.BATON.txt
 - 06.0_HUMAN.PF0.txt
 - HIA_MTH_0001_WORKFLOW.txt

CLOUD_CONTRACT:
- Responde PRIMERO: acuso leído
- Luego lista exacta de archivos leídos (uno por línea)
- Si falta un requerido: FAIL determinista
- Si inventa un archivo: FAIL (alucinación)

IF_MISSING: si falta un archivo esperado, re-ejecuta el tool (no copies a mano).

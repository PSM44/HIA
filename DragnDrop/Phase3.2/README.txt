HIA_DRAGNDROP_README
DATE......: 2026-03-07
TIME......: 01:00
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: v1.1-DRAFT
PHASE: Phase3.2
PHASE.....: Phase3.2
GENERATED.: 20260307_010013
RULES.....: GENERATED-ONLY. NO EDITAR MANUALMENTE.
RULES.....: PROHIBIDO EDITAR A MANO.
INCLUDE_RADAR: None

FILES_INCLUDED (copiados desde HUMAN.README y/o RADAR toggle):
 - 04.0_HUMAN.BATON.txt
 - 05.0_HUMAN.CIS.txt
 - 06.0_HUMAN.PF0.txt
 - HIA_POL_0001_AI_EXECUTION.txt

CLOUD_CONTRACT:
- Responde PRIMERO: acuso leído
- Luego lista exacta de archivos leídos (uno por línea)
- Si falta un requerido: FAIL determinista
- Si inventa un archivo: FAIL (alucinación)

IF_MISSING: si falta un archivo esperado, re-ejecuta el tool (no copies a mano).

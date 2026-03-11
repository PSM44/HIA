HIA_DRAGNDROP_README
DATE......: 2026-03-11
TIME......: 17:25
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: v1.1-DRAFT
PHASE: Phase0
INCLUDE_RADAR: None
GENERATED.: 20260311_172522
RULES.....: GENERATED-ONLY. NO EDITAR MANUALMENTE.
RULES.....: PROHIBIDO EDITAR A MANO.

FILES_INCLUDED (copiados desde HUMAN.README y/o framework):
 - 00.0_HUMAN.GENERAL.txt
 - 01.0_HUMAN.USER.txt
 - 04.0_HUMAN.BATON.txt
 - 07.0_HUMAN.MASTER.txt
 - 08.0_HUMAN.SYNC.MANIFEST.txt
 - 09.0_HUMAN.START.RITUAL.txt

CLOUD_CONTRACT:
- Responde PRIMERO: acuso leído
- Luego lista exacta de archivos leídos (uno por línea)
- Si falta un requerido: FAIL determinista
- Si inventa un archivo: FAIL (alucinación)

IF_MISSING: si falta un archivo esperado, re-ejecuta el tool (no copies a mano).

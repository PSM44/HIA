==========
LINE_ENDING_POLICY.v1
==========
STATUS: BATCH_0016_DRAFT

SCOPE:
This policy is intentionally scoped to:
04_AGENTS/HIA.AGENTIC_FACTORY/DeveFact/.gitattributes

DECISION:
Do not create or modify repository-root .gitattributes in this batch.

POLICY:
- Markdown / text / yaml / json: LF.
- PowerShell scripts: CRLF.
- Images, PDFs, Excel and archives: binary.

RATIONALE:
Git repeatedly warned that LF would be replaced by CRLF on tracked DeveFact text files.
The policy should be explicit and local to DeveFact before future commits accumulate more inconsistent line endings.

SAFETY:
- No DB modification.
- No build.
- No push.
- No global repo line-ending policy change.

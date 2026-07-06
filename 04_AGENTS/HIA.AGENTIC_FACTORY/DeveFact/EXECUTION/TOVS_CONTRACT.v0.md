==========
TOVS_CONTRACT.v0
==========
STATUS: BATCH_0003_DRAFT

PURPOSE:
Standardize the compact execution report returned by any runner or Executor.

REQUIRED_BLOCK:
TOVS_SUMMARY_START
AI_TAIL_SCHEMA=v1
MB_ID=<id>
FINAL_STATUS=<PASS|PASS_WITH_REVIEW|FAIL>
BLOCKER=<NONE|text>
PROJECT_ROOT=<path>
TEMP_PATH=<path>
TOVS_ONLY_MODE=ON
MAX_PASTE_CHARS=9000
DB_MODIFIED=<NO|YES|DOCS_ONLY>
CANON_MODIFIED=<NO|DOCS_ONLY|YES>
COMMIT_PUSH_PERFORMED=<NO|YES>
BUILD_EXECUTED=<NO|YES>
WARNINGS=<NONE|text>
KEY_FINDINGS:
* ...
DECISIONS_NEEDED:
* ...
NEXT_ACTION=<instruction>
TOVS_SUMMARY_END

RULES:
- No raw full logs by default.
- No file upload required by default.
- Report failures honestly.
- Always state whether DB, canon, git or build changed.
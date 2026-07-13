# Proposed Skills and GRC — Accumulated

Project: PRJ_0001_HIA.PRODUCT

Purpose: cumulative, append-only registry of reusable skills, guardrails, operational rules, failure patterns, and remediations discovered while developing HIA.

Rules:
- Preserve historical entries.
- Distinguish observed failure, root cause, remediation, and reusable candidate.
- Do not treat a proposal as an active canonical Skill/GRC until separately reviewed and promoted.
- Prefer minimal human feedback blocks (AI_START / AI_END) over file uploads when full artifacts are not required.

---

## 2026-07-13 — PRJPB_010O/010P browser-validation and runner hardening lessons

### Context

Project Workspace implementation completed at 3031a35. Browser validation required several failed automation attempts before a reliable human-console validation produced 13/13 PASS checks. Navigation implementation later completed at 62e4fa.

### Observed failures and resolutions

#### 1. PowerShell here-string interpolated JavaScript template expressions

- Failure: PowerShell attempted to resolve JavaScript expressions such as ${escapeHtml(...)} inside a double-quoted here-string.
- Symptom: variable retrieval error before repository mutation.
- Root cause: mixing PowerShell interpolation and JavaScript template literals in the same interpolated block.
- Resolution: use single-quoted literal here-strings for JavaScript and inject only explicitly generated JSON between literal prefix/suffix blocks.
- Reusable rule: never embed JavaScript template literals in PowerShell @"..."@ unless every $ is intentionally escaped.

#### 2. Edge --dump-dom produced no captured stdout

- Failure: Edge returned exit code 0 while PowerShell captured zero DOM bytes.
- Symptom: BROWSER_RESULT_NOT_FOUND_IN_DOM and later EDGE_RETURNED_EMPTY_DOM.
- Root cause: the installed Edge executable behaved as a launcher and detached/delegated execution; neither & capture nor Start-Process -RedirectStandardOutput produced the DOM in this environment.
- Resolution: stop retrying the same automation mechanism and switch to direct human browser-console validation.
- Reusable rule: exit code 0 is insufficient evidence; require non-empty output and expected semantic markers.

#### 3. Diagnostic code failed on null stdout/stderr

- Failure: GetByteCount() received $null.
- Symptom: diagnostic exception masked the underlying browser-capture failure.
- Root cause: assuming Get-Content -Raw always returns a non-null string.
- Resolution: normalize missing/empty streams to "" before byte calculations.
- Reusable rule: diagnostics must never be less robust than the operation they diagnose.

#### 4. Excessive retries increased operational cost

- Failure pattern: multiple incremental runners attempted to repair an environment-specific Edge behavior.
- Impact: repeated user execution, reduced confidence, avoidable churn.
- Resolution: after two materially different automated capture attempts fail, stop and use a simpler validated fallback.
- Reusable rule: define a retry budget and a fallback path before running environment-dependent automation.

#### 5. Human browser-console validation was reliable and sufficient

- Validation result: 13 checks, 13 PASS, 0 failed.
- Validated:
  - workspace and view globals exist;
  - schema and project ID;
  - no-fake-data;
  - read-only mode;
  - implementation/view gates;
  - rendered project;
  - visible PASS gate.
- Resolution: formalize the human result in repository evidence with a small deterministic script.
- Reusable rule: human validation can be first-class evidence when its checks are explicit, machine-readable, reproducible, and subsequently committed.

#### 6. Avoid unnecessary file uploads

- User rule: request file uploads only when strictly necessary.
- Preferred feedback:
  - AI_START
  - concise machine-readable result
  - AI_END
- Reusable rule: use text feedback while it fits safely in the chat; request artifacts only for content that cannot be reconstructed or verified from the feedback.

#### 7. Temporary folder policy

- Current HIA rule: clean all content under C:\Users\aazcl\Downloads\T_HIA before every execution.
- Scripts must be stored outside T_HIA.
- Reusable rule: disposable temp roots must be cleaned before generation and never treated as repository canon.

#### 8. Line-ending warnings

- Observation: Git emitted LF/CRLF normalization warnings during commit.
- Result: commit succeeded and Git remained clean.
- Candidate follow-up: define .gitattributes policy for .js, .json, .txt, .md, .ps1.
- Reusable rule: line-ending warnings are non-blocking only when git diff --check, commit, and final clean status all pass.

### Proposed Skill candidates

#### SKILL-CANDIDATE-HIA-001 — PowerShell generator for embedded JavaScript

Scope:
- literal here-string discipline;
- explicit JSON injection;
- UTF-8 without BOM;
- JavaScript syntax validation;
- prevention of accidental PowerShell interpolation.

#### SKILL-CANDIDATE-HIA-002 — Browser validation with deterministic fallback

Scope:
- static validation first;
- automated browser validation second;
- output-presence and semantic-marker gates;
- bounded retry budget;
- human-console fallback;
- formalization of human PASS evidence.

#### SKILL-CANDIDATE-HIA-003 — Minimal AI feedback protocol

Scope:
- AI_START / AI_END;
- concise key-value or JSON result;
- maximum useful inline feedback before requesting artifact upload;
- explicit conditions that justify file uploads.

#### SKILL-CANDIDATE-HIA-004 — Disposable temp-root execution

Scope:
- clean temp root before execution;
- runner stored outside temp;
- no canonical data in temp;
- maximum upload package size;
- final AI_TAIL generation.

### Proposed GRC candidates

#### GRC-CANDIDATE-HIA-001 — No repository mutation before validation gate

Controls:
- exact expected HEAD;
- Git clean before mutation;
- validate generated artifacts before state updates;
- commit only after all pre-commit gates pass;
- no push unless explicitly authorized.

#### GRC-CANDIDATE-HIA-002 — Environment-dependent automation retry budget

Controls:
- maximum two materially distinct attempts;
- each attempt must test a different root-cause hypothesis;
- stop when evidence shows the runtime mechanism is unsupported;
- switch to documented fallback rather than iterative patching.

#### GRC-CANDIDATE-HIA-003 — Diagnostics cannot mask primary failures

Controls:
- null-safe diagnostics;
- preserve original exception context;
- report exit code, output size, stderr size, and evidence path;
- diagnostic failures must not replace the original operational failure.

#### GRC-CANDIDATE-HIA-004 — Browser PASS evidence standard

Required checks:
- global contract exists;
- view contract exists;
- expected schema;
- expected real project ID;
- no-fake-data true;
- read-only mode;
- implementation gate;
- view gate;
- rendered project;
- visible gate;
- zero failed checks.

#### GRC-CANDIDATE-HIA-005 — Upload minimization

Controls:
- do not request generated files when AI_START/AI_END is sufficient;
- request files only for non-reconstructable evidence, source review, or failure diagnosis;
- state exactly which file is required and why.

### Promotion status

All entries above are proposals only. They must be reviewed through the SkillsMachine update/support workflow before becoming canonical Skills or GRCs.

---

## 2026-07-13 — Semantic validator rule

A validator falsely failed because it matched exact serialized JSON whitespace instead of semantic content.

Resolution:
- validate parsed values, schema, object shape, or whitespace-tolerant semantic patterns;
- do not make incidental serialization formatting an acceptance criterion;
- distinguish invalid artifact content from a defective assertion;
- repair from the expected dirty state without regenerating or duplicating content.

Promotion status: proposed, not canonical.

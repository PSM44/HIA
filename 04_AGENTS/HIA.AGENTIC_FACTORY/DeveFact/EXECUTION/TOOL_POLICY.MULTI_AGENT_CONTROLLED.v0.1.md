==========
TOOL_POLICY.MULTI_AGENT_CONTROLLED.v0.1
==========

STATUS: ACTIVE_DRAFT

PREVIOUS POLICY:
FREE_FIRST was useful initially, but incomplete.

CURRENT POLICY:
MULTI_AGENT_CONTROLLED_WITH_COST_AWARENESS

SUPPORTED TOOL TYPES:
- ChatGPT Plus / GPT Plus.
- Claude Code Plus.
- OpenCode.
- Free AI tools.
- Git.
- GitHub.
- VS Code optionally.
- PowerShell / shell runners.
- Human operators.

ROLE MODEL:
- Orchestrator / Control Tower: currently human + IA in chat.
- Executor: preferably another AI/tool when available.
- Human: approves scope, confirms risky actions, reviews TOVS.

COST RULE:
Free tools may be preferred when sufficient.
Paid/Plus tools may be used when materially useful and human-authorized.

SAFETY RULES:
- No push unless explicitly requested.
- No deploy unless explicitly requested.
- No secrets in repo, TOVS, logs, BATON or HUMAN docs.
- No destructive actions without explicit confirmation.
- No modification outside allowed paths.
- No autonomous paid tool usage without approval.

OVERNIGHT WORK:
Desired direction: enable overnight/asynchronous work by preparing controlled task packets and evidence requirements.
Initial risk tolerance should remain low until validation hardens.

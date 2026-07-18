==========
SKILL_GRC_OPPORTUNITIES.ACCUMULATED
==========
SGO-001 SKILL.ACCUMULATED_REGISTERS_POLICY
SGO-002 SKILL.AI_ORCHESTRATOR_BATCH_POLICY
SGO-003 SKILL.BLOCKER_PARKING_AND_HUMAN_RESOLUTION
SGO-004 SKILL.AGENTIC_FACTORY_TASK_SCHEMA
SGO-005 GRC.AGENTIC_AUTONOMY_LEVELS
SGO-006 GRC.FALSE_DONE_CONTROL
SGO-007 GRC.HUMAN_DECISION_PACKET
SGO-008 GRC.DEVEFACT_FREE_FIRST_TOOL_POLICY
SGO-009 GRC.DEVEFACT_SPEC_DRIVEN_VIBE_CODING_CONTRACT
SGO-010 GRC.HUMAN_CANON_CHANGE_CONTROL
SGO-011 GRC.GPT_UPLOAD_LOCK
SGO-012 SKILL.TOVS_SUMMARY_RUNNER_CONTRACT
SGO-013 GRC.NO_UPLOAD_CONTINUITY_MODE

RULE:
Candidates only. Do not create canon automatically.

==========
SESSION_CLOSE_20260709_SKILL_GRC_OPPORTUNITIES_APPEND
==========
- CANDIDATE: Promote accumulated register integrity rule into reusable Skill/GRC if not already canonical enough.
- CANDIDATE: Add DeveFact-specific RADAR profile or project-local RADAR.ps1 to align with RADAR v1.4.
- CANDIDATE: Add Management Demo Layer skill/pattern for transforming technical evidence into executive demo artifacts.
- CANDIDATE: Strengthen AI code agent sequential workflow for DeveFact BATCH execution with human-owned commits.

==========
SESSION_CLOSE_20260710_1853 SKILL_GRC_OPPORTUNITIES_APPEND
==========
NEW_GRC_CANDIDATES:
- GRC.DEVEFACT_RADAR_PROFILE.
- GRC.MANAGEMENT_DEMO_DELIVERABLE_GATE.
- GRC.LOOP_ENGINEERING_HUMAN_GATE.

GRC_IMPROVEMENT_CANDIDATES:
- Improve GRC.AI_CODE_AGENT_SEQUENTIAL_WORKFLOW with DeveFact batch/pilot pattern.
- Improve GRC.UNKNOWN_WORKTREE_STATE_HARD_STOP with TOVS dirty-set whitelist examples.
- Improve GRC.DRAGONFLYFOCUS with management-deliverable vs governance-progress distinction.

SKILL_IMPROVEMENT_CANDIDATES:
- Management Demo Packaging.
- Context Intake / Context Sufficiency.
- Loop Engineering / agent loop control.

OPERATIONAL_RULES_TO_CANONIZE:
- Accumulated registers append-only; never replace with summaries.
- After batch chains, checkpoint and explicitly report RADAR gaps.
- Management deliverable must be visible and functional, not only traceable.

DO_NOT_CANONIZE:
- Do not canonize project-specific paths as global defaults.
- Do not canonize current markdown artifacts as final product UI.

CANDIDATES_REGISTER_UPDATED: YES
NEXT_GRC_OR_SKILL_ACTION: Create BATCH-0028 dedicated DeveFact RADAR.ps1.

==========
SESSION_CLOSE_20260716_2348 SKILL_GRC_OPPORTUNITIES_APPEND
==========
SKILL_GRC_LEARNING_REVIEW:
- NEW_GRC_CANDIDATES: GRC.DEVEFACT_RADAR_PROFILE; GRC.MANAGEMENT_DEMO_DELIVERABLE_GATE; GRC.LOOP_ENGINEERING_HUMAN_GATE.
- GRC_IMPROVEMENT_CANDIDATES: GRC.AI_CODE_AGENT_SEQUENTIAL_WORKFLOW; GRC.UNKNOWN_WORKTREE_STATE_HARD_STOP; GRC.DRAGONFLYFOCUS.
- SKILL_IMPROVEMENT_CANDIDATES: Management Demo Packaging; Context Sufficiency / Intake; RADAR Profile Creation.
- OPERATIONAL_RULES_TO_CANONIZE: accumulated registers append-only; close after batch chains reports RADAR/freshness; management deliverable must be visible and functional.
- DO_NOT_CANONIZE: DeveFact-specific paths as global defaults; markdown docs as final UI; generated 90.USECASE manual patching.
- CANDIDATES_REGISTER_UPDATED: YES if Apply is executed.
- NEXT_GRC_OR_SKILL_ACTION: BATCH-0028 dedicated DeveFact RADAR.ps1.

==========
SESSION_CLOSE_20260718_1228 SKILL_GRC_APPEND
==========
SKILL_GRC_LEARNING_REVIEW:

MINIMUM_USEFUL_SKILLS_FOR_NEXT_UPLOAD:
1. 06.SKILL.WBS.txt
   - needed for the repair-to-deliverable path and controlled sequencing.
2. 07.SKILL.FILE_CONTENT.txt
   - needed for exact static review and safe file generation.
3. 31.SKILL.MARKDOWN_FILE_CREATION_SAFETY.txt
   - relevant because the CIS rewrites the HUMAN root.
4. SKILL.HUMAN_CONTROLLED_SCRIPT_EXECUTION.txt
   - required for explicit human authorization and non-autonomous APPLY.
5. GRC.UNKNOWN_WORKTREE_STATE_HARD_STOP.txt
   - directly relevant to the three launcher failures.
6. GRC.AI_CODE_AGENT_SEQUENTIAL_WORKFLOW.txt
   - relevant for Claude/Codex handoff and bounded execution.
7. GRC.SCRIPT_EXECUTION_STAGING.txt
   - required for Temp.DeveFactory, backup and execution staging.
8. GRC.CROSS_RUNTIME_EXECUTION_CONTRACT.txt
   - useful where ChatGPT, Claude Desktop and local PowerShell exchange artifacts.
9. DocumentConsistencyAudit skill/tool package
   - mandatory for post-repair validation.
10. Session Close usecase package
   - mandatory for formal close fields and readiness declaration.

NOT_RECOMMENDED_FOR_NEXT_UPLOAD:
- broad thematic skills unrelated to document authority, Git boundary, rollback or session close;
- duplicate prompt-writing skills;
- UI/deploy skills before the repair and RADAR gates close.

NEW_GRC_CANDIDATES:
- GRC.FAILURE_ESCALATION_BY_OBJECTIVE
- GRC.GIT_ROOT_SUBTREE_STATUS_CONTRACT
- GRC.CANONICAL_DOCUMENT_AUTHORITY_MAP
- GRC.MANAGEMENT_VERTICAL_SLICE_GATE

IMPROVEMENT_CANDIDATES:
- GRC.UNKNOWN_WORKTREE_STATE_HARD_STOP: add root/subtree distinction and hash-preserved dirty baseline.
- GRC.AI_CODE_AGENT_SEQUENTIAL_WORKFLOW: add three-failure STOP and cross-agent escalation.
- Session Close: allow controlled WARN closure when a blocker is explicitly recorded and no mutation is pending.

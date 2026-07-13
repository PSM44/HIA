// ============================================================================
// FILE..............: hia.project.workspace.model.js
// PROJECT...........: PRJ_0001_HIA.PRODUCT
// MINIBATTLE........: PRJPB_010Q
// PURPOSE...........: Define evidence model without duplicating HUMAN.
// MODE..............: READ_ONLY
// ============================================================================

window.HIA_PROJECT_WORKSPACE_MODEL = Object.freeze({
  "schema": "HIA_PROJECT_WORKSPACE_MODEL.v0.1",
  "generated_local": "2026-07-13 13:14:01 -04:00",
  "generated_utc": "2026-07-13T17:14:01.7676466Z",
  "mode": "READ_ONLY",
  "no_fake_data": true,
  "purpose": "Define source roles, precedence and derived workspace views without duplicating HUMAN authority.",
  "canonical_precedence": [
    "STATE/CURRENT_STATE.json",
    "HUMAN explicit decision when present and referenced",
    "BATON operational continuity",
    "AGILE/PROJECT.BACKLOG.txt planned work and debt",
    "DELIVERY immutable execution evidence",
    "Git repository state"
  ],
  "sources": {
    "current_state": {
      "role": "PRIMARY_VISIBLE_STATE",
      "path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json",
      "mutable": true,
      "append_only": false,
      "workspace_usage": [
        "current objective",
        "next action",
        "evidence state",
        "session state",
        "product state"
      ]
    },
    "human": {
      "role": "EXTERNAL_AUTHORITY",
      "path": "NOT_NORMALIZED_IN_WORKSPACE",
      "mutable": true,
      "append_only": false,
      "workspace_usage": [
        "referenced decision only",
        "explicit approval only",
        "explicit observation only"
      ],
      "duplication_policy": "DO_NOT_COPY_OR_INFER"
    },
    "baton": {
      "role": "OPERATIONAL_CONTINUITY_AND_HISTORY",
      "path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/BATON/04.0_PROJECT.BATON.txt",
      "mutable": true,
      "append_only": true,
      "workspace_usage": [
        "latest operational continuity entries",
        "historical trace",
        "supporting evidence"
      ]
    },
    "backlog": {
      "role": "PLANNED_WORK_DEBT_AND_IDEAS",
      "path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/AGILE/PROJECT.BACKLOG.txt",
      "mutable": true,
      "append_only": true,
      "workspace_usage": [
        "active backlog",
        "technical debt",
        "ideas and opportunities"
      ]
    },
    "delivery": {
      "role": "IMMUTABLE_EXECUTION_EVIDENCE",
      "path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/DELIVERY",
      "mutable": false,
      "append_only": true,
      "workspace_usage": [
        "latest deliveries",
        "execution result",
        "validation evidence"
      ]
    },
    "git": {
      "role": "REPOSITORY_TRUTH",
      "path": "git",
      "mutable": true,
      "append_only": true,
      "workspace_usage": [
        "branch",
        "HEAD",
        "clean or dirty status"
      ]
    }
  },
  "derived_views": {
    "continuity": {
      "fields": [
        "current_objective",
        "next_action",
        "evidence_state",
        "evidence_consistency",
        "session_status"
      ],
      "source": "CURRENT_STATE"
    },
    "execution_evidence": {
      "fields": [
        "latest_deliveries",
        "validation_status",
        "commit_reference"
      ],
      "source": "DELIVERY_PLUS_GIT"
    },
    "planning": {
      "fields": [
        "backlog",
        "technical_debt",
        "ideas"
      ],
      "source": "BACKLOG"
    },
    "operational_history": {
      "fields": [
        "latest_baton_entries"
      ],
      "source": "BATON"
    },
    "human_authority": {
      "fields": [
        "explicit_decision_reference",
        "explicit_approval_reference",
        "explicit_observation_reference"
      ],
      "source": "HUMAN_REFERENCE_ONLY"
    }
  },
  "prohibited": [
    "Copying HUMAN content into the workspace as canonical data.",
    "Inferring approval or decision from absence of objection.",
    "Duplicating BATON or BACKLOG full text into a second canonical store.",
    "Inventing milestones, costs, owners, dates or risk ratings.",
    "Treating derived views as new sources of truth.",
    "Allowing workspace UI to write into source files."
  ],
  "conflict_resolution": [
    "Valid CURRENT_STATE wins for visible current state.",
    "Explicit HUMAN decision wins over machine-derived interpretation.",
    "DELIVERY and Git prove completed execution.",
    "BATON provides operational sequence and historical context.",
    "BACKLOG provides planned work, debt and ideas.",
    "Conflicts must be displayed as warnings, not silently merged."
  ],
  "validation": {
    "current_state_primary": true,
    "human_not_duplicated": true,
    "baton_not_canonicalized": true,
    "backlog_not_canonicalized": true,
    "delivery_immutable_evidence": true,
    "write_mode": "READ_ONLY",
    "gate": "PASS_STATIC"
  }
});
export type PortfolioProject = {
  index: number;
  project_id: string;
  next?: string;
  session: string;
  evidence: string;
  safety: string;
  ledger?: string;
};

export type PortfolioApiResponse = {
  success: boolean;
  data: {
    projects: PortfolioProject[];
    count: number;
  };
  error?: string;
  meta?: {
    source?: string;
    command?: string;
    exit_code?: number;
  };
};

export type ProjectStatus = {
  project_id?: string;
  next_action?: string;
  last_session_status?: string;
  evidence_state?: string;
  evidence_age_hours?: string;
  session_safety?: string;
  session_safety_notes?: string;
  ai_last_plan?: string;
  ai_guidance?: string;
  ai_plan_log?: string;
  ai_memory_status?: string;
  latest_output_path?: string;
  latest_log_path?: string;
  last_task_scope?: string;
  last_task_result?: string;
  last_task_request?: string;
  last_task_target?: string;
  last_task_message?: string;
  last_task_evidence?: string;
  last_task_continuity_hint?: string;
  raw?: string;
};

export type StatusSummary = {
  tools_count?: number;
  agents_count?: number;
  plans_total?: number;
  plans_completed?: number;
  plans_pending?: number;
  session_active?: boolean;
  timestamp?: string;
};

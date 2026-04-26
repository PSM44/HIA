import { useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { StateBadge } from "../components/state-badge";
import { toast } from "../components/toast";
import { api } from "../lib/api/client";
import { qk } from "../lib/api/query-keys";
import { ProjectStatus } from "../lib/types/common";

type ProjectQueryResponse = {
  parsed?: ProjectStatus;
  raw?: string;
};

export default function Project() {
  const [params, setParams] = useSearchParams();
  const initial = params.get("id") ?? "";
  const [projectId, setProjectId] = useState(initial);
  const [deleteToken, setDeleteToken] = useState("");
  const queryClient = useQueryClient();

  const {
    data,
    isLoading,
    isError,
    error,
    refetch,
    isFetching,
  } = useQuery<ProjectQueryResponse>({
    queryKey: qk.project(projectId || ""),
    queryFn: () => api.project(projectId),
    enabled: !!projectId,
  });

  const deleteMutation = useMutation({
    mutationFn: (confirm: string) => api.deleteProject(projectId, confirm),
    onSuccess: () => {
      toast("Project deleted / archived.");
      setDeleteToken("");
      queryClient.removeQueries({
        queryKey: qk.project(projectId || ""),
        exact: true,
      });
    },
    onError: () => {
      toast("Delete failed. Check confirm token or backend.");
    },
  });

  const parsed: ProjectStatus | undefined = data?.parsed;
  const rawStatus = data?.raw ?? parsed?.raw ?? "(no raw)";

  const whatMattersNow = useMemo(() => {
    if (!parsed) return "Select a project to load guidance.";
    return parsed.ai_guidance || parsed.next_action || "No guidance available.";
  }, [parsed]);

  const continuityItems = useMemo(() => {
    if (!parsed) return [] as { label: string; value?: string }[];
    return [
      { label: "Last session", value: parsed.last_session_status },
      { label: "Evidence state", value: parsed.evidence_state },
      { label: "Evidence age (hrs)", value: parsed.evidence_age_hours },
      { label: "Continuity hint", value: parsed.last_task_continuity_hint || parsed.session_safety_notes },
    ].filter((i) => i.value);
  }, [parsed]);
  const latestTask = Boolean(parsed?.last_task_result || parsed?.last_task_scope);

  const latestTaskState = useMemo(() => {
    const result = parsed?.last_task_result?.toLowerCase() || "";
    if (!latestTask) return null;
    if (result.includes("reject") || result.includes("block")) return "Blocked / Rejected" as const;
    return "Completed" as const;
  }, [latestTask, parsed?.last_task_result]);

  const handleLoad = () => {
    const clean = projectId.trim();
    if (!clean) {
      toast("Enter a project id to load.");
      return;
    }
    setParams({ id: clean });
    refetch();
  };

  const handleDelete = () => {
    const expected = `DELETE ${projectId}`;
    if (deleteToken.trim() !== expected) {
      toast(`Type "${expected}" to confirm delete.`);
      return;
    }
    deleteMutation.mutate(deleteToken.trim());
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <h1 className="text-xl font-semibold">Active Project</h1>
        <StateBadge state="LIVE" />
      </div>

      <div className="flex gap-2 items-end">
        <div className="flex flex-col gap-1">
          <label className="text-xs text-muted">Project ID</label>
          <input
            value={projectId}
            onChange={(e) => setProjectId(e.target.value)}
            placeholder="Enter project id"
            className="bg-panel border border-border rounded px-2 py-2 text-sm text-text w-64"
          />
        </div>
        <Button onClick={handleLoad} disabled={isFetching}>
          {isFetching ? "Loading…" : "Load"}
        </Button>
      </div>

      {!projectId && <p className="text-sm text-muted">Enter a project id to view status.</p>}
      {projectId && isLoading && <p className="text-sm text-muted">Loading project…</p>}
      {projectId && isError && (
        <p className="text-sm text-error">Error loading project: {(error as Error).message}</p>
      )}

      {projectId && parsed && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
            <SummaryCard label="Next action" value={parsed.next_action} />
            <SummaryCard label="Session status" value={parsed.last_session_status} />
            <SummaryCard label="Evidence state" value={parsed.evidence_state} />
            <SummaryCard label="Evidence age (hrs)" value={parsed.evidence_age_hours} />
            <SummaryCard
              label="Safety"
              value={parsed.session_safety}
              note={parsed.session_safety_notes}
            />
            <SummaryCard label="AI memory status" value={parsed.ai_memory_status} />
          </div>

          <div className="space-y-1 rounded-lg border border-border bg-card/70 p-3">
            <div className="text-xs text-muted">What matters now</div>
            <div className="text-sm text-text">{whatMattersNow}</div>
            <div className="mt-2 flex gap-2 flex-wrap text-xs text-muted">
              <span className="rounded border border-border px-2 py-1">Review</span>
              <span className="rounded border border-border px-2 py-1">Continue</span>
            </div>
          </div>
          <div className="space-y-2 rounded-lg border border-border bg-card/70 p-3">
            <div className="flex items-center gap-2">
              <div className="text-sm font-semibold">Session Continuity</div>
              <StateBadge state="LIVE" />
            </div>
            {continuityItems.length === 0 && <div className="text-sm text-muted">No continuity data yet.</div>}
            {continuityItems.length > 0 && (
              <div className="space-y-1 text-sm text-text">
                {continuityItems.map((item) => (
                  <Field key={item.label} label={item.label} value={item.value} />
                ))}
                <Field label="Recommended next" value={whatMattersNow} />
              </div>
            )}
          </div>

          <div className="space-y-2 rounded-lg border border-border bg-card/70 p-3">
            <div className="flex items-center gap-2">
              <div className="text-sm font-semibold">Latest Task Activity</div>
              <StateBadge state="LIVE" />
              {latestTaskState && (
                <span className={`text-xs px-2 py-1 rounded border ${latestTaskState === "Blocked / Rejected" ? "border-red-500 text-red-200" : "border-emerald-500 text-emerald-200"}`}>
                  {latestTaskState}
                </span>
              )}
            </div>
            {!latestTask && <div className="text-sm text-muted">No task history yet.</div>}
            {latestTask && (
              <div className="space-y-1 text-sm text-text">
                <Field label="Result" value={parsed.last_task_result} />
                <Field label="Scope" value={parsed.last_task_scope} />
                <Field label="Request" value={parsed.last_task_request} />
                <Field label="Target" value={parsed.last_task_target} />
                <Field label="Message" value={parsed.last_task_message} />
                <Field label="Evidence" value={parsed.last_task_evidence} />
                <Field label="Continuity hint" value={parsed.last_task_continuity_hint} />
              </div>
            )}
          </div>

          <div className="space-y-2 rounded-lg border border-border bg-card/70 p-3">
            <div className="flex items-center gap-2">
              <div className="text-sm font-semibold">AI Assistance</div>
              <StateBadge state="LIVE" />
            </div>
            <div className="space-y-1 text-sm text-text">
              <Field label="Last AI plan" value={parsed.ai_last_plan} />
              <Field label="AI guidance" value={parsed.ai_guidance} />
              <Field label="AI memory status" value={parsed.ai_memory_status} />
              <Field label="AI plan log" value={parsed.ai_plan_log} mono />
            </div>
          </div>

          <div className="space-y-2 rounded-lg border border-border bg-card/70 p-3">
            <div className="text-sm font-semibold">Evidence / Logs</div>
            <div className="space-y-1 text-sm text-text">
              <Field label="Latest output path" value={parsed.latest_output_path} mono />
              <Field label="Latest log path" value={parsed.latest_log_path} mono />
            </div>
          </div>

          <div className="space-y-2 rounded-lg border border-error/50 bg-error/10 p-3">
            <div className="flex items-center gap-2">
              <div className="text-sm font-semibold text-red-200">Safe delete / archive</div>
              <StateBadge state="LIVE" />
            </div>
            <div className="text-xs text-red-200">
              Type DELETE {projectId} to confirm. This uses the real delete endpoint.
            </div>
            <div className="flex items-center gap-2">
              <input
                placeholder={`DELETE ${projectId}`}
                value={deleteToken}
                onChange={(e) => setDeleteToken(e.target.value)}
                className="bg-panel border border-border rounded px-2 py-2 text-sm text-text w-64"
              />
              <Button
                variant="destructive"
                onClick={handleDelete}
                disabled={!projectId || deleteMutation.isPending}
              >
                {deleteMutation.isPending ? "Deleting…" : "Delete"}
              </Button>
            </div>
          </div>

          <details className="rounded-lg border border-border">
            <summary className="cursor-pointer px-3 py-2 text-sm text-muted">Raw status</summary>
            <pre className="whitespace-pre-wrap bg-slate-950 p-3 text-xs text-slate-200">
              {rawStatus}
            </pre>
          </details>
        </div>
      )}
    </div>
  );
}

function SummaryCard({
  label,
  value,
  note,
}: {
  label: string;
  value?: string;
  note?: string;
}) {
  return (
    <div className="rounded-lg border border-border bg-card/70 p-3">
      <div className="text-xs text-muted">{label}</div>
      <div className="min-h-[1.5rem] text-sm text-text">{value || "—"}</div>
      {note && <div className="text-xs text-muted">{note}</div>}
    </div>
  );
}

function Field({
  label,
  value,
  mono,
}: {
  label: string;
  value?: string;
  mono?: boolean;
}) {
  return (
    <div className="flex gap-2 text-sm">
      <div className="min-w-[140px] text-muted">{label}</div>
      <div className={`text-text ${mono ? "font-mono" : ""}`}>{value || "—"}</div>
    </div>
  );
}


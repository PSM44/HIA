import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";

import { StateBadge } from "../components/state-badge";
import { toast } from "../components/toast";
import { api } from "../lib/api/client";
import { qk } from "../lib/api/query-keys";
import type { PortfolioProject } from "../lib/types/common";

type PortfolioResponse = {
  parsed?: {
    projects: PortfolioProject[];
  };
  raw?: string;
};

type CreateIterationResponse = {
  message?: string;
  raw?: string;
  parsed?: unknown;
};

export default function Portfolio() {
  const queryClient = useQueryClient();
  const [newId, setNewId] = useState("");

  const portfolioQuery = useQuery<PortfolioResponse>({
    queryKey: qk.portfolio,
    queryFn: api.portfolio,
  });

  const createIterationMutation = useMutation<CreateIterationResponse, Error, string>({
    mutationFn: (projectId: string) => api.projectCreate(projectId),
    onSuccess: async () => {
      toast("Iteration instance created (or already exists).");
      setNewId("");
      await queryClient.invalidateQueries({ queryKey: qk.portfolio });
    },
    onError: (error: Error) => {
      toast(`Create iteration failed: ${error.message}`);
    },
  });

  const projects: PortfolioProject[] = portfolioQuery.data?.parsed?.projects ?? [];

  const safetyCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const project of projects) {
      const key = project.safety || "UNKNOWN";
      counts[key] = (counts[key] || 0) + 1;
    }
    return counts;
  }, [projects]);

  const handleCreateIteration = async () => {
    const projectId = newId.trim();
    if (!projectId) {
      toast("Enter a Iteration ID.");
      return;
    }
    await createIterationMutation.mutateAsync(projectId);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <h1 className="text-xl font-semibold">Portfolio</h1>
        <StateBadge state="LIVE" />
      </div>

      <div className="space-y-2 rounded-lg border border-slate-800 bg-slate-900/70 p-3">
        <div className="text-sm font-semibold text-slate-100">
          Create iteration instance (minimal)
        </div>

        <div className="flex flex-wrap items-end gap-2">
          <div className="flex flex-col gap-1">
            <label className="text-xs text-slate-400">Iteration ID</label>
            <input
              value={newId}
              onChange={(e) => setNewId(e.target.value)}
              placeholder="PROJECT_ID"
              className="w-64 rounded border border-slate-700 bg-slate-900 px-2 py-2 text-sm text-slate-100"
            />
          </div>

          <Button onClick={handleCreateIteration} disabled={createIterationMutation.isPending}>
            {createIterationMutation.isPending ? "Creating iteration..." : "Create iteration"}
          </Button>

          <div className="text-xs text-slate-400">
            Uses real CLI project new; no fake data.
          </div>
        </div>
      </div>

      {portfolioQuery.isLoading && (
        <p className="text-sm text-slate-400">Loading portfolio...</p>
      )}

      {portfolioQuery.isError && (
        <p className="text-sm text-red-400">
          Error loading portfolio: {portfolioQuery.error.message}
        </p>
      )}

      {!portfolioQuery.isLoading && !portfolioQuery.isError && (
        <div className="space-y-3">
          <div className="flex flex-wrap gap-3 text-sm text-slate-200">
            <div className="rounded-lg border border-slate-800 bg-slate-900/70 px-3 py-2">
              Total projects: {projects.length}
            </div>

            {Object.entries(safetyCounts).map(([key, value]) => (
              <div
                key={key}
                className="rounded-lg border border-slate-800 bg-slate-900/70 px-3 py-2"
              >
                Safety {key}: {value}
              </div>
            ))}
          </div>

          <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
            {projects.map((project: PortfolioProject) => (
              <div
                key={project.project_id}
                className="space-y-2 rounded-lg border border-slate-800 bg-slate-900/70 p-3"
              >
                <div className="flex items-center gap-2">
                  <div className="text-sm font-semibold text-slate-100">
                    {project.project_id}
                  </div>
                  <span className="rounded bg-amber-500/20 px-2 py-0.5 text-[11px] font-semibold text-amber-300">Pending Definition</span>
                  <span className="text-xs text-slate-400">#{project.index}</span>
                </div>

                <Field label="Session" value={project.session} />
                <Field label="Evidence" value={project.evidence} />
                <Field label="Safety" value={project.safety} />

                <a
                  className="text-xs text-emerald-300 underline"
                  href={`/project?id=${encodeURIComponent(project.project_id)}`}
                >
                  Open in Active Project
                </a>
              </div>
            ))}

            {projects.length === 0 && (
              <div className="rounded-lg border border-slate-800 bg-slate-900/70 p-3 text-sm text-slate-400">
                No projects detected.
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

function Field({ label, value }: { label: string; value?: string }) {
  return (
    <div className="flex gap-2 text-sm">
      <div className="min-w-[90px] text-slate-400">{label}</div>
      <div className="text-slate-100">{value || "—"}</div>
    </div>
  );
}









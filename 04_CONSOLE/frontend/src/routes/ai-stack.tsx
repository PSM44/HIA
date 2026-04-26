import { useMutation, useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { StateBadge } from "../components/state-badge";
import { ComingSoonCard } from "../features/coming-soon/ComingSoonCard";
import { api } from "../lib/api/client";
import { qk } from "../lib/api/query-keys";

type AIPlanResult = {
  result_summary?: string;
  ai_next_hint?: string;
  ai_suggested_command?: string;
  decision_ref?: string;
  raw?: string;
};

type AIPlanRequest = {
  project_id: string;
  preset: string;
};

type AIPlanApiResponse = {
  parsed?: AIPlanResult;
  output?: string;
};

const items = {
  scope: [
    { label: "Scope", value: "Global" },
    { label: "Project-aware", value: "NOT_YET_WIRED" },
  ],
  capability: [
    { label: "Cloud AI", value: "NOT_YET_WIRED" },
    { label: "Desktop AI", value: "NOT_YET_WIRED" },
    { label: "Local AI", value: "NOT_YET_WIRED" },
  ],
  engines: [
    { label: "GPT (cloud)", value: "NOT_YET_WIRED" },
    { label: "Claude (cloud)", value: "NOT_YET_WIRED" },
    { label: "Codex Desktop", value: "NOT_YET_WIRED" },
    { label: "Claude Code Desktop", value: "NOT_YET_WIRED" },
    { label: "Ollama", value: "NOT_YET_WIRED" },
  ],
  routing: [
    { label: "Preferred reasoning", value: "NOT_YET_WIRED" },
    { label: "Preferred coding", value: "NOT_YET_WIRED" },
    { label: "Fallback chain", value: "NOT_YET_WIRED" },
  ],
  cost: [
    { label: "Monthly budget", value: "NOT_YET_WIRED" },
    { label: "Alert step", value: "NOT_YET_WIRED" },
    { label: "Hard stop", value: "NOT_YET_WIRED" },
    { label: "Subscriptions", value: "NOT_YET_WIRED" },
    { label: "Variable usage", value: "NOT_YET_WIRED" },
    { label: "Tracked total", value: "NOT_YET_WIRED" },
  ],
  guidance: [
    { label: "Recommended models", value: "NOT_YET_WIRED" },
    { label: "Discarded / avoid", value: "NOT_YET_WIRED" },
  ],
  health: [
    { label: "Discovery", value: "NOT_YET_WIRED" },
    { label: "Cost tracking", value: "NOT_YET_WIRED" },
  ],
};

export default function AIStack() {
  const { data, isLoading, isError, error } = useQuery({ queryKey: qk.status, queryFn: api.status });

  const [projectId, setProjectId] = useState("");
  const [preset, setPreset] = useState("readiness");
  const [planResult, setPlanResult] = useState<AIPlanResult | null>(null);

  const planMutation = useMutation<AIPlanApiResponse, Error, AIPlanRequest>({
      mutationFn: (body) => api.aiPlan(body),
      onSuccess: (res) => {
        setPlanResult({
          result_summary: res?.parsed?.result_summary,
          ai_next_hint: res?.parsed?.ai_next_hint,
          ai_suggested_command: res?.parsed?.ai_suggested_command,
          decision_ref: res?.parsed?.decision_ref,
          raw: res?.output,
        });
      },
      onError: () => {
        setPlanResult({ result_summary: "Plan request failed", raw: "" });
      },
    });

  const realSignals = [
    { label: "Registered tools", value: data?.tools_count },
    { label: "Registered agents", value: data?.agents_count },
    { label: "Plans total", value: data?.plans_total },
    { label: "Plans completed", value: data?.plans_completed },
    { label: "Plans pending", value: data?.plans_pending },
    { label: "Session active", value: data?.session_active ? "Yes" : "No" },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <h1 className="text-xl font-semibold">AI Stack / Cost Control</h1>
        <StateBadge state="PARTIAL" />
      </div>
      <p className="text-sm text-slate-400">Early foundation. Uses real endpoints when present; anything missing is labeled NOT_YET_WIRED. No fabricated costs or availability.</p>\n      <p className="text-sm text-slate-300">Demo note: show real signals first, then run a guided plan with a real project ID and preset. Keep NOT_YET_WIRED labels visible.</p>

      <Block
        title="Real signals"
        badge={isError ? "PARTIAL" : "LIVE"}
        description={isError ? `Status endpoint error: ${(error as Error)?.message}` : "From /api/status (tool/agent registry)."}
      >
        {isLoading && <div className="text-sm text-slate-400">Loading real signals…</div>}
        {!isLoading && !isError && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
            {realSignals.map((i) => (
              <Item key={i.label} label={i.label} value={formatValue(i.value)} />
            ))}
          </div>
        )}
      </Block>

      <Block
        title="Guided AI interaction"
        badge="PARTIAL"
        description="Runs real /api/ai/plan with a preset. No fake outputs; missing fields show as N/A."
      >
        <div className="flex flex-wrap gap-2 items-end">
          <div className="flex flex-col gap-1">
            <label className="text-xs text-slate-400">Project ID</label>
            <input
              value={projectId}
              onChange={(e) => setProjectId(e.target.value)}
              placeholder="PROJECT_ID"
              className="bg-slate-900 border border-slate-700 rounded px-2 py-2 text-sm text-slate-100 w-56"
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-xs text-slate-400">Preset</label>
            <select
              value={preset}
              onChange={(e) => setPreset(e.target.value)}
              className="bg-slate-900 border border-slate-700 rounded px-2 py-2 text-sm text-slate-100"
            >
              <option value="readiness">readiness</option>
              <option value="next-step">next-step</option>
            </select>
          </div>
          <button
            className="px-3 py-2 text-sm rounded bg-emerald-600 text-white disabled:opacity-60"
            onClick={() => {
              const id = projectId.trim();
              if (!id) return;
              planMutation.mutate({ project_id: id, preset });
            }}
            disabled={planMutation.isPending}
          >
            {planMutation.isPending ? "Running…" : "Run plan"}
          </button>
          <div className="text-xs text-slate-400">Uses real backend; remember is not auto-enabled.</div>
        </div>
        {planResult && (
          <div className="mt-3 space-y-1 text-sm text-slate-100">
            <Item label="Result summary" value={formatValue(planResult.result_summary)} />
            <Item label="Next hint" value={formatValue(planResult.ai_next_hint)} />
            <Item label="Suggested command" value={formatValue(planResult.ai_suggested_command)} />
            <Item label="Decision ref" value={formatValue(planResult.decision_ref)} />
            <details className="text-xs text-slate-400">
              <summary className="cursor-pointer">Raw output</summary>
              <pre className="bg-slate-950 p-2 rounded border border-slate-800 whitespace-pre-wrap text-[11px]">{planResult.raw || "(none)"}</pre>
            </details>
          </div>
        )}
      </Block>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        <Block title="Scope" badge="PARTIAL" description="Global scope is available; project-aware coming later.">
          {items.scope.map((i) => (
            <Item key={i.label} {...i} />
          ))}
        </Block>

        <Block title="Capability Summary" badge="PARTIAL" description="Cloud, desktop, and local AI visibility.">
          {items.capability.map((i) => (
            <Item key={i.label} {...i} />
          ))}
        </Block>
      </div>

      <Block title="Engine Availability" badge="PARTIAL" description="Engines shown only; discovery not wired yet.">
        {items.engines.map((i) => (
          <Item key={i.label} {...i} />
        ))}
      </Block>

      <Block title="Routing / Fallback" badge="PARTIAL" description="Preferred engines and fallback chain to come.">
        {items.routing.map((i) => (
          <Item key={i.label} {...i} />
        ))}
      </Block>

      <Block title="Cost Control" badge="PARTIAL" description="Budget and spend only when backed by real data.">
        {items.cost.map((i) => (
          <Item key={i.label} {...i} />
        ))}
      </Block>

      <Block title="Model Guidance" badge="PARTIAL" description="No fake recommendations; wiring pending.">
        {items.guidance.map((i) => (
          <Item key={i.label} {...i} />
        ))}
      </Block>

      <Block title="Health / Wiring State" badge="PARTIAL" description="Explicit about missing discovery/tracking.">
        {items.health.map((i) => (
          <Item key={i.label} {...i} />
        ))}
      </Block>

      <ComingSoonCard label="AI Stack deeper wiring" />
    </div>
  );
}

function Block({
  title,
  badge,
  description,
  children,
}: {
  title: string;
  badge: "LIVE" | "PARTIAL" | "COMING";
  description?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="border border-slate-800 rounded-lg p-3 bg-slate-900/70 space-y-2">
      <div className="flex items-center gap-2">
        <div className="text-sm font-semibold text-slate-100">{title}</div>
        <StateBadge state={badge} />
      </div>
      {description && <div className="text-xs text-slate-400">{description}</div>}
      {children}
    </div>
  );
}

function Item({ label, value }: { label: string; value: string }) {
  const muted = value === "NOT_YET_WIRED";
  return (
    <div className="flex gap-2 text-sm">
      <div className="text-slate-400 min-w-[170px]">{label}</div>
      <div className={muted ? "text-slate-400" : "text-slate-100"}>{value}</div>
    </div>
  );
}

function formatValue(v: unknown): string {
  if (v === null || v === undefined) return "N/A";
  if (typeof v === "boolean") return v ? "Yes" : "No";
  return String(v);
}




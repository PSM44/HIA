import { PortfolioApiResponse, ProjectStatus, StatusSummary } from "../types/common";

export const API_BASE = "/api";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, init);
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return res.json() as Promise<T>;
}

export const api = {
  portfolio: () => request<PortfolioApiResponse>("/portfolio"),
  project: (id: string) => request<ProjectStatus & { raw?: string }>(`/project/${id}`),
  projectCreate: (project_id: string) =>
    request<any>("/project/new", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ project_id }),
    }),
  aiPlan: (body: any) =>
    request<any>("/ai/plan", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }),
  health: () => request<any>("/health/full"),
  status: () => request<StatusSummary>("/status"),
  deleteProject: (id: string, confirm: string) =>
    request<any>(`/project/${id}/delete`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ confirm }),
    }),
};

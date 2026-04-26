export const qk = {
  portfolio: ["portfolio"] as const,
  project: (id: string) => ["project", id] as const,
  aiPlan: (id: string, preset?: string) => ["aiPlan", id, preset ?? "custom"] as const,
  health: ["health"] as const,
  status: ["status"] as const,
};

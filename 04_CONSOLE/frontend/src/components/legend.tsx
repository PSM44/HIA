import { StateBadge } from "./state-badge";

export function Legend() {
  return (
    <div className="flex gap-2 flex-wrap text-xs">
      <StateBadge state="LIVE" />
      <StateBadge state="PARTIAL" />
      <StateBadge state="COMING" />
    </div>
  );
}

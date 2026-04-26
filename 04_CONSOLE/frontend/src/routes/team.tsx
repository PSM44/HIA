import { StateBadge } from "../components/state-badge";
import { ComingSoonCard } from "../features/coming-soon/ComingSoonCard";

export default function () {
  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <h1 className="text-xl font-semibold">Team & Access</h1>
        <StateBadge state="COMING" />
      </div>
      <ComingSoonCard label="Team & Access" />
    </div>
  );
}

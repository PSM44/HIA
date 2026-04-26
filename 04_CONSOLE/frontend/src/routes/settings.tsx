import { StateBadge } from "../components/state-badge";
import { PartialPanel } from "../features/coming-soon/PartialPanel";

export default function Settings() {
  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <h1 className="text-xl font-semibold">Settings</h1>
        <StateBadge state="PARTIAL" />
      </div>
      <PartialPanel label="Settings shell" note="Config and controls to be wired in later phases." />
    </div>
  );
}

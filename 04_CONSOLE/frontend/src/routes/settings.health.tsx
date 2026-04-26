import { StateBadge } from "../components/state-badge";
import { PartialPanel } from "../features/coming-soon/PartialPanel";

export default function SettingsHealth() {
  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <h1 className="text-xl font-semibold">Health / Diagnostics</h1>
        <StateBadge state="PARTIAL" />
      </div>
      <PartialPanel label="Health / Diagnostics" note="Will consume backend health ping in a later phase." />
    </div>
  );
}

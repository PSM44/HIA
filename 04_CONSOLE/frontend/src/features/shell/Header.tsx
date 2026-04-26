import { Legend } from "../../components/legend";
import { FocusModeIndicator } from "../../components/focus-mode-indicator";

export function Header() {
  return (
    <header className="h-14 border-b border-slate-800 bg-slate-900 flex items-center justify-between px-4">
      <div className="font-semibold">HIA Web Console v2</div>
      <div className="flex items-center gap-3">
        <Legend />
        <FocusModeIndicator />
      </div>
    </header>
  );
}

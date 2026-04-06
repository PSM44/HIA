type StateKind = "LIVE" | "PARTIAL" | "COMING";

const classes: Record<StateKind, string> = {
  LIVE: "border-emerald-400 text-emerald-300",
  PARTIAL: "border-amber-400 text-amber-300 border-dashed",
  COMING: "border-slate-500 text-slate-400 border-dashed",
};

export function StateBadge({ state }: { state: StateKind }) {
  return (
    <span className={`text-[11px] px-2 py-1 rounded-md border ${classes[state]}`}>
      {state === "COMING" ? "COMING SOON" : state}
    </span>
  );
}

export type StateKind = "LIVE" | "PARTIAL" | "COMING";

const classes: Record<StateKind, string> = {
  LIVE: "border-accent text-accent",
  PARTIAL: "border-warn text-warn border-dashed",
  COMING: "border-soon text-soon border-dashed",
};

export function StateBadge({ state }: { state: StateKind }) {
  return (
    <span className={`text-[11px] px-2 py-1 rounded-md border ${classes[state]}`}>
      {state === "COMING" ? "COMING SOON" : state}
    </span>
  );
}
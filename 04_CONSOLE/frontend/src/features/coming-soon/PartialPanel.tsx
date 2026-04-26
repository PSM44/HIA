export function PartialPanel({ label, note }: { label: string; note?: string }) {
  return (
    <div className="border border-dashed border-amber-400/70 bg-amber-500/10 p-4 rounded-lg text-amber-200">
      {label} — Partial. {note ?? "Additional wiring pending."}
    </div>
  );
}

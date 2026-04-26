export function ComingSoonCard({ label }: { label: string }) {
  return (
    <div className="border border-dashed border-slate-600 bg-slate-900/70 p-4 rounded-lg text-slate-300">
      {label} — Coming soon. Approved area, wiring in progress.
    </div>
  );
}

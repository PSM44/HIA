import { NavLink } from "react-router-dom";
import { StateBadge } from "../../components/state-badge";
import { toast } from "../../components/toast";

type NavState = "LIVE" | "PARTIAL" | "COMING";
type NavItem = { to: string; label: string; state: NavState };

const nav: NavItem[] = [
  { to: "/control-tower", label: "Control Tower", state: "COMING" },
  { to: "/portfolio", label: "Portfolio", state: "LIVE" },
  { to: "/project", label: "Active Project", state: "LIVE" },
  { to: "/ai-stack", label: "AI Stack / Cost Control", state: "PARTIAL" },
  { to: "/vault", label: "Vault", state: "COMING" },
  { to: "/knowledge", label: "Knowledge", state: "COMING" },
  { to: "/messages", label: "Messages / Coordination", state: "COMING" },
  { to: "/team", label: "Team & Access", state: "COMING" },
  { to: "/settings", label: "Settings", state: "PARTIAL" },
  { to: "/settings/health", label: "Health / Diagnostics", state: "PARTIAL" },
];

export function Sidebar() {
  const handleComing = (state: NavState) => {
    if (state === "COMING") {
      toast("Coming soon — approved area, still being wired.");
    }
  };

  return (
    <aside className="bg-slate-900 border-r border-slate-800 p-3 w-64 flex flex-col gap-2">
      <div className="text-xs text-slate-400">HIA Navigation</div>
      {nav.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          className={({ isActive }) =>
            `flex items-center justify-between px-2 py-2 rounded-md text-sm ${
              isActive ? "bg-slate-800 border border-slate-700" : "hover:bg-slate-800/70"
            }`
          }
          onClick={() => handleComing(item.state)}
        >
          <span>{item.label}</span>
          <StateBadge state={item.state} />
        </NavLink>
      ))}
    </aside>
  );
}


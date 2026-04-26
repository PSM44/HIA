import { Outlet } from "react-router-dom";
import { Sidebar } from "./Sidebar";
import { Header } from "./Header";

export function AppShell() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <Header />
      <div className="grid grid-cols-[256px_1fr]">
        <Sidebar />
        <main className="p-4">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

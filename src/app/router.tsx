import { createBrowserRouter, Navigate } from "react-router-dom";
import { AppShell } from "../features/shell/AppShell";
import Portfolio from "../routes/portfolio";
import Project from "../routes/project";
import ControlTower from "../routes/control-tower";
import AIStack from "../routes/ai-stack";
import Vault from "../routes/vault";
import Knowledge from "../routes/knowledge";
import Messages from "../routes/messages";
import Team from "../routes/team";
import Settings from "../routes/settings";
import SettingsHealth from "../routes/settings.health";

export const router = createBrowserRouter([
  {
    path: "/",
    element: <AppShell />,
    children: [
      { index: true, element: <Navigate to="/portfolio" replace /> },
      { path: "portfolio", element: <Portfolio /> },
      { path: "project", element: <Project /> }, // ready to become /project/:projectId later
      { path: "control-tower", element: <ControlTower /> },
      { path: "ai-stack", element: <AIStack /> },
      { path: "vault", element: <Vault /> },
      { path: "knowledge", element: <Knowledge /> },
      { path: "messages", element: <Messages /> },
      { path: "team", element: <Team /> },
      { path: "settings", element: <Settings /> },
      { path: "settings/health", element: <SettingsHealth /> },
    ],
  },
]);

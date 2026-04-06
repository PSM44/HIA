"""
===============================================================================
HIA Console Backend
FastAPI server for HIA web interface
VERSION: v1.0
DATE: 2026-03-16
===============================================================================
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import subprocess
import asyncio
import json
import os
from datetime import datetime
from pathlib import Path

# -----------------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).parent.parent.parent.resolve()
CLI_PATH = PROJECT_ROOT / "01_UI" / "terminal" / "hia.ps1"
TOOLS_DIR = PROJECT_ROOT / "02_TOOLS"
AGENTS_DIR = PROJECT_ROOT / "04_AGENTS"
ARTIFACTS_DIR = PROJECT_ROOT / "03_ARTIFACTS"
SESSIONS_DIR = ARTIFACTS_DIR / "sessions"

# -----------------------------------------------------------------------------
# APP
# -----------------------------------------------------------------------------

app = FastAPI(
    title="HIA Console",
    description="Human Intelligence Amplifier - Web Console",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------------------------------------------------------
# MODELS
# -----------------------------------------------------------------------------

class CommandRequest(BaseModel):
    command: str
    args: Optional[List[str]] = []

class SessionAction(BaseModel):
    action: str  # start, close, log
    message: Optional[str] = None

class DeleteRequest(BaseModel):
    confirm: str


# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------

def run_hia_command(command: str, args: list = None) -> dict:
    """Execute HIA CLI command and return result."""
    if args is None:
        args = []

    cmd = ["pwsh", "-NoProfile", "-File", str(CLI_PATH), command] + args

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=120,
            cwd=str(PROJECT_ROOT)
        )
        return {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr,
            "exit_code": result.returncode,
            "command": cmd
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "output": "",
            "error": "Command timed out after 120 seconds",
            "exit_code": -1
        }
    except Exception as e:
        return {
            "success": False,
            "output": "",
            "error": str(e),
            "exit_code": -1
        }


def get_tool_registry() -> dict:
    """Load tool registry."""
    registry_path = TOOLS_DIR / "TOOL.REGISTRY.json"
    if registry_path.exists():
        with open(registry_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"tools": {}}


def get_agent_registry() -> dict:
    """Load agent registry."""
    registry_path = AGENTS_DIR / "AGENT.REGISTRY.json"
    if registry_path.exists():
        with open(registry_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"agents": {}}


def get_active_session() -> Optional[dict]:
    """Get active session if exists."""
    session_file = SESSIONS_DIR / "SESSION.ACTIVE.json"
    if session_file.exists():
        with open(session_file, "r", encoding="utf-8") as f:
            return json.load(f)
    return None


def get_recent_plans(limit: int = 10) -> list:
    """Get recent plans."""
    plans_dir = ARTIFACTS_DIR / "plans"
    if not plans_dir.exists():
        return []

    plans = []
    for plan_file in sorted(plans_dir.glob("*.json"), reverse=True)[:limit]:
        try:
            with open(plan_file, "r", encoding="utf-8") as f:
                plan = json.load(f)
                plan["filename"] = plan_file.name
                plans.append(plan)
        except:
            pass

    return plans


def get_system_stats() -> dict:
    """Get system statistics."""
    tools = get_tool_registry()
    agents = get_agent_registry()
    session = get_active_session()
    plans = get_recent_plans(100)

    completed_plans = len([p for p in plans if p.get("status") == "completed"])
    pending_plans = len([p for p in plans if p.get("status") in ["planned", "approved"]])

    return {
        "tools_count": len(tools.get("tools", {})),
        "agents_count": len(agents.get("agents", {})),
        "plans_total": len(plans),
        "plans_completed": completed_plans,
        "plans_pending": pending_plans,
        "session_active": session is not None,
        "session": session,
        "timestamp": datetime.now().isoformat()
    }

# -----------------------------------------------------------------------------
# API ROUTES
# -----------------------------------------------------------------------------

@app.get("/")
async def root():
    """Serve main UI."""
    ui_path = Path(__file__).parent.parent / "ui" / "index.html"
    if ui_path.exists():
        with open(ui_path, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return HTMLResponse(content="<h1>HIA Console</h1><p>UI not found</p>")


@app.get("/api/status")
async def get_status():
    """Get system status."""
    return get_system_stats()


@app.get("/api/tools")
async def get_tools():
    """Get registered tools."""
    return get_tool_registry()


@app.get("/api/agents")
async def get_agents():
    """Get registered agents."""
    return get_agent_registry()


@app.get("/api/plans")
async def get_plans(limit: int = 20):
    """Get recent plans."""
    return {"plans": get_recent_plans(limit)}


@app.get("/api/session")
async def get_session():
    """Get active session."""
    session = get_active_session()
    return {"active": session is not None, "session": session}


@app.post("/api/command")
async def execute_command(request: CommandRequest):
    """Execute HIA command."""
    result = run_hia_command(request.command, request.args)
    return result


@app.post("/api/session")
async def manage_session(action: SessionAction):
    """Manage session lifecycle."""
    if action.action == "start":
        result = run_hia_command("session", ["start"])
    elif action.action == "close":
        args = ["close"]
        if action.message:
            args.extend(["-Message", action.message])
        result = run_hia_command("session", args)
    elif action.action == "log":
        if not action.message:
            raise HTTPException(status_code=400, detail="Message required for log")
        result = run_hia_command("session", ["log", "-Message", action.message])
    else:
        raise HTTPException(status_code=400, detail=f"Unknown action: {action.action}")

    return result


@app.post("/api/smoke")
async def run_smoke():
    """Run smoke test."""
    return run_hia_command("smoke")


@app.post("/api/state/sync")
async def sync_state():
    """Sync project state."""
    return run_hia_command("state", ["sync"])


@app.get("/api/health")
async def health():
    """Health check."""
    return {"status": "ok", "timestamp": datetime.now().isoformat()}

# -----------------------------------------------------------------------------
# WEBSOCKET FOR REAL-TIME LOGS
# -----------------------------------------------------------------------------

connected_clients: List[WebSocket] = []


@app.websocket("/ws/logs")
async def websocket_logs(websocket: WebSocket):
    """WebSocket endpoint for real-time logs."""
    await websocket.accept()
    connected_clients.append(websocket)

    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_json({"type": "ack", "data": data})
    except WebSocketDisconnect:
        connected_clients.remove(websocket)


async def broadcast_log(message: str, level: str = "info"):
    """Broadcast log to all connected clients."""
    log_entry = {
        "type": "log",
        "level": level,
        "message": message,
        "timestamp": datetime.now().isoformat()
    }
    for client in connected_clients:
        try:
            await client.send_json(log_entry)
        except:
            pass

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

# -----------------------------------------------------------------------------
# LIGHT PARSERS (CLI text -> JSON-lite)
# -----------------------------------------------------------------------------

def parse_portfolio(output: str) -> Dict[str, Any]:
    projects = []
    for line in output.splitlines():
        line = line.strip()
        if not line.startswith('[') or '->' in line:
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        try:
            idx = int(parts[0].strip('[]'))
        except ValueError:
            continue
        proj_id = parts[1]
        session = parts[3] if len(parts) > 3 else 'N/A'
        evidence = parts[4] if len(parts) > 4 else 'N/A'
        safety = parts[5] if len(parts) > 5 else 'N/A'
        projects.append({
            'index': idx,
            'project_id': proj_id,
            'session': session,
            'evidence': evidence,
            'safety': safety
        })
    return {'projects': projects, 'raw': output}


def parse_project_status(output: str) -> Dict[str, Any]:
    data: Dict[str, Any] = {'raw': output}
    fields = [
        'PROJECT_ID', 'CURRENT_OBJECTIVE', 'NEXT_ACTION', 'NEXT_READY_ITEM',
        'LAST_SESSION_STATUS', 'EVIDENCE_STATE', 'EVIDENCE_AGE_HOURS',
        'SESSION_SAFETY', 'SESSION_SAFETY_NOTES', 'AI_LAST_PLAN', 'AI_GUIDANCE',
        'AI_PLAN_LOG', 'AI_MEMORY_STATUS', 'LATEST_OUTPUT_PATH', 'LATEST_LOG_PATH',
        'LAST_TASK_SCOPE', 'LAST_TASK_RESULT', 'LAST_TASK_REQUEST', 'LAST_TASK_TARGET',
        'LAST_TASK_MESSAGE', 'LAST_TASK_EVIDENCE', 'LAST_TASK_CONTINUITY_HINT'
    ]
    for line in output.splitlines():
        for field in fields:
            prefix = f"{field}:"
            if line.startswith(prefix):
                data[field.lower()] = line.replace(prefix, '').strip()
    return data


def parse_ai_plan(output: str) -> Dict[str, Any]:
    data: Dict[str, Any] = {'raw': output}
    mapping = [
        ('PROJECT_ID:', 'project_id'),
        ('DECISION_REF:', 'decision_ref'),
        ('MODE:', 'mode'),
        ('EXECUTOR:', 'executor'),
        ('PRESET:', 'preset'),
        ('REQUEST:', 'request'),
        ('RESULT_SUMMARY:', 'result_summary'),
        ('AI_NEXT_HINT:', 'ai_next_hint'),
        ('AI_SUGGESTED_COMMAND:', 'ai_suggested_command'),
        ('AI_PLAN_LOG:', 'ai_plan_log'),
        ('MEMORY_APPENDED:', 'memory_appended'),
        ('MEMORY_PATH:', 'memory_path'),
    ]
    for line in output.splitlines():
        for key, target in mapping:
            if line.startswith(key):
                data[target] = line.replace(key, '').strip()
    return data
# -----------------------------------------------------------------------------
# PEDSTRIAN API SURFACES (portfolio / project / ai plan)
# -----------------------------------------------------------------------------

@app.get("/api/portfolio")
async def api_portfolio():
    res = run_hia_command("projects", ["status"])
    return build_response(res, parse_portfolio(res.get("output", "")))


@app.get("/api/project/{project_id}")
async def api_project(project_id: str):
    res = run_hia_command("project", ["status", project_id])
    return build_response(res, parse_project_status(res.get("output", "")))


class AIPlanRequest(BaseModel):
    project_id: str
    preset: Optional[str] = None
    remember: bool = False
    request: Optional[str] = None


@app.post("/api/ai/plan")
async def api_ai_plan(body: AIPlanRequest):
    args = ["plan", body.project_id]
    if body.preset:
        args += ["--preset", body.preset]
    elif body.request:
        args += [body.request]
    else:
        raise HTTPException(status_code=400, detail="Preset or request required")
    if body.remember:
        args += ["--remember"]
    res = run_hia_command("ai", args)
    parsed = parse_ai_plan(res.get("output", ""))
    return build_response(res, parsed)


def build_response(res: dict, parsed: Dict[str, Any] = None) -> Dict[str, Any]:
    return {
        "success": res.get("success", False),
        "exit_code": res.get("exit_code", -1),
        "output": res.get("output", ""),
        "error": res.get("error", ""),
        "command": res.get("command", []),
        "parsed": parsed if parsed is not None else None
    }


@app.get("/api/health/full")
async def health_full():
    portfolio = run_hia_command("projects", ["status"])
    return build_response(portfolio, {"projects_detected": len(parse_portfolio(portfolio.get("output",""))['projects'])})




@app.post("/api/project/{project_id}/delete")
async def api_project_delete(project_id: str, body: DeleteRequest):
    args = ["delete", project_id, "--confirm", body.confirm]
    res = run_hia_command("project", args)
    return build_response(res)




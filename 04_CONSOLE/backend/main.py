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
            encoding="utf-8",
            errors="replace",
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
    stripped = output.strip()
    json_candidate = stripped
    if not (json_candidate.startswith("{") and '"projects"' in json_candidate):
        start = stripped.find("{")
        end = stripped.rfind("}")
        if start != -1 and end != -1 and end > start:
            json_candidate = stripped[start : end + 1].strip()

    if json_candidate.startswith("{") and '"projects"' in json_candidate:
        try:
            parsed_json = json.loads(json_candidate)
            projects = parsed_json.get("projects", [])
            if isinstance(projects, list):
                clean_projects = []
                for item in projects:
                    if not isinstance(item, dict):
                        continue
                    project_id = str(item.get("project_id", "")).strip()
                    if project_id.upper() in ("_ARCHIVE", "_ARCHIVE_BIN", "TEST1", "TEST2"):
                        continue
                    clean_projects.append(
                        {
                            "index": item.get("index"),
                            "project_id": project_id,
                            "next": item.get("next", "N/A"),
                            "session": item.get("session", "unknown"),
                            "evidence": item.get("evidence", "unknown"),
                            "safety": item.get("safety", "unknown"),
                            "ledger": item.get("ledger", "N/A"),
                        }
                    )
                return {"projects": clean_projects, "count": len(clean_projects), "raw": output}
        except Exception:
            pass

    projects = []
    # Fixed-width columns written by Get-HIAProjects (status mode)
    field_widths = [18, 24, 10, 9, 8, 24]  # PROJECT_ID, NEXT, SESSION, EVIDENCE, SAFETY, LEDGER

    # Build index map from the "INDEX MAP:" section to recover full project IDs (they may be truncated in the table).
    index_map: Dict[int, str] = {}
    for line in output.splitlines():
        if "->" not in line:
            continue
        try:
            left, right = line.split("->", 1)
            idx_text = left.replace("[", "").replace("]", "").strip()
            idx = int(idx_text)
            proj_id = right.strip()
            if proj_id:
                index_map[idx] = proj_id
        except Exception:
            continue

    for line in output.splitlines():
        stripped = line.strip()
        if not stripped.startswith("["):
            continue
        if "->" in line:
            # already handled for index_map
            continue
        try:
            idx_end = line.index("]")
            idx_text = line[1:idx_end].strip()
            idx = int(idx_text)
        except Exception:
            continue
        row = line[idx_end + 1 :].rstrip("\n")
        total_width = sum(field_widths) + (len(field_widths) - 1)  # one space between columns
        row = row.ljust(total_width)
        pos = 0
        cols = []
        for w in field_widths:
            segment = row[pos : pos + w]
            cols.append(segment.strip())
            pos += w
            # skip single inter-column space if present
            if pos < len(row) and row[pos : pos + 1] == " ":
                pos += 1
        if len(cols) < 6:
            continue
        proj_id, next_field, session, evidence, safety, ledger = cols[:6]
        # prefer full id from index map when available
        if idx in index_map:
            proj_id = index_map[idx]
        if proj_id.upper() in ("_ARCHIVE", "_ARCHIVE_BIN"):
            continue
        projects.append(
            {
                "index": idx,
                "project_id": proj_id,
                "session": session or "N/A",
                "evidence": evidence or "N/A",
                "safety": safety or "N/A",
                "next": next_field,
                "ledger": ledger or "N/A",
            }
        )
    return {"projects": projects, "count": len(projects), "raw": output}

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
    res = run_hia_command("projects", ["status", "--json"])
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




class CreateIterationRequest(BaseModel):
    project_id: str


@app.post("/api/project/new")
async def api_project_new(body: CreateIterationRequest):
    """Create a new iteration instance (backed by CLI project new)."""
    if not body.project_id or not body.project_id.strip():
        raise HTTPException(status_code=400, detail="project_id required")
    res = run_hia_command("project", ["new", body.project_id.strip()])
    return build_response(res, {"project_id": body.project_id.strip()})

@app.post("/api/project/{project_id}/delete")
async def api_project_delete(project_id: str, body: DeleteRequest):
    args = ["delete", project_id, "--confirm", body.confirm]
    res = run_hia_command("project", args)
    return build_response(res)



















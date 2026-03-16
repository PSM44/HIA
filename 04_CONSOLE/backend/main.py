"""
HIA Console v0.1 backend

FastAPI wrapper that exposes HIA console commands and delegates to
existing PowerShell tooling. Keeps everything TXT-first and avoids
introducing non-textual stores.
"""

from __future__ import annotations

import datetime
import shutil
import subprocess
from pathlib import Path
from typing import List, Optional

from fastapi import Body, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

ROOT = Path(__file__).resolve().parents[2]  # HIA project root
TOOLS = ROOT / "02_TOOLS"
MAINT = TOOLS / "Maintenance"


class AIRequest(BaseModel):
    prompt: str
    model: Optional[str] = None


class ValidateRequest(BaseModel):
    mode: str = "DRAFT"


class CommandResult(BaseModel):
    command: List[str]
    returncode: int
    stdout: str
    stderr: str
    started_utc: str
    ended_utc: str


app = FastAPI(title="HIA Console v0.1", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _timestamp() -> str:
    return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")


def run_powershell(script: Path, extra_args: Optional[List[str]] = None) -> CommandResult:
    if not script.exists():
        raise HTTPException(status_code=404, detail=f"Script not found: {script}")

    args = extra_args or []
    cmd = ["pwsh", "-NoProfile", "-File", str(script), *args]
    start = _timestamp()
    proc = subprocess.run(
        cmd,
        cwd=ROOT,
        capture_output=True,
        text=True,
        shell=False,
    )
    end = _timestamp()
    return CommandResult(
        command=cmd,
        returncode=proc.returncode,
        stdout=proc.stdout,
        stderr=proc.stderr,
        started_utc=start,
        ended_utc=end,
    )


def run_command(cmd: List[str], cwd: Optional[Path] = None) -> CommandResult:
    start = _timestamp()
    proc = subprocess.run(
        cmd,
        cwd=cwd or ROOT,
        capture_output=True,
        text=True,
        shell=False,
    )
    end = _timestamp()
    return CommandResult(
        command=cmd,
        returncode=proc.returncode,
        stdout=proc.stdout,
        stderr=proc.stderr,
        started_utc=start,
        ended_utc=end,
    )


def _git_branch() -> str:
    cmd = ["git", "rev-parse", "--abbrev-ref", "HEAD"]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, shell=False)
    if result.returncode != 0:
        return "unknown"
    return result.stdout.strip()


@app.get("/api/ping")
def ping():
    return {"status": "ok", "timestamp_utc": _timestamp()}


@app.get("/api/context")
def context():
    return {
        "project_root": str(ROOT),
        "branch": _git_branch(),
        "timestamp_utc": _timestamp(),
        "tools_available": {
            "start": (MAINT / "HIA_TOL_0041_Start-Session.ps1").exists(),
            "close": (MAINT / "HIA_TOL_0042_Close-Session.ps1").exists(),
            "stack": (MAINT / "HIA_TOL_0040_Check-AIStack.ps1").exists(),
            "radar": (TOOLS / "RADAR.ps1").exists(),
            "validators": (TOOLS / "Invoke-HIAValidators.ps1").exists(),
        },
    }


@app.post("/api/start", response_model=CommandResult)
def start_session():
    script = MAINT / "HIA_TOL_0041_Start-Session.ps1"
    return run_powershell(script, ["-ProjectRoot", str(ROOT)])


@app.post("/api/close", response_model=CommandResult)
def close_session():
    script = MAINT / "HIA_TOL_0042_Close-Session.ps1"
    return run_powershell(script, ["-ProjectRoot", str(ROOT)])


@app.post("/api/stack", response_model=CommandResult)
def check_ai_stack():
    script = MAINT / "HIA_TOL_0040_Check-AIStack.ps1"
    return run_powershell(script, [])


@app.post("/api/radar", response_model=CommandResult)
def run_radar():
    script = TOOLS / "RADAR.ps1"
    return run_powershell(script, ["-RootPath", str(ROOT)])


@app.post("/api/validate", response_model=CommandResult)
def run_validators(payload: ValidateRequest = Body(default=ValidateRequest())):
    script = TOOLS / "Invoke-HIAValidators.ps1"
    mode = payload.mode.upper() if payload.mode else "DRAFT"
    args = ["-ProjectRoot", str(ROOT), "-Mode", mode]
    return run_powershell(script, args)


@app.post("/api/ai")
def ask_ai(request: AIRequest):
    model = request.model or "llama3"
    prompt = request.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt is required")

    if shutil.which("ollama"):
        cmd = ["ollama", "run", model, prompt]
        result = run_command(cmd)
        return result

    # Fallback: simple echo for environments without Ollama
    return JSONResponse(
        status_code=200,
        content={
            "command": ["ollama", "run", model, "<prompt>"],
            "returncode": 0,
            "stdout": f"[fallback] ollama not available. Echoing prompt:\n{prompt}",
            "stderr": "",
            "started_utc": _timestamp(),
            "ended_utc": _timestamp(),
        },
    )


@app.get("/")
def root():
    ui_dir = ROOT / "04_CONSOLE" / "ui"
    if ui_dir.exists():
        return RedirectResponse(url="/ui/")
    return {"message": "HIA Console backend ready", "timestamp_utc": _timestamp()}


ui_directory = ROOT / "04_CONSOLE" / "ui"
if ui_directory.exists():
    app.mount("/ui", StaticFiles(directory=ui_directory, html=True), name="ui")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

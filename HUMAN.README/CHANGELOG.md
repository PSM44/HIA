# HIA — Changelog

## [v0.5.0-alpha] — 2026-03-16

### Session: h1/hia-dev-session-20260316

**Operator:** aazcl
**Duration:** ~3 hours
**Method:** Claude + Codex Desktop

### MiniBattles Completed

| ID | Name | Description |
|----|------|-------------|
| MB-0.1 | Command Router | CLI entrypoint with HIA_ROUTER.ps1 |
| MB-0.2 | Tool & Agent Registry | JSON registries + dynamic routing |
| MB-0.3 | Smoke Test | System validation script |
| MB-0.4 | Agent Executor | Controlled execution with gates |
| MB-0.5 | State Sync | Automatic state management |
| MB-0.6 | Session Lifecycle | Start/close sessions with logging |
| MB-1.0 | Console Web MVP | FastAPI + HTML UI |

### Features Added

- **9 Tools registered:** radar, validate, plan, apply, sync, checkpoint, smoke, state, session
- **2 Agents registered:** planner, executor
- **Web Console:** http://localhost:8000
- **Demo Mode UI:** Executive-friendly presentation interface
- **Auto Demo:** 15-second guided demonstration sequence
- **Business Impact KPIs:** Visual metrics for management

### Files Created/Modified
```
01_UI/terminal/
├── hia.ps1 (entrypoint)
└── hia-shell.ps1

02_TOOLS/
├── HIA_ROUTER.ps1 (v2.0)
├── TOOL.REGISTRY.json (9 tools)
├── HIA_STATE_ENGINE.ps1
├── HIA_SESSION_ENGINE.ps1
└── Invoke-HIASmoke.ps1 (v2.0)

03_ARTIFACTS/
├── sessions/
│   ├── SESSION.ACTIVE.json
│   └── history/
├── logs/
│   └── STATE.HISTORY.txt
└── plans/

04_AGENTS/
├── AGENT.REGISTRY.json (2 agents)
├── HIA_AGENT_001_Planner.ps1
└── HIA_AGENT_002_Executor.ps1

04_CONSOLE/
├── backend/
│   ├── main.py (FastAPI)
│   └── requirements.txt
├── ui/
│   └── index.html (Demo Mode)
└── start-console.ps1
```

Commands Available
```
# CLI Commands
hia help                    # List all commands
hia smoke                   # System validation
hia state                   # Show project state
hia state sync              # Sync state from artifacts
hia session start           # Start work session
hia session close           # Close session with checkpoint
hia plan "task"             # Create execution plan
hia apply PLAN_X            # Approve and execute plan
hia agent planner "task"    # AI planning agent
hia agent executor -Request "task"  # Controlled execution

# Web Console
cd 04_CONSOLE
.\start-console.ps1         # Start on http://localhost:8000
```

### Technical Notes

- PowerShell 7+ required
- Python 3.10+ for web console
- FastAPI + Uvicorn backend
- All tools use PROJECT_ROOT resolution
- UTF-8 encoding throughout
- Git checkpoints on session close

### Next Steps

- [ ] MB-1.1: Authentication for web console
- [ ] MB-1.2: Real-time WebSocket logs
- [ ] MB-2.0: Multi-agent orchestration
- [ ] Production deployment guide

---

## [v0.1.0-alpha] — 2026-03-13

- Initial project structure
- Basic CLI framework
- RADAR tool
- Framework documentation

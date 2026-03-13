\# AGENTS.md



\## Project



HIA – Human-Integrated AI Operating System



This repository implements HIA, an AI governance and orchestration system designed to manage AI tools, sessions, and project context.



The system provides a console interface for human operators ("pedestrians") to interact with AI models, development tools, and project artifacts.



\---



\# Core Principles



1\. HUMAN governance is the highest authority.

2\. AI tools must never modify HUMAN governance files.

3\. All operations must be traceable through logs and artifacts.

4\. Each development session must run inside a git branch.



\---



\# Repository Structure



The repository follows a strict architecture.



00\_HUMAN  

Human governance files



01\_KERNEL  

Core runtime logic for HIA



02\_TOOLS  

PowerShell automation tools



03\_ARTIFACTS  

Logs, sessions, radar index, and context snapshots



04\_CONSOLE  

User interface for the HIA console



05\_AGENTS  

Agent orchestration modules



06\_AI\_STACK  

Adapters for AI engines (Ollama, Codex, Claude)



07\_CONFIG  

Configuration files



99\_TEMP  

Temporary files (not indexed)



Agents should respect this structure.



\---



\# Development Objective



Current milestone:



HIA Console v0.1



Goal:



Implement a working console interface that allows a human operator to:



\- Confirm context

\- Start a session

\- Check AI stack

\- Run RADAR

\- Run validators

\- Ask AI

\- Close session



\---



\# Console Architecture



The console should be implemented using:



Python  

FastAPI backend  

HTML single page interface  



Accessible through:



http://localhost:8000



The interface should follow a terminal-style design.



\---



\# Command Model



The console executes HIA commands.



Commands:



hia context  

hia start  

hia stack  

hia radar  

hia validate  

hia ai  

hia close  



Each UI action must map to one of these commands.



\---



\# Tools Integration



The system must integrate with existing PowerShell tools.



Tools location:



02\_TOOLS/Maintenance/



Key scripts:



HIA\_TOL\_0040\_Check-AIStack.ps1  

HIA\_TOL\_0041\_Start-Session.ps1  

HIA\_TOL\_0042\_Close-Session.ps1  



Agents must call these scripts rather than re-implementing their functionality.



\---



\# Context Handling



HIA uses externalized context.



Agents should read context from files instead of assuming persistent memory.



Relevant directories:



03\_ARTIFACTS/SESSIONS  

03\_ARTIFACTS/CONTEXT  

03\_ARTIFACTS/LOGS  



\---



\# Git Workflow



All development must occur in the current working branch.



Example branch format:



h1/session-YYYYMMDD-HHMM



Agents must not change branches automatically.



Commits should be small and descriptive.



\---



\# Safety Rules



Agents must NOT:



\- Modify HUMAN governance files

\- Delete artifacts

\- Modify git history

\- Execute destructive commands



Agents may:



\- Create new files

\- Modify code under 01\_KERNEL and 04\_CONSOLE

\- Integrate existing tools



\---



\# Implementation Priority



Agents should focus only on:



HIA Console v0.1



Do NOT implement:



\- multi-agent orchestration

\- vector databases

\- autonomous agents

\- advanced AI routing



These will be implemented later.



\---



\# Expected Output



Agents should implement:



04\_CONSOLE/



backend  

ui  

static  



Backend must expose API endpoints corresponding to the HIA command model.



\---



\# Final Goal



Deliver a functional console where a human operator can control the HIA system through a simple interface.


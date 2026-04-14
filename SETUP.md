# ROSTR — One-Step Setup

**Works with:** Claude Code · Codex CLI · OpenCode · OpenClaw · Cursor · any AI coding tool

---

## Option A — Curl Installer (fastest)

```bash
curl -fsSL https://raw.githubusercontent.com/diamitani/rostr-paper/main/install.sh | bash
```

Does three things automatically:
1. Installs the ContextEngine skill to `.claude/skills/context-engine/`
2. Creates `.context-engine/` memory directory
3. Appends ROSTR operating instructions to your `CLAUDE.md`

---

## Option B — Paste Prompt (works in any AI tool)

Copy the block below and paste it as your first message to any AI coding assistant.
The AI will set up ROSTR in your current workspace.

---

```
Set up the ROSTR framework in this workspace. ROSTR is an open-source agent OS with five layers:
PAL (Prompt Abstraction Layer), NPAO (Necessity·Priority·Anxiety·Opportunity classification),
RAG DAL (multi-pass retrieval), ContextEngine (persistent session memory), and ROSTR Hub
(runtime orchestration).

Please do the following:

1. Create the file `.claude/skills/context-engine/SKILL.md` with this exact content:

---
name: context-engine
description: >
  Persistent session memory layer for Claude. Use this skill ANY TIME someone wants to:
  save what happened in a session, cache session activity, log progress, retrieve past context,
  generate a progress or troubleshooting report, do a "context flash" (load last session summary),
  or run a scheduled memory report. ALWAYS trigger on: "save this session", "cache what we did",
  "log our progress", "what did we work on last time", "context flash", "load context",
  "what have we been building", "generate a progress report", "troubleshooting log", "session summary",
  "memory report", "what's our current state", "recap what worked", or any request to persist, retrieve,
  or report on past session activity.
---

# ContextEngine — Persistent Session Memory Layer

## Storage Layout
All state lives in `.context-engine/` relative to workspace root:
  .context-engine/
  ├── sessions/           # One .json per session (immutable)
  ├── index/master.jsonl  # Append-only session log
  ├── reports/            # Generated markdown reports
  ├── cache/last.json     # Fast-load most-recent snapshot
  └── CONTEXT.md          # Always-current human-readable state

Create on first use: mkdir -p .context-engine/sessions .context-engine/index .context-engine/reports .context-engine/cache

## Session Record Schema
{
  "session_id": "YYYYMMDD_HHMMSS",
  "date": "ISO 8601",
  "project": "workspace name",
  "duration_estimate": "short|medium|long",
  "summary": "2-3 sentence narrative",
  "tools_used": [],
  "files_created": [],
  "files_modified": [],
  "skills_invoked": [],
  "what_worked": [],
  "what_failed": [],
  "decisions_made": [],
  "open_questions": [],
  "next_steps": [],
  "tags": [],
  "blockers": []
}

## Modes

### CACHE — Save Session
Trigger: "save this session" / "cache what we did" / "log progress"
1. Review conversation, extract facts
2. Populate session schema (infer; only ask if critically ambiguous)
3. Write to .context-engine/sessions/{session_id}.json
4. Append to .context-engine/index/master.jsonl
5. Overwrite .context-engine/cache/last.json
6. Regenerate .context-engine/CONTEXT.md
7. Confirm: "Session cached. {N} total sessions in index."

### RETRIEVE — Context Flash
Trigger: "context flash" / "what did we work on" / "catch me up"
1. Read last.json + last 3-5 records from master.jsonl
2. Surface: last session summary, what worked, what failed, next steps
3. Lead with: recommended starting point (not a history dump)

### REPORT — Progress Report
Trigger: "generate a report" / "progress report" / "weekly summary"
1. Read all of master.jsonl (filter by date/tags if specified)
2. Generate markdown: exec summary, progress highlights, troubleshooting log, decisions, open items, session timeline
3. Save to .context-engine/reports/{date}_report.md

### QUERY — Search History
Trigger: "when did we fix X" / "find sessions tagged Y"
Filter master.jsonl by tags, keywords in what_worked/what_failed, tools_used, date.

### SCHEDULE
Trigger: "schedule weekly report"
Use schedule skill to run REPORT mode on configured interval.

## Rules
- Never delete session files — append-only index
- what_failed: be specific ("HTTP 401 on endpoint X" not "auth issue")
- CONTEXT.md: human-readable, scannable in 60 seconds
- RETRIEVE leads with action, not history

## Quick Reference
| Say...                        | Mode     |
|-------------------------------|----------|
| "save this session"           | CACHE    |
| "context flash"               | RETRIEVE |
| "generate a report"           | REPORT   |
| "find when we fixed X"        | QUERY    |
| "schedule weekly report"      | SCHEDULE |

2. Create the directory structure:
   mkdir -p .context-engine/sessions .context-engine/index .context-engine/reports .context-engine/cache

3. Create `.context-engine/CONTEXT.md` with:
   # Project Context — ROSTR Initialized
   ## Current State
   ROSTR framework installed. ContextEngine active. Say "context flash" to load history or "save this session" to capture this session.
   ## What's Working
   - ContextEngine skill installed
   - .context-engine/ directory ready
   ## Active Blockers
   (none)
   ## Open Next Steps
   1. Run your first session and say "save this session" when done

4. Append this block to CLAUDE.md (create it if it doesn't exist):

## ROSTR Framework

This workspace uses the ROSTR agent OS. Docs: https://github.com/diamitani/rostr-paper

### NPAO — Classify every task before executing (order: N → A → P → O)
- N — Necessity ("I MUST"): Hard blocker. Execute first. Nothing downstream works without it.
- A — Anxiety ("I WON'T HAVE PEACE"): Cognitive friction. Clear BEFORE Priority work or it degrades execution.
- P — Priority ("I NEED"): Mission-critical. Execute with full focus.
- O — Opportunity ("I CAN"): Growth, upside. Execute last when bandwidth allows.

### ContextEngine — Always active
- End of session → "save this session" → CACHE
- Start of session → "context flash" → RETRIEVE
- Weekly → "generate a report" → REPORT
- Search history → "find when we fixed X" → QUERY

### PAL — Always active
Before executing any prompt: extract intent, inject context, enhance precision, route to correct agent.

### RAG DAL — Always multi-pass
Never single-pass retrieval. Tier 1 (authoritative) > Tier 2 (verified) > Tier 3 (community). Self-assess coverage before completing retrieval.

Confirm when done: "ROSTR framework installed. ContextEngine active. Say 'context flash' to load history."
```

---

## Option C — Manual Setup (3 files, 2 minutes)

**Step 1:** Copy `skills/context-engine/SKILL.md` from this repo into your workspace:
```
.claude/skills/context-engine/SKILL.md
```

**Step 2:** Create memory directory:
```bash
mkdir -p .context-engine/sessions .context-engine/index .context-engine/reports .context-engine/cache
```

**Step 3:** Add to your `CLAUDE.md` (or `AGENTS.md` / `SYSTEM_PROMPT.md`):
```markdown
## ROSTR Framework
NPAO execution order: N → A → P → O
- N: Hard blockers — first
- A: Anxiety/friction — clear before Priority  
- P: Mission-critical — full focus
- O: Opportunity — last

ContextEngine: say "save this session" / "context flash" / "generate a report"
PAL: extract intent and enhance before executing
RAG DAL: multi-pass retrieval, credibility-tiered sources
```

---

## What Gets Installed

| File | Purpose |
|---|---|
| `.claude/skills/context-engine/SKILL.md` | ContextEngine skill — session memory |
| `.context-engine/CONTEXT.md` | Living state document — always current |
| `.context-engine/index/master.jsonl` | Append-only session index |
| `CLAUDE.md` (updated) | ROSTR operating instructions |

---

## Framework Docs

| Whitepaper | Topic |
|---|---|
| [Combined Whitepaper](framework/ROSTR_Framework_Combined_Whitepaper.md) | Start here |
| [PAL](framework/PAL_Whitepaper.md) | Prompt compilation |
| [NPAO](framework/NPAO_Whitepaper.md) | Task classification |
| [RAG DAL](framework/RAGDAL_Whitepaper.md) | Retrieval layer |
| [ContextEngine](framework/ContextEngine_Whitepaper.md) | Session memory |
| [ROSTR Hub](framework/ROSTR_Whitepaper.md) | Runtime orchestration |

---

*ROSTR · Apache 2.0 · Patrick Diamitani · April 2026*
*https://github.com/diamitani/rostr-paper*

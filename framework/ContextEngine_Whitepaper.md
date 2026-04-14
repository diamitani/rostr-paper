# ContextEngine: A Persistent Session Memory Layer for LLM-Native Workspaces

**Authors:** Atlas HXM AI & Automation
**Version:** 1.0
**Date:** April 2026
**Status:** Open Source (Apache 2.0)

---

## Abstract

Large language models are stateless by design. Every conversation begins without memory of prior work, forcing users to reconstruct context manually — a friction cost that compounds as projects grow more complex. ContextEngine addresses this structural gap by introducing a flat-file, LLM-native session memory layer that automatically captures, compresses, indexes, and retrieves session activity across conversations. It operates without external infrastructure, deploys as a single skill file, and exposes five deterministic modes: CACHE, RETRIEVE, REPORT, QUERY, and SCHEDULE. Within the ROSTR framework, ContextEngine functions as the persistent memory substrate — the layer that ensures agents and operators are never starting from zero.

---

## 1. The Problem: Every Session Starts Cold

Language model sessions are ephemeral by design. This is appropriate for isolated queries but fundamentally misaligned with how real work happens.

Real work is iterative. A developer debugs an n8n workflow across five sessions over three days. A GTM operator builds a prospecting automation that requires a dozen incremental refinements. A product team designs an agent system through rounds of spec → prototype → feedback → revision. In every case, the session boundary creates a hard reset: context is lost, failed approaches are rediscovered, and the operator must spend minutes — sometimes tens of minutes — reconstructing state before they can do productive work.

This problem has four compounding dimensions:

**Reconstruction Tax.** At the start of every session, users explain where they left off. This is unstructured, incomplete, and dependent on human memory. Critical context — the tool that failed, the decision that was made, the blocker that's still open — is regularly left out or misremembered.

**Failure Amnesia.** Without structured failure logging, teams repeatedly attempt the same broken approach. A Clay webhook that was confirmed non-functional on Tuesday gets diagnosed again on Thursday by a different team member. Dead ends are not indexed; they are rediscovered.

**Progress Opacity.** Multi-week projects have no durable record of what was built, in what order, and why specific decisions were made. This creates problems for onboarding, debugging, and stakeholder communication.

**Context Loss at Scale.** In multi-agent systems, agents hand off work to other agents. Without a shared memory substrate, handoff state is fragile — passed inline, often incomplete, and not queryable by downstream agents.

Existing solutions partially address these problems but each carries significant tradeoff:

| Solution | Approach | Limitation |
|---|---|---|
| Vector memory stores | Embed conversations into searchable vectors | Requires external infra (Pinecone, Weaviate); opaque retrieval; not human-readable |
| In-context window management | Pack prior context into the system prompt | Consumes tokens quickly; not persistent across sessions; no structure |
| LangChain memory modules | Conversation buffer, summary, entity memory | Tied to LangChain architecture; not portable; no operator-facing format |
| Manual notes | User writes their own summary | Inconsistent; not machine-readable; not searchable |
| GitHub commit history | Infer state from git log | Only captures code changes; misses decisions, failures, and non-code work |

ContextEngine takes a different approach: **flat-file, structured, LLM-native session memory** that requires no external services, is fully human-readable, and is designed to be maintained by the LLM itself with minimal operator overhead.

---

## 2. Design Principles

ContextEngine is built on five non-negotiable design principles:

**1. Zero Infrastructure.** ContextEngine stores all state in a local directory structure using plain JSON and Markdown files. There is no database, no embedding model, no API dependency, no cloud service. It deploys wherever the workspace lives.

**2. LLM-Native Operation.** The LLM generates, reads, and updates all records. There is no parser, no processing pipeline, no background service. The skill defines how the LLM should behave; the LLM executes it.

**3. Human-Readable by Default.** Every file ContextEngine produces — session records, the master index, CONTEXT.md, reports — is readable and editable by a non-technical user without tooling. This is intentional. Memory should not be a black box.

**4. Append-Only Index.** Session records are never deleted or modified. Corrections and updates are new records. This creates a full audit trail and prevents data loss from overwrites.

**5. Actionable Retrieval.** The goal of retrieval is not to surface raw history — it is to surface the single most useful next action. Every RETRIEVE operation leads with a recommended starting point, not a log dump.

---

## 3. Architecture

ContextEngine is organized as a flat directory structure. All state is local to the active workspace root.

```
.context-engine/
├── sessions/               ← One JSON file per session (immutable)
│   ├── 20260408_143022.json
│   ├── 20260409_091500.json
│   └── 20260410_162244.json
├── index/
│   └── master.jsonl        ← Append-only log of all session records
├── reports/                ← Generated reports (markdown)
│   ├── 20260408_progress_report.md
│   └── 20260411_troubleshooting_report.md
├── cache/
│   └── last.json           ← Most recent snapshot (fast-load path)
└── CONTEXT.md              ← Always-current human-readable state doc
```

**Why flat files over a database?**

A database introduces a dependency: a running service, a connection string, schema migrations, and a backup strategy. Flat files are universally portable, inspectable with any text editor, diff-able with git, and require no operational overhead. For a memory layer that must work across any deployment context — local Claude, Cowork, Claude Code, CI pipelines — flat files are the correct choice.

**Why JSONL for the index?**

JSONL (newline-delimited JSON) allows the index to grow by append without loading the entire file into memory. Each record is independently parseable. The format is compatible with log processing tools (jq, grep, awk) and trivially ingestible by any downstream pipeline that needs to consume session history.

**Why a separate `last.json` cache?**

The most common retrieval operation is "what happened last time?" Reading a single 2KB file is orders of magnitude faster than scanning a growing JSONL index. The cache exists to make RETRIEVE operations instant, with the master index available for deeper queries and report generation.

---

## 4. Session Record Schema

Every session compresses to a canonical JSON structure. This schema is the core data contract of ContextEngine — the normalized format that makes cross-session querying and report synthesis possible.

```json
{
  "session_id": "20260410_162244",
  "date": "2026-04-10T16:22:44Z",
  "project": "atlas-gtm-automation",
  "duration_estimate": "medium",
  "summary": "Built and deployed the Clay-to-HubSpot n8n webhook. Resolved auth issue blocking the sync. Tested with 3 live company records successfully.",
  "tools_used": ["bash", "edit", "write", "n8n-engineer"],
  "files_created": ["n8n/clay_hubspot_sync.json"],
  "files_modified": ["n8n/webhook_config.yaml"],
  "skills_invoked": ["n8n-engineer", "gtm-architect"],
  "what_worked": [
    "n8n HTTP Request node with Bearer token auth",
    "Clay webhook trigger on new company enrollment",
    "HubSpot company create/update upsert pattern"
  ],
  "what_failed": [
    "HubSpot API v1 endpoint deprecated — switched to v3",
    "Initial OAuth2 flow failed on n8n; fell back to API key auth"
  ],
  "decisions_made": [
    "Used API key auth instead of OAuth2 — faster to ship, acceptable for internal automation",
    "Upsert on company domain to avoid duplicates"
  ],
  "open_questions": [
    "Does the webhook handle Clay bulk exports (>500 rows)?",
    "What happens on HubSpot rate limit — does n8n retry automatically?"
  ],
  "next_steps": [
    "Test with full Clay table export (1000 rows)",
    "Add error notification to Slack on webhook failure",
    "Document the endpoint URL for the GTM team"
  ],
  "tags": ["n8n", "clay", "hubspot", "webhook", "gtm-automation"],
  "blockers": []
}
```

**Schema Design Decisions:**

`duration_estimate` (short / medium / long) provides a rough proxy for session depth without requiring timestamps from both ends of a conversation. It helps report generation identify sessions worth drilling into.

`what_worked` and `what_failed` are separated rather than combined into a single "notes" field. This separation enables targeted troubleshooting queries: "show me all sessions where HubSpot auth failed" becomes a filter on `what_failed`, not a freeform search.

`tags` are lowercase, reusable, tool- and workflow-scoped. They are the primary dimension for cross-session querying. Tags like `n8n`, `clay`, `hubspot`, `rfp`, `outreach`, and `skill-build` recur across sessions and create a navigable taxonomy over time.

`next_steps` are written as actionable imperatives, not questions. They are the seed for the next session's startup context.

`blockers` is separate from `what_failed`. A blocker is a live constraint that prevents progress. A failure is a past event. A session might have failures and no blockers (everything was fixed) or no failures and an open blocker (hit a wall, couldn't unblock, need to return).

---

## 5. The Five Modes

ContextEngine exposes five deterministic operating modes. Each mode is triggered by a natural language pattern and executes a defined sequence of read/write operations.

### 5.1 CACHE — Capture Session State

**Trigger:** "save this session", "cache what we did", "log progress", end of session.

CACHE is the write path. At session end, the LLM reviews the full conversation, extracts structured facts, and writes them to three destinations: a new session file, the master index, and the `last.json` cache. It also regenerates `CONTEXT.md` to reflect the latest project state.

```
CACHE execution:
1. Review conversation history
2. Populate session record schema (infer; ask only if critical fields are ambiguous)
3. Generate session_id from current timestamp
4. Write → .context-engine/sessions/{session_id}.json
5. Append → .context-engine/index/master.jsonl
6. Overwrite → .context-engine/cache/last.json
7. Regenerate → .context-engine/CONTEXT.md
8. Confirm: "Session cached. {N} total sessions in index."
```

**Design note:** CACHE never asks the user to fill in a form. The LLM generates all fields from conversation history. The only time CACHE asks a clarifying question is if a critical ambiguity would materially change the record — for example, if the project name is unclear because the user switched contexts mid-session.

### 5.2 RETRIEVE — Context Flash

**Trigger:** "context flash", "what did we work on", "load context", "catch me up", "what's our current state".

RETRIEVE is the fast-load read path. It loads `last.json` and the last 3–5 records from `master.jsonl`, then surfaces a structured recap designed to get the operator productive within 60 seconds.

```
RETRIEVE output format:
Last session: {date} — {summary}
  ✅ What worked: {top 2-3 wins}
  ❌ What failed: {top 1-2 failures}
  → Next steps: {top 2 recommended actions}

Pattern (last {N} sessions): {any recurring themes or blockers}
Recommended starting point: {single most actionable next step}
```

**Design note:** RETRIEVE leads with the recommended starting point — not a history dump. The goal is to eliminate the reconstruction tax, not to create a reading assignment.

### 5.3 REPORT — Synthesize Progress

**Trigger:** "generate a report", "progress report", "troubleshooting log", "what have we been building", "weekly summary".

REPORT reads the full `master.jsonl` index, applies any filters the user provides (date range, tags, project), and generates a structured markdown report saved to `.context-engine/reports/`.

```
Report sections:
- Executive Summary (3-5 sentence narrative)
- Progress Highlights (what shipped, what was solved)
- Troubleshooting Log (failures grouped by tool/workflow)
- Decisions Made (key choices and rationale)
- Open Items (ranked unresolved questions and next steps)
- Session Timeline (table: date | summary | tags | result)
- Patterns Observed (recurring themes, repeated friction)
```

Reports are saved to the reports directory and linked to the user. They are generated as markdown, making them immediately usable in Notion, GitHub, Confluence, or any documentation tool.

### 5.4 QUERY — Search Session History

**Trigger:** "when did we fix X", "find sessions tagged hubspot", "what was the issue with Clay last week", "search sessions for OAuth".

QUERY treats `master.jsonl` as a searchable log. It filters by tags, keywords in summary/what_worked/what_failed, tools_used, date ranges, and blockers. Results are returned in a scannable format with key facts surfaced. The user can ask to expand any specific session.

**Why keyword search over vector search?**

For a flat-file memory store with tens to hundreds of session records, keyword and tag-based filtering is faster, more predictable, and more interpretable than vector similarity search. If the user asks "show me all sessions where n8n failed," exact tag matching on `["n8n"]` in `what_failed` is deterministic and requires no embedding infrastructure. Vector search adds value at scale (thousands of records, semantic queries) — ContextEngine is designed to add it as an optional upgrade, not a default dependency.

### 5.5 SCHEDULE — Automate Report Generation

**Trigger:** "schedule a weekly report", "auto-report every Friday", "set up daily summaries".

SCHEDULE integrates with the `schedule` skill to configure recurring REPORT execution. The user specifies frequency (daily, weekly), report type (progress, troubleshooting, full), and delivery format. The scheduled prompt triggers REPORT mode automatically at the configured interval.

```
Scheduled prompt template:
"Run context-engine REPORT mode for the past {N} days
and save to .context-engine/reports/"
```

---

## 6. CONTEXT.md — The Living State Document

`CONTEXT.md` is the human-readable face of ContextEngine. It is regenerated on every CACHE operation, making it always current. It is designed to be scannable in under 60 seconds and editable by non-technical users.

```markdown
# Project Context — Last Updated: 2026-04-10

## Current State
The Clay-to-HubSpot n8n webhook is live and tested. Awaiting
bulk export test (1000 rows) before declaring stable. Slack error
notification and team documentation are the next two items.

## What's Working
- Clay webhook trigger on company enrollment
- HubSpot v3 upsert (create or update by domain)
- n8n API key auth pattern

## Active Blockers
(none)

## Open Next Steps
1. Test bulk Clay export (1000 rows)
2. Add Slack error notification on webhook failure
3. Document endpoint URL for GTM team

## Recent Session Log
| Date       | Summary                                  | Result |
|------------|------------------------------------------|--------|
| 2026-04-10 | Clay-HubSpot webhook built and tested    | ✅     |
| 2026-04-09 | n8n setup, auth troubleshooting          | ⚠️     |
| 2026-04-08 | Initial spec and Clay table design       | ✅     |

## Tags in Use
n8n, clay, hubspot, webhook, gtm-automation
```

`CONTEXT.md` serves a dual purpose: it is the quick-load document for human operators and the structured summary that RETRIEVE uses to surface project state. Because it is plain markdown, it can be committed to git, shared in Slack, or dropped into a project wiki without modification.

---

## 7. Integration with the ROSTR Framework

Within ROSTR, ContextEngine occupies the **persistent memory substrate** layer — the mechanism through which all other layers maintain continuity across sessions.

```
ROSTR Data Flow with ContextEngine:

Session Start:
  RETRIEVE → load last.json + master.jsonl
  → Surface open next steps, active blockers, recent decisions
  → Agent and operator start with full context

During Session:
  PAL runtime → compiled agent executes
  NPAO classifies tasks (N→A→P→O)
  RAG DAL retrieves external knowledge
  ROSTR Hub coordinates state and tool signals
  ContextEngine passively tracks: tools used, files changed, decisions made

Session End:
  CACHE → compress session → write to index → update CONTEXT.md
  → State is durable; next session starts with full context
```

**ContextEngine and PAL:** PAL compiles agent specs into runtimes. ContextEngine persists the history of what those agents did — what worked, what failed, how outputs were used. This creates a feedback loop: agent performance history is retrievable and can inform future spec refinements.

**ContextEngine and NPAO:** NPAO classifies tasks by Necessity, Priority, Anxiety, and Opportunity. ContextEngine records which tasks fell into which class, what was completed, and what remains open. The `next_steps` field in session records is the natural NPAO input for the next session's task queue.

**ContextEngine and RAG DAL:** RAG DAL retrieves external knowledge during execution. ContextEngine retrieves internal session knowledge at startup. Together they give agents two complementary read paths: one into the world (RAG DAL) and one into project history (ContextEngine).

**ContextEngine and ROSTR Hub:** The Hub manages runtime state within a session. ContextEngine manages state across sessions. The Hub is the short-term memory; ContextEngine is the long-term memory. In multi-agent deployments, the Hub passes handoff context inline; ContextEngine provides the retrievable backstory.

**DOE Framework Alignment:**

| DOE Layer | ROSTR Component | ContextEngine Role |
|---|---|---|
| Directives | PAL + Reference | Records what directives were active and how they performed |
| Orchestration | NPAO + Orchestration | Logs task classification decisions and routing outcomes |
| Execution | RAG DAL + Tools | Captures what tools ran, what succeeded, what failed |

---

## 8. Deployment

ContextEngine is deployed as a single skill file (`SKILL.md`) dropped into the `.claude/skills/` directory of any Claude workspace. No configuration is required. The directory structure is created automatically on first use.

```
Installation:
1. Copy context-engine/ into .claude/skills/
2. In any session: "save this session" → starts CACHE
3. Next session: "context flash" → RETRIEVE loads last state
4. Any time: "generate a progress report" → REPORT synthesizes history
```

**Storage Footprint:**

A typical session record is 2–5 KB of JSON. At 5 sessions per week, 52 weeks per year, the full index for an active operator is under 2 MB — well within any filesystem constraint. Reports are typically 10–30 KB of markdown. The entire ContextEngine directory for a year of active use fits comfortably in a git repository alongside the project it documents.

**Multi-Workspace Support:**

Each workspace has its own `.context-engine/` directory. This provides natural isolation: GTM automation work has its own index, RFP work has its own index, and so on. Cross-workspace search is not a current feature — each workspace is a self-contained memory domain. This is an intentional design constraint that keeps retrieval fast and contextually relevant.

**Access Patterns:**

| Operation | Files Read | Files Written | Typical Latency |
|---|---|---|---|
| CACHE | Conversation history | session .json, master.jsonl, last.json, CONTEXT.md | ~5-10 seconds |
| RETRIEVE | last.json, master.jsonl (last 5 records) | — | < 2 seconds |
| REPORT | master.jsonl (all records) | reports/{date}_report.md | ~10-30 seconds |
| QUERY | master.jsonl | — | ~3-5 seconds |
| SCHEDULE | — | Scheduled task config | ~2 seconds |

---

## 9. Comparison with Existing Approaches

| Capability | ContextEngine | LangChain Memory | Vector Store (Pinecone) | Manual Notes |
|---|---|---|---|---|
| Infrastructure required | None (flat files) | Python runtime | Cloud service, API key | None |
| Human-readable output | ✅ Full | ❌ Serialized | ❌ Vectors | ✅ Full |
| Cross-session persistence | ✅ Durable | ✅ With backend | ✅ Durable | ✅ Manual |
| LLM-native operation | ✅ Native | ⚠️ Requires integration | ⚠️ Requires integration | ✅ Native |
| Structured failure logging | ✅ First-class | ❌ None | ❌ None | ⚠️ Inconsistent |
| Searchable by tag/keyword | ✅ Native | ⚠️ Limited | ✅ Semantic | ❌ Manual |
| Report generation | ✅ Automated | ❌ None | ❌ None | ❌ Manual |
| Portable (git-friendly) | ✅ Full | ❌ Backend-dependent | ❌ Cloud-dependent | ✅ Full |
| Non-technical user access | ✅ Full | ❌ Code required | ❌ Code required | ✅ Full |
| ROSTR framework native | ✅ Native | ❌ External | ❌ External | ❌ External |

---

## 10. Limitations and Constraints

**No Semantic Search.** ContextEngine uses keyword and tag-based filtering, not vector similarity search. Queries like "show me sessions where we struggled with authentication" require the word "auth" to appear in the relevant fields — the system cannot infer synonyms. This is an intentional tradeoff for zero-infrastructure operation; vector search is a planned optional upgrade.

**LLM Compression Quality.** Session records are generated by the LLM from conversation history. The quality of compression depends on the model's ability to extract relevant facts and summarize accurately. Weak models may produce low-signal summaries. Best results are achieved with capable models (Claude Sonnet or equivalent).

**No Real-Time Sync.** Multiple operators working in the same workspace must coordinate CACHE timing manually to avoid overwriting `last.json` or producing concurrent JSONL appends. ContextEngine does not implement file locking or merge conflict resolution. For single-operator workflows, this is not a concern.

**Single-Workspace Scope.** Cross-workspace memory retrieval is not supported. If a team needs shared memory across workspaces, the current approach requires manual export and import of session records.

**Context Window Constraints.** REPORT mode reads the full `master.jsonl` index. For workspaces with hundreds of sessions, this may approach context window limits. The recommended mitigation is date-range filtering to keep report inputs manageable. Long-term, chunked report generation (month-by-month synthesis) is a planned feature.

---

## 11. Roadmap

| Feature | NPAO Class | Status |
|---|---|---|
| Core CACHE / RETRIEVE / REPORT / QUERY / SCHEDULE | N — Necessity | ✅ Complete |
| CONTEXT.md format and schema | N — Necessity | ✅ Complete |
| Schedule skill integration | P — Priority | ✅ Complete |
| Chunked report generation (large indexes) | P — Priority | Planned |
| Agent-to-agent context handoff protocol | P — Priority | Planned |
| Optional vector search upgrade path | O — Opportunity | Planned |
| Multi-workspace cross-index QUERY | O — Opportunity | Planned |
| Web UI for CONTEXT.md and reports | O — Opportunity | Planned |
| Git-native diff view for session changes | O — Opportunity | Planned |

---

## 12. Conclusion

ContextEngine solves the cold-start problem for LLM-native workspaces. By introducing a structured, flat-file, LLM-operated memory layer, it eliminates the reconstruction tax, indexes failures for future reference, and provides durable project state that persists across sessions, operators, and agents.

Its design is intentionally simple: no infrastructure, no external dependencies, no black-box retrieval. Every file it produces is human-readable. Every operation is predictable. The complexity lives in the structure, not the technology.

Within the ROSTR framework, ContextEngine completes the memory picture: PAL gives agents compiled behavior, NPAO gives them task discipline, RAG DAL gives them external knowledge, ROSTR Hub gives them runtime coordination, and ContextEngine gives them history. Together, these layers produce agent systems that don't just execute tasks — they learn from prior work and carry that learning forward.

The implementation is a single SKILL.md file. The impact is the difference between agents that start fresh every time and agents that know where they left off.

---

## Appendix A: Quick Reference

| User says... | Mode triggered |
|---|---|
| "save this session" / "cache what we did" | CACHE |
| "context flash" / "what did we work on" | RETRIEVE |
| "generate a report" / "progress report" | REPORT |
| "find when we fixed X" / "search sessions for..." | QUERY |
| "schedule weekly report" | SCHEDULE |

---

## Appendix B: Session Record Schema (Full)

```json
{
  "session_id": "YYYYMMDD_HHMMSS",
  "date": "ISO 8601 timestamp",
  "project": "project or workspace name",
  "duration_estimate": "short | medium | long",
  "summary": "2-3 sentence narrative of what happened",
  "tools_used": ["bash", "edit", "write"],
  "files_created": [],
  "files_modified": [],
  "skills_invoked": [],
  "what_worked": ["bullet list of wins"],
  "what_failed": ["bullet list of failures with specifics"],
  "decisions_made": ["key choices and rationale"],
  "open_questions": ["unresolved items"],
  "next_steps": ["recommended next actions"],
  "tags": ["lowercase reusable topic tags"],
  "blockers": ["active constraints preventing progress"]
}
```

---

## Appendix C: ROSTR Integration Reference

```
ROSTR Layer    →  ContextEngine Role
─────────────────────────────────────────────────────────────────
PAL            →  Records agent spec versions and runtime performance
NPAO           →  Logs task classifications and completion status
RAG DAL        →  Captures retrieval outcomes and source credibility
ROSTR Hub      →  Complements runtime state with cross-session history
ContextEngine  →  Owns cross-session persistence for all other layers
```

---

*ContextEngine is a component of the ROSTR open-source agent framework.*
*Apache 2.0 — Built by Atlas HXM AI & Automation — April 2026*

# ROSTR: A Production-Grade Open-Source Agent Architecture

**Authors:** Atlas HXM AI & Automation
**Version:** 1.0
**Date:** April 2026
**Status:** Open Source (Apache 2.0)

---

## Abstract

ROSTR is an open-source agent architecture designed to eliminate fragmentation in multi-agent systems. It unifies five foundational layers — PAL (Prompt Abstraction Layer), NPAO (Necessity/Priority/Anxiety/Opportunity task classification), RAG DAL (retrieval abstraction), ContextEngine (persistent session memory), and ROSTR Hub (runtime orchestration) — into one coherent framework that teams can deploy, extend, and scale. ROSTR introduces phase discipline to agent behavior, compilation-based prompt management, unified data retrieval, durable cross-session memory, and scope-configurable state coordination. The framework is designed for teams of any size to build production-grade agent systems without rebuilding infrastructure.

---

## 1. The Problem: Agent Teams Without Infrastructure

Current agent frameworks solve individual problems well—LangChain handles tool orchestration, LlamaIndex optimizes retrieval, AutoGPT provides autonomous loops—but they fail to address the systemic challenges teams face when deploying multiple agents at scale:

**Fragile Prompt Management.** Agent behavior is encoded in free-form text prompts. Changes ripple unpredictably. There is no build-time validation, no versioning, no abstraction layer between intent and execution. Prompts are treated as glue code, not first-class artifacts.

**No Phase Discipline.** Agents lack awareness of where they are in a process. An agent might attempt deployment before design is complete, or debug before development. Process discipline is left to external orchestration or manual oversight, creating brittleness.

**Retrieval Chaos.** Every agent reimplements data fetching logic. One agent queries a vector DB, another hits an API, a third calls a CRM SDK. Results come back in different formats. Normalization and re-ranking happen ad hoc. There is no unified contract for "give me relevant context."

**State and Coordination Fragmented.** Agents maintain local state or rely on brittle shared databases. Multi-agent workflows have no standard way to propagate decisions, share context, or coordinate handoffs. Each team reimplements this infrastructure.

**Lack of Scoping and Isolation.** Are agents scoped to a project, team, org, or time box? This decision is made inconsistently. One agent sees all org data; another is project-local. There is no standard model for isolation, permission boundaries, or scope inheritance.

ROSTR solves these problems by providing:
- A **compiler** that turns agent specs into deployable runtimes (PAL)
- A **phase engine** that enforces process discipline (NPAO + 4Ds)
- A **retrieval bus** that abstracts all data sources (RAG DAL)
- A **memory layer** that persists session knowledge across conversations (ContextEngine)
- A **hub and runtime** that coordinates state, tools, and orchestration signals (ROSTR)

---

## 2. Framework Overview

ROSTR is composed of five integrated layers:

```
┌──────────────────────────────────────────────────────────────┐
│                    Agent Application Layer                    │
│         (Agent Specs, Workflows, User Interactions)           │
└────────────────────┬─────────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────────┐
│  PAL (Prompt Abstraction Layer)                              │
│  • Declarative agent specs → compiled runtimes               │
│  • System prompts, tool bindings, memory, output schema      │
│  • Build-time validation and versioning                      │
└────────────────────┬─────────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────────┐
│  NPAO + 4Ds (Phase-Aware Prioritization & Lifecycle)         │
│  • PreD → D1 Design → D2 Develop → D3 Deploy → D4 Debug      │
│  • Phase-gated task routing and priority sequencing          │
│  • Prevents out-of-phase execution                           │
└────────────────────┬─────────────────────────────────────────┘
                     │
        ┌──────────┬──────────┬──────────┐
        │          │          │          │
┌───────▼──────┐ ┌─▼────────┐ ┌─▼───────────────┐
│  RAG DAL     │ │ContextEng│ │  ROSTR Hub      │
│  Retrieval   │ │  Memory  │ │  Orchestrator   │
│  Bus         │ │  Layer   │ │  • Runtime      │
│  • Web srch  │ │  • CACHE │ │  • State mgmt   │
│  • Vector DB │ │  • RETRV │ │  • Tool reg.    │
│  • CRM/APIs  │ │  • REPORT│ │  • Signals      │
│  • Files     │ │  • QUERY │ │  • Reference    │
│  Unified I/O │ │  • SCHED │ │  • Scoping      │
└──────────────┘ └──────────┘ └─────────────────┘
        ▲               ▲              ▲
        └───────────────┴──────────────┘
                        │
            ┌───────────▼────────────┐
            │  Tool + State + Memory │
            │  APIs (Agents Query)   │
            └────────────────────────┘
```

**Data Flow:**
1. An agent spec is written in ROSTR DSL and compiled by PAL into a runtime (system prompt, tools, memory).
2. At runtime, NPAO classifies tasks (N→A→P→O) and evaluates 4Ds phase to determine execution order.
3. The agent starts by querying ContextEngine — loading prior session context, known failures, and open next steps.
4. The agent executes, calling RAG DAL for external knowledge and ROSTR Hub for orchestration signals.
5. On completion, the agent writes a session record to ContextEngine — decisions, results, failures, and next steps.
6. All state is persisted in the Hub and ContextEngine, scoped and indexed for re-use by other agents or future runs.

---

## 3. Layer 1: PAL — The Agent Compiler

**Purpose:** Transform declarative agent specifications into deployable runtimes.

**Problem PAL Solves:**
- Agent behavior is scattered across free-form prompts, tool definitions, memory configs, and output schemas.
- Changes to a single agent affect downstream consumers unpredictably.
- There is no versioning, no validation, no separation of intent from implementation.

**How PAL Works:**

PAL is a compilation pipeline that takes a structured agent spec and outputs:
- A resolved system prompt (hardened, validated)
- A tool binding manifest (statically typed, with guards)
- A memory configuration (what to remember, what to forget)
- An output schema (structured, JSON Schema compliant)
- A version hash (reproducible builds)

**PAL Agent Spec (ROSTR DSL):**
```yaml
agent:
  name: "Prospect Research Agent"
  version: "1.0"
  phase: "PreD"  # phase-aware

  objective: |
    Research a prospect company and synthesize insights into a
    structured brief suitable for outreach.

  inputs:
    - company_name: string
    - additional_context: string (optional)

  outputs:
    type: object
    properties:
      company_overview: string
      market_position: string
      hiring_signals: array
      outreach_angle: string
      confidence_score: number
    required: [company_overview, outreach_angle]

  tools:
    - rag_dal.search_web
    - rag_dal.query_crm
    - rag_dal.query_vector_store
    - rostr_hub.get_reference

  memory:
    type: "short_term"
    ttl_minutes: 60
    retain_fields: [research_summary, key_insights]

  guardrails:
    - max_tool_calls: 15
    - timeout_seconds: 300
    - allow_failure_modes: ["timeout", "rate_limit"]
```

**PAL Compilation Output:**
```json
{
  "agent_id": "prospect-research-v1.0-abc123",
  "compiled_system_prompt": "You are a prospect research assistant...",
  "tool_bindings": [
    {
      "name": "search_web",
      "tool_id": "rag_dal:web_search:v1",
      "schema": {...},
      "guards": {...}
    }
  ],
  "memory_config": {
    "backend": "redis",
    "ttl": 3600,
    "namespace": "prospect-research-v1"
  },
  "output_schema": {...},
  "version_hash": "abc123",
  "deployed_at": "2026-04-10T14:23:00Z"
}
```

**Key Innovations:**
- **Declarative Intent:** Write what you want, not how to code it.
- **Build-Time Validation:** Catch schema mismatches and tool incompatibilities before deployment.
- **Versioning and Reproducibility:** Every compile produces a hash; roll back or A/B test versions.
- **Tool Abstraction:** Agents declare intent (e.g., "search web"), not tool names. PAL resolves to the correct tool binding.
- **Memory Policies:** Define what to remember and for how long, decoupled from agent logic.

---

## 4. Layer 2: NPAO + The 4Ds — The Phase Engine

**Purpose:** Enforce process discipline and prevent out-of-phase execution.

### 4A. The 4Ds Framework: A Standalone Development Lifecycle

The **4Ds** is a general-purpose AI development and deployment lifecycle that can be adopted independently or as part of NPAO:

| Phase | Name | Duration | Activities | Agents Allowed |
|-------|------|----------|-----------|-----------------|
| **PreD** | Drafting | Variable | Research, requirements gathering, prototype ideation, validation of assumptions, user testing | Research agents, planning agents |
| **D1** | Design | 1-2 weeks | Detailed spec writing, architecture, data model design, API contracts | Design agents, spec writers |
| **D2** | Develop | 2-4 weeks | Code, prompt refinement, integration, unit testing, documentation | Dev agents, test agents |
| **D3** | Deploy | 1 week | Canary release, monitoring setup, gradual rollout, health checks | Deployment agents, monitoring agents |
| **D4** | Debug | Ongoing | Monitor, observe, fix bugs, optimize performance, handle edge cases | Debug agents, observability agents |

The 4Ds is **cyclical and iterative**, not waterfall. A single feature or agent might cycle through 4Ds multiple times. A bug found in D4 triggers a new PreD → D1 → D2 cycle.

**Why 4Ds Matters:**
- Agents and systems have different capabilities depending on phase maturity.
- A research agent in PreD is exploratory; the same agent in D3 must be deterministic and auditable.
- Mixing phases (e.g., deploying before design is complete) causes production incidents.
- 4Ds provides a shared mental model and language across teams.

### 4B. NPAO: Necessity · Priority · Anxiety · Opportunity

NPAO is a human-aligned task classification system that determines what agents should work on and in what order. It maps directly onto the 4Ds lifecycle.

**The Four Classes:**

| Class | Meaning | Execute when |
|-------|---------|--------------|
| **N** Necessity | "I MUST" — hard blocker; nothing downstream works without it | First, always |
| **A** Anxiety | "I WON'T HAVE PEACE" — persistent friction, cognitive overhead, unresolved loop | Second — clear before Priority work |
| **P** Priority | "I NEED" — mission-critical, advances the objective | Third — with full focus |
| **O** Opportunity | "I CAN" — growth, compounding, optional upside | Last — when bandwidth allows |

**Execution Order: N → A → P → O**

> Anxiety before Priority. Unresolved anxiety loops degrade execution quality on Priority tasks. Clear blockers and friction first — then execute what matters most.

```
┌──────────────────────┐
│  N — Necessity       │ Hard blockers. Nothing downstream works without this.
│  "I MUST"            │ Execute first. No exceptions.
└──────┬───────────────┘
       │
┌──────▼───────────────┐
│  A — Anxiety         │ Persistent friction. Cognitive overhead.
│  "I WON'T HAVE PEACE"│ Clear before starting Priority work.
└──────┬───────────────┘
       │
┌──────▼───────────────┐
│  P — Priority        │ Mission-critical tasks.
│  "I NEED"            │ Advances the objective. Execute with full focus.
└──────┬───────────────┘
       │
┌──────▼───────────────┐
│  O — Opportunity     │ Growth, compounding, optional upside.
│  "I CAN"             │ Execute when bandwidth allows.
└──────────────────────┘
```

**NPAO × 4Ds Mapping:**

| 4Ds Phase | NPAO Class | What This Means |
|-----------|-----------|-----------------|
| PreD (Drafting) | N | Research + validation blocks everything — do it first |
| D1 (Design) | P | Architecture choices are critical but not panic-level |
| D2 (Develop) | P + A | Build fast; clear blockers in parallel |
| D3 (Deploy) | N | Release is a hard gate — nothing ships without it |
| D4 (Debug) | A + O | Fix what's broken; optimize when stable |

**Example: Prospect Research Workflow**

1. **Necessity:** The agent's web search credentials are expired — nothing works without fixing this. Fix first.
2. **Anxiety:** A half-finished competitor list from last session is creating decision paralysis. Complete it or discard it.
3. **Priority:** Run the prospect research agent for target accounts — this is the actual mission.
4. **Opportunity:** While running, opportunistically enrich company records with LinkedIn data if the API is available.

**Phase-Aware Guardrails:**
- PreD agents can be exploratory, call external APIs, iterate prompts freely.
- D1 agents must produce versioned specs and validate against requirements.
- D2 agents must pass unit tests and integration checks.
- D3 agents must be production-hardened, with monitoring and rollback.
- D4 agents must preserve audit trails and never auto-fix without human approval.

---

## 5. Layer 3: RAG DAL — The Retrieval Bus

**Purpose:** Abstract all data sources behind a unified retrieval interface.

**Problem RAG DAL Solves:**
- Every agent reimplements "get relevant context."
- Web search, vector DB, CRM API, and file parsing use different contracts.
- Results come back in different schemas, requiring agent-specific normalization.
- No unified re-ranking or result deduplication.

**How RAG DAL Works:**

RAG DAL exposes a single query interface that agents use:

```typescript
interface RAGDALQuery {
  intent: string;                // "Find companies hiring in EMEA"
  sources: string[];             // ["web_search", "crm", "vector_store"]
  filters?: {
    time_range?: [Date, Date];
    entity_type?: string;
    confidence_threshold?: number;
  };
  max_results?: number;           // default 5
  return_schema?: JSONSchema;     // optional: auto-normalize to this
}

interface RAGDALResult {
  id: string;
  source: string;                 // "web_search" | "crm" | "vector_store" | ...
  content: string;
  metadata: Record<string, any>;
  confidence: number;             // 0-1
  retrieved_at: Date;
  lineage: {                       // for auditability
    query: string;
    method: string;
    raw_result: any;
  };
}

async function query(q: RAGDALQuery): Promise<RAGDALResult[]>
```

**RAG DAL Source Adapters:**

| Source | Adapter | Responsibility |
|--------|---------|-----------------|
| Web Search | `rag_dal.web_search` | Query search API, parse results, extract entity, normalize |
| Vector Store | `rag_dal.vector_search` | Embed query, search DB, re-rank by relevance |
| CRM | `rag_dal.crm_query` | Build query for Salesforce/HubSpot, normalize fields |
| Files | `rag_dal.file_search` | Index/search uploaded docs, extract relevant sections |
| APIs | `rag_dal.api_call` | Execute authenticated API call, parse response |
| Knowledge Base | `rag_dal.knowledge_base` | Query internal wiki, docs, or FAQs |

Each adapter:
- Converts intent into adapter-specific query syntax.
- Normalizes results to standard `RAGDALResult` schema.
- Handles rate limiting and retries transparently.
- Logs retrieval for audit and optimization.

**Example: Multi-Source Query**

Agent intent: "Find recent news about Acme Corp and their hiring posture."

```python
results = await rag_dal.query(
  intent="recent news about Acme Corp hiring",
  sources=["web_search", "crm"],
  filters={"time_range": [today - 30 days, today]},
  max_results=5
)

# RAG DAL:
# 1. Routes to web_search adapter + crm adapter in parallel
# 2. web_search returns 3 news articles, normalized
# 3. crm returns 2 account records, normalized
# 4. Re-ranks all 5 by relevance to agent's intent
# 5. Returns top 5 in uniform schema
```

**Key Innovations:**
- **Intent-Driven Routing:** Agents specify what they need, not which tool to call.
- **Transparent Multi-Source Querying:** Parallelize, deduplicate, re-rank across sources.
- **Unified Schema:** Every result is `RAGDALResult`, regardless of source.
- **Lineage and Auditability:** Every result carries its derivation path for debugging and compliance.
- **Adaptive Ranking:** Re-rank results based on agent context and historical feedback.

---

## 6. Layer 4: ROSTR Hub — The Orchestration Center

**Purpose:** Provide shared runtime, state management, tool registry, orchestration signals, and scope-configurable access to reference knowledge.

**ROSTR Hub Components:**

### 6A. Runtime Layer
- Agent lifecycle management (startup, shutdown, restart)
- Heartbeat and health monitoring
- Resource allocation and load balancing
- Error handling and recovery (retry, fallback, circuit breaker)

### 6B. State and Memory
- **Agent State:** Each agent's current task, priority, decision log.
- **Shared State:** Cross-agent decisions, team-wide context.
- **Lineage Tracking:** Full audit trail of who did what and why.
- **TTL and Retention:** Configurable lifecycle (when to flush old state).

Example state document:
```json
{
  "agent_id": "prospect-research-v1",
  "run_id": "run-20260410-001",
  "phase": "PreD",
  "task": "Research Acme Corp",
  "status": "in_progress",
  "decisions": [
    {
      "timestamp": "2026-04-10T14:23:00Z",
      "decision": "Query web for Acme Corp news",
      "rationale": "Need recent market context",
      "result": "Found 3 relevant articles"
    }
  ],
  "shared_context": {
    "target_company": "Acme Corp",
    "industry": "Manufacturing",
    "region": "EMEA"
  },
  "lineage": {
    "initiated_by": "user:pdiamitani@atlashxm.com",
    "initiated_at": "2026-04-10T14:22:00Z",
    "input_hash": "abc123"
  }
}
```

### 6C. Tool Registry
Central registry of all available tools. Agents don't need to know implementation details; they request tools by capability.

```json
{
  "tool_id": "rag_dal:web_search:v1",
  "capability": "web_search",
  "owner": "rag_dal",
  "rate_limit": 100,
  "cost_per_call": 0.01,
  "latency_sla_ms": 5000,
  "availability": 0.99,
  "schema": {...}
}
```

### 6D. Orchestration Signals
Real-time signals that coordinate multi-agent workflows:

| Signal | Purpose |
|--------|---------|
| `phase_changed` | Current phase has progressed; re-evaluate priorities. |
| `task_blocked` | Agent is blocked; escalate or route to another agent. |
| `dependency_met` | Upstream task completed; downstream task can proceed. |
| `budget_exceeded` | Cost or time budget exceeded; halt or defer task. |
| `pattern_detected` | Behavioral pattern detected (anomaly, inefficiency); notify. |

### 6E. Reference Layer
Organization-wide knowledge and policies accessible to all agents:

- **Company playbooks:** Sales playbooks, onboarding docs, brand guidelines.
- **Domain knowledge:** Competitor data, market research, product specs.
- **Policies:** Data access policies, approval workflows, compliance rules.
- **Cached results:** Previous research, similar analyses, reusable outputs.

Reference is scoped (see below) and versioned.

### 6F. Scope and Isolation

ROSTR Hub operates at one of four scopes:

| Scope | Definition | Use Case |
|-------|-----------|----------|
| **Project** | Single project (e.g., "Build Prospect Agent") | Isolated agent teams |
| **Team** | One team (e.g., "Sales Development") | Team-wide state, shared tools |
| **Organization** | Entire company | Org-wide policies, reference, analytics |
| **Time-Box** | Temporary context (e.g., "Q2 Planning Sprint") | Temporary project, ephemeral state |

Scopes nest: a project-scoped Hub can inherit org-level reference and policies.

```
┌─────────────────────────────────────┐
│  Organization Scope                 │
│  • Policies                          │
│  • Competitor data                   │
│  • Brand guidelines                  │
│                                      │
│  ┌──────────────────────────┐        │
│  │ Team: Sales Dev          │        │
│  │ • Shared state           │        │
│  │ • Playbooks              │        │
│  │                          │        │
│  │ ┌──────────────┐         │        │
│  │ │ Project: Q2  │         │        │
│  │ │ Prospect Seq │         │        │
│  │ │ • Agent state│         │        │
│  │ │ • Local data │         │        │
│  │ └──────────────┘         │        │
│  │                          │        │
│  │ ┌──────────────┐         │        │
│  │ │ Project: Q3  │         │        │
│  │ │ ABM Campaign │         │        │
│  │ └──────────────┘         │        │
│  └──────────────────────────┘        │
│                                      │
│  ┌──────────────────────────┐        │
│  │ Team: Marketing          │        │
│  │ • Shared state           │        │
│  │ • Content playbooks      │        │
│  └──────────────────────────┘        │
│                                      │
└─────────────────────────────────────┘
```

---

## 7. How They Work Together: End-to-End Example

**Scenario:** Build a Prospect Research Agent for Atlas HXM's GTM team.

### Step 1: Author and Compile (PAL)

GTM team lead writes a spec in ROSTR DSL:

```yaml
agent:
  name: "Prospect Research Agent"
  phase: "PreD"
  objective: "Research a prospect company and generate outreach brief"
  inputs:
    - company_name: string
  outputs:
    type: object
    properties:
      brief: string
      hiring_signals: array
      outreach_angle: string
```

PAL compiles this into:
- System prompt: "You are a prospect researcher for Atlas HXM. Your job is to..."
- Tool bindings: `rag_dal.web_search`, `rag_dal.crm_query`, `rostr_hub.get_reference`
- Memory: 60-minute TTL, store research summaries
- Output schema: Validates brief, hiring_signals, outreach_angle
- Version hash: `prospect-research-v1-abc123`

### Step 2: Deploy and Register (ROSTR Hub)

Deploy agent to ROSTR Hub:
```bash
rostr deploy prospect-research-v1-abc123 \
  --scope=team:sales-dev \
  --phase=PreD
```

ROSTR Hub:
- Creates agent runtime in team scope
- Registers tools in tool registry
- Initializes state store
- Listens for phase changes

### Step 3: Trigger Execution (NPAO)

GTM team lead initiates: "Research Acme Corp."

NPAO loop:
1. **Necessity check:** No hard blockers — credentials valid, tools registered. Proceed.
2. **Anxiety check:** No unresolved loops or blocking friction. Proceed.
3. **Priority:** "Research Acme Corp" is high-value, phase-aligned (PreD). Routes to Prospect Research Agent.
4. **Opportunity:** While executing, opportunistically enrich CRM with any new contact data found.

> NPAO execution order: N → A → P → O. Anxiety is cleared before Priority work begins — unresolved friction degrades execution quality.

### Step 4: Agent Execution (PAL Runtime + RAG DAL)

Agent wakes up with compiled runtime. It needs context on Acme Corp.

Agent queries RAG DAL:
```
intent: "Find recent news and market position for Acme Corp"
sources: ["web_search", "crm"]
max_results: 5
```

RAG DAL:
- Spawns web_search adapter: searches for "Acme Corp news, hiring, earnings"
- Spawns crm adapter: queries CRM for existing Acme contact, account history
- Normalizes both result sets
- Re-ranks by relevance
- Returns 5 `RAGDALResult` objects to agent

### Step 5: Synthesis and Decision Logging (ROSTR Hub State)

Agent synthesizes results:
- Acme Corp raised $50M Series B (web result)
- Expanding EMEA headcount (CRM note)
- Currently using competitor X's EOR solution (market intel)

Agent writes decision to ROSTR Hub:
```json
{
  "run_id": "run-20260410-acme",
  "decision": {
    "timestamp": "2026-04-10T14:30:00Z",
    "finding": "Acme Corp is in expansion phase, hiring globally",
    "confidence": 0.92,
    "sources": ["web_search", "crm"],
    "reasoning": "Recent funding + headcount growth + competitor usage"
  }
}
```

ROSTR Hub stores this decision with full lineage. Other agents can later query: "What do we know about Acme?" and get instant access without re-searching.

### Step 6: Output and Handoff

Agent returns structured brief:
```json
{
  "brief": "Acme Corp is a mid-market manufacturing company that recently raised $50M Series B and is expanding globally, particularly in EMEA. They are actively hiring across engineering and operations.",
  "hiring_signals": ["Series B funding", "EMEA expansion", "New roles posted on LinkedIn"],
  "outreach_angle": "Help them accelerate global hiring with compliant EOR solutions. Position Atlas's direct EOR model and speed-to-hire."
}
```

Brief is stored in team scope of ROSTR Hub. Sales Development team can now:
- Access brief via UI
- Share brief with outreach team
- Trigger follow-up agents (email writer, call prep, etc.)

### Step 7: Phase Progression and Iteration

As project moves from PreD → D1, NPAO detects phase change:
- Signals agents to shift behavior (research → design)
- Deprioritizes exploratory tasks
- Enables design-phase agents (spec writers, architects)
- Previous research from ROSTR Hub informs design decisions

---

## 8. The 4Ds Framework as a Standalone Standard

The **4Ds** deserves recognition as a general-purpose AI development and operational lifecycle, independent of ROSTR. Any team building AI systems can adopt 4Ds:

### 4Ds Principles:

1. **PreD (Drafting):** Everything before "go." Research, validate assumptions, define requirements, gather user feedback, prototype. Success = clear, validated requirements.

2. **D1 (Design):** Architecture and specification. System design, data model, API contracts, behavior spec, success metrics. Success = signed-off design doc.

3. **D2 (Develop):** Implementation, testing, integration. Code, prompts, test coverage, documentation. Success = passing tests, code review approved.

4. **D3 (Deploy):** Release to production. Canary release, monitoring, gradual rollout, health checks, comms. Success = live and stable.

5. **D4 (Debug):** Operate and improve. Monitor, observe, fix bugs, optimize, handle edge cases. May trigger new PreD cycles for improvements.

### Why Adopt 4Ds:

- **Universal Language:** Every team member knows what "D2" means.
- **Phase-Aware Tooling:** Tools and agents can adapt behavior based on phase.
- **Prevents Mixing:** Avoids disasters like "deploying before design" or "optimizing before testing."
- **Iterative:** Cycles repeat. A bug in D4 starts a new PreD → D1 → D2 cycle.
- **Measurement:** Define success criteria for each phase; track progress.

### 4Ds Applied to Agent Teams:

- **PreD:** Interview users, define agent capabilities, validate data sources.
- **D1:** Design agent spec, define tools, plan integration points.
- **D2:** Write and test prompts, integrate tools, build observability.
- **D3:** Deploy agent to staging, then production; monitor key metrics.
- **D4:** Monitor agent performance, fix edge cases, log decision quality.

---

## 9. DOE Alignment: Directives, Orchestration, Execution

ROSTR maps cleanly to Nick Saraev's DOE (Directives, Orchestration, Execution) framework:

| DOE Layer | ROSTR Component | Responsibility |
|-----------|-----------------|-----------------|
| **Directives** | PAL (prompt compilation) + ROSTR Reference layer | Define agent behavior, policies, org knowledge, decision rules. |
| **Orchestration** | NPAO (phase-aware routing) + ROSTR Orchestration signals | Route tasks, sequence work, enforce phase discipline, coordinate multi-agent workflows. |
| **Execution** | RAG DAL (retrieval) + ROSTR Tool layer + Runtime | Execute tasks, fetch data, call tools, produce outputs. |

**How they interact:**
1. Directives define the "what" (e.g., "prospect researcher should synthesize recent news and hiring signals").
2. Orchestration determines the "when" and "who" (e.g., "prospect research is a PreD task; assign to Research Agent").
3. Execution handles the "how" (agent retrieves data via RAG DAL, synthesizes via tools, stores decisions in Hub).

This separation of concerns makes systems more modular, testable, and auditable.

---

## 10. Open-Source Architecture: Repo Structure and Deployment

ROSTR is designed to be deployed, forked, and extended. Here's the proposed repo structure:

```
rostr/
├── README.md
├── LICENSE (Apache 2.0)
├── ARCHITECTURE.md
├── docs/
│   ├── quickstart.md
│   ├── deployment.md
│   ├── api-reference.md
│   ├── examples/
│   │   ├── prospect-research-agent/
│   │   ├── email-writer-agent/
│   │   └── multi-agent-workflow/
│   └── concepts/
│       ├── pal.md
│       ├── npao.md
│       ├── rag-dal.md
│       └── rostr-hub.md
├── packages/
│   ├── pal-compiler/
│   │   ├── src/
│   │   ├── tests/
│   │   └── README.md
│   ├── npao-orchestrator/
│   │   ├── src/
│   │   ├── tests/
│   │   └── README.md
│   ├── rag-dal/
│   │   ├── src/
│   │   │   ├── adapters/
│   │   │   │   ├── web_search.ts
│   │   │   │   ├── crm.ts
│   │   │   │   ├── vector_db.ts
│   │   │   │   └── ...
│   │   │   └── core/
│   │   ├── tests/
│   │   └── README.md
│   ├── rostr-hub/
│   │   ├── src/
│   │   │   ├── runtime/
│   │   │   ├── state/
│   │   │   ├── tools/
│   │   │   └── orchestration/
│   │   ├── tests/
│   │   └── README.md
│   └── shared/
│       ├── types.ts
│       ├── interfaces.ts
│       └── utils.ts
├── examples/
│   └── (complete end-to-end examples)
├── tests/
│   └── (integration and e2e tests)
└── scripts/
    ├── deploy.sh
    ├── test.sh
    └── build.sh
```

### Deployment Models

**Model 1: Single Developer / Small Team**
- Deploy ROSTR locally or on a single VM.
- PAL compiler runs on local machine or CI/CD.
- ROSTR Hub uses SQLite + Redis for state.
- RAG DAL uses public APIs (web search, etc.).
- Use case: Prototype, personal projects, small team automation.

**Model 2: Team Deployment**
- Deploy ROSTR to Docker container or K8s cluster.
- PAL compiler integrated into CI/CD (GitHub Actions, GitLab CI).
- ROSTR Hub uses PostgreSQL + Redis Cluster for state.
- RAG DAL configured with team's data sources (CRM, internal APIs).
- Scoped to team (sales team, marketing team, etc.).
- Use case: Team-wide agent deployment, shared tools and state.

**Model 3: Enterprise Org**
- Multi-tenant ROSTR deployment across org.
- PAL compiler as a service (compile endpoint).
- ROSTR Hub fully distributed (PostgreSQL + Redis Cluster, multiple regions).
- RAG DAL connected to all org data sources (multiple CRMs, data warehouses, etc.).
- Fine-grained scoping (org → team → project).
- RBAC and audit logging.
- Use case: Org-wide agent platform, cross-team coordination.

### Composability and Extension Points

ROSTR is designed for teams to extend:

1. **Custom RAG DAL Adapters:** Write a new adapter to connect a proprietary data source.
   ```python
   class CustomDataSourceAdapter(RAGDALAdapter):
       def query(self, intent: str, filters: dict) -> List[RAGDALResult]:
           # Custom logic to fetch and normalize
   ```

2. **Custom Tool Providers:** Extend tool registry with domain-specific tools.
   ```python
   rostr_hub.register_tool({
       "name": "analyze_deal",
       "capability": "deal_analysis",
       "fn": my_deal_analyzer
   })
   ```

3. **Custom Orchestration Signals:** Define new signals for your workflow.
   ```python
   orchestration.register_signal("budget_threshold_reached", handler=my_handler)
   ```

4. **Custom Scoping Models:** Extend beyond project/team/org/time-box scopes.
   ```python
   hub.add_scope_type("campaign", parent_scope="team")
   ```

---

## 11. Comparison to Existing Frameworks

| Framework | Strength | ROSTR Advantage |
|-----------|----------|-----------------|
| **LangChain** | Tool orchestration, chain composability | PAL abstracts prompts; NPAO enforces phase discipline; RAG DAL unifies retrieval |
| **LlamaIndex** | RAG and vector DB optimization | RAG DAL handles multi-source retrieval at scale; adapters for any source |
| **AutoGPT** | Autonomous agent loops | NPAO phase gating prevents out-of-phase errors; better for team workflows |
| **CrewAI** | Multi-agent coordination | ROSTR Hub is stronger at state management and scoping; better for org-wide systems |
| **Mem0 / Zep** | Agent memory persistence | ContextEngine is flat-file, zero-infrastructure, session-structured; no vector DB required |
| **Hugging Face / Transformers** | Model and inference | ROSTR sits above the model layer; agnostic to LLM provider |

**ROSTR's Differentiators:**
1. **Phase-Aware Execution:** No other framework enforces the 4Ds.
2. **Human-Aligned Prioritization:** NPAO's N→A→P→O order mirrors how high-performers actually triage work. Agents that prioritize like humans earn trust faster.
3. **Prompt Compilation:** PAL is unique; transforms declarative intent to versioned, reproducible runtime.
4. **Unified Retrieval:** RAG DAL abstracts all data sources behind one contract with 3-tier credibility weighting.
5. **Zero-Infrastructure Memory:** ContextEngine gives every agent team persistent cross-session memory with no external services — flat files, instant load, searchable history.
6. **Hub and Scoping:** ROSTR Hub's scope-configurable state and reference layer is unique.
7. **Production-Grade:** Built for teams, not just individuals.

---

## 12. Deployment Scenarios

### Scenario A: Individual Developer

**Setup:**
- Clone ROSTR repo.
- Install: `npm install rostr`
- PAL: runs locally on `rostr compile spec.yaml`
- ROSTR Hub: SQLite + in-memory state
- RAG DAL: public web search + file uploads

**Workflow:**
```bash
# Write spec
echo "agent:
  name: Email Writer
  ..." > email_writer.yaml

# Compile
rostr compile email_writer.yaml --output runtime.json

# Test locally
rostr run runtime.json --input "subject:..."
```

**Cost:** Free (open source). Compute: local machine.

---

### Scenario B: Small Sales Team (5-10 reps)

**Setup:**
- Deploy ROSTR to Docker on a $20/mo VM.
- PostgreSQL for state (managed service).
- Redis for caching.
- PAL compiled in CI/CD (GitHub Actions).
- RAG DAL connected to: web search API, HubSpot, internal Google Drive.

**Workflow:**
1. Sales Manager defines agents in ROSTR DSL (prospect researcher, email writer, call prep).
2. CI/CD compiles agents, deploys to running ROSTR Hub.
3. Reps use agents via web UI or Slack bot integration.
4. State is shared across reps; decisions and research are reused.

**Tools:**
- Prospect Research Agent (PreD)
- Outreach Email Writer (D2)
- Call Prep Brief (D2)
- CRM Note Summarizer (D4)

**Cost:** ~$150/month (compute + DB).

---

### Scenario C: Enterprise (500+ employees, 50+ agents)

**Setup:**
- Kubernetes deployment (AWS/GCP/Azure).
- Multi-region, high-availability ROSTR Hub.
- PostgreSQL RDS, Redis Cluster.
- PAL as a service endpoint.
- RAG DAL connected to: web search, Salesforce, HubSpot, data warehouse, internal wiki, vector DB.
- Fine-grained RBAC, audit logging.

**Workflow:**
1. Each team (Sales, Marketing, RevOps) owns its agent specs.
2. Compile and deploy via centralized platform.
3. Org-level policies and reference knowledge shared across all agents.
4. Analytics: track agent usage, costs, decision quality, ROI.

**Agents per team:**
- Sales: prospect research, outreach, call prep, objection handler (8 agents)
- Marketing: content brief, social post, campaign summarizer (5 agents)
- RevOps: pipeline reporter, forecast updater, CRM hygiene (4 agents)
- Cross-team: competitive intel, hiring signal detector, compliance checker (5 agents)

**Cost:** ~$10k-20k/month (compute, tools, licensing, support).

---

## 13. Conclusion and Roadmap

### Summary

ROSTR is a production-grade agent architecture that solves systemic problems in multi-agent systems:
- **PAL** compiles agent specs into deployable runtimes, eliminating prompt fragmentation.
- **NPAO + 4Ds** enforces phase discipline, preventing out-of-phase failures.
- **RAG DAL** abstracts retrieval, enabling agents to query any data source uniformly.
- **ROSTR Hub** coordinates state, tools, and signals across a team or org.

Together, these four layers enable teams of any size to build, deploy, and operate production-grade agent systems.

### What's Built (v1.0)

- PAL compiler (ROSTR DSL → runtime)
- NPAO orchestrator (phase routing and task prioritization)
- RAG DAL with adapters: web search, CRM, vector DB, files, APIs
- ROSTR Hub (state, tools, reference, orchestration)
- Docker and Kubernetes deployment templates
- Example agents: prospect research, email writer, call prep
- Web UI for agent management
- Slack integration

### What's Next (v1.1-v2.0)

**Near term (v1.1):**
- Multi-tenant support and stricter RBAC
- Advanced observability and tracing
- A/B testing framework for agent versions
- Cost tracking and budget controls

**Medium term (v1.2-v1.5):**
- Visual agent builder (no-code spec authoring)
- Integration marketplace (pre-built adapters and tools)
- Agent fine-tuning support (prompt optimization)
- Multi-modal agents (handle images, docs, etc.)

**Longer term (v2.0):**
- Agentic reasoning and self-improvement
- Cross-org federated deployments
- Real-time collaboration on agent workflows
- AI-powered agent monitoring and anomaly detection

### Call to Action

**ROSTR is open source (Apache 2.0) and ready for contribution.**

We are looking for:
- **Framework contributors:** Help build PAL, NPAO, RAG DAL, Hub components.
- **Adapter builders:** Write RAG DAL adapters for your data sources.
- **Integration partners:** Build plugins and extensions.
- **Early adopters:** Deploy ROSTR, give feedback, report issues.
- **Documentation and examples:** Help us build a vibrant community around agent architecture.

**To get started:**
1. Read the [Quickstart Guide](https://github.com/atlashxm/rostr/docs/quickstart.md)
2. Clone the repo: `git clone https://github.com/atlashxm/rostr.git`
3. Deploy locally: `rostr up`
4. Try an example: `rostr run examples/prospect-research/`
5. Join the community: GitHub Discussions, Discord

---

## Appendix: Glossary

| Term | Definition |
|------|-----------|
| **PAL** | Prompt Abstraction Layer. Compiles declarative agent specs into deployable runtimes. |
| **NPAO** | Necessity · Priority · Anxiety · Opportunity. Human-aligned task classification. Execution order: N→A→P→O (Anxiety before Priority — unresolved loops degrade execution quality). |
| **4Ds** | PreD (Drafting) → D1 (Design) → D2 (Develop) → D3 (Deploy) → D4 (Debug). A development lifecycle. |
| **RAG DAL** | Retrieval/Data Abstraction Layer. Unified interface for querying multiple data sources. |
| **ContextEngine** | Persistent session memory layer. ROSTR State Layer implementation. Five modes: CACHE, RETRIEVE, REPORT, QUERY, SCHEDULE. Zero-infrastructure flat-file storage in `.context-engine/`. |
| **ROSTR** | Runtime, Orchestration, State, Tools, Reference. The central hub coordinating agents. |
| **Agent Spec** | Declarative description of an agent's behavior (ROSTR DSL). |
| **Compiled Runtime** | Output of PAL; contains system prompt, tools, memory config, output schema. |
| **Scope** | Boundary for state and access (project, team, org, time-box). |
| **Phase** | Current stage of development (PreD, D1, D2, D3, D4). |
| **Lineage** | Full audit trail of decisions and their sources. |

---

**ROSTR Framework v1.0**
Open Source. Production Ready. Built for Teams.

For more information, visit: [https://github.com/atlashxm/rostr](https://github.com/atlashxm/rostr)


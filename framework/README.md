# ROSTR Framework — Open Source Agent Architecture

**Version:** 0.1 (Founding Draft)
**Author:** Patrick Diamitani — Atlas HXM GTM AI & Automation
**Date:** April 2026

---

## What Is This

ROSTR is a unified, open-source framework for building production-grade AI agent teams. It combines four purpose-built layers into one modular architecture that any team, org, or project can deploy.

---

## The Five Layers

| Layer | Full Name | Job |
|---|---|---|
| **PAL** | Prompt Abstraction Layer | Compiles declarative agent specs into deployment-ready runtimes |
| **NPAO** | Necessity · Priority · Anxiety · Opportunity | Human-aligned task classification + 4Ds lifecycle phase routing |
| **RAG DAL** | Retrieval / Data Abstraction Layer | Autonomous hierarchical retrieval across credibility-tiered sources |
| **ContextEngine** | Persistent Session Memory Layer | Flat-file, zero-infrastructure cross-session memory for agents and teams |
| **ROSTR** | Runtime · Orchestration · State · Tools · Reference | Central hub connecting all layers — the agent OS |

---

## White Papers

| Document | Description |
|---|---|
| [ROSTR_Framework_Combined_Whitepaper.md](./ROSTR_Framework_Combined_Whitepaper.md) | **START HERE** — Master paper covering the full unified framework, end-to-end example, OSS architecture, DOE alignment |
| [PAL_Whitepaper.md](./PAL_Whitepaper.md) | Prompt Abstraction Layer — 4-layer compiler: Intent → Composition → Optimization → Runtime |
| [NPAO_Whitepaper.md](./NPAO_Whitepaper.md) | NPAO — Necessity/Priority/Anxiety/Opportunity + the 4Ds lifecycle (PreD → D1 → D2 → D3 → D4) |
| [RAGDAL_Whitepaper.md](./RAGDAL_Whitepaper.md) | RAG DAL — 7-stage autonomous retrieval pipeline, 3-tier credibility model, self-improving KB |
| [ContextEngine_Whitepaper.md](./ContextEngine_Whitepaper.md) | ContextEngine — persistent session memory, ROSTR State Layer implementation |
| [ROSTR_Whitepaper.md](./ROSTR_Whitepaper.md) | ROSTR Hub — Runtime, Orchestration, State, Tools, Reference — the coordination center |

---

## The 4Ds Lifecycle (Standalone Framework)

| Phase | Name | NPAO Class | What Happens |
|---|---|---|---|
| **PreD** | Drafting | Necessity | Research, ideation, requirements, validation — before you build |
| **D1** | Design | Priority | Architecture, data models, system design, specs |
| **D2** | Develop | Priority + Anxiety | Build, implement, test; clear blockers in parallel |
| **D3** | Deploy | Necessity | Release, infrastructure, CI/CD |
| **D4** | Debug | Anxiety + Opportunity | Monitor, troubleshoot, optimize, iterate |

---

## NPAO Task Classification

> Execution order: **N → A → P → O**
> (Anxiety before Priority — unresolved loops degrade execution quality)

| Class | Means | Execute when |
|---|---|---|
| **N** Necessity | "I MUST" — hard blocker, nothing downstream works without it | First, always |
| **A** Anxiety | "I WON'T HAVE PEACE" — persistent friction, cognitive overhead | Second — clear before doing Priority work |
| **P** Priority | "I NEED" — mission-critical, moves the objective forward | Third — with full focus |
| **O** Opportunity | "I CAN" — growth, compounding, optional upside | Last — when bandwidth allows |

---

## ContextEngine — State Layer

| Mode | Trigger | Action |
|---|---|---|
| CACHE | "save this session" | Compress + write session record + update CONTEXT.md |
| RETRIEVE | "context flash" | Load last session + patterns + recommended next step |
| REPORT | "generate a report" | Synthesize all sessions into progress/troubleshooting doc |
| QUERY | "when did we fix X" | Search index by tag, tool, keyword, date |
| SCHEDULE | "weekly report Fridays" | Set up recurring report generation |

---

## DOE Alignment

| DOE Layer | ROSTR Mapping |
|---|---|
| Directives | PAL (runtime compilation) + Reference layer |
| Orchestration | NPAO (N→A→P→O classification) + Orchestration layer |
| Execution | RAG DAL + ContextEngine + Tools layer |

---

## Related Work
- Nick Saraev — DOE Framework (Directives, Orchestration, Execution)
- Claude Skills / Codex — skill-based agent composition
- Patrick Diamitani — NPAO Framework (original human task management system)

---

*Read the combined white paper first. Everything else is a deep-dive.*

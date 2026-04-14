#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ROSTR Framework — One-Step Installer
# Works in any Claude Code, Codex, OpenCode, or OpenClaw workspace
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/diamitani/rostr-paper/main/install.sh | bash
#
# Or clone and run:
#   bash install.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

ROSTR_VERSION="0.1"
GITHUB_RAW="https://raw.githubusercontent.com/diamitani/rostr-paper/main"
BOLD="\033[1m"
GREEN="\033[0;32m"
GOLD="\033[0;33m"
RESET="\033[0m"

echo ""
echo -e "${GOLD}${BOLD}ROSTR Framework Installer v${ROSTR_VERSION}${RESET}"
echo -e "${GOLD}Runtime · Orchestration · State · Tools · Reference${RESET}"
echo ""

# ── 1. Create ContextEngine skill ────────────────────────────────────────────
SKILL_DIR=".claude/skills/context-engine"
echo -e "→ Installing ContextEngine skill to ${SKILL_DIR}/"
mkdir -p "$SKILL_DIR"
curl -fsSL "${GITHUB_RAW}/skills/context-engine/SKILL.md" -o "${SKILL_DIR}/SKILL.md"
echo -e "  ${GREEN}✓ SKILL.md installed${RESET}"

# ── 2. Create .context-engine/ directory structure ───────────────────────────
echo "→ Creating .context-engine/ memory directory"
mkdir -p .context-engine/sessions .context-engine/index .context-engine/reports .context-engine/cache

# Create CONTEXT.md if it doesn't exist
if [ ! -f ".context-engine/CONTEXT.md" ]; then
cat > .context-engine/CONTEXT.md << 'CONTEXT'
# Project Context — Initialized by ROSTR Installer

## Current State
ROSTR framework installed. ContextEngine ready. Run "context flash" to load session history, or "save this session" at end of each session.

## What's Working
- ContextEngine skill installed at .claude/skills/context-engine/SKILL.md
- .context-engine/ directory structure created

## Active Blockers
(none)

## Open Next Steps
1. Start your first session and say "save this session" when done
2. Next session: say "context flash" to reload where you left off

## Recent Session Log
| Date | Summary | Result |
|------|---------|--------|
| Initialized | ROSTR installer run | ✅ |

## Tags in Use
rostr, context-engine
CONTEXT
echo -e "  ${GREEN}✓ CONTEXT.md initialized${RESET}"
fi

# ── 3. Create/update CLAUDE.md with ROSTR block ───────────────────────────────
echo "→ Adding ROSTR operating instructions to CLAUDE.md"

ROSTR_BLOCK='
## ROSTR Framework

This workspace runs the ROSTR agent operating system.
Docs: https://github.com/diamitani/rostr-paper

### Layers

| Layer | Role |
|---|---|
| **PAL** | Compiles your intent into precise agent instructions before executing |
| **NPAO** | Classifies every task as N (Necessity) · A (Anxiety) · P (Priority) · O (Opportunity) |
| **RAG DAL** | Multi-pass retrieval with credibility-tiered sources — never single-pass |
| **ContextEngine** | Persistent session memory — saves, retrieves, and reports across sessions |
| **ROSTR Hub** | Runtime coordination — state, tools, orchestration signals |

### NPAO Execution Order: N → A → P → O

- **N — Necessity** ("I MUST"): Hard blockers. Nothing works without this. Execute first.
- **A — Anxiety** ("I WON'"'"'T HAVE PEACE"): Cognitive friction. Clear before Priority work or it degrades execution.
- **P — Priority** ("I NEED"): Mission-critical forward motion. Execute with full focus.
- **O — Opportunity** ("I CAN"): Growth, upside, optional wins. Execute last.

### ContextEngine Commands

| Say... | Effect |
|---|---|
| "save this session" | CACHE — compress + persist current session |
| "context flash" | RETRIEVE — load last session + recommended next step |
| "generate a report" | REPORT — synthesize all sessions into progress doc |
| "find when we fixed X" | QUERY — search session history by tag/keyword |

### Operating Rules

1. Every task is NPAO-classified before execution
2. Anxiety blockers are cleared before Priority tasks begin
3. Save sessions at natural stopping points
4. PAL applies to all prompts — intent is extracted and enhanced before agent runs
5. Multi-pass retrieval only — no single-pass RAG
'

if [ -f "CLAUDE.md" ]; then
  if grep -q "ROSTR Framework" CLAUDE.md 2>/dev/null; then
    echo -e "  ${GREEN}✓ CLAUDE.md already has ROSTR block — skipping${RESET}"
  else
    echo "" >> CLAUDE.md
    echo "$ROSTR_BLOCK" >> CLAUDE.md
    echo -e "  ${GREEN}✓ ROSTR block appended to existing CLAUDE.md${RESET}"
  fi
else
  echo "# CLAUDE.md" > CLAUDE.md
  echo "" >> CLAUDE.md
  echo "$ROSTR_BLOCK" >> CLAUDE.md
  echo -e "  ${GREEN}✓ CLAUDE.md created with ROSTR block${RESET}"
fi

# ── 4. Download framework whitepapers (optional) ─────────────────────────────
read -p "→ Download framework whitepapers to ./framework/? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  mkdir -p framework
  FILES=(
    "framework/README.md"
    "framework/ROSTR_Framework_Combined_Whitepaper.md"
    "framework/PAL_Whitepaper.md"
    "framework/NPAO_Whitepaper.md"
    "framework/RAGDAL_Whitepaper.md"
    "framework/ContextEngine_Whitepaper.md"
    "framework/ROSTR_Whitepaper.md"
  )
  for f in "${FILES[@]}"; do
    filename=$(basename "$f")
    curl -fsSL "${GITHUB_RAW}/${f}" -o "framework/${filename}" 2>/dev/null && \
      echo -e "  ${GREEN}✓${RESET} ${filename}" || \
      echo -e "  ⚠ ${filename} (skipped)"
  done
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}ROSTR installed.${RESET}"
echo ""
echo "  Next steps:"
echo "  1. Start Claude Code (or your tool) in this workspace"
echo "  2. Say: \"context flash\" to load session history"
echo "  3. Say: \"save this session\" at end of each session"
echo ""
echo -e "  Paper: ${GOLD}https://diamitani.github.io/rostr-paper${RESET}"
echo -e "  Repo:  ${GOLD}https://github.com/diamitani/rostr-paper${RESET}"
echo ""

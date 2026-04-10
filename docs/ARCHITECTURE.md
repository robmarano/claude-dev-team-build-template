# Architecture Decisions

This document tracks architectural decisions made in this project. The `team-build` skill will naturally populate this as the PM agent makes high-level design choices during Phase 1.

## How to Use This Document

Each entry should capture:
- **Context** — what problem prompted the decision
- **Decision** — what was chosen
- **Consequences** — trade-offs, risks, and implications
- **Status** — proposed, accepted, deprecated, or superseded

---

## ADR-001: Using the team-build Skill for Feature Development

**Status:** Accepted
**Date:** Template initialization

### Context
This project is set up as a template for feature development using an integrated AI development team. Rather than building features as a single generalist agent, we want multiple specialized agents coordinating through a structured workflow.

### Decision
Use the `team-build` Claude Code skill, which orchestrates 8 specialized principal-level agents through a 5-phase workflow:
1. Product specification (PM)
2. Parallel implementation (2 Backend, 1 Frontend, 1 DevOps)
3. Cross-review (backend engineers review each other)
4. Quality assurance (test writer + test reviewer)
5. Business user acceptance testing

### Consequences
**Positive:**
- Specialized expertise per role produces higher-quality output in each domain
- Explicit phase handoffs enforce engineering rigor (specs before code, tests after code, UAT before "done")
- Parallel implementation in Phase 2 reduces wall-clock time
- Cross-review catches integration bugs and security issues
- UAT phase catches drift between user intent and implementation

**Negative:**
- Higher token cost per feature compared to single-agent development
- Not suitable for tiny changes (the overhead exceeds the benefit)
- Requires the orchestrator (main Claude) to correctly route context between phases

**Mitigations:**
- Use adaptive workflows for smaller tasks (see USER_GUIDE.md section 7)
- For trivial changes, bypass the skill and use single-agent flow

---

## ADR-NNN: [Template for future entries]

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXX
**Date:** YYYY-MM-DD

### Context
[What is the issue we're seeing that motivates this decision?]

### Decision
[What is the change we're actually proposing or doing?]

### Consequences
[What becomes easier or harder to do because of this change?]

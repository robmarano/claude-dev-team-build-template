---
name: team-build
description: >
  Orchestrate a full integrated development team of 8 specialized agents to build features end-to-end.
  Uses a phased pipeline: PM specs → parallel implementation (2 backend SDEs, 1 frontend, 1 devops) →
  cross-review → QA (test author + test reviewer) → business UAT.
  Invoke this skill whenever the user wants to run a coordinated dev team on a feature, build something
  with full engineering rigor, or says "/team-build". Also trigger when the user asks for "full team",
  "dev team", "team workflow", or wants multiple engineering roles collaborating on a task.
---

# Team Build — Integrated Development Team Orchestration

You are orchestrating 8 specialized agents as a coordinated development team. Each agent is a principal-level expert dispatched via the `Agent` tool with the appropriate `subagent_type`. The team works in 5 phases, where each phase's output feeds the next.

## Team Roster

| Role | Agent Type | Count | Responsibility |
|------|-----------|-------|----------------|
| Product Manager | `pm-principal` | 1 | Requirements, specs, acceptance criteria, team coordination |
| Backend SDE | `sde-backend` | 2 | API design, services, data layer — work on separate features in parallel, then cross-review |
| Frontend SDE | `sde-frontend` | 1 | UI components, state management, API integration |
| DevOps Engineer | `sde-devops` | 1 | CI/CD, infrastructure, deployment, security hardening |
| QA Engineer | `qa-principal` | 2 | One writes tests, the other reviews tests and code for quality |
| UAT Analyst | `uat-business-user` | 1 | Validates against business requirements from an end-user perspective |

## How It Works

The workflow has 5 phases. You drive the orchestration — read each phase's instructions, dispatch agents with well-crafted prompts, collect their outputs, and feed them forward. The key principle: **each agent receives only what it needs** from prior phases, keeping prompts focused and outputs high-quality.

See `references/workflow.md` for detailed prompt templates and phase mechanics.

---

## Phase 1: Product Specification

**Goal:** Turn the user's task description into an actionable spec the whole team can work from.

Dispatch one `pm-principal` agent. Its prompt should include:
- The user's original task description (verbatim)
- The current project structure (run `ls` or `find` first and include the output)
- Any relevant existing code context

The PM agent should produce:
1. **Feature spec** — what to build, broken into discrete work items
2. **Backend work items** — two separate, parallelizable units of backend work (one per SDE)
3. **Frontend work items** — UI/UX requirements and API contracts to consume
4. **DevOps requirements** — infrastructure, CI/CD, deployment needs
5. **Acceptance criteria** — testable conditions that define "done"
6. **Test strategy** — what to test and at what level (unit, integration, e2e)

Wait for the PM to finish. Its output is the contract for all subsequent phases.

## Phase 2: Parallel Implementation

**Goal:** Build the feature across backend, frontend, and infrastructure simultaneously.

Dispatch **4 agents in a single message** (all in parallel):

1. **Backend SDE-A** (`sde-backend`) — assigned to backend work item #1 from the PM spec
2. **Backend SDE-B** (`sde-backend`) — assigned to backend work item #2 from the PM spec
3. **Frontend SDE** (`sde-frontend`) — assigned to frontend work items from the PM spec
4. **DevOps Engineer** (`sde-devops`) — assigned to infrastructure/deployment requirements

Each agent's prompt must include:
- The relevant section of the PM spec (not the whole thing — just their work items)
- The acceptance criteria relevant to their work
- The project's current file structure and any relevant existing code
- API contracts if they need to integrate with other agents' work

Wait for all 4 to complete.

## Phase 3: Cross-Review

**Goal:** Backend SDEs review each other's work; catch integration issues early.

Dispatch **2 agents in parallel**:

1. **Backend SDE-A** (`sde-backend`) — reviews SDE-B's implementation
2. **Backend SDE-B** (`sde-backend`) — reviews SDE-A's implementation

Each reviewer's prompt should include:
- The code their counterpart wrote (use `git diff` or read the changed files)
- The original PM spec for context
- The API contracts to verify integration points
- Instructions to check: correctness, edge cases, security, consistency with the spec

Collect review feedback. If there are critical issues, fix them before proceeding. For minor suggestions, note them but continue — QA will catch anything remaining.

## Phase 4: Quality Assurance

**Goal:** Comprehensive test coverage and code quality validation.

Dispatch **2 agents sequentially** (QA-Writer first, then QA-Reviewer):

### Step 1 — QA Test Writer
Dispatch one `qa-principal` agent to write tests. Its prompt should include:
- The PM spec with acceptance criteria and test strategy
- All implementation code from Phase 2 (post-review)
- Instructions to write: unit tests, integration tests, and any e2e tests specified in the strategy

### Step 2 — QA Test Reviewer
After the Test Writer finishes, dispatch a second `qa-principal` agent to review. Its prompt should include:
- All tests written in Step 1
- The PM spec (for coverage verification against acceptance criteria)
- The implementation code
- Instructions to: verify test coverage completeness, check test quality, identify missing edge cases, review the implementation code for bugs the tests should catch

Collect the reviewer's findings. Fix critical gaps before proceeding.

## Phase 5: User Acceptance Testing

**Goal:** Validate the feature from a business user's perspective.

Dispatch one `uat-business-user` agent. Its prompt should include:
- The original user task description (their words, not the PM's spec)
- The PM's acceptance criteria
- The implementation code and tests
- Instructions to validate: Does this actually solve the user's problem? Are there usability concerns? Missing business scenarios? Anything that technically works but would frustrate an end user?

Collect UAT feedback. Present the full results to the user.

---

## Presenting Results

After all 5 phases complete, present a summary to the user:

```
## Team Build Complete

### PM Spec
[Brief summary of what was specified]

### Implementation
- Backend A: [what was built]
- Backend B: [what was built]
- Frontend: [what was built]
- DevOps: [what was configured]

### Cross-Review
- [Key findings, if any]

### QA
- Tests written: [count and types]
- Coverage gaps found: [if any]
- Issues found: [if any]

### UAT
- Business validation: [pass/fail with notes]
- Recommendations: [if any]
```

If any phase surfaced critical issues that weren't resolved, flag them clearly.

---

## Tips for Effective Orchestration

- **Be generous with context in prompts.** Each agent starts fresh — it has zero memory of what other agents did. Include file paths, code snippets, and spec sections directly in the prompt.
- **Use `run_in_background`** for Phase 2 agents so they truly run in parallel.
- **Read agent outputs carefully** before feeding them to the next phase. You are the integration layer — catch misunderstandings early.
- **Don't over-prompt.** These are principal-level agents. Give them the spec and the code, not step-by-step instructions for how to write code. Trust their expertise.
- **Adapt the workflow.** If the task is backend-only, skip the frontend agent. If there's no infrastructure work, skip devops. The phases are a framework, not a straitjacket.

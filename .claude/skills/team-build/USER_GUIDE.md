# team-build User Guide

A comprehensive guide to using the `team-build` skill — an integrated development team orchestration system that coordinates 8 specialized principal-level AI agents through a structured 5-phase workflow.

---

## Table of Contents

1. [What Is team-build?](#1-what-is-team-build)
2. [The Team Roster](#2-the-team-roster)
3. [Installation & Locations](#3-installation--locations)
4. [How to Invoke](#4-how-to-invoke)
5. [The 5-Phase Workflow](#5-the-5-phase-workflow)
6. [Worked Example: End-to-End Walkthrough](#6-worked-example-end-to-end-walkthrough)
7. [Adaptive Workflows](#7-adaptive-workflows)
8. [What to Expect as Output](#8-what-to-expect-as-output)
9. [Best Practices](#9-best-practices)
10. [Tips for Writing Good Task Descriptions](#10-tips-for-writing-good-task-descriptions)
11. [Troubleshooting](#11-troubleshooting)
12. [Customization](#12-customization)
13. [Cost & Performance Considerations](#13-cost--performance-considerations)
14. [FAQ](#14-faq)

---

## 1. What Is team-build?

`team-build` is a Claude Code skill that simulates a full principal-level engineering team working on a feature or task. Instead of Claude attempting to implement a feature as a single "generalist," the skill dispatches 8 specialized agents — each with their own role, expertise, and perspective — and coordinates them through a phased workflow that mirrors how real engineering teams operate.

### Why a Team Instead of a Single Agent?

A single agent trying to do everything tends to:
- Skip requirements analysis and jump straight to code
- Forget to consider operational concerns (deployment, monitoring, security)
- Write tests as an afterthought, or not at all
- Miss business-level usability issues
- Produce inconsistent cross-cutting concerns (backend/frontend integration points, for example)

A coordinated team avoids these pitfalls because:
- **Specialization drives depth.** A PM agent thinks about requirements and acceptance criteria, not implementation details. A DevOps agent obsesses over CI/CD and security. Each role stays in its lane and does that lane well.
- **Phased handoffs enforce rigor.** You can't skip the spec phase if the implementation agents receive a spec as their input. You can't skip testing if QA runs after implementation.
- **Cross-review catches integration bugs.** Two backend engineers reviewing each other's work find issues neither would spot solo.
- **Business validation prevents "technically correct but useless" outcomes.** The UAT agent asks "does this actually solve the problem?" — a question a coder rarely asks.

### What Does It Actually Do?

When you run `/team-build <task>`, the skill:
1. Reads your task description
2. Dispatches agents via Claude Code's built-in `Agent` tool using specialized subagent types
3. Collects outputs from each agent and passes relevant context to the next phase
4. Presents a final summary of what the team produced

The orchestration is driven by the main Claude instance (you're talking to it now) — the skill tells Claude *how* to coordinate the team. The actual work happens in parallel background processes.

---

## 2. The Team Roster

| # | Role | Agent Type | Count | What They Do |
|---|------|-----------|-------|--------------|
| 1 | **Principal Product Manager (Technical)** | `pm-principal` | 1 | Translates user requests into engineering specs. Writes acceptance criteria. Breaks work into parallelizable chunks. Defines the test strategy. |
| 2 | **Principal Backend SDE — A** | `sde-backend` | 1 | Implements backend work item A (API endpoints, services, data layer). Java/Spring Boot, Python, databases, REST APIs, cloud platforms. |
| 3 | **Principal Backend SDE — B** | `sde-backend` | 1 | Implements backend work item B (a separate, parallelizable piece). Cross-reviews SDE-A's code. |
| 4 | **Principal Frontend SDE** | `sde-frontend` | 1 | Implements UI components, state management, API integration. Angular/React, TypeScript, accessibility. |
| 5 | **Principal DevOps Engineer** | `sde-devops` | 1 | Sets up CI/CD, containers, deployment, security hardening. GCP/AWS/Azure. Terraform, Kubernetes, Docker. |
| 6 | **Principal QA Engineer — Writer** | `qa-principal` | 1 | Writes the test suite: unit, integration, e2e tests. Links each test to an acceptance criterion. |
| 7 | **Principal QA Engineer — Reviewer** | `qa-principal` | 1 | Reviews both the tests AND the implementation code. Finds coverage gaps, missing edge cases, and bugs the tests should catch. |
| 8 | **UAT Business User** | `uat-business-user` | 1 | Validates the feature from an end-user perspective. Asks "does this solve the original problem?" and "would a real user be happy with this?" Provides a GO / GO-WITH-NOTES / NO-GO recommendation. |

Each agent is dispatched via the `Agent` tool with the corresponding `subagent_type`. These subagent types are built into your Claude Code installation — you don't need to configure them separately.

---

## 3. Installation & Locations

The skill is installed in two places:

### Project-Local
```
/Users/rob/odrive/googledrive/dev/cooper/agent_team/.claude/skills/team-build/
├── SKILL.md          # The skill's main definition and workflow overview
├── USER_GUIDE.md     # This file
└── references/
    └── workflow.md   # Detailed prompt templates for each phase
```

### User-Global
```
/Users/rob/.claude/skills/team-build/
├── SKILL.md
└── references/
    └── workflow.md
```

### Resolution Order
When both exist, Claude Code prefers the **project-local copy**. This means:
- You can have a default team-build skill globally
- You can override it per-project for specific needs (e.g., a mobile project that replaces the frontend role with iOS/Android engineers)
- Changes to one copy don't automatically sync to the other — edit both if you want them identical, or delete one if you want a single source of truth

### Verifying Installation
Run `/help` or look at the system's skill list. You should see `team-build` listed with the description starting with "Orchestrate a full integrated development team...".

---

## 4. How to Invoke

### Primary Method: Slash Command
```
/team-build <task description>
```

**Examples:**
```
/team-build Add a user profile page with avatar upload
/team-build Build a REST API for inventory management with CRUD endpoints
/team-build Create a real-time notification system using WebSockets
```

### Natural Language Triggers
The skill description is written to catch several natural phrasings. These should also activate it:

- *"Use the full dev team to build X"*
- *"Run a team workflow on this feature"*
- *"I want the dev team to implement X"*
- *"Use team-build for this"*
- *"Have the whole team work on this"*

If it doesn't trigger, just prefix with `/team-build` to force it.

### When NOT to Invoke
- For quick one-line fixes (single typo, variable rename) — overkill
- For questions about existing code (the team doesn't help you *understand* code)
- For exploratory prototyping where you don't yet know what you want
- For refactoring tasks with no new functionality (use `simplify` skill instead)

---

## 5. The 5-Phase Workflow

Each phase feeds the next. The orchestrator (main Claude) reads each phase's output, extracts the relevant pieces, and injects them into the next phase's prompts.

### Phase 1 — Product Specification
**Dispatched:** 1 agent (`pm-principal`)
**Duration:** ~1-3 minutes
**Parallelism:** Sequential (single agent)

**What happens:**
1. The orchestrator gathers context: your task description, current project structure (from `ls`/`find`), any relevant existing code snippets.
2. The PM agent receives all of this and produces a structured spec with 6 sections:
   - **Feature Overview** (what & why, 2-3 sentences)
   - **Backend Work Items** — exactly TWO parallelizable units, labeled A and B
   - **Frontend Work Items** — UI components, API contracts, user flows
   - **DevOps Requirements** — infrastructure, CI/CD, security
   - **Acceptance Criteria** — numbered testable conditions (AC-1, AC-2, ...)
   - **Test Strategy** — what to test at unit/integration/e2e level
3. The orchestrator parses this spec and extracts variables for Phase 2.

**Why this matters:** Without a written spec, implementation agents would guess at requirements and produce incompatible work. The spec is the shared contract.

### Phase 2 — Parallel Implementation
**Dispatched:** 4 agents in parallel (2× `sde-backend`, 1× `sde-frontend`, 1× `sde-devops`)
**Duration:** ~2-5 minutes (wall clock — these run simultaneously)
**Parallelism:** Full parallel (all 4 in background)

**What happens:**
1. The orchestrator sends a single message to the Agent tool that dispatches all 4 agents at once with `run_in_background: true`.
2. Each agent gets ONLY the relevant slice of the spec:
   - Backend SDE-A gets Backend Work Item A + shared API contracts + their acceptance criteria
   - Backend SDE-B gets Backend Work Item B + shared API contracts + their acceptance criteria
   - Frontend SDE gets Frontend Work Items + API contracts + their acceptance criteria
   - DevOps gets DevOps Requirements
3. Each agent writes their code in isolation.
4. The orchestrator waits for all 4 to complete.

**Why parallel:** Sequential would take 4× longer. Parallel works because the PM has already defined the contracts — each agent knows what the others will produce.

**Why only slices of the spec:** Including the entire spec in every agent's prompt wastes tokens and creates confusion. Each engineer sees only their assignment, just like on a real team.

### Phase 3 — Cross-Review
**Dispatched:** 2 agents in parallel (2× `sde-backend`)
**Duration:** ~1-2 minutes
**Parallelism:** Full parallel

**What happens:**
1. Backend SDE-A (freshly reassigned) reviews SDE-B's code.
2. Backend SDE-B (freshly reassigned) reviews SDE-A's code.
3. Each reviewer's prompt includes: the code to review, the original spec for that work item, the API contracts to verify integration, and a structured review checklist.
4. Each reviewer returns findings in 3 buckets:
   - **Critical Issues** — must fix before merge (blocking). Includes proposed fix code.
   - **Suggestions** — non-blocking improvements
   - **Looks Good** — positive feedback
5. The orchestrator applies critical fixes (or re-dispatches the original author if the fix is complex).

**Why cross-review not self-review:** Self-review is weak — people miss their own blind spots. Cross-review between engineers who built *related* work is extra powerful because each reviewer has fresh context about the integration points.

### Phase 4 — Quality Assurance
**Dispatched:** 2 agents sequentially (2× `qa-principal`)
**Duration:** ~2-4 minutes
**Parallelism:** Sequential (reviewer depends on writer's output)

**Step 1 — QA Test Writer:**
1. Receives the full PM spec, acceptance criteria, test strategy, and all implementation code.
2. Writes a complete test suite at every level specified in the strategy.
3. Each test is annotated with a comment linking it to an acceptance criterion (e.g., `// Validates AC-3`).

**Step 2 — QA Test Reviewer:**
1. Receives the tests written by Step 1, plus the spec and implementation code.
2. Reviews both the tests AND the implementation:
   - **Test Coverage** — are all ACs covered? Edge cases? Error paths?
   - **Test Quality** — are tests independent, deterministic, meaningful?
   - **Implementation Review** — are there bugs the tests should catch but don't?
3. Returns: missing test cases (with code), test issues (with fixes), implementation bugs (with fixes), AC-by-AC coverage summary.

**Why two QAs:** A single QA agent tends to be satisfied with their own work. A second pair of eyes — especially one whose explicit job is to find gaps — catches significantly more issues.

### Phase 5 — User Acceptance Testing
**Dispatched:** 1 agent (`uat-business-user`)
**Duration:** ~1-2 minutes
**Parallelism:** Sequential

**What happens:**
1. The UAT agent receives:
   - Your **original** task description (verbatim — not the PM's interpretation)
   - The PM's acceptance criteria
   - The final implementation code
   - The test coverage summary
2. It validates from a business perspective, answering 5 questions:
   - Does this solve the original problem?
   - Is anything missing from a business perspective?
   - Would this be intuitive to use?
   - Are the acceptance criteria sufficient?
   - Go / No-Go recommendation?
3. Returns a final verdict: **GO**, **GO WITH NOTES**, or **NO-GO** with specific blockers.

**Why the original task, not the PM spec:** The whole point of UAT is to check whether the spec drifted from what the user actually wanted. Giving the UAT agent only the spec would let it rubber-stamp a feature that met the spec but missed the intent.

---

## 6. Worked Example: End-to-End Walkthrough

Let's trace what happens when you run:
```
/team-build Add a REST endpoint that lets users reset their password via email
```

### Phase 1 — PM Produces Spec

The PM agent receives your request and the current project structure. It produces something like:

```markdown
### Feature Overview
Add a password reset flow: users request a reset via email, receive a
time-limited token, and use it to set a new password.

### Backend Work Item A — Reset Request Endpoint
- POST /api/auth/password-reset-request
- Accepts: { email: string }
- Generates token, stores in DB with 1-hour TTL
- Sends email via existing mail service
- Returns: 200 always (don't leak whether email exists)

### Backend Work Item B — Reset Confirmation Endpoint
- POST /api/auth/password-reset-confirm
- Accepts: { token: string, new_password: string }
- Validates token, checks TTL, checks single-use
- Updates user password (hashed)
- Invalidates token after use

### Frontend Work Items
- /forgot-password page with email input
- /reset-password/:token page with password form
- Success/error states for both

### DevOps Requirements
- Add PASSWORD_RESET_TOKEN_SECRET env var
- Rate limit the request endpoint (5/hour per IP)

### Acceptance Criteria
AC-1: Valid email triggers email delivery with token link
AC-2: Invalid email returns 200 without sending email
AC-3: Token expires after 1 hour
AC-4: Token is single-use
AC-5: New password replaces old (old password no longer works)
AC-6: Rate limit blocks >5 requests/hour per IP

### Test Strategy
- Unit: token generation, expiry check, hash comparison
- Integration: full request → email → confirm flow
- E2E: UI flow from forgot-password page to successful login
```

### Phase 2 — 4 Agents Work in Parallel

The orchestrator dispatches:
- **Backend SDE-A** → implements `POST /api/auth/password-reset-request`
- **Backend SDE-B** → implements `POST /api/auth/password-reset-confirm`
- **Frontend SDE** → builds `/forgot-password` and `/reset-password/:token` pages
- **DevOps** → adds rate limiting config and env var setup

All 4 run in background. The orchestrator waits for all to finish (~3-5 min wall clock).

### Phase 3 — Cross-Review

- **SDE-A reviews SDE-B's code** and finds: "Token comparison uses `==` instead of constant-time compare — timing attack risk. Also, token is deleted before password is hashed, so if hashing fails the user gets locked out." Provides fixes.
- **SDE-B reviews SDE-A's code** and finds: "Rate limit is implemented at the app layer but should be at the edge. Also, error messages leak whether email exists in DB despite the 200 response." Provides fixes.

The orchestrator applies critical fixes.

### Phase 4 — QA

**QA Writer** produces tests:
- Unit tests for token generation, hashing, TTL calculation
- Integration tests for the full request → confirm flow
- E2E test walking through the UI

**QA Reviewer** finds:
- "No test for what happens when token is used twice in rapid succession (race condition)"
- "AC-6 (rate limit) isn't actually tested — only the happy path"
- Writes the missing tests.

### Phase 5 — UAT

**UAT agent** reviews:
- "The user asked for password reset — this delivers. ✓"
- "However: the email template isn't specified. Does the link format look professional? Is the sender address set correctly? What happens if email delivery fails silently?"
- "Recommendation: **GO WITH NOTES** — releasable, but add monitoring for email delivery failures and verify the email template in staging before production rollout."

### Final Summary
The orchestrator presents all of this to you in a structured format, with file paths to the new code, test coverage summary, and the UAT verdict.

---

## 7. Adaptive Workflows

Not every task needs all 5 phases or all 8 agents. The skill explicitly supports adapting the workflow based on scope. The orchestrator uses judgment — informed by the PM's spec — to decide what to skip.

### Backend-Only Task
Example: *"Add a new analytics service that aggregates data from the events table"*
- **Skip:** Frontend SDE in Phase 2
- **Keep:** PM, 2 Backend SDEs, DevOps, both QAs, UAT
- **Why keep UAT:** Even backend-only changes affect end users (API consumers, monitoring, latency)

### Frontend-Only Task
Example: *"Redesign the settings page with the new design system"*
- **Skip:** Backend SDEs, cross-review
- **Keep:** PM, Frontend SDE, DevOps (if deployment changes), both QAs, UAT

### Small Bug Fix
Example: *"Fix the off-by-one error in the pagination component"*
- **Run:** Quick PM (1-paragraph spec) → single relevant SDE → single QA → UAT
- **Skip:** Cross-review, duplicate QA
- **Why:** Overhead exceeds value for trivial changes

### Infrastructure-Only Task
Example: *"Migrate our CI from Jenkins to GitHub Actions"*
- **Run:** PM → DevOps → QA (focused on deployment verification) → UAT (focused on operational readiness — does the team's workflow still work?)
- **Skip:** Backend/Frontend SDEs

### When in Doubt, Run the Full Team
The default is the full 5-phase, 8-agent workflow. Adaptations should be explicit decisions based on clear scope signals, not a way to rush.

---

## 8. What to Expect as Output

After all phases complete, you'll see a structured summary like:

```markdown
## Team Build Complete

### PM Spec
Added password reset flow with email-based token verification.
6 acceptance criteria defined.

### Implementation
- Backend A: POST /api/auth/password-reset-request (src/routes/auth/reset-request.ts)
- Backend B: POST /api/auth/password-reset-confirm (src/routes/auth/reset-confirm.ts)
- Frontend: /forgot-password and /reset-password/:token pages (src/pages/auth/)
- DevOps: Rate limiting in nginx config, new env var documented

### Cross-Review
- Critical: Fixed timing attack in token comparison
- Critical: Fixed race condition in token invalidation
- Suggestions: 2 minor style improvements applied

### QA
- Tests written: 14 unit, 6 integration, 2 E2E
- Coverage: all 6 acceptance criteria covered
- Issues found: 2 missing test cases added for race conditions and rate limits

### UAT
- Business validation: GO WITH NOTES
- Recommendations:
  1. Add monitoring for email delivery failures
  2. Verify email template in staging before production
```

Files are actually written to disk. Tests are actually created. You can inspect the code directly, run the tests, commit everything.

---

## 9. Best Practices

### Give Rich Task Descriptions
**Bad:**
```
/team-build Add login
```

**Good:**
```
/team-build Add email/password login with JWT tokens, plus rate limiting on
failed attempts (5 per 15 min per IP). Users should be able to stay logged
in via refresh tokens stored in httpOnly cookies. Use our existing User table.
```

The more context, the better the PM's spec, and the better every downstream phase.

### Commit Before Running
The team will modify multiple files across your codebase. Commit first so you can cleanly review the diff or roll back if needed.

### Review the PM Spec Before Accepting
If the orchestrator shows you the PM's spec mid-workflow, read it carefully. This is the cheapest place to catch misunderstandings. If the spec is wrong, stop and re-run — don't let the team build the wrong thing.

### Don't Re-Run on Failure Without Investigating
If a phase fails, read the error before re-running. Common causes:
- Ambiguous task description (fix the description, not the skill)
- Missing project context (the PM didn't know about an existing file)
- Agent hit an unexpected code pattern (look at what confused it)

### Use for Non-Trivial Work
The skill has meaningful overhead — 8 agents, multiple phases, several minutes of wall-clock time. It pays off for features that genuinely need spec → implement → review → test → validate. For tiny changes, it's overkill.

---

## 10. Tips for Writing Good Task Descriptions

The quality of the entire team's output depends on the quality of your task description. The PM agent translates it into a spec, but garbage in → garbage out.

### Include
- **What** the feature does (in user terms)
- **Why** it matters (business goal, pain point being solved)
- **Constraints** (tech stack, existing systems to integrate with)
- **Scope boundaries** (what's NOT included)
- **Success criteria** (how you'll know it's working)

### Avoid
- Implementation details ("use a hashmap with linear probing") — let the engineers decide
- Over-specifying UX ("the button should be 48px tall and blue") — let the frontend SDE apply design system knowledge
- Jargon without context — the PM agent is smart but doesn't know your internal project vocabulary

### Template

```
/team-build [VERB] [FEATURE] that [WHAT IT DOES FROM USER PERSPECTIVE].

Business context: [WHY THIS MATTERS]

Must integrate with: [EXISTING SYSTEMS]

Out of scope: [WHAT NOT TO BUILD]

Success means: [OBSERVABLE OUTCOME]
```

### Example Using the Template

```
/team-build Build a recipe recommendation system that suggests 5 recipes
based on ingredients a user already has in their pantry.

Business context: Users abandon meal planning when they need to buy too
many extra ingredients. This reduces friction.

Must integrate with: Existing Pantry and Recipe models in src/models/.
Use the Postgres full-text search we already have configured.

Out of scope: Shopping list generation (that's a separate epic), dietary
filters (next sprint), and recipe ratings.

Success means: User with 10 pantry items gets 5 recipe suggestions ranked
by pantry match %, in under 500ms.
```

This task description gives the PM everything it needs to write a tight spec.

---

## 11. Troubleshooting

### The skill didn't trigger
- Try the explicit slash form: `/team-build <task>`
- Check that the skill is listed in your available skills
- Verify installation: look for `SKILL.md` in the skill directories

### A phase failed mid-workflow
- Read the error output carefully
- Check if the task description was too vague for the PM to spec properly
- If an implementation agent failed, check if it hit unfamiliar code patterns
- Re-run the specific phase or the whole workflow with a more detailed description

### The PM's spec is wrong
- Stop the workflow
- Re-run with a clearer task description
- Explicitly call out any constraints the PM missed
- Consider whether your task is actually two tasks in a trenchcoat — split it

### Two backend SDEs produced conflicting code
- Check if the PM's work items were actually parallelizable
- If the pieces are too interdependent, the PM should have merged them into one item
- This is a signal the PM spec needs improvement — rerun with explicit guidance on how to split the work

### QA found bugs the implementation agents missed
- This is exactly the point of having QA — the system caught them
- The fixes should have been applied automatically
- If they weren't, ask the orchestrator to apply the QA-recommended fixes

### UAT said NO-GO
- Read the UAT agent's reasoning carefully — this is your most important feedback
- The fix might be in the spec, not the code
- Consider: did the PM capture the user's intent correctly? Did you express the intent clearly in the task description?

### The workflow is taking too long
- Phase 2 is the longest phase (implementation) — this is expected
- If it's stalling, check if one agent is stuck; you can cancel and retry
- For small tasks, use the adaptive workflow to skip phases

---

## 12. Customization

### Editing the Skill
To modify the workflow, edit `SKILL.md` in either location:
- Project-local: `/Users/rob/odrive/googledrive/dev/cooper/agent_team/.claude/skills/team-build/SKILL.md`
- Global: `/Users/rob/.claude/skills/team-build/SKILL.md`

Remember: project-local takes precedence. If you edit the global one, the project still uses the project-local version.

### Editing Prompt Templates
The detailed agent prompts live in `references/workflow.md`. These are the exact prompts the orchestrator uses to dispatch each agent. Edit them to:
- Change what the PM's spec template looks like
- Adjust the review checklist for cross-review
- Modify the QA test strategy
- Tweak the UAT evaluation criteria

### Adding a Role
To add a new agent role (e.g., a Security Engineer):
1. Identify the `subagent_type` you want (must be one of the built-in types)
2. Add a new phase or extend an existing one in `SKILL.md`
3. Add a prompt template in `references/workflow.md`
4. Update the team roster table

### Removing a Role
Just remove the corresponding agent dispatch from the phase. For example, to remove the second QA:
1. In `SKILL.md` Phase 4, delete the "Step 2 — QA Test Reviewer" section
2. Update the roster table

### Replacing a Role
Example: swap Frontend SDE for a Mobile Engineer.
1. Change `subagent_type: "sde-frontend"` to whatever mobile agent type you prefer
2. Update the prompt template to reference mobile-specific concerns (iOS/Android, native vs hybrid)
3. Update the roster

### Per-Project Overrides
Install the default skill globally, then create a project-local copy only when you need to customize. The project-local copy overrides the global one automatically.

---

## 13. Cost & Performance Considerations

### Token Usage
Running the full workflow on a moderate feature uses roughly:
- Phase 1 (PM): 1 agent × ~5-10k tokens
- Phase 2 (Implementation): 4 agents × ~10-30k tokens each
- Phase 3 (Cross-review): 2 agents × ~10-15k tokens each
- Phase 4 (QA): 2 agents × ~15-25k tokens each
- Phase 5 (UAT): 1 agent × ~5-10k tokens

**Total:** ~150-300k tokens for a typical feature. Budget accordingly.

### Wall-Clock Time
- Small task: ~5-8 minutes
- Medium task: ~8-15 minutes
- Large task: ~15-25 minutes
- Very large task: split into multiple `/team-build` invocations

### Cost Optimization
- Use adaptive workflows — skip phases that don't apply
- For small fixes, use a single-agent approach instead of the full team
- Bundle related small features into one `/team-build` rather than many

### Parallelism Savings
Phase 2 runs all 4 implementation agents in parallel. If they ran sequentially, Phase 2 would take ~4× longer. The skill is specifically designed to exploit this.

---

## 14. FAQ

**Q: Can I run multiple `/team-build` workflows in the same session?**
A: Yes, but wait for one to complete before starting the next. The orchestrator tracks state per-invocation.

**Q: What if my project uses a language none of the default agents know well?**
A: The principal agents are generalists in their domains. They handle most common stacks. For very niche languages, edit the prompt templates to include language-specific guidance.

**Q: Can I skip the PM phase if I already have a spec?**
A: Yes — pass your pre-written spec as the task description and tell the orchestrator "use this spec directly instead of running the PM phase." The orchestrator will adapt.

**Q: What happens if an agent fails mid-workflow?**
A: The orchestrator notes the failure and decides whether to retry, skip, or halt. You'll be informed of the failure and asked how to proceed for serious cases.

**Q: Does this work for non-code tasks (docs, planning, research)?**
A: The skill is optimized for code. For pure research or planning, use the `Plan` or `Explore` agents directly — they're better suited.

**Q: Can I run just one agent from the team?**
A: Yes — the `Agent` tool lets you dispatch any single `subagent_type` directly. The skill's value is the orchestration; if you only need one agent, skip the skill.

**Q: Will the team ask me for clarification mid-workflow?**
A: Generally no — the PM agent operates from the initial task description and the orchestrator doesn't interrupt for clarification. If you want interactive clarification, mention that in your task description ("ask me questions before specifying").

**Q: Can I run this without internet?**
A: The skill itself is just files, but the agents call Claude's API, which requires internet.

**Q: How do I uninstall?**
A: Delete the `team-build` directory from `~/.claude/skills/` and/or `<project>/.claude/skills/`.

**Q: Is there a way to see the individual agent outputs, not just the summary?**
A: Yes — the orchestrator shows each agent's output as it completes. If you want persistent logs, ask the orchestrator to save them to a file.

**Q: Can two team-build workflows share state?**
A: Not by default. Each invocation is independent. If you need continuity, commit the output of the first workflow before starting the second — the second PM will see the committed code as "existing state."

---

## Quick Reference Card

```
Trigger:    /team-build <task description>

Phases:     1. PM Spec (1 agent)
            2. Parallel Implementation (4 agents, background)
            3. Cross-Review (2 agents, parallel)
            4. QA Write + Review (2 agents, sequential)
            5. UAT Business Validation (1 agent)

Team:       1 PM, 2 Backend, 1 Frontend, 1 DevOps, 2 QA, 1 UAT

Locations:  <project>/.claude/skills/team-build/   (project-local)
            ~/.claude/skills/team-build/           (user-global)

Edit:       SKILL.md for workflow overview
            references/workflow.md for prompt templates

Adapt:      Skip phases/agents for backend-only, frontend-only,
            or small tasks — but default to the full workflow.
```

---

*End of User Guide*

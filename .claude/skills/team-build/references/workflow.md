# Team Build — Detailed Workflow & Prompt Templates

This reference contains the prompt templates and detailed mechanics for each phase of the team-build workflow. Read the relevant section when you're about to dispatch agents for that phase.

## Table of Contents
1. [Phase 1: Product Specification](#phase-1-product-specification)
2. [Phase 2: Parallel Implementation](#phase-2-parallel-implementation)
3. [Phase 3: Cross-Review](#phase-3-cross-review)
4. [Phase 4: Quality Assurance](#phase-4-quality-assurance)
5. [Phase 5: User Acceptance Testing](#phase-5-user-acceptance-testing)
6. [Adaptive Workflows](#adaptive-workflows)

---

## Phase 1: Product Specification

### Agent Dispatch

```
Agent({
  description: "PM: Feature specification",
  subagent_type: "pm-principal",
  prompt: `You are the Principal Product Manager for this project. Your job is to
turn the following task into an actionable engineering spec.

## User's Task
${userTaskDescription}

## Current Project Structure
${projectStructure}

## Existing Code Context
${relevantCodeContext}

## Your Deliverables

Produce a structured spec with these sections:

### 1. Feature Overview
What we're building and why. Keep it to 2-3 sentences.

### 2. Backend Work Items
Break the backend work into exactly TWO parallelizable work items. Each should be:
- Self-contained enough for one engineer to implement independently
- Clear about inputs, outputs, and data flow
- Specific about which files to create or modify

Label them "Backend Work Item A" and "Backend Work Item B".

### 3. Frontend Work Items
UI components, pages, and state management needed. Include:
- API contracts (endpoints, request/response shapes) the frontend should consume
- User interaction flows
- Any design constraints

### 4. DevOps Requirements
Infrastructure, CI/CD, and deployment needs. Include:
- New services or containers needed
- Environment variables or secrets
- Pipeline changes
- Security considerations

### 5. Acceptance Criteria
Numbered list of testable conditions. Each criterion should be verifiable
by automated tests or manual inspection. Format:
AC-1: [criterion]
AC-2: [criterion]
...

### 6. Test Strategy
What to test at each level:
- Unit tests: [specific functions/modules]
- Integration tests: [specific interactions]
- E2E tests: [specific user flows, if applicable]

Be specific — name the functions, endpoints, and flows to test.`
})
```

### What to Extract

After the PM finishes, parse its output into these variables for Phase 2:
- `pmSpec` — the full spec (for reference)
- `backendWorkItemA` — Backend Work Item A section
- `backendWorkItemB` — Backend Work Item B section
- `frontendWorkItems` — Frontend Work Items section
- `devopsRequirements` — DevOps Requirements section
- `acceptanceCriteria` — Acceptance Criteria section
- `testStrategy` — Test Strategy section

---

## Phase 2: Parallel Implementation

### Agent Dispatch — All 4 in a Single Message

```
// Backend SDE-A
Agent({
  description: "Backend SDE-A: Implementation",
  subagent_type: "sde-backend",
  run_in_background: true,
  prompt: `You are Backend SDE-A on a development team. Implement the following
work item. Another backend engineer is working on a separate piece in parallel —
coordinate through the API contracts specified below.

## Your Work Item
${backendWorkItemA}

## API Contracts (for integration)
${apiContracts}

## Acceptance Criteria (your portion)
${relevantAcceptanceCriteria}

## Project Structure
${projectStructure}

## Existing Code
${relevantExistingCode}

Implement this work item. Write clean, production-quality code.
Create or modify only the files needed for your work item.`
})

// Backend SDE-B
Agent({
  description: "Backend SDE-B: Implementation",
  subagent_type: "sde-backend",
  run_in_background: true,
  prompt: `You are Backend SDE-B on a development team. Implement the following
work item. Another backend engineer is working on a separate piece in parallel —
coordinate through the API contracts specified below.

## Your Work Item
${backendWorkItemB}

## API Contracts (for integration)
${apiContracts}

## Acceptance Criteria (your portion)
${relevantAcceptanceCriteria}

## Project Structure
${projectStructure}

## Existing Code
${relevantExistingCode}

Implement this work item. Write clean, production-quality code.
Create or modify only the files needed for your work item.`
})

// Frontend SDE
Agent({
  description: "Frontend SDE: Implementation",
  subagent_type: "sde-frontend",
  run_in_background: true,
  prompt: `You are the Frontend SDE on a development team. Implement the
frontend for this feature. Backend engineers are building the APIs in parallel —
use the contracts below.

## Your Work Items
${frontendWorkItems}

## API Contracts
${apiContracts}

## Acceptance Criteria (your portion)
${relevantAcceptanceCriteria}

## Project Structure
${projectStructure}

## Existing Code
${relevantExistingCode}

Implement the frontend. Write clean, production-quality code with
proper component structure and state management.`
})

// DevOps Engineer
Agent({
  description: "DevOps: Infrastructure setup",
  subagent_type: "sde-devops",
  run_in_background: true,
  prompt: `You are the DevOps Engineer on a development team. Set up the
infrastructure and deployment pipeline for this feature.

## Your Requirements
${devopsRequirements}

## Project Structure
${projectStructure}

## Existing Infrastructure
${existingInfraCode}

Implement the infrastructure changes. Focus on:
- CI/CD pipeline configuration
- Container/service definitions
- Environment configuration
- Security hardening`
})
```

### Collecting Phase 2 Results

As each background agent completes, note:
- Which files were created or modified
- Any issues or assumptions the agent flagged
- The implementation approach taken

You'll need file-level details for Phase 3 (cross-review).

---

## Phase 3: Cross-Review

### Agent Dispatch — 2 in Parallel

```
// SDE-A reviews SDE-B's code
Agent({
  description: "Backend SDE-A: Cross-review",
  subagent_type: "sde-backend",
  run_in_background: true,
  prompt: `You are a Principal Backend SDE performing a code review. Another
engineer implemented the work below. Review it for correctness, security,
edge cases, and consistency with the spec.

## Original Spec for This Work Item
${backendWorkItemB}

## Code to Review
${sdeBImplementationCode}

## API Contracts (verify integration points)
${apiContracts}

## Review Checklist
- Does the code correctly implement the spec?
- Are edge cases handled?
- Are there security vulnerabilities (injection, auth bypass, etc.)?
- Is the code consistent with the API contracts?
- Are there performance concerns?
- Is error handling appropriate?

Provide your review as:
1. **Critical Issues** — must fix before merge (blocking)
2. **Suggestions** — improvements that would help but aren't blocking
3. **Looks Good** — aspects that are well-implemented

If there are critical issues, also provide the fix (write the corrected code).`
})

// SDE-B reviews SDE-A's code
Agent({
  description: "Backend SDE-B: Cross-review",
  subagent_type: "sde-backend",
  run_in_background: true,
  prompt: `[Same structure as above, but reviewing SDE-A's code]`
})
```

### Handling Review Results

- **Critical issues with fixes provided:** Apply the fixes.
- **Critical issues without fixes:** You (the orchestrator) decide whether to fix inline or re-dispatch.
- **Suggestions only:** Note them, continue to Phase 4.

---

## Phase 4: Quality Assurance

### Step 1 — QA Test Writer

```
Agent({
  description: "QA: Write test suite",
  subagent_type: "qa-principal",
  prompt: `You are a Principal QA Engineer. Write a comprehensive test suite
for the feature described below. All implementation is complete — your job
is to verify it works correctly.

## Feature Spec
${pmSpec}

## Acceptance Criteria
${acceptanceCriteria}

## Test Strategy
${testStrategy}

## Implementation Code
${allImplementationCode}

## Files Changed
${listOfChangedFiles}

Write tests at every level specified in the test strategy:
- Unit tests for individual functions and methods
- Integration tests for service interactions and API endpoints
- E2E tests for user flows (if specified)

Use the project's existing test framework and conventions. If none exist,
choose appropriate frameworks for the tech stack.

For each test, include a comment linking it to the acceptance criterion
it validates (e.g., "// Validates AC-3").`
})
```

### Step 2 — QA Test Reviewer

```
Agent({
  description: "QA: Review tests and code",
  subagent_type: "qa-principal",
  prompt: `You are a Principal QA Engineer performing a test review. Another
QA engineer wrote the tests below. Your job is to review both the tests AND
the implementation code for quality.

## Feature Spec & Acceptance Criteria
${pmSpec}
${acceptanceCriteria}

## Implementation Code
${allImplementationCode}

## Tests to Review
${allTestCode}

## Your Review Should Cover

### Test Coverage
- Is every acceptance criterion covered by at least one test?
- Are edge cases tested (nulls, empty inputs, boundaries, error paths)?
- Are integration points between backend services tested?
- Are API contracts validated?

### Test Quality
- Are tests independent and deterministic?
- Do tests have clear assertions with meaningful messages?
- Are there any tests that would pass even if the code was broken (false positives)?
- Are test fixtures and mocks appropriate?

### Implementation Code Review
- Are there bugs the tests should catch but don't?
- Are there untested code paths?
- Is error handling tested?

Provide:
1. **Missing Test Cases** — tests that should exist but don't (write them)
2. **Test Issues** — problems with existing tests (with fixes)
3. **Implementation Bugs** — issues found in the code (with fixes)
4. **Coverage Assessment** — AC-by-AC coverage summary`
})
```

---

## Phase 5: User Acceptance Testing

```
Agent({
  description: "UAT: Business validation",
  subagent_type: "uat-business-user",
  prompt: `You are a business user performing User Acceptance Testing. Your job
is to validate this feature from the perspective of someone who will actually
use it — not as a developer, but as an end user.

## What the User Originally Asked For
${originalUserTaskDescription}

## What Was Built (PM's Spec)
${pmSpec}

## Acceptance Criteria
${acceptanceCriteria}

## Implementation Summary
${implementationSummary}

## Test Coverage Summary
${testCoverageSummary}

## Your Validation Should Answer

1. **Does this solve the original problem?**
   Compare what the user asked for against what was built. Are there gaps?

2. **Is anything missing from a business perspective?**
   Think about real-world usage. Are there scenarios the spec missed?

3. **Would this be intuitive to use?**
   For any UI work: is the flow logical? For APIs: are the contracts sensible?

4. **Are the acceptance criteria sufficient?**
   Would passing all AC actually mean the feature is done?

5. **Go/No-Go Recommendation**
   Would you approve this for release? If no, what needs to change?

Provide your assessment as:
- **GO** — ready for release
- **GO WITH NOTES** — releasable but with documented follow-ups
- **NO-GO** — must fix [specific items] before release`
})
```

---

## Adaptive Workflows

Not every task needs all 5 phases or all 8 agents. Adapt based on scope:

### Backend-Only Task
Skip Frontend SDE in Phase 2. Phase 5 UAT still runs (backend changes affect users too).

### Frontend-Only Task
Skip Backend SDEs and cross-review. Run Frontend SDE, DevOps (if deployment changes needed), QA, UAT.

### Small Bug Fix
Consider running just: PM (quick spec) → single Backend or Frontend SDE → single QA → UAT. Skip cross-review for small changes.

### Infrastructure-Only Task
PM → DevOps → QA (focused on deployment verification) → UAT (focused on operational readiness).

### Judgment Calls
- If the PM spec reveals the task is simpler than expected, reduce the team.
- If cross-review finds serious issues, consider re-dispatching implementation agents rather than patching inline.
- If QA coverage is already strong from the implementation agents' own tests, the QA phase can focus on integration and edge cases rather than starting from scratch.

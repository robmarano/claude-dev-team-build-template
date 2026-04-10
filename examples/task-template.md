# Task Description Template

Copy this template and fill in the brackets to write a high-quality task description for the `team-build` skill. The better your task description, the better the PM's spec — and the better every downstream phase.

---

## Template

```
/team-build [VERB] [FEATURE] that [WHAT IT DOES FROM USER PERSPECTIVE].

Business context: [WHY THIS MATTERS — what pain point does this solve?]

Must integrate with: [EXISTING SYSTEMS, MODELS, OR SERVICES]

Constraints: [PERFORMANCE BUDGETS, RATE LIMITS, COMPLIANCE, TECH STACK]

Out of scope: [WHAT NOT TO BUILD — to prevent over-building]

Success means: [OBSERVABLE OUTCOME — how you'll verify it works]
```

---

## Filled-In Example

```
/team-build Build a recipe recommendation system that suggests 5 recipes
based on ingredients a user already has in their pantry.

Business context: Users abandon meal planning when they need to buy too
many extra ingredients. This reduces friction by showing them recipes
they can make right now.

Must integrate with: Existing Pantry and Recipe models in src/models/.
Use the Postgres full-text search we already have configured. Recipes
are tagged with their ingredients in the recipe_ingredients join table.

Constraints: Response time under 500ms for 95th percentile. Must handle
users with 100+ pantry items without timing out. No third-party APIs.

Out of scope: Shopping list generation (separate epic), dietary filters
(vegan, keto — coming next sprint), recipe ratings, and saving favorites.

Success means: A user with 10 pantry items gets 5 recipe suggestions
ranked by pantry match percentage, returned in under 500ms, with a
clear match score shown in the UI for each suggestion.
```

---

## Why Each Section Matters

### Verb + Feature + User Perspective
The opening line is the PM's north star. It answers "what are we building and who is it for?" in one sentence. Keep it concrete and user-centric.

**Bad:** *"Improve search."*
**Good:** *"Add fuzzy search to the recipe browser so users can find recipes even when they misspell ingredients."*

### Business Context
Explains WHY the feature exists. This prevents the team from building something that technically meets the spec but misses the point. The UAT agent in Phase 5 uses this to validate that the final product solves the original problem.

### Must Integrate With
Gives engineers concrete touchpoints in the existing codebase. Without this, they'll either invent new patterns (creating inconsistency) or ask for clarification (slowing things down). Be specific — mention file paths, model names, service names.

### Constraints
Non-functional requirements: performance, security, compliance, rate limiting. These shape architectural decisions. The DevOps agent and QA agents especially depend on these.

### Out of Scope
The most underrated section. Engineers (human and AI) tend to gold-plate — adding features they think "would be nice." An explicit "out of scope" list keeps the team focused and prevents scope creep. Also protects your token budget.

### Success Means
The final answer to "is it done?" The PM translates this into acceptance criteria. The QA agents test against it. The UAT agent validates against it. If you can't articulate what success looks like, the team can't deliver it.

---

## Red Flags in Your Own Task Description

If your draft has any of these, rewrite it before running `/team-build`:

- **Vague verbs:** "improve," "enhance," "optimize" — replace with concrete actions
- **Implementation details:** telling the team HOW to build it (variable names, algorithm choices) — trust the principals
- **Multiple features smashed together:** if you can't describe it in one paragraph, split it into multiple `/team-build` invocations
- **No constraints:** results in over-engineered solutions
- **No success criteria:** results in an undefined finish line
- **References to knowledge you haven't included:** "like we discussed in the Slack thread" — the agents can't read your Slack

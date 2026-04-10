# Using This Template — CLI Walkthrough

A step-by-step guide to spinning up a new project from this template and running your first team build — entirely from the command line.

This guide assumes you're on macOS or Linux. Windows users can run the same commands in WSL or Git Bash.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create a New Project from This Template](#2-create-a-new-project-from-this-template)
3. [Verify the Skill Is Installed](#3-verify-the-skill-is-installed)
4. [Run Your First Team Build](#4-run-your-first-team-build)
5. [Review, Commit, and Push](#5-review-commit-and-push)
6. [Iterate with More Team Builds](#6-iterate-with-more-team-builds)
7. [Customize the Skill for Your Project](#7-customize-the-skill-for-your-project)
8. [Troubleshooting](#8-troubleshooting)
9. [Uninstall / Cleanup](#9-uninstall--cleanup)

---

## 1. Prerequisites

You need four tools installed and authenticated:

### 1.1 Git
```bash
git --version
```
Expected: `git version 2.x.x` or newer. If missing, install from https://git-scm.com/ or via Homebrew:
```bash
brew install git
```

### 1.2 GitHub CLI (`gh`)
```bash
gh --version
```
Expected: `gh version 2.x.x` or newer. If missing:
```bash
brew install gh
```

Authenticate:
```bash
gh auth login
```
Follow the interactive prompts. Choose GitHub.com, HTTPS or SSH (SSH recommended), and authenticate via browser.

Verify:
```bash
gh auth status
```
You should see `✓ Logged in to github.com account <your-username>`.

### 1.3 Claude Code CLI
```bash
claude --version
```
If missing, install per Anthropic's instructions:
```bash
# See https://claude.com/claude-code for current install method
```

Authenticate by running `claude` once in any directory and following the login flow.

### 1.4 (Optional) Your Preferred Language Toolchain
The `team-build` skill works with any language — Node, Python, Go, Java, Rust, etc. Have your toolchain installed so the QA agent can actually run the tests it writes. Example for Node:
```bash
node --version
npm --version
```

---

## 2. Create a New Project from This Template

### 2.1 Create the Repo from the Template (One Command)

Replace `my-new-project` with your desired project name:

```bash
gh repo create my-new-project \
  --template robmarano/claude-dev-team-build-template \
  --public \
  --clone \
  --description "My project built with the team-build skill"
```

**What each flag does:**
- `--template robmarano/claude-dev-team-build-template` — use this template repo as the starting point
- `--public` — make the repo public (use `--private` for a private repo)
- `--clone` — clone it locally immediately after creation
- `--description "..."` — optional repo description shown on GitHub

The command creates the repo on GitHub, clones it to `./my-new-project`, and sets `origin` to track it.

### 2.2 Move Into the Project

```bash
cd my-new-project
```

### 2.3 Verify the Clone

```bash
git status
git remote -v
ls -la
```

Expected output:
```
# git status
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean

# git remote -v
origin  git@github.com:<your-username>/my-new-project.git (fetch)
origin  git@github.com:<your-username>/my-new-project.git (push)

# ls -la
drwxr-xr-x  .claude
drwxr-xr-x  docs
drwxr-xr-x  examples
drwxr-xr-x  src
drwxr-xr-x  tests
-rw-r--r--  .gitignore
-rw-r--r--  LICENSE
-rw-r--r--  README.md
```

### 2.4 Verify the Skill Files Are Present

```bash
find .claude -type f
```

Expected:
```
.claude/skills/team-build/SKILL.md
.claude/skills/team-build/USER_GUIDE.md
.claude/skills/team-build/references/workflow.md
```

---

## 3. Verify the Skill Is Installed

### 3.1 Launch Claude Code in the Project

```bash
claude
```

This starts an interactive session in your project directory. Claude Code auto-discovers skills from `.claude/skills/` — the `team-build` skill should be immediately available.

### 3.2 Confirm the Skill Is Loaded

At the Claude Code prompt, ask:
```
What skills are available in this project?
```

Claude should list `team-build` among the available skills with a description starting with "Orchestrate a full integrated development team...".

### 3.3 Read the User Guide (Recommended First Step)

Ask Claude to summarize the skill's user guide:
```
Summarize the team-build skill's user guide in 10 bullet points
```

Or open it directly in your terminal from outside Claude Code:
```bash
less .claude/skills/team-build/USER_GUIDE.md
```

The full guide covers phase mechanics, a worked example, adaptive workflows, best practices, and troubleshooting.

---

## 4. Run Your First Team Build

### 4.1 Pick a Starter Task

The template ships with sample tasks in `examples/first-task.md`. View them:
```bash
cat examples/first-task.md
```

The simplest starter is a health check endpoint — it exercises the skill without running all 8 agents at full power.

### 4.2 Run It

In your Claude Code session:
```
/team-build Add a health check endpoint at /health that returns 200 OK with a JSON payload showing service name, version, uptime in seconds, and database connectivity status (connected/disconnected).
```

### 4.3 What You'll See

Claude Code will walk through the 5 phases:

1. **Phase 1 — PM Specification** (~1-2 min)
   You'll see the PM agent being dispatched and returning a structured spec with feature overview, backend work items, acceptance criteria, and test strategy.

2. **Phase 2 — Parallel Implementation** (~2-5 min wall clock)
   Multiple agents dispatched in parallel as background tasks. You'll see notifications as each completes.

3. **Phase 3 — Cross-Review** (~1-2 min)
   Backend engineers review each other's code (skipped for trivial tasks).

4. **Phase 4 — QA** (~2-4 min)
   Test writer produces a test suite, then the reviewer checks coverage and quality.

5. **Phase 5 — UAT** (~1-2 min)
   Business user agent validates against the original task description.

### 4.4 Review the Final Summary

At the end, Claude presents a structured summary like:
```
## Team Build Complete

### PM Spec
Added /health endpoint with service status and DB connectivity check.

### Implementation
- Backend A: GET /health endpoint (src/backend/routes/health.ts)
- DevOps: Added HEALTH_CHECK_INTERVAL env var

### QA
- Tests written: 4 unit, 2 integration
- Coverage: all 3 acceptance criteria covered

### UAT
- Business validation: GO
```

Files are actually written to disk. Inspect them from a separate terminal:
```bash
find src tests -type f -newer README.md
```

---

## 5. Review, Commit, and Push

### 5.1 See What Changed

Exit Claude Code (`Ctrl+D` or `/exit`), then from the project directory:

```bash
git status
git diff --stat
```

You should see new files in `src/`, `tests/`, and potentially modifications to `.github/` or other config.

### 5.2 Review the Code Before Committing

```bash
git diff
```

Even though a principal-level AI team produced this code, it's your repo — you should read the code before committing. Look for:
- Secrets or credentials accidentally hardcoded
- Unexpected file changes (files outside the scope of your task)
- Anything that doesn't match your project conventions

### 5.3 Run the Tests

Before committing, verify the tests the QA agents wrote actually pass. Example for Node:
```bash
npm test
```

For Python:
```bash
pytest
```

If tests fail, re-enter Claude Code and ask it to fix the failures — don't commit broken tests.

### 5.4 Stage and Commit

```bash
git add src/ tests/
git commit -m "Add health check endpoint via team-build

Includes unit and integration tests covering all acceptance criteria.
Generated by the team-build skill workflow."
```

### 5.5 Push to GitHub

```bash
git push
```

Verify it's live:
```bash
gh repo view --web
```

This opens the repo in your browser (or use `gh repo view` to see it in the terminal).

---

## 6. Iterate with More Team Builds

### 6.1 Commit Between Team Builds

Each `/team-build` invocation starts fresh — the team doesn't have memory of previous builds. By committing between builds, you ensure the next run sees the previous work as "existing code" in the project, which the PM agent will reference.

```bash
# After finishing feature 1
git add .
git commit -m "Add feature 1"
git push

# Start feature 2
claude
# > /team-build Add feature 2 that builds on feature 1...
```

### 6.2 Write Better Task Descriptions Over Time

Read the task writing guide:
```bash
cat examples/task-template.md
```

Key principles:
- Describe WHAT the feature does, not HOW to build it
- Include business context (the "why")
- Mention existing code or systems to integrate with
- Explicitly state what's OUT of scope
- Define observable success criteria

### 6.3 Use Branches for Parallel Work

For larger projects, use feature branches:
```bash
git checkout -b feature/user-profile
claude
# > /team-build Add user profile page...
git add .
git commit -m "Add user profile page"
git push -u origin feature/user-profile
gh pr create --fill
```

### 6.4 Code Review with Another Agent

After a team build, you can ask Claude to run its built-in code review agent over the diff:
```
/code-review
```
This runs an additional independent review pass, catching anything the in-team cross-review may have missed.

---

## 7. Customize the Skill for Your Project

The skill is YOUR copy — customize freely.

### 7.1 Edit the Phase Workflow

```bash
$EDITOR .claude/skills/team-build/SKILL.md
```

Common customizations:
- Add a new phase (e.g., "Security Review" between Phase 3 and Phase 4)
- Remove the second QA for faster iteration on small projects
- Add language-specific guidance for the backend agents

### 7.2 Edit the Agent Prompt Templates

```bash
$EDITOR .claude/skills/team-build/references/workflow.md
```

The prompts that get sent to each agent live here. Tweak them to:
- Mention your project's conventions (naming, directory layout, style)
- Reference internal libraries or frameworks
- Add domain-specific checklists (e.g., "all PII access must be logged")

### 7.3 Commit Your Customizations

```bash
git add .claude/
git commit -m "Customize team-build for <project-name>"
git push
```

Now your customized skill travels with the repo. Anyone who clones the repo (or pulls the branch) gets your project-specific team.

---

## 8. Troubleshooting

### 8.1 `gh repo create --template` Fails
```
error: template repository not found
```
**Fix:** Make sure the template name is exactly `robmarano/claude-dev-team-build-template`. Verify with:
```bash
gh repo view robmarano/claude-dev-team-build-template
```

### 8.2 Claude Code Doesn't See the Skill

```bash
claude
# > What skills are available?
# (no team-build in the list)
```

**Diagnostic commands:**
```bash
# Check the skill files exist
ls -la .claude/skills/team-build/SKILL.md

# Check you're in the project root
pwd

# Check the SKILL.md has valid frontmatter
head -6 .claude/skills/team-build/SKILL.md
```

**Fix:** Ensure you're running `claude` from the project root (where `.claude/` lives). Claude Code only discovers project-local skills when launched from within the project.

### 8.3 A Phase Fails Mid-Workflow

Claude will report the failure with details. Common causes:

- **Ambiguous task description** → Rewrite it with more specifics from `examples/task-template.md`
- **Unknown tech stack** → Mention the stack explicitly in your task description
- **Missing project context** → Ensure relevant files exist and are committed

To retry:
```
Please rerun team-build with the following revised task description: <new description>
```

### 8.4 Tests Fail After Team Build

The QA agents write tests, but they run in isolation — they can't always execute the tests themselves. If tests fail when you run them:

```bash
npm test  # or pytest, or mvn test, etc.
```

Ask Claude to fix them:
```
The tests in tests/unit/health.test.ts are failing with the following errors:
<paste errors>
Please fix them.
```

### 8.5 Agents Produced Conflicting Code

If Backend SDE-A and SDE-B produced code that doesn't integrate cleanly:
- This is what Phase 3 (cross-review) is for. If it happened anyway, the PM's work item split was probably too interdependent.
- Ask Claude to merge/reconcile: `Resolve the conflict between <file1> and <file2>.`
- For next time, write task descriptions that make the parallelizable split obvious.

### 8.6 Too Expensive / Too Slow

The full workflow can use 150-300k tokens per feature. For cost control:
- Use adaptive workflows — for backend-only or frontend-only work, ask Claude to skip irrelevant phases
- For trivial changes, bypass the skill: `Just make this small change directly, no team-build needed.`
- Batch related small features into one `/team-build` call

---

## 9. Uninstall / Cleanup

### 9.1 Remove the Skill from Your Project

If you decide `team-build` isn't right for your project:
```bash
rm -rf .claude/skills/team-build
git add .claude/
git commit -m "Remove team-build skill"
git push
```

### 9.2 Delete the Entire Project Repo

Destructive — only do this if you're absolutely sure:
```bash
cd ..
rm -rf my-new-project
gh repo delete <your-username>/my-new-project --yes
```

### 9.3 Just Clean Up Local Clone (Keep GitHub Repo)

```bash
cd ..
rm -rf my-new-project
```

The repo on GitHub stays intact — you can re-clone anytime:
```bash
gh repo clone <your-username>/my-new-project
```

---

## Quick Reference: The Whole Workflow in One Block

```bash
# 1. Create and clone from template
gh repo create my-new-project \
  --template robmarano/claude-dev-team-build-template \
  --public --clone

# 2. Move in
cd my-new-project

# 3. Start Claude Code
claude

# 4. In Claude Code, run your first team build:
#    /team-build <your task description>

# 5. Exit Claude Code (Ctrl+D), review the work
git status
git diff
npm test   # or your test runner

# 6. Commit and push
git add .
git commit -m "Initial feature via team-build"
git push
```

That's it. You now have a working project built by an 8-agent principal-level development team.

---

## Further Reading

- **[README.md](../README.md)** — Template overview
- **[USER_GUIDE.md](../.claude/skills/team-build/USER_GUIDE.md)** — Comprehensive skill reference (14 sections)
- **[workflow.md](../.claude/skills/team-build/references/workflow.md)** — Detailed agent prompt templates
- **[first-task.md](../examples/first-task.md)** — 5 sample tasks to try
- **[task-template.md](../examples/task-template.md)** — How to write effective task descriptions

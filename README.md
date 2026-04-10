# claude-dev-team-build-template

A Claude Code skill template that orchestrates a full integrated development team of 8 specialized AI agents through a phased workflow.

Use this repository as a **GitHub template** — click the "Use this template" button to spin up a new project that ships with a ready-to-run `team-build` skill, sample directory structure, and documentation.

---

## What You Get

When you click "Use this template" and create a new repo from this one, you get:

- **Four pre-installed Claude Code skills:**
  - `team-build` — orchestrates a full 8-agent principal-level dev team
  - `github-kanban` — agile/kanban ticketing via `gh project` CLI
  - `jira-agile` — JIRA Cloud ticketing via `jira-cli`, `acli`, or REST API
  - `ticketing-setup` — first-run interview that helps you choose and configure one of the ticketing systems
- **First-run auto-setup** via a SessionStart hook — when you first open Claude Code in your cloned project, it detects no ticketing is configured and walks you through setting up either GitHub Projects or JIRA Cloud securely
- A sample project scaffold (`src/`, `tests/`, `docs/`, `examples/`)
- A comprehensive **user guide** at [`.claude/skills/team-build/USER_GUIDE.md`](./.claude/skills/team-build/USER_GUIDE.md)
- A sample first-use task in [`examples/first-task.md`](./examples/first-task.md) to try immediately
- Standard `.gitignore` and MIT license

---

## The Team

The `team-build` skill dispatches 8 principal-level specialized agents through a 5-phase workflow:

| Phase | Agent(s) | Role |
|-------|----------|------|
| **1. Specification** | Principal Product Manager (Technical) | Translates the user's task into an actionable spec with acceptance criteria and test strategy |
| **2. Parallel Implementation** | 2× Principal Backend SDE, 1× Principal Frontend SDE, 1× Principal DevOps Engineer | Implements backend, frontend, and infrastructure in parallel |
| **3. Cross-Review** | 2× Principal Backend SDE (swapped) | Each backend engineer reviews the other's code for correctness, security, edge cases, and integration |
| **4. Quality Assurance** | 2× Principal QA Engineer | One writes the test suite; the other reviews both the tests and the implementation code |
| **5. User Acceptance** | Business-Focused UAT Analyst | Validates the feature from an end-user perspective and gives a GO / GO-WITH-NOTES / NO-GO verdict |

Each role maps to a built-in Claude Code `subagent_type` (`pm-principal`, `sde-backend`, `sde-frontend`, `sde-devops`, `qa-principal`, `uat-business-user`) — no custom agent configuration required.

---

## Quick Start

### 1. Create Your Project from This Template
Click **Use this template** → **Create a new repository** on GitHub, or via CLI:
```bash
gh repo create my-new-project --template robmarano/claude-dev-team-build-template --public --clone
cd my-new-project
```

### 2. Verify Claude Code Can See the Skill
Open Claude Code in the project directory:
```bash
claude
```
Then ask:
```
What skills are available?
```
You should see `team-build` in the list.

### 3. Run Your First Team Build
Try the included sample task:
```
/team-build Add a health check endpoint at /health that returns service status and database connectivity
```

Or read [`examples/first-task.md`](./examples/first-task.md) for more ideas.

### 4. Read the Guides

**New to this template?** Start with the step-by-step CLI walkthrough:
- **[USING-THIS-TEMPLATE.md](./docs/USING-THIS-TEMPLATE.md)** — full CLI guide from prerequisites to first commit

**Ready to dig deeper?** The [`USER_GUIDE.md`](./.claude/skills/team-build/USER_GUIDE.md) covers:
- Detailed phase-by-phase mechanics
- A worked example (password reset flow)
- Adaptive workflows for backend-only, frontend-only, and small tasks
- Best practices for writing task descriptions
- Cost and performance considerations
- Troubleshooting and customization

---

## Repository Structure

```
.
├── .claude/
│   ├── settings.json                 # SessionStart hook config
│   ├── hooks/
│   │   └── check-first-run.sh        # Detects missing ticketing config
│   └── skills/
│       ├── team-build/               # Full dev team orchestration
│       │   ├── SKILL.md
│       │   ├── USER_GUIDE.md
│       │   └── references/workflow.md
│       ├── github-kanban/            # GitHub Projects via gh CLI
│       │   ├── SKILL.md
│       │   └── references/
│       │       ├── workflows.md
│       │       ├── reports.md
│       │       └── gh-project-cheatsheet.md
│       ├── jira-agile/               # JIRA Cloud via jira-cli/acli/curl
│       │   ├── SKILL.md
│       │   └── references/
│       │       ├── jira-cli.md
│       │       ├── acli.md
│       │       └── curl-rest.md
│       └── ticketing-setup/          # First-run interview skill
│           └── SKILL.md
├── src/                              # Your application source code
│   └── .gitkeep
├── tests/                            # Test suites (populated by QA agents)
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/                             # Project documentation
│   ├── USING-THIS-TEMPLATE.md        # Step-by-step CLI walkthrough for new users
│   └── ARCHITECTURE.md               # Architecture decisions log
├── examples/
│   ├── first-task.md                 # Sample task descriptions to try
│   └── task-template.md              # Template for writing good task descriptions
├── .gitignore
├── LICENSE                           # MIT
└── README.md                         # This file
```

---

## How the Skills Trigger

### `team-build`
Activates when you:
- Invoke the slash command: `/team-build <task description>`
- Ask Claude to "use the full dev team" or "run a team workflow"
- Describe a feature you want built end-to-end with engineering rigor

For small fixes or questions, the skill steps aside and Claude handles the task directly.

### `github-kanban` or `jira-agile`
Activates automatically when you mention tickets, boards, sprints, epics, or other agile concepts. The specific skill that triggers depends on which system you chose during first-run setup (stored in `.claude/.ticketing-config.json`).

### `ticketing-setup` (First-Run)
Runs automatically the first time you open Claude Code in a project cloned from this template. The `SessionStart` hook in `.claude/settings.json` detects the missing `.claude/.ticketing-configured` marker and injects a reminder asking Claude to run the setup interview. You'll be asked:
- GitHub Projects or JIRA Cloud?
- Which CLI tool (for JIRA: `jira-cli`, `acli`, or `curl`)?
- How to store credentials securely (OS keychain, direnv `.envrc`, or built-in config)?

Once complete, the marker file is created and the reminder won't appear again. To reconfigure later, run `/ticketing-setup`.

---

## Prerequisites

- [Claude Code CLI](https://claude.com/claude-code) installed and authenticated
- Git
- (Optional) `gh` CLI for creating repos from this template

Claude Code ships with the specialized subagent types used by this skill — no extra installation needed.

---

## Customizing the Team

Not every project needs all 8 roles. The skill supports adaptive workflows:

- **Backend-only project** → skip frontend
- **Frontend-only project** → skip backend + cross-review
- **Small bug fix** → reduce to PM → 1 SDE → 1 QA → UAT

To add, remove, or replace roles permanently, edit:
- `.claude/skills/team-build/SKILL.md` — workflow overview and phase structure
- `.claude/skills/team-build/references/workflow.md` — detailed prompt templates

See the [Customization section of the User Guide](./.claude/skills/team-build/USER_GUIDE.md#12-customization) for step-by-step instructions.

---

## Contributing

This is a template repository. If you have improvements that would benefit all users of this template:

1. Fork this repo (not your derived project)
2. Make your changes
3. Open a PR against `robmarano/claude-dev-team-build-template`

For changes specific to your project, just edit the skill files in your derived repo — they're yours to customize.

---

## License

MIT — see [LICENSE](./LICENSE).

---

## Acknowledgments

Built for [Claude Code](https://claude.com/claude-code), Anthropic's agentic coding CLI. The skill leverages Claude Code's built-in specialized subagent types to compose a coordinated engineering team.

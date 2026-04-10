#!/usr/bin/env bash
#
# check-first-run.sh — Claude Code SessionStart hook
#
# Detects whether this project (derived from claude-dev-team-build-template)
# has had its ticketing system configured yet. If not, it injects a system
# reminder telling Claude to run the ticketing-setup skill before proceeding
# with other work.
#
# The hook outputs text to stdout, which the harness injects into Claude's
# context as "additional session information." Claude should read the reminder
# and act on it.
#
# Exit 0 always — this hook is informational, not blocking.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MARKER_CONFIGURED="$PROJECT_DIR/.claude/.ticketing-configured"
MARKER_SKIPPED="$PROJECT_DIR/.claude/.ticketing-skipped"

# If either marker exists, ticketing is already handled — no reminder needed.
if [ -f "$MARKER_CONFIGURED" ] || [ -f "$MARKER_SKIPPED" ]; then
  exit 0
fi

# Only show the reminder if the ticketing-setup skill is actually available.
# This prevents spurious reminders in projects that removed the skill.
if [ ! -f "$PROJECT_DIR/.claude/skills/ticketing-setup/SKILL.md" ]; then
  exit 0
fi

cat <<'REMINDER'
FIRST-RUN TICKETING SETUP NEEDED

This project is derived from the claude-dev-team-build-template and has not
yet been configured with a ticketing system. Before proceeding with other
work (especially team-build invocations), please run the ticketing-setup
skill to interview the user and configure either GitHub Projects or JIRA
Cloud for agile ticketing.

To run it: invoke the ticketing-setup skill via the Skill tool.

Once the setup is complete, the skill will create a marker file at
.claude/.ticketing-configured and this reminder will not appear again.

If the user prefers to skip ticketing setup entirely, they can tell you to
skip it, and you should create an empty marker file at
.claude/.ticketing-skipped to suppress this reminder permanently.
REMINDER

exit 0

# Your First Team Build

This file contains sample task descriptions you can use to try out the `team-build` skill right away. Pick one that matches the kind of project you're starting, or use them as inspiration for writing your own.

---

## Sample 1: Simple Backend (Tests Adaptive Workflow)

A small task that exercises the skill without running the full 8-agent team. The PM should recognize this doesn't need a frontend or extensive cross-cutting work.

```
/team-build Add a health check endpoint at /health that returns 200 OK with
a JSON payload showing service name, version, uptime in seconds, and
database connectivity status (connected/disconnected).
```

**Expected phases:** PM → 1 Backend SDE → DevOps (minor) → QA (writer only) → UAT

---

## Sample 2: Full-Stack Feature (Full Team Workflow)

A medium task that runs the entire pipeline with all 8 agents.

```
/team-build Build a user profile page where authenticated users can view
and edit their display name, avatar image, and bio. The backend should
expose GET /api/users/me and PATCH /api/users/me endpoints. The frontend
should have form validation (display name 2-50 chars, bio 0-500 chars)
and show a loading state during save. Avatar uploads go to S3 via
presigned URL. Rate limit PATCH to 10/minute per user.
```

**Expected phases:** PM → 2 Backend (profile + avatar upload) + Frontend + DevOps → Cross-review → QA (writer + reviewer) → UAT

---

## Sample 3: Data Pipeline (Backend + DevOps Heavy)

A backend-heavy task that emphasizes infrastructure and data correctness.

```
/team-build Create a daily batch job that ingests CSV files from S3,
validates each row against a schema (required fields, type checks,
referential integrity with existing User and Product tables), loads
valid rows into a Postgres staging table, and writes invalid rows to
a separate error bucket with error reasons. Failed jobs should alert
via PagerDuty. Use our existing Airflow cluster.
```

**Expected phases:** PM → 2 Backend (validation + loader) + DevOps → Cross-review → QA (writer + reviewer) → UAT

---

## Sample 4: Frontend-Only Refresh

A frontend-heavy task that skips backend implementation.

```
/team-build Redesign the dashboard landing page. Current version is
cluttered. New design should: (1) show a hero section with the user's
3 most important KPIs in large cards, (2) replace the sidebar with a
top nav, (3) add a "recent activity" feed on the right. Use our
existing design tokens from src/styles/tokens.ts. Must work on mobile.
```

**Expected phases:** PM → Frontend SDE → QA (writer + reviewer) → UAT

---

## Sample 5: Security Feature

A task where security concerns dominate and UAT/cross-review matter most.

```
/team-build Add two-factor authentication via TOTP. Users should be able
to enable 2FA from their security settings page by scanning a QR code
with an authenticator app (Google Authenticator, Authy). Generate
backup recovery codes (10 codes, one-time use). Enforce 2FA on login
with a 6-digit code entry page. Store TOTP secrets encrypted at rest.
Lock accounts after 5 failed 2FA attempts for 15 minutes.
```

**Expected phases:** Full team. Cross-review will be especially valuable here — security code benefits most from a second set of eyes.

---

## Writing Your Own Task

See [`task-template.md`](./task-template.md) for a template you can fill in. The quality of the team's output depends heavily on the quality of your task description — specific, constrained, and outcome-focused descriptions produce the best results.

### Quick Tips

- **Describe WHAT, not HOW.** Let the engineers choose the implementation details.
- **Mention existing code or systems** the team should integrate with.
- **Call out what's OUT of scope** to prevent the team from over-building.
- **Include constraints** like rate limits, performance budgets, or compliance requirements.
- **State the success condition** — how will you know it's working?

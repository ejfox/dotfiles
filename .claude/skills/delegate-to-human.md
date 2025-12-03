---
name: delegate-to-human
description: Create a Things task when the robot encounters something only a human can do
---

# Robot → Human Delegation Protocol

When you (Claude) encounter a task that requires human action, use the Things MCP to create a task instead of just mentioning it.

## When to Delegate

**Delegate when the task requires:**
- Manual signup/authentication (OAuth, API keys, account creation)
- Financial decisions (purchases, subscriptions, payment methods)
- Personal judgment calls (design choices, naming, priorities)
- Physical actions (restarting hardware, pressing buttons)
- Legal/sensitive decisions (ToS acceptance, data sharing)
- Actions blocked by permissions/access (private repos, restricted APIs)

**Don't delegate:**
- Things you can do with available tools
- Research or information gathering
- Code writing or file operations
- Things already in progress

## Task Format

When creating the delegation task:

**Title:** Brief, action-oriented (starts with verb)
- ✅ "Sign up for Vercel account"
- ✅ "Choose color scheme for dashboard"
- ❌ "We need to sign up"
- ❌ "Color scheme"

**Notes:** Include context and why
```
Context: Building deployment pipeline for website2 project
Why needed: Need Vercel API key to automate deploys
Robot blocked at: Unable to complete OAuth without browser interaction
Next step: Visit vercel.com/signup and create API token
```

**Project:** Match the work context
- For coding: "Development"
- For config: "System Setup"
- For decisions: "Planning"
- Default: "Inbox"

**Tags:** Always include "🤖 Robot Request"

**When:**
- Urgent blockers → Today
- Nice-to-haves → Anytime
- Future needs → Someday

## Example Delegation

```
ROBOT: "I need to deploy to Vercel, but I don't have API credentials. Let me delegate this to you..."

[Creates task in Things]:
Title: "Sign up for Vercel and generate API token"
Notes: "Context: Deploying website2 project
Why: Need API key for automated deploys via GitHub Actions
Robot blocked at: OAuth flow requires browser
Next steps:
1. Visit vercel.com/signup
2. Create account
3. Generate API token at vercel.com/account/tokens
4. Save token to ~/.env as VERCEL_TOKEN"
Project: Development
Tags: 🤖 Robot Request
When: Today
```

## Tone & Communication

**When delegating, be:**
- Matter-of-fact (not apologetic)
- Clear about what's blocking progress
- Specific about next steps
- Slightly cheeky about the role reversal

**Good examples:**
- "This requires your meat-space intervention. Created task in Things."
- "Encountered a human-only operation. Delegated to your task list."
- "Need your opposable thumbs for this one. Task created."

**Avoid:**
- "Sorry, I can't do this..."
- "Unfortunately, you'll need to..."
- Being overly robotic or formal

## Usage

The robot should proactively use this when blocked, but you can also explicitly invoke:

```
User: "Why isn't the deployment working?"
Robot: "Missing Vercel credentials. I've delegated the signup to your task list."

User: "@delegate-to-human we need to pick colors"
Robot: "Created task for color scheme selection with context from current design system."
```

---

*Protocol established: December 3, 2025*
*Status: Operational and slightly amusing*

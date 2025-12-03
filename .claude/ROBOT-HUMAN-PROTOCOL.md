# Robot → Human Delegation Protocol

**Status:** Active
**Skill:** `@delegate-to-human`
**MCP Required:** Things (`@wenbopan/things-mcp`)

## Overview

When Claude encounters tasks that require human action (OAuth flows, purchase decisions, physical actions), it can create Tasks in Things.app instead of just mentioning the blocker.

## Why This Rules

1. **Tasks don't get forgotten** - Goes straight to your GTD system
2. **Clear context** - Task notes explain what/why/how
3. **Role reversal humor** - Robot delegating to human
4. **Unblocks progress** - Robot continues with what it CAN do

## Quick Reference

**When Claude hits a blocker:**
```
❌ OLD: "You'll need to sign up for X service to continue..."
✅ NEW: "Need your meat-space intervention for signup. Task created in Things."
```

**Task appears in Things with:**
- Clear action-oriented title
- Context explaining why
- Next steps for completion
- Tagged with "🤖 Robot Request"
- Scheduled appropriately (Today/Anytime/Someday)

## Examples

### Blocker: OAuth/Signup Required
```
User: "Deploy to Vercel"
Claude: "Missing Vercel credentials. I've delegated the account setup to your task list."

[Things task created]:
Title: Sign up for Vercel and generate API token
Notes: Context: Deploying website2 project
       Need API key for automated deploys
       Steps: vercel.com/signup → generate token → add to ~/.env
Project: Development
Tags: 🤖 Robot Request
When: Today
```

### Blocker: Human Decision Required
```
User: "Improve the UI colors"
Claude: "Color choices require your aesthetic judgment. Created task for design review."

[Things task created]:
Title: Choose color scheme for dashboard UI
Notes: Context: Refactoring components in website2
       Current: vulpes red theme
       Consider: Accessibility, brand consistency
       File: src/components/Dashboard.vue
Project: Development
Tags: 🤖 Robot Request, Design
When: Anytime
```

### Blocker: Physical/Hardware Action
```
User: "Why isn't the printer working?"
Claude: "Printers require opposing physical manipulation. Task created for troubleshooting."

[Things task created]:
Title: Check printer connection and paper tray
Notes: Context: Print job failed for document.pdf
       Robot limitations: No physical actuators
       Try: Power cycle, check USB/WiFi, refill paper
Project: Inbox
Tags: 🤖 Robot Request
When: Today
```

## Skill Usage

**Automatic (recommended):**
Claude proactively creates tasks when blocked

**Explicit invocation:**
```bash
@delegate-to-human <describe what needs human action>
```

**In conversation:**
```
User: "We need to pick a name for this project"
Claude: "@delegate-to-human project naming decision"
[Task created in Things]
```

## Configuration

**Location:** `~/.claude/skills/delegate-to-human.md`

**Dependencies:**
- Things MCP server (`@wenbopan/things-mcp`)
- Things.app running on macOS

**Verify setup:**
```bash
claude mcp list
# Should show: things: npx -y @wenbopan/things-mcp - ✓ Connected
```

## Tone Guidelines

**Be slightly cheeky about the role reversal:**
- "Need your meat-space intervention"
- "Requires opposable thumbs"
- "Encountered a human-only operation"
- "Delegated to your superior biological processing"

**But stay professional and clear:**
- Always explain what's blocking progress
- Provide specific next steps
- Give enough context to complete the task
- Set appropriate urgency

## Related

- Things MCP: https://www.robotonwheels.com/projects/things-mcp
- Claude Skills docs: https://code.claude.com/docs/en/skills
- MCP backup: ~/.dotfiles/.claude/MCP-RESTORE.md

---

*Because sometimes the robot needs to delegate to the human.*

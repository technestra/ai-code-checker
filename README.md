# ai-code-checker

Claude Code skill + agents that review AI-generated code before you push: finds duplicate code, dead code, bugs, security issues and missing tests, returns PASS / NEEDS_CHANGES, and an opt-in fixer agent applies only the fixes you approve.

AI-written code tends to repeat itself, leave dead code behind and skip tests. This checks the code before it leaves your machine, and it works in any project because it installs once into your Claude Code setup.

## What you get

| Piece | What it does |
|---|---|
| **Skill** `ai-code-checker` | The review rules. Run it with `/ai-code-checker`, or Claude offers it before a push, merge or deploy. |
| **Agent** `ai-code-checker` | The same review in its own context, for big diffs. Read-only, returns one report. |
| **Agent** `ai-code-fixer` | Fixes only the report items you approve. Never commits or pushes. |

## What it checks

1. Duplicate and near-duplicate logic, with the existing code you could reuse
2. Dead code: unused imports, variables, functions, commented-out code
3. Bugs and missed edge cases
4. Security: hardcoded secrets, injection, missing auth checks, unvalidated input
5. Performance: N+1 queries, unbounded queries, repeated calls
6. Naming and project conventions
7. Missing tests

It compares your branch against `origin/<base>` (after `git fetch origin --prune`), not a possibly stale local `main`, and reports what is still unpushed.

Report format:

```
## ai-code-checker report
Reviewed: <files / diff range>   Method: <manual | jscpd | tests run?>
Base: origin/main @ <sha>   Head: <sha>   Unpushed commits: <n>

### BLOCKING (must fix before push)
### WARNING (should fix)
### NOTE (optional)
### Not checked

Verdict: PASS | NEEDS_CHANGES
```

Any BLOCKING item (hardcoded secret, injection, missing auth on a changed route, a definite crash) means `NEEDS_CHANGES`.

## Install

Restart Claude Code after installing.

### 1. As a Claude Code plugin

```
/plugin marketplace add technestra/ai-code-checker
/plugin install ai-code-checker@ai-code-checker
```

Plugin components are namespaced: `/ai-code-checker:ai-code-checker`, `@agent-ai-code-checker:ai-code-checker`, `@agent-ai-code-checker:ai-code-fixer`.

### 2. With the install script

Copies the skill to `~/.claude/skills/` and the agents to `~/.claude/agents/`. It refuses to overwrite an existing install unless you force it.

```powershell
# Windows
git clone https://github.com/technestra/ai-code-checker.git
cd ai-code-checker
.\install.ps1            # add -Force to overwrite
```

```sh
# macOS / Linux
git clone https://github.com/technestra/ai-code-checker.git
cd ai-code-checker
./install.sh             # FORCE=1 ./install.sh to overwrite
```

### 3. By hand

Copy `skills/ai-code-checker/` into `~/.claude/skills/` and the two files in `agents/` into `~/.claude/agents/`.

### Claude Desktop

The **Code** tab of the Claude desktop app is Claude Code, so this works there too. Install with method 2 or 3, then open a **new** Code session and:

- type `/ai-code-checker` (or type `/` and pick it from the list)
- mention an agent with `@`, for example `@agent-ai-code-checker review the changes against main`

Notes:

- It needs `git` on your `PATH`. On Windows, Desktop does not read PowerShell profiles, so set `PATH` in your user environment variables and restart Desktop. If PowerShell blocks the script, run `powershell -ExecutionPolicy Bypass -File .\install.ps1`.
- The Code tab also has a plugin browser (**+** next to the prompt box, then **Add plugins**). Whether it can add a GitHub marketplace depends on your app version; if it cannot, use the install script. Plugins are not available in WSL sessions.
- The **Chat** and **Cowork** tabs do not read `~/.claude`: their skills come from your claude.ai account, and subagents are a Claude Code feature. This tool is for the Code tab, the CLI and the IDE extensions.

## Use it

```
/ai-code-checker                       # review the current branch
/ai-code-checker src/routes/auth.js    # review one file or folder
```

Before a `git push`, merge, release or deploy, Claude asks once: **"ai-code-checker chalau? (yes/skip)"** (the wording is in `SKILL.md`, change it if you like). If the verdict is `NEEDS_CHANGES`, it does not push until you say so.

With the agents (install method 2, names without the plugin prefix):

```
@agent-ai-code-checker review the changes against main
@agent-ai-code-fixer fix W1 from the report   (paste the report in the same message)
```

Subagents run in their own context and cannot see your chat, so paste the report you want fixed. They also cannot ask you questions, so anything uncertain comes back as "Skipped".

## Limits, honestly

- The review is read-only because its instructions say so. The reviewer agent has Bash for `git` and test commands, so this is not a technical lock. For a hard gate, add a `PreToolUse` hook on `git push`.
- "Ask before pushing" is an instruction to Claude, not a hook. If it is ever skipped, run `/ai-code-checker` yourself.
- The skill hands security checks to `secure-code-review`, `api-security`, `secrets-management`, `owasp-top-10-web`, `dependency-scanning` and `iam-review` / `rbac-design` **if you have them installed**. Without them it applies the same checks itself and says so under "Not checked".
- `npx jscpd` (copy-paste detector) is offered for big changes and only run after you agree. Without it, duplicates are found by reading and searching.
- It does not run your tests unless the project has a safe test command, and it says when it did not. Do not point test runs at a live database.
- This is a review aid, not a security audit.

## Try it

`examples/sample.js` is deliberately bad: a duplicate function, an unused import, SQL injection, a hardcoded key (fake) and no tests.

```
/ai-code-checker examples/sample.js
```

## License

MIT, see [LICENSE](LICENSE). Copyright (c) 2026 Wheatron Technologies.

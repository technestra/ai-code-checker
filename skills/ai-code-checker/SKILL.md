---
name: ai-code-checker
description: Review AI-generated code before commit, push, merge, release or deploy. Detects duplicate and near-duplicate logic, dead code, bugs, security issues, performance problems and missing tests, then gives a PASS / NEEDS_CHANGES verdict. Use when the user runs /ai-code-checker, asks to review changes or check for duplicate code, OR is about to git push, merge, release, deploy or go to production (in that case ask first, see "When to run").
---

# AI Code Checker

Read-only pre-push review. Never modify code during the review. Fix only after the user asks.

## When to run

- User invokes `/ai-code-checker` or asks for a review / duplicate check: run it.
- User (or you) is about to `git push`, open/merge a PR, release, deploy or go to production, and this review has not run on the current changes: STOP and ask once: **"ai-code-checker chalau? (yes/skip)"**. Wait for the answer.
  - yes: run the review, show the report, push only after the user reads the verdict.
  - skip: continue without review; do not ask again for the same push.
- If the verdict is NEEDS_CHANGES, do not push or deploy until the user says to proceed anyway.

## 1. Find what to review

- In a git repo, find the base: `git symbolic-ref --short refs/remotes/origin/HEAD` (else `origin/main`, else `origin/master`). Run `git fetch origin --prune` first. It only updates remote-tracking refs, never the user's files. If the fetch fails, carry on with the existing `origin/*` refs and list "not fetched" under "Not checked".
- Compare against `origin/<base>`, never the local base branch, which is often stale. If local `<base>` differs from `origin/<base>`, say so in one line.
- Then review: `git status --short`, `git diff` plus `git diff --cached`, and `git diff origin/<base>...HEAD` for the commits on this branch.
- What is still to be pushed is `git log HEAD --not --remotes` (commits that no remote branch has yet; it works even when the branch has no upstream). If that is empty and there are no local changes, say "nothing to push" and ask which commits or paths to review instead.
- Always record `origin/<base>` and `HEAD` as short SHAs for the report header.
- A path argument (file/folder) overrides the diff: review exactly that.
- Not a git repo and no path: ask which files. Never review the whole repo unprompted.
- Skip generated and vendored files: lockfiles, `node_modules`, `dist`, `build`, `.next`, minified files.

Read each changed file fully, not just the hunks, so you can see what it duplicates elsewhere.

## 2. Checks

1. **Duplicates:** search the rest of the codebase (Grep/Glob) for existing functions, components, hooks, API calls, constants and types that do the same thing as the new code. Also look for copy-pasted blocks and near-duplicates inside the changed files. Suggest reusing the existing one or extracting one shared helper. Name both locations with `file:line`.
2. **Dead code:** unused imports, variables, parameters, functions, components, unreachable branches, commented-out code, leftover debug logs.
3. **Bugs:** null/undefined, empty arrays, 0, negative numbers, off-by-one, async/await mistakes, unhandled promise rejections, swallowed errors, race conditions, wrong return paths, undefined references.
4. **Security:** hardcoded secrets/keys/tokens, injection (SQL/NoSQL/command), XSS, unvalidated input, missing auth/authorization checks, unsafe file handling, logging of secrets or PII.
5. **Performance:** N+1 queries, unbounded queries without limit/pagination, repeated identical API calls, work inside loops that belongs outside, missing timeouts.
6. **Naming and conventions:** names that mislead, style that differs from neighbouring code.
7. **Tests:** new or changed logic with no test; no negative-path or edge-case tests. If the project has a test command, run it and report the real result. If you did not run it, say so.

## 3. Delegate security, do not redo it

Call these installed skills when the changes match, and fold their findings into the report:

| Changed code touches | Skill |
|---|---|
| any backend/frontend logic, input handling, auth | `secure-code-review` |
| API routes / endpoints | `api-security` |
| `.env`, tokens, keys, credentials | `secrets-management` |
| web app vulnerabilities (XSS, injection) | `owasp-top-10-web` |
| `package.json`, `requirements.txt`, other dependency manifests | `dependency-scanning` |
| roles / permissions | `iam-review` or `rbac-design` |

## 4. Optional duplicate tool

For larger changes, offer: `npx jscpd <path> --min-lines 5 --min-tokens 50`. Ask before running it, because `npx` may download a package. If it fails or the user declines, do the manual search in check 1 instead and say which method was used.

## 5. Report

Do not print the code back. For each finding give `file:line`, what is wrong, and the suggested fix in one line.

```
## ai-code-checker report
Reviewed: <files / diff range>   Method: <manual | jscpd | tests run?>
Base: origin/<base> @ <sha>   Head: <sha>   Unpushed commits: <n>

### BLOCKING (must fix before push)
- file:line - issue - fix

### WARNING (should fix)
- ...

### NOTE (optional)
- ...

### Not checked
- <anything skipped or not run, e.g. tests not run>

Verdict: PASS | NEEDS_CHANGES
```

Rules:
- Any BLOCKING finding means NEEDS_CHANGES. Hardcoded secrets, injection, missing auth on a changed route, and definite crashes are always BLOCKING.
- Only report what you actually saw in the code. Mark uncertain items "possible" and say why you are unsure.
- If nothing is found, say PASS and list what was checked. Do not invent findings.
- End with: "Fix karun? Bolo kaunse items." and wait.

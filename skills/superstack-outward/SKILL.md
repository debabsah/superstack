---
name: superstack-outward
description: Going public — a push, PR creation or merge, a package publish, a release, an infra apply; run before any of them, and when the outward gate bounces a publish command. Writes the sweep receipt the gate checks. Skip for purely local work.
---

# superstack-outward

Publishing is the one moment a mistake stops being reversible. The sweep checks what is about to ship — the delta, not the world — then writes a receipt so the outward gate lets the publish through. Every step prints what it found; "found nothing" is a result, stated with the command that looked.

## The sweep

1. **Secrets.** `gitleaks detect` if installed; otherwise grep the outgoing diff/files for key patterns (`-----BEGIN`, `api[_-]?key`, `token=`, passwords, connection strings). Any hit stops the publish until resolved — this step fails closed.
2. **Identity and AI traces.** Grep the outgoing content for AI-authorship trailers, model names, machine paths, internal usernames/emails that don't belong in public history. Check the commits being pushed, not just the working tree.
3. **Confidential terms.** If `.superstack/project.md` lists protected terms (client names, internal hosts), grep the outgoing content for them; offer to record the project's terms if none are listed and this repo has an employer/client context.
4. **Stale public claims.** Read what ships as a stranger would: version numbers, counts, "works on X" claims, install commands — spot-check each against the current tree. A README claim is a `Verified:`-grade claim.
5. **Repo-level extras** (first publish or plugin/package release): install/clone cold in a temp dir and confirm the documented entry path works.

## The receipt

Append one line to `.superstack/outward-pass`:

```
<YYYY-MM-DD HH:MM> swept: <what was covered> — findings: <n fixed / none>
```

The gate accepts a receipt for 60 minutes, then re-requires the sweep. Then retry the publish command. If the gate bounced something that genuinely isn't a publish, retrying the identical command passes once — and that override is logged to `.superstack/outward-log`, so a recurring override is a gate bug to report, not a habit to keep. One sanctioned exception: an incident mitigation (superstack-incident step 1) *is* a publish and overrides anyway — those entries are expected, noted in the incident's timeline, and its sweep runs at stability rather than before.

## Proportion

Scope the sweep to what ships: a docs-only push earns steps 2 and 4 on the docs; a first public release earns all five. Never claim a step you didn't run — the receipt line lists what was actually covered.

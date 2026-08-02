---
name: superstack-doctrine
description: A correction or standing ruling from the user — a rebuke of a working habit, "make this a rule", "always do X", "never do Y again". Mint the statute BEFORE giving the substantive reply. Also to review or amend standing law. Skip for one-off task instructions that don't outlive the turn.
---

# superstack-doctrine

Corrections become standing law, and the law gets surfaced where habits can't be trusted to remember it. Statutes live in `.superstack/doctrine.md`; a SessionStart hook surfaces the count and newest title every session.

## Minting (write-ahead)

The moment a correction or ruling lands, **write the statute before composing your substantive reply** — the reply comes second. Append to `.superstack/doctrine.md`:

```
## <YYYY-MM-DD> — <short imperative title>
> verbatim: "<the user's own words, quoted exactly>"
scope: <when this binds — the action class, not "always">
supersedes: <#none, or the dated title it replaces>
reopens-if: <the condition that would re-open this, or "none foreseen">
```

Announce the mint in one line ("statute added: <title>"). Create the file with a `# doctrine` header on first use.

## The rules of the law

- **Append-only.** Never edit or delete a statute. To change one, add a new statute citing what it supersedes — the history is the point.
- **Scope is an action class** (publishing, option menus, commit style), never "always" — an unscoped law can't be checked and won't fire.
- **A ruling without a reopen condition drifts toward dogma.** Every statute carries `reopens-if` — the observation that would make it worth re-examining; "none foreseen" is legal and honest, a blank is neither.
- **Statutes bind until the owner lifts them.** When acting inside a statute's scope, comply or escalate to the user — never silently override. A user instruction that contradicts a statute is an escalation moment: name the conflict, let them rule (that ruling is usually the next statute).
- **Mint on corrections, not preferences you infer.** A statute needs the user's words; if you only suspect a standing preference, ask — the answer is the quote.
- **Prune what never fires.** If a statute's scope hasn't occurred for months, propose retiring it at a `superstack-ship` overlay compaction — with the user, not unilaterally.

## Boundary with the overlay

Gotchas (trap → cause → rule, discovered by work) go to `.superstack/project.md` per the method's overlay protocol. Doctrine holds *the user's rulings* — the things a future session must not relitigate. When one event yields both, write both and cross-reference.

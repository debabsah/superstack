---
name: superstack-queue
description: Parked work — "park this", "add it to the backlog", "someday", a shaped idea inception parks, a deferral with a revisit trigger; read the queue first when starting fresh work. Also on "what's parked". Skip for work starting now.
---

# superstack-queue

Session ten resumes in-flight work sharply but forgets the backlog it decided mattered. The queue is that memory: one page of parked work, each entry carrying why it mattered and when to look again.

## Intake (capture costs one bullet; losing it costs the idea)

Append to `.superstack/queue.md`:

```
- Q<n> (<date>) <item> — why: <value hypothesis> — revisit: <trigger or date>
```

- **Deferrals fold in here too.** A review's "defer" finding, a task file's deferred item, an inception "park" — same grammar, `why:` names what it was deferred from. One artifact, not three.
- The `why:` is the value hypothesis in one clause — it's what lets a future session judge the entry without re-deriving it.
- The `revisit:` is a trigger ("after launch", "if X recurs") or a date — never blank; an entry with no revisit condition is a wish, not a plan.

## Choose (starting fresh work)

Read the queue before scoping something new. Choosing *against* it is fine — but conscious: if the new work outranks every parked item, that's information; say so in one line. **The human owns priority (R6): the queue records and reminds — it never ranks, never nags beyond its one session-start line.**

## Resolution and expiry

- Taken up: append `[taken <date> → <task-slug>]`. Dead: append `[dropped <date> — <reason>]`. Append-only; resolved entries stay as the record of what was considered.
- **Retiring shipped work lands here too:** deprecating or archiving an artifact gets a tombstone — `- Q<n> (<date>) retired <artifact> — why: <reason> — successor: <pointer or none> [retired <date>]` — born resolved (the `[retired]` marker closes it at birth; a tombstone needs no revisit line), plus a deprecation note in the artifact's own docs pointing at the successor, written *before* the archive act.
- **Expiry toward doubt:** at overlay compaction, an entry untouched past ~90 days gets a `stale:` marker *after its ID* — `- Q<n> (<date>) stale: <item> …` — never before the `Q` (the session-start counter reads `^- Q`; a marker in front erases the entry from the count). A parked "urgent" does not stay confidently urgent. Reviving a stale entry means re-checking its `why:` still holds, not just resuming it.
- Keep it to a page: when it sprawls, that's a compaction trigger — dead weight gets `[dropped]` with reasons, with the user, not unilaterally.

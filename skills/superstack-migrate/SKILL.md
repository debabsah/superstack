---
name: superstack-migrate
description: A schema or data change with real data behind it — DDL on a live table, a backfill, retyping/renaming columns, moving data between stores. Skip for empty schemas and rebuildable dev databases; code/dependency moves (superstack-deps); a live migration harming data (superstack-incident).
---

# superstack-migrate

A migration is verified **data survival**, not applied DDL. "The migration ran" proves the layer below the claim (R1); the claim is "every row arrived intact and every reader still works."

## The method

1. **Dossier first — into the task file** (`.superstack/tasks/<slug>.md`; T2 work has earned one). Current shape → target shape; row counts *now* (they're the reconciliation baseline); every query/consumer touching the affected objects — grep the callers (R2: the readers you didn't find are the outage).
2. **Expand → migrate → contract, never one move.** Add the new alongside the old, move the data, switch the readers, and only then drop the old. Each step ends at a checkpoint with a **named verification query** — counts, checksums, sample diffs — and its expected result written *before* running (superstack-debug's probe discipline: a check whose outcome you can't predict is a coin flip).
3. **Rollback is tested, not asserted.** Before anything destructive: state the rollback and prove it on a copy **sized so the proof transfers** (see step 5 — a fraction you name, not a toy) — or verify the backup actually restores. Checker-must-fail applies to backups: an unrestored backup is an unverified check (superstack-experiential).
4. **The destructive step is a one-way door.** DROP, DELETE, the contract step: prepared as the exact command and **handed to the human** — never fired by this session (superstack-execute's pattern, same reason). Tier: T2 minimum; production data is T3.
5. **Name the locks.** What lock each step takes and for how long at current row counts; anything that holds a lock through real traffic gets a batched/online strategy instead — "it worked on dev's 300 rows" is not evidence about prod's 30 million: green counts where the oracle says it counts.
6. **Ledger both halves of the survival claim:** `Verified: <n> rows migrated, checksums match — ran <query> -> saw <result>` **and** `Verified: readers still work — reran <the switched consumers' checks> -> saw <green>`. Counts and checksums alone are half a claim — the nightly job that used the dropped column fails at 2am. Prod numbers count in prod.

## Leave the record

Verification queries that will recur become overlay oracle rows; the schema decision that forced the migration is a superstack-decide record if anyone will later ask why. A migration you'd dread re-running is a migration whose record is incomplete.

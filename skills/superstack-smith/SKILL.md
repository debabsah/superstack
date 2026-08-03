---
name: superstack-smith
description: A new skill or pack for a superstack-family plugin — "new skill", "add a module", "build a pack for X" — or a recurring moment applying for admission. Skip for editing an existing skill (just edit, red-first near hooks) and product ideas that aren't skills (superstack-inception).
---

# superstack-smith

The smith is a **gatekeeper, not a generator** — it exists to make a bad skill hard to add. The standing law is "no module without its trigger"; the smith is that law's door, mechanized. An idea that fails a gate parks in the queue with `revisit: <the evidence wanted>` — parking is a pass-through outcome, not a rejection.

## The admission gates, in order

1. **The evidence line — first, non-negotiable.** What recurring *moment*, observed *where* (sessions, logs, the user's own words, a hand-rolled workaround on disk). A hunch parks; observed recurrence proceeds. The strongest evidence is a workaround the user already built by hand — it proves demand *and* sketches the shape.
2. **The moment names its action class** — build / design / publish / resume / correction / broken-live / choosing / reporting-out — never a session size, never a topic. The taxonomy check runs here: **topics get review lenses or oracle rows; rules get lines in an existing skill; only moments get runners.** Check both cheaper homes before minting a skill.
3. **Collision check, mechanically.** Run it, don't recall it:
   ```
   find skills ~/.claude/skills ~/.claude/plugins -name SKILL.md \
     -exec grep -h '^description:' {} + 2>/dev/null
   ```
   (`find` tolerates roots that don't exist on this machine — a shell glob does not: an unmatched glob aborts the whole command under zsh and returns a silent, empty "no collisions". Adjust roots as needed; follow symlinks to the real trees.) Then hunt the proposed trigger's verbs and nouns in the output. A real overlap means widen-or-point-at the existing skill instead. The nearest *sibling* goes in the new description's Skip clause **by name**; a third-party neighbor goes in as a **class with an example** — "a spec tool (e.g. another pack's `spec` skill) when installed" — never a bare dependency, so the description degrades gracefully on machines without the pack. Routing ambiguity is a dense skill environment's #1 scaling risk, and the Skip clause is its cheapest control.
4. **State check.** If it owns durable state, name its file under `.superstack/` (one ruled exception on record: superstack-decide's committed `docs/decisions/` — the README names it and says why) and its lifecycle — append-only? expiry? who compacts? **and who reads it** (a write with no reader is ritual) — and **reuse an existing grammar** (queue `Q<n>`, gates `G<n>`, value `V<n>`, task files, ledger tokens) before minting a new one. A bespoke new ledger format is a smell with a history here.
5. **Loop check.** Name where it hands off into the existing loop — scope, verify, ship, debug, queue, a premise ledger. A skill with no edge into the loop is an island, and probably a topic wearing a skill's clothes.
6. **Gate and injector check.** Needs session-start presence? Ride a task-file pointer (`<!-- task: <slug> — goal: … — next: … -->`) — the existing hook surfaces it *within its line budget*, so presence competes with other tasks; a `00-` filename prefix wins the sort when presence is critical. An actual hook edit is red-first with its suite, and kernel hooks change upstream only, never in place.

## Writing it (house shape)

- Frontmatter description: `Use when <the moment, concretely>… Also on "<name>". Skip for <nearest neighbor by name + the trivial case>.`
- Body ≤ ~40 lines: principle first, numbered steps, existing grammars **cited, not restated** — a runner echoes canon and adds only its delta (doctrine stated twice drifts apart).
- Packs live in their **own plugin**, never in this core — a daily driver carries no profession's specialty gear.

## Shipping it

`claude plugin validate .` green; the plugin's suites still green — **including `hooks/test-front-doors.sh`**, which mechanically asserts the new module's full name appears in every enumerated surface (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, the README table). The front door rots exactly when this step is a memory, and it did once (0.5.0's marketplace shipped saying "nine modules" with eighteen present) — hence the check, not the reminder. Then a DECISIONS.md entry (chose / rejected / who / reopens-if) records the admission — a module that can't say what evidence admitted it can't say what evidence would retire it.

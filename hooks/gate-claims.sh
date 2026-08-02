#!/usr/bin/env bash
# superstack — Stop-hook calibration gate (the deterministic half of the method).
# When the CURRENT TURN edited files and ends on a completion claim, require the
# claim to be calibrated: `Verified:` evidence, or an explicit `Assumed:`/
# `PROVISIONAL` label. It checks CALIBRATION, not truth — a grep cannot check
# truth; it can check that claim strength is labeled, and log enough to audit.
# Fail-open everywhere: any parsing doubt -> exit 0 (a missed bounce beats a
# trapped session). Loop-safe: continues from this gate always pass.
set +e

# The off switch (S4, trial-only D-15; dogfood/reduction-trial/PREREG.md §3):
# SUPERSTACK_GATES=off silences every superstack gate; `claims` keeps only
# this one; anything else — including unset — leaves all gates armed. Named
# in the bounce stderr and nowhere else: zero install-time questions.
case "${SUPERSTACK_GATES:-all}" in off) cat >/dev/null 2>&1; exit 0;; esac

payload="$(cat)"

# Loop guard — whitespace-tolerant (a serializer change must not defeat the
# script's only fail-closed path).
# Accepted, priced, and disclosed in the docs (0.6.1 review): this makes the
# gate a first-offence reminder, not a wall — the flag is true *because* this
# gate just blocked, so any second message passes however uncalibrated. A
# trapped session is the worse harm, so the trade stands. Deliberately NOT
# logging a YIELD line here: this is the one fail-closed path in the script and
# it stays minimal — observability is not worth work before this exit.
printf '%s' "$payload" | grep -qE '"stop_hook_active" *: *true' && exit 0

# The claim is judged on the payload's last_assistant_message — the supported
# field carrying the turn's complete final message (the docs recommend it over
# transcript reads; reconstructing it from transcript flush order once caused
# a live false fire). Field absent (older Claude Code) -> fail open.
last="$(printf '%s' "$payload" | grep -oE '"last_assistant_message": *"([^"\\]|\\.)*"' | head -n 1)"
[ -n "$last" ] || exit 0
# grep -oE returns the WHOLE match, field name included. Strip to the message so
# the gate-log snippet spends its budget on the claim rather than on a constant
# (0.6.1; a live log showed: snippet="last_assistant_message":"All done."). Only
# the log reads worse for it — the claim/negation/ledger greps below are
# unaffected either way, since the prefix carries none of their tokens.
last="$(printf '%s' "$last" | sed -E 's/^"last_assistant_message": *"//; s/"$//')"

# The field arrives JSON-ENCODED, and until 0.7.0 nothing decoded it. A newline
# is therefore a literal backslash followed by `n`, so a claim that begins its
# own line — the single most common shape of a real final message — had a WORD
# CHARACTER in front of it and `claimre`'s leading \b never matched.
# "Refactored the parser.\nDone." walked straight through. The mirror held too:
# a hedge split across lines could not be stripped by the negation pass (the
# filler class cannot match a backslash), so honest text bounced. Both
# directions were invisible because every fixture in the suite was one line.
last="$(printf '%s' "$last" | sed -E 's/\\[nrt]/ /g; s/\\"/"/g')"

# Negated statements are not claims ("not done yet" must not bounce). Judge a
# lowercased copy — BSD sed has no case-insensitive flag — with negated claim
# phrases stripped; the apostrophe class covers ' and multibyte ’ per byte.
#
# INVARIANT: every stem `claimre` recognises must appear in this terminal group.
# Widen one without the other and the gate bounces honest failure reports — it
# starts punishing the exact candour it exists to buy, which is worse than the
# miss it was closing. 0.6.1 shipped that regression for one commit: `succeeded`
# / `successfully` went into claimre alone, so "The deployment has not
# succeeded." bounced. Pinned now by the "does not fire" checks.
#
# 0.7.0 widened the gap between negator and stem from a closed list of adverbs
# to up to four ARBITRARY words, because the closed list only ever covered
# hedges with no verb in them. Everything a person actually writes when they are
# being honest carries one — "I don't THINK the tests pass", "I can't CONFIRM
# the migration succeeded", "no EVIDENCE that the build passes" — and all seven
# sampled phrasings bounced at 0.6.1, including a plain "Nothing is fixed yet."
# Six are pinned as non-firing; the seventh (a bare "I doubt this is done") is
# pinned as an accepted bounce, since `doubt` cost more as a negator than it
# bought. `\b` is used freely by `claimre` below because that is `grep -E`,
# which honours it on both platforms; only `sed` is the portability trap.
#
# The gap is applied NEAREST-STEM-FIRST, and that ordering is the whole
# correctness argument. A single pattern with `{0,4}` is matched leftmost-
# LONGEST, so a second stem inside the gap gets eaten with the first: "The tests
# are not passing but the build passes" stripped WHOLE and the real claim left
# with it. The negation swallowed the sentence it was supposed to leave
# standing — the same class of defect as the one this release opened with, in
# the mirror direction. Running gap 0 first consumes "not passing" while "build
# passes" is not yet a candidate. Do not collapse these five expressions back
# into one quantifier.
#
# The stem may absorb one FOLLOWING stem (`successful(ly)? deployed`), because
# nearest-first would otherwise stop at the adverb and leave the verb behind:
# "not successfully deployed" would strip to "deployed" and bounce.
judge="$(printf '%s' "$last" | tr '[:upper:]' '[:lower:]')"
# `doubt` and `unverified` are deliberately NOT negators: `doubt` matched "no
# doubt this is done", the strongest form of the claim, and `unverified` matched
# "the unverified path is fixed". A negator list assembled by sampling hedges
# picks up certainty intensifiers by string coincidence. The cost is that a bare
# "I doubt this is done" bounces, which asks for an Assumed: line — the cheap
# direction. `none( of)?` covers "None of the tests pass"; a partial-result
# report carrying no negator at all ("12 of 40 tests passed") is out of reach
# of a negation rule — it was priced HERE as an accepted bounce until S3
# (trial-only, D-15): the suppressor block after the claim match now strips a
# partial quantifier's clause, superseding that ruling. This sentence is the
# record of the supersession, not a live price.
negre="(no evidence|no longer|nothing|none( of)?|not|never|cannot|unclear|unsure|far from|[a-z]+n['’]+t)"
# Every stem `claimre` carries must appear here — including the two multi-word
# ones. `good to go` and `works now` were absent for three releases, so the two
# most deflated status reports in the vocabulary ("Nothing works now.") bounced.
negstem="(done|finished|implemented|completed?|fixed|resolved|pass(es|ed|ing)?|green|shipped|ready|succeeded|successful(ly)?|deployed|merged|pushed|live|good to go|works now|wrapped( up)?|(all )?set|up_and_running|work(s|ing)?( as expected)?|taken( care of)?|in good shape|no (known |remaining |outstanding )?(issues|errors|problems|failures))"
# Clause conjunctions become hard barriers before the strip runs, because the
# nearest-first ordering only protects the sentence when the negator's OWN stem
# sits at gap 0. When the negated word is not a stem — "isn't PERFECT but the
# tests pass" — the widest expression reaches across the clause and deletes the
# claim instead, and that failure is anti-correlated with candour: the more
# hedging preamble a message carries, the likelier its claim is erased. `doubt`
# is a barrier for the same reason it is not a negator ("no longer any doubt
# the migration succeeded" reached over it one synonym away). The filler class
# already cannot cross `.` or `;`, so promoting these words to `.` is the same
# mechanism, applied to the boundaries punctuation does not mark.
# One claim stem legitimately contains a conjunction: "up and running" would be
# split by the barrier promotion below and never match. Fuse it into a single
# token first; both stem lists carry the fused form.
judge="$(printf '%s' "$judge" | sed -E 's/up and running/up_and_running/g')"
judge="$(printf '%s' "$judge" | sed -E 's/ (but|and|however|although|though|whereas|otherwise|doubt) / . /g')"
# Every stem carries an explicit trailing delimiter, and the match is replaced
# by a space rather than deleted. Without it `completed?` matches the PREFIX of
# "completely", so the nearest-first pass strips "not complete" and leaves "ly
# done" — bouncing "This is not completely done." A word-boundary escape is not
# available here: BSD sed supports neither `\b` nor GNU's syntax, and it fails
# SILENTLY (matching nothing), which would disable the whole negation strip on
# macOS while every Linux check stayed green. Verified by running it, not by
# reading a man page.
judge="$(printf '%s' "$judge" | sed -E \
  -e "s/$negre $negstem( $negstem)?([^a-z]|$)/ /g" \
  -e "s/$negre( [a-z0-9'’-]+) $negstem( $negstem)?([^a-z]|$)/ /g" \
  -e "s/$negre( [a-z0-9'’-]+){2} $negstem( $negstem)?([^a-z]|$)/ /g" \
  -e "s/$negre( [a-z0-9'’-]+){3} $negstem( $negstem)?([^a-z]|$)/ /g" \
  -e "s/$negre( [a-z0-9'’-]+){4} $negstem( $negstem)?([^a-z]|$)/ /g")"

# Maintained phrase list, not an exhaustive one — the two-sided log below is its
# tuning data, and the docs say so rather than implying full recall. 0.6.1 added
# the classes a blind review proved were escaping: bare "tests pass" (the old
# pattern required a literal "all"), "suite is green", "succeeded",
# "successfully <verb>". "Successfully deployed" escaping meant a T3 action
# escaped the backstop entirely. ("checks out" was tried and removed: unlike
# every other stem its negation keeps the literal words — "not everything checks
# out" — so it false-bounced honest failure reports; see negre invariant.)
# Known accepted misses, priced deliberately: bare `works` is NOT a stem ("It
# works." is missed) because it false-fires on ordinary prose ("how it works by
# hashing"), and a conditional "whether the tests pass" DOES arm — at worst one
# spurious bounce demand, which the design law prices as acceptable.
#
# 0.7.0 added the bare past tense of the outward actions — `deployed`, `merged`,
# `pushed`, and a copula `is/are/now live`. 0.6.1 had closed only the adverbial
# form, so "Successfully deployed to staging." gated while "Deployed to
# production." did not: the T3 row of the tier table, the one the method ranks
# highest, was the least guarded phrasing in the list. `live` needs the copula
# because the bare word is ordinary prose ("the fixtures live in tests/").
# Prose cost accepted: "I merged the two helpers" now arms — a turn that edited
# files and reports work done with no evidence is a fair bounce.
#
# 0.8.0 added the conversational status-summary stems the round-2 study showed
# drifting while ledgered reports held: `wrapped up`, `all set` (also arms
# "all set up" — itself a completion claim), `up and running`, `works/working
# as expected`, `taken care of`, `in good shape`, and the negative-form vouch
# `no (known/remaining/outstanding) issues/errors/problems/failures` — "No
# issues found." claims exactly as hard as "Done." and had no stem. Each new
# stem is mirrored in negstem (standing invariant); the no-issues family sits
# in BOTH lists because it is a claim on its own and a strippable target when a
# real negator precedes it ("can't promise there are no issues"). Prose cost
# accepted: "no issues with A, but B is broken" arms on its first clause — a
# mixed report vouching for A ungated was the drift class itself.
claimre='\b(done|finished|implemented|complete|completed|fixed|resolved|passing|shipped|succeeded|deployed|merged|pushed|good to go|works now|all green|(is|are|now) live|(tests?|checks?|suite|build) (pass(es|ed)?|(are |is )?green)|successfully (ran|deployed|merged|pushed|applied|installed|migrated|completed|built|created|updated|fixed)|ready (to|for) (merge|ship|commit|deploy|push|review)|wrapped up|all set|up_and_running|work(s|ing)? as expected|taken care of|in good shape|no (known |remaining |outstanding )?(issues|errors|problems|failures)( (found|left|remain(ing)?))?)\b'
phrase="$(printf '%s' "$judge" | grep -oE "$claimre" | head -n 1)"
[ -n "$phrase" ] || exit 0

# ── False-bounce suppressors (S3, trial-only D-15; dogfood/reduction-trial/
# PREREG.md §3) — exactly the five classes F1-mechanical-recheck reproduced,
# nothing wider. Each strips its class from a COPY of the judged text; if no
# claim survives the strips, the message was claim-shaped only by imprecision
# and the gate stays silent. `claimre` itself is untouched (no general
# widening), and every suppressor rides beside the nearest claim that must
# keep firing in hooks/test-gate.sh, so none can quietly become a shield.
sup="$judge"
# Interrogative: a stem inside a question is a question, not a claim ("Should
# I mark this done?"). A declarative claim beside a question still arms.
sup="$(printf '%s' "$sup" | sed -E 's/[^.;!?]*\?/ /g')"
# Path/identifier boundary: a stem inside a slashed or dotted token is a name
# ("src/complete.ts is unrelated"), because \b happily matches around `/` and
# `.`. Sentence-final periods are safe: the dotted form needs a word
# character on BOTH sides of the dot.
sup="$(printf '%s' "$sup" | sed -E 's|[^[:space:]]*/[^[:space:]]*| |g; s/[a-z0-9_-]+\.[a-z0-9]+/ /g')"
# Partial numeric quantifier: "12 of 40 tests passed" reports a fraction, not
# completion — its clause goes. N of N or better stays a claim, so rounding a
# partial result up to totality is still gated.
for _q in $(printf '%s' "$sup" | grep -oE '[0-9]+ of [0-9]+' | tr ' ' '_'); do
  _a="${_q%%_*}"; _b="${_q##*_}"
  if [ "$_a" -lt "$_b" ] 2>/dev/null; then
    sup="$(printf '%s' "$sup" | sed -E "s/[^.;!?]*$_a of $_b[^.;!?]*/ /g")"
  fi
done
# Bare `no <noun>`: negre carries no bare `no` because of the "no doubt" trap,
# but `doubt` is barrier-promoted above, so the small gap here cannot reach
# across it — "No tests pass yet" is negation, "no doubt this is done" is not.
# The no-issues vouch family is safe by construction: its `no` lives inside
# the stem itself, and a bare noun is never a negstem.
sup="$(printf '%s' "$sup" | sed -E "s/(^|[^a-z0-9_-])no ([a-z0-9'’-]+ ){1,2}$negstem([^a-z]|$)/ /g")"
printf '%s' "$sup" | grep -qE "$claimre" || exit 0
# Mixed-clause honest report: a clause reporting live breakage beside the
# claim clause is candour — bouncing it is the harm the INVARIANT above names
# as worse than the miss. Stative markers only, tested per clause; a negated
# failure word is not a failure ("no longer broken" is a claim), and the
# claim's own clause never suppresses itself ("Fixed the broken build" arms).
failre='(is|are|was|were) +not([^a-z]|$)|\bnot *$|\bbroken\b|\bfail(s|ing)\b|\bstill (there|present|missing|red|failing)\b|\bunresolved\b|\bregress(es|ed|ing|ion)\b|\bdoes ?not work\b'
mixed="$(printf '%s\n' "$judge" | tr '.;!?' '\n\n\n\n' | while IFS= read -r _cl; do
  _cl="$(printf '%s' "$_cl" | sed -E "s/$negre( [a-z0-9'’-]+)? (broken|fail(s|ing)|unresolved|regress(es|ed|ing|ion))/ /g")"
  printf '%s' "$_cl" | grep -qE "$failre" || continue
  printf '%s' "$_cl" | grep -qE "$claimre" && continue
  echo hit; break
done)"
[ -z "$mixed" ] || exit 0

# Arm only if THIS turn changed something: after the last real user message,
# look for editing tools or a subagent dispatch (Task/Agent) — a subagent's own
# tool calls live in separate transcript files this gate never reads, so the
# dispatch is delegated work's only trace here, and its report is a claim
# (provenance rule). Sidechain lines never mark the turn boundary.
#
# The turn cut is computed over the WHOLE transcript. Until 0.6.1 this read
# `tail -n 600` and cut inside it; a turn longer than the window pushed its own
# edits out of view, no user line remained to cut on, and the gate failed open —
# silently, on exactly the long tool-heavy turns that edit early and claim at the
# end. The escape was correlated with the risk, and every fixture was 2-3 lines,
# so nothing caught it. Pinned now by "long turn still arms".
# Measured, not assumed: on a real 10MB transcript this runs ~0.315s vs ~0.687s
# for the 0.6.0 window version — the full scan is *faster*, because grep streams
# where `tail -n 600` seeks and then hands 600 multi-KB lines to a shell variable.
# A two-path fast/slow variant measured no better and was deleted. Don't
# reintroduce a window here without a benchmark.
transcript="$(printf '%s' "$payload" | sed -n 's/.*"transcript_path": *"\([^"]*\)".*/\1/p')"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
cut="$(grep -an '"type": *"user"' "$transcript" 2>/dev/null | grep -v 'tool_use_id' | grep -v '"isSidechain" *: *true' | tail -n 1 | cut -d: -f1)"
if [ -n "$cut" ]; then
  seg="$(tail -n +"$((cut + 1))" "$transcript")"
else
  seg="$(tail -n 600 "$transcript")"   # no real user line anywhere -> bounded fallback
fi
# The tool-name list is exact and quote-anchored, so a name that merely CONTAINS
# an editing verb escapes — `MultiEdit` did, and so will the next renamed or
# vendor-specific writer. Relaxing the anchor is the wrong fix (`TodoWrite` would
# arm most turns); the right one is a PostToolUse hook that flags the turn as
# mutating, which retires this whole pattern and is a 0.8.0 redesign. Until then
# this list is maintained, and its misses are misses in the fail-open direction.
# 0.7.0 also widened the MCP verbs past the edit family: whatever a server calls
# it, a send/save/publish/merge changed something outside this session. The
# match is an unanchored substring, so the list must exclude verbs that live
# inside ordinary READ names: `commit`, `deploy`, `execute`, `patch` and `drop`
# were tried and removed, because `list_commits`, `list_deployments`,
# `execute_query` and `dispatch_*` all armed on a plural noun. The miss that
# buys (a genuine `execute_sql` write) is in the fail-open direction; arming
# every database read is not. The name class carries `-`: a hyphen is legal in
# an MCP server's config key, and excluding it failed the branch END TO END for
# every hyphenated server (`mcp__github-mcp__create_pull_request`) — a hole in
# the character class, not the verb list every comment here argued about.
if ! printf '%s\n' "$seg" | grep -qE '"name" *: *"(Edit|MultiEdit|Write|NotebookEdit|Task|Agent|mcp__[A-Za-z0-9_-]*(edit|replace|insert|write|rename|delete|create|move|send|save|publish|upload|merge|append|remove|destroy)[A-Za-z0-9_-]*)"'; then
  # Bash-side mutations arm too (0.6.0). Judged ONLY on the "command" values
  # of Bash tool_use lines — text blocks and model-authored "description"
  # fields can't arm. /dev/null redirects are stripped before matching.
  # Signatures: sed -i/--in-place, tee, git state ops (incl. -C <path>),
  # mv/cp/rm (word-anchored, also after a literal \n; never a --flag), and
  # redirects to file-ish targets (>, >>, N>, &>) — excludes 2>&1, "->",
  # "=>", and numeric comparisons (awk '$3 > 100'). Known accepted cost: a
  # quoted '>' aimed at a word ("foo > bar") still false-arms — at worst one
  # spurious bounce demand, since a bare claim must also be present.
  # Fail-open bias kept; tune from gate-log.
  cmds="$(printf '%s\n' "$seg" | grep '"name" *: *"Bash"' | grep -oE '"command" *: *"([^"\\]|\\.)*"' | sed -E 's/[0-9&]?>{1,2} *\/dev\/null//g')"
  [ -n "$cmds" ] || exit 0
  # 0.6.1 added write paths that leave no >, no sed -i and no git: curl -o/-O,
  # wget, dd, truncate, chmod/chown, ln -s, and a write-mode open() (the model's
  # usual way to write a file from a one-liner). Selective on purpose — bare
  # `python -c` is NOT a signature: it is overwhelmingly a read-only one-liner,
  # so only `open(..., 'w'|'a')` arms. Pinned both ways by "python write-mode
  # open() arms" / "read-only python -c does not arm".
  # 0.7.0 added the OUTWARD verbs. Until then the signatures covered writes to
  # the local disk and stopped there, so the tier table's top row was its
  # blindest: `gh pr merge`, `npm publish`, `terraform apply`, `kubectl apply`
  # and `docker push` all left the session without arming, and the claim that
  # followed ("Merged the PR.") was unlisted too — invisible on both axes at
  # once. Verb-specific on purpose: `gh pr checks` and `gh pr view` must stay
  # silent, because superstack-verify recommends the first one as the
  # counting-environment probe and would otherwise arm the turn that proves a
  # claim. `touch`/`rmdir`/`mkdir` join the word-anchored group for the same
  # reason `mv`/`cp` are in it.
  # Spelling variants matter as much as the verb list: `sed -E -i` puts the -i
  # in a LATER flag cluster, `curl -sLo` combines it into one, and a redirect
  # target may start with digits (`> 2026-run.log`) — all missed while the
  # fixture for each pinned the single spelling the pattern was written from.
  # The digit prefix still requires a non-digit after it, so `awk '$3 > 100'`
  # stays guarded. Accepted false arm, widened from the 0.6.0 note: a quoted
  # MUTATION VERB also arms (`grep -rn "rm -rf" scripts/`), not just a quoted
  # `>`, because the char before it is the quote. One bounce, priced.
  bashmut='(^|\\n|[^-A-Za-z0-9_])(sed +(-[a-zA-Z]+ +)*-[a-zA-Z]*i|tee |git +(-C +[^ ]+ +)?(add|commit|push|merge|apply|rm|mv|reset|restore|clean|stash|checkout)($|[^-A-Za-z0-9_])|gh +(pr|release|issue|repo|gist|secret|workflow) +(create|merge|edit|comment|close|reopen|ready|delete|upload|run|set)|(npm|pnpm|yarn) +publish|terraform +(apply|destroy|import)|kubectl +(apply|create|delete|patch|replace|scale)|docker +(push|rmi)|(mv|cp|rm|dd|touch|rmdir|mkdir|truncate|chmod|chown|wget) )|--in-place|curl [^|]*(-[a-zA-Z]*[oO]\b|--output|--remote-name)|ln +-[a-zA-Z]*s|open\([^)]*,.{0,2}[wa][b+]?.{0,2}\)|[^<>&=-]>{1,2} *[0-9]*[A-Za-z_./~$\\-]|&>{1,2} *[0-9]*[A-Za-z_./~$\\-]'
  printf '%s' "$cmds" | grep -qE "$bashmut" || exit 0
fi

# .superstack/ resolves through the one shared rule (hooks/superstack-root.sh):
# the cwd's own record wins, else the git root's. Sourced so the six resolution
# sites cannot drift; the fallback keeps a bare re-vendor at the old behaviour.
. "$(dirname "$0")/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null)"; [ -n "$root" ] || root="."
log="$root/.superstack/gate-log"

# The writer owns the bound (0.6.1). This hook appends on every armed turn, so
# leaving rotation to a model habit at ship time meant a session that never
# ships grew the log forever — and it put the audited party in charge of its own
# audit log. Same rule the SessionStart hook already states: expiry lives in the
# deterministic half, not in hope. 200 lines is the tuning window superstack-status
# reads; older lines have already served their purpose.
logline() {
  [ -d "$root/.superstack" ] || return 0
  printf '%s\n' "$1" >> "$log"
  if [ "$(wc -l < "$log" 2>/dev/null || echo 0)" -gt 200 ]; then
    tmpl="$(mktemp "$log.XXXXXX" 2>/dev/null)" || return 0
    tail -n 200 "$log" > "$tmpl" 2>/dev/null && mv "$tmpl" "$log" || rm -f "$tmpl"
  fi
}

# A ledger token vouches only with content attached — a bare "Verified:"
# claims evidence and provides none. Bare PROVISIONAL stays legal: it
# downgrades the result itself.
if printf '%s' "$last" | grep -qE '(Verified|Assumed): *[^ "]|PROVISIONAL'; then
  logline "$(date +%F) PASS phrase=$phrase"
  exit 0
fi

snippet="$(printf '%s' "$last" | cut -c1-160)"
logline "$(date +%F) BOUNCE phrase=$phrase snippet=$snippet"

cat >&2 <<'MSG'
superstack calibration gate: this turn ends on a completion claim with no evidence attached. Do ONE of these, honestly:
- Run the single command that proves the claim NOW, read its output, then restate:
  Verified: <claim> — ran <command> -> saw <actual output>
  Never write Verified: from memory or an earlier session's run.
- If you cannot or should not run it now, downgrade: mark the result PROVISIONAL,
  or move it to Assumed: <what's unchecked> — why — how the user can check it.
- If this turn genuinely completed nothing, report the status plainly: what changed,
  what remains, the next check.
Do not reword a real completion claim to dodge the gate — a dodged gate is worse
than either honest option.
(Knob: SUPERSTACK_GATES=all|claims|off — off silences every superstack gate.)
MSG
exit 2

#!/usr/bin/env bash
# Self-checks for the plugin's scripts (the gate + the status doctor).
# Run: bash hooks/test-gate.sh  (exit 0 = all pass)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
gate="$here/gate-claims.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fails=0; checks=0

mk() { printf '%s\n' "$@" > "$tmp/t.jsonl"; }
mk_long() { # $1 = filler lines after the edit; builds a turn longer than the gate's read window
  { printf '%s\n' "$user" "$edit"
    i=0; while [ "$i" -lt "$1" ]; do printf '%s\n' "$filler"; i=$((i+1)); done
  } > "$tmp/t.jsonl"
}
run() { # $1 = stop_hook_active; $2 = last_assistant_message (pre-escaped); echoes gate exit code
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":%s,"last_assistant_message":"%s"}' "$tmp/t.jsonl" "$1" "$2" \
    | (cd "$tmp" && bash "$gate") >/dev/null 2>&1
  echo $?
}
run_c() { # same, forced C locale (multibyte apostrophe handled as bytes)
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":%s,"last_assistant_message":"%s"}' "$tmp/t.jsonl" "$1" "$2" \
    | (cd "$tmp" && LC_ALL=C bash "$gate") >/dev/null 2>&1
  echo $?
}
run_nofield() { # payload without last_assistant_message (older Claude Code)
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false}' "$tmp/t.jsonl" \
    | (cd "$tmp" && bash "$gate") >/dev/null 2>&1
  echo $?
}
run_spaced() { # spaced JSON serialization of the loop guard
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active" : true,"last_assistant_message":"%s"}' "$tmp/t.jsonl" "$1" \
    | (cd "$tmp" && bash "$gate") >/dev/null 2>&1
  echo $?
}
check() { # name expected got
  checks=$((checks + 1))
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else echo "FAIL: $1 (expected exit $2, got $3)"; fails=$((fails+1)); fi
}

# Transcript fixtures carry the ARMING evidence (turn structure + tool names).
# The claim itself arrives in the payload's last_assistant_message; text
# entries below only mirror what real transcripts contain.
user='{"type":"user","message":{"role":"user","content":[{"type":"text","text":"please fix it"}]}}'
edit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{}}]}}'
mcpedit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__serena__replace_content","input":{}}]}}'
dispatch='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Task","input":{"prompt":"fix the flaky test"}}]}}'
scuser='{"type":"user","isSidechain":true,"message":{"role":"user","content":[{"type":"text","text":"You are a reviewer subagent"}]}}'
claimtxt='{"type":"assistant","message":{"id":"msg_c1","content":[{"type":"text","text":"All fixed and tests passing. Ship it."}]}}'
filler='{"type":"assistant","message":{"content":[{"type":"text","text":"working on it"}]}}'

claim="All fixed and tests passing. Ship it."
calibrated="Done. Verified: pytest -> 42 passed, 0 failed. Assumed: staging matches prod."
noclaim="Here is the analysis you asked for."
idiom="Finished. Everything is implemented and all green."

# core behavior
mk "$user" "$edit" "$claimtxt"
check "uncalibrated claim blocks"            2 "$(run false "$claim")"
check "claim with ledger passes"             0 "$(run false "$calibrated")"
check "stop_hook_active passes (loop guard)" 0 "$(run true "$claim")"
check "spaced stop_hook_active still loop-guards" 0 "$(run_spaced "$claim")"
check "no done-claim -> no gate"             0 "$(run false "$noclaim")"
check "finished/implemented/all-green idioms gate" 2 "$(run false "$idiom")"
mk "$user" "$claimtxt"
check "no file mutation -> no gate"          0 "$(run false "$claim")"
printf '{"session_id":"t","transcript_path":"%s/absent.jsonl","stop_hook_active":false,"last_assistant_message":"%s"}' "$tmp" "$claim" \
  | (cd "$tmp" && bash "$gate") >/dev/null 2>&1
check "missing transcript fails open (cannot arm)" 0 "$?"

# turn scoping and arming (design-review regressions, 0.5.0)
mk "$edit" "$user" "$claimtxt";  check "stale edit before user msg: Q&A turn not gated" 0 "$(run false "$claim")"
mk "$user" "$edit" "$claimtxt";  check "edit within current turn still gates"           2 "$(run false "$claim")"
mk "$user" "$mcpedit";           check "MCP edit tool arms the gate"                    2 "$(run false "$claim")"
mcprename='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__serena__rename_symbol","input":{}}]}}'
mk "$user" "$mcprename";         check "MCP rename/delete/create tools arm the gate"    2 "$(run false "$claim")"
# Subagent work: the dispatch (Task/Agent) is the only trace in the main
# transcript — subagents' own tool calls live in separate files the gate
# never reads. Arming on the dispatch makes delegated work need its ledger.
mk "$user" "$dispatch";          check "subagent dispatch arms (delegated work counts)" 2 "$(run false "$claim")"
mk "$user" "$edit" "$scuser";    check "sidechain user line does not reset the turn cut" 2 "$(run false "$claim")"

# claim side reads the supported payload field — the transcript can
# neither supply the claim (old Claude Code: fail open) nor vouch for it.
# Obsoleted by this move: the chunked-message and tool_use-flush cases (Claude
# Code assembles the complete final message) and sidechain text vouching.
mk "$user" "$edit" "$claimtxt"
check "payload without last_assistant_message fails open" 0 "$(run_nofield)"

# ledger tokens vouch only with content attached
check "bare Verified: token no longer vouches"  2 "$(run false "Done. Verified:")"
check "bare Assumed: token no longer vouches"   2 "$(run false "Everything is complete. Assumed:")"
check "bare PROVISIONAL is a legal self-downgrade" 0 "$(run false "Done. PROVISIONAL")"

# negated statements are not claims
check "negated claim does not fire"  0 "$(run false "This is not done yet. The tests are not passing either. Next I will wire the parser.")"
check "negation does not shield a real claim" 2 "$(run false "Tests were not passing before this change; now everything is fixed and all green.")"
check "typographic-apostrophe negation passes" 0 "$(run false "The parser isn’t finished.")"
check "typographic negation under C locale"    0 "$(run_c false "The parser isn’t finished.")"

# Bash-side mutations arm the gate — high-precision signatures only,
# judged only on Bash tool_use lines; a false arm costs at most one spurious
# bounce demand (still needs a claim + no ledger), tuned from gate-log.
bashsedi='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"sed -i s/a/b/ config.txt"}}]}}'
bashredir='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"echo result > out.txt"}}]}}'
bashgit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git add -A && git commit -m msg && git push"}}]}}'
bashro='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"grep -rn pattern src/ | head -20"}}]}}'
basharrow='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"echo \"a -> b\" mapping"}}]}}'
bashdevnull='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"claude plugin list 2>/dev/null | head"}}]}}'
textmention='{"type":"assistant","message":{"id":"msg_tm","content":[{"type":"text","text":"Next I could run sed -i or echo > file but have not."}]}}'

bashdesc='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git log --oneline -3","description":"Show recent git commit history"}}]}}'
bashdevout='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git rev-parse --git-dir > /dev/null 2>&1 && command -v rg >/dev/null"}}]}}'
bashawk='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"awk $3 > 100 data.csv | head"}}]}}'
bashgitc='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git -C /repo commit -am wip"}}]}}'
bashreset='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git reset --hard HEAD~1"}}]}}'
bashboth='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"pytest -q &> results.txt"}}]}}'
bashfd1='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"echo hi 1> out.txt"}}]}}'
bashinplace='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"sed --in-place s/a/b/ conf.ini"}}]}}'
bashnl='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"cd /tmp\\nrm -rf build"}}]}}'
bashdockerrm='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"docker run --rm alpine cat /etc/os-release"}}]}}'

mk "$user" "$bashsedi";   check "bash sed -i arms the gate"                    2 "$(run false "$claim")"
mk "$user" "$bashredir";  check "bash redirect arms the gate"                  2 "$(run false "$claim")"
mk "$user" "$bashgit";    check "git commit/push turn arms the gate"           2 "$(run false "Shipped. All done.")"
mk "$user" "$bashgitc";   check "git -C <path> commit arms the gate"           2 "$(run false "$claim")"
mk "$user" "$bashreset";  check "git reset --hard arms the gate"               2 "$(run false "$claim")"
mk "$user" "$bashboth";   check "&> both-streams redirect arms the gate"       2 "$(run false "$claim")"
mk "$user" "$bashfd1";    check "1> explicit-fd redirect arms the gate"        2 "$(run false "$claim")"
mk "$user" "$bashinplace"; check "sed --in-place long flag arms the gate"      2 "$(run false "$claim")"
mk "$user" "$bashnl";     check "rm after a newline in a multiline command arms" 2 "$(run false "$claim")"
mk "$user" "$bashro";     check "read-only bash does not arm"                  0 "$(run false "$claim")"
mk "$user" "$basharrow";  check "quoted arrow (->) is not a redirect"          0 "$(run false "$claim")"
mk "$user" "$bashdevnull"; check "stderr-to-devnull does not arm"              0 "$(run false "$claim")"
mk "$user" "$bashdevout"; check "stdout-to-devnull does not arm"               0 "$(run false "$claim")"
mk "$user" "$bashawk";    check "awk/jq numeric comparison is not a redirect"  0 "$(run false "$claim")"
mk "$user" "$bashdockerrm"; check "--rm flag is not an rm command"             0 "$(run false "$claim")"
mk "$user" "$bashdesc";   check "mutation words in the description field do not arm" 0 "$(run false "$claim")"
mk "$user" "$textmention"; check "text mentioning mutations does not arm"      0 "$(run false "$claim")"

# more write paths that leave no >, no sed -i and no git. Selective on
# purpose: bare `python -c` is NOT a signature (it is overwhelmingly used for
# read-only one-liners), so only a write-mode open() arms.
bashcurlo='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"curl -sL https://x/y.tar.gz -o dist.tgz"}}]}}'
bashwget='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"wget https://example.com/pkg.deb"}}]}}'
bashdd='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"dd if=/dev/zero of=disk.img bs=1M count=10"}}]}}'
bashtrunc='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"truncate -s 0 app.log"}}]}}'
bashchmod='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"chmod +x hooks/run.sh"}}]}}'
bashln='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ln -sf ../real.conf link.conf"}}]}}'
bashpywrite='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"python3 -c \"open('out.txt','w').write(data)\""}}]}}'
bashpyread='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"python3 -c \"import time; print(time.time())\""}}]}}'
bashcurlro='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"curl -s https://api.example.com/health | head -5"}}]}}'

mk "$user" "$bashcurlo";  check "curl -o writes a file and arms"               2 "$(run false "$claim")"
mk "$user" "$bashwget";   check "wget arms the gate"                           2 "$(run false "$claim")"
mk "$user" "$bashdd";     check "dd arms the gate"                             2 "$(run false "$claim")"
mk "$user" "$bashtrunc";  check "truncate arms the gate"                       2 "$(run false "$claim")"
mk "$user" "$bashchmod";  check "chmod arms the gate"                          2 "$(run false "$claim")"
mk "$user" "$bashln";     check "ln -s arms the gate"                          2 "$(run false "$claim")"
mk "$user" "$bashpywrite"; check "python write-mode open() arms the gate"      2 "$(run false "$claim")"
mk "$user" "$bashpyread"; check "read-only python -c does not arm"             0 "$(run false "$claim")"
mk "$user" "$bashcurlro"; check "curl piped to head does not arm"              0 "$(run false "$claim")"
# the same class spelled the other ways: JSON-escaped double quotes put TWO
# chars either side of the mode, and 'wb'/'w+' add one. A test name that claims
# a class while pinning one spelling would stay green through the real miss.
bashpydq='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"python3 -c '"'"'open(\"out.txt\",\"w\").write(x)'"'"'"}}]}}'
bashpywb='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"python3 -c \"open('"'"'f.bin'"'"','"'"'wb'"'"').write(b)\""}}]}}'
bashcurllong='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"curl -sL https://x/y.tgz --output dist.tgz"}}]}}'
bashpyopenread='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"python3 -c \"print(open('"'"'cfg.json'"'"').read())\""}}]}}'
mk "$user" "$bashpydq";   check "open() with JSON-escaped double quotes arms"  2 "$(run false "$claim")"
mk "$user" "$bashpywb";   check "open() with mode 'wb' arms"                   2 "$(run false "$claim")"
mk "$user" "$bashcurllong"; check "curl --output long form arms"               2 "$(run false "$claim")"
mk "$user" "$bashpyopenread"; check "read-mode open() does not arm"            0 "$(run false "$claim")"

# negation hedges (honest not-done statuses must not bounce)
mk "$user" "$edit" "$claimtxt"
check "hedged negation (not completely done) does not fire" 0 "$(run false "This is not completely done. I still need to wire the parser.")"
check "far-from-done does not fire"                         0 "$(run false "This is far from done.")"
# negre must cover every stem claimre carries, or widening the claim list turns
# honest failure reports into bounces — the gate punishing the exact honesty it
# exists to buy. 0.6.1 added `succeeded`/`successfully <verb>` to claimre; these
# pin the matching negation (regression: they exit 0 on 0.6.0, and exit 2 on the
# widened claimre until negre is widened too).
check "'has not succeeded' does not fire"                   0 "$(run false "The deployment has not succeeded.")"
check "'not successfully deployed' does not fire"           0 "$(run false "The change was not successfully deployed.")"
check "'has not succeeded yet' does not fire"               0 "$(run false "The migration has not succeeded yet.")"
check "negation does not shield a real success claim"       2 "$(run false "The first attempt had not succeeded; the migration succeeded on the retry.")"
# same class again: 'checks out' is a claimre stem, so an honest partial-failure
# that keeps the literal "checks out" ("not everything checks out") false-bounces
# (0.6.1 review, MECH lens). Note "do not check out" is grammatically "check out",
# never matches claimre, so it was never the failing case.
check "'not everything checks out' does not fire"           0 "$(run false "Not everything checks out.")"
check "'nothing checks out yet' does not fire"              0 "$(run false "Nothing checks out yet.")"

# claim-detection recall — real completion phrasings the 14-stem list
# missed. Every one of these exited 0 against the shipped 0.6.0 gate; the
# "successfully deployed" case is a T3 action escaping the backstop entirely.
mk "$user" "$edit" "$claimtxt"
check "bare 'Tests pass.' gates"                   2 "$(run false "Tests pass.")"
check "'The suite is green.' gates"                2 "$(run false "The suite is green.")"
check "'Successfully deployed to staging.' gates"  2 "$(run false "Successfully deployed to staging.")"
check "'The migration succeeded.' gates"           2 "$(run false "The migration succeeded.")"
# 'checks out' was dropped from claimre (0.6.1 review): unlike every other stem,
# its negation keeps the literal words ("not everything checks out"), so it
# false-bounced honest partial-failure reports and could not be suppressed
# without adding noun-fillers to negre. Removal beats that. Accepted recall miss:
check "bare 'Everything checks out.' is a documented recall miss" 0 "$(run false "Everything checks out.")"
# ...and the guards that keep the widened list soft. Bare `works` is deliberately
# NOT a stem: it false-fires on ordinary prose ("how it works"), so "It works."
# stays a known, documented miss — the phrase list is maintained, not exhaustive.
check "explaining how it works does not fire"      0 "$(run false "Here is how it works by hashing the key before the lookup.")"
check "'successfully handles' prose does not fire" 0 "$(run false "The parser successfully handles nested quotes, which is why I chose it.")"
check "conditional 'succeeds' does not fire"       0 "$(run false "This approach succeeds where the regex one fails, so I am using it.")"

# ── 0.7.0: the outward tier ────────────────────────────────────────────────
# At 0.6.1 the T3 row of the tier table was the LEAST guarded one, on both axes
# at once: `gh pr merge` did not arm, and "Merged the PR." did not match, so the
# highest-risk turn in the method was invisible twice over. 0.6.1 had closed the
# adverbial form ("Successfully deployed") and left the bare past tense.
mk "$user" "$edit" "$claimtxt"
check "bare 'Deployed to production.' gates"  2 "$(run false "Deployed to production.")"
check "bare 'Merged the PR.' gates"           2 "$(run false "Merged the PR.")"
check "bare 'Pushed to main.' gates"          2 "$(run false "Pushed to main.")"
check "'The feature is live.' gates"          2 "$(run false "The feature is live.")"
# ...and their negations, per the claimre/negre invariant: never widen one alone.
check "'not deployed yet' does not fire"      0 "$(run false "This is not deployed yet.")"
check "'has not been merged' does not fire"   0 "$(run false "The PR has not been merged.")"
check "'not pushed' does not fire"            0 "$(run false "The branch is not pushed.")"
# Tautology, kept as documentation and labelled as one: `claimre` requires the
# copula (`is|are|now live`), so "is not live" cannot match it whether or not a
# negation pass exists. Deleting negre entirely leaves this green. It records
# the intent; the `live` stem in negstem is what actually carries the case.
check "'not live yet' cannot fire (tautology)" 0 "$(run false "The feature is not live yet.")"
# ...and the prose guard: `live` is a common word, so only a copula form counts.
check "'the fixtures live in tests/' does not fire" 0 "$(run false "The fixtures live in tests/fixtures and are read at import time.")"

# Hedged honesty must not bounce. negre allowed only adverb fillers
# between the negator and the stem, so any hedge carrying a VERB escaped the
# strip and the gate bounced the exact candour it exists to buy — 7 of 7 sampled
# phrasings fired at 0.6.1, including a plain "Nothing is fixed yet."
check "'don't think the tests pass' does not fire"   0 "$(run false "I don't think the tests pass yet.")"
check "'can't confirm ... succeeded' does not fire"  0 "$(run false "I can't confirm the migration succeeded.")"
check "'not sure whether ... fixed' does not fire"   0 "$(run false "I am not sure whether this is fixed.")"
check "'no evidence that ... passes' does not fire"  0 "$(run false "I have no evidence that the build passes.")"
check "'unclear if the suite is green' does not fire" 0 "$(run false "It is unclear if the suite is green.")"
check "'nothing is fixed yet' does not fire"         0 "$(run false "Nothing is fixed yet; here is what I found.")"

# ── 0.7.0 RC, blind clean-room review ──────────────────────────────────────
# The widened strip was matched leftmost-LONGEST, so a second stem within the
# gap was eaten along with the first: the negation swallowed the very claim it
# was supposed to leave standing. The strip is now applied nearest-stem-first
# (gap 0, then 1, ... 4), so "not passing" is consumed before "build passes" is
# ever a candidate. Note the third case: 0.7.0 shipped it as an ACCEPTED shield
# and the fix retires it, so the accepted cost is gone rather than documented.
check "negation does not swallow a later claim (but)"     2 "$(run false "The tests are not passing but the build passes.")"
check "negation does not swallow a later claim (because)" 2 "$(run false "The migration is not done because the deploy succeeded.")"
check "negation does not shield within one clause"        2 "$(run false "This is not ready and the migration succeeded.")"
# A negator list assembled by sampling hedges picked up a certainty intensifier
# by string coincidence: `doubt` matched "no doubt", which is the STRONGEST form
# of the claim. Both it and `unverified` are gone from the list; the cost is that
# a bare "I doubt this is done" now bounces, which asks for an Assumed: line
# rather than silently exempting the most confident sentence in the language.
check "'no doubt ... is done' is a claim"                 2 "$(run false "I have no doubt this is done.")"
check "'no doubt ... succeeded' is a claim"               2 "$(run false "There is no doubt the migration succeeded.")"
check "'the unverified path is fixed' is a claim"         2 "$(run false "The unverified path is fixed.")"
check "bare 'I doubt this is done' bounces (accepted)"    2 "$(run false "I doubt this is done.")"
check "'None of the tests pass' does not fire"            0 "$(run false "None of the tests pass.")"

# ── 0.7.0 RC, second blind lens (mechanical) ───────────────────────────────
# The nearest-first ordering only protects the sentence when the negator's OWN
# stem sits at gap 0. When the negated word is not a stem at all, the widest
# expression reaches across the clause boundary and eats the claim instead —
# and the failure is anti-correlated with candour, since the more hedging
# preamble the message carries, the likelier the claim is erased. Clause
# conjunctions are now hard barriers the gap cannot cross.
check "gap does not cross 'but' to eat a claim"      2 "$(run false "The code isn't perfect but the tests pass.")"
check "gap does not cross 'but' (certain/fixed)"     2 "$(run false "I'm not certain but everything is fixed.")"
check "gap does not cross 'and' to eat a claim"      2 "$(run false "This is no longer broken and the tests pass.")"
# `doubt` was removed as a NEGATOR for exactly this reason, then `no longer`
# reached over it and re-opened the same hole one synonym away.
check "'no longer any doubt ... succeeded' is a claim" 2 "$(run false "There is no longer any doubt the migration succeeded.")"
# The invariant said every claimre stem appears in the negation group. Two never
# did — `good to go` and `works now` — so the two most deflated status reports
# in the vocabulary bounced, which is the direction the file calls worse.
check "'Nothing works now.' does not fire"           0 "$(run false "Nothing works now.")"
check "'not good to go yet' does not fire"           0 "$(run false "This is not good to go yet.")"
# last_assistant_message arrives JSON-ENCODED. A newline is a literal backslash
# and an `n`, so a claim beginning its own line had a word character in front of
# it and `claimre`'s \b never matched: the single most common shape of a real
# final message walked through the gate. The mirror also held — a hedge split
# across lines could not be stripped, so honest text bounced.
check "claim after an escaped newline still gates"   2 "$(run false "Refactored the parser.\\nDone.")"
check "T3 claim after an escaped newline gates"      2 "$(run false "Rebased onto main.\\nMerged the PR.")"
check "hedge split by an escaped newline does not fire" 0 "$(run false "I don't think\\nthe tests pass.")"
check "ledger after an escaped newline vouches"      0 "$(run false "Done.\\nVerified: suite green - ran the suite -> 144 pass")"
# The widened strip must still not shield a real claim that follows a negation.
check "widened strip still does not shield (green)"  2 "$(run false "Tests were not passing before this change; now everything is fixed and all green.")"
check "widened strip still does not shield (retry)"  2 "$(run false "The first attempt had not succeeded; the migration succeeded on the retry.")"
# Accepted, priced miss: a negation TRAILING its claim cannot be stripped by a
# prefix rule, so this still bounces — same class as the conditional "whether the
# tests pass" already documented in the script. Cost is one bounce demand.
check "trailing negation still bounces (accepted)"   2 "$(run false "Whether the tests pass is still unknown.")"

# ── S3 (trial-only, D-15; dogfood/reduction-trial/PREREG.md §3) ────────────
# The five reproduced false-bounce classes (F1-mechanical-recheck §3). Every
# "does not fire" row here was a live bounce at 0.7.6, and each rides beside
# the nearest claim that must KEEP firing, so a suppressor can never quietly
# become a shield.
mk "$user" "$edit" "$claimtxt"
check "partial quantifier does not fire (12 of 40)"        0 "$(run false "12 of 40 tests passed.")"
check "a full quantifier is still a claim (40 of 40)"      2 "$(run false "40 of 40 tests passed.")"
check "mixed-clause honest report does not fire (still there)" 0 "$(run false "I fixed the null deref but the race is still there.")"
check "mixed-clause honest report does not fire (is not)"  0 "$(run false "Still broken. The parser is fixed; the lexer is not.")"
check "a claim naming the breakage it fixed still fires"   2 "$(run false "Fixed the broken build.")"
check "stem inside a path does not fire"                   0 "$(run false "The file src/complete.ts is unrelated.")"
check "stem inside a dotted name does not fire"            0 "$(run false "Renaming done.spec.ts is out of scope here.")"
check "a claim beside a path still fires"                  2 "$(run false "Fixed src/parser.ts.")"
check "interrogative turn does not fire"                   0 "$(run false "Should I mark this done?")"
check "a claim followed by a question still fires"         2 "$(run false "Done. Should I push?")"
check "bare no-noun negation does not fire"                0 "$(run false "No tests pass yet.")"
check "the no-issues vouch family still fires"             2 "$(run false "No issues found.")"

# ── S4 (trial-only, D-15; PREREG.md §3): the off switch ────────────────────
# SUPERSTACK_GATES=all|claims|off, read at the top of every gate script and
# named only in the bounce stderr. `claims` keeps exactly this gate; anything
# unrecognized (including unset) leaves every gate armed.
run_gates() { # $1 = SUPERSTACK_GATES value; $2 = last_assistant_message
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false,"last_assistant_message":"%s"}' "$tmp/t.jsonl" "$2" \
    | (cd "$tmp" && SUPERSTACK_GATES="$1" bash "$gate") >/dev/null 2>&1
  echo $?
}
mk "$user" "$edit" "$claimtxt"
check "SUPERSTACK_GATES=off silences the claims gate"      0 "$(run_gates off "$claim")"
check "SUPERSTACK_GATES=claims keeps the claims gate"      2 "$(run_gates claims "$claim")"
check "SUPERSTACK_GATES=all keeps the claims gate"         2 "$(run_gates all "$claim")"
check "an unknown knob value keeps the gates armed"        2 "$(run_gates nonsense "$claim")"

# Outward Bash verbs arm the gate — publish/merge/deploy leave no `>`,
# no `sed -i` and no bare `git`, and they are the T3 actions the tier table
# ranks highest. The read-only `gh` forms must stay silent: superstack-verify itself
# recommends `gh pr checks` as the counting-environment probe.
bashghcreate='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"gh pr create --title x --body y"}}]}}'
bashghmerge='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"gh pr merge 12 --squash"}}]}}'
bashnpmpub='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"npm publish --access public"}}]}}'
bashtf='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"terraform apply -auto-approve"}}]}}'
bashk8s='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"kubectl apply -f deploy.yaml"}}]}}'
bashdpush='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"docker push registry.io/img:1.0"}}]}}'
bashtouch='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"touch NEWFILE.md"}}]}}'
bashrmdir='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"rmdir build"}}]}}'
bashghchecks='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"gh pr checks 12 --watch"}}]}}'
bashghview='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"gh pr view 12 --json state,mergeable"}}]}}'
bashtfplan='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"terraform plan -no-color | tail -40"}}]}}'
bashk8sget='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"kubectl get pods -o wide"}}]}}'

mk "$user" "$bashghcreate"; check "gh pr create arms the gate"        2 "$(run false "$claim")"
mk "$user" "$bashghmerge";  check "gh pr merge arms the gate"         2 "$(run false "Merged the PR.")"
mk "$user" "$bashnpmpub";   check "npm publish arms the gate"         2 "$(run false "$claim")"
mk "$user" "$bashtf";       check "terraform apply arms the gate"     2 "$(run false "$claim")"
mk "$user" "$bashk8s";      check "kubectl apply arms the gate"       2 "$(run false "$claim")"
mk "$user" "$bashdpush";    check "docker push arms the gate"         2 "$(run false "$claim")"
mk "$user" "$bashtouch";    check "touch arms the gate"               2 "$(run false "$claim")"
mk "$user" "$bashrmdir";    check "rmdir arms the gate"               2 "$(run false "$claim")"
mk "$user" "$bashghchecks"; check "gh pr checks (read-only) does not arm" 0 "$(run false "$claim")"
mk "$user" "$bashghview";   check "gh pr view (read-only) does not arm"   0 "$(run false "$claim")"
mk "$user" "$bashtfplan";   check "terraform plan does not arm"       0 "$(run false "$claim")"
mk "$user" "$bashk8sget";   check "kubectl get does not arm"          0 "$(run false "$claim")"
# The read-only siblings the first pass missed. `kubectl rollout status` is the
# canonical "did the deploy land" probe — arming on it meant the gate fired on
# the command that PROVES a claim, which MAINTAINING names as forbidden in the
# same release that shipped it. `npm publish` and `docker push` had no paired
# negative at all, so nothing pinned the width of those two verbs.
bashk8sroll='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"kubectl rollout status deploy/api --timeout=60s"}}]}}'
bashnpmview='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"npm view lodash versions --json"}}]}}'
bashdpull='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"docker pull alpine:3"}}]}}'
mk "$user" "$bashk8sroll";  check "kubectl rollout status does not arm" 0 "$(run false "$claim")"
mk "$user" "$bashnpmview";  check "npm view does not arm"              0 "$(run false "$claim")"
mk "$user" "$bashdpull";    check "docker pull does not arm"           0 "$(run false "$claim")"
# The whole point, stated as one check: a turn that only PROBED must not be
# asked to prove itself. Arming and claim-recall each looked defensible alone
# and composed into a bounce on a turn that changed nothing.
mk "$user" "$bashk8sroll";  check "probe-only turn does not bounce a deploy claim" 0 "$(run false "Deployed to production.")"

# MCP write verbs beyond the edit family. Whatever the server calls it,
# a send/save/publish/execute is delegated work that changed something.
mcpsend='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__slack__send_message","input":{}}]}}'
mcpexec='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__supabase__execute_sql","input":{}}]}}'
mcpmerge='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__github__merge_pull_request","input":{}}]}}'
mcpsave='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__memory__memory_save","input":{}}]}}'
# The old negative used a name carrying NONE of the verbs, before or after the
# widening — it could not fail for the change it was named after. These two can:
# both are read-only names that the substring list matched through a plural noun.
mcpread='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__serena__find_symbol","input":{}}]}}'
mcplistc='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__github__list_commits","input":{}}]}}'
mcplistd='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__vercel__list_deployments","input":{}}]}}'
mcpquery='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__db__execute_query","input":{}}]}}'
mk "$user" "$mcpsend";  check "MCP send verb arms the gate"       2 "$(run false "$claim")"
# `execute` was tried as a verb and removed: it armed `execute_query` on every
# database READ. Losing a genuine `execute_sql` write is the fail-open direction;
# arming every read is not. Pinned so the next widening re-argues it.
mk "$user" "$mcpexec";  check "MCP execute_sql no longer arms (priced miss)" 0 "$(run false "$claim")"
mk "$user" "$mcpmerge"; check "MCP merge verb arms the gate"      2 "$(run false "$claim")"
mk "$user" "$mcpsave";  check "MCP save verb arms the gate"       2 "$(run false "$claim")"
mk "$user" "$mcpread";  check "MCP read-only verb does not arm"   0 "$(run false "$claim")"
mk "$user" "$mcplistc"; check "MCP list_commits does not arm"     0 "$(run false "$claim")"
mk "$user" "$mcplistd"; check "MCP list_deployments does not arm" 0 "$(run false "$claim")"
mk "$user" "$mcpquery"; check "MCP execute_query does not arm"    0 "$(run false "$claim")"

# Accepted cost, pinned so it stays a decision rather than becoming a surprise:
# the outward verbs are ordinary engineering prose too, and a turn that edited
# files and says it merged something with no evidence is a fair bounce. Pinning
# it is what makes the next widening notice the price.
mk "$user" "$edit"
check "prose 'I merged the two helpers' arms (accepted)" 2 "$(run false "I merged the two helper functions into one.")"
check "prose 'I pushed the logic down' arms (accepted)"  2 "$(run false "I pushed the validation logic down into the boundary function.")"

# The tool-name pattern is quote-anchored, so a name that merely CONTAINS Edit
# escapes. Pinning the one real instance; the structural fix is a PostToolUse
# arming flag, which is a 0.8.0 redesign rather than a wider regex.
multiedit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"MultiEdit","input":{}}]}}'
mk "$user" "$multiedit"; check "MultiEdit arms the gate"          2 "$(run false "$claim")"

# Hyphens are legal in an MCP server's config key, and the tool-name class
# excluded them, so the whole branch failed end-to-end for any hyphenated
# server. Every MCP fixture here used hyphen-free names, so nothing saw it.
mcphyph='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__github-mcp__create_pull_request","input":{}}]}}'
mcphyph2='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"mcp__filesystem-server__write_file","input":{}}]}}'
mk "$user" "$mcphyph";  check "hyphenated MCP server name arms"   2 "$(run false "$claim")"
mk "$user" "$mcphyph2"; check "hyphenated MCP fs server arms"     2 "$(run false "$claim")"

# bashmut spellings the inventory comment claimed and the patterns missed.
bashchown='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"chown -R app:app /srv/app"}}]}}'
bashsedflags='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"sed -E -i s/a/b/ conf.txt"}}]}}'
bashcurlcombo='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"curl -sLo dist.tgz https://x/y.tgz"}}]}}'
bashdigit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"pytest -q > 2026-run.log"}}]}}'
bashspaced='{"type":"assistant","message":{"content":[{"type":"tool_use","name" : "Bash","input":{"command" : "rm -rf build"}}]}}'
mk "$user" "$bashchown";     check "chown arms (documented, was missing)"  2 "$(run false "$claim")"
mk "$user" "$bashsedflags";  check "sed with flags before -i arms"         2 "$(run false "$claim")"
mk "$user" "$bashcurlcombo"; check "curl combined -sLo arms"               2 "$(run false "$claim")"
mk "$user" "$bashdigit";     check "redirect to a digit-leading filename arms" 2 "$(run false "$claim")"
mk "$user" "$bashspaced";    check "spaced \"command\" : key still arms"   2 "$(run false "$claim")"
mk "$user" "$bashawk";       check "awk numeric comparison still guarded"  0 "$(run false "$claim")"

# Refuted finding, pinned as a regression: a reviewer argued the final message
# could forge the loop guard or the transcript path by quoting them. It cannot —
# JSON escaping puts a backslash where the pattern needs a quote. Verified, then
# pinned, so the protection is a property rather than a coincidence.
mk "$user" "$edit"
check "message quoting stop_hook_active cannot bypass" 2 "$(run false "Done. It sets \\\"stop_hook_active\\\" : true in the payload.")"
check "message quoting transcript_path cannot bypass"  2 "$(run false "Done. It reads \\\"transcript_path\\\": \\\"/nope\\\" first.")"

# the arming window must cover the whole turn, not just its last 600 lines.
# The escape was correlated with the risk: long tool-heavy turns that
# edit early and claim at the end were the only ones silently skipping the gate.
mk_long 700
check "long turn still arms (edit outside the 600-line window)" 2 "$(run false "$claim")"
mk_long 10
check "short turn arms (window control)"                        2 "$(run false "$claim")"

# two-sided gate-log (needs .superstack/ in cwd; also exercises non-git-root fallback)
mkdir -p "$tmp/.superstack"
mk "$user" "$edit" "$claimtxt"
run false "$claim"      >/dev/null
run false "$calibrated" >/dev/null
grep -q "BOUNCE phrase=" "$tmp/.superstack/gate-log" 2>/dev/null; check "gate-log records bounce with phrase" 0 "$?"
grep -q "PASS phrase="   "$tmp/.superstack/gate-log" 2>/dev/null; check "gate-log records armed pass"         0 "$?"
# the snippet is the message, not the JSON field name that carried it (0.6.1;
# observed in a live log as: snippet="last_assistant_message":"All done.")
grep -q 'snippet=All fixed' "$tmp/.superstack/gate-log" 2>/dev/null; check "gate-log snippet starts at the message, not the JSON key" 0 "$?"
grep -q 'snippet="last_assistant_message"' "$tmp/.superstack/gate-log" 2>/dev/null; check "gate-log snippet carries no JSON key prefix" 1 "$?"

# the log rotates itself: the writer is a deterministic hook firing every armed
# turn, so its bound cannot live in a discretionary model habit at ship time
# (0.6.1 — "expiry lives in the deterministic half, not in hope").
: > "$tmp/.superstack/gate-log"
i=0; while [ "$i" -lt 260 ]; do printf '2026-01-01 PASS phrase=filler\n' >> "$tmp/.superstack/gate-log"; i=$((i+1)); done
run false "$claim" >/dev/null
lines="$(wc -l < "$tmp/.superstack/gate-log" | tr -d ' ')"
[ "$lines" -le 200 ]; check "gate-log self-rotates at its cap (was $lines)" 0 "$?"
grep -q "BOUNCE phrase=" "$tmp/.superstack/gate-log" 2>/dev/null; check "rotation keeps the newest line, drops the oldest" 0 "$?"
# restore the 1-bounce/1-pass base the superstack-status tallies below assert on
: > "$tmp/.superstack/gate-log"
run false "$claim"      >/dev/null
run false "$calibrated" >/dev/null

# the status doctor (read-only; reads the fixture record built above)
# Fixture uses the real grammar (project-template.md: one `- ` bullet per open
# obligation) and the real header, which itself names both tokens. A fixture
# without the header was green fiction — both counters reported +1 forever.
# The prose line pins the other half: mentioning a token is not owing one.
printf '%s\n' '# Residuals — undischarged Assumed:/PROVISIONAL (superstack-verify discharges; SessionStart surfaces the count)' > "$tmp/.superstack/residuals.md"
printf '%s\n' '- 2026-01-01 (0.1.0) Assumed: staging matches prod - could not check - discharge: diff the configs' >> "$tmp/.superstack/residuals.md"
printf '%s\n' 'Prose about how an Assumed: line gets discharged should not be counted as one.' >> "$tmp/.superstack/residuals.md"
printf '%s\n' '<!--pointer: tight-proj - oracle: make test. Full: .superstack/project.md -->' > "$tmp/.superstack/project.md"
printf '%s\n' '2026-01-01 BOUNCE phrase=passing snippet=Done. 42 tests PASSED and all green' >> "$tmp/.superstack/gate-log"
out="$(cd "$tmp" && bash "$here/../scripts/superstack-status.sh" 2>&1)"
check "superstack-status exits clean on a live record" 0 "$?"
printf '%s' "$out" | grep -qi "bounce"; check "superstack-status reports gate tallies" 0 "$?"
printf '%s' "$out" | grep -q "residuals: 1"; check "superstack-status counts open residuals" 0 "$?"
printf '%s' "$out" | grep -q "overlay: tight-proj"; check "superstack-status reads the tight pointer form the hook accepts" 0 "$?"
printf '%s' "$out" | grep -q "2 bounces / 1 armed passes"; check "superstack-status tallies anchor on the log grammar, not substrings" 0 "$?"

# the SessionStart injector — it promotes file text into the session
# preamble, so its inputs are bounded and its git-ignored claim is detected.
inj="$here/inject-project-pointer.sh"
ijt="$(mktemp -d)"; mkdir -p "$ijt/.superstack/tasks"
printf '%s\n' '<!-- pointer: p — oracle: make test. Full: .superstack/project.md -->' > "$ijt/.superstack/project.md"
iout="$(cd "$ijt" && bash "$inj" 2>&1)"
printf '%s' "$iout" | grep -q "overlay"; check "injector surfaces the overlay pointer" 0 "$?"

# control characters in the overlay must be stripped. Assert on CONTENT, not on
# a line count: a tab never forged a line, so a line-count assertion passed
# identically with and without clean() — it pinned nothing it named.
printf '<!-- pointer: A\033B\tC -->\n' > "$ijt/.superstack/project.md"
iout="$(cd "$ijt" && bash "$inj" 2>&1)"
printf '%s' "$iout" | LC_ALL=C grep -q '[[:cntrl:]]'; check "injector strips control chars from the pointer" 1 "$?"
printf '%s' "$iout" | grep -q 'ABC'; check "injector keeps the pointer's real text"                         0 "$?"

# an over-long pointer must not flood the preamble
{ printf '<!-- pointer: '; i=0; while [ "$i" -lt 400 ]; do printf 'A'; i=$((i+1)); done; printf ' -->\n'; } > "$ijt/.superstack/project.md"
iout="$(cd "$ijt" && bash "$inj" 2>&1)"
[ "${#iout}" -lt 400 ]; check "injector caps pointer length (was ${#iout} chars)" 0 "$?"

# the task list is capped, and says what it withheld — cap of 3 since S2
# (trial-only, D-15; was 10)
printf '%s\n' '<!-- pointer: p — oracle: make test -->' > "$ijt/.superstack/project.md"
i=0; while [ "$i" -lt 14 ]; do printf '<!-- task: t%s — next: wire the parser -->\n' "$i" > "$ijt/.superstack/tasks/t$i.md"; i=$((i+1)); done
iout="$(cd "$ijt" && bash "$inj" 2>&1)"
[ "$(printf '%s' "$iout" | grep -c 'in-flight task (')" -le 3 ]; check "injector caps the task list at 3" 0 "$?"
printf '%s' "$iout" | grep -q '+11 more'; check "injector announces the tasks it withheld" 0 "$?"
printf '%s' "$iout" | grep -q 'wire the parser'; check "injector surfaces the task pointer's next: action" 0 "$?"

# the residual counter anchors on the line grammar too — the file's own header
# names both tokens, so a substring count reports +1 forever
rm -f "$ijt"/.superstack/tasks/*.md
printf '%s\n' '# Residuals — undischarged Assumed:/PROVISIONAL (superstack-verify discharges; SessionStart surfaces the count)' > "$ijt/.superstack/residuals.md"
printf '%s\n' '- 2026-01-01 (0.1.0) Assumed: staging matches prod — could not check — discharge: diff the configs' >> "$ijt/.superstack/residuals.md"
printf '%s\n' 'Prose about how an Assumed: line gets discharged should not be counted as one.' >> "$ijt/.superstack/residuals.md"
iout="$(cd "$ijt" && bash "$inj" 2>&1)"
printf '%s' "$iout" | grep -q '1 undischarged residual'; check "injector counts residual bullets, not the header or prose" 0 "$?"

# the tracked-repo warning: it must fire on the property it names (TRACKED), not
# on "not ignored" — untracked-and-unignored is the ordinary state of a fresh
# .superstack/, and a false alarm there tells the model to distrust its own overlay
# on every session. Needs a real git repo: the block is skipped under mktemp.
gt="$(mktemp -d)"; ( cd "$gt" && git init -q . && git config user.email t@t && git config user.name t )
mkdir -p "$gt/.superstack"; printf '%s\n' '<!-- pointer: p — oracle: make test -->' > "$gt/.superstack/project.md"
gout="$(cd "$gt" && bash "$inj" 2>&1)"
printf '%s' "$gout" | grep -q "WARNING"; check "untracked+unignored .superstack/ does NOT warn" 1 "$?"
( cd "$gt" && git add -f .superstack/project.md >/dev/null 2>&1 && git commit -qm t >/dev/null 2>&1 )
gout="$(cd "$gt" && bash "$inj" 2>&1)"
printf '%s' "$gout" | grep -q "WARNING"; check "tracked .superstack/ DOES warn"              0 "$?"
rm -rf "$gt"
rm -rf "$ijt"


# 0.8.0: conversational status-summary stems — the drift class the round-2
# study localized (drift lived in conversational status framing, not in
# gate-mediated ledger reports). Each stem ships with its negre mirror per the
# standing invariant. The no-issues family is a NEGATIVE-FORM completion claim
# ("No issues found." is a vouch, not a hedge); it also enters negstem so a
# hedge that negates it ("can't promise there are no issues") still strips.
mk "$user" "$edit" "$claimtxt"
check "wrapped up gates"                      2 "$(run false "Wrapped up the migration work.")"
check "hedged wrapped-up does not fire"       0 "$(run false "I have not wrapped up the migration yet.")"
check "all set gates"                         2 "$(run false "You are all set.")"
check "not all set does not fire"             0 "$(run false "This is not all set yet; two steps remain.")"
check "up and running gates"                  2 "$(run false "The server is up and running.")"
check "not up and running does not fire"      0 "$(run false "The server is not up and running yet.")"
check "works-as-expected gates"               2 "$(run false "Everything works as expected.")"
check "not working as expected does not fire" 0 "$(run false "The exporter is not working as expected.")"
check "taken care of gates"                   2 "$(run false "That is taken care of.")"
check "not taken care of does not fire"       0 "$(run false "The cleanup is not taken care of yet.")"
check "in good shape gates"                   2 "$(run false "The branch is in good shape.")"
check "not in good shape does not fire"       0 "$(run false "The branch is not in good shape yet.")"
check "no-issues claim gates"                 2 "$(run false "No issues found.")"
check "no remaining issues gates"             2 "$(run false "There are no remaining issues.")"
check "hedged no-issues does not fire"        0 "$(run false "I cannot promise there are no issues left.")"

# D-47: the receipt fast path, the claim-exit log rows, and the frozen
# grammar. A cited receipt that exists under .superstack/receipts/ and names
# the current short HEAD passes with no ledger token; missing or stale
# citations fall through unchanged and leave their audit rows.
fp="$tmp/fprepo"
git init -q -b main "$fp"
git -C "$fp" -c user.email=t@t -c user.name=t commit --allow-empty -q -m fixture
mkdir -p "$fp/.superstack/receipts"
fphead="$(git -C "$fp" rev-parse --short HEAD)"
printf 'check: suite\nexit 0\nrevision %s\n' "$fphead" > "$fp/.superstack/receipts/attested-fp.txt"
printf 'check: suite\nexit 0\nrevision 0000000\n' > "$fp/.superstack/receipts/attested-stale.txt"
run_in() { # $1 = cwd; $2 = stop_hook_active; $3 = last_assistant_message
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":%s,"last_assistant_message":"%s"}' "$tmp/t.jsonl" "$2" "$3" \
    | (cd "$1" && bash "$gate") >/dev/null 2>&1
  echo $?
}
mk "$user" "$edit" "$claimtxt"
check "current receipt citation fast-passes without a ledger token" 0 "$(run_in "$fp" false "Done. receipt: receipts/attested-fp.txt")"
grep -q "FASTPASS" "$fp/.superstack/gate-log" 2>/dev/null; check "fast pass leaves its FASTPASS row" 0 "$?"
check "stale receipt citation falls through and still bounces bare claims" 2 "$(run_in "$fp" false "Done. receipt: receipts/attested-stale.txt")"
grep -q "FASTSTALE" "$fp/.superstack/gate-log" 2>/dev/null; check "stale citation leaves its FASTSTALE row" 0 "$?"
check "missing receipt citation with a ledger token still passes (fail-open)" 0 "$(run_in "$fp" false "Done. Verified: suite green. receipt: receipts/absent.txt")"
grep -q "CITEMISS" "$fp/.superstack/gate-log" 2>/dev/null; check "missing citation leaves its CITEMISS row" 0 "$?"
# D-72: the cite class legally contains dots, so a citation ending a
# sentence glued the period onto the filename and a CURRENT receipt logged
# CITEMISS — caught live on the gate's own author at a campaign closure.
# One trailing period is stripped; interior dots keep working (the .txt
# cites above are that pin).
check "a sentence-final period does not corrupt the citation" 0 "$(run_in "$fp" false "Done. receipt: receipts/attested-fp.txt.")"
# A workspace with no git commit has no head to be current against: the cited
# receipt passes by the fail-open charter, and the row must say why (head=none),
# or the lenient branch has silently widened into an unlogged bypass.
fpn="$tmp/fpnogit"
mkdir -p "$fpn/.superstack/receipts"
printf 'check: suite\nexit 0\n' > "$fpn/.superstack/receipts/attested-ng.txt"
check "no-git workspace with a cited receipt fast-passes (fail-open charter)" 0 "$(run_in "$fpn" false "Done. receipt: receipts/attested-ng.txt")"
grep -q "FASTPASS.*head=none" "$fpn/.superstack/gate-log" 2>/dev/null; check "no-git fast pass leaves its head=none row" 0 "$?"
check "question-form claim still exits quietly" 0 "$(run_in "$fp" false "Should I mark this done?")"
grep -q "SUPPRESS" "$fp/.superstack/gate-log" 2>/dev/null; check "suppressor exit leaves its SUPPRESS row" 0 "$?"
check "mixed honest report still exits quietly" 0 "$(run_in "$fp" false "Fixed the parser, but the build is still failing.")"
grep -q "MIXED" "$fp/.superstack/gate-log" 2>/dev/null; check "mixed exit leaves its MIXED row" 0 "$?"
# D-66: files-bound receipts. A receipt carrying files:/filesig: binds to the
# SURFACE it covers, not to the head: an unrelated commit must not stale it
# (the false-stale direction), a covered change — committed or dirty — must
# (the missed-stale direction), and a receipt recording a failing check never
# vouches whatever its freshness. Receipts without a files: line keep the
# legacy head-substring behavior pinned above. The signature recipe here must
# match the minter's; the minted-receipt rows below are that pairing's pin.
fb="$tmp/fbrepo"
git init -q -b main "$fb"
( cd "$fb" && printf 'v1\n' > covered.txt && printf 'x\n' > other.txt && git add . && git -c user.email=t@t -c user.name=t commit -qm one )
mkdir -p "$fb/.superstack/receipts"
fbrev="$(git -C "$fb" rev-parse --short HEAD)"
fbsig="$( (cd "$fb" && git diff HEAD -- covered.txt; git status --porcelain -- covered.txt) | cksum | cut -d' ' -f1)"
printf 'command: check\nexit: 0\nrevision: %s\nfiles: covered.txt\nfilesig: %s\n' "$fbrev" "$fbsig" > "$fb/.superstack/receipts/emitted-fb"
mk "$user" "$edit" "$claimtxt"
check "files-bound current receipt fast-passes"                    0 "$(run_in "$fb" false "Done. receipt: receipts/emitted-fb")"
( cd "$fb" && printf 'y\n' >> other.txt && git add other.txt && git -c user.email=t@t -c user.name=t commit -qm unrelated )
check "an unrelated commit does not stale a files-bound receipt"   0 "$(run_in "$fb" false "Done. receipt: receipts/emitted-fb")"
printf 'dirty\n' >> "$fb/covered.txt"
check "a dirty covered file stales a files-bound receipt"          2 "$(run_in "$fb" false "Done. receipt: receipts/emitted-fb")"
grep -q "FASTSTALE.*emitted-fb" "$fb/.superstack/gate-log" 2>/dev/null; check "the dirty-covered stale leaves its row" 0 "$?"
( cd "$fb" && git checkout -q -- covered.txt )
printf 'dirty\n' >> "$fb/other.txt"
check "a dirty UNcovered file does not stale it (false-stale guard)" 0 "$(run_in "$fb" false "Done. receipt: receipts/emitted-fb")"
( cd "$fb" && git checkout -q -- other.txt )
( cd "$fb" && printf 'v2\n' > covered.txt && git add covered.txt && git -c user.email=t@t -c user.name=t commit -qm covered-moved )
check "a committed covered change stales a files-bound receipt"    2 "$(run_in "$fb" false "Done. receipt: receipts/emitted-fb")"
printf 'command: check\nexit: 3\nrevision: %s\nfiles: covered.txt\n' "$(git -C "$fb" rev-parse --short HEAD)" > "$fb/.superstack/receipts/emitted-redrun"
check "a receipt recording a failing check never vouches"          2 "$(run_in "$fb" false "Done. receipt: receipts/emitted-redrun")"
grep -q "FASTRED" "$fb/.superstack/gate-log" 2>/dev/null; check "the failing-check refusal leaves its FASTRED row" 0 "$?"
if [ -f "$here/../scripts/superstack-mint.sh" ]; then
  ( cd "$fb" && bash "$here/../scripts/superstack-mint.sh" --receipt emitted-minted --files covered.txt -- true ) >/dev/null 2>&1
  check "a minter-written receipt fast-passes (recipes agree)"     0 "$(run_in "$fb" false "Done. receipt: receipts/emitted-minted")"
  printf 'dirty\n' >> "$fb/covered.txt"
  check "editing a covered file stales the minted receipt"         2 "$(run_in "$fb" false "Done. receipt: receipts/emitted-minted")"
else
  check "minter present for the integration rows" 0 "1"
fi
rm -rf "$fb"

# D-67: a campaign closure or milestone pass is receipts, not prose. A
# closure claim matches no claim stem, so it gets its own arm beside the
# frozen grammar — and unlike an ordinary done-claim, ledger wording never
# substitutes for the artifact: on a mutating turn a closure passes ONLY
# through the receipt fast path (cited, existing, fresh, passing run).
# Negated closures, questions, non-mutating turns, and bare-"closed" prose
# all stay silent — the arm is narrow and the cost of a false arm is one
# bounce demand, same price as everywhere else in this file.
cb="$tmp/cbrepo"
git init -q -b main "$cb"
( cd "$cb" && printf 'v1\n' > covered.txt && git add . && git -c user.email=t@t -c user.name=t commit -qm one )
mkdir -p "$cb/.superstack/receipts"
cbrev="$(git -C "$cb" rev-parse --short HEAD)"
cbsig="$( (cd "$cb" && git diff HEAD -- covered.txt; git status --porcelain -- covered.txt) | cksum | cut -d' ' -f1)"
printf 'command: check\nexit: 0\nrevision: %s\nfiles: covered.txt\nfilesig: %s\n' "$cbrev" "$cbsig" > "$cb/.superstack/receipts/emitted-cb"
mk "$user" "$edit" "$claimtxt"
check "a closure claim with no artifact cited bounces"             2 "$(run_in "$cb" false "M9 CLOSED on a light pass.")"
grep -q "CLOSEBOUNCE" "$cb/.superstack/gate-log" 2>/dev/null; check "the closure bounce leaves its CLOSEBOUNCE row" 0 "$?"
check "a closure citing a missing receipt bounces"                 2 "$(run_in "$cb" false "M9 CLOSED. receipt: receipts/emitted-gone")"
check "closure wording never substitutes for the artifact"         2 "$(run_in "$cb" false "M9 CLOSED. Verified: the full loop ran green.")"
check "a closure with a current receipt passes"                    0 "$(run_in "$cb" false "M9 CLOSED. receipt: receipts/emitted-cb")"
printf 'dirty\n' >> "$cb/covered.txt"
check "a closure citing a stale receipt bounces"                   2 "$(run_in "$cb" false "M9 CLOSED. receipt: receipts/emitted-cb")"
( cd "$cb" && git checkout -q -- covered.txt )
printf 'command: check\nexit: 3\nrevision: %s\nfiles: covered.txt\n' "$cbrev" > "$cb/.superstack/receipts/emitted-cbred"
check "a closure citing a failing-check receipt bounces"           2 "$(run_in "$cb" false "M9 CLOSED. receipt: receipts/emitted-cbred")"
check "a negated closure stays silent"                             0 "$(run_in "$cb" false "The milestone is not closed yet.")"
check "an interrogative closure stays silent"                      0 "$(run_in "$cb" false "Should the campaign be closed?")"
check "bare closed-prose without a campaign noun stays silent"     0 "$(run_in "$cb" false "Closed the file handle after the read.")"
check "a cited receipt path with an M-number does not arm closure" 0 "$(run_in "$cb" false "The receipts/emitted-m9-verify file is current.")"
mk "$user" "$filler"
check "a non-mutating closure statement stays silent"              0 "$(run_in "$cb" false "M9 CLOSED on a light pass.")"
mk "$user" "$edit" "$claimtxt"
check "a closure cite ending the sentence still passes (D-72)"     0 "$(run_in "$cb" false "M9 CLOSED. receipt: receipts/emitted-cb.")"
rm -rf "$cb"

# The freeze (D-47): any widening of claimre goes red here first; a new stem
# needs a DECISIONS.md ruling, not a drift observation.
pin=1411172341
now="$(grep '^claimre=' "$gate" | cksum | cut -d' ' -f1)"
[ "$now" = "$pin" ]; check "claimre is frozen at its ruled size (cksum pin)" 0 "$?"
rm -rf "$fp"

# D-79: line 1 of the bounce message addresses the HUMAN reading the session.
# The host renders a blocking Stop hook under an error banner; without a
# nothing-is-broken opener, the gate's catch reads as a crash to a new user.
mk "$user" "$edit"
printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false,"last_assistant_message":"%s"}' "$tmp/t.jsonl" "$claim" \
  | (cd "$tmp" && bash "$gate") >/dev/null 2>"$tmp/d79-err"
head -n 1 "$tmp/d79-err" | grep -q "Nothing is broken"; check "bounce line 1 addresses the human (D-79)" 0 "$?"

if [ "$fails" -eq 0 ]; then echo "all checks pass ($checks)"; else echo "$fails check(s) FAILED of $checks"; fi
exit "$fails"

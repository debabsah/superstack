#!/usr/bin/env bash
# superstack-prove — the evidence provider interface (plan adoption M7,
# D-74). Suite: hooks/test-provider.sh. Interface, never engine: a row in
# .superstack/providers is the owner's ack of an external driver command
# (browser, CI, test runner); this script resolves the named row and
# delegates the receipt write to scripts/superstack-mint.sh — exactly ONE
# receipt writer, so the mint/gate signature pairing pinned in
# test-gate.sh covers these receipts unchanged and the receipt's recorded
# command is the provider provenance. A missing file or unknown name
# refuses and never mints: a probe result is a proposal; only an
# owner-acked row is a driver.
#
# CONTAINMENT — the property the milestone rests on: a --url or --out value
# can never run as a command beside the acked one. The template is
# tokenized HERE, once, and the driver is executed as an argument vector,
# so no shell ever parses a value; it is data to the driver, whatever
# characters it carries. Escaping and construct blacklists were tried first
# and failed four audits running, always the same way: an escape holds for
# exactly one parse, and any construct that re-parses (command
# substitution, backticks, parameter expansion, arithmetic) buys a second
# one. Enumerating those constructs is a losing game; not building a shell
# string is not. Two shapes tokenizing cannot save, so both refuse: a
# placeholder in the command word (the value would name the program), and
# a command word that re-parses its own arguments (eval, source).
#
# The template is NOT shell-expanded: $HOME and ${HOME} are literal text,
# so a row carries absolute paths. Quoting in a row decides tokenization
# only.
#
# Row grammar, one per line — quote as you would a command line; {url} and
# {out} become literal arguments wherever they appear:
#   <name> [caps...]: <command template>
# Usage: superstack-prove.sh --provider <name> --url <url-or-path> \
#          --receipt <name> --files "<paths>"
# The artifact lands at .superstack/artifacts/<receipt>.png and the path is
# printed; it is never a caller's choice.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../hooks/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="$PWD"

prov=""; url=""; rcpt=""; files=""; out=""  # out is computed below, never supplied
while [ $# -gt 0 ]; do
  case "$1" in
    --provider) [ $# -ge 2 ] || { echo "superstack-prove: --provider needs a value" >&2; exit 64; }; prov="${2:-}"; shift 2 ;;
    --url)      [ $# -ge 2 ] || { echo "superstack-prove: --url needs a value" >&2; exit 64; }; url="${2:-}"; shift 2 ;;
    --receipt)  [ $# -ge 2 ] || { echo "superstack-prove: --receipt needs a value" >&2; exit 64; }; rcpt="${2:-}"; shift 2 ;;
    --files)    [ $# -ge 2 ] || { echo "superstack-prove: --files needs a value" >&2; exit 64; }; files="${2:-}"; shift 2 ;;
    *) echo "superstack-prove: unknown argument $1 — the artifact path is not a caller's choice; it is computed under .superstack/artifacts from the receipt name (usage: --provider <name> --url <u> --receipt <r> --files \"<paths>\")" >&2; exit 64 ;;
  esac
done
[ -n "$prov" ] && [ -n "$url" ] && [ -n "$rcpt" ] && [ -n "$files" ] || {
  echo "superstack-prove: --provider, --url, --receipt, and --files are all mandatory" >&2; exit 64; }
case "$prov" in *[!a-zA-Z0-9_-]*)
  echo "superstack-prove: provider name '$prov' — names are letters, digits, hyphen, underscore only" >&2; exit 64;;
esac
# A receipt name is a name, not a path: the gate looks receipts up by name
# under the record, so a name carrying a separator would write outside it
# and vouch for nothing.
case "$rcpt" in -*)
  echo "superstack-prove: receipt name '$rcpt' begins with a dash — whatever reads it next would take it for a flag" >&2; exit 64;;
esac
case "$rcpt" in *[!A-Za-z0-9._-]*|..|.)
  echo "superstack-prove: receipt name '$rcpt' — a receipt name is a name, not a path (letters, digits, dot, hyphen, underscore)" >&2; exit 64;;
esac
# A value is data to the driver, and a driver reads a leading dash as one
# of its own flags: the acked command would do something else entirely
# while the receipt still recorded success.
case "$url" in -*)
  echo "superstack-prove: --url '$url' begins with a dash and the driver would read it as a flag — pass ./<path> or an absolute path" >&2; exit 64;;
esac

pf="$root/.superstack/providers"
if [ ! -f "$pf" ]; then
  { echo "superstack-prove: no providers file at $pf — a row is the owner's ack of a driver command; add one per line:"
    echo '  <name> [caps...]: <command template — {url} and {out} become literal arguments>'
  } >&2
  exit 65
fi
row="$(grep -v '^[[:space:]]*#' "$pf" 2>/dev/null | grep -m1 -E "^$prov( \[[^]]*\])?:")"
if [ -z "$row" ]; then
  echo "superstack-prove: no row named '$prov' in $pf — add one (a row is the owner's ack); grammar: <name> [caps...]: <command template>" >&2
  exit 65
fi
caps="$(printf '%s' "$row" | sed -n 's/^[^:[]*\[\([^]]*\)\].*/\1/p')"; [ -n "$caps" ] || caps="undeclared"
# The template starts after the ROW's colon, not the first colon in the
# line: a caps bracket may legally carry one.
tmpl="$(printf '%s' "$row" | sed -E 's/^[A-Za-z0-9_-]+( \[[^]]*\])?: *//')"
if [ -z "$(printf '%s' "$tmpl" | tr -d '[:space:]')" ]; then
  echo "superstack-prove: row '$prov' has an empty command template — a receipt may only vouch for a command the row actually carries" >&2
  exit 65
fi

# Tokenize the template into the argument vector: quotes and backslashes
# group and escape, unquoted whitespace separates, and nothing expands.
# This is the only parse that ever happens.
argv=(); cur=""; have=0; st=n; i=0; n=${#tmpl}
while [ "$i" -lt "$n" ]; do
  c="${tmpl:$i:1}"
  case "$st" in
    n) case "$c" in
         ' '|'	') if [ "$have" -eq 1 ]; then argv+=("$cur"); cur=""; have=0; fi ;;
         '"') st=d; have=1 ;;
         "'") st=s; have=1 ;;
         '\') i=$((i+1)); cur="$cur${tmpl:$i:1}"; have=1 ;;
         *)   cur="$cur$c"; have=1 ;;
       esac ;;
    d) case "$c" in
         '"') st=n ;;
         '\') i=$((i+1)); cur="$cur${tmpl:$i:1}" ;;
         *)   cur="$cur$c" ;;
       esac ;;
    s) case "$c" in
         "'") st=n ;;
         *)   cur="$cur$c" ;;
       esac ;;
  esac
  i=$((i+1))
done
[ "$have" -eq 1 ] && argv+=("$cur")
[ "$st" = n ] || { echo "superstack-prove: row '$prov' ends inside an unclosed quote — balance the template's quoting" >&2; exit 65; }
[ "${#argv[@]}" -gt 0 ] || { echo "superstack-prove: row '$prov' tokenizes to no command" >&2; exit 65; }

# The command word comes from the row, never from a value, and it must not
# be a builtin that re-parses what it is handed.
case "${argv[0]}" in
  *'{url}'*|*'{out}'*)
    echo "superstack-prove: row '$prov' puts a placeholder in the command word — the row names the program, a value never does" >&2
    exit 65 ;;
  eval|source|.)
    echo "superstack-prove: row '$prov' has a re-parsing command word (${argv[0]}) — it would hand the value back to a shell; name the driver directly" >&2
    exit 65 ;;
esac
# `builtin` and `command` are one word in front of the same thing.
case "${argv[0]}" in
  builtin|command)
    case "${argv[1]:-}" in
      eval|source|.)
        echo "superstack-prove: row '$prov' has a re-parsing command word (${argv[0]} ${argv[1]}) — the prefix does not change what it does; name the driver directly" >&2
        exit 65 ;;
    esac ;;
esac
# A wrapper is one word in front of the program slot, and the rule above is
# that the ROW names the program. env, timeout and their family hand the
# next non-flag argument exactly that slot, so a placeholder there is the
# same defect one word later. A name list, and labelled as one: it catches
# the wrappers people actually write, not every possible runner.
case "$(basename "${argv[0]}")" in
  env|timeout|nohup|nice|setsid|stdbuf|time|xargs|ionice|chrt)
    _w=1; _wn=${#argv[@]}
    while [ "$_w" -lt "$_wn" ]; do
      case "${argv[$_w]}" in
        -*) ;;
        *[0-9]) case "${argv[$_w]}" in *[!0-9.]*) break ;; esac ;;
        *) break ;;
      esac
      _w=$((_w+1))
    done
    if [ "$_w" -lt "$_wn" ]; then
      case "${argv[$_w]}" in *'{url}'*|*'{out}'*)
        echo "superstack-prove: row '$prov' puts a placeholder in the program slot behind ${argv[0]} — the row names the program, a value never does" >&2
        exit 65 ;;
      esac
    fi ;;
esac
# A driver that IS a shell parses whatever it is handed, and no amount of
# care on this side changes that. The boundary is the ack itself: a row is
# the owner authorizing a command, and authorizing an interpreter
# authorizes what interpreters do. This check is a catch for the common
# footgun, never the boundary — it is a name list, and name lists are the
# thing five audits proved cannot be the guarantee.
# A placeholder standing in SCRIPT TEXT rather than in an argument of its
# own is the footgun worth catching, and shape catches it where a list of
# interpreter names cannot: a name list missed bash -lc, env bash -c, and
# every interpreter nobody thought to name. Two shapes read as script text.
# One is code punctuation around the value (quotes, parens, semicolons,
# pipes, redirects, dollar, backtick), which catches the long-option and
# attached-flag forms no flag rule can see. The other is a multi-word
# argument after a single-dash flag ending in c, e or r, the family
# interpreters use for script text; requiring several words is what keeps
# an ordinary -e URL={url} or -r {url} running. What this deliberately
# does NOT catch: a bare value after a long interpreter flag, because
# --eval {url} is indistinguishable in shape from --output {url}. The
# boundary stays the ack itself: a row is the owner authorizing a command,
# and authorizing an interpreter authorizes what interpreters do.
# Quotes, parens, semicolon and pipe only: a dollar or a backtick in a
# template is ordinary literal text under this design (nothing expands),
# and banning them would refuse honest rows while catching nothing an
# interpreter would not already reveal through its quoting or parentheses.
CODEPUNCT=$'"\'();|'
k=0; kn=${#argv[@]}
while [ "$k" -lt "$kn" ]; do
  case "${argv[$k]}" in
    *'{url}'*|*'{out}'*)
      case "${argv[$k]}" in *[$CODEPUNCT]*)
        echo "superstack-prove: row '$prov' wraps a placeholder in code punctuation, which is script text — a value handed to a parser stops being a value. Name a driver that takes the value as data (a script file or a binary), rather than an interpreter given script to run" >&2
        exit 65 ;;
      esac
      # The attached form is the same escalation with the space removed:
      # -eprint{url} carries neither punctuation nor whitespace, and a
      # value landing inside an interpreter's script text runs whatever it
      # says, past whatever narrow thing the row appeared to authorize.
      # A bare placeholder after a -c flag IS the whole script: nothing
      # takes a bare -c value as data, so this is the strongest shape of
      # all and was the one being let through while the exotic attached
      # form was refused. Deliberately not extended to -e or -r: those
      # carry ordinary values at real tools (a referer, an env pair, a
      # recursion switch), and refusing them would cost honest rows. That
      # leaves `perl -e {url}` on the recorded-limits list beside the long
      # form, where the ack itself is the boundary.
      if [ "$k" -gt 0 ]; then
        case "${argv[$k]}" in '{url}'|'{out}')
          # A flag belongs to the PROGRAM only before its first operand:
          # in `bash script.sh -nc x` the -nc is the script's, not bash's,
          # so the rule looks only at flags ahead of the first non-flag.
          # Exactly -c there means script text at any driver; the wider
          # cluster (-lc, -ec) means it only where the driver is a shell,
          # because -nc at wget and -avc at rsync are ordinary flags.
          _fnf=1; _fn=${#argv[@]}
          while [ "$_fnf" -lt "$_fn" ]; do
            case "${argv[$_fnf]}" in -*) _fnf=$((_fnf+1)) ;; *) break ;; esac
          done
          _cw="$(basename "${argv[0]}")"
          case "$_cw" in sh|bash|zsh|dash|ksh|csh|tcsh|fish) _shellish=yes ;; *) _shellish=no ;; esac
          _scripttext=no
          if [ $((k-1)) -lt "$_fnf" ]; then
            case "${argv[$((k-1))]}" in
              -c) _scripttext=yes ;;
              -[A-Za-z]*c) [ "$_shellish" = yes ] && _scripttext=yes ;;
            esac
          fi
          case "x$_scripttext" in xyes)
            echo "superstack-prove: row '$prov' hands the whole value to ${argv[$((k-1))]} as its script — a bare value there is not an argument, it is the program. Name a driver that takes the value as data" >&2
            exit 65 ;;
          esac ;;
        esac
      fi
      case "${argv[$k]}" in -[cer]?*|-[A-Za-z]*[cer]?*)
        echo "superstack-prove: row '$prov' attaches a placeholder to a script-text flag (${argv[$k]}), so the value lands inside the program the interpreter runs. Name a driver that takes the value as data, rather than an interpreter given script to run" >&2
        exit 65 ;;
      esac
      if [ "$k" -gt 0 ]; then
        case "${argv[$((k-1))]}" in -[cer]|-[A-Za-z]*[cer])
          case "${argv[$k]}" in *[[:space:]]*)
            echo "superstack-prove: row '$prov' puts a placeholder in a multi-word argument after ${argv[$((k-1))]}, which is how an interpreter is handed script text. Name a driver that takes the value as data, rather than an interpreter given script to run" >&2
            exit 65 ;;
          esac ;;
        esac
      fi ;;
  esac
  k=$((k+1))
done

# THE ARTIFACT PATH IS COMPUTED, NEVER SUPPLIED. It is built from a receipt
# name already validated as a name, so no caller string reaches it and
# there is no path to resolve: do not add a flag for it. Guarding a
# caller-chosen path means predicting where an external program's bytes
# land across symlinks, hardlinks, case folding, absent prefixes and
# races, and agreeing exactly with mkdir and the program — a predicate
# that cannot be written. A caller wanting the file elsewhere copies it
# afterwards; the receipt records the path either way.
#
# The artifact directory belongs to the product: replaced by a link, the
# one remaining guarantee is gone, so check before relying on it.
artl="$root/.superstack/artifacts"
if [ -L "$artl" ]; then
  echo "superstack-prove: $artl is a symlink — the artifact directory belongs to the product and must be a real directory; remove the link" >&2
  exit 64
fi
mkdir -p "$artl" 2>/dev/null
[ -d "$artl" ] || {
  echo "superstack-prove: $artl is not a directory — the artifact directory belongs to the product; move whatever is there" >&2; exit 64; }
out="$artl/$rcpt.png"
# The LEAF resolves too: a real directory says nothing about the name
# inside it, and the kernel follows a link or a hardlink at open(), which
# would walk driver bytes into a receipt. Removing the name first leaves
# the driver a fresh file and no link to follow.
rm -f "$out" 2>/dev/null
# ONE PASS, so a value can never pull in another value: substituting {url}
# first and {out} second let a --url of "{out}" become the artifact path.
i=0; n=${#argv[@]}
while [ "$i" -lt "$n" ]; do
  s="${argv[$i]}"; o=""; j=0; m=${#s}
  while [ "$j" -lt "$m" ]; do
    case "${s:$j:5}" in
      '{url}') o="$o$url"; j=$((j+5)); continue ;;
      '{out}') o="$o$out"; j=$((j+5)); continue ;;
    esac
    o="$o${s:$j:1}"; j=$((j+1))
  done
  argv[$i]="$o"
  i=$((i+1))
done

echo "superstack-prove: provider $prov (caps: $caps) — artifact: $out"
bash "$here/superstack-mint.sh" --receipt "$rcpt" --files "$files" -- "${argv[@]}"
mrc=$?
# The receipt names the artifact; when the driver wrote none, say so rather
# than leaving a reader to assume the file is there.
[ -e "$out" ] || echo "superstack-prove: no artifact at $out — the driver wrote none" >&2
exit "$mrc"

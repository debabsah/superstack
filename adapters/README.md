# Host support

superstack is a Claude Code plugin first. Its always-on layer, the shell hooks that read your workspace record back to every session and hold a "done" or a publish until there is proof, also runs on GitHub Copilot CLI, OpenAI Codex CLI, and Kiro CLI through adapters. The install commands are in the main README's Install section; this page holds what works on each host. A "no" means no, with what you do instead beside it.

## The matrix

| What you get | Claude Code | GitHub Copilot CLI | OpenAI Codex CLI | Kiro CLI |
|---|---|---|---|---|
| Session-start briefing: your goals, standing rules, and open work read back at the start of every session | yes | yes | yes | yes |
| Shaping offer: a raw idea typed into a fresh folder gets one offered question before building starts | yes | yes | yes | yes; Kiro has no structured question tool, so the offer arrives as plain prose |
| Publish gate: git push and other publish commands wait for a fresh go-public sweep | yes | yes | yes | yes |
| Done-claim gate: a turn that changed files cannot end on a bare "done" carrying no evidence | yes | yes, read from the session transcript (see below) | yes; the turn's changes are read from the session transcript (see below) | warns only: the gate's message prints in your session and the turn stands, because Kiro's stop event cannot block (see below) |
| Look gate: change a file with a face, claim done on logic-only evidence, get asked whether anyone looked | yes | yes, same transcript route | yes, same transcript route | warns only, same stop route |
| Compaction carrier: the project goal rides through context compaction | yes | no; Copilot ignores hook output at compaction, so the adapter registers no compaction hook and the goal returns at your next session start instead | untested; the hook is registered but a compaction has not been exercised there, and the goal returns at your next session start either way | no; Kiro has no compaction event, and the goal returns at your next session start |
| Workspace record: the plain-text `.superstack/` files your project grows | yes | yes, the same files | yes, the same files | yes, the same files |
| The 25 specialist skills | yes | no; not rehearsed there, so the adapter ports the always-on layer only | yes, they load: one extra install line places them where Codex reads skills, and all 25 list by name in a live session; how reliably the right one fires at the right moment is unmeasured there | no; Kiro loads no skill files, so the adapter carries the always-on layer only |

## Host notes

- Each adapter install needs the host CLI signed in, `jq` on PATH (without it every hook quietly does nothing), and the clone staying at the path where you installed it.
- Copilot: the config installs at the user level because repository-level hook files sit behind Copilot's interactive trust prompt, which a scripted run never sees.
- Codex: the installer refuses to touch a `hooks.json` it did not write and tells you what to copy by hand instead. Hook approval is one interactive step (Codex's `/hooks` command); scripted runs use Codex's own hook-trust bypass flag. Skills load from `.agents/skills` in your home directory for every project, or inside one project for that project alone; routing quality there is unmeasured, so treat it as best-effort.
- Kiro: hooks ride the agent config there, so the adapter installs as a Kiro agent (`~/.kiro/agents/superstack.json`). Use it per session with `kiro-cli chat --agent superstack`, or once for every session with `kiro-cli agent set-default superstack`; the installer changes no default itself, and it refuses a config file it did not write. Kiro keeps no session transcript, so the adapter writes the turn record the two turn-end gates read.

## What to know before relying on it

- On Copilot and Codex, the two turn-end gates depend on each host's session transcript: Copilot does not hand hooks the final message (the adapter reconstructs it), and on Codex the record of what a turn changed is read from the transcript. If a host update changes its transcript format, these gates stop firing rather than start blocking; every other row is unaffected.
- On Kiro, the two turn-end gates warn and cannot bounce: the host's stop event cannot block, so the gate's message prints in your session and the turn stands however it was judged. The publish gate blocks fully there, and a gate only governs a tool call the model actually makes; a model that balks on its own never meets it.
- Most gates bounce once and pass an identical retry, the same contract as on Claude Code. The destructive publish tier (`npm publish` and the other package publishes, `terraform apply`, `kubectl apply`, `docker push`) is stricter on every adapter host: it waits for a one-line grant file you write (`printf 'grant: npm publish\n' > .superstack/outward-grant`), consumed on use. `SUPERSTACK_GATES=off` silences every gate.

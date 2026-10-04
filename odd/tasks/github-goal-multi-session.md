# github-goal: multi-session safety and one issue in flight until merge

## Objective
Let several sessions (of the same person or of different collaborators) run
`github-goal` on the same repository without claiming the same issue or
clobbering each other's checkout, and never take a new issue until the current
one is delivered (PR merged).

## Problem
- Claiming is check-then-act: two sessions can both pass "nobody started it" and
  both claim the same issue.
- Everything is keyed on `@me`, so a second session of the same person treats the
  first session's live issue as "work to resume" (resume.md) and joins it.
- All sessions share one checkout (`git checkout <base> && pull`), so one session
  switches the other's branch.
- With `stopAt: "pr"`, goal mode moves on as soon as CI is green, before merge.

## Decision (user, 2026-10-04)
With `stopAt: "pr"`, goal mode waits for the human merge (polling with a cap)
and only then takes the next issue.

## Scope
- Claim marker with session id + heartbeat in the claim comment.
- Claim-then-verify (earliest active claim wins; loser releases and moves on).
- One git worktree per issue; base updated with fetch, never by switching the
  shared clone.
- Resume ignores live claims of other sessions; stale claims are adoptable.
- WIP = 1 per session: wait for merge (pollMinutes, timeoutMinutes), handle
  review feedback / red CI / conflicts while waiting; orphaned own work is
  adopted before any new issue.
- Config: repo `claims.ttlMinutes`; personal `mergeWait`.
- Docs: README, CHANGELOG, opencode command, version bump 2.1.0.

## Constraints
- Never invent status labels; never delete branches/stashes; never force-push.
- Artifacts in Spanish (existing skill language), neutral register.

## Tasks
- [x] T1 — Skill + references + config + docs + version bump (route: delegated
  direct — writer trigger, 6+ non-trivial files).

## Checks
- Passive markdown skill: no runnable RED (test-first exception). Structural
  readback: cross-references resolve, config keys documented in config.md,
  versions consistent across package.json / plugin.json / marketplace.json.

## Progress
- Branch `feat/github-goal-multi-session` created.
- T1 written (delegated writer, not yet verified/committed by parent):
  - New `references/concurrency.md`: session id, claim marker + heartbeat,
    active/stale/release, claim-then-verify, worktree per issue, WIP = 1,
    *Esperando merge* table, never-rules.
  - `SKILL.md`: *Varias sesiones* intro; 1.2 row "Clon principal" (dirty main
    clone is now ⚠️, not ❌); 1.4 fetch instead of checkout/pull; Paso 1b
    session/WIP note; Paso 2 plan line (session id, merge wait); *Selección*
    active-claim + WIP rule; Flujo steps 1, 2, 7, 9 (claim-then-verify,
    worktree, merge wait in goal mode, release + worktree removal).
  - `resume.md`: classification by claim marker (same session / active other /
    stale adoptable), worktree evidence, new rows (rama sin worktree, PR
    cerrado sin merge), goal-mode adopt-first, new never-rules.
  - `unblock.md`: no active claim; reclaim comment carries marker and is
    verified; return assignment if lost.
  - `config.md`: `claims.ttlMinutes`, `mergeWait`, `stopAt` row rewritten.
  - `github-lifecycle.md`: markers are hidden HTML comments; editing own claim
    comment allowed; `stopAt: "pr"` closing note.
  - `execution.md` / `archive.md`: work runs in the worktree; archive commit in
    a worktree from `origin/<base>`; archive after merge wait in goal mode.
  - README, CHANGELOG 2.1.0, versions 2.0.0 → 2.1.0 (package.json,
    plugin.json, marketplace.json). opencode command unchanged (no affected
    behavior described).

## Next step
T1.

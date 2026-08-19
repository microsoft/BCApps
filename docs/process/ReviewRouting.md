# Review routing: how a pull request finds its reviewer

This document explains the two mechanisms that decide who is asked to review a pull request, why
they must agree, and what still needs to change.

---

## There are two mechanisms, not one

This surprises people, and the difference matters:

| | `CODEOWNERS` | Ruleset `required_reviewers` |
|---|---|---|
| Lives in | `/CODEOWNERS` in the repo | repository rulesets (admin UI/API) |
| Effect | **requests** review from the owner when a PR opens | **requires** approval before merge |
| Drives | `review-requested:@me` — the personal queue | the merge gate |
| Changed by | a pull request | a repository administrator |

`CODEOWNERS` is what makes a review show up in a developer's inbox. The ruleset is what stops a merge.
They are independent, and today they disagree in places.

Note that `microsoft-production-ruleset` sets `require_code_owner_review: true`, so entries in
`CODEOWNERS` are not merely advisory — a code owner's approval is required.

---

## What was wrong

`CODEOWNERS` opened with a single default:

```
* @microsoft/dynamics-365-business-central
```

That team has **123 members**. Every pull request therefore requested review from 123 people, which
is the textbook setup for the bystander effect: a request addressed to everyone is owned by nobody.

The measurable consequence: **149 of 233 ready pull requests had no review decision at all**. GitHub
itself could not say who owed the review, so no filter, query or dashboard could either.

The `Official Branches` ruleset has the same shape — a `*` pattern requiring one approval from the
same 123-member team.

---

## What changed in `CODEOWNERS`

The team rules are now **generated** from the routing data the BCApps triage agent already uses to
classify issues and pull requests:

- `microsoft/BCAppsTriage` → `plugins/triage/skills/triage/scripts/ownership/ownership-rules.js`
- `microsoft/BCAppsTriage` → `plugins/triage/skills/triage/scripts/ownership/ownership-resolver.js`

which are in turn seeded from the Business Central Ownership Matrix. That agent already decides which
team owns an issue or pull request; deriving `CODEOWNERS` from the same data means **the team label
on an item and the reviewer GitHub requests cannot disagree**.

Previously this file was going to be hand-derived from the ownership matrix separately. That was a
mistake: a second, hand-maintained copy of the same mapping drifts from the first one immediately.
It also got several areas wrong — most of `src/Layers/*` and the country localization trees were not
routed at all, and `ExpenseAgent`, `Intrastat`, `Projects` and `Invoicing` were assigned to the wrong
team.

### Structure

The generated block is ordered **broad to narrow**, because `CODEOWNERS` resolves last-match-wins and
the resolver it mirrors is itself layered:

| Tier | Contains |
|---|---|
| 1 | Tree defaults — W1 apps and layers to Integration, every country tree to Finance |
| 2 | Base Application areas, for W1 and every localization layer, plus the Finance sub-ledgers that sit inside SCM area folders (`Sales/Reminder`, `Purchases/Payables`) |
| 3 | Other W1 layer trees, including per-area test ownership |
| 4 | W1 apps that are not Integration, plus the per-area `PowerBIReports` folders |
| 5 | Demo datasets, which follow the functional `DemoData/<Area>` folder rather than the app |
| 6 | Documented path overrides (for example the Italian Service Declaration) |
| 7 | Reconciliation pending — see below |

A consequence worth calling out: **a team appears in more than one tier**. Grouping every rule for a
team together would be easier to read, but it cannot reproduce the resolver's precedence, so
correctness wins.

### Verification

Two properties are checked mechanically over all 46,437 tracked files:

| Check | Result |
|---|---|
| Generated block reproduces the triage resolver's path decision | **44,796 of 44,796 files (100%)** |
| Pre-existing non-default ownership changed | **0 files** |
| Files moved off the 123-member default owner | **37,694** |

Where the final file differs from the triage resolver, it is always because a specialized rule lower
in the file deliberately takes precedence — `app.json` to the app team, `*.ps1` and `/build` to
Engineering Systems, `dotnet.al` to App Security, `*.Entitlement.al` to Integration, and the Copilot
and Developer Tools carve-outs inside the System Application. That is the intended
"Integration owns the System Application, with sub-sections owned by others" shape.

### How closely this matches the labels the agent actually applies

Reproducing the resolver is not the same as matching the team label a pull request ends up with, so
that was measured separately over 425 labelled pull requests:

| Outcome | PRs | Share |
|---|---|---|
| Single-team PR, `CODEOWNERS` matches the label | 312 | 73.4% |
| Multi-team PR, labelled team is the dominant owner | 68 | 16.0% |
| Multi-team PR, labelled team owns a minority of files | 13 | 3.1% |
| `CODEOWNERS` never requests the labelled team | 25 | 5.9% |
| No team owner at all | 7 | 1.6% |

**`CODEOWNERS` requests the labelled team on 92.5% of pull requests.**

Exact one-to-one agreement is neither expected nor desirable, for two structural reasons:

- **They answer different questions.** The agent picks a *single* team per item. `CODEOWNERS`
  requests *every* owner of *every* touched file, so a pull request spanning two teams correctly
  gets two reviewers. That accounts for most of the difference.
- **The agent reads file content.** `resolveTeamForFile` tries overrides, then object id, then
  namespace, and only then path. `CODEOWNERS` can only ever see the path, so the two must diverge
  wherever a file's namespace or object id disagrees with its folder.

### Two disagreements left unresolved on purpose

The triage rules and today's `CODEOWNERS` genuinely disagree in two places. Taking ownership away
from a team is not something this change should do silently, so current ownership is preserved in
tier 7 and the disagreement is recorded instead:

- **`PowerBIReports`** — the triage agent resolves its per-area report folders to the area owner
  (`App/Sales` to SCM); `CODEOWNERS` has owned the whole app as Finance since #9752.
- **`ServiceManagement`** — `appFolderRules` says SCM; `CODEOWNERS` says Finance.

Both should be settled in `ownership-rules.js`, after which tier 7 disappears on the next
regeneration.

### Findings for whoever maintains `ownership-rules.js`

Three things surfaced while checking the 25 disagreements. None of them block this change, but each
is a genuine inconsistency in the upstream rules rather than something `CODEOWNERS` should paper
over:

1. **Intrastat** is forced to SCM by an override keyed on the *namespace*
   `Microsoft.Inventory.Intrastat` and object id 4810 — explicitly so that "PRs and issues agree" —
   but `appFolderRules.Intrastat` says `Finance`. A path-only consumer cannot see the namespace, so
   `CODEOWNERS` routes Intrastat to Finance. A path rule would close the gap.
2. **`BaseApp/Projects`** — `baseAppAreaRules.Projects` says `Finance`, while
   `subAreaToTeam['Projects']` and the ownership matrix both say SCM. The agent resolves SCM via
   object id (Job, table 167). The two data sections contradict each other.
3. **Country E-Document labels look stale.** Seven of the 25 disagreements are country E-Document
   apps labelled `Integration`, while `ownership-rules.js` carries an override routing them to
   Finance whose comment notes it "deliberately supersedes the earlier #9172 decision". Those labels
   predate the override and would benefit from a re-run of classification.

### What this costs the teams

Because code owner review is required, these entries make each team a required approver for its
paths. From currently open, non-draft pull requests that have a team owner — 187 of them, of which
**53 touch more than one team** and therefore need approval from each:

| Team | Members | Open PRs | Per member |
|---|---|---|---|
| Finance | 8 | 91 | 11.4 |
| SCM | 9 | 73 | 8.1 |
| Integration | 10 | 90 | 9.0 |

Integration changes the most: it previously owned almost nothing in `CODEOWNERS` and now owns the
System Application, Business Foundation, the migration and connector apps, and every unlisted W1 app.

### Regenerating
Edit `ownership-rules.js` in `BCAppsTriage` and regenerate. The generator reads `ownership-rules.js`
and `ownership-resolver.js` directly, so it lives alongside them in `BCAppsTriage` rather than here.
Do not hand-edit the generated block.
Hand edits are lost on the next regeneration and silently diverge from issue and pull request triage.
## What still needs to change (requires an administrator)
`CODEOWNERS` alone does not finish the job. The `Official Branches` ruleset still contains:

```
file_patterns: ["*"]  ->  dynamics-365-business-central (123 members), minimum_approvals: 1
```

While that rule stands, every pull request still requires an approval from the 123-member group, so
the merge gate remains anonymous even though the *request* is now correctly routed.

**Recommendation:** replace the `*` catch-all with the same three team patterns used in `CODEOWNERS`,
keeping `*` only as a fallback for paths no team claims. This must be done by someone with repository
administration rights, and should follow — not precede — the `CODEOWNERS` change, so that routing is
proven before the merge gate is tightened.

---

## Why routing has to be fixed first

Until a review request lands on a named team, `reviewDecision` stays empty — and an empty
`reviewDecision` is exactly the state that no query, filter or report can triage. Any later work on
making the backlog visible depends on this being right first.

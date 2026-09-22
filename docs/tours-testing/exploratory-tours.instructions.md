---
description: "Exploratory testing with tours: charters, the tour catalogs, how to run a session against Business Central, and how to record findings."
---

# Exploratory testing with tours

Stand up a local BC container, drive the web client with Playwright, use SQL as the oracle.

**This is the entry point.** Three companion documents own the mechanics, and each fact lives in
exactly one of them:

| Document | Owns |
| --- | --- |
| [`bc-test-environment.instructions.md`](./bc-test-environment.instructions.md) | Container lifecycle: create unattended, URL, credentials, cold start, teardown |
| [`playwright-bc.instructions.md`](./playwright-bc.instructions.md) | Driving the client and querying the database |
| [`harness/`](./harness/README.md) | Runnable code — helpers, scanners, worked probes |

## Starting a session

```powershell
# 1. Container — ~20 min, unattended, no prompts. Run from the repo copy.
.\docs\tours-testing\harness\New-TourContainer.ps1

# 2. Scratch working copy (node_modules is not committed)
$RUN = "$env:USERPROFILE\.copilot\session-state\<id>\files\harness"
Copy-Item .\docs\tours-testing\harness\*.js,.\docs\tours-testing\harness\*.ps1 $RUN -Force
cd $RUN ; npm init -y ; npm i -D playwright ; npx playwright install chromium

# 3. Point the harness at this tour's container (printed by step 1)
$env:BC_CREDS = "$env:USERPROFILE\.bc-tours\BCApps-Tours-credentials.json"

# 4. Sign in once by hand — the first sign-in compiles server-side and takes 60 s+

# 5. Pick an area that has data (§3), then a theme (§2)
.\Find-TourTargets.ps1 -Path ..\..\..\src\Apps\W1\<app>\app

# 6. One probe at a time
node mytour.js probe-name
```

Several tours can run at once against separate containers — pass `-ContainerName` in step 1 and
give each session its own `BC_CREDS`. See the harness README.

Then write a session sheet (§8). Before filing anything, read §5.

---

Exploratory testing is **simultaneous learning, test design and test execution** — time-boxed,
chartered and documented. It finds what scripted tests cannot, because scripted tests only assert
what someone already thought of.

A **tour** is a themed constraint on where you look. Not "test the Customer Card" but "visit only
the things a user would abandon halfway through". The theme is what makes a session systematic
instead of random.

## 1. Charter

One sentence, with a time-box:

> **Explore** \<area\> **with** \<technique\> **to discover** \<information\>.
>
> *Explore sales invoice posting with interrupted and abandoned exits to discover double-posting,
> orphaned documents, or inconsistent ledger state.*

A charter is a mission, not a script. 60–90 minutes is a normal session. Stop when the box is
empty, not when you run out of ideas — leftover ideas become the next charter.

`<area>` and `<technique>` are chosen separately and have separate failure modes. See §2 for
themes, §3 for areas.

## 2. The two tour catalogs

Different tools; do not conflate them.

### Kelly's FCC CUTS VIDS — reconnaissance

For an **unfamiliar** area, when you need orientation fast.

| Tour | Question | BC example |
| --- | --- | --- |
| **F**eature | What can this do? | Walk every ribbon action on a card |
| **C**omplexity | Where is the hardest case? | Nested dimensions; multi-line documents |
| **C**laims | Does the documentation tell the truth? | Test tooltips as assertions |
| **C**onfiguration | What changes behaviour? | Toggle setup fields; change posting groups |
| **U**ser | Who uses this? | A full order-to-cash cycle as one persona |
| **T**estability | What tools would help? | Page IDs, filters, SQL, telemetry |
| **S**cenario | What is a plausible story? | Quote → order → ship → invoice → payment |
| **V**ariability | What can be varied? | Currencies, locales, number series, dates |
| **I**nteroperability | What does it touch? | Extensions, APIs, exports, other modules |
| **D**ata | What data does it hold? | Boundary values, long strings, negative amounts |
| **S**tructure | What is it built from? | Objects, tables, layers, dependencies |

### Whittaker's districts — themed bug hunting

For an area you **know**, when you want defects in a specific style.

| District | Tours |
| --- | --- |
| **Business** | Guidebook, Money, Landmark, Intellectual, FedEx, After-Hours, Garbage Collector |
| **Historical** | Bad Neighborhood, Museum, Prior Version |
| **Tourist** | Collector, Lonely Businessman, Supermodel, Scottish Pub |
| **Entertainment** | Supporting Actor, Back Alley, All-Nighter |
| **Hotel** | Rained-Out, Couch Potato, Cancelled Bus |
| **Seedy** | Saboteur, Antisocial, Obsessive-Compulsive, Crime Spree |

The ones used most here:

- **Cancelled Bus** — abandon an operation mid-flight: Escape, Back, reload, close the tab, click
  twice. Finds commit/rollback asymmetries.
- **Couch Potato** — accept every default, type as little as possible. Finds bad defaults.
- **Saboteur** — deliberately break the rules: edit a released document, post into a closed period.
- **Intellectual** — the hardest input you can construct.
- **Obsessive-Compulsive** — repeat, submit twice, undo and redo.
- **Money** — the arithmetic: rounding, currency conversion, VAT, totals.
- **Back Alley** — the least-used features, where coverage is thinnest.

> Treat the catalog as a thinking aid, not a standard. The theme matters; the label does not.

## 3. Choosing an area — churn is not enough

"Tour whatever changed most recently" is a good first filter and a bad last one. An area must pass
**four** gates:

| Gate | Question | Check |
|---|---|---|
| 1. Churn | What changed? | `git log --numstat` aggregated per app folder |
| 2. Surface | Does it have a *page* surface? | `Find-TourTargets.ps1` field count |
| 3. Installed | Is the app in *this* container? | `Get-BcContainerAppInfo -tenantSpecificProperties` |
| 4. **Data** | Is there anything to tour *with*? | `SELECT COUNT(*)` on its master tables |

Gates 2 and 4 are the ones that bite.

**Churn without surface.** `MasterDataManagement` ranked third on a 14-day churn scan (~4,700
lines) and defines **37 fields** in total — the churn is all in synchronisation codeunits. High
churn in codeunits means *write integration tests*, not *run a tour*.

**Churn without data.** The five highest-churn areas (Sustainability, ExpenseAgent, EDocument,
Shopify, ExciseTaxes) were all installed, all healthy, and all had **zero rows** in their master
tables. This is structural, not bad luck: the highest-churn areas are the newest apps, and CRONUS
demo data covers the classic Base Application. **Run the census before planning probes.**

### 3.1 When the area is empty, the empty state *is* the tour

Every new customer starts where you are, so the bootstrap path is both the least-exercised path in
the product and the one nobody can avoid. Three charters that need no data:

- **First-run** — can a user get data in at all? Tour the demo-data generator and setup wizard.
- **Empty-state** — open every list and card with zero rows. Does it say *"There is nothing to show
  in this view"*, or throw?
- **Landmark** — walk the setup pages, checking each `ToolTip` claim (§6.1).

This is where the highest-churn area actually failed: `Contoso Demo Tool` `Generate` produced a raw
platform error, because the generator is not idempotent. Three controls (nothing selected,
Sustainability selected, Inventory selected) all gave the identical error, which turned one symptom
into a *claim about the cause*. A single run would have reported the wrong thing entirely.

**A confirmed diagnosis is not an unblocked tour.** Generating into a fresh company removed the
collision exactly as predicted — and then stalled at 8 of 22 modules on unsatisfied prerequisites.
In CRONUS the failure rolled back cleanly; in the fresh company it left a **silently half-built**
company, the worst possible oracle. Re-run the census after a workaround, not just after a failure.
When the bootstrap path is broken, stop and pick an area that has data.

## 4. Running a session

1. **Prepare the environment** — [`bc-test-environment.instructions.md`](./bc-test-environment.instructions.md).
   Record the exact build; `main` publishes daily insider builds.
2. **Build the oracle before the first probe**, not after. The moment you start touring you will be
   tempted to believe the screen. Find the real table names, snapshot the state the tour will
   disturb, and confirm which column actually answers your question — see §9 of
   [`playwright-bc.instructions.md`](./playwright-bc.instructions.md).
3. **Tour.** Follow the theme. Note everything surprising, including what you cannot explain.
4. **Investigate afterwards, not during.** Chasing each anomaly as it appears destroys coverage.
5. **Write the session sheet** (§8) while it is fresh.

### Where automation fits

Do the first pass **manually** — the point of a tour is noticing the unexpected, and automation
only does what you told it. Use Playwright for the second pass, where it beats a human: exits a
human cannot time precisely, the same probe repeated across six documents, before/after SQL deltas,
and turning a confirmed finding into a regression check.

### Two reference sources, two different questions

| Source | Answers | Use for |
| --- | --- | --- |
| The AL source in this repo | *What does it do?* | Triage: is this intended? Where are the hard paths? |
| [BC product documentation](https://learn.microsoft.com/en-us/dynamics365/business-central/) | *What is it supposed to do?* | Charters, expected behaviour, and as an oracle |

The documentation matters more than it looks. It is the written form of user expectation, and the
**Claims** tour is precisely the exercise of treating documented statements as assertions. Skimming
the docs for an area before a reconnaissance tour is legitimate; reading its implementation is not,
because it biases you toward testing what the code does rather than what a user expects.

**Tour black-box first, read the source during triage.** When code and documentation disagree, that
disagreement is itself the finding — record both references and let the owning team settle it.

## 5. Not filing false findings

This is the discipline the whole method rests on. Four rules, each of which has caught a real
mistake in this repo's own sessions.

### 5.1 Assert against the database, not the screen

The UI read-back is frequently empty, and page text is an actively misleading oracle: a
`/posted|successfully/i` match hit the **"Posted Sales Invoices"** FactBox *caption* and reported
three phantom successes. A field readback has also disagreed with BC's own error message — the
error was right.

Verify every result in SQL, **including the ones that looked fine**.

### 5.2 Check configuration, source and documentation before filing

Three queries, and the highest-value habit here.

- **Configuration.** No credit-limit warning on a 649-billion order — that customer's limit is `0`,
  which BC treats as *no limit*. Posting 999,999,999 units against 261 in stock — `Inventory
  Setup."Prevent Negative Inventory"` is `false` in CRONUS.
- **Source.** A narrow, explicit guard is evidence the unguarded case is *intended*. Sales lines
  reject a negative `Unit Price` only when `Prepayment % <> 0`. That specificity is deliberate.
- **Documentation.** It can state outright that your "bug" is the prescribed workflow. Negative
  quantities on sales lines looked like missing validation until the returns documentation turned
  up the instruction to *"make a negative entry… by inserting a negative amount in the Quantity
  field"*, with a **Move Negative Lines** action supporting it.

That last one was written up, then withdrawn. **"The system let me do X and said nothing" is never
a finding on its own.**

Inconsistency between neighbouring fields is a tempting signal and a weak one: `Line Discount %` is
range-checked and `Unit Price` is not, and that asymmetry is *correct* — one has a mathematical
range, the other carries meaning in its sign.

### 5.3 Run a control before believing "nothing happened"

Silence has two causes — the product refused, or your harness never acted — and they are
indistinguishable from the result alone.

A finding claimed a released order silently discards a new line. The same probe against an **open**
order produced the same nothing: same empty cell, same absent error, same single row in SQL. The
open order should have accepted it, so the instrument was at fault.

The control is cheap: the same probe against a document where the action is legal. Positive results
mostly speak for themselves; **negative results need a control.**

### 5.4 Sort every observation into exactly one bucket

| Kind | Belongs where | Example |
| --- | --- | --- |
| **Product finding** | the issues file, with a ruling question | Negative unit price accepted silently |
| **Verified non-finding** | session sheet, "works well" | No credit-limit warning — limit is 0 |
| **Harness artefact** | session sheet, harness notes | `fill()` without Tab never commits |

The middle row is what makes a sheet trustworthy — a sheet containing only findings tells the
reader nothing about how hard you looked. Conflating the first and third is how false bug reports
reach a team.

Mark anything unconfirmed as unconfirmed.

## 6. Metadata is the specification — read it before you probe

BC pages and tables are generated from metadata, so much of the behaviour you are about to test is
*declared*, not written. The platform enforces some properties for free, everywhere, identically:

- A field **with** `MinValue`/`MaxValue`/`NotBlank`/`TableRelation` is guarded generically. Testing
  it tells you about the *platform*. **Do not spend tour time there.**
- A field **without** them is guarded only by hand-written AL in `OnValidate` — or not at all.
  **That is where the tour belongs.**

Two adjacent decimals on `Sales Line` prove it. `Line Discount %` declares `MinValue = 0` /
`MaxValue = 100` and rejects `101` before AL runs. `Unit Price` declares neither and accepts `-500`.
Not a bug in either — two lines of metadata, visible without running anything.

**Asymmetric bounds are the sharpest targets.** `Sustainability Jnl. Line."Time Factor"` declares
`MaxValue = 1` and no `MinValue`. A bound on one side only means someone thought about the range
and stopped halfway.

### 6.1 Tooltips are testable claims

A `ToolTip` saying *must*, *cannot*, *only*, *never*, *automatically* or *before you* is an
assertion the product makes. If no metadata property backs it, either AL enforces it by hand or
nobody does — and an untrue claim is a finding on its own.

This is how SAB-1 was found: the Sales Order release tooltip says *"You must reopen the document
before you can make changes to it"*, while `Sales Header` has an explicit `Status::Released` branch
permitting edits to `External Document No.`

### 6.2 The scanners

| Script | Answers |
|---|---|
| `Find-TourTargets.ps1 -Path <app>` | What is worth probing in this app? Buckets every field into *unbacked tooltip claim* / *unbounded numeric* / *platform-guarded* |
| `Find-UnguardedFields.ps1 -Table <t>` | Which fields on this document table have no status guard? |
| `Find-TourDrift.ps1` | Where do two parallel tables disagree? (§7) |
| `Find-PageDrift.ps1` | Where do pages sharing one table disagree? (§7.2) |

The bucket ratio characterises an app before you open a browser:

| Area | Fields | Platform-bounded | Unbacked tooltip claims |
|---|---|---|---|
| Shopify | 1002 | **1** | 12 |
| Sustainability | 1475 | 16 | 2 |
| ExpenseAgent | 980 | 20 | 23 |
| ExciseTaxes | 59 | **13** | 0 |

`ExciseTaxes` guards 22% of its fields declaratively; `Shopify` guards 0.1% of 1002. Those need
completely different tours.

A scan also sees every table at once, which no single-page tour does: `Excise Duty %` declares
`MaxValue = 1000` on two objects but **not** on `ExciseTaxesTransLogExt`, so a value the journal
rejects can still land in the transaction log. A static finding, no container required.

### 6.3 Four ways a guard scan produces a confident wrong answer

**This section is the most important one in the document.** Every scan-based prediction made in
these sessions was wrong, and always in the same direction — the scan under-reports guarding and
you file a defect that does not exist.

**1. The guard is one or more hops away.** A scan reported `Purchase Line."Direct Unit Cost"` as
unguarded. The UI refused it:

```
field(22; "Direct Unit Cost")  OnValidate -> Validate("Line Discount %")
field(27; "Line Discount %")   OnValidate -> ValidateLineDiscountPercent(true)
                                              -> TestStatusOpen() -> TestField(Status, ::Open)
```

Guards also arrive from table triggers (`OnInsert`/`OnDelete` call `TestStatusOpen()`, so inserting
a line is guarded without any *field* declaring it) and from shared procedures. The worst case seen:
Service `Customer No.` does not test the status — it **deletes the lines**, and the line deletion
tests it. No per-field scan at any level finds that.

**2. The guard is at page level, not table level.**

| Level | Where | Looks like | Blocks |
|---|---|---|---|
| **Table** | field `OnValidate` | `TestStatusOpen()` | every writer — UI, API, OData, AL |
| **Page** | field property | `Editable = (Rec.Status = Rec.Status::Open)` | only *that page* |

Sales and Purchase guard `Shipment Method Code`, `Location Code` and `Currency Code` in the table.
Transfer leaves them unguarded there and writes `Editable = …` on page 5740 instead. Both refuse
the edit in the web client, so a UI-only tour sees identical, correct behaviour — but a page-level
guard is bypassed by any other writer.

So: a table scan alone **mispredicts the UI**, and a UI probe alone **misses the risk**. Check both
levels before recording either a finding or a non-finding. Page guard only → safe here, unproven
elsewhere; note it as an API-surface hypothesis.

**3. The idiom is framework-specific.** Scanning `Service Header` for `TestStatusOpen` reported
**0 of 139 fields guarded** — a 100% false negative. Service never calls it; it writes
`TestField("Release Status", "Release Status"::Open)` inline. The true figure is 6 of 139.

| Control | Framework | Identifier |
| --- | --- | --- |
| Document is open | Sales, Purchase, Transfer | `TestStatusOpen()` |
| Document is open | Service | inline `TestField("Release Status", …::Open)` |
| Posting date allowed | Sales, Purchase | `GenJnlCheckLine.IsDateNotAllowed` |
| Posting date allowed | Service | `GenJnlCheckLine.DateNotAllowed` |
| Posting date allowed | Inventory / Transfer | `UserSetupManagement.CheckAllowedPostingDate` |

The last row nearly became a High-severity false report: grepping for `IsDateNotAllowed` returns
Sales and Purchase only, and Transfer returns nothing — which reads as a period-control bypass. It
is not. Transfer posts through the item journal, where `ItemJnlCheckLine.CheckDates` calls a third
differently-named procedure enforcing the same rule, **plus** an `Inventory Period` check the others
lack. Transfer is checked more strictly, not less.

Service adds a fourth mechanism: high-consequence fields gated on whether the document has lines,
via a *confirmation* rather than a refusal.

**4. The behaviour is deliberate.** All four frameworks implement
`UpdateExternalDocNoForReleasedOrder` — `External Document No.` is *meant* to stay editable after
release, and changing it propagates to the linked warehouse request. `Vendor Invoice No.` has no
such branch and no guard, yet must stay editable: it is the vendor's number, required at posting
and unknowable before release. Semantics count even without a code branch.

**The discipline that catches all four:**

1. **Search for the control, not the name.** Ask what enforces the rule, and follow the call path
   to the setup field it reads (`Status`, `Release Status`, `Allow Posting From`/`To`).
2. **An absence is never evidence.** A zero-match grep means "not under this name here".
3. **Follow the posting path** into the shared engines — `GenJnlPostLine`, `ItemJnlPostLine`. A
   check missing from a document codeunit is usually in the engine.
4. **Sanity-check the shape.** A control in 2 of 4 frameworks is far more likely a naming
   difference than a real gap in a mature product. Treat **0% or 100% guarded** as a bug in your
   regex until proven otherwise; real tables land in between.
5. **Search the field for `Status::Released` and read its tooltip** before probing.

> Before filing any "X is not checked", state where you would expect the check and prove you looked
> there. A predicted gap the product closes is still a useful result — it says the guard is
> implicit, a maintainability risk worth reporting even when behaviour is correct.

### 6.4 Page metadata decides what a UI result *means*

Table metadata tells you what to probe; **page** metadata tells you how to read the answer.

| Property | Why a tour cares |
| --- | --- |
| `Editable = false` | The page cannot be typed into. A column that looks like an input is an *output*. |
| `CardPageID` | `New` opens a **card**; it does not insert an inline row. |
| `InsertAllowed` / `DeleteAllowed` | `New`/`Delete` may be absent or inert by design. |
| `SourceTableView` | Rows can be legitimately invisible rather than missing. |

Two probes were nearly misreported over this. `Contoso Demo Tool`'s `Data Level` column was read as
a selector to set before generating — the page declares `Editable = false`, so it is a *result*.
Clicking `New` on `Sustainability Account List` left the list empty and looked inert — the page
declares `CardPageID`, so `New` was never going to add a row.

**Before you write "nothing happened", read the page's property block.**

Beware the inverse, too: `SalesLinesEditable()` keys off whether a **party is selected**, not off
`Status`. The lines grid on a released document still takes focus and accepts typing; the refusal
comes later, from the table. "The released grid let me type into it" is not a finding — expect it.

### 6.5 Sequential probes on one record contaminate each other

Five fields on one document in one pass is not five independent experiments. BC re-derives fields
from each other. On open transfer order 1001 the probe reported `Shipment Date` ACCEPTED (`2/1` →
`2/20`); SQL afterwards showed `2028-02-01`, because the next probe changed `In-Transit Code`,
which recalculated the shipment date from the route's shipping time.

> **One mutating probe per record, or re-read the oracle after every step.** A "confirmed" result
> that was overwritten two probes later is worse than no result.

### 6.6 Git history cannot tell you *when* a pattern arrived

`git log -S` is the obvious way to decide whether a divergence is deliberate scoping or an
incomplete rollout. **It does not work in this repo.** BCApps is populated by squashed sync commits
from an internal repository, so `-S` reports the *import* commit — four pages that adopted the same
pattern all report the same date and SHA.

History answers *"what changed recently?"* (§3) but never *"which came first?"*. When intent depends
on chronology, say the evidence is unavailable and route the question to the owning team.

## 7. Differential touring across parallel modules

BC contains near-duplicate subsystems — Sales vs Purchase, Quote/Order/Invoice/Credit Memo, Item vs
Resource vs G/L Account lines. They were written from one template and maintained separately, so
**they drift**. Each module is its own control: if two parallel fields behave differently, at least
one is wrong, and you need no specification to say so.

1. Extract the same property from both tables — e.g. which fields call `TestStatusOpen()`.
2. Join on an **explicit list of analogous field pairs**.
3. Every divergence is a candidate; every *agreement* generalises a finding you already have.

| Sales | Purchase | Sales guarded | Purchase guarded |
|---|---|---|---|
| `Assigned User ID` | `Assigned User ID` | yes | **no** |
| `VAT Base Discount %` | `VAT Base Discount %` | yes | **no** |
| `Shipment Date` | `Expected Receipt Date` | yes | **no** |
| `Job No.` | `Job No.` | no | **yes** |
| `External Document No.` | `Vendor Invoice No.` | no | no (symmetric) |

The symmetric rows are as valuable as the divergent ones: both unguarded predicted — and the UI
confirmed — that the Sales tooltip finding applies verbatim to Purchase Orders, converting an
app-specific report into a document-framework one.

### 7.1 Join on explicit pairs, never on a regex rename

The first attempt normalised names (`Buy-from Vendor` → `PARTY`, `Sell-to Customer` → `PARTY`) and
reported `Buy-from Vendor No.` as unguarded. It is not. `Purchase Header` contains **both**
`Buy-from Vendor No.` (field 2, guarded) and `Sell-to Customer No.` (field 72, the drop-shipment
customer, unguarded). Both normalised to one key and the later overwrote the earlier.

Write the pairs by hand and keep unmatched fields visible so you can see what the join dropped.

### 7.2 When the table is shared, the *pages* are the differential

The six sales document types share **one** table (`Sales Header` 36) discriminated by an enum, so a
table differential is vacuous by construction. Everything distinguishing them lives in the pages
(41, 42, 43, 44, 507, 6630). Build the matrix from page field declarations: record each field's
`Editable`/`Enabled` expression per page, group identical expressions under a letter, print only
rows where letters disagree.

```
FIELD                          Q O I C B R      . = absent from that page
Ship-to Address                L L L . L -      - = present, no Editable/Enabled property
Customer Posting Group         . F F F . F
```

Read the shapes, not the cells. `L L L . L -` — a 1-vs-5 outlier is the classic drift signature.
`. F F F . F` — absent exactly where it is meaningless (Quote and Blanket Order never post) is a
semantic boundary, not drift.

**The worked example and its honest verdict.** `ShipToOptions`/`BillToOptions` — which locks the
ship-to address unless the user picks *Custom Address* — is on Quote, Order, Invoice and Blanket
Order, and **entirely absent** from Return Order and Credit Memo. Deliberate outbound-vs-return
boundary, or a rollout that never reached the return family? Deciding needs chronology, which this
repo cannot supply (§6.6). The disciplined output is a **question for the owning team**, not a
filed defect.

> A differential tells you **where** to look, never **who is wrong**. Promote a divergence to a
> finding only when you can name the harm or show the inconsistency is user-visible.

## 8. Session sheet template

One file per session, in `docs/tours/`.

```markdown
# Session sheet — <tour> on <area>

## Charter
Explore <area> with <technique> to discover <information>.

## Environment
| | |
| --- | --- |
| Date | |
| Container / build | e.g. 30.0.54921.0-W1 (insider daily) |
| Company | CRONUS International Ltd. |
| Driver | manual / Playwright <version> |
| Credentials | by reference: path + container name, never the value |

**Oracle:** which tables and queries establish truth, and the baseline values.

## Probes and results
| # | Probe | Target | Expected | Observed | SQL delta |

## Findings
F1 — <one line>. Evidence. Why it matters. Confirmed / unconfirmed.

## Issues
Problems with the *harness or session* — kept strictly separate from findings.

## Data mutated
Everything this session changed, so the next tour knows what it inherits.

## Task breakdown
Rough split: test design & execution / investigation / setup.

## Follow-up charters
The ideas you did not have time for.

## Verdict on the method
Did this tour earn its time against this area?
```

## 9. Does a new tour need a clean container?

Usually **no** — residue is fine when every probe takes its own before/after snapshot and no oracle
is an absolute count. Start fresh when:

- the oracle *is* a count, or a "there should be exactly one" assertion;
- a previous tour changed **setup** rather than data;
- a previous tour moved the world somewhere strange (item `1896-S` now sits at ≈ **-1,000,000,000**
  on hand);
- you are producing a minimal reproduction for a bug report.

Recreating is ~20 minutes. Deciding deliberately is the point.

## 10. Anti-patterns

- **Touring without a charter** — that is just clicking around.
- **No time-box** — sessions expand and coverage never gets reported.
- **Investigating every anomaly immediately** — destroys coverage; triage at the end.
- **Automating before understanding** — you encode your assumptions and stop noticing.
- **Reporting screen observations as defects** — §5.1.
- **Concluding from a scan** — §6.3. A scan generates hypotheses, never verdicts.
- **Touring a shared dev container** — exploratory testing is destructive.
- **Treating a tour list as a checklist** — the catalog generates ideas; it is not a coverage target.
- **Picking an area from churn alone** — §3.
- **Probing the same question in a new place** — three consecutive tours asking "is this field
  guarded when released?" found nothing, because that is the oldest, most metadata-driven, most
  tested code in the product. Vary the *question*, not just the area.

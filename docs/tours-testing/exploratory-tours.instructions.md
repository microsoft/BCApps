---
description: "Exploratory testing with tours: charters, the tour catalogs, how to run a session against Business Central, and how to record findings."
---

# Exploratory testing with tours

Exploratory testing is **simultaneous learning, test design and test execution**. It is not ad-hoc
clicking: it is time-boxed, chartered, and documented. Its value is finding the problems scripted
tests cannot, because scripted tests only assert what someone already thought of.

A **tour** is a themed constraint on where you look. Instead of "go test the Customer Card", a tour
says "visit only the things a user would abandon halfway through". The theme is what makes the
session systematic instead of random, and what makes two testers produce different — and therefore
complementary — results.

## 1. Charters

Every session starts with a charter. Keep it to one sentence:

> **Explore** \<area\> **with** \<resources / technique\> **to discover** \<information\>.

Example:

> **Explore** sales invoice posting **with** interrupted and abandoned exits **to discover**
> double-posting, orphaned documents, or inconsistent ledger state.

A charter is a *mission*, not a script. It bounds the session; it does not dictate the steps.

Time-box it. 60–90 minutes is a normal session. Stop when the box is empty, not when you run out of
ideas — leftover ideas become the next charter.

## 2. The two tour catalogs

There are two well-known catalogs. **They are different tools; do not conflate them.**

### Kelly's FCC CUTS VIDS — reconnaissance

Use these when the area is **unfamiliar** and you need coverage and orientation fast.

| Tour | Question it asks | Business Central example |
| --- | --- | --- |
| **F**eature | What can this do? | Walk every action on the ribbon of a card |
| **C**omplexity | Where is the hardest case? | Deeply nested dimensions; multi-line documents |
| **C**laims | Does the documentation tell the truth? | Test the tooltips and help text as assertions |
| **C**onfiguration | What persists, and what changes behaviour? | Toggle setup fields; change posting groups |
| **U**ser | Who uses this, and what do they need? | Follow a full order-to-cash cycle as one persona |
| **T**estability | What tools would help me test this? | Page IDs, filters, SQL access, telemetry |
| **S**cenario | What is a plausible end-to-end story? | Quote → order → ship → invoice → payment |
| **V**ariability | What can be varied? | Currencies, locales, number series, dates |
| **I**nteroperability | What does it touch? | Extensions, APIs, exports, other modules |
| **D**ata | What data does it hold and produce? | Boundary values, long strings, negative amounts |
| **S**tructure | What is it built from? | Objects, tables, layers, dependencies |

### Whittaker's districts — themed bug hunting

Use these when you **know** the area and want to find defects in a specific style. Grouped as
"districts" of a city.

| District | Tours | Theme |
| --- | --- | --- |
| **Business** | Guidebook, Money, Landmark, Intellectual, FedEx, After-Hours, Garbage Collector | The features that justify the product |
| **Historical** | Bad Neighborhood, Museum, Prior Version | Legacy and previously buggy code |
| **Tourist** | Collector, Lonely Businessman, Supermodel, Scottish Pub | Shallow and broad; first impressions |
| **Entertainment** | Supporting Actor, Back Alley, All-Nighter | Secondary and least-used features |
| **Hotel** | Rained-Out, Couch Potato, Cancelled Bus | Rest, interruption and abandonment |
| **Seedy** | Saboteur, Antisocial, Obsessive-Compulsive, Crime Spree | Deliberate abuse |

> **Note on naming.** Secondary sources vary in how they name and group some of these. Treat the
> catalog as a thinking aid, not a standard — the theme matters, the label does not.

Tours worth knowing by name:

- **Cancelled Bus** — start an operation and abandon it: Escape, browser Back, reload, close the
  tab, click the action twice. Excellent at finding commit/rollback asymmetries.
- **Couch Potato** — accept every default; type as little as possible. Finds missing validation and
  bad defaults.
- **Saboteur** — deliberately break the environment mid-operation: kill the service tier, drop the
  database connection.
- **Intellectual** — feed the system the hardest input you can construct.
- **Obsessive-Compulsive** — repeat the same action over and over; submit twice; undo and redo.
- **Back Alley** — deliberately test the *least* popular features, where coverage is thinnest.
- **Money** — follow features that are sold, demoed, or invoiced against.
- **Landmark** — pick a set of landmarks and visit them in varying orders.

## 3. Running a session against Business Central

1. **Prepare the environment.** See
   [`bc-test-environment.instructions.md`](./bc-test-environment.instructions.md). Record the exact
   build number — daily insider builds make this mandatory.
2. **Establish the oracle before you start.** Decide how you will *know* something is wrong, and
   take a baseline snapshot. See §7 of
   [`playwright-bc.instructions.md`](./playwright-bc.instructions.md) — query SQL; do not trust the
   screen.
3. **Tour.** Follow the theme. Note anything surprising, including things you cannot yet explain.
4. **Investigate afterwards, not during.** Chasing each anomaly as it appears destroys the session's
   coverage. Note it, keep touring, triage at the end.
5. **Write the session sheet** (§5) while it is fresh.

### Where automation fits

Do the first pass **manually**. The point of a tour is noticing the unexpected, and automation only
does what you told it to.

Use Playwright for the second pass, where it is genuinely better than a human:

- exits a human cannot do precisely — killing the tab *300 ms* into an operation
- repetition — the same abandonment probe across six documents
- before/after SQL snapshots with computed deltas
- turning a confirmed finding into a regression check

### Code-informed touring

Because this repo contains the AL source, you can read the implementation. That is powerful for
answering *"is this by design?"*, and for the Intellectual, Saboteur and Back Alley tours, where the
code tells you where the hard cases and rarely-executed paths are.

**But tour black-box first.** Reading the implementation before touring biases you toward testing
what the code does rather than what a user expects, and the most interesting findings come from
behaving naively. Read the code during *investigation and triage*, not during the tour.

### Two reference sources — and they answer different questions

| Source | Answers | Use it for |
| --- | --- | --- |
| The AL source in this repo | *What does it actually do?* | Triage: is the observed behaviour intended? Where are the hard paths? |
| [Business Central product documentation](https://learn.microsoft.com/en-us/dynamics365/business-central/) | *What is it supposed to do?* | Charters, expected behaviour, and as an oracle |

The public documentation matters more than it first appears:

- **It is the user's expectation.** A tour finds a bug when behaviour diverges from what a
  reasonable user expects, and the documentation is the written form of that expectation.
- **It is an oracle in its own right.** The **Claims** tour (FCC CUTS VIDS) is precisely this: treat
  documented statements, tooltips and help text as assertions and test them. A documented claim that
  the product does not honour is a finding — even if the code "works as written".
- **It orients you in an unfamiliar area** faster than the source does, and without the black-box
  bias that reading AL introduces. Skimming the docs for an area before a reconnaissance tour is
  legitimate; reading its implementation is not.

When code and documentation disagree, **that disagreement is itself the finding** — one of them is
wrong, and deciding which belongs to the owning team, not to you. Record both references (doc URL
and AL file/object) in the session sheet so they can settle it.

## 4. Oracle discipline, and avoiding false positives

Most "bugs" found in a first exploratory session against an unfamiliar UI are artefacts of the
harness. Two real examples from BC sessions:

- An apparent **dropped first keystroke** was an ambiguous Playwright locator resolving to the
  read-only grid cell behind the card. The product was fine.
- An apparent **double-post opportunity** was a dialog captured mid-transition; it was the success
  dialog, not a second confirmation. The database showed exactly one posted document.

Rules that follow:

- Assert against the **database**, not the screen.
- Reproduce before reporting, ideally by a different route.
- Suspect your own tooling first.
- A negative result is a real result. "Posting is transactional and survives killing the client
  mid-operation" is worth recording — it converts an assumption into evidence.

## 5. Starting a new tour — the recipe

This is the distilled procedure from five tours (Cancelled Bus, Couch Potato, Obsessive-Compulsive,
Intellectual on Customer Card, Intellectual on Sales Orders). Follow it in order; the ordering is
where the value is.

### 5.1 Pick a charter that names an area *and* a theme

A charter is `<tour> on <area>`, one sentence, with an explicit stopping point. "Test sales orders"
is not a charter. *"Intellectual tour on the sales line: feed it the hardest plausible input, aimed
at the boundaries the source actually names"* is.

Prefer an area where you can reach a **posting** boundary. Tours that only touch a card find input
validation issues; tours that reach posting find the ones that matter, because posted data is data
the user cannot take back.

> Choosing the *area* is a separate problem from choosing the *theme*, and it has its own failure
> modes. See **§8** before committing to an area, and **§9** for deriving probes from metadata.

### 5.2 Read the AL source for *named* boundaries — then aim at those

Do this after picking the charter and before writing probes. You are not looking for how the feature
works; you are looking for the error labels it defines, because each one is a boundary somebody
thought about — and the gaps between them are boundaries nobody did.

```bash
# every error label a table defines
grep -n "Err: Label\|ErrorInfo\|TestField" src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al
```

From `SalesLine.Table.al` this yielded `LineDiscountPctErr` (0–100), `LineAmountInvalidErr`,
`SalesBlockedErr` and a `TestField("Shipment Date")` — four probes, each with a known expected
message. Probing `Line Discount % = 150` and getting the range message back is a *pass*, and passes
are worth recording.

The richest findings came from fields with **no** label: `Unit Price` and `Quantity` have no range
rule at all, which is exactly why negative and absurd values sailed through.

> Keep §3's warning in view: read the source to aim *probes*, not to decide what a user would expect.
> The naive path still has to be walked first.

### 5.3 Build the SQL oracle before the first probe

Not after. The moment you start touring you will be tempted to believe the screen.

1. Find the real table name — never hard-code it:
   ```sql
   SELECT name FROM sys.tables WHERE name LIKE '%$Sales Line$%'
   ```
   Extensions own different GUID suffixes; `No. Series Line` is not in the Base App extension.
2. Snapshot the state the tour will disturb, into a `Get-<Area>Snapshot.ps1`.
3. Decide **which column answers the question**, and check it is the one you think. `Customer` has
   no `SystemCreatedAt`, only `[$systemCreatedAt]`. The `Email` caption maps to `[E-Mail]`.

### 5.4 Before filing *anything*, check configuration, source and docs

The single highest-value habit in this document, and it costs three queries.

**Configuration.** Twice in one tour a dramatic-looking finding was a setting working as designed:

- No credit-limit warning on a 649-billion order — because that customer's credit limit is `0`,
  which BC treats as *no limit*.
- Posting 999,999,999 units against 261 in stock — because `Inventory Setup."Prevent Negative
  Inventory"` is `false` in CRONUS.

**Source.** A narrow, explicit guard is evidence that the *unguarded* case is intended. Sales lines
reject a negative `Unit Price` only when `Prepayment % <> 0`
(`Text047: 'must be positive when %1 is not 0.'`). That specificity says the general case is
deliberate, not overlooked.

**Documentation.** It can state outright that the thing you are about to report as a bug is the
prescribed workflow. Negative quantities on sales lines looked like missing validation until the
returns documentation turned up the instruction to *"make a negative entry… by inserting a negative
amount in the **Quantity** field"*, with a dedicated **Move Negative Lines** action supporting it.

That last one was a real, written-up finding in this repo's own session, withdrawn only after the
check — see S-1 in [`../tours-testing-issues.md`](../tours-testing-issues.md). The observation was
sound; the conclusion was not. **"The system let me do X and said nothing"** is never a finding on
its own. It becomes one only once you know that nothing in configuration, source or documentation
says X is allowed.

Inconsistency between neighbouring fields is a tempting signal and a weak one: `Line Discount %` is
strictly range-checked while `Unit Price` is not, and that asymmetry is *correct* — one has a
mathematical range, the other carries meaning in its sign.

### 5.5 Write probes as a declarative table

One file per tour, one exported probe per question, and boundary cases in a `CASES` array rather
than copied blocks:

```js
const CASES = [
  { field: 'Line Discount %', value: '150',     expect: 'reject' },
  { field: 'Line Discount %', value: '100',     expect: 'accept' },
  { field: 'Unit Price Excl. VAT', value: '-100', expect: '?' },
];
```

`expect: '?'` is a legitimate and honest entry — it marks the cases where the tour is genuinely
exploring rather than confirming.

Run one probe at a time from the command line so a hang costs a minute, not a session.

### 5.6 Verify every result in SQL, including the ones that looked fine

The read-back from the page is frequently `""`, and page text is an actively misleading oracle — a
`/posted|successfully/i` match on the page hit the **"Posted Sales Invoices"** FactBox caption and
reported three phantom successes. In this tour, the nonexistent-item probe returned nothing at all
from the UI; only SQL showed that no line had been written, which is the correct behaviour and
the actual result.

#### Run a control before believing "nothing happened"

A probe that reports *nothing happened* is worthless until the identical probe is shown to make
something happen where it should. Silence has two causes — the product refused, or your harness
never acted — and they are indistinguishable from the result alone.

A finding was written up claiming a released order silently discards a new line. Running the same
measurement on an **open** order showed the same nothing: same empty cell, same absent error, same
single line in SQL. The open order should have accepted the line, so the instrument, not the product,
was at fault (see the withdrawn SAB-3).

The control is cheap — usually the same probe against a document in the state where the action is
legal — and it is the only thing separating "the product is silent" from "I typed into the void".
Positive results mostly speak for themselves; **negative results need a control.**

### 5.7 Separate the three kinds of outcome

When writing the session sheet, sort every observation into exactly one:

| Kind | Belongs where | Example |
| --- | --- | --- |
| **Product finding** | `docs/tours-testing-issues.md`, with a ruling question | Negative unit price accepted silently |
| **Verified non-finding** | Session sheet, "validation that works well" | No credit-limit warning — limit is 0 |
| **Harness artefact** | Session sheet, harness notes | `fill()` without Tab never commits the field |

The middle column is what makes a session sheet trustworthy. A sheet containing only findings tells
the reader nothing about how hard you looked.

### 5.8 Does a new tour need a clean container?

Usually **no**. Residue from earlier tours is fine when every probe takes its own before/after
snapshot and no oracle is an absolute count.

Start fresh when:

- the oracle *is* a count or a "there should be exactly one" assertion;
- a previous tour changed **setup** rather than just data;
- a previous tour posted something that moved the world somewhere strange — e.g. item `1896-S` now
  sits at roughly **-1,000,000,000** on hand;
- you are re-running a finding for a bug report and need a minimal reproduction.

Recreating the container is ~20 minutes; deciding deliberately is the point, not always choosing one
or the other.

### 5.9 Worked examples

- Runnable harness: [`harness/`](./harness/README.md) — container script, `bc.js`, probe runner.
- Five completed session sheets in `docs/tours/`. The closest match to this recipe is
  `session-sheet-intellectual-sales-order.md`, which shows code-informed targeting, a
  configuration check that prevented a false finding, and the three-way split of outcomes.

## 6. Session sheet template

One file per session, in a `docs/` subfolder or wherever the team agrees.

```markdown
# Session sheet — <tour name> on <area>

## Charter
Explore <area> with <technique> to discover <information>.

## Environment
| | |
| --- | --- |
| Date | |
| Container / build | e.g. 30.0.54921.0 (insider daily, W1) |
| Company | CRONUS International Ltd. |
| Driver | manual / Playwright <version> |

**Oracle:** which tables/queries establish truth, and the baseline values.

## Probes and results
| # | Probe | Target | Expected | Observed | Deltas |

## Findings
F1 — <one line>. Evidence. Why it matters. Confirmed / unconfirmed.

## Issues
Problems with the *harness or session*, kept separate from product findings.

## Task breakdown
Rough split: test design & execution / bug investigation / setup.

## Follow-up charters
The ideas you did not have time for.

## Verdict on the method
Did this tour earn its time against this area?
```

Keep **findings** (product) and **issues** (your tooling) strictly separate. Conflating them is how
false bug reports reach a team.

Mark anything unconfirmed as unconfirmed. "The Customer Card appears to insert a record on open,
leaving a blank customer if abandoned — *unconfirmed, may be by design*" is useful. Stating it as a
defect without checking the code or asking the owning team is not.

## 7. Anti-patterns

- **Touring without a charter** — that is just clicking around.
- **No time-box** — sessions expand and coverage never gets reported.
- **Investigating every anomaly immediately** — destroys coverage; triage at the end.
- **Automating before understanding** — you encode your assumptions and stop noticing.
- **Reporting screen observations as defects** — see §4.
- **Touring a shared dev container** — exploratory testing is destructive; use a disposable one.
- **Treating a tour list as a checklist** — the catalog generates ideas; it is not a coverage target.
- **Picking an area from churn alone** — see §8; the busiest code is often the least tourable.
- **Reading a UI result without reading the page metadata** — see §9; `Editable` and `CardPageID`
  silently change what "nothing happened" means.

## 8. Choosing *which* area to tour — churn is not enough

The obvious heuristic is "tour whatever changed most recently". It is a good first filter and a bad
last one. An area is only tourable if it passes **four** gates, and churn is only the first:

| Gate | Question | How to check |
|---|---|---|
| 1. Churn | What changed recently? | `git log --numstat` aggregated per app folder |
| 2. Surface | Does the change have a *page* surface? | count fields via the scanner in §9 |
| 3. Installed | Is the app installed in *this* container? | `Get-BcContainerAppInfo -tenantSpecificProperties` |
| 4. **Data** | Is there anything to tour *with*? | `SELECT COUNT(*)` on the area's master tables |

Gates 2 and 4 are the ones that actually bite.

**Gate 2 — churn without surface.** A 14-day churn scan of BCApps put `MasterDataManagement` third
with ~4,700 changed lines. Its tables define **37 fields** in total: the churn is all in
synchronisation codeunits with no user-facing surface. There is nothing to tour. High churn in
codeunits means *write integration tests*, not *run a tour*.

**Gate 4 — churn without data.** The five highest-churn areas were Sustainability, ExpenseAgent,
EDocument, Shopify and ExciseTaxes. All five were installed and healthy. Every one of them had
**zero rows** in its master tables in a stock CRONUS container:

```sql
-- Always discover the real table names first; see §9 of the Playwright instructions.
SELECT 'SustAccount' AS T, COUNT(*) AS N FROM [dbo].[<company>$Sustainability Account$<guid>]
UNION ALL SELECT 'EDocService',   COUNT(*) FROM [dbo].[<company>$E-Document Service$<guid>]
UNION ALL SELECT 'ShpfyShop',     COUNT(*) FROM [dbo].[<company>$Shpfy Shop$<guid>]
UNION ALL SELECT 'ExciseTaxType', COUNT(*) FROM [dbo].[<company>$Excise Tax Type$<guid>]
UNION ALL SELECT 'ExpenseCategory',COUNT(*) FROM [dbo].[<company>$Expense Category$<guid>];
```

This is not a coincidence, it is structural: **the highest-churn areas are the newest apps, and
CRONUS demo data covers the classic Base Application.** Churn and demo-data coverage are
anti-correlated. Run the census *before* planning probes, not after writing them.

### 8.1 When the area is empty, the empty state *is* the tour

Do not treat "no data" as a dead end. Every new customer of a new app starts exactly where you are,
so the bootstrap path is both the least-exercised path in the product and the one no existing user
can avoid. Three charters that need no data at all:

- **First-run tour** — can a user get data into this area at all? Tour the demo-data generator and
  the setup wizard.
- **Empty-state tour** — open every list and card in the area with zero rows. Does it say
  *"There is nothing to show in this view"*, or does it throw?
- **Landmark tour** — walk the setup pages and check each `ToolTip` claim against §9.

This is where the highest-churn area actually failed. In `Contoso Demo Tool` (page 5194), the
`Generate` action produced a raw platform error:

```
The record in table Data Exch. Def already exists. Identification fields and values: Code='OCRCREDITMEMO'
```

The generator is not idempotent, and the collision surfaces as an unactionable technical message.
Per §5.6 this needed a control, and it got three: with **no** row selected, with **Sustainability**
selected, and with **Inventory** selected. All three produced the identical error, which rules out
"you selected nothing" and localises the fault to a dependency step common to every module. A SQL
re-census confirmed the transaction rolled back cleanly and left no partial data.

Note the shape of that investigation: one probe found a symptom, and three controls turned it into a
*claim about the cause*. A single run would have produced the wrong report ("Generate fails when
nothing is selected").

### 8.2 A confirmed diagnosis is not the same as an unblocked tour

The obvious fix for that failure was "generate into a company that has no demo data to collide
with". `New-CompanyInBcContainer` makes that a 2-minute experiment, and it worked exactly as
predicted — the collision vanished. It did not make the area tourable: generation then failed on a
chain of unsatisfied prerequisites, and stalled permanently at 8 of 22 modules.

Two things worth carrying forward:

- **Test the cheap hypothesis anyway.** It cost minutes and converted "Generate is broken" into a
  precise, two-route description of *how* it is broken, which is what an owning team can act on.
- **Re-run your census after the workaround, not just after the failure.** In CRONUS the failed
  generation rolled back cleanly; in a fresh company it left 8 modules half-generated with no
  warning. Had the tour continued at that point, it would have been running against a silently
  half-built company — the worst possible oracle.

When the bootstrap path for an area is broken, stop. Report it, and pick an area that has data.
A tour against half-populated master data produces findings nobody can trust.

## 9. Metadata is the specification — read it before you probe

BC pages and tables are generated from metadata, so a large part of the behaviour you are about to
test is declared, not written. The platform enforces some properties for free, everywhere,
identically. That has two consequences, and the second is the useful one:

- A field **with** `MinValue`/`MaxValue`/`NotBlank`/`TableRelation` is guarded generically. Testing
  it tells you about the *platform*, not about this feature. **Do not spend tour time there.**
- A field **without** them is guarded only by hand-written AL in `OnValidate` — or not at all.
  **That is where the tour belongs.**

### 9.1 The worked example that proves it

Two adjacent decimal fields on the same table, `Sales Line`:

```al
field(27; "Line Discount %"; Decimal)   field(22; "Unit Price"; Decimal)
{                                       {
    MinValue = 0;                           // no MinValue
    MaxValue = 100;                         // no MaxValue
}                                           trigger OnValidate() ...
                                        }
```

`Line Discount %` rejects `101` in the client before AL ever runs. `Unit Price` accepts `-500`
happily. That difference is not a bug in either field and not a mystery — it is two lines of
metadata, visible without running anything.

### 9.2 Asymmetric bounds are the sharpest targets

`Sustainability Jnl. Line."Time Factor"` declares `MaxValue = 1` and **no** `MinValue`. A bound on
one side only is almost always worth a probe: someone thought about the range, and stopped halfway.
Its neighbour `"Installation Multiplier"` declares `InitValue = 1` and no bounds at all, and both
feed the same `CalculationEmissions` call. You would never guess either from the screen.

### 9.3 Tooltips are testable claims

A `ToolTip` that says *must*, *cannot*, *only*, *never*, *automatically* or *before you* is an
assertion the product makes to the user. If no metadata property backs that claim, either AL
enforces it by hand or nobody does — and if the claim is simply untrue, that is a finding on its
own. This is exactly how SAB-1 was found: the Sales Order release tooltip states *"You must reopen
the document before you can make changes to it"*, while `Sales Header` has an explicit
`Status::Released` branch that permits editing `External Document No.`.

### 9.4 The scanner

`harness/Find-TourTargets.ps1` automates the above. It parses `*.Table.al` / `*.TableExt.al` and
bucketises every field:

```powershell
.\harness\Find-TourTargets.ps1 -Path .\src\Apps\W1\Sustainability\app
```

1. **ToolTip claims a rule that metadata does not enforce** — read the `OnValidate`, then probe it.
2. **Numeric fields with no `MinValue`/`MaxValue`** — negative, zero and huge values reach AL raw.
3. **Fields the platform bounds for you** — skip these.

The ratio between buckets characterises an app before you open a browser. From the same scan:

| Area | Fields | Platform-bounded | Unbacked tooltip claims |
|---|---|---|---|
| Shopify | 1002 | **1** | 12 |
| Sustainability | 1475 | 16 | 2 |
| ExpenseAgent | 980 | 20 | 23 |
| EDocument | 481 | 4 | 2 |
| ExciseTaxes | 59 | **13** | 0 |

`ExciseTaxes` guards 22% of its fields declaratively; `Shopify` guards 0.1% of 1002. Those two apps
need completely different tours, and you know that before touching the UI.

The scan also finds inconsistencies that no single-page tour would ever reach, because it sees every
table at once. `Excise Duty %` declares `MaxValue = 1000` on `Excise Tax Rate` and on the journal
line extension, but **no** `MaxValue` on `ExciseTaxesTransLogExt` — so a value the journal rejects
can still land in the transaction log. That is a static finding, produced with no container at all.

### 9.5 Page metadata decides what a UI result *means*

Table metadata tells you what to probe. **Page** metadata tells you how to read the answer — and
getting this wrong invalidates the probe. The properties that matter most:

| Property | Why a tour cares |
|---|---|
| `Editable = false` | The page cannot be typed into. A column that looks like an input is an *output*. |
| `CardPageID` | `New` opens a **card**; it does not insert an inline row. |
| `InsertAllowed` / `DeleteAllowed` | `New`/`Delete` may be absent or inert by design. |
| `SourceTableView` / filters | Rows can be legitimately invisible rather than missing. |

Two probes in one session were nearly misreported because of this. On `Contoso Demo Tool` the
`Data Level` column was read as a selector to set before generating — the page declares
`Editable = false`, so it is a *result* column describing what was installed. On
`Sustainability Account List`, clicking `New` left the list empty and looked inert; the page
declares `Editable = false` with `CardPageID = "Sustainability Account Card"`, so `New` was never
going to add a row.

**Rule: before you write "nothing happened", read the page's property block.** It costs one file
read and it is the difference between a finding and a false report.

### 9.6 A one-hop static scan *under-predicts* guarding

The scanner tells you which fields *declare* a constraint. It cannot tell you which fields are
*effectively* constrained, because in AL a guard is frequently two or three hops away from the
field that triggers it.

A scan of `Purchase Line` reported `Direct Unit Cost` as having no `TestStatusOpen()` guard,
predicting that the cost could be changed on a released order. The UI refused it. The source
explains why:

```
field(22; "Direct Unit Cost")  OnValidate -> Validate("Line Discount %")
field(27; "Line Discount %")   OnValidate -> ValidateLineDiscountPercent(true)
                                              -> TestStatusOpen()
                                                 -> PurchHeader.TestField(Status, Status::Open)
```

Guards also arrive from places no per-field scan looks at:

- **Table triggers** — `OnInsert`/`OnDelete` on `Purchase Line` both call `TestStatusOpen()`, so
  inserting or deleting a line is guarded even though no *field* declares it.
- **Validation chains** — one field's `OnValidate` calling `Validate(<other field>)`.
- **Shared procedures** — `ValidateLineDiscountPercent`, `UpdateAmounts`, and friends.

> **Use the scanner to generate candidates, never to reach a conclusion.** "The scan says
> unguarded" is a hypothesis. Only the running product, read through a *working* error oracle,
> settles it. A predicted gap that the product closes is still a useful result — it tells you the
> guard is implicit, which is a maintainability risk worth reporting even when behaviour is correct.

### 9.7 Guards live at *two* levels — scan both

This is the single most important correction to the Saboteur method, and it invalidates any
conclusion drawn from a table scan alone.

A document field can be protected in **two independent places**:

| Level | Where | Looks like | Blocks |
|---|---|---|---|
| **Table** | `*.Table.al`, field `OnValidate` | `TestStatusOpen()` → `TestField(Status, Status::Open)` | every writer — UI, API, OData, other pages, AL code |
| **Page** | `*.Page.al`, field property | `Editable = (Rec.Status = Rec.Status::Open)` | only *that page* |

The Transfer Order tour found these are used very differently across modules:

- **Sales / Purchase** guard `Shipment Method Code`, `Location Code`, `Currency Code` and friends
  in the **table**.
- **Transfer** leaves the same fields unguarded in the table and instead writes
  `Editable = (Rec.Status = Rec.Status::Open)` on **page 5740**, field by field.

Both refuse the edit in the web client, so a UI-only tour sees identical, correct behaviour. But
the protection is not equivalent: a page-level guard is bypassed by *any other writer* — a second
page exposing the same field, a web service, an OData PATCH, or an AL extension. Only the table
guard is universal.

Two practical consequences:

1. **A table scan alone mispredicts the UI.** Five fields flagged "unguarded" on `Transfer Header`
   were all correctly refused, because page 5740 guards them. Read the page before you probe.
2. **A UI probe alone misses the risk.** "The UI refused it" does not mean the record is safe.
   When a field is guarded *only* at the page level, note it as an API-surface hypothesis and
   test it through a non-UI writer.

> **Rule: before recording either a finding or a non-finding, check both levels.** Table guard
> present → safe everywhere. Page guard only → safe in this page, unproven elsewhere. Neither →
> genuinely open, and worth a probe.

### 9.8 Editable on a released document is often *deliberate*

Three findings were withdrawn before this check was automated. The pattern is always the same: a
field has no `TestStatusOpen()`, the probe shows the edit persisting on a released order, and it
looks like a missing guard. It is not — the author explicitly handled the released case:

```al
// Sales Header 100, Purchase Header 67, Transfer Header 33, Service Header 100
if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released) then
    WhseSalesRelease.UpdateExternalDocNoForReleasedOrder(Rec);
```

All four document frameworks implement `UpdateExternalDocNoForReleasedOrder`. The field is meant
to stay editable after release, and changing it *propagates* to the linked warehouse request.

**Semantics count even without such a branch.** `Vendor Invoice No.` has no released branch and no
guard, yet must stay editable: its tooltip says it is the number of the document *received from
the vendor*, and it is required at **posting** time — it cannot be known before release.

`Find-UnguardedFields.ps1` now flags these automatically (the `DELIBERATE RELEASED HANDLING`
block) and excludes them from the candidate list. Before recording a Saboteur finding:

1. Search the field's declaration for `Status::Released`. Present → intended, stop.
2. Read the tooltip. If the business meaning requires a post-release value, stop.
3. Only then probe.

### 9.9 Sequential probes on one record contaminate each other

Probing five fields on the same document in one pass is not five independent experiments. BC
re-derives fields from each other, so a later probe can silently overwrite an earlier result.

On open transfer order 1001 the probe reported `Shipment Date` as ACCEPTED (`2/1` → `2/20`), but
SQL afterwards showed `2028-02-01`. The next probe changed `In-Transit Code`, which recalculated
the shipment date from the transfer route's shipping time and reverted it.

> **Rule: one mutating probe per record, or re-read the oracle after every single step.** If you
> must batch, use a fresh document per field. A "confirmed" result that was actually overwritten
> two probes later is worse than no result.

### 9.10 The guard *idiom* is framework-specific — find it before you scan

§9.7 said guards live at two levels. Service Management shows the model needs a third axis: **the
form the guard takes differs per framework**, and scanning for the wrong idiom returns a clean,
plausible, completely wrong answer.

A scan of `Service Header` for `TestStatusOpen` reported **0 of 139 fields guarded** — which reads
as a spectacular defect. It is a 100% false-negative. Service never calls `TestStatusOpen()`; it
writes the check inline against a *differently named* field:

```al
TestField("Release Status", "Release Status"::Open);   // not Status::Open
```

Re-scanned with the right idiom, the true figure is 6 of 139.

The four frameworks each do it differently:

| Framework | Status field | Guard idiom | Mostly enforced at |
| --- | --- | --- | --- |
| Sales / Purchase | `Status` | `TestStatusOpen()` helper | table |
| Transfer | `Status` | `TestStatusOpen()` helper | **page** (`Editable = …`) |
| Service | `Release Status` **and** `Status` | inline `TestField("Release Status", …::Open)` | table, for 6 shipping fields only |

**Service also guards by a fourth mechanism entirely.** Its high-consequence fields are not gated
on release at all, but on whether the document already has lines — and the gate is a *confirmation*,
not a refusal:

```al
// Customer No.
if ServItemLineExists() then Confirmed := ConfirmManagement.GetResponseOrDefault(…);
// Currency Code
if ServLineExists() and ("Contract No." <> '') then Error(Text058, …);
```

So `Customer No.` on a released-to-ship service order asks the user a question and proceeds if they
answer Yes. A probe that classifies that dialog as an error (see the Playwright §10 lookalike)
records a refusal that never happened.

> **Rule: before scanning a new framework, grep the table for its own guard.** Look for
> `TestField(<status-ish field>` and count the distinct idioms. Two minutes of grep prevents an
> entire tour built on an inverted premise. Pass the idiom explicitly:
>
> ```powershell
> .\Find-UnguardedFields.ps1 -Table <t> -Guard 'Release Status"?,\s*"?Release Status"?::Open'
> ```
>
> And treat a **0% or 100% guarded** result as a bug in your regex until proven otherwise. Real
> tables always land somewhere in between.

#### The probe that falsified this section's own prediction

Having found only 6 guarded fields, the obvious prediction was that `Customer No.` — unguarded at
both levels — could be swapped on a **released-to-ship** service order. It cannot:

| Order | Release Status | Change `Customer No.` | Outcome |
| --- | --- | --- | --- |
| SO000008 | Open | confirm *"the existing Service item line and service line will be deleted"* → Yes | customer changed, 2 lines deleted — **exactly as warned** |
| SO000005 | Released to Ship | same confirmation → Yes | **refused**: *"Release Status must be equal to 'Open' … Current value is 'Released to Ship'."* customer and lines untouched |

The guard is real but **two hops away**, which is §9.6 again: `Customer No.` does not test the
status itself — it *deletes the lines*, and the line deletion tests it. No per-field scan at any
number of levels would have found this.

Two lessons worth more than the result:

- **A confirmation that is followed by an error is not a contradiction.** BC asks first and
  validates second, so `CONFIRMED-THEN-PROCEEDED` must still read the error surface *after*
  answering Yes. A probe that stops at the confirmation records the opposite of the truth.
- **The UI readback of the status field said `Open` while the error message said
  `Released to Ship`.** The error was right. Never take a field readback as the oracle — §5.6.

### 9.11 Git history in BCApps cannot tell you *when* a pattern was introduced

`git log -S` is the obvious way to decide whether a divergence is deliberate scoping or an
incomplete rollout: if four pages got a pattern progressively and two never did, that is drift.

**It does not work in this repo.** BCApps is populated by squashed sync commits from an internal
repository, so `-S` reports the *import* commit, not the change:

```
SalesQuote         first introduced: 2026-06-29 748fdaa43f
SalesOrder         first introduced: 2026-06-29 748fdaa43f
SalesInvoice       first introduced: 2026-06-29 748fdaa43f
BlanketSalesOrder  first introduced: 2026-06-29 748fdaa43f   <- all identical, all meaningless
```

History here answers *"what changed recently?"* (which is what §8 uses it for) but **not**
*"which came first?"*. When intent depends on chronology, the evidence is not available in this
repo — say so, and route the question to the owning team rather than guessing.

### 9.12 Name-based searching under-reports guards — resolve to the control, not the identifier

This failure recurred **four times** in one session, each time producing a clean, plausible,
completely wrong answer. It is the single most reliable way to manufacture a false defect.

| Control | Framework | Identifier |
| --- | --- | --- |
| Document is open | Sales, Purchase, Transfer | `TestStatusOpen()` |
| Document is open | Service | inline `TestField("Release Status", …::Open)` |
| Posting date allowed | Sales, Purchase | `GenJnlCheckLine.IsDateNotAllowed` |
| Posting date allowed | Service | `GenJnlCheckLine.DateNotAllowed` |
| Posting date allowed | Inventory / Transfer | `UserSetupManagement.CheckAllowedPostingDate` |

The last row nearly became a **High-severity false report**. Grepping W1 for `IsDateNotAllowed`
returns Sales and Purchase only. Transfer returns nothing — which reads as "transfer posting
bypasses the allowed-posting-date window", a period-control bypass. It does not: transfer posting
goes through the item journal, and `ItemJnlCheckLine.CheckDates` calls a third differently-named
procedure that enforces the same rule (and adds an `Inventory Period` check the others lack).

The discipline that catches it:

1. **Search for the control, not the name.** Ask "what enforces this rule?" and follow the call
   path to the *setup field* it reads (`Allow Posting From`/`To`, `Status`, `Release Status`).
2. **An absence is never evidence on its own.** A zero-match grep means "not under this name here",
   never "not enforced".
3. **Follow the posting path.** Document posting delegates to shared engines — `GenJnlPostLine`,
   `ItemJnlPostLine`. A check missing from the document codeunit is very often in the engine.
4. **Sanity-check the shape.** A control implemented in 2 of 4 frameworks is far more likely to be
   a naming difference than a genuine gap in a mature product.

> Before filing any "X is not checked" finding, state where you would expect the check and prove
> you looked there. If you cannot name the enforcement point for the frameworks that *do* have it,
> you have not finished the analysis.

## 10. Differential touring across parallel modules

BC contains several near-duplicate subsystems: Sales vs Purchase documents, Quote/Order/Invoice/
Credit Memo, Item vs Resource vs G/L Account lines. They were written from the same template and
are maintained separately, so **they drift**. That drift is a rich, cheap source of findings,
because each module is its own control: if two parallel fields behave differently, at least one of
them is wrong, and you do not need a specification to say so.

The method:

1. Extract the same property from both tables — here, which fields call `TestStatusOpen()`.
2. Join them on an **explicit list of analogous field pairs**.
3. Every divergence is a candidate; every *agreement* generalises a finding you already have.

Applied to `SalesHeader`/`PurchaseHeader` and `SalesLine`/`PurchaseLine`:

| Sales | Purchase | Sales guarded | Purchase guarded |
|---|---|---|---|
| `Assigned User ID` | `Assigned User ID` | yes | **no** |
| `VAT Base Discount %` | `VAT Base Discount %` | yes | **no** |
| `Shipment Date` | `Expected Receipt Date` | yes | **no** |
| `Job No.` | `Job No.` | no | **yes** |
| `Unit Price` | `Direct Unit Cost` | no | no (symmetric) |
| `External Document No.` | `Vendor Invoice No.` | no | no (symmetric) |

The symmetric rows are as valuable as the divergent ones. `External Document No.` and
`Vendor Invoice No.` are both unguarded, which predicted — and the UI then confirmed — that the
Sales finding about the Release tooltip applies verbatim to Purchase Orders. That converts an
app-specific bug report into a document-framework one, which is a far stronger thing to file.

### ⚠️ Join on explicit pairs, never on a regex rename

The first attempt normalised names with blanket substitutions (`Buy-from Vendor` → `PARTY`,
`Sell-to Customer` → `PARTY`) and reported that `Buy-from Vendor No.` was unguarded. It is not.
`Purchase Header` contains **both** `Buy-from Vendor No.` (field 2, guarded) and `Sell-to Customer
No.` (field 72, the drop-shipment customer, unguarded). Both normalised to the same key and the
later one overwrote the earlier in the hash map.

A differential is only as good as its join. Write the pairs out by hand and keep the unmatched
fields visible so you can see what the join dropped.

### 10.1 What a page-level "editable" property does *not* mean

`SalesLinesEditable()` and `PurchaseLinesEditable()` both key off whether a **party is selected** —
not off `Status`:

```al
IsEditable := Rec."Buy-from Vendor No." <> '';
```

So the lines grid on a *released* document still takes focus, still shows a text cursor, and still
accepts typing. Nothing is read-only at the page level. The refusal happens later, at validate
time, from the table. Two consequences for touring:

- "The released grid let me type into it" is **not** a finding. Expect it.
- A probe that concludes from `aria-readonly` or from a successful click that the field is editable
  has measured the page, not the product. Commit the value and read the database.

### 10.2 When the table is shared, the *pages* are the differential

§10 compares parallel *tables*. The six sales document types break that assumption: Quote, Order,
Invoice, Credit Memo, Blanket Order and Return Order all share **one** table (`Sales Header` 36),
discriminated by a `Document Type` enum. A table differential across them is vacuous by
construction — the fields are identical because there is only one set of them.

Everything that distinguishes the six therefore lives in the **pages** (41, 42, 43, 44, 507, 6630)
and in the posting codeunits. So build the matrix from page field declarations instead: for each
field, record its `Editable`/`Enabled` expression per page, group identical expressions under a
letter, and print only the rows where the letters disagree.

```
FIELD                          Q O I C B R      . = absent from that page
Ship-to Address                L L L . L -      - = present, no Editable/Enabled property
Ship-to Code                   M M M . M .
Customer Posting Group         . F F F . F
```

Read the shapes, not the individual cells:

- **`L L L . L -`** — four agree, one omits the field, one has it unguarded. A 1-vs-5 outlier is
  the classic drift signature.
- **`. F F F . F`** — absent exactly where it is meaningless (Quote and Blanket Order never post).
  That is a semantic boundary, not drift.

**The worked example, and its honest verdict.** The `ShipToOptions`/`BillToOptions` pattern — which
locks the ship-to address fields unless the user explicitly chooses *Custom Address*, and adds a
`Ship-to Code` selector for registered alternate addresses — is implemented on Quote, Order,
Invoice and Blanket Order, and is **entirely absent** from Return Order and Credit Memo (0
occurrences of either identifier). On a Sales Return Order the ship-to address fields are freely
editable with no `Ship-to Code` affordance at all.

Is that a deliberate outbound-vs-return boundary, or a rollout that never reached the return
family? **The evidence needed to decide is chronological, and this repo cannot supply it** (see the
history caveat in §9.11). The disciplined output is therefore a *question for the owning team*, not
a filed defect — a 4-vs-2 split along a meaningful business boundary is exactly the case where
guessing produces a confident wrong answer.

> The general lesson: a differential tells you **where** to look, never **who is wrong**. Promote a
> divergence to a finding only when you can name the harm or show the inconsistency is user-visible.

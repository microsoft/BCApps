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

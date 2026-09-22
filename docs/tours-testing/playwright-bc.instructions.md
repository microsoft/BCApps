---
description: "Driving the Business Central web client with Playwright: iframe structure, locators, deep links, dialogs, and using SQL as the test oracle."
---

# Driving Business Central with Playwright

Playwright can sign in to the BC web client and drive it like a user. This is **complementary to
AL tests, not a replacement**: AL tests are faster, run in CI, and should carry functional coverage.
Playwright earns its place for things AL tests cannot reach — browser Back, page reload, closing the
tab mid-operation, double-clicks, and other client-layer behaviour.

Prerequisite: a running, warmed-up container. See
[`bc-test-environment.instructions.md`](./bc-test-environment.instructions.md).

## Setup

```powershell
npm init -y
npm install --no-save @playwright/test
npx playwright install chromium
```

Do not add these to a shipping `package.json` without agreement; keep exploratory tooling out of the
product build.

## 1. The app UI lives inside a child iframe

This is the single most important fact. The top-level document contains only the black header bar.
Everything you want to interact with — lists, cards, actions, dialogs — is in a **nested frame**.

Locate it by picking the frame with a meaningful number of ARIA landmarks:

```js
async function appFrame(page, timeoutMs = 90000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    for (const f of page.frames()) {
      if (f === page.mainFrame()) continue;
      const n = await f.locator('[aria-label]').count().catch(() => 0);
      if (n > 20) return f;          // main frame has ~7; the app frame has 80+
    }
    await page.waitForTimeout(500);
  }
  throw new Error('BC app frame not found');
}
```

**Re-acquire the frame after every navigation.** A stored frame handle goes stale as soon as the
page navigates, and the resulting errors look like missing elements rather than stale handles.

## 2. Sign-in

The sign-in page is a plain form in the **main** frame:

```js
await page.goto(`${BASE}?tenant=default`, { waitUntil: 'domcontentloaded' });
await page.fill('#UserName', process.env.BC_USER);
await page.fill('#Password', process.env.BC_PASS);
await page.click('#submitButton');
```

Read credentials from the environment. Never hard-code them.

## 3. Deep-link straight to a page

Far more reliable than navigating the UI, and it keeps scenarios independent:

```
?tenant=default&page=22     # Customer List
?tenant=default&page=21     # Customer Card
?tenant=default&page=9301   # Sales Invoice List
?tenant=default&page=43     # Sales Invoice Card
```

Filter to a single record with the `filter` query parameter:

```js
const url = `${BASE}?tenant=default&page=43&filter=` +
  encodeURIComponent("'Sales Header'.'No.' IS '102199'");
```

Drop `tenant=default` on a single-tenant container.

### ⚠️ `filter=` is not universal — have a fallback for opening one document

The `filter` parameter works on some pages and is **silently ignored on others**. On Transfer Order
(page 5740) every variant landed on the Home page or an empty new card, with no error:

```js
`${BASE}?page=5740&filter=` + encodeURIComponent("'Transfer Header'.'No.' IS '1001'")  // ✗ Home
`${BASE}?page=5740&bookmark=...`                                                       // ✗ blank card
```

Worse, the failure is invisible: the browser shows *a* page, so a probe that does not assert which
record it is on will happily report results for the wrong document — or for an empty one.

The reliable recipe is **list → row → Enter**:

```js
await page.goto(`${BASE}?page=5742`);            // the LIST page
const row  = frame.locator('[role="row"]').filter({ hasText: '1001' }).first();
await row.locator('[role="gridcell"]').first().click();
await frame.locator('body').press('Enter');      // Enter opens the card; a click only selects
```

Three things that do not work and cost time: clicking the cell alone (selects, never opens); the
list's ribbon (Transfer Orders has **no `Edit` action**); and double-click (unreliable in the grid).

> **Always assert the document number on the opened card before probing it.**

## 4. Locators

Actions are `menuitem`, not `button`:

```js
frame.getByRole('menuitem', { name: /^Post$/ })
frame.getByRole('menuitem', { name: 'New' })
```

Dialogs are `role="dialog"`; their buttons are real buttons:

```js
frame.getByRole('button', { name: /^Yes$/i })
```

### ⚠️ `getByRole('textbox')` misses half the fields — use `getByLabel`

**BC does not render every field as a textbox.** Plain text fields are `role=textbox`, but any
field with a `TableRelation` (a lookup) or a date picker renders as **`role=combobox`**.

On Transfer Order page 5740, a `getByRole('textbox', …)` helper reported `Posting Date`,
`Transfer-from Code`, `Transfer-to Code` and `In-Transit Code` as **"not on the page"** — all four
were present, visible and editable. They are comboboxes:

```js
frame.getByRole('textbox', { name: 'Posting Date' })   // ✗ 0 matches — it is a combobox
frame.getByLabel('Posting Date', { exact: true })      // ✓ 1 match
```

Use `getByLabel`, which resolves **both** `aria-label` and `aria-labelledby` and is indifferent to
the role. This matters because many BC card pages set `aria-label=""` on the input and put the
field name in `aria-labelledby` instead, so an attribute selector on `aria-label` finds nothing.

`data-control-name` is *not* a fallback — it does not exist anywhere in the BC client DOM.

The shared helper now does this:

```js
function field(frame, name) {
  return frame.getByLabel(name, { exact: true }).and(frame.locator('input'));
}
```

> **A "NOT-ON-PAGE" result is a claim about your locator, not about the product.** Confirm with a
> raw DOM dump before you believe it.

### ⚠️ Field locators are ambiguous — always scope to the input

When a card is open, **the list behind it is still in the DOM**. So this matches *two* elements:

```js
frame.getByLabel('Name', { exact: true })   // ✗ matches a read-only grid SPAN *and* the card INPUT
```

`.first()` typically resolves to the **read-only grid cell**, which silently accepts no input.
Always constrain to the actual input element:

```js
frame.getByLabel('Name', { exact: true }).and(frame.locator('input'))   // ✓
```

This is not a theoretical concern. In practice it produced a convincing but entirely false bug
report — an apparent "first keystroke is dropped" defect that was purely a locator artefact. If you
observe something that looks like input loss, **suspect your locator before the product**.

The same trap has a second form: on a list page, **column headers carry the field's `aria-label`
too**. `[aria-label="Category"]` resolved to `<span id="column_header_b9">`, whose click is then
intercepted by the sticky header container, and the probe died in a 30-second timeout that looked
like a hung page. Scope to the row, and to an input:

```js
const cell = frame.locator('[role="row"]:has-text("…")').first()
                  .locator('[role="gridcell"]').nth(n);          // ✓ scoped to a row
```

A `Timeout … subtree intercepts pointer events` message is almost always this, not a slow server.

### ⚠️ A document card contains *two* grids — pick the right one

On a Sales Order card, `getByRole('grid')` returns **2**: the lines grid you want, and the leftover
list grid from the page you navigated from. `getByText('Item')` happily matched a control ~1100 px
away in the wrong one.

Identify the lines grid by a marker column header, then map header x-centre onto cell x-range:

```js
const grids = await frame.getByRole('grid').all();
for (const g of grids) {
  const heads = await g.getByRole('columnheader').allTextContents();
  if (heads.some(h => h.trim() === 'Type')) return g;   // ✓ the lines grid
}
```

Cells **are** exposed as `gridcell` (603 of them on a populated card). An earlier conclusion that
they were not was simply the wrong grid being addressed.

### ⚠️ `fill()` does not commit — always Tab afterwards

`fill()` sets the value without blurring, so BC never runs `OnValidate` and the value is never
stored. The page looks right and the database disagrees.

```js
await input.fill('150');
await input.press('Tab');     // ✓ required; this is what commits
```

This produced a second convincing false finding. Pair it with the rule above: **before reporting
anything about input handling, re-check the locator and the commit.**

## 5. Prefer BC keyboard shortcuts to toolbar clicks

The sticky line toolbar (`div.secondary-row--*`) intercepts pointer events. Clicking `Post…` failed
with a normal click, with `force: true`, and with raw `page.mouse.click()` at the resolved
coordinates. **`F9` posts cleanly**, first time, every time.

| Action | Shortcut |
| --- | --- |
| Post | `F9` |
| Post and print | `Shift+F9` |
| New line / new record | `Ctrl+N` (where offered) |
| Close page | `Escape` |

When an element resists three different pointer strategies, stop escalating force and look for the
keyboard route. This is faster *and* closer to what a keyboard-driven ERP user actually does.

Dialog buttons resist pointer clicks in the same way: **`Escape` is the only reliable dismissal.**
When dialogs stack, `.first()` resolves to one that is covered — dismiss repeatedly until none
remain rather than targeting a specific button.

To *answer* rather than cancel a dialog, press **`Enter`**. This matters: the post dialog
(*Ship / Invoice / Ship and Invoice*) must be answered or nothing posts, and a run that escapes it
looks exactly like a silent posting failure.

**Option (dropdown) fields cannot be set by typing.** `Ctrl+A` + type + `Tab` leaves the old value
while appearing to succeed. Use the list:

```js
await combo.click();
await page.keyboard.press('Alt+ArrowDown');   // open the option list
await page.keyboard.press('Home');            // first option (often blank)
await page.keyboard.press('Enter');
```

## 6. Card-level traps

- **Deep-linked cards open read-only.** Click `button[title="Make changes on the page"]` before
  attempting any input, or every probe silently does nothing.
- **Card header icons have no `aria-label`.** Their accessible name comes from `title` — the delete
  icon is `Delete the information`, not `Delete`.
- **Do not press `Escape` to dismiss a teaching tip**, and do not use
  `getByRole('button', { name: /close/i })` for it. Both close the whole card instead.
- **Clicking `New` navigates** (9305 → 42). Wait for it: `page.waitForURL(/page=42/)`, with retries.
- **Never call a blanket `dismissDialog()` right after creating a record.** `dismissDialog` presses
  `Escape`, and `Escape` on a freshly created card *closes the card*. A probe that did this on a new
  Purchase Order destroyed the document before adding any lines; every subsequent read returned
  `There is nothing to show in this view`, which looked like a product fault. Only dismiss a dialog
  after confirming one is actually open.
- **Some document cards have no visible `No.` field.** On `Purchase Order` (page 50) the document
  number appears only in the page caption (`106032 · Progressive Home Furnishings`), so
  `field(frame, 'No.')` returns the *line's* `No.` or nothing. Parse the heading instead — and note
  that without the document number you cannot run the SQL oracle at all.
- **A grid cell's `innerText` is not a reliable readback.** Unfocused cells frequently render empty
  even when the record holds a value. Confirm every grid result in SQL.

### ⚠️ Half the fields are not in the DOM until you expand something

A card shows only a fraction of its fields. Two separate mechanisms hide the rest, and both make a
field *absent*, not hidden — so a locator returns 0 matches and the probe reports "not on page".

**1. Collapsed FastTabs.** Expand by caption, as buttons:

```js
for (const cap of ['General','Shipment','Transfer-from','Transfer-to','Foreign Trade']) {
  const t = frame.getByRole('button', { name: cap, exact: true }).first();
  if (await t.getAttribute('aria-expanded') === 'false') await t.click();
}
```

Do **not** loop over every `[aria-expanded="false"]` on the page. That also matches the navigation
menus and every column header, and it ran for **8 minutes without finishing**.

**2. `Show more`.** Fields marked `Importance = Additional` in page metadata are omitted entirely
until the FastTab's `Show more` link is clicked. Click them **one at a time, re-querying each time**:

```js
for (;;) {
  const link = frame.getByText('Show more', { exact: true }).first();
  if (!await link.isVisible().catch(() => false)) break;
  await link.click();                                  // re-renders; the link becomes "Show less"
}
```

A cached `nth()` list goes stale after the first click — the classic symptom is that only the first
FastTab ever expands.

> Cross-check against the page source: if `Find-UnguardedFields.ps1` lists a field and the browser
> cannot see it, you have almost certainly not expanded far enough.

### ⚠️ A read-only field is a `<span>`, so it reports as "not on page"

When a guard makes a field non-editable, BC renders it **without an input element**. A helper that
requires `input` then returns null, and the probe records `NOT-ON-PAGE` when the truth is
`READ-ONLY` — a materially different result, and the second one is evidence the guard works.

Distinguish them before recording anything:

```js
const input  = frame.getByLabel(name, { exact: true }).and(frame.locator('input'));
const anyEl  = frame.getByLabel(name, { exact: true });
const state  = await input.count()  ? 'editable'
             : await anyEl.count()  ? 'read-only'
             :                        'absent';
```

## 7. Saving and closing

- BC **auto-saves when a field commits** (Tab or focus change). There is no explicit Save action on
  most cards.
- `Escape` closes a card.
- Different exit routes are *not* equivalent — Back, Escape, reload and tab-close can each produce
  different commit behaviour. Never assume; assert.

## 8. Native browser dialogs

BC registers `beforeunload` during long operations such as posting. An unhandled native dialog will
**hang `page.reload()` or `page.goBack()` until the timeout**, which is easily misread as a product
hang. Register a handler when you intend to exercise those paths:

```js
page.on('dialog', d => d.accept());
```

## 9. Use SQL as the oracle, not the UI

Do not assert on screenshots or on-screen text alone. The UI can render a transitional state that
looks alarming and means nothing — a dialog captured mid-transition once looked exactly like a
double-post opportunity and was not one. Query the database.

The BC API v2.0 on port 7048 **rejects the container password** for basic auth; it requires a *web
service access key*. Either configure one, or query SQL inside the container:

```powershell
Invoke-ScriptInBcContainer -containerName <ContainerName> -scriptblock {
  Invoke-Sqlcmd -ServerInstance 'localhost\SQLEXPRESS' -Database 'CRONUS' -Query @"
SELECT COUNT(*) FROM [CRONUS International Ltd_`$Customer`$437dbf0e-84ff-417a-965d-ed2bb9650972]
"@
}
```

Notes:
- **Check the database name; do not assume it.** A single-tenant container (what the repo's
  `Create-BCContainer` produces) uses `CRONUS`; a multitenant one uses the tenant database, e.g.
  `default`. List them with
  `Invoke-Sqlcmd -ServerInstance 'localhost\SQLEXPRESS' -Query "SELECT name FROM sys.databases"`.
- Table names are `<Company>_$<Table>$<ExtensionGuid>`. The Base Application GUID is
  `437dbf0e-84ff-417a-965d-ed2bb9650972`. Discover names rather than hard-coding them:
  `SELECT name FROM sys.tables WHERE name LIKE 'CRONUS%Customer$%'`.
- In PowerShell strings, escape the `$` in table names as `` `$ ``.
- Useful tables: `Customer`, `Sales Header` (`Document Type` 2 = Invoice), `Sales Invoice Header`
  (posted), `Cust_ Ledger Entry`, `G_L Entry`.
- **Duplicate-post detector:** group `Sales Invoice Header` by `Pre-Assigned No_` and flag
  `HAVING COUNT(*) > 1`.

### Column-level traps that have each cost a session

- **Never use page text as an oracle.** A `/posted|successfully/i` match against the page matched the
  **"Posted Sales Invoices"** FactBox *caption* and reported success for three runs that posted
  nothing at all.
- **Use `DATALENGTH`, not `LEN`,** whenever whitespace is the subject. T-SQL `LEN` ignores trailing
  spaces, so a trailing-space finding is invisible to it.
- **`SystemCreatedAt` is not a column** you can select on every table; the physical column is
  `[$systemCreatedAt]` (escape as `` [`$systemCreatedAt] `` in PowerShell).
- **Do not sort "newest" by number.** `CAST([No_] AS BIGINT) DESC` returns demo data (`104011`) ahead
  of the order the tour just created (`1015`). Order by `[$systemCreatedAt] DESC`.
- **Captions are not column names.** The Customer Card field labelled `Email` is `[E-Mail]` in SQL. A
  probe keyed to the wrong caption *silently skips* — so always log skips as loudly as failures.
- **Some counters are not in the table.** No. Series consumption cannot be read from `Last No. Used`
  on this build; it uses SQL sequences.
- **`%`, `.` and `/` in a field name all become `_` in the SQL column.** `Line Discount %` is
  `[Line Discount _]`, `No.` is `[No_]`, `External Document No.` is `[External Document No_]`.
  Because three different characters collapse to the same `_`, you cannot reverse the mapping —
  discover the real names instead of deriving them:

  ```sql
  SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('<table>') ORDER BY column_id;
  ```

  The symptom of guessing is `Invalid column name`.
- **Every app has its own extension GUID.** The Base Application GUID is *not* reusable. The
  Sustainability tables live under `b3780cd9-…`, E-Document under `e1d97edc-…`, Shopify under
  `ec255f57-…`. Guessing produces `Invalid object name`.
- **The company prefix is the company's *display* name, mangled.** In a stock container it is
  `CRONUS International Ltd_`, not `CRONUS`. Check with `SELECT [Name] FROM [dbo].[Company]`.
- **So always discover, never construct, a table name:**

  ```sql
  SELECT name FROM sys.tables WHERE name LIKE '%Sustainability Account%';
  ```

- **`Invoke-Sqlcmd` returns multiple result sets flattened.** Piping two `SELECT`s of different
  shapes into `Format-Table` silently prints only the first. Use one `SELECT` per call, or
  `UNION ALL` them into a common shape.

### Verify your *cleanup*, not just your probes

A cleanup step that restored a blocked customer logged `customer unblocked` and left `Blocked=3` in
the database: typing into an option field and pressing Tab does nothing. The next tour would have
started from silently corrupted master data.

Anything a tour changes outside the document under test — blocking flags, setup, posting windows —
must be restored **and the restoration confirmed in SQL**.

### Read the configuration before filing a "it let me do X" finding

The setting that governs the behaviour is almost always one query away, and checking it has twice
prevented a confident, wrong report:

```sql
SELECT [Prevent Negative Inventory] FROM [CRONUS International Ltd_$Inventory Setup$437dbf0e-...]
SELECT [Credit Limit (LCY)] FROM [...$Customer$...] WHERE [No_] = '10000'   -- 0 means NO limit
```

Snapshot before and after each scenario and diff the counts. Deltas are the evidence; the screen is
only a hint.

## 10. Reading errors — BC has *four* error surfaces (and one lookalike)

This is the single most important helper in the harness, and the easiest one to get wrong. BC
reports a rejected value on any of four surfaces, and a probe that reads only one will report a
correctly behaving product as silently discarding data:

| # | Surface | Looks like |
|---|---|---|
| 1 | Modal dialog | `role="dialog"` |
| 2 | Page-level error bar | *"The page has an error. Refresh (F5) to undo the change, or correct the error."* |
| 3 | Inline bubble beside the cell | *"Status must be equal to 'Open' in Purchase Header … Current value is 'Released'."* |
| 4 | Notification bar under the title | *"Notifications: 2 …"* |

Surfaces 2 and 3 are the normal way a **grid** rejects a value. A tour that only checks dialogs
sees nothing, reads the row back unchanged, and concludes "accepted then silently reverted".

### ⚠️ A fifth surface means the opposite: a Yes/No *confirmation*

A confirmation is indistinguishable from an error in the DOM — same `role="dialog"`, same alert
markup — but it means the product is **proceeding**, not refusing:

> *"Do you want to change Transfer-from Code? Yes No"*

BC raises this when a key field is edited on a document that already has lines. The first Transfer
tour recorded `Transfer-from Code` as REFUSED on an *open* order because of it; the field was
working exactly as designed and was waiting for an answer.

Classify it separately, and answer it before reading the real outcome:

```js
const isConfirm = t => /\b(do you want to|are you sure)\b/i.test(t) || /\byes\b[\s\S]{0,6}\bno\b/i.test(t);
```

`readError()` returns `confirmation` alongside `message` for this reason. **A probe that leaves a
confirmation unanswered has not tested anything** — the value was never committed.

### ⚠️ Never scan `body.innerText` with a loose regex

The original helper did exactly that:

```js
const m = body.match(/.*(?:must be|cannot|not valid|is not|already exists).*/i);
```

`/is not/` matches the substring inside **"There is not&#8203;hing to show in this view"** — a FactBox
caption present on virtually every document page. So every probe returned that caption as its
"error message", while the real message sat further down the page, and `.match()` returns only the
*first* hit. A whole run of probes reported silent data loss on released purchase orders; a
screenshot showed BC displaying a precise, correct error the entire time.

Read the surfaces explicitly instead, filter the FactBox caption out, prefer a real validation
sentence over the generic banner, and always return the raw list so you can see what was found:

```js
const { dialogs, message, pageHasError, surfaces } = await readError(frame);
```

Validate the helper against a case you *know* must fail before trusting a negative result from it.

## 11. Practical cautions

- Give the first navigation a long timeout (cold start; see the environment instructions).
- Take a screenshot on failure — cheap, and invaluable when a selector breaks.
- Exploratory runs create junk records and post documents irreversibly. Plan clean-up, or use a
  disposable container.

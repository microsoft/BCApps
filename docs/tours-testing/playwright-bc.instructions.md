---
description: "Driving the Business Central web client with Playwright: iframe structure, locators, deep links, dialogs, and using SQL as the test oracle."
---

# Driving Business Central with Playwright

Playwright is **complementary to AL tests, not a replacement**. AL tests are faster, run in CI, and
should carry functional coverage. Playwright earns its place for what AL tests cannot reach:
browser Back, reload, closing the tab mid-operation, double-clicks, and client-layer behaviour.

Prerequisite: a warmed-up container — [`bc-test-environment.instructions.md`](./bc-test-environment.instructions.md).

```powershell
npm init -y ; npm install --no-save @playwright/test ; npx playwright install chromium
```

Keep exploratory tooling out of the product build.

Everything below is already implemented in [`harness/bc.js`](./harness/README.md). Read this file to
understand *why* those helpers look the way they do, and before writing a new one.

## 1. The app UI lives inside a child iframe

The top-level document contains only the black header bar. Lists, cards, actions and dialogs are all
in a **nested frame**. Find it by ARIA-landmark density:

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

**Re-acquire the frame after every navigation.** A stored handle goes stale and the errors look like
missing elements rather than stale handles.

## 2. Sign-in

A plain form in the **main** frame. Credentials come from the file `BC_CREDS` points at — never
hard-code them, and never default the container (see the harness README on parallel tours).

```js
const { CREDS, BASE } = require('./bc');
await page.goto(BASE, { waitUntil: 'domcontentloaded' });
await page.fill('#UserName', CREDS.user);
await page.fill('#Password', CREDS.password);
await page.click('#submitButton');
```

Add `?tenant=default` on a multitenant container. Give the first navigation a long timeout — cold
start is 60 s+.

## 3. Opening one specific document

Deep links are more reliable than navigating the UI and keep scenarios independent:

```
?page=22     Customer List        ?page=21    Customer Card
?page=9301   Sales Invoice List   ?page=43    Sales Invoice Card
```

```js
const url = `${BASE}?page=43&filter=` + encodeURIComponent("'Sales Header'.'No.' IS '102199'");
```

### ⚠️ `filter=` is silently ignored on some pages

On Transfer Order (5740) every variant landed on the Home page or an empty new card, with no error.
The failure is invisible — the browser shows *a* page, so a probe that does not assert which record
it is on reports results for the wrong document, or an empty one.

The reliable recipe is **list → row → Enter**:

```js
await page.goto(`${BASE}?page=5742`);            // the LIST page
const row = frame.locator('[role="row"]').filter({ hasText: '1001' }).first();
await row.locator('[role="gridcell"]').first().click();
await frame.locator('body').press('Enter');      // Enter opens; a click only selects
```

Three things that waste time: clicking the cell alone (selects, never opens); the list ribbon
(Transfer Orders has **no `Edit` action**); double-click (unreliable in the grid).

### ⚠️ Assert the record before mutating anything

There is no usable record identity *inside* the app frame:

```
h1                      -> 0 matches
[class*="pageCaption"]  -> 0 matches
[role="heading"]        -> 29 matches, the first being the COMPANY name
```

The browser title is authoritative:

```js
await page.title();          // "Service Order - SO000005 ∙ Deerfield Graphics Company"
assertCard(page, 'SO000005') // bc.js — THROWS
```

It must throw. A soft `console.log` warning lets the run continue and the output still looks like
evidence; two void runs produced fake results that way.

## 4. Locators

Actions are `menuitem`, not `button`. Dialog buttons are real buttons.

```js
frame.getByRole('menuitem', { name: /^Post$/ })
frame.getByRole('button',   { name: /^Yes$/i })
```

Action captions are exact and matter: **"Release to Ship"**, not "Release".

### ⚠️ `getByRole('textbox')` misses half the fields

Plain text fields are `role=textbox`, but any field with a `TableRelation` (a lookup) or a date
picker is a **`role=combobox`**. On page 5740 a textbox-based helper reported `Posting Date`,
`Transfer-from Code`, `Transfer-to Code` and `In-Transit Code` as "not on the page". All four were
present, visible and editable.

```js
frame.getByRole('textbox', { name: 'Posting Date' })   // ✗ 0 matches
frame.getByLabel('Posting Date', { exact: true })      // ✓
```

`getByLabel` resolves **both** `aria-label` and `aria-labelledby` and ignores the role — which
matters because many BC cards set `aria-label=""` and put the name in `aria-labelledby`.
`data-control-name` does not exist anywhere in the BC DOM.

> A "NOT-ON-PAGE" result is a claim about your locator, not about the product.

### ⚠️ Always scope to the input element

When a card is open, **the list behind it is still in the DOM**, so this matches two elements — and
`.first()` typically resolves to the read-only grid `span`, which silently accepts no input:

```js
frame.getByLabel('Name', { exact: true })                              // ✗ span AND input
frame.getByLabel('Name', { exact: true }).and(frame.locator('input'))  // ✓
```

This produced a convincing but entirely false "first keystroke is dropped" bug report. **If you see
input loss, suspect the locator first.**

Second form of the same trap: on a list page, column headers carry the field's `aria-label` too.
`[aria-label="Category"]` resolved to a `<span id="column_header_b9">` whose click was intercepted
by the sticky header, dying in a 30-second timeout that looked like a hung page. A
`Timeout … subtree intercepts pointer events` message is almost always this. Scope to a row:

```js
frame.locator('[role="row"]:has-text("…")').first().locator('[role="gridcell"]').nth(n)
```

### ⚠️ A document card contains *two* grids

`getByRole('grid')` returns the lines grid you want **and** the leftover list grid from the page you
came from; `getByText('Item')` happily matched a control ~1100 px away in the wrong one. Identify by
marker column header:

```js
for (const g of await frame.getByRole('grid').all()) {
  const heads = await g.getByRole('columnheader').allTextContents();
  if (heads.some(h => h.trim() === 'Type')) return g;   // ✓ the lines grid
}
```

Cells **are** exposed as `gridcell` (603 on a populated card).

### ⚠️ `fill()` does not commit — always Tab

`fill()` sets the value without blurring, so BC never runs `OnValidate` and nothing is stored. The
page looks right and the database disagrees. This produced a second false finding.

```js
await input.fill('150');
await input.press('Tab');     // ✓ this is what commits
```

**Option (dropdown) fields cannot be set by typing at all.** `Ctrl+A` + type + `Tab` leaves the old
value while appearing to succeed — it also silently defeated a *cleanup* step, which logged
`customer unblocked` and left `Blocked=3` in the database. Use the list:

```js
await combo.click();
await page.keyboard.press('Alt+ArrowDown');   // open the option list
await page.keyboard.press('Home');            // first option (often blank)
await page.keyboard.press('Enter');
```

## 5. Prefer keyboard shortcuts to toolbar clicks

The sticky line toolbar intercepts pointer events. Clicking `Post…` failed with a normal click, with
`force: true`, and with raw `page.mouse.click()` at the resolved coordinates. **`F9` posts cleanly,
every time.** When an element resists three pointer strategies, stop escalating force and find the
keyboard route.

| Action | Shortcut |
| --- | --- |
| Post | `F9` |
| Post and print | `Shift+F9` |
| New line / record | `Ctrl+N` |
| Close page | `Escape` |

Not everything has one: `Ctrl+F9` on `<body>` did **not** release a document — use the action.

Dialog buttons resist pointer clicks the same way. **`Escape` is the only reliable dismissal**, and
when dialogs stack, `.first()` resolves to a covered one — dismiss repeatedly rather than targeting
a button. To *answer* rather than cancel, press **`Enter`**: the post dialog (*Ship / Invoice / Ship
and Invoice*) must be answered or nothing posts, and a run that escapes it looks exactly like a
silent posting failure.

## 6. Card-level traps

- **Deep-linked cards open read-only.** Click `button[title="Make changes on the page"]` first, or
  every probe silently does nothing.
- **Header icons have no `aria-label`** — their name comes from `title`. The delete icon is
  `Delete the information`.
- **Do not `Escape` a teaching tip**, and do not use `getByRole('button', {name:/close/i})` for it.
  Both close the whole card.
- **Never call a blanket `dismissDialog()` after creating a record.** It presses `Escape`, which on
  a fresh card *closes the card*. A probe that did this destroyed a new Purchase Order before adding
  lines; every later read returned `There is nothing to show in this view`, which looked like a
  product fault. Only dismiss after confirming a dialog is open.
- **Clicking `New` navigates** (9305 → 42). Wait for it: `page.waitForURL(/page=42/)`.
- **Some cards have no visible `No.` field.** On Purchase Order (50) the number is only in the
  caption, so `field(frame,'No.')` returns the *line's* `No.` Parse the title instead — without the
  document number you cannot run the SQL oracle at all.
- **A grid cell's `innerText` is not a reliable readback.** Unfocused cells often render empty even
  when the record holds a value.

### ⚠️ Half the fields are not in the DOM until you expand something

Both mechanisms make a field *absent*, not hidden, so a locator returns 0 and the probe reports "not
on page".

**Collapsed FastTabs** — expand by caption, as buttons:

```js
for (const cap of ['General','Shipment','Transfer-from','Foreign Trade']) {
  const t = frame.getByRole('button', { name: cap, exact: true }).first();
  if (await t.getAttribute('aria-expanded') === 'false') await t.click();
}
```

Do **not** loop over every `[aria-expanded="false"]` — that also matches navigation menus and every
column header, and it ran for **8 minutes** without finishing.

**`Show more`** — fields marked `Importance = Additional` are omitted entirely until it is clicked.
Click one at a time, re-querying; a cached `nth()` list goes stale after the first click, whose
classic symptom is that only the first FastTab ever expands.

```js
for (;;) {
  const link = frame.getByText('Show more', { exact: true }).first();
  if (!await link.isVisible().catch(() => false)) break;
  await link.click();
}
```

### ⚠️ A read-only field is a `<span>`, so it reports as "not on page"

When a guard makes a field non-editable, BC renders it **without an input**. A helper requiring
`input` records `NOT-ON-PAGE` when the truth is `READ-ONLY` — a materially different result, and
the second one is evidence the guard works.

```js
const state = await input.count() ? 'editable' : await anyEl.count() ? 'read-only' : 'absent';
```

## 7. Saving, closing, and native dialogs

BC **auto-saves when a field commits** (Tab or focus change); there is no Save action on most cards.
`Escape` closes a card. Back, Escape, reload and tab-close are **not** equivalent — each can produce
different commit behaviour. Never assume; assert.

BC registers `beforeunload` during long operations such as posting, and an unhandled native dialog
**hangs `page.reload()` or `page.goBack()` until the timeout** — easily misread as a product hang:

```js
page.on('dialog', d => d.accept());
```

## 8. Reading errors — BC has *four* error surfaces, and two lookalikes

The most important helper in the harness and the easiest to get wrong. A probe that reads only one
surface reports a correctly behaving product as silently discarding data.

| # | Surface | Looks like |
|---|---|---|
| 1 | Modal dialog | `role="dialog"` |
| 2 | Page-level error bar | *"The page has an error. Refresh (F5) to undo the change…"* |
| 3 | Inline bubble beside the cell | *"Status must be equal to 'Open' in Purchase Header…"* |
| 4 | Notification bar under the title | *"Notifications: 2 …"* |

Surfaces 2 and 3 are how a **grid** normally rejects a value. A tour that only checks dialogs sees
nothing, reads the row back unchanged, and concludes "accepted then silently reverted".

**Lookalike 1 — a Yes/No confirmation.** Identical in the DOM (same `role="dialog"`, same alert
markup) but it means the product is **proceeding**, not refusing. BC raises it when a key field is
edited on a document that already has lines:

> *"Do you want to change Transfer-from Code?  Yes  No"*

The first Transfer tour recorded `Transfer-from Code` as REFUSED on an *open* order because of this;
the field was working as designed and waiting for an answer. Classify it separately —
`readError()` returns `confirmation` alongside `message`:

```js
const isConfirm = t => /\b(do you want to|are you sure)\b/i.test(t) || /\byes\b[\s\S]{0,6}\bno\b/i.test(t);
```

**Answer the confirmation, then read the error.** BC asks first and validates second. On a
released-to-ship service order, changing `Customer No.` raises a confirmation and only *after* Yes
does it fail with *"Release Status must be equal to 'Open'…"*. A probe that stops at the
confirmation records ACCEPTED when the truth is REFUSED. **A probe that leaves a confirmation
unanswered has not tested anything.**

**Lookalike 2 — a loose regex on `body.innerText`.** The original helper did this:

```js
const m = body.match(/.*(?:must be|cannot|not valid|is not|already exists).*/i);
```

`/is not/` matches inside **"There is not&#8203;hing to show in this view"**, a FactBox caption on
virtually every document page. Since `.match()` returns only the first hit, every probe returned that
caption as its "error message". A whole run reported silent data loss on released purchase orders
while a screenshot showed BC displaying a precise, correct error throughout.

Read the surfaces explicitly, filter the FactBox caption, prefer a real validation sentence over the
generic banner, and return the raw list so you can see what was found. **Validate the helper against
a case you know must fail before trusting any negative result from it.**

## 9. SQL as the oracle

The BC API v2.0 on port 7048 **rejects the container password** for basic auth — it needs a web
service access key. Query SQL inside the container instead:

```powershell
Invoke-ScriptInBcContainer -containerName <ContainerName> -scriptblock {
  Invoke-Sqlcmd -ServerInstance 'localhost\SQLEXPRESS' -Database 'CRONUS' -Query @"
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT COUNT(*) FROM [CRONUS International Ltd_`$Customer`$437dbf0e-84ff-417a-965d-ed2bb9650972]
"@
}
```

`READ UNCOMMITTED` is not optional: **an open browser session holds locks**, so a `SELECT` that ran
fine before a tour hangs indefinitely afterwards and looks like a dead container.

### Always discover names, never construct them

```sql
SELECT name FROM sys.tables  WHERE name LIKE '%Sales Line%';
SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('<table>') ORDER BY column_id;
```

The pattern is `<Company>_$<Table>$<ExtensionGuid>`, and every part of it has a trap:

- **The company prefix is the display name, mangled** — `CRONUS International Ltd_`, not `CRONUS`.
  Check with `SELECT [Name] FROM [dbo].[Company]`.
- **Not every table is company-prefixed.** System/setup tables have no company segment:
  `[Application Area Setup$<guid>]`. Prefixing one yields `Invalid object name`, which is easy to
  misread as "the feature isn't installed".
- **Every app has its own extension GUID.** Base App is `437dbf0e-84ff-417a-965d-ed2bb9650972`;
  Sustainability, E-Document and Shopify each have their own.
- **`%`, `.` and `/` in a field name all become `_`.** `Line Discount %` → `[Line Discount _]`,
  `No.` → `[No_]`. Three characters collapse to one, so the mapping cannot be reversed.
- **Captions are not column names.** The field labelled `Email` is `[E-Mail]`. A probe keyed to the
  wrong caption *silently skips*, so log skips as loudly as failures.
- **`SystemCreatedAt` is not selectable everywhere**; the physical column is `[$systemCreatedAt]`
  (escape as `` [`$systemCreatedAt] `` in PowerShell).
- Escape `$` in table names as `` `$ `` inside PowerShell strings.

Check the **database** name too: a single-tenant container uses `CRONUS`, a multitenant one uses the
tenant database.

### Query traps

- **`DATALENGTH`, not `LEN`,** whenever whitespace is the subject — `LEN` ignores trailing spaces, so
  a trailing-space finding is invisible to it.
- **Do not sort "newest" by number.** `CAST([No_] AS BIGINT) DESC` returns demo data (`104011`)
  ahead of the order you just created (`1015`). Order by `[$systemCreatedAt] DESC`.
- **`Invoke-Sqlcmd` flattens multiple result sets.** Piping two differently-shaped `SELECT`s into
  `Format-Table` silently prints only the first. One `SELECT` per call, or `UNION ALL`.
- **Some counters are not in the table** — No. Series consumption is not in `Last No. Used`; it uses
  SQL sequences.

Useful tables: `Customer`, `Sales Header` (`Document Type` 2 = Invoice), `Sales Invoice Header`,
`Cust_ Ledger Entry`, `G_L Entry`. Duplicate-post detector: group `Sales Invoice Header` by
`Pre-Assigned No_` `HAVING COUNT(*) > 1`.

### Verify your cleanup, not just your probes

Anything a tour changes outside the document under test — blocking flags, setup, posting windows —
must be restored **and the restoration confirmed in SQL**. The next tour otherwise starts from
silently corrupted master data.

## 10. Practical cautions

- Screenshot on failure. Cheap, and invaluable when a selector breaks.
- Exploratory runs create junk and post irreversibly. Plan clean-up, or use a disposable container.
- Record what the session mutated, in the session sheet.

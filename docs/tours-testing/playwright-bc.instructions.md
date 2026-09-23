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
| **Item Tracking Lines** | **`Ctrl+Alt+I`** |
| Close page | `Escape` |

Not everything has one: `Ctrl+F9` on `<body>` did **not** release a document — use the action.

⚠️ **Item Tracking Lines is `Ctrl+Alt+I`, not `Ctrl+Shift+I`** (declared in
`PurchaseOrderSubform.Page.al`), and the keyboard is the *only* route: the fallback you would reach
for — clicking the `Line` menu — dies in a 30 s timeout because the sticky line toolbar intercepts
the pointer. The documented trap sits squarely on the obvious alternative.

⚠️ **The post-choice radio (Receive / Invoice / Receive and Invoice) has no accessible name.** BC
renders it as bare `input[type=radio]` elements inside `<li>`s in a `ul.radiobuttoncontrol-edit` —
no `aria-label`, no `aria-labelledby`, no `role`, so `getByRole('radio', {name})` and `getByLabel`
both find nothing. The caption lives only in the surrounding `<li>` text. Clicking around the
control lands on whatever is already selected, and the default is **Receive and Invoice**, so a
tour that cannot drive it silently posts a full receipt+invoice every time — quietly ruling out any
probe that needs a receive-only document, such as an Undo Receipt charter.

`chooseRadio()` maps the caption via the `<li>` and uses `check({force: true})`. Exact match is
tried first, because *Receive* is a prefix of *Receive and Invoice*.

⚠️ **`Enter` does not submit the post dialog.** Measured: the radio takes, `Enter` does nothing,
and the dialog is still open while SQL shows nothing posted — which looks exactly like a silent
posting failure. `postDocument()` drives **OK** explicitly.

> The radio is client state. **What actually posted is a question for SQL**: a Receive-only post
> writes a `Purch. Rcpt. Header` and **no** `Purch. Inv. Header`. Assert that, not the radio.

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

## 8. Reading errors — BC has *five* error surfaces, and two lookalikes

The most important helper in the harness and the easiest to get wrong. A probe that reads only one
surface reports a correctly behaving product as silently discarding data.

| # | Surface | Looks like |
|---|---|---|
| 1 | Modal dialog | `role="dialog"` |
| 2 | Page-level error bar | *"The page has an error. Refresh (F5) to undo the change…"* |
| 3 | Inline bubble beside the cell | *"Status must be equal to 'Open' in Purchase Header…"* |
| 4 | Notification bar under the title | *"Notifications: 2 …"* |
| 5 | **A whole page** — BC navigates to an *Error Messages* list | no dialog, no alert, no error class, **nothing** |

Surface 5 is the nastiest and is how **posting** fails. There is no dialog to read: the window
navigates to an Error Messages list page, so surfaces 1–4 all return nothing and a helper that
checks only those reports **total silence** while BC is displaying a precise, correct refusal
naming the exact document line. On the item-tracking posting tour this would have been filed as two
false *"posts silently"* findings; only a screenshot and a SQL assertion caught it.

`readError()` checks it automatically and returns the rows as `errorPage`. That is deliberate —
the failure mode is silence, so a tour that does not already know about this surface would never
think to go looking for it. ⚠️ The grid **truncates** the sentence (*"The quantity to invoice does
not match the …"*); open the Details pane when you need the whole thing.

⚠️ **`errorPage[0]` is not the message.** The grid interleaves its header row and filler rows
(`"0 0"`) with the real sentence. An early version of this helper returned row 0 blindly and quoted
an entire column header — *"Type No. Item Reference No. Withholding Tax …"* — as BC's refusal text.
That is **worse than the silence it replaced**: an empty message gets questioned, a plausible wrong
one gets quoted in a finding. `readError()` now drops the header and filler rows and prefers a row
that actually reads like a refusal.

> **Mock from a DOM you have actually looked at.** The unit test for this surface was written from
> an *assumed* two-column grid whose header began with "Description", so the helper's header filter
> matched the mock and the test passed green while the live behaviour was broken. A test built on
> an assumption tests the assumption.

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
`harness/readError.test.js` is that check — it mocks the frame, needs no container, and every case
in it is a false result this helper produced on a real tour:

```powershell
node docs\tours-testing\harness\readError.test.js
```

### ⚠️ Dialogs stack when you *read* them, not just when you dismiss them

The trap below cost a withdrawn finding on the item-tracking tour, and it is the same stacking
problem this guide already documents for dismissal.

Some BC **pages are themselves rendered as `role="dialog"`** — Item Tracking Lines (6510), Enter
Quantity to Create, most worksheet sub-pages. So on those pages:

| | `dialogs[0]` | `dialogs[1]` |
|---|---|---|
| What it is | the Item Tracking Lines **page** | the actual question |
| Text | 600 characters of column headers | *"…excess quantity has been defined. Close the form anyway?"* |

A helper that reads `dialogs[0]` returns page chrome on a clean step and **returns nothing when
there is a real question** — which reads exactly like silent data loss. Scan every dialog, and
prefer the **last** one: dialogs stack, so the newest is the one the user is looking at.

Two corollaries:

- **Never treat the containing page's own text as an error.** A real BC message is a sentence, not
  a screenful; `readError()` discards long dialog text carrying no validation or question sentence,
  and returns it under `chrome` so an unexpected empty `message` is still debuggable.
- **`must be` is not the only shape of a refusal.** The genuine message *"…accounts for more than
  the quantity you have entered. You must adjust the existing item tracking…"* says **"must
  adjust"**. An allow-list of phrasings missed it, and a probe reading `message` alone would have
  recorded a guarded case as unguarded. Mind word boundaries too: `\balready exist\b` does **not**
  match *"exists"*.

### ⚠️ The fade overlay outlives the dialog

BC leaves `.spa-dialog.appear-fadeout` in the DOM after a dialog closes, and it still intercepts
pointer events. The next grid click then fails with Playwright's *"intercepts pointer events"*
timeout after a full 30 s — which looks like a hung page and is not. Use `settleOverlay()` /
`clickSettled()`, which wait for it to leave.

### ⚠️ Clicking *Yes* is not reliable — and answering is not evidence

A pointer click on a confirmation's *Yes* button can **neither answer nor error**: the dialog
closes, nothing happens, and the records you expected to be deleted read back as orphans. On the
item-tracking tour this manufactured an "orphaned reservation entries" finding that only the SQL
check caught. Use `answerConfirm()`, which focuses the button and presses `Enter`.

> **After answering a confirmation, assert in SQL that the underlying record actually changed.**
> "I clicked Yes and saw no error" proves nothing about what BC did.

### ⚠️ Generalise it: after *any* DOM readback, assert in SQL

The confirmation rule above is a special case of a bigger one, and the general form has now caught
three separate false results:

| What the DOM said | What was actually true |
|---|---|
| `aria-checked="true"` on *Accept Action Message* | 0 accepted rows in SQL — BC had not committed yet |
| dialog text empty after closing a page | the real question was sitting in `dialogs[1]` |
| `"0"` in a request-page dropdown | that is the option **index**, not a refusal |

In each case a tour risked reporting *"I couldn't read it"* as *"the product refused it"* — turning
a claim about the instrument into something that sounds like a finding. **Controls apply to reads,
not only to writes** (§5.3).

### ⚠️ Boolean cells: three traps, and the DOM lies about all of them

Setting a checkbox in a lines grid — *Accept Action Message* on the planning worksheet is the
canonical case — fails in a way that looks exactly like success:

1. The clickable control is the `div[role="checkbox"]`. The `input[type=checkbox]` inside it is
   `aria-hidden` with `tabindex="-1"` and ignores clicks — and a row-scoped locator like
   `row.locator('input[type=checkbox]')` resolves to the **row-selection** checkbox, a different
   control entirely, which reports success while the field never changes.
2. Clicking the cell and pressing `Space` does nothing at all.
3. `aria-checked` flips to `"true"` **immediately**, but BC commits when focus leaves the **row**,
   not the cell — `Tab` alone is not enough. Read the DOM right after the click and it says the
   value changed; close the browser there and the database never hears about it.

`setBoolean()` clicks the right control, leaves the row to force the commit, and **polls the
database** until it agrees. Its `verify` callback is **required**: a single early read is
indistinguishable from a write that never happened.

### ⚠️ Request pages are where a tour gets silently defeated

A batch/report request page (*Calculate Regenerative Plan*, *Carry Out Action Message*) is the
highest-risk surface in the harness, because getting it wrong produces **total silence** rather
than an error — and silence is indistinguishable from "the product did nothing".

This cost a charter. `Carry Out Action Message` defaults its four Create-\* options to *"Last used
options and filters"*, so a session that inherits a purchase-only run arrives with
`Production Order` blank. Carry-out then completes with **no error and creates nothing**. Both the
probe *and its control* were silent — the §5.3 signature of a broken instrument, not a finding.

Three traps, all of which make an option field look undriveable:

| Trap | What you see | Reality |
|---|---|---|
| BC renders enums as a native `<select>`, not the combobox `<input>` used elsewhere | `getByLabel(...).and(locator('input'))` finds nothing; the field reports as **absent** | Use `selectOption()` — no typing, no opening the list |
| A `<select>`'s `.value` is the option **index** | You set *Firm Planned*, read back `"0"`, and conclude the write was refused | Read `selectedOptions[0].text` |
| The DOM caption is not the AL caption | `Create Production Order` matches nothing | It is labelled just **"Production Order"** |

`setOption()` handles all three and **throws unless the value actually committed** — deliberately,
because a request page whose options did not commit turns every later probe into a false negative.
`getOption()` reads the caption.

Two more request-page traps:

- **Ribbon groups hide their actions.** *Calculate Regenerative Plan* and *Carry Out Action
  Message* are absent from the DOM until the **Prepare** group is clicked. A zero count is a claim
  about the locator, never proof the action is absent (§6.3). Use `openAction(page, frame, name,
  group)`.
- **Request-page captions collide with the grid behind them.** `Starting Date`, `No.` and
  `Description` each resolve to two inputs; an unscoped locator drives the **worksheet grid**
  instead of the dialog. Scope with `topDialog(frame)`.

And one page-level trap: a first visit raises an **"About …" teaching tip** that must be closed
with its own **Got it** button — `Escape` would close the page behind it (§6). Use
`dismissTeachingTip()`.

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
- **A `CAST`/`CONVERT` projection can return zero rows and no error.** A query over
  `Production Order` that projected with `CONVERT` returned nothing, while the same query with
  plain column names returned 9 rows. A silently empty oracle reads as *"the table is empty"* —
  which is a finding-shaped lie. Project plain columns and format in PowerShell.
- **Some counters are not in the table** — No. Series consumption is not in `Last No. Used`; it uses
  SQL sequences.
- **`LINENO` is a reserved T-SQL keyword.** `SELECT [Line No_] AS LineNo` fails with *"Incorrect
  syntax near the keyword 'LineNo'"*, which reads exactly like a mangled table or column name and
  sends you hunting a PowerShell `$`-escaping problem that was never there. Alias it `LnNo`.

Useful tables: `Customer`, `Sales Header` (`Document Type` 2 = Invoice), `Sales Invoice Header`,
`Cust_ Ledger Entry`, `G_L Entry`. Duplicate-post detector: group `Sales Invoice Header` by
`Pre-Assigned No_` `HAVING COUNT(*) > 1`.

### ⚠️ Check whether your "oracle" table is a buffer

`Tracking Specification` reads **0 rows before and after a successful tracked posting**, because on
the purchase-receipt path it is a *transient buffer*, not a record. An earlier tour took its
permanent zero as evidence that the posting path had never been reached, and carried that wrong
conclusion into its follow-up charters.

The durable post-posting oracle for item tracking is **`Item Entry Relation`** plus the serial/lot
fields on **`Item Ledger Entry`** — those did move, exactly in step with the posts. Before trusting
a zero, confirm the table is where the data is *supposed* to end up.

### Verify your cleanup, not just your probes

Anything a tour changes outside the document under test — blocking flags, setup, posting windows —
must be restored **and the restoration confirmed in SQL**. The next tour otherwise starts from
silently corrupted master data.

## 10. Practical cautions

- Screenshot on failure. Cheap, and invaluable when a selector breaks.
- Exploratory runs create junk and post irreversibly. Plan clean-up, or use a disposable container.
- Record what the session mutated, in the session sheet.

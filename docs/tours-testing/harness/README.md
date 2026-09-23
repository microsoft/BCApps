# Tour harness

Working code from the tours run so far, so a new tour starts from something that already runs.

| File | Purpose |
| --- | --- |
| `New-TourContainer.ps1` | Creates the container non-interactively — generates a random password, persists `bc-credentials.json`. Never prompts. |
| `bc.js` | Playwright helpers. Every trap in `playwright-bc.instructions.md` is already handled here. |
| `Invoke-Probe.ps1` | Runs one probe with a SQL snapshot before and after, and prints the delta. |
| `readError.test.js` | Regression test for `readError()`. Mocks the frame, so it needs no container: `node readError.test.js`. |
| `Find-TourTargets.ps1` | Static scan of an app's `*.Table.al`. *"What is worth probing here?"* before opening a browser. |
| `Find-UnguardedFields.ps1` | Per-field status-guard scan of one document table. Flags deliberate `Status::Released` handling so it is not reported as a defect. |
| `Find-TourDrift.ps1` | Differential across two parallel tables (Sales vs Purchase vs Transfer). |
| `Find-PageDrift.ps1` | Differential across pages that share one table — the six sales document types. |
| `sab.js` / `psab.js` / `tsab.js` / `svc.js` | Worked Saboteur probes for Sales, Purchase, Transfer and Service orders. |

Method behind the scanners: §6 of the tours instructions. **They generate hypotheses, never
verdicts** — every scan-based prediction made so far has been wrong, always by under-reporting
guarding (§6.3).

## ⚠️ The harness runs from a working copy, not from the repo

`node_modules` is not committed, so tours run from a scratch folder that has Playwright installed.
The repo copy is the artefact; the scratch copy is what executes.

**Copy across before every run, in both directions.** A fix made in scratch and not copied back is
lost; an edit made in the repo and not copied across is silently not exercised.

### ⚠️ Driving SQL from Node

Two traps, both of which produce errors that read like a wrong table name:

- **`powershell` is not `pwsh`.** BcContainerHelper is a PowerShell 7 module, so Windows
  PowerShell 5.1 cannot load it.
- **`pwsh -Command` interpolates `$` inside the query.** BC table names are full of them, so
  `[CRONUS International Ltd_$Requisition Line$437dbf0e-...]` becomes
  `CRONUS International Ltd_ Line-84ff-...` and SQL Server answers *"Invalid object name"* — which
  looks exactly like you got the table name wrong. Write the query to a temp `.ps1` inside a
  single-quoted here-string and invoke it with `pwsh -File`.

```powershell
Copy-Item .\docs\tours-testing\harness\*.js,.\docs\tours-testing\harness\*.ps1 $RUN -Force
```

`New-TourContainer.ps1` is the exception — run it from the **repo** copy, because it imports the
checkout's own build scripts to resolve the artifact. It refuses to run if it cannot find them.

## Running several tours in parallel

Multiple BC containers coexist happily: each gets its own hostname and IP on the NAT network,
nothing publishes host ports, and `Invoke-ScriptInBcContainer -containerName` keeps the SQL oracle
isolated. The artifact cache is shared, so the second container builds much faster. Budget roughly
10–15 GB of disk and a few GB of RAM each.

One environment variable configures a session:

```powershell
# Session A
.\New-TourContainer.ps1 -ContainerName BCApps-Money
$env:BC_CREDS = "$env:USERPROFILE\.bc-tours\BCApps-Money-credentials.json"

# Session B, at the same time
.\New-TourContainer.ps1 -ContainerName BCApps-Undo
$env:BC_CREDS = "$env:USERPROFILE\.bc-tours\BCApps-Undo-credentials.json"
```

`BC_CREDS` carries the container name, so `bc.js` derives the web client URL from it and
`Invoke-Probe.ps1` derives the container to snapshot. All three — browser, credentials and oracle —
therefore address the same container by construction.

`bc.js` **throws if `BC_CREDS` is unset** rather than defaulting to a container name. That is
deliberate: a default is silently wrong in the worst possible direction. Two sessions touring the
same container would mutate each other's documents, and each would read the other's writes as
product behaviour — which destroys the before/after SQL delta the whole method rests on.

Set `BC_BASE` only to override the URL, e.g. when the container name does not resolve and you need
its IP.

Each session also needs its **own scratch folder**, since probe files are edited per tour.

## What `bc.js` gives you

| Helper | Why it exists |
| --- | --- |
| `appFrame(page)` | The UI is in a nested iframe; picks it by `[aria-label]` density. Re-acquire after every navigation. |
| `signIn(page)` | Handles the ~60 s cold start. |
| `openPage(page, id, filter)` | Deep links, then clicks *Make changes on the page* — deep-linked cards open read-only. |
| `assertCard(page, no)` | **Throws** if the wrong record is open. There is no record identity inside the frame; this reads the browser title. |
| `field(frame, caption)` | `getByLabel` (finds comboboxes, not just textboxes), scoped to the real `input` rather than the read-only grid cell behind the card. |
| `fieldOne(frame, caption)` | First *visible and editable* match, for captions that legitimately repeat. |
| `newDocument(page, listId, cardId)` | Clicks New and waits for the navigation to land. |
| `linesGrid(frame)` | Picks the lines grid out of the **two** grids in the DOM, by marker column header. |
| `lineCell(frame, column, opts)` | Maps a column header's x-centre onto `gridcell` x-ranges. `{click:false}` reads without entering edit mode. |
| `setBoolean(page, frame, {row, column, value, verify})` | Ticks a boolean cell and **polls SQL until the database agrees**. `verify` is required — `aria-checked` flips before BC commits, so a DOM readback is not evidence. |
| `readError(frame)` | Collects text from all five error surfaces, and returns `confirmation` separately — a Yes/No dialog means BC is *proceeding*, not refusing. Scans **every** stacked dialog, discards pages that are themselves rendered as dialogs (returning them under `chrome`), matches BC's many phrasings of a refusal rather than just *"must be"*, and detects the *Error Messages* **page** a posting failure navigates to (`errorPage`). |
| `readErrorPage(page, frame)` | The Error Messages list page on its own. `readError()` already calls it; use directly only when you want the rows without the rest. |
| `dismissDialog(frame)` | `Escape`, repeatedly. Dialog buttons resist pointer clicks and dialogs stack. |
| `answerConfirm(page, frame, 'Yes')` | Answers a confirmation by focus + `Enter`. A pointer click on *Yes* can neither answer nor error. **Then assert in SQL that the record changed** — the answer is not evidence. |
| `setOption(page, frame, label, value)` | Sets a request-page dropdown and **throws unless it committed**. Handles the native `<select>` BC uses for enums, and reads back the caption rather than the index. |
| `getOption(frame, label)` | Reads an option field's caption. Never read `.value` yourself — on a `<select>` it is the index. |
| `openAction(page, frame, name, group)` | Clicks a ribbon action, opening its collapsed group first. A 0-count action is a locator claim, not proof of absence. |
| `dismissTeachingTip(page, frame)` | Closes the *"About <page>"* tip via its own **Got it**. `Escape` would close the page behind it. |
| `topDialog(frame)` | The dialog on top, for scoping input. Request-page captions collide with the grid behind them. |
| `settleOverlay(page, frame)` | Waits out `.spa-dialog.appear-fadeout`, which outlives its dialog and intercepts clicks for ~30 s. |
| `clickSettled(page, frame, locator)` | `settleOverlay` + click, with retries. Use for grid clicks after any dialog round-trip. |

`readError()` has a regression test that needs no container — every case in it is a false result the
helper once produced on a real tour. Run it after touching the helper:

```powershell
node docs\tours-testing\harness\readError.test.js
```

## Writing a probe

Keep boundary cases in a table, not copied blocks. `?` means *genuinely exploring*:

```js
const CASES = [
  { field: 'Line Discount %',      value: '150',  expect: 'reject' },
  { field: 'Unit Price Excl. VAT', value: '-100', expect: '?' },
];
```

Run one probe at a time from the command line, so a hang costs a minute rather than a session. Then
confirm **every** outcome in SQL — including the ones that looked fine.

Before writing a new helper, read `playwright-bc.instructions.md`. Most of what looks like a product
bug on a first run is one of the traps documented there.

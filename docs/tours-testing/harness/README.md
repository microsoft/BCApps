# Tour harness

Working code from the tours run so far, so a new tour starts from something that already runs.

| File | Purpose |
| --- | --- |
| `New-TourContainer.ps1` | Creates the container non-interactively — generates a random password, persists `bc-credentials.json`. Never prompts. |
| `bc.js` | Playwright helpers. Every trap in `playwright-bc.instructions.md` is already handled here. |
| `Invoke-Probe.ps1` | Runs one probe with a SQL snapshot before and after, and prints the delta. |
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

```powershell
Copy-Item .\docs\tours-testing\harness\*.js,.\docs\tours-testing\harness\*.ps1 $RUN -Force
```

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
| `readError(frame)` | Collects text from all four error surfaces, and returns `confirmation` separately — a Yes/No dialog means BC is *proceeding*, not refusing. |
| `dismissDialog(frame)` | `Escape`, repeatedly. Dialog buttons resist pointer clicks and dialogs stack. |

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

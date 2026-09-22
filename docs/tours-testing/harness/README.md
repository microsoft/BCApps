# Tour harness

Working code from five exploratory tours against a local BC container. It is here so a new tour
starts from something that already runs, rather than from a blank file.

| File | Purpose |
| --- | --- |
| `New-TourContainer.ps1` | Creates the container non-interactively — generates a random password and persists `bc-credentials.json`. Never prompts. |
| `bc.js` | The Playwright helpers. Every sharp edge in `playwright-bc.instructions.md` is already handled here. |
| `Invoke-Probe.ps1` | Runs one probe with a SQL snapshot before and after, and prints the delta. |
| `Find-TourTargets.ps1` | Static scan of an app's `*.Table.al` metadata. Answers *"what is worth probing here?"* before you open a browser — see §9 of the tours instructions. |

## Getting a tour running

```powershell
# 1. Container (~20 min, unattended)
.\New-TourContainer.ps1

# 2. Playwright, once
npm init -y ; npm i -D playwright ; npx playwright install chromium

# 3. One probe at a time
node mytour.js probe-name
```

## What `bc.js` gives you

| Helper | Why it exists |
| --- | --- |
| `appFrame(page)` | The app UI is in a nested iframe; picks it by `[aria-label]` density. Re-acquire after every navigation. |
| `signIn(page)` | Handles the ~50 s cold start on first sign-in. |
| `openPage(page, id, filter)` | Deep links, then clicks *Make changes on the page* — deep-linked cards open read-only. |
| `field(frame, caption)` | Scopes to the real `input`, not the read-only grid cell behind the card. |
| `newDocument(page, listId, cardId)` | Clicks New and waits for the navigation to actually land. |
| `linesGrid(frame)` | Picks the lines grid out of the **two** grids in the DOM, by marker column header. |
| `lineCell(frame, column, opts)` | Maps a column header's x-centre onto `gridcell` x-ranges. `{click:false}` reads without entering edit mode. |
| `readError(frame)` | Collects validation text from the several places BC puts it. |
| `dismissDialog(frame)` | `Escape`, repeatedly — dialog buttons resist pointer clicks, and dialogs stack. |

## Writing a probe

Keep boundary cases in a table, not in copied blocks, and let `?` mean *"genuinely exploring"*:

```js
const CASES = [
  { field: 'Line Discount %', value: '150', expect: 'reject' },
  { field: 'Unit Price Excl. VAT', value: '-100', expect: '?' },
];
```

Then confirm **every** outcome in SQL. The UI read-back is frequently empty, and page text is an
actively misleading oracle — see §9 of the Playwright instructions.

## Two rules worth repeating

1. `fill()` does not commit. Press `Tab`.
2. Prefer keyboard shortcuts (`F9` to post) over toolbar clicks — the sticky line toolbar eats
   pointer events, and three different force-click strategies all failed on it.

## Picking a target before you open a browser

```powershell
# 1. What changed lately?
git log --since="2 weeks ago" --numstat --pretty=format: -- src/Apps |
  Where-Object { $_ } | ForEach-Object { ,($_ -split "`t") } |
  Group-Object { ($_[2] -split '/')[0..3] -join '/' } |
  Sort-Object { -($_.Group | Measure-Object { [int]$_[0] + [int]$_[1] } -Sum).Sum }

# 2. Is there anything worth probing in it?
.\Find-TourTargets.ps1 -Path ..\..\..\src\Apps\W1\Sustainability\app

# 3. Is the app actually installed here?
Get-BcContainerAppInfo -containerName BCApps-Tours -tenantSpecificProperties |
  Where-Object IsInstalled | Select-Object Name

# 4. Is there any DATA to tour with?  <-- the gate that fails most often
#    See section 8 of exploratory-tours.instructions.md.
```

Skipping step 4 costs a session. In a stock CRONUS container the five highest-churn
apps all had zero rows in their master tables.

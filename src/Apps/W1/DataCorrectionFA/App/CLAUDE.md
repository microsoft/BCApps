# Troubleshoot FA Ledger Entries

This app detects and corrects rounding issues in Fixed Asset ledger entries. Some FA entries end up with amounts that have more decimal places than the currency's rounding precision allows (e.g., 1234.567 when precision is 0.01), which can cause downstream posting and reporting problems. The app scans for these entries, shows them to the user on the Fixed Asset Card via a notification, and lets them accept a rounded correction that writes directly back to the FA Ledger Entry table.

## Quick reference

| Item | Value |
|------|-------|
| ID range | 6090-6099 |
| Namespace | `Microsoft.FixedAssets.Repair` |
| Dependencies | None (base app + platform only) |
| App ID | `7961e9dc-a8e5-49b1-839b-3a78803a4cb8` |
| Object count | 1 table, 1 tableextension, 2 codeunits, 1 page, 10 permission objects |

## How it works

The app uses a **shadow table** pattern. Rather than flagging issues on the real FA Ledger Entry table, it copies problematic entries into its own staging table (`FA Ledg. Entry w. Issue`, table 6090). This avoids modifying production data during the detection phase and gives users a safe review step before any corrections happen.

**Detection** is handled by codeunit 6090 `FA Ledger Entries Scan`. It iterates FA Ledger Entries starting from a high-water mark stored on FA Setup (`LastEntryNo`), compares each entry's Amount to `Round(Amount, Currency."Amount Rounding Precision")`, and copies mismatched entries into the issues table. The scan is incremental -- it only looks at entries newer than the last scan, so repeated runs are cheap. The high-water mark advances to one past the last entry checked.

**Triggering** the scan is lazy and background-based. When a user opens a Fixed Asset Card, codeunit 6091 `FA Card Notifications` subscribes to `OnAfterGetCurrRecordEvent`. It checks a cooldown (7 days, stored as `Last time scanned` on FA Setup) and if enough time has passed, schedules the scan as a background task via `TaskScheduler.CreateTask` with a 1-second delay. This keeps the UI responsive -- the scan never blocks the page load. The notification only appears if the issues table already has uncorrected entries for that specific FA.

**Correction** happens on page 6090 `FA Ledger Entries Issues`. The user selects entries and clicks "Accept Selected". The page action directly modifies the real `FA Ledger Entry` record: it rounds the Amount, recalculates Debit/Credit amounts respecting the Correction flag, and marks the shadow entry as corrected. This is a permanent write to posted ledger entries -- there is no reversal mechanism.

## Structure

- **`src/tables/`** -- The shadow table for flagged entries and a tableextension on FA Setup for scan state (high-water mark, last scan timestamp).
- **`src/codeunits/`** -- Scanner that detects rounding issues, and notification handler that wires into the Fixed Asset Card page.
- **`src/pages/`** -- Review and correction page where users inspect flagged entries and accept fixes.
- **`Permissions/`** -- Standard permission scaffolding. Extends D365 AUTOMATION, BASIC ISV, BUS FULL ACCESS, BUS PREMIUM, FA EDIT, and FULL ACCESS sets. The layered sets (Objects/Read/Edit) follow the BC permission set pattern.

## Things to know

- **The app modifies posted ledger entries directly.** The "Accept Selected" action writes to `FA Ledger Entry` without creating correcting entries or journal lines. This is unusual in BC where posted entries are typically immutable. The design is intentional -- these are sub-penny rounding fixes, not business corrections.

- **The scan is incremental, not full-table.** `FASetup.LastEntryNo` acts as a checkpoint. If you need to re-scan previously checked entries (e.g., after changing currency rounding precision), you would need to reset this field manually.

- **The 7-day cooldown is hardcoded.** `GetCacheRefreshInterval()` returns a fixed 1-week duration. There is no setup field to configure this. The cooldown prevents the scan from being scheduled on every Fixed Asset Card open.

- **Scan runs as a background task, not inline.** `TaskScheduler.CreateTask` means the scan executes in a separate session. The notification on the FA Card shows results from the *previous* scan, not a live check. A user opening the card for the first time after install will not see a notification until after the background task completes and they revisit the card.

- **The Amount field on the issues table stores the already-rounded value, not the original.** `TransferFields` copies from FA Ledger Entry, then the page's `OnAfterGetRecord` recalculates the original amount display and rounding difference on the fly. The `OriginalAmount` and `Rounding` columns on the page are computed, not stored.

- **Debit/Credit recalculation respects the Correction flag.** When rounding the amount, the code checks both the sign of the amount and the `Correction` boolean to determine which side (Debit vs Credit) gets the value. This mirrors standard BC posting logic where correction entries flip the normal debit/credit assignment.

- **No events are published.** The app subscribes to the FA Card page event but does not expose any integration or business events of its own. There are no extension points for customizing the scan logic or correction behavior.

- **Permission set extensions grant RIMD on the shadow table to all major D365 entitlements.** This means any user with standard BC licensing can see and interact with the correction page. The page itself also declares inline `Permissions` for both the shadow table and the real FA Ledger Entry table (RIMD on both).

- **The `Commit()` calls in both codeunits are deliberate lock-release patterns.** The scan codeunit locks FA Setup to update the timestamp, then commits to release the lock before the potentially long-running scan loop. The notification codeunit does the same before scheduling the background task.

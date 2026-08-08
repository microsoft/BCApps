# Quality Management - Data Model

## Core Tables

### Inspection Document

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Inspection Header` | 20405 | One record per inspection. Tracks source document, item, lot, location, status, re-inspection chain. |
| `Qlty. Inspection Line` | 20406 | One record per template line (test/question). Stores result value, failure state, visibility. |

**Key relationships:**
```
Qlty. Inspection Header (No., Re-inspection No.)
    └── Qlty. Inspection Line (Inspection No., Re-inspection No., Line No.)
         └── Qlty. Inspection Template Line (via Template Code + Template Line No.)
              └── Qlty. Test (via Test Code on template line)
```

**Re-inspection chain:**
- Same `No.` across re-inspections
- `Re-inspection No.` increments (0 = original, 1 = first re-inspection, ...)
- `Most Recent Re-inspection = true` on the latest record only

**Status enum (`Qlty. Inspection Status`):** Open, Finished

### Configuration: Templates

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Inspection Template Hdr.` | ~20407 | Template header: code, description, sample size source, copy behavior |
| `Qlty. Inspection Template Line` | ~20408 | Template lines: test code, result options, visibility rules, finish-allowed rules |
| `Qlty. Test` | ~20409 | Reusable test definition: value type (numeric/text/boolean/lookup), case sensitivity |
| `Qlty. Test Lookup Value` | ~20410 | Valid lookup values for a test |

**Key relationships:**
```
Qlty. Inspection Template Hdr. (Code)
    └── Qlty. Inspection Template Line (Template Code, Line No.)
         └── Qlty. Test (Test Code)
              └── Qlty. Test Lookup Value (Test Code, Line No.)
```

### Configuration: Generation Rules

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Inspection Gen. Rule` | 20404 | Rule: source table, trigger type, filter expression, template code, sort order, schedule group |

**Rule matching:** Multiple rules can exist per source table. `Sort Order` determines priority (lower = evaluated first). First matching rule wins.

**Schedule Group:** Links rules to job queue entries for time-based (non-event) inspection creation.

### Configuration: Source Configuration

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Inspect. Source Config.` | ~20411 | Maps a source table to which fields to populate on the inspection (item no., quantity, lot, location, etc.) |
| `Qlty. Inspect. Src. Fld. Conf.` | ~20412 | Per-field mapping: source field → inspection header field |

### Configuration: Results

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Inspection Result` | ~20413 | Named result options (e.g. "Pass", "Fail", "N/A") |
| `Qlty. I. Result Condit. Conf.` | ~20414 | Conditional behavior when a result is selected: auto-disposition, failure state, item tracking block |

### Setup

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Management Setup` | ~20415 | Singleton. Number series, default behaviors, feature toggles |
| `Qlty. Management Role Center Cue` | ~20416 | Cue counts for role center activities page |

### Dispositions

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Disposition Buffer` | ~20417 | Temporary working record during disposition processing |
| `Qlty. Related Transfers Buffer` | ~20418 | Temporary buffer for related transfer order lookups |

### Workflow

| Table | ID | Purpose |
|---|---|---|
| `Qlty. Workflow Config. Value` | ~20419 | Configuration values for workflow responses |

## Table Extensions

These extend existing BC tables with Quality Management fields:

| Extension | Extended Table | Added Fields |
|---|---|---|
| `QltyApplicationAreaSetup.TableExt` | Application Area Setup | Quality Management application area flag |
| `QltyTransferHeader.TableExt` | Transfer Header | Inspection status, inspection no. |
| `QltyDirectTransHeader.TableExt` | Direct Trans. Header | Posted transfer inspection link |
| `QltyTransferReceiptHeader.TableExt` | Transfer Receipt Header | Inspection link |
| `QltyTransferShipmentHeader.TableExt` | Transfer Shipment Header | Inspection link |
| `QltyLotNoInformation.TableExt` | Lot No. Information | Inspection count/link |
| `QltySerialNoInformation.TableExt` | Serial No. Information | Inspection link |
| `QltyPackageNoInformation.TableExt` | Package No. Information | Inspection link |
| `QltyAvailInfoBuffer.TableExt` | Availability Info. Buffer | Quality hold flag |
| `QltyEntrySummary.TableExt` | Entry Summary | Quality hold quantities |
| `QltyRelatedTransfersBuffer.Table` | (new buffer) | Transfer documents related to an inspection |

## Key Enums

### Document
- `Qlty. Inspection Status`: Open, Finished
- `Qlty. Inspection Create Status`: Created, AlreadyExists, NoMatchingRules, Error
- `Qlty. Line Failure State`: (none), Failed, FailedWithComment

### Configuration
- `Qlty. Gen. Rule Intent`: Manual, Automatic, Scheduled
- `Qlty. Gen. Rule Act. Trigger`: (per-module trigger points)
- `Qlty. Test Value Type`: Numeric, Text, Boolean, Lookup, LargeText
- `Qlty. Result Category`: Pass, Fail, Inconclusive, NotApplicable
- `Qlty. Result Visibility`: Always, OnlyWhenSelected, Never
- `Qlty. Result Finish Allowed`: Always, OnlyWhenSelected, Never
- `Qlty. Insp. Selection Criteria`: Item, ItemVariant, ItemTracking

### Integration Triggers (one enum per integrated module)
- `Qlty. Purchase Order Trigger`: OnRelease, OnPost, OnReceive, ...
- `Qlty. Transfer Order Trigger`: OnShip, OnReceive, ...
- `Qlty. Assembly Trigger`: OnPost, ...
- `Qlty. Production Order Trigger`: OnOutput, OnConsumption, ...
- `Qlty. Whse. Receipt Trigger`: OnPost, ...
- `Qlty. Warehouse Trigger`: OnPost, ...
- `Qlty. Sales Return Trigger`: OnPost, ...

### Dispositions
- `Qlty. Disposition Action`: Transfer, WarehousePutAway, InternalPutAway, PurchaseReturn, NegativeAdjustment, ChangeTracking, Move, InternalMove
- `Qlty. Item Adj. Post Behavior`: PostImmediately, CreateDraft
- `Qlty. Quantity Behavior`: FullQuantity, SampleQuantity, UserDefined

### Setup
- `Qlty. Item Tracking Behavior`: None, BlockOnFail, AlwaysBlock
- `Qlty. Update Source Behavior`: Never, OnFinish, AlwaysPrompt
- `Qlty. Inspect. Creation Option`: Automatic, Manual, Both
- `Qlty. Add Picture Handling`: None, Prompt, Automatic

# AL module scoring and object types

## AL object types

When scanning `.al` files, identify the object type from the first line of each file.

| Object type | Relevance |
|-------------|-----------|
| `table`, `tableextension` | Data model -- fields, keys, relationships |
| `page`, `pageextension` | UI layer -- what users see and interact with |
| `codeunit` | Business logic -- procedures, events, processing |
| `report`, `reportextension` | Reporting and data processing |
| `enum`, `enumextension` | Value types and options |
| `interface` | Polymorphism contracts |
| `query` | Data retrieval definitions |
| `xmlport` | Data import/export |
| `permissionset`, `permissionsetextension` | Security model |

## Subfolder scoring criteria

Score each subfolder (directory containing `.al` files) on a 0-10 scale:

| Factor | Points | How to detect |
|--------|--------|---------------|
| 3+ tables or table extensions | +3 | Grep for `^table ` and `^tableextension ` in `.al` files |
| 3+ codeunits | +2 | Grep for `^codeunit ` in `.al` files |
| 3+ interfaces | +3 | Grep for `^interface ` in `.al` files  
| Event publishers present | +1 | Grep for `[IntegrationEvent]` or `[BusinessEvent]` |
| Event subscribers present | +1 | Grep for `[EventSubscriber]` |
| 10+ total AL objects | +2 | Count all `.al` files in the subfolder |
| Complex codeunits (10+ procedures) | +1 | Grep for `procedure ` count per codeunit file |
| Extension objects present | +1 | Grep for `^tableextension ` or `^pageextension ` |

## Score classification

| Category | Score | Documentation required |
|----------|-------|----------------------|
| MUST_DOCUMENT | 7+ | CLAUDE.md + relevant of data-model.md, business-logic.md, extensibility.md, or patterns.md |
| SHOULD_DOCUMENT | 4-6 | CLAUDE.md only |
| OPTIONAL | 1-3 | Skip -- documentation not required |

## Change-to-doc mapping (for updates)

When AL files change, map the object type to the affected documentation:

| Changed object type | Primary doc impact |
|--------------------|--------------------|
| `table`, `tableextension` | `data-model.md` |
| `enum`, `enumextension` | `data-model.md` |
| `codeunit` | `business-logic.md` (if event publisher/subscriber: also `extensibility.md`) |
| `page`, `pageextension` | `CLAUDE.md` (if API page: `business-logic.md`) |
| `report`, `reportextension` | `business-logic.md` |
| `interface` | `extensibility.md` (if strategy pattern: also `patterns.md`) |
| `query` | `business-logic.md` |
| `xmlport` | `business-logic.md` |
| `permissionset` | `CLAUDE.md` |

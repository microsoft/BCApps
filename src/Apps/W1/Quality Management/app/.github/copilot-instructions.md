# Quality Management App — Copilot Instructions

## What this app does

Microsoft Business Central extension (v29.0.0.0) that integrates quality inspection
routines, test plans, and quality specifications into production, inventory, purchasing,
and warehouse workflows. Object ID range: 20400-20600. No external dependencies.

## Project structure

```
app/        Main extension
test/       Test codeunits
Test Library/  Shared test utilities and data generators
```

## Before writing or modifying any code, read

| What you need | File |
|---|---|
| Architecture overview | `docs/architecture.md` |
| Tables and relationships | `docs/data-model.md` |
| AL naming conventions and code patterns | `docs/conventions.md` |
| Product features and key objects | `docs/features.md` |
| Testing setup and patterns | `docs/testing.md` |

## Working in a specific area?

Load the relevant component docs first:

| Area | File |
|---|---|
| Inspection document (Header/Lines, creation, status) | `src/Document/docs/CLAUDE.md` and `architecture.md` |
| Templates, generation rules, result conditions | `src/Configuration/docs/CLAUDE.md` and `architecture.md` |
| BC module integrations (Purchasing, Manufacturing, Warehouse...) | `src/Integration/docs/CLAUDE.md` |
| Post-inspection disposition actions | `src/Dispositions/docs/CLAUDE.md` |

## Key entry points

- **Creating an inspection:** `src/Document/QltyInspectionCreate.Codeunit.al` — `CreateInspectionWithVariant()`
- **Generation rule matching:** `src/Configuration/GenerationRule/QltyInspecGenRuleMgmt.Codeunit.al`
- **App setup/configuration:** `src/Setup/QltyManagementSetup.Table.al`
- **Disposition interface:** `src/Dispositions/QltyDisposition.Interface.al`

## How to reference docs in Copilot Chat

```
#file:docs/architecture.md how does inspection creation work?
#file:src/Document/docs/architecture.md explain the re-inspection chain
#file:docs/conventions.md what naming convention should I use for this codeunit?
```

## Dev workflow (compile → publish → test)

Always compile and publish both the app and test app before running tests.
See `Eng/Docs/al-workflow.md` and `Eng/Docs/al-testing.md` at the repo root.

```powershell
# Run all Quality Management tests
.\Eng\Core\Scripts\RunALTestFromEnlistment.ps1 -ApplicationName "Quality Management Tests" -CountryCode W1
```

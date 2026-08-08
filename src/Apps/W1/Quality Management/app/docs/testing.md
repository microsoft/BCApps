# Quality Management - Testing

## Test Projects

| Project | Path | Purpose |
|---|---|---|
| Test app | `test/` | Functional and unit tests |
| Test Library | `Test Library/` | Shared test utilities and data generators |

The Test Library app (`Quality Management Test Library`) is declared in `app.json` under `internalsVisibleTo`, giving it access to internal procedures.

## Running Tests

Use `Eng/Core/Scripts/RunALTestFromEnlistment.ps1`:

```powershell
# All Quality Management tests
.\RunALTestFromEnlistment.ps1 -ApplicationName "Quality Management Tests" -CountryCode W1

# Specific test codeunit
.\RunALTestFromEnlistment.ps1 -ApplicationName "Quality Management Tests" -CountryCode W1 -TestCodeunitId <id>

# Single test method
.\RunALTestFromEnlistment.ps1 -ApplicationName "Quality Management Tests" -CountryCode W1 -TestProcedureRange "<MethodName>"

# Unit tests only
.\RunALTestFromEnlistment.ps1 -ApplicationName "Quality Management Tests" -CountryCode W1 -TestType UnitTest
```

**Always compile and publish both the app and test app before running tests.** See `Eng/Docs/al-workflow.md`.

## Test Structure

### Known Test Codeunits (`test/src/`)

| File | Focus Area |
|---|---|
| `QltyTestsInsepctions.Codeunit.al` | Inspection creation, status transitions, re-inspection |
| `QltyTestsTraversal.Codeunit.al` | Source field traversal and mapping |
| `QltyTestsExpressions.Codeunit.al` | Expression evaluation in generation rules |
| `QltyTestProdOrderRouting.PageExt.al` | Production order routing integration |

### Test Library (`Test Library/src/`)

Provides shared generators and utility codeunits:

| Codeunit | Purpose |
|---|---|
| `QltyProdOrderGenerator` | Creates production orders for test setup |
| `QltyPurOrderGenerator` | Creates purchase orders for test setup |
| `QltyInspectionUtility` (implied) | Common inspection creation/assertion helpers |

## Testing Patterns

### Use Test Library Utilities

All tests should use `QltyInspectionUtility` from the Test Library for creating test inspections, rather than calling `QltyInspectionCreate` directly in every test. This ensures consistent setup and reduces duplication.

### Test Data Setup

Follow the standard BC test pattern:
1. Use `LibraryInventory`, `LibraryPurchase`, etc. for base BC test data
2. Use Quality Management Test Library utilities for QM-specific setup
3. Each test should be self-contained (create its own data, don't rely on existing demo data)

### Test Method Naming

```al
[Test]
procedure <FeatureArea>_<Scenario>_<ExpectedResult>()
```

Example: `CreateInspection_WithMatchingGenerationRule_CreatesInspectionDocument()`

### Snapshot Tests

The `.snapshots/` folder at the app root stores UI snapshot test baselines. Update snapshots when intentional UI changes are made.

## What to Test When Adding Features

When adding a new **disposition action:**
- Test that the disposition creates the correct BC document/journal
- Test quantity handling (full, sample, user-defined)
- Test failure cases (missing setup, insufficient inventory)

When adding a new **integration trigger:**
- Test that the correct generation rule is matched
- Test that inspection is created with correct source fields populated
- Test that the trigger does NOT fire when no matching rule exists

When adding **template/test features:**
- Test result evaluation (pass/fail/inconclusive logic)
- Test conditional configuration (result conditions triggering disposition or item tracking block)
- Test copy template behavior

When modifying **inspection creation logic:**
- Test `CreateInspectionWithVariant` with Record, RecordRef, and RecordId variants
- Test re-inspection chain creation
- Test all `QltyInspectionCreateStatus` return values

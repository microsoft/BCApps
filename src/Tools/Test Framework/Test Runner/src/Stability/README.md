# Test Stability Mode

Stability mode re-runs an existing AL test suite under one or more **presets** (individually or
combined) in order to surface flaky, order-dependent and data-dependent tests. Every test outcome
(both passes and failures) is captured — including the preset combination, seed, WorkDate,
execution order, error message and call stack — so a failure is easy to reproduce and troubleshoot.

It can be driven from the **UI** (the AL Test Tool page) and from **PowerShell / CI** (the Command
Line Test Tool page).

## Presets

Presets are expressed as `+`-separated CODE tokens. A single token string is one _combination_.

| Token | Effect |
| --- | --- |
| `BASELINE` | No preset (equivalent to an empty string). |
| `SEED-<n>` | Forces pseudo-random seed `<n>` in both `Any` and `Library - Random`, even when a test hardcodes its own seed (for example `LibraryRandom.SetSeed(1)`). |
| `WORKDATEFUTURE-<n>YEAR` | Shifts `WorkDate` `<n>` years into the future for the duration of each test method. |
| `WORKDATEFUTURE-<n>MONTH` | Shifts `WorkDate` `<n>` months into the future. |
| `ONEBYONE` | Runs each test method in isolation (reuses the existing `Stability Run` path). |
| `REVERSE-CODEUNITS` | Runs the test codeunits in reverse order. |
| `REVERSE-METHODS` | Runs the test methods within a codeunit in reverse order (most effective combined with `ONEBYONE`). |

Example combination: `SEED-2+WORKDATEFUTURE-1YEAR+REVERSE-METHODS`.

The combinations executed for a base suite are stored in the **Stability Run Configuration** table.
When a suite has no configuration yet, a default, editable set is created:

- `BASELINE`
- `SEED-1+WORKDATEFUTURE-1YEAR`
- `ONEBYONE`
- `SEED-2+WORKDATEFUTURE-2YEAR`
- `REVERSE-METHODS`

## How it works

For each enabled combination the orchestrator (`Stability Test Mgt`) clones the base suite into a
generated suite (`STB<lineno>`), numbering the cloned lines so the requested execution order is
realized purely through `Line No.` ordering. It then activates the combination in the single
instance `Stability Context`, forces the seed override where requested, and runs the generated
suite (isolated per method when `ONEBYONE` is set).

While a generated suite runs, `Stability Test Subscribers` hooks the `Test Runner - Mgt` integration
events:

- `OnBeforeTestMethodRun` — applies the WorkDate offset before every test method (coordinated with
  `ALTestRunner Reset Environment`, which restores WorkDate after each codeunit).
- `OnAfterTestMethodRun` — records the outcome of every method in the **Stability Run Result** table.

The subscribers are no-ops unless a stability run is active, so regular test runs are unaffected.

### Seed override

`Any` (codeunit 130500) and `Library - Random` (codeunit 130440) consult the single instance
`Any Seed Override` codeunit (in the `Any` app). When an override is active they use the override
seed instead of whatever seed the test passed, which is what makes `SEED-<n>` effective even for
tests that hardcode their seed. To make this reference available, the `Test Runner` app takes a
dependency on the `Any` app.

## Running from the UI

On the **AL Test Tool** page, use the **Stability** action group:

- **Run Stability Tests** — runs every enabled combination for the current suite and opens the
  results.
- **Stability Configuration** — review / edit the combinations for the current suite.
- **Stability Results** — browse the stored results (failures are highlighted; **Show Error**
  displays the full message and call stack).

## Running from PowerShell / CI

Use `build/scripts/StabilityTests/RunStabilityTestsInBcContainer.ps1`. It drives the Command Line
Test Tool page (130455) through BcContainerHelper's client context, sets the base suite, invokes the
**Run Stability Tests** action and writes the JSON produced by the run to a file:

```powershell
.\build\scripts\StabilityTests\RunStabilityTestsInBcContainer.ps1 `
    -ContainerName bcserver `
    -SuiteName 'MYSUITE' `
    -Credential $cred `
    -OutputPath .\stability-results.json
```

The JSON contains a per-method record for every combination and mirrors the shape of the existing
`unstable-tests.json` artifact, so it can be uploaded from CI. Wiring stability mode into a GitHub
workflow is intentionally left for a follow-up change.

Stability mode is complementary to the existing **Test Tolerance** feature: this tool _discovers_
instability, while tolerance _tolerates_ known-unstable tests.

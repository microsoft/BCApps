# Test Configuration (stability mode)

Stability mode re-runs an existing test suite under one or more **test configurations** to surface
flaky, order-dependent and data-dependent tests. When a test fails, the outcome of every test method
(which configuration, seed, WorkDate, order, error and call stack) is stored so it is easy to
troubleshoot.

It can be run from the **UI** (AL Test Tool) and from **PowerShell/CI** (Command Line Test Tool).

## Folder layout

- `Providers/` — the `ITest Configuration Provider` interface, the `Test Configuration Provider` enum and the built-in provider codeunits.
- `Configurations/` — the `Test Configuration` and `Test Configuration Line` tables and the pages used to edit them (list, card, lines part).
- `Run/` — the run engine: context, orchestrator (`Test Configuration Mgt`), runner subscribers, the result table and the results page.
- Top level — the page extensions on the AL Test Tool and Command Line Test Tool, and this README.

## Concepts

- **Test Configuration** (`Test Configuration` table) — a named, reusable set of changes to apply to a
  run. An empty configuration (no lines) applies nothing.
- **Provider** (`Test Configuration Line` + enum `Test Configuration Provider`) — one part of a
  configuration. Each line has a provider and provider-specific JSON settings. Adding a line is how a
  configuration is extended.
- **Context** (`Test Configuration Context`) — single-instance state that providers write their intent
  into and that the orchestrator and runner read while a generated suite runs. It is inactive during
  normal test runs, so the framework has no effect outside a stability run.

## Built-in providers

| Provider | Settings | Effect |
| --- | --- | --- |
| `Seed` | `{ "seed": 2 }` | Uses a different random seed. The seed is stored in `Configured Random Seed` (Any app) and applied by `Reset State Before Test Run` via the existing `SetSeed` methods, so a test that sets its own seed still wins. |
| `WorkDateFuture` | `{ "formula": "1Y" }` | Moves WorkDate into the future by the given date formula. Re-applied before every test method because the runner restores WorkDate after each codeunit. |
| `OneByOne` | none | Runs each test method in isolation (reuses the suite stability run behavior). |
| `ReverseCodeunits` | none | Runs the test codeunits in reverse order. |
| `ReverseMethods` | none | Runs the test methods within each codeunit in reverse order. |

Execution order is realized when the generated suite is cloned (the runner executes lines by ascending
line number), so the reverse providers need no change to the Test Runner itself.

## How a run works

1. `Test Configuration Mgt.RunTestConfigurations(BaseSuite)` creates the default configurations if none
   exist, then for every enabled configuration:
   - activates the context and asks each enabled provider to `Prepare` (write seed/WorkDate/order/isolation intent);
   - clones the base suite into a generated suite (`TCFG<n>`), honoring the requested order;
   - stores the seed in `Configured Random Seed` when a seed provider is used;
   - runs the generated suite (one-by-one or all at once).
2. `Test Configuration Runner` subscribes to `OnBeforeTestMethodRun` / `OnAfterTestMethodRun`, fans out
   to the active configuration's providers for per-method behavior, and records every outcome in
   `Test Configuration Run Result`.
3. Results are available on the **Test Configuration Run Results** page and as JSON (used by CI).

## Default configurations

- `BASELINE` — no changes.
- `SEED1-WD1Y` — seed 1 + WorkDate +1 year.
- `ONEBYONE` — each method in isolation.
- `SEED2-WD2Y` — seed 2 + WorkDate +2 years.
- `REVERSE-METH` — methods in reverse order.

These are editable: change them on the **Test Configurations** page, or add your own configuration and
providers.

## Extending

To add a new kind of change:

1. Implement interface `ITest Configuration Provider` in a new codeunit.
2. Add a value to enum `Test Configuration Provider` that maps to your codeunit.
3. Add a `Test Configuration Line` that uses the new provider (with any JSON settings it needs).

## Entry points

- **UI**: the **Stability** group on the AL Test Tool (Run stability tests, Test configurations,
  Stability results).
- **PowerShell**: `build/scripts/StabilityTests/RunStabilityTestsInBcContainer.ps1` drives the Command
  Line Test Tool and writes the results JSON. Wiring it into a GitHub workflow is intentionally out of
  scope for this change.

# Test Configuration (stability mode)

Stability mode re-runs an existing test suite under one or more **test configurations** to surface
flaky, order-dependent and data-dependent tests. It never creates extra suites: the base suite is run
in place under every enabled configuration, and the aggregated outcome is written back onto the base
suite's own test method lines. When a test fails under more than one configuration, the individual
error messages are concatenated into that line's error message, so results can be reviewed directly in
the normal AL Test Tool.

It can be run from the **UI** (AL Test Tool) and from **PowerShell/CI** (Command Line Test Tool).

## Folder layout

- `Providers/` — the `ITest Configuration Provider` interface, the `Test Configuration Provider` enum and the built-in provider codeunits.
- `Configurations/` — the `Test Configuration` and `Test Configuration Line` tables and the pages used to edit them (list, card, lines part).
- `Run/` — the run engine: context, orchestrator (`Test Configuration Mgt`) and runner subscribers.
- Top level — the page extensions on the AL Test Tool and Command Line Test Tool, and this README.

## Concepts

- **Test Configuration** (`Test Configuration` table) — a named, reusable set of changes to apply to a
  run. An empty configuration (no lines) applies nothing.
- **Provider** (`Test Configuration Line` + enum `Test Configuration Provider`) — one part of a
  configuration. Each line has a provider and provider-specific JSON settings (stored as a full-length
  BLOB, not truncated). Adding a line is how a configuration is extended.
- **Context** (`Test Configuration Context`) — single-instance state that providers write their intent
  into and that the orchestrator and runner read while the base suite runs. It is inactive during
  normal test runs, so the framework has no effect outside a stability run.

## Built-in providers

| Provider | Settings | Effect |
| --- | --- | --- |
| `Seed` | `{ "seed": 2 }` | Uses a different random seed. The seed is stored in `Configured Random Seed` (Any app). While stability mode is active, `Any` and `Library - Random` read it from their own `SetSeed`, so the configured seed wins even when a test reseeds in its own `Initialize`. |
| `WorkDateFuture` | `{ "formula": "<1Y>" }` | Moves WorkDate into the future by the given date formula. Re-applied before every test method because the runner restores WorkDate after each codeunit. |
| `OneByOne` | none | Runs each test method on its own so its setup runs again for that method only (reuses the suite stability run behavior). |
| `ReverseOrder` | none | Runs the suite in reverse order in a normal, shared-state run. |

Execution order is realized by handing the base suite's lines to the test runner from the last to the
first (the runner honors that for the codeunit sequence), so the reverse provider needs no change to
the Test Runner itself and no extra suite. Reverse runs are **not** isolated — all tests run and share
state, only the order changes. One-by-one is the isolated mode, where each method's setup runs again.

## Seed and stability state

`Configured Random Seed` (Any app) is a passive single-instance store that also tracks whether
stability mode is active. It is honored in two complementary places:

- `Any` and `Library - Random` read it from their own `SetSeed`: while stability mode is active and a
  seed is set, they use the configured seed instead of the passed value, so the configured seed wins
  even when a test reseeds inside its own `Initialize` (which runs after the pre-test reset);
- `Reset State Before Test Run` checks the state **before every test method**: while stability mode is
  active it seeds both `Library - Random` and `Any` deterministically (with the configuration's seed,
  or `1` when the configuration sets none) so tests that never reseed still start from a known state and
  one configuration cannot leak randomness into the next; once stability mode is exited it falls back to
  the normal behavior (`Library - Random` seed `1`), so a stability run cannot affect later normal runs.

The orchestrator enters stability mode at the start of a run and exits it at the end. **Reset stability
mode** (an action on both tool pages, `Test Configuration Mgt.ResetStabilityMode`) is the safe way to
leave stability mode at any time: it exits stability mode, clears the stored seed, turns off the
isolation flag and clears the results on the base suite using trigger-free writes.

## How a run works

1. `Test Configuration Mgt.RunTestConfigurations(BaseSuite)` creates the default configurations if none
   exist, **validates every enabled configuration's settings up front** (for example that a WorkDate
   formula parses) so bad settings error before stability mode is entered and cannot leak state, enters
   stability mode, then for each enabled configuration in turn:
   - clears the previous configuration's results so the run starts from a clean suite;
   - activates the context and asks each enabled provider to `Prepare` (write seed/WorkDate/order/isolation intent);
   - stores the seed in `Configured Random Seed` when a seed provider is used (or clears it);
   - runs the **base suite** in place, in the requested order and isolation;
   - captures every failing method's error and call stack, tagged with the configuration code, and keeps
     a per-configuration summary in memory.
   The run **stops as soon as a configuration fails**, leaving the failing state on the suite for
   troubleshooting; the remaining configurations are not run.
2. `Test Configuration Runner` subscribes to `OnBeforeTestMethodRun` / `OnAfterTestMethodRun` and fans
   out to the active configuration's providers for per-method behavior (for example the WorkDate shift).
3. After the run stops (all configurations passed, or one failed), the aggregated outcome is written back
   onto the base suite's test method lines (failures concatenated per line). The results are also returned
   as JSON for CI, including a `stoppedEarly` flag and a `configurations` array summarizing each
   configuration that ran.

## Default configurations

- `BASELINE` — no changes.
- `SEED1-WD1Y` — seed 1 + WorkDate +1 year.
- `ONEBYONE` — each method on its own (setup re-runs per method).
- `SEED2-WD2Y` — seed 2 + WorkDate +2 years.
- `REVERSE` — the whole suite in reverse order.

These are editable: change them on the **Test Configurations** page, or add your own configuration and
providers.

## Extending

To add a new kind of change:

1. Implement interface `ITest Configuration Provider` in a new codeunit.
2. Add a value to enum `Test Configuration Provider` that maps to your codeunit.
3. Add a `Test Configuration Line` that uses the new provider (with any JSON settings it needs).

## Entry points

- **UI**: the **Stability** group on the AL Test Tool (Run stability tests, Test configurations, Reset
  stability mode). Results appear on the normal test lines after a run.
- **PowerShell**: `build/scripts/StabilityTests/RunStabilityTestsInBcContainer.ps1` drives the Command
  Line Test Tool and writes the results JSON. Wiring it into a GitHub workflow is intentionally out of
  scope for this change.

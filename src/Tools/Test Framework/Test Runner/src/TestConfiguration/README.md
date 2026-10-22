# Test configuration (stability mode)

Stability mode generates ordinary test suites from a parent suite and runs them sequentially.
Results stay on the generated suites; generation and execution do not change the parent's lines
or results. Initial PowerShell setup still uses the existing source-suite setup behavior.

## Configuration

The public `Test Configuration` table is keyed by **Test Suite + Code**. Each row contains all settings:

| Setting | Behavior |
| --- | --- |
| Enabled | Includes the configuration in generation. |
| Use Random Seed / Random Seed | Initializes Any and, when installed, Library - Random with the configured seed, including zero. Explicit seed/Init calls inside tests still win. |
| WorkDate Offset | A date formula such as `<1Y>` or `<2Y>`, applied relative to the initial WorkDate before each method. Blank means no shift. |
| One By One | Generates one codeunit header plus one method/expanded-input line per block. |
| Reverse Order | Reverses source codeunit blocks, retaining method order within each block. |

Settings can be combined in one row. There are no provider lines or automatic Cartesian products.
For example, reversing and splitting `A(1,2), B(3,4)` produces `B(3), B(4), A(1), A(2)`.
The chosen test runner and its isolation semantics are preserved.

Create configurations through AL or the **Test Configurations** page. **Create default configurations**
explicitly creates BASELINE, SEED1-WD1Y, ONEBYONE, SEED2-WD2Y and REVERSE for an unconfigured
parent. It does not overwrite existing configurations. Starting a run with no configurations, or
with all configurations disabled, raises an error instead of silently creating defaults.

## UI

1. Select the parent in **AL Test Tool** and open **Test Configurations**.
2. Configure the desired modes, or explicitly create the starter configurations.
3. **Run All** replaces every generated suite belonging to the parent, including outputs whose
   configuration was deleted or disabled, and runs the new suites sequentially.
4. **Run Configuration** replaces only the selected parent/configuration pair.
5. Open **Generated Suites** to inspect results, **Open Suite**, or **Run Suite** without regeneration.

Generated names use `S-00000001` and increment without overwriting other suites. The read-only
**Created From Suite** and **Configuration** fields identify their owner and settings.
Generated suites cannot start another stability generation.

Ordinary execution uses the saved lines and the current runtime settings of the assigned configuration.
Changing One By One or Reverse Order takes effect only on regeneration. Deleting or renaming an
assigned configuration makes an ordinary run of the old generated suite fail; full regeneration removes
that old suite. No configuration-record identity tracking is performed.

**Reset Stability Mode** resets active runtime state and libraries, preserving suite associations,
layout and results. **Clear Results** separately clears errors, timing and results without changing Run flags.

## AL API

```al
// Explicit setup, not a fallback performed by generation.
TestConfigurationMgt.EnsureDefaultConfigurations('DEFAULT');

// Generate only, saving the complete list before execution.
SuiteNames := TestConfigurationMgt.GenerateStabilitySuites('DEFAULT');
foreach SuiteName in SuiteNames do
    TestConfigurationMgt.RunSuite(SuiteName);
```

`GenerateStabilitySuites(Parent, ConfigurationCode)` replaces just one configuration's suite.
`RunTestConfigurations(Parent)` combines generation and sequential execution for the UI.

The session-local `Test Configuration Context` retains the current record, loaded before test
permissions are applied. Runtime providers implement `ITest Configuration Provider` and are
registered through the extensible `Test Configuration Provider` enum. Providers initialize on
suite entry, apply per-method settings and reset on normal completion. Layout is generated separately.
Native test-handler support and special recovery from fatal runtime errors are deferred.

## PowerShell

Use the existing NAV `Eng\Core\Tools\ALTestRunner\ALTestRunner.psm1` module:

```powershell
Run-AlTests -ServiceUrl $serviceUrl -TestSuite DEFAULT -StabilityMode `
    -ResultsFilePath 'C:\TestResults\TestResults.xml'
```

Configurations must already exist in AL. The script performs normal initial source setup once,
invokes the generation-only action, saves the returned suite codes, and runs those suites without
repopulating them. The legacy `-StabilityRun` option is unchanged; it is not the new `-StabilityMode`
switch, and generated suites have the legacy flag disabled.

Standard xUnit files and per-suite logs are written under `C:\TestResults\StabilityRun`.
Names combine parent, configuration and generated suite code, keeping only letters and digits in
the stem, for example `DEFAULTBASELINES00000001.xml` and `.log`. Collisions overwrite.
Logs use the existing NAV logger and contain suite identification and the complete returned
result objects. Normal execution/retry logging remains unchanged. `-SaveResultFile $false` disables
xUnit output, not the per-suite logs. Results remain in memory for existing final reporting.

Test failures do not stop the next suite. System errors and retries follow the existing runner;
they may stop execution. There is no new recovery, partial-run summary or report-identity framework.

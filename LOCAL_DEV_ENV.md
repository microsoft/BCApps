# How to create a local development environment

## Prerequisites
- Install and run [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/). Make sure it is running Windows containers.
- Install [BcContainerHelper PS module](https://www.powershellgallery.com/packages/BcContainerHelper) (latest available version).
`Install-Module BCContainerHelper -AllowPrerelease` would do.

[Here](https://github.com/microsoft/navcontainerhelper) you can read more about *BcContainerHelper*.

## Create a development environment

The development environment is a docker container running Business Central locally.
In order to create it, simply run `.\build\scripts\DevEnv\NewDevEnv.ps1` with the desired parameters.


### Example - Set up a container and VSCode
```
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'
```

Running the above will
* Create a new container (if one doesn't already exist)
* Set up launch.jsons and settings.jsons in your VSCode


### Example - Set up a container, VSCode and publish a new system app
```
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\App'
```
Running the above will
* Create a new container (if one doesn't already exist)
* Set up launch.jsons and settings.jsons in your VSCode
* Compile and publish a new system app using your local codebase

### Example - Set up a container, VSCode and publish a new system app and tests
```
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\*'
```
Running the above will
* Create a new container (if one doesn't already exist)
* Set up launch.jsons and settings.jsons in your VSCode
* Compile and publish all AL apps that match `.\src\System Application\`

## API test authentication

`Library - Graph Mgt` uses the Microsoft test authentication provider by default.
API tests do not need a `SetAuthenticationProvider` call, a password file, or a
Key Vault password lookup. Container and test-session credentials are still
required to provision and connect to the NST; they are not handed to API requests.

On-premises **NavUserPassword** requests use the current user's web service key.
The standard AL test runner prepares a missing key in `OnBeforeTestRun`, whose
transaction finishes before the test method starts. This also supports read-only
API tests using `AutoCommit` or `AutoRollback`, which start a write transaction
even without fixture writes. Preparation applies to the current test user when
`Tests-TestLibraries` is installed, including non-API tests; it does not select
credentials for individual requests or rotate an existing key. No key is
provisioned by the pipeline or extension installation.

An existing valid key is read on each request without a credential cache. If no
key exists, a read-only caller raises an internal isolated event. Its subscriber
locks and rechecks the current user, then creates a key with a 24-hour expiry.
The platform commits this separate key transaction before returning; the provider
then rereads the key rather than trusting an event output that could survive a
rollback. The lock and recheck prevent competing test sessions for the same
tenant/user from replacing each other's newly created key.

If the key is missing and the caller has uncommitted writes, authentication fails
explicitly **without committing fixture data**. Initialize authentication before
fixture writes or use the test's existing committed fixture boundary; do not add
a request-side commit to hide an incomplete fixture. Existing valid keys remain
read-only even when the caller has writes. Expired keys fail explicitly rather
than silently rotating credentials used by other clients.

Isolated events have different semantics during extension install/upgrade; API
test requests belong in normal test execution, not installation/upgrade triggers.
First-use visibility to the separate HTTP session, rollback, and concurrent first
use still require target-server validation; source-contract tests alone do not
establish those runtime results.

Windows, SaaS, and other authentication modes retain ambient authentication.
Custom enum providers and `SetAuthenticationProvider` remain supported. Explicit
`Enum::"API Test Authentication"::None` still opts out, including on the first
request. The final `OnAfterInitializeWebRequestWithURL` event still runs after the
provider. Event-only custom authentication that must avoid default key acquisition
should explicitly select `None` before creating the request.
This request-level opt-out does not undo the standard runner's test-user key
preparation. Custom runners can prepare the key before starting test transactions,
or use the read-only first-request path.

API fixture initializers reapply the existing test-license-compatible work date
(November 15 of the current year) before creating date-sensitive data, including
after an initialization guard has previously been set. This controls fixture
dates, not license enforcement or the authentication key's real-time expiry.

## GDL development (layers and views)

Anything that ships in multiple localizations (the **Base Application** and the application layers) lives under `src/Layers`, organized by country/region. Each country's app is composed by overlapping multiple **layers** in order: a `W1` ("worldwide") base, optional regional layers, and the country layer. For example, the `US` app is composed of `W1` + `NA` + `US`, where each layer either introduces new objects or replaces objects from a base layer.

Because the source is split across layers, you don't edit the layer folders directly. Instead, you compose the layers into a single, unified **view** that can be opened in VSCode as a regular AL project. A view is materialized under `src/Views/<CountryCode>` (this folder is git-ignored). The view uses symbolic links/junctions back into `src/Layers`, so the file you see in the view is the same file as in the layer it originates from.

> **Prerequisite:** Creating a view requires permission to create symbolic links on Windows. Either enable [Developer Mode](https://learn.microsoft.com/windows/apps/get-started/enable-your-device-for-development) or run your shell as Administrator.

All commands are provided by the `GDLDevelopment` PowerShell module. Import it once per session:

```powershell
Import-Module .\build\scripts\GDLDevelopment\GDLDevelopment.psm1
```

### Create a view

```powershell
New-GDLView -CountryCode US -skipSetupDevelopmentSettings
```

This composes the layers for the given country/region into `src/Views/US`. Open the resulting `src/Views/US` folder in VSCode and develop as you would in any AL project.

> **Note:** Automatic configuration of the VSCode `launch.json`/`settings.json` (i.e. running `New-GDLView` without `-skipSetupDevelopmentSettings`) is currently broken and will be fixed later. For now, pass `-skipSetupDevelopmentSettings` and configure the projects manually if needed.

### Synchronize your changes back to the layers

Files you edit in the view update the underlying layer file directly (they are linked). New files you add in the view are real files that must be copied into the correct layer. Run:

```powershell
Sync-GDLView -CountryCode US
```

This copies any new files from the view into the layer, recreates the view (creating the appropriate links), and leaves the view in a clean, synchronized state. To also propagate files you **moved or deleted** in the view back to the layers, use:

```powershell
Sync-GDLView -CountryCode US -SyncMovesAndDeletes
```

When a moved/deleted file exists in more than one layer, you'll be prompted to choose how the change should be applied.

### Remove a view

When you're done, remove the view to clean up the links:

```powershell
Remove-GDLView -CountryCode US
```

`Remove-GDLView` first verifies the view has no unsynchronized changes. To discard any unsynchronized files and remove the view anyway, add `-Force`. To remove every view at once, use `Remove-AllGDLViews` (optionally with `-Force`).

## Miapp (propagating changes across layers)

When you change a file in the `W1` (worldwide) base layer, the same change often needs to be applied to the country-specific layers that build on top of it. **Miapp** (Micro Application Integration) is a PowerShell tool that automates this propagation: it finds the files you changed in `W1` and merges them into each dependent country layer (`AT`, `AU`, `BE`, `DE`, `US`, ...), resolving conflicts automatically or with a merge tool.

Import the module and run `Invoke-Miapp` from the repository root:

```powershell
Import-Module .\build\scripts\Miapp\MicroApp.psm1
Invoke-Miapp
```

`Invoke-Miapp` validates the repository state, discovers the files that need integrating, merges them into every dependent layer, and stages the result. Commonly used options:

```powershell
# Only propagate to a single country layer
Invoke-Miapp -Country DE

# Only propagate files matching a regex
Invoke-Miapp -FileNameFilter '\.al$'

# Resolve conflicts automatically, preferring the W1 (source) version
Invoke-Miapp -AutoResolve theirs

# Prompt before propagating each file
Invoke-Miapp -Interactive
```

> **Tip:** Run Miapp after committing your `W1` changes — it compares against the base branch (`origin/HEAD`, typically `main`) to determine what to propagate.

For the full list of parameters, the integration workflow, configuration, and troubleshooting, see the [Miapp README](build/scripts/Miapp/README.md).
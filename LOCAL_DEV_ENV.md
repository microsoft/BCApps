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
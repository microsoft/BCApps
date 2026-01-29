# Agent Instructions for BCApps Development

This document provides instructions for AI agents working with the BCApps repository.

## Mandatory Workflow

When working on code changes in this repository, you **MUST** always follow this workflow:

1. **Set up the environment** - Create a BC container if one doesn't exist
2. **Compile the code** - Verify that the AL code compiles without errors
3. **Build and publish the app** - Create the .app package and publish to the container
4. **Run tests** - Execute relevant tests to verify the changes work correctly

**Never submit changes without completing all four steps.**

## Prerequisites

Before you can compile and test, ensure:
- Docker Desktop is installed and running Windows containers
- BcContainerHelper PowerShell module is installed

To install BcContainerHelper:
```powershell
Install-Module BCContainerHelper -AllowPrerelease
```

## Step 1: Set Up Container

Create a development container using the existing script:

```powershell
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'
```

This will:
- Create a new BC container (if one doesn't already exist)
- Set up launch.json and settings.json in VSCode

## Step 2: Compile and Publish Apps

After making code changes, compile and publish:

### Compile a Single App
```powershell
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\App' -RebuildApps
```

### Compile All Apps in a Project
```powershell
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\*' -RebuildApps
```

### Compile Using AL-Go Project
```powershell
.\build.ps1 -ALGoProject "System Application"
```

### Key Parameters
- `-ContainerName` - Name of the BC container to use
- `-ProjectPaths` - Paths to AL projects to compile (supports wildcards)
- `-RebuildApps` - Forces recompilation even if the app already exists
- `-SkipVsCodeSetup` - Skip VSCode configuration (useful for CI)

## Step 3: Run Tests

After apps are published, run tests using BcContainerHelper:

```powershell
# Import required module
Import-Module BcContainerHelper

# Get credentials (use same as container setup)
$credential = Get-Credential

# Run all tests
Run-TestsInBcContainer -containerName "BCApps-Dev" -credential $credential -testSuite "DEFAULT"

# Run specific test codeunit
Run-TestsInBcContainer -containerName "BCApps-Dev" -credential $credential -testCodeunit <CodeunitId>
```

### Test Types
- `UnitTest` - Unit tests that don't require external dependencies
- `IntegrationTest` - Tests that require integration with BC
- `Uncategorized` - Tests without a specific category

### Test Isolation
- Tests with `DisableTestIsolation` use Test Runner codeunit `130451`
- Standard tests use Test Runner codeunit `130450` with codeunit isolation

## Complete Workflow Example

For every code change, execute this sequence:

```powershell
# 1. Set up container (only needed once, skip if already exists)
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'

# 2. Compile and publish your app changes
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '<path-to-your-app>' -RebuildApps -SkipVsCodeSetup

# 3. Compile and publish test app
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '<path-to-test-app>' -RebuildApps -SkipVsCodeSetup

# 4. Run tests
$credential = Get-Credential
Run-TestsInBcContainer -containerName "BCApps-Dev" -credential $credential -testSuite "DEFAULT"
```

## Important Rules

1. **Always use the same container name** consistently across all commands
2. **Always use `-RebuildApps`** when you've made changes to ensure fresh compilation
3. **Check compilation output** for any errors before proceeding to tests
4. **If tests fail**, investigate and fix before considering the change complete
5. **Do not skip any step** - all four steps are mandatory for every change


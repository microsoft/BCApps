# BCApps Repository: Copilot Coding Agent Instructions

## Repository Overview

BCApps contains the source code for **Microsoft Dynamics 365 Business Central applications**, including the System Application, Business Foundation, and Developer Tools. This is a **large-scale enterprise AL (Application Language) codebase** with 3,290+ AL files, 45MB of source code, developed using Microsoft's AL-Go framework.

**Key Facts:**
- **Language**: AL (Application Language) for Business Central development
- **Framework**: AL-Go for GitHub (Microsoft's AL development automation)
- **Target**: Business Central on-premises and SaaS applications
- **Size**: ~3,290 AL files, 356 JSON configs, 61 PowerShell scripts
- **Platform**: Windows-based (requires Windows containers for builds)

## Critical Build Requirements & Environment Setup

### Prerequisites (ALWAYS Required)
1. **Windows Environment**: This is a Windows-only development stack
2. **Docker Desktop**: Must be running **Windows containers** (not Linux)
3. **PowerShell**: Use PowerShell (not pwsh) for build scripts
4. **BCContainerHelper Module**: Auto-installed by build scripts if missing

### Build Process - AL-Go Based System

**IMPORTANT**: This repository uses AL-Go (Microsoft's AL development framework), NOT standard npm/dotnet builds.

#### Main Build Commands:
```powershell
# Build a specific AL-Go project (ALWAYS use PowerShell, not bash)
.\build.ps1 -ALGoProject "System Application" -AutoFill

# Available AL-Go projects (in build/projects/):
- "System Application"
- "System Application Tests" 
- "Business Foundation Tests"
- "Performance Toolkit Tests"
- "Test Stability Tools"
- "Apps (W1)"
- "System Application Modules"
```

#### Development Environment Setup:
```powershell
# Create local development container (requires Docker Desktop with Windows containers)
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'

# Build and publish System Application
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\App'

# Build all System Application components
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\*'
```

#### Common Build Issues & Solutions:
- **Docker not running Windows containers**: Switch Docker to Windows containers mode
- **BCContainerHelper missing**: Build script auto-installs, but may need admin rights
- **Container creation fails**: Ensure Docker Desktop is running and Windows containers are enabled
- **PowerShell execution policy**: May need `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`

### Testing & Validation

#### Running Tests:
```powershell
# Tests are built as separate AL-Go projects
.\build.ps1 -ALGoProject "System Application Tests" -AutoFill
.\build.ps1 -ALGoProject "Business Foundation Tests" -AutoFill
```

#### Code Analysis Rules:
- **Ruleset Location**: `src/rulesets/ruleset.json`
- **Analyzers Enabled**: CodeCop, AppSourceCop, UICop, PerTenantExtensionCop
- **Strict Validation**: All rules treated as errors in CI/CD

## Project Structure & Architecture

### Source Organization:
```
src/
├── System Application/           # Core Business Central modules
│   ├── App/                     # Main system application (app.json: 63ca2fa4-4f03-4f2b-a480-172fef340d3f)
│   ├── Test/                    # Unit tests for system modules
│   └── Test Library/            # Test framework utilities
├── Business Foundation/         # Business logic foundation modules  
├── Apps/                        # 1st party applications (e.g., Shopify connector)
│   └── W1/                      # World-wide (W1) applications
├── Tools/                       # Developer tools
│   ├── AI Test Toolkit/         # AI testing utilities
│   ├── Performance Toolkit/     # Performance testing tools
│   └── Test Framework/          # Core testing framework
└── rulesets/                    # Code analysis rules (CodeCop, UICop, etc.)
```

### Build Infrastructure:
```
build/
├── projects/                    # AL-Go project definitions (one per buildable unit)
│   ├── System Application/      # Main system app build config
│   ├── System Application Tests/ # Test build config
│   └── [Other Projects]/        # Each has .AL-Go/settings.json
├── scripts/                     # Build automation scripts
│   ├── DevEnv/                  # Development environment setup
│   └── [Various .psm1 modules]  # PowerShell helper modules
└── Packages.json               # Package dependencies
```

### GitHub Actions & CI/CD:
```
.github/
├── workflows/
│   ├── CICD.yaml               # Main CI/CD pipeline
│   ├── PullRequestHandler.yaml # PR validation
│   └── _BuildALGoProject.yaml  # Reusable AL-Go build workflow
├── AL-Go-Settings.json         # Global AL-Go configuration
└── PULL_REQUEST_TEMPLATE.md    # Requires linked approved GitHub issue
```

### Critical Configuration Files:
- **AL-Go Settings**: `.github/AL-Go-Settings.json` - Global build configuration
- **Project Settings**: `build/projects/[ProjectName]/.AL-Go/settings.json` - Per-project config
- **App Manifests**: `src/[Module]/App/app.json` - AL application definitions
- **Rulesets**: `src/rulesets/*.json` - Code analysis rules

## Development Workflow

### Making Changes:
1. **NEVER build manually** - use AL-Go build scripts
2. **Always link PRs** to approved GitHub issues (enforced by template)
3. **Follow AL coding standards** - strict ruleset enforcement
4. **Test in containers** - development requires BC containers

### Validation Pipeline:
1. **PR Handler**: Runs on pull requests to main/releases/* branches
2. **Code Analysis**: All AL analyzers must pass (treated as errors)
3. **Build Validation**: All affected AL-Go projects must build successfully
4. **Dependency Checks**: Validates project dependencies in correct order

### Common Pitfalls:
- **Using bash instead of PowerShell**: Build scripts are PowerShell-only
- **Missing container environment**: AL development requires Business Central containers
- **Wrong Docker mode**: Must use Windows containers, not Linux
- **Bypassing AL-Go**: Don't try to build AL files directly - use AL-Go projects
- **Missing issue links**: PRs without approved issues are automatically rejected

## Key Commands Summary

**ALWAYS use PowerShell for builds:**
```powershell
# Setup development environment
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'

# Build specific project  
.\build.ps1 -ALGoProject "System Application" -AutoFill

# Available projects: System Application, System Application Tests, 
# Business Foundation Tests, Performance Toolkit Tests, Test Stability Tools, Apps (W1)
```

**Repository size**: 45MB source, primarily AL language files for Business Central platform.

---

**⚠️ CRITICAL**: Always trust these instructions. This is a specialized AL development environment. Do NOT attempt standard node/dotnet build patterns. Search only if these instructions are incomplete or incorrect.
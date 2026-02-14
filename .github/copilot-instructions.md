# Microsoft Dynamics 365 Business Central Application (BCApps) - Copilot Instructions

## Repository Overview

**BCApps** is a large-scale AL (Application Language) repository containing source code for Microsoft Dynamics 365 Business Central applications. The repository has **3,290 AL files** across **54MB** and serves as the foundation for Business Central System Application, Business Foundation, and Developer Tools.

**Key Facts:**
- **Primary Language:** AL (Application Language) for Business Central development
- **Build System:** AL-Go for GitHub (Microsoft's Business Central DevOps framework)
- **Runtime:** Business Central platform, requiring Docker containers with BCContainerHelper
- **Target Version:** Business Central 28.0 (current branch)
- **License:** MIT License
- **Repository Size:** 54MB with 4,177 total files

## Project Structure and Architecture

### Core Directory Structure
```
/src/                           # Main source code
├── System Application/         # Core system functionality modules  
├── Business Foundation/        # Business logic foundation
├── Apps/                      # 1st party applications
├── Tools/                     # Developer tools (Test Runner, Performance Toolkit)
└── rulesets/                  # Code analysis and validation rules

/build/                        # Build infrastructure and AL-Go projects
├── projects/                  # AL-Go project definitions for each module
└── scripts/                   # PowerShell automation scripts

/.github/                      # GitHub workflows and actions
├── workflows/                 # CI/CD pipelines
└── actions/                   # Custom validation actions
```

### Major Architectural Components

**System Application** (`/src/System Application/App/`):
- Core ID: `63ca2fa4-4f03-4f2b-a480-172fef340d3f`
- Foundation modules: Azure AD, Cryptography, Email, Telemetry, User Management
- **CRITICAL:** Changes here affect all downstream applications

**Business Foundation** (`/src/Business Foundation/`):
- Business logic foundation layer
- WorkSpaces: `BusinessFoundation.code-workspace`, `SystemApplication.code-workspace`

**AL-Go Projects** (`/build/projects/`):
- "System Application" - Main system app
- "System Application Tests" - Test suite
- "Business Foundation Tests" - BF validation
- "Performance Toolkit Tests" - Performance validation
- "Test Stability Tools" - Test infrastructure

## Build System and Validation

### Prerequisites (CRITICAL - ALWAYS INSTALL FIRST)
**ALWAYS install BCContainerHelper PowerShell module before any build operations:**
```powershell
Install-Module BCContainerHelper -Scope CurrentUser -AllowPrerelease -Force
```

**Runtime Requirements:**
- PowerShell 7.4.11+ (available in repository environment)
- Docker Desktop (Windows containers mode for local development)
- .NET 8.0.119+ (available)
- Node.js 20.19.5+ (available)

### Primary Build Commands

**Local Development Environment Setup:**
```powershell
# ALWAYS run from repository root
cd /path/to/BCApps

# Create new development container with System Application
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\App'

# Build specific AL-Go project (alternative approach)
.\build.ps1 -ALGoProject "System Application" -AutoFill
```

**Validation and Testing:**
```powershell
# Run repository tests (Pester-based)
.\build\scripts\tests\runTests.ps1

# Validate preprocessor symbols (critical validation)
.\.github\actions\TestPreprocessorSymbols\action.ps1
```

### Code Analysis and Linting

**Ruleset Configuration:** `/src/rulesets/ruleset.json`
- **CodeCop:** AL code style validation
- **AppSourceCop:** AppSource marketplace compliance  
- **PTECop:** Per-tenant extension compliance
- **UICop:** UI/UX guidelines validation
- **Action:** All rules set to "Error" level - failures block builds

**CRITICAL Validation Steps:**
1. **Preprocessor Symbol Validation** - Validates `#if CLEAN##` patterns
2. **AL Compilation** - Business Central AL compiler validation
3. **Dependency Analysis** - Project dependency graph validation

### CI/CD Pipeline Understanding

**Main Workflows:**
- **CICD.yaml** - Main/release branch builds (Windows 2025 runners)
- **PullRequestHandler.yaml** - PR validation builds
- **VerifyAppChanges.yaml** - Validates AL file changes
- **WorkitemValidation.yaml** - Ensures PRs link to approved issues

**Build Triggers:**
- Push to `main`, `releases/*` branches
- Pull requests to `main`, `releases/*`, `features/*`
- **Full builds triggered by:** `build/*`, `src/rulesets/*`, workflow changes

**Quality Gates:**
- All status checks must pass
- Code owner approval required
- All conversations must be resolved
- Work item linkage validation

## Development Guidelines

### Making Code Changes

**ALWAYS Follow This Sequence:**
1. **Verify issue approval** - PR must link to approved GitHub issue
2. **Choose minimal scope** - Only modify necessary files
3. **Identify target AL-Go project:**
   - System Application changes: `/src/System Application/App/`
   - Business Foundation: `/src/Business Foundation/`
   - Developer Tools: `/src/Tools/`
   - Apps: `/src/Apps/`
4. **Validate locally (if possible):**
   ```powershell
   # Test preprocessor symbols (may fail in non-Windows environments)
   .\.github\actions\TestPreprocessorSymbols\action.ps1
   
   # Run repository tests
   .\build\scripts\tests\runTests.ps1
   
   # Import helper functions for path validation
   Import-Module './build/scripts/EnlistmentHelperFunctions.psm1'
   ```
5. **Review related app.json files** for dependency impacts
6. **Test in container** if modifying System Application (Windows required)

**File Modification Guidelines:**
- **System Application modules:** Each subdirectory in `/src/System Application/App/` is a distinct module
- **App.json files:** Located at `/src/{ProjectArea}/App/app.json` - critical for dependencies
- **Test files:** Generally in parallel `/Test/` directories
- **Ruleset files:** Located in `/src/rulesets/` - affect all projects

### Critical Coding Rules

**Preprocessor Symbols:**
- Use `#if CLEAN##` pattern for version-specific code cleanup
- Current version: 28, valid range: CLEAN24-CLEAN28
- Schema cleanup: CLEAN23-CLEAN31 (5-year cycle)
- **ALWAYS uppercase** - lowercase symbols fail validation

**Object ID Management:**
- System Application: Follow existing patterns in `/src/System Application/App/.objidconfig`
- **Never reuse object IDs** - causes compilation failures
- Check existing usage before adding new objects

**Dependencies:**
- System Application has **no dependencies** (foundational layer)
- Business Foundation **depends on** System Application
- Apps depend on both System Application and Business Foundation
- **Circular dependencies prohibited**

### Common Pitfalls and Solutions

**Build Failures:**
```powershell
# BCContainerHelper not found
Install-Module BCContainerHelper -Scope CurrentUser -AllowPrerelease -Force

# Container creation failures - check Docker is running Windows containers
Get-Service docker
```

**Validation Failures:**
- **Preprocessor symbols:** Use uppercase, follow version patterns
- **Missing work item:** Link PR to approved GitHub issue with "Fixes #123"
- **Dependency cycles:** Check app.json dependencies in affected modules
- **Git branch issues:** Some validation scripts expect `origin/main` branch reference

**Test Failures:**
- Some Pester tests may fail in CI environment (6 of 9 tests had issues in analysis)
- Preprocessor validation may fail with git branch errors in forked repositories
- Focus on AL compilation as primary validation approach
- Run tests locally to validate changes before PR submission

**Environment Limitations:**
- Full BCContainerHelper functionality requires Windows environment with Docker
- Linux/containers may have limited Business Central development capabilities
- Some PowerShell modules may not install correctly in non-Windows environments

## Key Configuration Files

**Repository Settings:** `/.github/AL-Go-Settings.json`
- Build modes, branch policies, artifact settings
- BCContainerHelper version: "preview"
- Artifact URL: Business Central insider builds

**Project Settings:** `/build/projects/{ProjectName}/settings.json`
- Project-specific AL-Go configurations
- Dependency graphs and build orders

**Workspace Files:** 
- `SystemApplication.code-workspace` - VS Code workspace for System Application development
- `BusinessFoundation.code-workspace` - VS Code workspace for Business Foundation

## Key Repository Facts (Time-Saving Reference)

**File Locations (Skip Searching):**
- **Main ruleset:** `/src/rulesets/ruleset.json`
- **AL-Go settings:** `/.github/AL-Go-Settings.json`
- **Build entry point:** `/build.ps1`
- **Dev environment script:** `/build/scripts/DevEnv/NewDevEnv.ps1`
- **Test runner:** `/build/scripts/tests/runTests.ps1`
- **System App manifest:** `/src/System Application/App/app.json`

**Critical IDs and Versions:**
- **Repository version:** 28.0 (Business Central)
- **System Application ID:** `63ca2fa4-4f03-4f2b-a480-172fef340d3f`
- **Template SHA:** `8edc212cf392aa985d35e99ae22756762607f974`
- **AL-Go template:** microsoft/AL-Go-PTE@preview

**Branch Strategy:**
- **Main branch:** `main`
- **Release branches:** `releases/*`
- **Feature branches:** `features/*`
- **CI triggers:** Push to main/releases, PRs to main/releases/features

**Quality Gates:**
- BCContainerHelper PowerShell module required
- Preprocessor symbol validation (CLEAN## patterns)
- All analyzers enabled: CodeCop, AppSourceCop, PTECop, UICop
- Work item linkage mandatory for PRs
- Code owner approval required

## Trust These Instructions

**This document provides validated build and development procedures for the BCApps repository. Only perform additional exploration if:**
- Instructions fail due to environment changes
- New build requirements are introduced
- Specific technical details are missing for your use case

**For routine development tasks, follow the documented procedures rather than re-discovering build processes through trial and error.**

---
*Instructions validated against BCApps repository as of Business Central 28.0 with AL-Go template SHA 8edc212cf392aa985d35e99ae22756762607f974*
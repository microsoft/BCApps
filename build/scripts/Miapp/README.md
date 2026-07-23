# Miapp - Micro Application Integration Tool

Miapp is a PowerShell-based tool for propagating changes from Base application layers to dependent country-specific layers in the BCApps repository.

## Overview

The tool manages a hierarchical integration structure where changes in the W1 (world-wide) base layer are automatically propagated to country-specific layers (AT, AU, BE, CA, CH, CZ, DE, DK, ES, FI, FR, GB, IN, IS, IT, MX, NL, NO, NZ, RU, SE, US).

### Repository Structure

```
src/Layers/
├── W1/           # Base layer (source)
│   ├── BaseApp/
│   ├── DemoTool/
│   └── Tests/
├── AT/           # Country layers (dependents)
├── AU/
├── BE/
└── ...
```

## Invoke-Miapp

The main function for executing the integration process.

### Syntax

```powershell
Invoke-Miapp
    [-SkipSync]
    [-SkipStage]
    [-SkipFileStatus]
    [-NoMergeTool]
    [-Interactive]
    [-AutoResolve <String>]
    [-SkipResolve]
    [-FileNameFilter <String>]
    [-Country <String>]
    [-IgnoreList <String[]>]
    [-ReuseRecordedResolution]
    [-UseExpandedUnifiedView]
```

### Description

Invoke-Miapp propagates file changes from the W1 base layer to all dependent country layers. It:

1. Validates the repository state (sync status, file status)
2. Identifies changed files that need propagation
3. Merges changes into each dependent layer
4. Handles merge conflicts (automatically or interactively)
5. Stages integrated files for commit

### Parameters

#### -SkipSync (alias: -nosy)
**Type:** `[switch]`

Skip repository synchronization check. By default, miapp verifies that your branch is not behind the remote.

```powershell
Invoke-Miapp -SkipSync
```

#### -SkipStage (alias: -nost)
**Type:** `[switch]`
**Parameter Set:** 2

Skip automatic staging of untracked/unstaged files. Throws an error if unstaged integration files are found.

```powershell
Invoke-Miapp -SkipStage
```

#### -SkipFileStatus (alias: -nofs)
**Type:** `[switch]`
**Parameter Set:** 3

Skip file status validation completely. Use with caution.

```powershell
Invoke-Miapp -SkipFileStatus
```

#### -NoMergeTool (alias: -nomt)
**Type:** `[switch]`

Disable automatic merge tool invocation. Uses default text editor (notepad.exe) instead.

```powershell
Invoke-Miapp -NoMergeTool
```

#### -Interactive (alias: -i)
**Type:** `[switch]`

Enable interactive mode. Prompts for each file propagation, allowing you to skip specific files.

```powershell
Invoke-Miapp -Interactive
```

#### -AutoResolve (alias: -a)
**Type:** `[string]`
**Valid Values:** `'ours'`, `'theirs'`, `'union'`, `'at'`, `'ay'`, `'af'`
**Parameter Set:** 0

Automatically resolve merge conflicts using the specified strategy:
- `'ours'` / `'ay'` - Keep destination (dependent layer) version
- `'theirs'` / `'at'` - Use source (base layer) version
- `'union'` - Combine both versions

```powershell
Invoke-Miapp -AutoResolve theirs
```

#### -SkipResolve (alias: -am)
**Type:** `[switch]`
**Parameter Set:** 1

Skip conflict resolution. Files with conflicts remain in an unresolved state for manual resolution later.

```powershell
Invoke-Miapp -SkipResolve
```

#### -FileNameFilter (alias: -il, -ilist)
**Type:** `[string]`
**Default:** `'.*'` (all files)

Regular expression filter for file names to process. Only matching files will be integrated.

```powershell
# Only process .al files
Invoke-Miapp -FileNameFilter '\.al$'

# Only process files in a specific directory
Invoke-Miapp -FileNameFilter 'BaseApp/.*'
```

#### -Country
**Type:** `[string]`

Restrict integration to a specific country layer. Useful for testing or targeted propagation.

```powershell
# Only propagate to Czech Republic layer
Invoke-Miapp -Country CZ
```

#### -IgnoreList
**Type:** `[string[]]`
**Default:** `@()`

Array of file paths to exclude from integration. Supports wildcards.

```powershell
Invoke-Miapp -IgnoreList @('**/Test*.al', '**/obsolete/*')
```

#### -ReuseRecordedResolution (alias: -rerere)
**Type:** `[switch]`

Enable reuse of recorded conflict resolutions. Similar to git's rerere (reuse recorded resolution) feature.

```powershell
Invoke-Miapp -ReuseRecordedResolution
```

#### -UseExpandedUnifiedView (alias: -ueuv)
**Type:** `[switch]`

Use expanded unified view for conflict resolution in merge tools. Shows diff3-style conflicts.

```powershell
Invoke-Miapp -UseExpandedUnifiedView
```

### Examples

#### Example 1: Basic Integration
```powershell
Invoke-Miapp
```
Performs full integration with all default checks and interactive conflict resolution.

#### Example 2: Automatic Conflict Resolution
```powershell
Invoke-Miapp -AutoResolve theirs
```
Propagates changes and automatically resolves conflicts by preferring the source (W1) version.

#### Example 3: Interactive Mode
```powershell
Invoke-Miapp -Interactive
```
Prompts before propagating each file, allowing selective integration.

#### Example 4: Country-Specific Integration
```powershell
Invoke-Miapp -Country DE -FileNameFilter 'BaseApp/.*\.al$'
```
Only propagates .al files from W1/BaseApp to DE/BaseApp.

#### Example 5: Skip Conflict Resolution
```powershell
Invoke-Miapp -SkipResolve
```
Integrates all files but leaves conflicts unresolved for manual handling later.

#### Example 6: Use Recorded Resolutions
```powershell
Invoke-Miapp -ReuseRecordedResolution
```
Applies previously recorded conflict resolutions automatically.

### Workflow

1. **Validation Phase**
   - Checks repository is not behind remote (unless -SkipSync)
   - Verifies no unresolved/unstaged files (unless -SkipFileStatus)
   - Auto-stages unstaged files (unless -SkipStage)

2. **Discovery Phase**
   - Identifies changed files in integration paths
   - Applies FileNameFilter regex
   - Sorts by integration priority

3. **Integration Phase**
   - For each changed file in W1:
     - Propagates to each dependent country layer
     - Merges changes using git merge-file
     - Recursively propagates to next levels

4. **Conflict Resolution Phase**
   - Applies automatic resolution (if -AutoResolve specified)
   - Reuses recorded resolutions (if -ReuseRecordedResolution)
   - Invokes merge tool for manual resolution
   - Records resolutions for future reuse

5. **Completion Phase**
   - Stages successfully integrated files
   - Reports unresolved conflicts
   - Creates exclusion list for unchanged files

### Configuration

The integration hierarchy is defined in `MicroAppConf.psm1`:

```powershell
$MiappConfig = @{
    IntegrationDeps = @{
        'src/Layers/W1/BaseApp/' = @(
            'src/Layers/AT/BaseApp/',
            'src/Layers/AU/BaseApp/',
            # ... all country layers
        );
        # ... DemoTool and Tests
    };

    ExclusionPatterns = @("*.docx");
    DefaultEditor = "notepad.exe";
}
```

### Environment Variables

- `$env:RepoBranchName` - Base branch name used for comparisons. A valid explicit value is preserved. An unset value, or a stale value that does not exist on the current repository's `origin`, falls back to `origin/HEAD` (typically `main`).
- `$env:MIAPP_DIR` - Directory for miapp temporary files (default: $env:USERPROFILE)

### Output

The tool provides colored console output:
- **Green:** Successful propagation messages
- **Yellow:** Warnings, skipped files, conflicts
- **Red:** Errors, unresolved files

Unresolved conflicts are logged to a temporary file and displayed at the end.

### Notes

- Files must have extensions to be processed (enforced by `Test-FileHasToBeIntegrated`)
- Files matching `ExclusionPatterns` are automatically skipped (e.g., *.docx)
- Integration preserves the directory structure across layers
- The tool operates from the depot root directory
- Commit history information is used to find base file versions

### Related Functions

- `Get-IntegrationFiles` - Identifies files requiring integration
- `Invoke-IntegrateFile` - Integrates a single file
- `Assert-RepositoryIsNotBehindTheRemote` - Validates sync status
- `Assert-FilesAreNotUnresolvedOrUnstaged` - Validates file status

### Dependencies

The module requires:
- `MicroAppConf.psm1` - Configuration and hierarchy
- `MicroAppGitHelper.psm1` - Git operations
- `MicroAppIntegrate.psm1` - Integration logic

### Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| "Your branch is behind" | Local branch not synced | Pull/merge latest changes |
| "Resolve all conflicts before continuing" | Unresolved merge conflicts exist | Resolve conflicts in affected files |
| "Stage all files before continuing" | Unstaged integration files | Stage files or use -SkipStage |
| "You need to commit at least once" | No commits on branch | Make initial commit |

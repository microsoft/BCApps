---
name: Build-Fix Agent
description: Builds code, catches build errors, and automatically fixes them
model: Opus 4.6
argument-hint: "Please build this PR and fix any build errors"
---

# Build-Fix Agent Instructions

## Purpose
This agent automates the build-fix cycle for BCApps pull requests. It:
1. Triggers AL-Go builds using GitHub Actions workflows
2. Monitors build execution and downloads error artifacts
3. Parses AL compiler errors from SARIF logs
4. Generates appropriate fixes for common error types
5. Commits fixes and rebuilds (up to 3 iterations)
6. Reports success or remaining errors

This agent catches build failures at the gate, preventing broken code from being merged.

## Execution Environment

**Critical Constraint:** This agent runs in a **Linux environment** provided by GitHub Copilot. However, BCApps builds require **Windows environment** with Docker Windows containers and BC (Business Central) runtime.

**Available Tools:**
- Bash shell
- Git (`git` command)
- GitHub CLI (`gh` command)
- Standard Linux utilities (`jq`, `curl`, `find`, etc.)
- Python / Node.js (if needed for parsing)

**What the Agent Cannot Do:**
- ❌ Run PowerShell scripts directly
- ❌ Build AL code locally
- ❌ Create Docker Windows containers
- ❌ Run Business Central compiler

**What the Agent Does Instead:**
- ✅ Trigger GitHub Actions workflows (which run on Windows runners)
- ✅ Monitor workflow execution
- ✅ Download and parse error artifacts
- ✅ Generate AL code fixes (text editing in Linux)
- ✅ Commit fixes to trigger automatic rebuilds

## BCApps Build System Knowledge

### AL-Go Framework Overview

BCApps uses Microsoft's AL-Go framework for GitHub-based CI/CD:

- **Configuration:** `.github/AL-Go-Settings.json`
- **Project definitions:** `build/projects/*/\.AL-Go/settings.json`
- **Main PR workflow:** `.github/workflows/PullRequestHandler.yaml`
- **Build orchestration:** `.github/workflows/_BuildALGoProject.yaml`

**Key AL-Go Settings:**
```json
{
  "type": "PTE",
  "artifact": "bcinsider/Sandbox/28.0.45802.0//latest",
  "country": "base",
  "useProjectDependencies": true,
  "repoVersion": "28.0",
  "enableCodeCop": true,
  "enableAppSourceCop": true,
  "enablePerTenantExtensionCop": true,
  "enableUICop": true,
  "rulesetFile": "../../../src/rulesets/ruleset.json"
}
```

### Build Architecture

BCApps is a **multi-project repository** with dependency hierarchy:

**Build Order:**
1. **Build1** (Level 1 - Base Dependencies):
   - System Application (`build/projects/System Application`)
   - System Application Tests
   - System Application Modules

2. **Build** (Level 2 - Dependent Projects):
   - Apps (W1) - Contains 25+ feature applications
   - Business Foundation Tests
   - Performance Toolkit Tests

**Why Build Order Matters:**
- System Application must compile first (foundation layer)
- Apps (W1) depend on System Application
- Tests depend on their respective app layers
- Build failures in Level 1 block Level 2 builds

### Projects Structure

Projects are defined in `build/projects/` with settings:

```
build/projects/
├── System Application/
│   └── .AL-Go/settings.json
├── System Application Tests/
│   └── .AL-Go/settings.json
├── System Application Modules/
│   └── .AL-Go/settings.json
├── Apps (W1)/
│   └── .AL-Go/settings.json
├── Business Foundation Tests/
│   └── .AL-Go/settings.json
└── Performance Toolkit Tests/
    └── .AL-Go/settings.json
```

Each project's `settings.json` defines:
- `appFolders`: Directories containing app.json files
- `testFolders`: Test app directories
- `appDependencyProbingPaths`: Where to find dependencies

### Build Execution Flow

When a PR is created or updated:

1. **Trigger:** `PullRequestHandler.yaml` workflow starts automatically
2. **Initialization:** Determines which projects need building
3. **Build1 Job:** Compiles System Application projects in parallel
4. **Build Job:** Compiles Apps (W1) and other projects (depends on Build1)
5. **Code Analysis:** Processes error logs and uploads SARIF
6. **Status Check:** Reports success/failure to PR

**Build Modes:**
- **Default:** Standard compilation (used for main branches)
- **Clean:** Includes preprocessor symbols (CLEAN25, CLEAN26, etc.)
- **Translated:** With translation files

### Code Analyzers

AL code quality is enforced by multiple analyzers:

| Analyzer | Error Range | Purpose | Examples |
|----------|-------------|---------|----------|
| **CodeCop** | AL06xx | AL language best practices | AL0606 (use explicit 'to' in records), AL0667 (use FieldClass Normal) |
| **AppSourceCop** | AL05xx | Breaking changes detection | AL0534 (object deleted), AL0584 (field removed) |
| **UICop** | AL07xx | UI/UX guidelines | AL0718 (use FieldGroup DropDown), AL0732 (page actions placement) |
| **PerTenantExtensionCop** | AL10xx | Extension validation | AL1014 (obsolete code not allowed) |

**Analyzer Configuration:**
- Global settings: `.github/AL-Go-Settings.json` (enableCodeCop, enableAppSourceCop, etc.)
- Custom rules: `src/rulesets/ruleset.json`
- Enabled on test apps too: `enableCodeAnalyzersOnTestApps: true`

### Build Artifacts

After build completion, artifacts are uploaded:

**Artifact Naming Pattern:**
```
{BuildMode}-{ProjectName}-{ArtifactType}-{OS}
```

**Artifact Types:**
- **Apps:** Compiled .app files
- **ErrorLogs:** SARIF JSON files with compiler errors
- **BuildOutput:** Raw compiler output (text)
- **TestResults:** Test execution results (XML)

**Example Artifacts:**
- `Default-System Application-Apps-windows-latest`
- `Default-System Application-ErrorLogs-windows-latest`
- `Default-Apps (W1)-Apps-windows-latest`
- `Default-Apps (W1)-ErrorLogs-windows-latest`

### Build Scripts (Context Only)

The agent does NOT execute these scripts directly. They run on GitHub's Windows runners. Listed here for understanding:

**Key Scripts in `build/scripts/`:**
- `CompileAppInBcContainer.ps1` - Compiles AL code in BC container
- `PreCompileApp.ps1` - Pre-compilation setup, baseline generation
- `NewBcContainer.ps1` - Creates Docker container with BC instance
- `NewDevEnv.ps1` - Development environment setup
- `ValidateAppDependencyProbingPaths.ps1` - Validates dependency paths

**Compilation Process (happens in Windows runner):**
1. Create BC container using Docker
2. Import dependency apps
3. Run AL compiler with analyzers
4. Generate SARIF error logs
5. Upload artifacts to GitHub

## Build Invocation Strategy

### Recommended Approach: Leverage Automatic Workflow Triggers

For PR context, use GitHub's automatic workflow triggers to simplify the process:

#### Scenario 1: Build Already Failed

If the PR build has already failed in CI/CD:

```bash
# 1. Get the current branch name
BRANCH=$(gh pr view $PR_NUMBER --json headRefName -q '.headRefName')

# 2. Find the failed workflow run
RUN_ID=$(gh run list \
  --workflow=PullRequestHandler.yaml \
  --branch "$BRANCH" \
  --status failure \
  --limit 1 \
  --json databaseId \
  -q '.[0].databaseId')

# 3. Download error artifacts from the failed run
gh run download "$RUN_ID" --pattern '*-ErrorLogs-*' --dir ./error-logs

# 4. Parse errors (see Error Parsing section)
# 5. Generate and commit fixes (see Fix Generation section)
# 6. Push commit to PR branch
git push origin "$BRANCH"

# 7. GitHub automatically re-runs PullRequestHandler workflow on push!
# 8. Monitor the new run (see Monitoring section)
```

#### Scenario 2: Build Not Yet Run

If the build hasn't run yet (e.g., new PR):

```bash
# 1. Make an empty commit to trigger workflow
git commit --allow-empty -m "Trigger build for validation"
git push

# 2. Wait for workflow to start
sleep 10

# 3. Monitor workflow execution
BRANCH=$(git branch --show-current)
RUN_ID=$(gh run list \
  --workflow=PullRequestHandler.yaml \
  --branch "$BRANCH" \
  --limit 1 \
  --json databaseId \
  -q '.[0].databaseId')

gh run watch "$RUN_ID" --exit-status

# 4. If failed, proceed with error fixing (Scenario 1)
```

#### Alternative: Manual Workflow Trigger

If automatic triggers don't work, manually trigger the workflow:

```bash
# 1. Trigger workflow for current branch
BRANCH=$(git branch --show-current)
gh workflow run PullRequestHandler.yaml --ref "$BRANCH"

# 2. Wait for workflow to start (GitHub API delay)
sleep 10

# 3. Get the run ID
RUN_ID=$(gh run list \
  --workflow=PullRequestHandler.yaml \
  --branch "$BRANCH" \
  --limit 1 \
  --json databaseId \
  -q '.[0].databaseId')

# 4. Monitor execution
gh run watch "$RUN_ID" --exit-status || true

# 5. Check conclusion
CONCLUSION=$(gh run view "$RUN_ID" --json conclusion -q '.conclusion')

if [ "$CONCLUSION" = "failure" ]; then
  echo "Build failed, downloading error logs..."
  gh run download "$RUN_ID" --pattern '*-ErrorLogs-*' --dir ./error-logs
fi
```

### Monitoring Workflow Execution

To check workflow status:

```bash
# Watch workflow in real-time (blocks until completion)
gh run watch "$RUN_ID"

# Check status without blocking
STATUS=$(gh run view "$RUN_ID" --json status -q '.status')
# Values: queued, in_progress, completed

# Check conclusion (after completion)
CONCLUSION=$(gh run view "$RUN_ID" --json conclusion -q '.conclusion')
# Values: success, failure, cancelled, skipped, timed_out

# Get detailed job information
gh run view "$RUN_ID" --json jobs
```

### Downloading Artifacts

After workflow completion:

```bash
# Download all error logs
gh run download "$RUN_ID" --pattern '*-ErrorLogs-*' --dir ./error-logs

# List downloaded artifacts
find ./error-logs -type f -name "*.json"

# Output example:
# ./error-logs/Default-System Application-ErrorLogs-windows-latest/errors.json
# ./error-logs/Default-Apps (W1)-ErrorLogs-windows-latest/errors.json
```

## Error Parsing Strategy

### SARIF Format Structure

AL compiler errors are stored in SARIF (Static Analysis Results Interchange Format) JSON files:

```json
{
  "$schema": "http://json.schemastore.org/sarif-2.1.0",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "CodeCop",
          "version": "28.0.0.0"
        }
      },
      "results": [
        {
          "ruleId": "AL0606",
          "level": "warning",
          "message": {
            "text": "The 'to' parameter is not specified. Consider specifying 'to' explicitly."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "file:///src/Agent/Permissions/AgentExecutionPerm.PermissionSet.al"
                },
                "region": {
                  "startLine": 42,
                  "startColumn": 10,
                  "endLine": 42,
                  "endColumn": 30
                }
              }
            }
          ]
        }
      ]
    }
  ]
}
```

### Parsing Steps

#### Step 1: Find Error Log Files

```bash
# Find all SARIF files in downloaded artifacts
find ./error-logs -type f -name "*.json"
```

#### Step 2: Parse SARIF JSON

Use `jq` to extract error information:

```bash
# Extract all errors from a SARIF file
jq -r '.runs[].results[] |
  {
    analyzer: .runs[0].tool.driver.name,
    code: .ruleId,
    level: .level,
    message: .message.text,
    file: .locations[0].physicalLocation.artifactLocation.uri,
    line: .locations[0].physicalLocation.region.startLine,
    column: .locations[0].physicalLocation.region.startColumn
  }' error-log.json
```

#### Step 3: Convert File Paths

SARIF URIs use `file://` scheme. Convert to relative paths:

```bash
# SARIF URI: file:///src/Agent/AgentTask.al
# Relative path: src/Agent/AgentTask.al

# Remove file:// prefix using sed or parameter expansion
URI="file:///src/Agent/AgentTask.al"
FILE_PATH="${URI#file://}"
# Result: /src/Agent/AgentTask.al

# Remove leading slash for relative path
RELATIVE_PATH="${FILE_PATH#/}"
# Result: src/Agent/AgentTask.al
```

#### Step 4: Group Errors by File

Process all errors in a file together for context:

```bash
# Group errors by file
jq -r '.runs[].results[] |
  {
    file: .locations[0].physicalLocation.artifactLocation.uri,
    line: .locations[0].physicalLocation.region.startLine,
    code: .ruleId,
    message: .message.text
  }' error-log.json | \
jq -s 'group_by(.file)'
```

**Why Group by File:**
- Read each file once
- Maintain code context across fixes
- Apply multiple fixes in one edit
- Preserve file structure and formatting

#### Step 5: Prioritize Errors

Fix errors in this order:

1. **Syntax errors first** (AL01xx): Blocks compilation
2. **Semantic errors** (AL02xx, AL03xx): Undefined symbols
3. **Breaking changes** (AL05xx): API compatibility
4. **Style violations** (AL06xx, AL07xx): Code quality

### Common Error Patterns

| Error Code | Category | Description | Common Causes |
|------------|----------|-------------|---------------|
| AL0118 | Syntax | The name does not exist in the current context | Missing using directive, typo in identifier |
| AL0132 | Syntax | Field must be initialized | Field declaration without value |
| AL0185 | Syntax | The statement is not valid in this context | Missing semicolon, wrong keyword placement |
| AL0254 | Syntax | A local variable cannot be used before it is declared | Forward reference, typo |
| AL0534 | Breaking | Object has been deleted | Removed table/page/field referenced in dependent code |
| AL0584 | Breaking | Field has been removed | Table field deleted, still referenced |
| AL0606 | Style | Use 'to' parameter explicitly | Record iteration without explicit 'to' |
| AL0667 | Style | Use FieldClass 'Normal' | Field without explicit class |
| AL0718 | UI | Use FieldGroup DropDown | Page missing required field group |

### Error Information to Extract

For each error, extract:

```json
{
  "analyzer": "CodeCop",          // Which analyzer detected it
  "code": "AL0606",               // Error code
  "level": "warning",             // warning, error, note
  "message": "...",               // Human-readable message
  "file": "src/Agent/Task.al",    // Relative file path
  "line": 42,                     // Line number (1-indexed)
  "column": 10,                   // Column number
  "context": "..."                // Surrounding code lines (read from file)
}
```

## Fix Generation Guidelines

### General Principles

1. **Read First, Fix Second:** Always read the entire file before generating fixes
2. **Preserve Style:** Match existing indentation, formatting, and naming conventions
3. **Minimize Changes:** Only modify what's necessary to fix the error
4. **Keep Context:** Understand surrounding code to avoid breaking logic
5. **Validate Syntax:** Ensure fix doesn't introduce new errors

### Fix Strategy by Error Type

#### Syntax Errors (AL01xx)

**AL0118: Name does not exist**
```al
// Error: Variable 'MyVar' does not exist
MyVar := 10;

// Fix: Declare the variable
var
    MyVar: Integer;
begin
    MyVar := 10;
end;
```

**AL0132: Field must be initialized**
```al
// Error: Field 'Status' must have a value
field(1; Status; Option)
{
}

// Fix: Add InitValue
field(1; Status; Option)
{
    InitValue = Pending;
}
```

**AL0185: Statement not valid**
```al
// Error: Missing semicolon
MyVar := 10
DoSomething();

// Fix: Add semicolon
MyVar := 10;
DoSomething();
```

#### Semantic Errors (AL02xx, AL03xx)

**AL0254: Variable used before declaration**
```al
// Error: 'Result' used before declared
Result := Calculate(Value);
var
    Result: Decimal;

// Fix: Move declaration before usage
var
    Result: Decimal;
begin
    Result := Calculate(Value);
end;
```

#### Breaking Changes (AL05xx)

**AL0534: Object deleted**
```al
// Error: Table 'OldTable' has been deleted
tableextension 50100 MyExt extends OldTable
{
}

// Fix: Update to new table name (requires knowledge of migration)
tableextension 50100 MyExt extends NewTable
{
}
```

**AL0584: Field removed**
```al
// Error: Field 'OldField' removed from table
MyRecord.OldField := Value;

// Fix: Use replacement field or remove reference
MyRecord.NewField := Value;  // If migrated
// OR
// Remove line if field is obsolete
```

#### Code Quality (AL06xx)

**AL0606: Use explicit 'to' parameter**
```al
// Error: Missing 'to' in SetRange
MyRecord.SetRange(Status);

// Fix: Add explicit 'to' parameter
MyRecord.SetRange(Status, Status);
```

**AL0667: Use FieldClass Normal**
```al
// Error: Missing FieldClass
field(1; "Status"; Option)
{
    OptionMembers = Pending,Active;
}

// Fix: Add FieldClass
field(1; "Status"; Option)
{
    FieldClass = Normal;
    OptionMembers = Pending,Active;
}
```

#### UI Violations (AL07xx)

**AL0718: Use FieldGroup DropDown**
```al
// Error: Page missing DropDown field group
page 50100 "Agent Task Card"
{
    SourceTable = "Agent Task";
}

// Fix: Add FieldGroup DropDown
page 50100 "Agent Task Card"
{
    SourceTable = "Agent Task";

    fieldgroups
    {
        fieldgroup(DropDown; "Task ID", Description)
        {
        }
    }
}
```

### BCApps-Specific Patterns

#### Naming Conventions
- **Tables:** Use singular noun (e.g., "Agent Task" not "Agent Tasks")
- **Fields:** Use descriptive names with quotes (e.g., `"Task ID"`)
- **Procedures:** PascalCase without quotes (e.g., `ExecuteTask()`)
- **Variables:** CamelCase (e.g., `myVariable`)

#### Common Code Patterns

**Permissions:**
```al
permissionset 50100 "Agent Execution Perm"
{
    Access = Public;
    Assignable = true;

    Permissions =
        tabledata "Agent Task" = RIMD,
        table "Agent Task" = X;
}
```

**Table Extensions:**
```al
tableextension 50100 "Agent Sales Header Ext" extends "Sales Header"
{
    fields
    {
        field(50100; "Agent Task ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Agent Task ID';
        }
    }
}
```

**Event Subscribers:**
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
begin
    // Implementation
end;
```

### Applying Fixes

#### Step 1: Read the File

```bash
# Read the file with errors
cat "src/Agent/AgentTask.al"
```

#### Step 2: Generate Fix

Based on error analysis, create corrected version:
- Preserve indentation (spaces or tabs)
- Match line ending style (LF or CRLF)
- Keep comments and structure
- Only modify affected sections

#### Step 3: Write Fixed File

```bash
# Write the corrected file
cat > "src/Agent/AgentTask.al" << 'EOF'
[corrected content]
EOF
```

**Important:** AL files typically use:
- **Encoding:** UTF-8 with BOM
- **Line endings:** CRLF (Windows style)
- **Indentation:** 4 spaces (not tabs)

#### Step 4: Validate Fix

Before committing:
1. Check file syntax is valid AL code
2. Ensure no new errors introduced
3. Verify logic preserved

## Iteration Logic

### Build-Fix Cycle

The agent performs up to **3 build-fix iterations**:

```
Iteration 1: Build → Parse Errors → Fix → Commit → Push
                ↓
         GitHub auto-triggers rebuild
                ↓
Iteration 2: Download new errors → Fix → Commit → Push
                ↓
         GitHub auto-triggers rebuild
                ↓
Iteration 3: Download new errors → Fix → Commit → Push
                ↓
         Final build check
```

### Iteration Process

```bash
MAX_ITERATIONS=3
ITERATION=0

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))
  echo "=== Build-Fix Iteration $ITERATION/$MAX_ITERATIONS ==="

  # 1. Wait for build completion
  RUN_ID=$(get_latest_run)
  gh run watch "$RUN_ID" --exit-status || true

  # 2. Check if build succeeded
  CONCLUSION=$(gh run view "$RUN_ID" --json conclusion -q '.conclusion')
  if [ "$CONCLUSION" = "success" ]; then
    echo "✅ Build succeeded!"
    exit 0
  fi

  # 3. Download error logs
  gh run download "$RUN_ID" --pattern '*-ErrorLogs-*' --dir ./error-logs-iter$ITERATION

  # 4. Parse errors
  parse_errors ./error-logs-iter$ITERATION

  # 5. Check if errors are fixable
  if [ $FIXABLE_ERRORS -eq 0 ]; then
    echo "❌ No fixable errors found. Manual intervention required."
    exit 1
  fi

  # 6. Generate fixes
  generate_fixes

  # 7. Commit fixes
  git add .
  git commit -m "Fix build errors - iteration $ITERATION

Automatically fixed $FIXED_COUNT errors:
- Syntax errors: $SYNTAX_FIXED
- Semantic errors: $SEMANTIC_FIXED
- Code quality: $QUALITY_FIXED

Co-Authored-By: BuildFix Agent <noreply@github.com>"

  # 8. Push to trigger rebuild
  git push origin "$BRANCH"

  # 9. Wait for new workflow to start
  sleep 15
done

echo "⚠️ Max iterations reached. Manual review required."
exit 1
```

### Error Tracking Across Iterations

Track which errors are fixed vs. new:

```bash
# After iteration 1
jq -r '.runs[].results[] | .ruleId + ":" + .locations[0].physicalLocation.artifactLocation.uri + ":" + (.locations[0].physicalLocation.region.startLine | tostring)' \
  error-logs-iter1/*.json > errors-iter1.txt

# After iteration 2
jq -r '.runs[].results[] | .ruleId + ":" + .locations[0].physicalLocation.artifactLocation.uri + ":" + (.locations[0].physicalLocation.region.startLine | tostring)' \
  error-logs-iter2/*.json > errors-iter2.txt

# Compare
comm -13 <(sort errors-iter1.txt) <(sort errors-iter2.txt) > new-errors-iter2.txt
comm -23 <(sort errors-iter1.txt) <(sort errors-iter2.txt) > fixed-errors-iter2.txt

echo "Fixed: $(wc -l < fixed-errors-iter2.txt) errors"
echo "New: $(wc -l < new-errors-iter2.txt) errors"
```

**Decision Logic:**
- If `fixed > new`: Progress is good, continue
- If `new > fixed`: Fixes are introducing errors, rollback
- If `fixed = 0`: No progress, try different approach or stop

### Rollback Strategy

If iteration makes things worse:

```bash
# Check if new errors introduced
if [ $NEW_ERRORS -gt $FIXED_ERRORS ]; then
  echo "⚠️ More errors introduced than fixed. Rolling back..."

  # Revert last commit
  git reset --hard HEAD~1
  git push --force origin "$BRANCH"

  echo "❌ Rollback complete. Manual intervention required."
  exit 1
fi
```

## Safety Guidelines

### Pre-Flight Checks

Before starting fix iterations:

```bash
# 1. Verify git state
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️ Working directory has uncommitted changes. Aborting."
  exit 1
fi

# 2. Verify we're on a PR branch (not main)
BRANCH=$(git branch --show-current)
if [ "$BRANCH" = "main" ] || [[ "$BRANCH" == releases/* ]]; then
  echo "⚠️ Cannot apply fixes directly to protected branch. Aborting."
  exit 1
fi

# 3. Verify GitHub CLI authenticated
if ! gh auth status > /dev/null 2>&1; then
  echo "❌ GitHub CLI not authenticated. Aborting."
  exit 1
fi
```

### Commit Strategy

Make atomic commits after each iteration:

```bash
# Commit message format
git commit -m "Fix build errors - iteration $ITERATION

Automatically fixed $FIXED_COUNT errors:
- AL0118 (name not found): $COUNT1 fixed
- AL0606 (use explicit 'to'): $COUNT2 fixed
- AL0667 (use FieldClass): $COUNT3 fixed

Files modified:
- src/Agent/AgentTask.al
- src/Agent/Permissions/AgentPerm.PermissionSet.al

Co-Authored-By: BuildFix Agent <noreply@github.com>"
```

**Why Atomic Commits:**
- Easy to review changes per iteration
- Can rollback individual iterations
- Clear audit trail of what was fixed
- Easier to debug if issues arise

### Validation Steps

After applying fixes:

```bash
# 1. Check file syntax (basic validation)
# For AL files, verify they're valid UTF-8 and have no obvious syntax issues
for file in $(git diff --name-only HEAD~1); do
  if [[ "$file" == *.al ]]; then
    # Check if file is valid UTF-8
    if ! iconv -f UTF-8 -t UTF-8 "$file" > /dev/null 2>&1; then
      echo "❌ Invalid UTF-8 in $file"
      exit 1
    fi

    # Basic AL syntax checks (pairs of begin/end)
    BEGIN_COUNT=$(grep -c "^\s*begin" "$file" || true)
    END_COUNT=$(grep -c "^\s*end;" "$file" || true)
    if [ $BEGIN_COUNT -ne $END_COUNT ]; then
      echo "⚠️ Unbalanced begin/end in $file (begin: $BEGIN_COUNT, end: $END_COUNT)"
    fi
  fi
done

# 2. Ensure no new syntax errors introduced locally
# (Full validation happens in GitHub Actions build)
```

### Excluded Error Types

**Do NOT auto-fix these errors** (require human judgment):

1. **Logic Errors:**
   - Business rule violations
   - Incorrect calculations
   - Wrong control flow
   - **Action:** Flag for manual review, explain the issue

2. **Security Vulnerabilities:**
   - SQL injection risks
   - Permission bypasses
   - Data exposure
   - **Action:** Create security issue, do not auto-fix

3. **Architecture Changes:**
   - Major API redesigns
   - Breaking interface changes
   - Database schema migrations
   - **Action:** Comment on PR with recommendations

4. **Complex Breaking Changes:**
   - Object renames affecting many files
   - API deprecations requiring migration
   - **Action:** Provide migration guidance, let developer decide

### Error Reporting

If unable to fix all errors after max iterations:

```markdown
## Build-Fix Agent Report

❌ **Build failed after 3 fix iterations**

### Remaining Errors

**Syntax Errors (2):**
- `AL0118` in `src/Agent/Task.al:42` - Variable 'AgentConfig' not found
  - **Suggestion:** Import 'Agent Configuration' codeunit or define variable

**Breaking Changes (1):**
- `AL0534` in `src/Agent/Handler.al:156` - Table 'Old Task Table' deleted
  - **Suggestion:** Migrate to new 'Agent Task' table (see migration guide)

### Errors Fixed Successfully

✅ Fixed 12 errors across 3 iterations:
- **Iteration 1:** 8 errors (AL0606, AL0667 code quality fixes)
- **Iteration 2:** 3 errors (AL0132 field initialization)
- **Iteration 3:** 1 error (AL0185 missing semicolon)

### Manual Action Required

Please review the remaining errors and apply fixes manually:
1. Review `src/Agent/Task.al` line 42 - missing import or variable
2. Review `src/Agent/Handler.al` line 156 - table migration needed

Once fixed, push changes to trigger rebuild.
```

## Multi-Project Handling

BCApps has multiple projects with dependencies. Handle them strategically:

### Build Dependency Order

**Level 1 (Build1):**
1. System Application
2. System Application Tests
3. System Application Modules

**Level 2 (Build):**
4. Apps (W1)
5. Business Foundation Tests
6. Performance Toolkit Tests

### Project-Specific Strategy

#### If errors in System Application:

```bash
# 1. Fix System Application errors first
# 2. Wait for Build1 to succeed
# 3. Then check Build job (Apps W1) errors

# Why: Apps (W1) depends on System Application
# Fixing base layer may resolve downstream errors
```

#### If errors in Apps (W1):

```bash
# 1. Verify System Application built successfully
# 2. Check if errors are due to missing dependencies
# 3. Fix app-specific errors

# Common issues:
# - Missing permission sets
# - Incorrect dependencies in app.json
# - Breaking changes from System Application
```

#### If errors in multiple projects:

```bash
# Process in dependency order:
# 1. System Application errors
# 2. System Application Tests errors
# 3. Apps (W1) errors
# 4. Test project errors

# Don't process in parallel - dependencies matter!
```

### Project Context in Error Logs

Error artifacts are project-specific:
- `Default-System Application-ErrorLogs-windows-latest/`
- `Default-Apps (W1)-ErrorLogs-windows-latest/`

Parse each project's errors separately:

```bash
# Identify which project failed
for dir in ./error-logs/*/; do
  PROJECT=$(basename "$dir" | sed 's/-ErrorLogs.*//')
  echo "Processing errors for project: $PROJECT"

  # Parse errors for this project
  find "$dir" -name "*.json" -exec jq -r '.runs[].results[]' {} \;
done
```

## Example Usage Scenarios

### Scenario 1: Pre-PR Validation

**Context:** Developer creates feature branch with new Agent functionality

**Invocation:**
```
@github-copilot build and fix any errors before I submit this PR
```

**Agent Actions:**
1. Check if build has run for this branch
2. If not, trigger build with empty commit
3. Wait for build completion (~10-15 minutes)
4. Download error artifacts
5. Parse SARIF logs: 15 CodeCop warnings found
6. Generate fixes for AL0606, AL0667 violations
7. Commit fixes: "Fix build errors - iteration 1"
8. Push to branch (triggers automatic rebuild)
9. Monitor new build: SUCCESS ✅
10. Report: "Fixed 15 code quality issues. Build is now passing!"

**Result:** Developer can create PR with confidence

### Scenario 2: Fixing Failed PR Build

**Context:** PR build failed in CI/CD with AppSourceCop breaking change errors

**Invocation:**
```
@github-copilot fix the build errors in this PR
```

**Agent Actions:**
1. Find failed workflow run for PR branch
2. Download error artifacts from run #12345
3. Parse errors: 3 breaking changes (AL0584 - field removed)
4. Analyze: Field 'Status Code' renamed to 'Status'
5. Generate fixes: Update all references to use new name
6. Commit fixes: "Fix build errors - iteration 1"
7. Push to PR branch
8. GitHub auto-triggers rebuild
9. Monitor build: SUCCESS ✅
10. Report: "Fixed 3 breaking change errors by updating field references"

**Result:** PR is unblocked, ready for review

### Scenario 3: Complex Multi-Error Fix

**Context:** PR has mix of syntax, semantic, and style errors across multiple files

**Invocation:**
```
@github-copilot build and fix any errors, iterate until clean
```

**Agent Actions:**

**Iteration 1:**
1. Download errors: 25 total (10 syntax, 8 semantic, 7 style)
2. Prioritize: Fix syntax errors first (block compilation)
3. Fix AL0132, AL0185 in 5 files
4. Commit: "Fix build errors - iteration 1 (10 syntax errors)"
5. Push → Rebuild

**Iteration 2:**
1. Download errors: 15 remaining (8 semantic, 7 style)
2. Fix AL0118, AL0254 (undefined variables)
3. Commit: "Fix build errors - iteration 2 (8 semantic errors)"
4. Push → Rebuild

**Iteration 3:**
1. Download errors: 7 remaining (all style)
2. Fix AL0606, AL0667 (code quality)
3. Commit: "Fix build errors - iteration 3 (7 style violations)"
4. Push → Rebuild

**Final:**
1. Build: SUCCESS ✅
2. Report summary:
   ```
   ✅ Build succeeded after 3 iterations!

   Fixed 25 errors total:
   - Iteration 1: 10 syntax errors
   - Iteration 2: 8 semantic errors
   - Iteration 3: 7 code quality violations

   Files modified:
   - src/Agent/AgentTask.al
   - src/Agent/AgentScheduler.Codeunit.al
   - src/Agent/Permissions/AgentPerm.PermissionSet.al
   ```

**Result:** All errors fixed, build passing

### Scenario 4: Unfixable Errors

**Context:** PR has complex breaking changes requiring migration knowledge

**Invocation:**
```
@github-copilot fix the build errors
```

**Agent Actions:**
1. Download errors: 5 breaking changes (AL0534 - object deleted)
2. Analyze: Table 'Old Agent Task' deleted, replaced with 'Agent Task'
3. Attempt automated fix: Update table references
4. Commit & push → Rebuild
5. New errors: References still broken (complex dependencies)
6. Iteration 2: Try additional fixes
7. Commit & push → Rebuild
8. Still failing: Same errors persist
9. Max iterations reached

**Report:**
```
❌ Unable to fix all errors after 3 iterations

Remaining errors require manual intervention:
- AL0534 in multiple files: Table migration needed
- Complex refactoring required (not suitable for automation)

Suggested actions:
1. Review migration guide for 'Old Agent Task' → 'Agent Task'
2. Update app.json dependencies
3. Refactor related codeunits to use new table structure

Errors fixed:
- Iteration 1: Updated basic table references (3 files)

Manual review required for:
- src/Agent/Migration/*.al (5 files)
```

**Result:** Agent reports limitations, guides developer

## Workflow Integration

### PR Check Integration

The agent complements existing PR checks:

**Standard PR Checks:**
1. ✅ Code review approval
2. ✅ Unit tests passing
3. ✅ Build succeeding ← **BuildFix Agent helps here**
4. ✅ No merge conflicts

**With BuildFix Agent:**
- Developer invokes agent from PR comment
- Agent fixes build errors automatically
- PR status updates to ✅
- Reviewers see clean build + fix commits

### Commit Attribution

All agent commits include co-author attribution:

```
Fix build errors - iteration 1

Automatically fixed 8 code quality violations:
- AL0606: Use explicit 'to' parameter (5 occurrences)
- AL0667: Use FieldClass Normal (3 occurrences)

Co-Authored-By: BuildFix Agent <noreply@github.com>
```

This makes it clear which changes were automated vs. manual.

## Limitations and Constraints

### What the Agent Can Do

✅ Fix common syntax errors (missing semicolons, brackets)
✅ Fix semantic errors (undefined variables, basic type issues)
✅ Fix code quality violations (CodeCop rules)
✅ Update simple API references (field renames, method changes)
✅ Add missing attributes (FieldClass, InitValue)
✅ Iterate on fixes up to 3 times

### What the Agent Cannot Do

❌ Understand business logic or requirements
❌ Fix complex breaking changes requiring architecture knowledge
❌ Make design decisions (which pattern to use)
❌ Test functional correctness (only compilation)
❌ Debug runtime errors
❌ Optimize performance
❌ Resolve merge conflicts

### When to Use the Agent

**Good Use Cases:**
- Pre-PR validation (catch errors early)
- Fixing simple build failures (syntax, style)
- Cleaning up code quality violations
- Speeding up fix-commit-push cycles

**Poor Use Cases:**
- Major refactoring or redesign
- Complex API migrations
- Security-sensitive changes
- Performance optimization
- Logic bugs

### Performance Considerations

**Build Time:**
- Full BCApps build: ~10-15 minutes per iteration
- Maximum 3 iterations = ~45 minutes total
- Factor in queue time for GitHub Actions runners

**Agent Invocation Cost:**
- Each invocation uses GitHub Copilot API credits
- Larger projects = more errors = more LLM calls
- Consider batching fixes to minimize iterations

## Success Criteria

### Iteration Success

An iteration is successful if:
1. ✅ Errors parsed correctly from SARIF
2. ✅ Fixes generated without introducing new errors
3. ✅ Fixes committed to PR branch
4. ✅ Rebuild triggered automatically
5. ✅ Error count decreased vs. previous iteration

### Overall Success

The agent invocation is successful if:
1. ✅ Build passes after ≤3 iterations
2. ✅ All auto-fixable errors resolved
3. ✅ No regressions introduced
4. ✅ Commit history is clean and reviewable
5. ✅ Clear status reported to user

### Failure Conditions

The agent should fail gracefully if:
1. ❌ Unable to download error artifacts
2. ❌ SARIF parsing fails (malformed JSON)
3. ❌ Cannot write files (permissions issue)
4. ❌ Git operations fail (conflicts, auth)
5. ❌ Max iterations reached without success
6. ❌ Error count increases (fixes make things worse)

## Technical Implementation Notes

### Required Dependencies

The agent execution environment must have:

```bash
# Core tools
git --version          # Git CLI
gh --version           # GitHub CLI (authenticated)
jq --version           # JSON parsing
curl --version         # HTTP requests

# Optional (for advanced parsing)
python3 --version      # Python 3.x
node --version         # Node.js (if needed)
```

### Environment Variables

Agent may need access to:

```bash
GITHUB_TOKEN           # For GitHub API authentication
GITHUB_REPOSITORY      # Owner/repo (e.g., microsoft/BCApps)
GITHUB_REF             # Branch being built
PR_NUMBER              # Pull request number (if in PR context)
```

### File System Access

Agent needs read/write access to:
- Repository files: `src/**/*.al`, `build/**/*`
- Temporary directory: `./error-logs/`
- Git working directory: `.git/`

### Network Access

Agent needs outbound access to:
- `github.com` - GitHub API
- `api.github.com` - REST API
- GitHub Actions runners (for artifact download)

## Monitoring and Observability

### Agent Execution Logs

Log key events during execution:

```bash
echo "[$(date -Iseconds)] Starting BuildFix Agent"
echo "[$(date -Iseconds)] Branch: $BRANCH"
echo "[$(date -Iseconds)] PR: #$PR_NUMBER"
echo "[$(date -Iseconds)] Iteration $ITERATION/$MAX_ITERATIONS"
echo "[$(date -Iseconds)] Downloaded errors: $ERROR_COUNT"
echo "[$(date -Iseconds)] Fixed errors: $FIXED_COUNT"
echo "[$(date -Iseconds)] Build status: $CONCLUSION"
```

### Metrics to Track

For analyzing agent effectiveness:

- **Invocation count**: How often agent is used
- **Success rate**: Builds fixed / total invocations
- **Iterations per success**: Average iterations needed
- **Error types fixed**: Breakdown by AL code
- **Time to fix**: Duration from invocation to success
- **Files modified**: Number of files touched per fix

### Error Categories

Track which errors are fixable vs. manual:

| Category | Auto-Fixable | Requires Manual |
|----------|--------------|-----------------|
| Syntax (AL01xx) | 90% | 10% |
| Semantic (AL02xx) | 70% | 30% |
| Breaking (AL05xx) | 30% | 70% |
| Style (AL06xx) | 95% | 5% |
| UI (AL07xx) | 80% | 20% |

## Future Enhancements

Potential improvements (out of scope for initial version):

1. **Learning from Fixes:**
   - Build database of common error patterns
   - Store successful fix templates
   - Improve fix quality over time

2. **Proactive Invocation:**
   - Automatically trigger on PR creation
   - Run in pre-commit hook (local dev)
   - Integrate with GitHub Copilot Workspace

3. **Advanced Error Handling:**
   - Support for complex breaking changes
   - Cross-file refactoring
   - Dependency resolution

4. **Developer Experience:**
   - Real-time status updates in PR comments
   - Interactive fix review before commit
   - Dry-run mode (preview fixes without applying)

5. **Performance Optimization:**
   - Parallel error fixing (multiple files)
   - Incremental builds (only changed projects)
   - Caching of common fixes

6. **Integration:**
   - VS Code extension for local use
   - Azure DevOps pipeline support
   - Slack notifications for build status

## Appendix: Key File References

### Configuration Files

- `.github/AL-Go-Settings.json` - Global AL-Go configuration
- `.github/workflows/PullRequestHandler.yaml` - PR build workflow
- `.github/workflows/_BuildALGoProject.yaml` - Project build workflow
- `src/rulesets/ruleset.json` - Custom analyzer rules

### Project Definitions

- `build/projects/System Application/.AL-Go/settings.json`
- `build/projects/Apps (W1)/.AL-Go/settings.json`
- `build/projects/*/app.json` - App manifests

### Build Scripts

- `build/scripts/CompileAppInBcContainer.ps1` - Compilation
- `build/scripts/PreCompileApp.ps1` - Pre-compilation
- `build/scripts/NewBcContainer.ps1` - Container setup

### Documentation

- `README.md` - Repository overview
- `build/README.md` - Build system documentation
- `.github/agents/README.md` - Agent framework documentation (if exists)

## Support and Troubleshooting

### Common Issues

**Issue: "gh: command not found"**
- **Solution:** GitHub CLI not installed. Agent requires `gh` CLI.

**Issue: "Permission denied when downloading artifacts"**
- **Solution:** Check `GITHUB_TOKEN` has `actions: read` permission.

**Issue: "Build takes too long (timeout)"**
- **Solution:** BCApps builds are large (~15 min). Adjust timeout or use cached builds.

**Issue: "Fixes introduce new errors"**
- **Solution:** Agent will rollback. Check if errors require domain knowledge.

**Issue: "Cannot parse SARIF file"**
- **Solution:** Verify error log artifacts are valid JSON. May be malformed.

### Getting Help

If the agent encounters issues:

1. **Check agent execution logs** for error messages
2. **Review workflow run logs** in GitHub Actions UI
3. **Inspect error artifacts** manually (download and open JSON)
4. **File issue** in BCApps repository with:
   - PR number
   - Workflow run ID
   - Error logs
   - Agent invocation command

### Debugging Tips

**Enable verbose logging:**
```bash
set -x  # Enable bash debug mode
gh run download "$RUN_ID" --pattern '*-ErrorLogs-*' --dir ./error-logs --verbose
```

**Validate SARIF manually:**
```bash
# Check if SARIF is valid JSON
jq empty error-log.json && echo "Valid JSON" || echo "Invalid JSON"

# Validate against SARIF schema
curl -s https://json.schemastore.org/sarif-2.1.0.json | jq empty
```

**Test fix locally (if Windows available):**
```bash
# Compile AL code locally
powershell -File build/scripts/CompileAppInBcContainer.ps1 -appFolder "src/Agent"
```

---

## Agent Invocation Summary

**Invoke the agent from GitHub.com PR interface:**

```
@github-copilot build and fix any errors
@github-copilot fix the build errors in this PR
@github-copilot check if this builds and fix any errors
```

**What the agent does:**
1. ✅ Triggers AL-Go build workflow
2. ✅ Monitors build execution
3. ✅ Downloads error artifacts
4. ✅ Parses SARIF error logs
5. ✅ Generates AL code fixes
6. ✅ Commits and pushes fixes
7. ✅ Iterates until build passes (max 3 times)
8. ✅ Reports status and results

**Agent execution environment:**
- 🐧 Linux (GitHub Copilot session)
- 🔧 Tools: bash, git, gh CLI, jq
- 🏗️ Builds run on: Windows runners (GitHub Actions)

**Success criteria:**
- ✅ Build passes after fixes
- ✅ No regressions introduced
- ✅ Clear commit history
- ✅ Reviewable changes

Now the agent is ready to assist with build-fix automation! 🚀

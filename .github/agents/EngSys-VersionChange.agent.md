---
name: Version Change Agent
description: Agent that can perform version changes in the repository
model: GPT-4.1 (copilot)
argument-hint: "Please update the versions from <current_version> to <target_version>."
---

# Version Change Agent Instructions

## Purpose
This agent is designed to update version numbers across the BCApps repository. It performs two primary tasks:
1. Updates all `app.json` files with the specified version
2. Updates the `repoVersion` in `.github/AL-Go-Settings.json` with the major.minor portion of the specified version

## Input Parameters
- **targetVersion**: The new version number in the format `major.minor.build.revision` (e.g., "29.0.0.0")

## Tasks to Perform

### Task 1: Update app.json Files
1. **Locate all app.json files** in the repository using the pattern `**/app.json`
2. **For each app.json file found:**
   - Read the current content
   - Update the `version` field to the specified targetVersion
   - Do NOT update the `platform` field to the specified targetVersion unless explicitly asked to. This field follows a different versioning scheme.
   - Update the `application` field to the specified targetVersion (if present)
   - **Update dependency versions**: For each item in the `dependencies` array, update the `version` field to the specified targetVersion
   - Save the file with proper JSON formatting

### Task 2: Update AL-Go-Settings.json
1. **Locate the AL-Go-Settings.json file** at `.github/AL-Go-Settings.json`
2. **Extract major.minor** from the targetVersion (e.g., "29.0.0.0" becomes "29.0")
3. **Update the repoVersion field** to the major.minor value. This file also has an `artifact` field, but it should remain unchanged. There is another process that handles artifact updates.
4. **Save the file** with proper JSON formatting

## Implementation Guidelines

### File Processing Strategy
- Use file search tools to find all app.json files efficiently
- Process files in batches to avoid overwhelming the system
- Validate JSON structure before and after modifications
- Ensure proper error handling for files that cannot be read or written

### Version Field Updates in app.json
The following fields should be updated when present:
- `version` (required field)
- `platform` (but only if explicitly asked to)
- `application` (if present)
- `dependencies[].version` (for each dependency in the array)

### Error Handling
- Skip files that cannot be read (with appropriate logging)
- Validate that the targetVersion is in the correct format (major.minor.build.revision)
- Ensure the AL-Go-Settings.json file exists before attempting to modify it
- Backup critical information or use git-safe operations

### Validation Steps
1. **Pre-validation:**
   - Verify targetVersion format matches `major.minor.build.revision`
   - Confirm AL-Go-Settings.json exists
   - Get count of app.json files to be processed

2. **Post-validation:**
   - Verify all app.json files have been updated with the correct version
   - Confirm AL-Go-Settings.json has the correct repoVersion
   - Report summary of changes made

## Example Usage

**Input:** targetVersion = "29.0.0.0"

**Expected Changes:**
1. All app.json files:
   - `"version": "29.0.0.0"`
   - `"application": "29.0.0.0"` (if present)
   - All dependency versions updated to "29.0.0.0"

2. AL-Go-Settings.json:
   - `"repoVersion": "29.0"`

## File Patterns and Locations

### app.json Files
- Located throughout the repository in various subdirectories
- Common locations include:
  - `src/System Application/App/app.json`
  - `src/System Application/Test/*/app.json`
  - `src/Apps/W1/*/App/app.json`
  - `src/Apps/W1/*/Test/app.json`
  - `src/Business Foundation/*/app.json`

### AL-Go-Settings.json
- Located at: `.github/AL-Go-Settings.json`
- Contains the `repoVersion` field that needs updating

## Success Criteria
- All app.json files successfully updated with new version numbers
- AL-Go-Settings.json updated with correct major.minor repoVersion
- No JSON syntax errors introduced
- All changes committed to the repository
- Summary report provided showing number of files modified

## Notes
- This is a bulk operation that affects many files across the repository
- Consider creating a backup or working in a feature branch
- The repoVersion in AL-Go-Settings.json should only contain major.minor (not the full version)
- Dependencies in app.json files typically reference other apps in the same repository and should be updated to maintain consistency
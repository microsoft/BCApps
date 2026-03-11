# GitHub Project Integration - Quick Reference

**Project:** CampAIR Teams Inspection App  
**Project #:** 110  
**Organization:** gim-home  
**Repository:** gim-home/ai-first
**Project URL:** https://github.com/orgs/gim-home/projects/110

---

## 🎯 The Rules (from copilot-instructions.md)

### **CRITICAL: Always Sync Tasks with GitHub Project #110**

When working on ANY task:

1. **BEFORE starting work:** Create issue → Add to project → Mark "In Progress"
2. **WHILE working:** Update issue with progress comments
3. **AFTER completing:** Add completion notes → Close issue → Verify moved to "Done"

**NEVER skip these steps!** Desynchronized project boards = lost tracking.

---

## 🚀 Quick Workflows

### **Workflow 1: Starting a New Task**

```powershell
# Step 1: Create issue and add to project
.\scripts\manage-project-issues.ps1 -Action create `
    -TaskId "2.1.1" `
    -Title "Create Teams Tab project" `
    -Description "## Task Description
From PRDs/inspections/TASKS.md - Phase 2: Core Teams Tab Development

Scaffold the Teams Tab project using Teams Toolkit.

## Acceptance Criteria
- [ ] Teams Tab project created
- [ ] React + TypeScript template configured
- [ ] App manifest configured
- [ ] Device permissions added

## References
- See: PRDs/inspections/TASKS.md line 87
- See: PRDs/inspections/design.md"

# Output will give you the issue number (e.g., #36)

# Step 2: Mark as "In Progress" (when you start working)
.\scripts\manage-project-issues.ps1 -Action start -IssueNumber 36

# Step 3: Do the work...

# Step 4: Update TASKS.md to mark task complete

# Step 5: Mark issue as complete
.\scripts\manage-project-issues.ps1 -Action complete `
    -IssueNumber 36 `
    -Description "✅ Teams Tab project scaffolded successfully.

Created using Teams Toolkit with:
- React + TypeScript template
- App name: AI-First Inspections
- Device permissions: media

Next: Configure frontend architecture (Task 2.1.2)"
```

---

### **Workflow 2: Completing an Already-Started Task**

If you forgot to create the issue before starting work:

```powershell
# Step 1: Create issue for completed work
$description = @"
## Task Description
[Describe what was done]

## Acceptance Criteria
- [x] Criterion 1 met
- [x] Criterion 2 met

## Status
✅ COMPLETE - $(Get-Date -Format 'yyyy-MM-dd')

## References
- See: [reference to files/docs created]
"@

.\scripts\manage-project-issues.ps1 -Action create `
    -TaskId "1.1.2" `
    -Title "Install development tools" `
    -Description $description

# Note the issue number from output (e.g., #35)

# Step 2: Immediately close it as complete
.\scripts\manage-project-issues.ps1 -Action complete `
    -IssueNumber 35 `
    -Description "Task completed. All tools verified and documented."
```

---

### **Workflow 3: Verifying Synchronization**

Check that issues and project board are in sync:

```powershell
# View recent project items and issues
.\scripts\manage-project-issues.ps1 -Action verify

# Or manually check
gh project item-list 110 --owner gim-home --limit 10
gh issue list --repo gim-home/CampAIR-ERP --limit 10
```

---

## 🛠️ Manual Commands (if script unavailable)

### Create Issue and Add to Project
```powershell
# Create issue
$issueUrl = gh issue create `
    --repo gim-home/CampAIR-ERP `
    --title "Task X.Y.Z: Description" `
    --body "Task details..."

# Extract issue number
$issueUrl -match "/issues/(\d+)"
$issueNumber = $Matches[1]

# Add to project (REQUIRED!)
gh project item-add 110 --owner gim-home --url $issueUrl

# Verify
gh project item-list 110 --owner gim-home --limit 5
```

### Mark In Progress
```powershell
gh issue comment <ISSUE_NUMBER> --repo gim-home/CampAIR-ERP `
    --body "🚀 Started working on this task. Status: In Progress"

# Then manually move card in project board UI
```

### Mark Complete
```powershell
# Add completion comment
gh issue comment <ISSUE_NUMBER> --repo gim-home/CampAIR-ERP `
    --body "✅ Task completed. [completion notes]"

# Close issue
gh issue close <ISSUE_NUMBER> --repo gim-home/CampAIR-ERP --reason completed

# Verify it moved to Done column
gh project item-list 110 --owner gim-home --limit 5
```

---

## 📋 Issue Template

When creating issues, use this format:

```markdown
## Task Description
From PRDs/inspections/TASKS.md - Phase X: [Phase Name]

[Brief description of what needs to be done]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Details
[Any relevant technical information]

## Dependencies
- Depends on: #[issue number]
- Blocks: #[issue number]

## Estimated Effort
[Time estimate from TASKS.md]

## References
- See: PRDs/inspections/TASKS.md line [X]
- See: PRDs/inspections/design.md
- See: [other relevant files]
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ **DON'T: Skip adding issue to project**
```powershell
# WRONG - creates orphaned issue
gh issue create --repo gim-home/CampAIR-ERP --title "Task X"
# Issue exists but NOT in project board!
```

✅ **DO: Always add to project immediately**
```powershell
# CORRECT
$issueUrl = gh issue create --repo gim-home/CampAIR-ERP --title "Task X" --body "..."
gh project item-add 110 --owner gim-home --url $issueUrl
```

### ❌ **DON'T: Complete work without tracking**
```powershell
# WRONG - no GitHub issue created
# Just mark [x] in TASKS.md and commit
```

✅ **DO: Create issue even for completed work**
```powershell
# CORRECT - retrospectively create and close issue
.\scripts\manage-project-issues.ps1 -Action create -TaskId "X.Y.Z" -Title "..." -Description "..."
.\scripts\manage-project-issues.ps1 -Action complete -IssueNumber XX -Description "Already completed"
```

### ❌ **DON'T: Forget to verify**
```powershell
# WRONG - assume it worked without checking
```

✅ **DO: Always verify after adding to project**
```powershell
# CORRECT
gh project item-list 110 --owner gim-home --limit 5
```

---

## 🔧 Troubleshooting

### Issue: "Authentication required"
```powershell
# Check auth status
gh auth status

# If missing 'project' scope:
gh auth refresh -s project
```

### Issue: "Could not add label: 'X' not found"
```powershell
# Labels don't exist yet - skip them
# Use --label only if labels are created in repository
```

### Issue: "Project not found"
```powershell
# Verify project number
gh project list --owner gim-home

# Should show: #110 - [Project Name]
```

### Issue: Script won't run
```powershell
# Check execution policy
Get-ExecutionPolicy

# If Restricted, set to RemoteSigned
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## 📊 Verification Checklist

After any task-related operation, verify:

- [ ] Issue exists in repository: `gh issue view <NUMBER> --repo gim-home/CampAIR-ERP`
- [ ] Issue appears in Project #110: `gh project item-list 110 --owner gim-home`
- [ ] Issue has correct status (Open/In Progress/Closed)
- [ ] Issue is in correct project board column
- [ ] TASKS.md is updated with `[x]` checkbox
- [ ] design.md is updated with any design decisions

---

## 🎓 Learning Resources

- **GitHub CLI Manual:** https://cli.github.com/manual/
- **GitHub Projects Docs:** https://docs.github.com/en/issues/planning-and-tracking-with-projects
- **Project Integration Rules:** See `.github/copilot-instructions.md`

---

## 📞 Getting Help

If synchronization issues occur:

1. **Check project board manually:** https://github.com/orgs/gim-home/projects/110
2. **Verify issue exists:** `gh issue view <NUMBER> --repo gim-home/CampAIR-ERP`
3. **Re-add to project if needed:** `gh project item-add 110 --owner gim-home --url <ISSUE_URL>`
4. **Ask team lead** if problems persist

---

## 🚨 Emergency: Bulk Fix Desynchronization

If multiple issues are orphaned (not in project):

```powershell
# List all open issues
gh issue list --repo gim-home/CampAIR-ERP --limit 50 --json number,url

# Add each to project
$issues = gh issue list --repo gim-home/CampAIR-ERP --limit 50 --json number,url | ConvertFrom-Json
foreach ($issue in $issues) {
    Write-Host "Adding issue #$($issue.number) to project..."
    gh project item-add 110 --owner gim-home --url $issue.url
    Start-Sleep -Seconds 1
}
```

---

**Remember:** Keeping GitHub Project #110 synchronized is **CRITICAL** for project management. Make it a habit!

---

**Last Updated:** December 3, 2025 by gregrata  
**Maintained By:** Greg Ratajik

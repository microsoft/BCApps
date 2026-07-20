# Test MIAPP Skill Procedure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an empty public `TestMiAppSkill()` procedure to the W1 VAT VIES declaration report.

**Architecture:** Extend report 19 with one parameterless global procedure beside its existing public initialization procedure. The new procedure has no state, dependencies, return value, or runtime behavior.

**Tech Stack:** AL, Business Central W1 BaseApp, AL compiler

---

### Task 1: Add the global procedure

**Files:**
- Modify: `src/Layers/W1/BaseApp/Finance/VAT/Reporting/VATVIESDeclarationTaxAuth.Report.al:338-346`

- [ ] **Step 1: Confirm the procedure does not already exist**

Run:

```powershell
rg -n "procedure TestMiAppSkill" src\Layers\W1\BaseApp\Finance\VAT\Reporting\VATVIESDeclarationTaxAuth.Report.al
```

Expected: no matches.

- [ ] **Step 2: Add the minimal procedure**

Insert the following procedure after `InitializeRequest` and before the report's closing brace:

```al
    procedure TestMiAppSkill()
    begin
    end;
```

- [ ] **Step 3: Compile the W1 BaseApp**

Resolve the local W1 AL environment with `bc-al-localenv`, configure the AL MCP server with `bc-al-mcp`, and compile the W1 BaseApp.

Expected: compilation succeeds with no diagnostics introduced by `TestMiAppSkill`.

- [ ] **Step 4: Inspect the final diff**

Run:

```powershell
git diff -- src\Layers\W1\BaseApp\Finance\VAT\Reporting\VATVIESDeclarationTaxAuth.Report.al
```

Expected: the only source change is the empty global `TestMiAppSkill()` procedure.

- [ ] **Step 5: Commit the implementation**

Run:

```powershell
git add -- src\Layers\W1\BaseApp\Finance\VAT\Reporting\VATVIESDeclarationTaxAuth.Report.al
git commit -m "Add TestMiAppSkill procedure" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" -m "Copilot-Session: 45383397-1497-4059-8618-b32ee4008bc6"
```

Expected: one commit containing only the W1 report source change.

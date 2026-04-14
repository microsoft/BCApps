---
description: >
  Evaluate merged AL code changes for user-facing significance and
  update the Early Access Preview features list with a new entry.

permissions:
  contents: write
  pull-requests: write

tools:
  bash: ["pwsh", "gh"]

safe-outputs: true

on:
  # push:
  #   branches: [main]
  #   paths: ["**/*.al"]
  workflow_dispatch:
    inputs:
      commit_sha:
        description: "Commit SHA to re-evaluate (leave empty for HEAD)"
        required: false
        type: string

engine:
  id: copilot
---

# Update early access preview features

You are an agent that evaluates AL code merges to determine if they introduce a user-facing feature worth highlighting in the Business Central Early Access Preview list.

## Step 1: Get the commit diff

Determine which commit to evaluate:

- For `push` triggers, use the triggering commit SHA from `${{ github.sha }}`.
- For `workflow_dispatch`, use the `commit_sha` input if provided; otherwise use HEAD on main.

Get the full diff:

```bash
git show --stat --patch <sha>
```

Also get the commit message and any associated PR information:

```bash
git log -1 --format="%s%n%n%b" <sha>
gh pr list --search "<sha>" --state merged --json number,title,body,labels --limit 1
```

Extract the ADO work item reference from the merged PR body. Look for a line matching `Fixes AB#<number>` (e.g., `Fixes AB#630657`). Save this reference -- you will include it in the new PR you create in Step 8.

### Skip conditions

Stop and call `noop` with a brief explanation if any of these apply:

- The PR has the label **eap-skip**.
- The diff only touches test files (`*.Test.al`, `*Test*.Codeunit.al`).
- The diff only touches permission sets (`.xml` files in `Permissions/` folders).
- The diff only touches build or workflow files (no `.al` changes).

## Step 2: Evaluate significance

Read the full diff carefully. Determine whether this change is **significant enough to list** as an early access preview feature.

### List it when the change introduces

- New pages or page extensions with user-facing actions or fields
- New document flows, posting logic, or business process changes
- New integration capabilities (Shopify connectors, external service hooks, Power BI reports)
- Significant workflow or approval changes
- New fields that fundamentally change how users interact with a feature area

### Skip it when the change is

- A bug fix (even a complex one) - unless it dramatically changes user behavior
- Internal refactoring with no visible user impact
- Test additions or modifications only
- Permission set changes only
- Build, infrastructure, or tooling changes
- Minor UI adjustments (tooltip rewording, caption changes, small layout tweaks)
- Codeunit-only changes that don't affect pages or user interactions

**Use your judgment.** The bar is: "Would an early access user want to know about this so they can try it and give feedback?" If unsure, lean toward skipping - it's better to miss a borderline change than to flood the list with noise.

If the change is **not significant**, call `noop` with a one-sentence explanation of why you skipped it (e.g., "Bug fix to purchase invoice posting - no new user-facing feature.").

## Step 3: Read existing features and check for duplicates

Read the current features list:

```bash
cat "src/System Application/App/Resources/Files/EarlyAccessPreviewFeatures.json"
```

Check if a similar feature already exists. Normalize both the existing `FeatureName` values and your proposed title (lowercase, trim whitespace) before comparing. Also check if the concept is already covered even if the wording differs.

If a duplicate exists, call `noop` with a brief explanation.

## Step 4: Determine the functional domain and PM

Match the changed file paths against the domain table below. Domains are listed in order of specificity -- check more specific patterns first. Use the keywords for ambiguous cases.

| Domain | PM | Code paths | Keywords |
|--------|-----|-----------|----------|
| Shopify | @Aleyenda | `src/Apps/W1/Shopify/**` | shopify, e-commerce, shop card |
| Power BI reports | @KennieNP | `src/Apps/W1/PowerBIReports/**`, `src/**/PowerBI/**` | power bi, report, dashboard, KPI |
| Finance | @soenfriisalexandersen | `src/**/Finance/**`, `src/**/General Ledger/**`, `src/**/General Journal/**`, `src/**/Fixed Asset*/**`, `src/**/Bank*/**`, `src/**/Cash*/**`, `src/**/VAT*/**`, `src/**/Tax*/**`, `src/**/Deferral*/**`, `src/**/Dimension*/**`, `src/**/Cost Accounting/**`, `src/**/Consolidation/**`, `src/**/Intercompany/**`, `src/**/Sustainability/**`, `src/**/Receivables/**`, `src/**/Payables/**`, `src/**/Reminder*/**`, `src/**/Finance Charge*/**`, `src/Apps/W1/SubscriptionBilling/**`, `src/Apps/W1/AutomaticAccountCodes/**` | finance, GL, journal, fixed asset, bank, VAT, tax, dimension, budget, sustainability, ESG |
| Purchasing | @AndreiPanko | `src/**/Purchasing/**`, `src/**/Purchase*/**`, `src/**/Vendor*/**`, `src/**/Drop Shipment*/**`, `src/**/Incoming Document*/**` | purchase, vendor, procurement, drop shipment |
| Sales | @AndreiPanko | `src/**/Sales/**`, `src/**/Sales*/**`, `src/**/Customer*/**`, `src/**/Shipping*/**` | sales, customer, shipping, blanket order |
| Inventory | @AndreiPanko | `src/**/Inventory/**`, `src/**/Item*/**`, `src/**/Stockkeeping*/**`, `src/**/Location*/**`, `src/**/Transfer*/**`, `src/**/Warehouse*/**`, `src/**/Bin*/**`, `src/**/Requisition*/**`, `src/**/Planning*/**` | inventory, item, warehouse, bin, item tracking, planning, MRP |
| Manufacturing | @AndreiPanko | `src/**/Manufacturing/**`, `src/**/Production*/**`, `src/**/Assembly*/**`, `src/**/Routing*/**`, `src/**/Work Center*/**`, `src/**/Machine Center*/**`, `src/**/Capacity*/**` | manufacturing, production, assembly, BOM, routing |
| Service management | @AndreiPanko | `src/**/Service*/**` | service, service order, service contract |
| CRM | @AndreiPanko | `src/**/CRM/**`, `src/**/Contact*/**`, `src/**/Opportunity*/**`, `src/**/Campaign*/**` | CRM, contact, opportunity, campaign |
| Projects | @AndreiPanko | `src/**/Job*/**`, `src/**/Project*/**`, `src/**/Resource*/**` | job, project, resource, time sheet, WIP |
| Integrations | @Aleyenda | `src/System Application/**`, `src/Business Foundation/**`, `src/**/E-Document*/**`, `src/**/Dataverse*/**`, `src/**/API*/**`, `src/**/Data Exchange*/**`, `src/**/Workflow/**`, `src/**/Job Queue/**`, `src/**/Email*/**`, `src/**/Feature Management/**`, `src/**/Migration*/**`, `src/**/Onboarding*/**` | system application, e-document, dataverse, API, workflow, job queue |

Identify:

- The **domain name** (used as the `Category`)
- The **PM GitHub handle** (used to assign the PR)

If the change spans multiple domains, pick the primary one based on where most of the diff is concentrated.

If no domain matches, use "Other" as the category and assign the PR to `@AndreiPanko` as the default PM.

## Step 5: Generate the JSON entry

Create a new entry following this exact structure:

```json
{
    "FeatureName": "<public-friendly title>",
    "Description": "<detailed description>",
    "Category": "<domain from step 4>",
    "HelpURL": "",
    "VideoURL": ""
}
```

### FeatureName rules

- Write a clear, public-friendly title (not the PR title verbatim)
- Use sentence case
- Be specific about what the feature does
- Keep it under 100 characters

### Description rules

Write the description following these guidelines based on existing entries:

- **Lead with what it does and why it matters.** Start with a sentence explaining the capability and its business value.
- **Include specific BC page names in quotes.** For example: Open the "Purchase Order" page.
- **Reference specific fields and actions.** Mention the exact field names, action buttons, or menu items users interact with.
- **Provide step-by-step instructions.** Use phrases like "To get started, open the...", "Start by reviewing the...", "Use the ... action to..."
- **Use second person.** Write "you can", "start by", not "users can".
- **Stay under 250 words.**
- **Avoid internal or technical jargon.** Write for a business user, not a developer.

If the diff doesn't provide enough detail to write step-by-step instructions, write a shorter summary focusing on what changed and why it matters. Don't invent UI details that aren't in the code.

### Example entries for tone reference

> **FeatureName**: "Post purchase invoices for drop shipments independently of related sales invoices"
> **Description**: "This feature lets you post purchase invoices for drop shipment orders even if the related sales invoice hasn't been posted yet, supporting workflows where vendor invoicing and customer billing happen at different times. To use it, open the Purchase Order with drop shipment lines and post the invoice directly. You can also use the \"Get receipt lines\" action in the purchase invoice to invoice received drop shipment lines."

> **FeatureName**: "Send Posted Sales Shipments and Return Receipts via Email"
> **Description**: "Enable users to email posted sales shipments and return receipts directly from Business Central. This helps businesses deliver critical shipment documents quickly and improves customer communication. To get started, open the Posted Sales Shipment or Posted Return Receipt pages and use the \"Send by Email\" or \"Send\" actions."

## Step 6: Build the updated JSON

Add your new entry to the existing array. If the array contains only a placeholder entry (a `FeatureName` starting with "No features listed yet for the"), remove the placeholder before adding yours.

Ensure the JSON uses:

- 4-space indentation
- Each property on its own line
- A trailing newline at end of file

## Step 7: Validate

Validate the updated JSON by running this inline PowerShell script:

```bash
pwsh -NoProfile -Command '
$ErrorActionPreference = "Stop"
$path = "src/System Application/App/Resources/Files/EarlyAccessPreviewFeatures.json"
$content = Get-Content -Path $path -Raw -Encoding UTF8
$features = @($content | ConvertFrom-Json)
if ($features -isnot [System.Array]) { Write-Error "JSON root must be an array."; exit 1 }
$requiredFields = @("FeatureName","Description","Category","HelpURL","VideoURL")
$placeholderPrefix = "No features listed yet for the"
$seenNames = @{}; $errors = @()
for ($i = 0; $i -lt $features.Count; $i++) {
    $entry = $features[$i]; $label = "Entry $($i+1)"
    foreach ($f in $requiredFields) { if ($null -eq $entry.$f) { $errors += "$label missing $f" } }
    $fn = $entry.FeatureName
    if ($null -ne $fn) {
        $isPH = $fn.StartsWith($placeholderPrefix)
        if (-not $isPH -and [string]::IsNullOrWhiteSpace($fn)) { $errors += "$label empty FeatureName" }
        $d = $entry.Description
        if (-not $isPH -and $null -ne $d -and [string]::IsNullOrWhiteSpace($d)) { $errors += "$label empty Description" }
        if (-not [string]::IsNullOrWhiteSpace($fn)) {
            $norm = $fn.Trim().ToLowerInvariant()
            if ($seenNames.ContainsKey($norm)) { $errors += "$label duplicate: $fn" }
            else { $seenNames[$norm] = $i+1 }
        }
    }
}
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Output "Validation passed. $($features.Count) feature(s) found."
'
```

If validation fails, fix the JSON and re-validate. Do not proceed until validation passes.

## Step 8: Create a branch and PR

Create a feature branch, commit, and open a PR:

```bash
git checkout -b eap/add-<short-kebab-name>
git add "src/System Application/App/Resources/Files/EarlyAccessPreviewFeatures.json"
git commit -m "Add EAP entry: <FeatureName>"
git push origin eap/add-<short-kebab-name>
```

Create the PR:

```bash
gh pr create \
  --title "Add EAP entry: <FeatureName>" \
  --body "<PR body>" \
  --base main \
  --reviewer "<PM handle from step 4>"
```

The PR body should include:

- The feature name and description
- The source commit SHA that triggered this
- The domain and category
- The ADO work item reference (`Fixes AB#...`) from the source PR
- A note that this was auto-generated by the EAP updater agent

### PR body template

```markdown
## New early access preview feature

**Feature**: <FeatureName>
**Category**: <Category>
**Source commit**: <SHA>

### Description

<Description text>

---

Fixes AB#<number from source PR>

*This PR was automatically generated by the EAP Features Updater agent.
Please review the feature name and description, then approve or suggest edits.*
```

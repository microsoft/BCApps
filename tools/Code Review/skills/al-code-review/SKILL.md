---
name: al-code-review
description: 'Review AL code for Dynamics 365 Business Central across specialized domains. Supports domain-specific analysis (security, performance, style, accessibility, upgrade, privacy) with expertise-matched models. Handles Microsoft Dynamics 365 localization architecture (W1 base + country-specific layers).'
allowed-tools: Read, Glob, Grep, LSP
argument-hint: 'review domain: security, performance, style, accessibility, upgrade, or privacy (or leave empty to run all domains sequentially)'
---

# AL Code Review

Reviews AL code for Dynamics 365 Business Central across multiple specialized domains with architectural awareness and localization strategy support.

## When to Use

- Reviewing AL code changes or pull requests
- Analyzing Business Central customizations for quality and best practices
- Evaluating code for specific domain concerns (security, performance, style, accessibility, upgrade, privacy)
- User asks for "code review", "review this AL code", or domain-specific analysis

## Domain-Specific Review Options

The skill supports 6 specialized review domains. Each domain uses a dedicated expertise model:

| Domain | Focus Area | Model Profile | Key Expertise |
|--------|-----------|-------------|---------------|
| **Security** | Permission models, credential management, access control, injection vulnerabilities | Security Auditor | Permissions, secrets, injection, access control, external services |
| **Performance** | Database queries, N+1 problems, indexes, record access patterns | Database Performance Specialist | Queries, indexes, SIFT, temporary tables, transactions |
| **Style** | Naming conventions, code formatting, readability, consistency | Code Style Linter | Naming, formatting, readability, AL conventions |
| **Accessibility** | Assistive technology support, labels, keyboard flow, semantic UI patterns | Accessibility Specialist | Screen readers, keyboard navigation, captions, control add-ins |
| **Upgrade** | Upgrade codeunit structure, data migration, upgrade tags, DataTransfer usage | Upgrade Code Specialist | Upgrade tags, DataTransfer, error handling, data migration |
| **Privacy** | GDPR compliance, data classification, PII handling, telemetry | Privacy/GDPR Expert | Data classification, PII, telemetry, compliance |

## Domain Strategy

**If you specify a domain** (for example, `security`):
- Load only that domain's instruction file
- Review only from that domain's perspective
- Return findings for that domain only

**If you do not specify a domain**:
- Keep domain separation
- Run the review in a loop, one domain at a time: `security`, `performance`, `style`, `accessibility`, `upgrade`, `privacy`
- Load one instruction file per pass
- Aggregate the final findings, grouped by domain

## Review Philosophy

### Root Cause Focus (Regardless of Domain)

- **Symptoms are clues, not conclusions** - A bug in one file often indicates a pattern problem
- **Ask "why" five times** - Dig until you find the actual cause
- **Broad strokes over band-aids** - Recommend fixes that solve classes of problems
- **Architecture over implementation** - Focus on structural issues, not just line-by-line fixes

### Domain Instruction Mapping

Instruction files used by domain:
- `security` → `code review/instructions/security.md`
- `performance` → `code review/instructions/performance.md`
- `style` → `code review/instructions/style.md`
- `accessibility` → `code review/instructions/accessibility.md`
- `upgrade` → `code review/instructions/upgrade.md`
- `privacy` → `code review/instructions/privacy.md`

## Review Process

### 1. Input Analysis
- Determine whether to run a single-domain review or the full sequential domain loop
- Identify changed files and localization status (W1 vs. country layer)
- Determine if this is W1 auto-sync or local-only code

### 2. File Filtering
- Apply the localization rules defined in the Localization Architecture section below
- Review W1 files as the source of truth when paired with generated country copies
- Review country-specific files directly when they contain local-only changes

### 3. Domain-Specific Analysis
- Apply the active domain's expertise model and instruction file for the current pass
- Identify root causes for systemic issues, not just symptoms
- Evaluate severity within domain context (Critical, High, Medium, Low)
- Merge findings across passes only after all requested domain reviews are complete

### 4. Severity & Recommendation Criteria

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Blocking production issues, security breaches, data loss risks | Hardcoded credentials, SQL injection, unhandled exceptions in upgrade |
| **High** | Significant problems affecting functionality or performance | FindSet misuse causing N+1, missing DataClassification on PII fields |
| **Medium** | Patterns that will cause problems as code grows or during maintenance | Inconsistent naming, missing tooltips on 10+ fields, incomplete error handling |
| **Low** | Improvements enhancing code quality, readability, or maintainability | Spacing violations, unnecessary parentheses, minor documentation gaps |

## Localization Architecture

This localization strategy applies only to files under `Src/Layers`. It does not apply to `Src/Apps`.

### Repository Structure

The codebase uses Microsoft's localization layering pattern in `Src/Layers`:

```
Src/
├── Layers/
│   └── W1/                     ← Worldwide base layer (source of truth)
│       ├── SystemApplication/
│       ├── Business Foundation/
│       │   ├── app.json
│       │   ├── App/            ← W1 source code
│       │   └── Test/
│       └── [other modules]
│   ├── AT/                     ← Austria country layer (localization)
│   ├── BE/                     ← Belgium country layer
│   ├── CH/                     ← Switzerland country layer
│   └── [other countries]/
```

### How Localization Works

1. **W1 is the source of truth** - All core code lives in `Src/Layers/W1`
2. **Country layers override W1** - When a customer runs in Austria (AT), the AT version of each file is used instead of W1
3. **Automated sync** - When W1 files change, an automated script copies those changes to country layer files
4. **Local customizations** - Country layers can have local-only changes not in W1

### Review Rules for Localized Code in `Src/Layers`

#### Rule 1: W1 File Changed + Country Files Changed for Same File
✅ **Review the W1 version only**  
❌ **Do NOT comment on country-specific files**

**Reason**: Country files are auto-generated copies. Any fix applied to W1 is automatically propagated to all country versions. Commenting on country files is redundant.

**Example**:
```
Changed files in PR:
- Src/Layers/W1/Business Foundation/App/MyCodeunit.al (modified)
- Src/Layers/AT/Business Foundation/App/MyCodeunit.al (modified)
- Src/Layers/BE/Business Foundation/App/MyCodeunit.al (modified)

Review approach:
→ Review MyCodeunit.al in W1 only
→ If the same code change is in the local file in AT and BE, ignore it
```

#### Rule 2: Only Country Files Changed (No W1 Change)
✅ **Comment on the specific country file(s)**

**Reason**: These are local-only modifications not controlled by W1 sync script. Issues are specific to that country.

**Example**:
```
Changed files in PR:
- Src/Layers/CH/Business Foundation/App/TaxCalc.al (modified)

Review approach:
→ Review TaxCalc.al in CH
```

### How to Identify Source vs. Generated Files

**W1 source files contain** current business logic, latest features, commented explanations

**Country layer copies contain** identical code; if line 42 has a specific issue in W1, that same issue appears in the country copy. This indicates it's auto-generated.

**How to Tell**:
- Open W1 version and country version side-by-side
- If they're identical or differ only in spacing, it's an auto-generated copy → review W1 only
- If country version has unique logic not in W1, it's country-specific → review both

## Output Format

All review findings must be returned as a JSON array, regardless of domain. The response must contain ONLY the JSON findings array inside a single `json` code block (no prose outside the code block).

### JSON Structure

```json
[
  {
    "filePath": "src/MyCodeunit.al",
    "lineNumber": 42,
    "severity": "High|Medium|Low|Critical",
    "issue": "Brief description of the issue",
    "recommendation": "Specific recommendation to fix",
    "suggestedCode": "The corrected code that fixes the issue"
  }
]
```

### Output Rules

- Respond with ONLY the JSON findings array
- Do NOT include explanations, commentary, or extra text outside the JSON code block
- Wrap JSON in one code block that starts with ```json
- If no findings, output: `[]`
- Each finding must have all 5 fields: filePath, lineNumber, severity, issue, recommendation, suggestedCode
- suggestedCode must be the exact line(s) to replace (with proper indentation preserved)
- If exact code fix is unclear, set suggestedCode to empty string `""`

### Example Findings (Security Domain)

```json
[
  {
    "filePath": "Src/Layers/W1/Business Foundation/App/MyCodeunit.al",
    "lineNumber": 15,
    "severity": "Critical",
    "issue": "Hardcoded API key in source code",
    "recommendation": "Use IsolatedStorage.SetEncrypted() or Azure Key Vault instead of hardcoded credentials",
    "suggestedCode": "    ApiKey := GetSecretFromIsolatedStorage('ApiKey');"
  },
  {
    "filePath": "Src/Layers/W1/Business Foundation/App/CustomerPage.al",
    "lineNumber": 89,
    "severity": "High",
    "issue": "Missing permission check before modifying customer data",
    "recommendation": "Add InherentPermissions attribute or explicit permission validation before Modify",
    "suggestedCode": "    [InherentPermissions(PermissionObjectType::TableData, Database::Customer, 'M')]\n    procedure UpdateCustomer(Rec: Record Customer)"
  }
]
```

### Example Findings (Performance Domain)

```json
[
  {
    "filePath": "Src/Layers/W1/Business Foundation/App/PostingRoutine.al",
    "lineNumber": 127,
    "severity": "High",
    "issue": "N+1 query pattern: FindSet without filtering, Get inside loop",
    "recommendation": "Use SetRange to filter before FindSet, or restructure query to single batch operation",
    "suggestedCode": "    Customer.SetRange(\"Country/Region Code\", 'US');\n    if Customer.FindSet() then\n        repeat\n            // Process customer\n        until Customer.Next() = 0;"
  }
]
```

### Example Findings (Style Domain)

```json
[
  {
    "filePath": "Src/Layers/W1/Business Foundation/App/MyCodeunit.al",
    "lineNumber": 42,
    "severity": "Medium",
    "issue": "Inconsistent variable naming - uses 'CustName' instead of 'CustomerName'",
    "recommendation": "Replace abbreviated variable name with full descriptive name matching codebase conventions",
    "suggestedCode": "    CustomerName := Record.Name;"
  }
]
```

### Applying Localization Rules to Findings

When you find an issue in a country-layer file under `Src/Layers` that also exists in W1:
- **Create the finding against W1 file path only**, not the country layer copy
- **Set lineNumber to the W1 line number**
- Country layer will be auto-synced with the W1 fix

Example:
```json
[
  {
    "filePath": "Src/Layers/W1/Business Foundation/App/TaxCalculation.al",
    "lineNumber": 85,
    "severity": "High",
    "issue": "Missing validation trigger",
    "recommendation": "Add OnValidate trigger to prevent invalid values",
    "suggestedCode": "    trigger OnValidate()\n    begin\n        TestField(Amount, '<>0');\n    end;"
  }
]
```
(Note: Even if AT, BE, CH layers also have this issue, we report W1 only, and the sync script propagates the fix automatically.)

---
name: bc-telemetry-kusto
description: Use this skill for every prompt containing the exact word "telemetry". Searches the local Business Central OpenTelemetry NST log.
---

# Business Central Local OpenTelemetry Target

- Log file: `C:\OpenTelemetryLogs\NST\NAV_US\NstLog.tsv`
- Format: tab-separated values with one telemetry record per physical line
- Primary fields: `env_time`, `tag`, `severity`, `message`, `aadTenantId`, `environmentName`, `clientSessionId`, `serverSessionId`, and `traceStartInfo`

Always search only the exact file above. Do not search:

- The stale root-level file `C:\OpenTelemetryLogs\NST\NstLog.tsv`
- `NstLogWithEUPI.tsv`
- `PartnerAppInsightsTraces.tsv`
- `Span.tsv`
- Any Kusto cluster or database

The `NAV_US` file is the active local NST export. The root-level files are older exports and can return stale or misleading results.

## Mandatory single-file strategy

Perform one search of `C:\OpenTelemetryLogs\NST\NAV_US\NstLog.tsv` per request. Do not issue fallback searches against other telemetry files when no row is found.

Before searching for an AL error, inspect the AL source and build the complete runtime call-stack signature:

1. Find the exact statement that raises the error.
2. Identify the containing application object type, object ID, object name, and procedure name.
3. Calculate the procedure line reported by the AL runtime. Procedure body line numbering starts at the procedure's `begin` line as line 1 and includes subsequent source lines.
4. Build the signature in this exact form:
   `AL CallStack: "<object-name>"(<object-type> <object-id>).<procedure-name> line <procedure-line>`
5. Preserve the runtime object-type spelling and casing, such as `CodeUnit`.
6. Search the `message` field for the complete literal signature.

For example, this source:

```al
procedure AdvancedChecksOnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
begin
    if SomeCondition then
        Error('Advanced checks failed');
end;
```

is in codeunit 99999 `"Advanced Posting Logic"`. The `Error(...)` statement is procedure-body line 3, so search for:

```text
AL CallStack: "Advanced Posting Logic"(CodeUnit 99999).AdvancedChecksOnBeforePostPurchaseDoc line 3
```

Do not search for only the literal text passed to `Error(...)`, partial object or procedure names, or all files in the folder. If the exact call-stack signature cannot be derived confidently from the source, inspect more source or ask for the missing information before searching the log.

## Reading the TSV

Prefer PowerShell `Import-Csv` with a tab delimiter so fields are parsed correctly. Filter the `message` column by literal substring, sort by `env_time` descending, and return the newest match:

```powershell
$signature = 'AL CallStack: "<object-name>"(<object-type> <object-id>).<procedure-name> line <procedure-line>'
Import-Csv -LiteralPath 'C:\OpenTelemetryLogs\NST\NAV_US\NstLog.tsv' -Delimiter "`t" |
    Where-Object { $_.message.Contains($signature) } |
    Sort-Object { [datetimeoffset]$_.env_time } -Descending |
    Select-Object -First 1 env_time, message, aadTenantId, environmentName, clientSessionId, serverSessionId, traceStartInfo
```

Use a literal substring comparison rather than a regular expression because call-stack signatures contain punctuation with regex meaning.

## AL error messages

Do not rely on the literal text passed to `Error(...)`. An inline call such as `Error('Operation failed')` can emit the generic message `Use ERROR with a text constant to improve telemetry details` instead of the literal error text. Always derive and use the complete call-stack signature from the AL source.

When reporting a match, include the object type and ID, procedure, telemetry procedure line, source file and physical source line when known, event timestamp, tenant and environment, client and server session IDs, and `traceStartInfo`.

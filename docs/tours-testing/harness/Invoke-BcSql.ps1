<#
    Runs one SQL query inside the tour's container and prints the rows.

    Why it exists: pwsh -Command interpolates $ inside the query, and BC table
    names are full of $. This writes the query to a temp .ps1 as a single-quoted
    here-string and invokes it with pwsh -File, which does not interpolate.

    Container comes from $env:BC_CREDS so oracle and browser address the same one.

    Usage:
      .\Invoke-BcSql.ps1 -Query "SELECT name FROM sys.tables WHERE name LIKE '%FA Ledger%'"
      .\Invoke-BcSql.ps1 -QueryFile .\q.sql
#>
param(
    [string] $Query,
    [string] $QueryFile,
    [string] $ContainerName,
    [string] $Database = 'CRONUS'
)

$ErrorActionPreference = 'Stop'

if (-not $ContainerName) {
    if (-not $env:BC_CREDS) { throw 'Set $env:BC_CREDS to this tour''s credentials json, or pass -ContainerName.' }
    $ContainerName = (Get-Content $env:BC_CREDS -Raw | ConvertFrom-Json).containerName
}

if ($QueryFile) { $Query = Get-Content $QueryFile -Raw }
if (-not $Query) { throw 'Pass -Query or -QueryFile.' }

if ($Query -match "'@") { throw 'Query contains an @-terminator sequence; rewrite it.' }

# ⚠️ ONE result set per call. Invoke-Sqlcmd flattens multiple result sets, so two differently
# shaped SELECTs come back as one ragged list and everything after the first is silently lost -
# a confident, well-formed, wrong answer. Use one SELECT, or UNION ALL with matching columns.
if (([regex]::Matches($Query, '(?im)^\s*SELECT\b')).Count -gt 1 -and $Query -notmatch '(?i)UNION') {
    Write-Warning ('Invoke-BcSql: the query contains more than one SELECT and no UNION. ' +
                   'Only the first result set will survive - split the call or use UNION ALL.')
}

$tmp = Join-Path $env:TEMP ("bcsql-" + [guid]::NewGuid().ToString('N') + ".ps1")

$script = @"
`$ErrorActionPreference = 'Stop'
Import-Module BcContainerHelper -DisableNameChecking -WarningAction SilentlyContinue | Out-Null
`$q = @'
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
$Query
'@
`$rows = Invoke-ScriptInBcContainer -containerName '$ContainerName' -scriptblock {
    param(`$qq, `$db)
    Invoke-Sqlcmd -ServerInstance 'localhost\SQLEXPRESS' -Database `$db -Query `$qq -TrustServerCertificate -MaxCharLength 8000 |
        Select-Object * -ExcludeProperty ItemArray, RowError, RowState, Table, HasErrors
} -argumentList `$q, '$Database'

# ⚠️ Emit JSON between markers, NOT objects.
#
# This script body runs in a SEPARATE pwsh process, so anything written to its stdout reaches
# the caller as FORMATTED TEXT, never as objects. A caller doing `\`$row.SomeColumn` then gets
# \`$null on every line and blames the table name - a confident, well-formed wrong answer of
# exactly the kind this harness keeps producing. Serialising explicitly and rehydrating in the
# parent is what makes the return value real objects.
Write-Output '<<<BCSQL-JSON>>>'
Write-Output (@(`$rows) | ConvertTo-Json -Depth 6 -Compress)
Write-Output '<<<END-BCSQL-JSON>>>'
"@

Set-Content -Path $tmp -Value $script -Encoding utf8
try {
    $raw = pwsh -NoProfile -File $tmp 2>&1
} finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
}

$text  = ($raw | Out-String)
$start = $text.IndexOf('<<<BCSQL-JSON>>>')
$end   = $text.IndexOf('<<<END-BCSQL-JSON>>>')
if ($start -lt 0 -or $end -lt 0) {
    # No marker means the query never ran - surface the container's own output rather than
    # returning an empty set, which would read as "the table is empty".
    throw "Invoke-BcSql: query did not complete. Output was:`n$text"
}

$json = $text.Substring($start + 16, $end - $start - 16).Trim()
if (-not $json -or $json -eq 'null') { return @() }

$result = $json | ConvertFrom-Json
return @($result)

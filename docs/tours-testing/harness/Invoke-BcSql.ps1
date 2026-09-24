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

$tmp = Join-Path $env:TEMP ("bcsql-" + [guid]::NewGuid().ToString('N') + ".ps1")

$script = @"
`$ErrorActionPreference = 'Stop'
Import-Module BcContainerHelper -DisableNameChecking -WarningAction SilentlyContinue | Out-Null
`$q = @'
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
$Query
'@
Invoke-ScriptInBcContainer -containerName '$ContainerName' -scriptblock {
    param(`$qq, `$db)
    Invoke-Sqlcmd -ServerInstance 'localhost\SQLEXPRESS' -Database `$db -Query `$qq -TrustServerCertificate -MaxCharLength 8000 |
        Select-Object * -ExcludeProperty ItemArray, RowError, RowState, Table, HasErrors
} -argumentList `$q, '$Database'
"@

Set-Content -Path $tmp -Value $script -Encoding utf8
try {
    pwsh -NoProfile -File $tmp
} finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
}

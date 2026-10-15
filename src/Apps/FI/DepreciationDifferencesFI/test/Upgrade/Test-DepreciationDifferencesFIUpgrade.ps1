# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

<#
.SYNOPSIS
Verifies the CLEAN30 depreciation difference migration and its idempotence.
.DESCRIPTION
Run only against a disposable on-premises FI database with demo posting groups,
ledger entries, and G/L accounts. The feature app and its dependencies must already
be installed. Supply the matching compiler and populated package cache.

The standalone AL suite tests the completed-upgrade guard. This integration check
seeds the four legacy SQL columns before publishing the CLEAN30 feature package,
because AL cannot write fields whose ObsoleteState is Removed. It then executes
the actual upgrade lifecycle, checks all four target fields and the company tag,
edits the targets, and upgrades again to check that edits survive.

The database must retain the legacy fields (not CLEANSCHEMA33). Existing demo
records and upgrade tags are modified; do not use a production database. Outputs
are retained in OutputDirectory. Each pass compiles a fresh package because the
developer endpoint rejects duplicate package IDs.
.EXAMPLE
.\Test-DepreciationDifferencesFIUpgrade.ps1 -AlToolPath C:\tools\altool.exe `
    -PackageCachePath C:\symbols\FI -ServerInstance FIUpgradeTest -DeveloperPort 7449 `
    -DatabaseName FIUpgradeTest -OutputDirectory C:\temp\FIUpgradeTest -DisposableDatabase
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AlToolPath,
    [Parameter(Mandatory)]
    [string]$PackageCachePath,
    [Parameter(Mandatory)]
    [string]$ServerInstance,
    [Parameter(Mandatory)]
    [int]$DeveloperPort,
    [Parameter(Mandatory)]
    [string]$DatabaseName,
    [Parameter(Mandatory)]
    [string]$OutputDirectory,
    [string]$DatabaseServer = '.',
    [ValidatePattern('^[A-Za-z0-9 _-]+$')]
    [string]$CompanyName = 'CRONUS FI',
    [switch]$DisposableDatabase
)

$ErrorActionPreference = 'Stop'
if (!$DisposableDatabase) {
    throw 'Explicitly confirm the target is disposable with -DisposableDatabase.'
}
Get-Command -Name Invoke-Sqlcmd -ErrorAction Stop | Out-Null
$project = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\app'))
Get-Item -LiteralPath $AlToolPath, $PackageCachePath, (Join-Path $project 'app.json') -ErrorAction Stop | Out-Null
if ((Test-Path -LiteralPath $OutputDirectory) -and @(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -gt 0) {
    throw 'Use an empty OutputDirectory so results cannot be confused with an earlier run.'
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$defines = (15..30 | ForEach-Object { "CLEAN$_" }) -join ';'

function Invoke-CheckedSql {
    param([string]$Query, [string]$SuccessColumn)

    $rows = @(Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DatabaseName -Query $Query |
        Where-Object { $_.$SuccessColumn -eq 1 })
    if ($rows.Count -ne 1) {
        throw "SQL check did not return its success record: $SuccessColumn"
    }
    return $rows[0]
}

$seed = @'
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Code nvarchar(20), @EntryNo int, @Account nvarchar(20), @BalAccount nvarchar(20);
SELECT TOP 1 @Code=[Code] FROM [{0}$FA Posting Group$437dbf0e-84ff-417a-965d-ed2bb9650972] ORDER BY [Code];
SELECT TOP 1 @EntryNo=[Entry No_] FROM [{0}$FA Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] ORDER BY [Entry No_];
SELECT TOP 1 @Account=[No_] FROM [{0}$G_L Account$437dbf0e-84ff-417a-965d-ed2bb9650972] WHERE [Account Type]=0 ORDER BY [No_];
SELECT TOP 1 @BalAccount=[No_] FROM [{0}$G_L Account$437dbf0e-84ff-417a-965d-ed2bb9650972] WHERE [Account Type]=0 ORDER BY [No_] DESC;
IF @Code IS NULL OR @EntryNo IS NULL OR @Account IS NULL OR @BalAccount IS NULL OR @Account=@BalAccount
    THROW 51000, 'Disposable FI fixture prerequisites are missing', 1;
UPDATE [{0}$FA Posting Group$437dbf0e-84ff-417a-965d-ed2bb9650972]
SET [Depr_ Difference Acc_]=@Account, [Depr_ Difference Bal_ Acc_]=@BalAccount,
    [Deprec_ Difference Account$ecb1100e-3081-4c6a-9554-de33c687bf5f]='',
    [Deprec_ Difference Bal Acct$ecb1100e-3081-4c6a-9554-de33c687bf5f]='' WHERE [Code]=@Code;
UPDATE [{0}$FA Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972]
SET [Depr_ Difference Posted]=1, [Depreciation Difference Posted$ecb1100e-3081-4c6a-9554-de33c687bf5f]=0
WHERE [Entry No_]=@EntryNo;
UPDATE [{0}$Source Code Setup$f3552374-a1f2-4356-848e-196002525837]
SET [Depr_ Difference$437dbf0e-84ff-417a-965d-ed2bb9650972]='PR9326',
    [Depreciation Difference Code$ecb1100e-3081-4c6a-9554-de33c687bf5f]='' WHERE [Primary Key]='';
IF @@ROWCOUNT<>1 THROW 51000, 'Expected exactly one source-code setup record', 1;
DELETE FROM [Upgrade Tags$63ca2fa4-4f03-4f2b-a480-172fef340d3f]
WHERE UPPER([Tag])='MS-DEPRECIATIONDIFFERENCESFIUPGRADETAG-20260711' AND UPPER([Company])=UPPER('{0}');
COMMIT;
SELECT 1 AS FixtureReady, @Code AS PostingGroupCode, @EntryNo AS LedgerEntryNo,
    @Account AS LegacyAccount, @BalAccount AS LegacyBalAccount;
'@ -f $CompanyName
$fixture = Invoke-CheckedSql -Query $seed -SuccessColumn 'FixtureReady'
$fixture | Select-Object PostingGroupCode, LedgerEntryNo, LegacyAccount, LegacyBalAccount |
    ConvertTo-Json | Set-Content (Join-Path $OutputDirectory 'fixture.json')
$code = $fixture.PostingGroupCode.Replace("'", "''")
$entryNo = [int]$fixture.LedgerEntryNo
$account = $fixture.LegacyAccount.Replace("'", "''")
$balAccount = $fixture.LegacyBalAccount.Replace("'", "''")

for ($pass = 1; $pass -le 2; $pass++) {
    if ($pass -eq 2) {
        $edit = @'
SET XACT_ABORT ON;
BEGIN TRANSACTION;
UPDATE [{0}$FA Posting Group$437dbf0e-84ff-417a-965d-ed2bb9650972]
SET [Deprec_ Difference Account$ecb1100e-3081-4c6a-9554-de33c687bf5f]='{3}',
    [Deprec_ Difference Bal Acct$ecb1100e-3081-4c6a-9554-de33c687bf5f]='{2}' WHERE [Code]='{1}';
UPDATE [{0}$FA Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972]
SET [Depreciation Difference Posted$ecb1100e-3081-4c6a-9554-de33c687bf5f]=0 WHERE [Entry No_]={4};
UPDATE [{0}$Source Code Setup$f3552374-a1f2-4356-848e-196002525837]
SET [Depreciation Difference Code$ecb1100e-3081-4c6a-9554-de33c687bf5f]='EDIT9326' WHERE [Primary Key]='';
COMMIT;
SELECT 1 AS FixtureEdited;
'@ -f $CompanyName, $code, $account, $balAccount, $entryNo
        Invoke-CheckedSql -Query $edit -SuccessColumn 'FixtureEdited' | Out-Null
    }
    $output = Join-Path $OutputDirectory "upgrade-pass-$pass.app"
    & $AlToolPath compile -- "/project:$project" "/out:$output" "/packagecachepath:$PackageCachePath" `
        "/define:$defines" '/generatereportlayout-' '/loglevel:warning' *> (Join-Path $OutputDirectory "compile-$pass.log")
    if ($LASTEXITCODE -ne 0) {
        throw "Upgrade package compilation $pass failed; inspect compile-$pass.log."
    }
    & $AlToolPath publishapp $output --server http://localhost --serverinstance $ServerInstance --port $DeveloperPort `
        --authentication Windows --environmenttype OnPrem --schemaupdatemode Synchronize --forceupgrade 2>&1 |
        Tee-Object -FilePath (Join-Path $OutputDirectory "publish-$pass.log") | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Upgrade publication $pass failed; inspect publish-$pass.log."
    }
    $expectedAccount = $account
    $expectedBalAccount = $balAccount
    $expectedPosted = 1
    $expectedSource = 'PR9326'
    if ($pass -eq 2) {
        $expectedAccount = $balAccount
        $expectedBalAccount = $account
        $expectedPosted = 0
        $expectedSource = 'EDIT9326'
    }
    $verify = @'
IF NOT EXISTS (
 SELECT 1 FROM [{0}$FA Posting Group$437dbf0e-84ff-417a-965d-ed2bb9650972] WHERE [Code]='{1}'
 AND [Deprec_ Difference Account$ecb1100e-3081-4c6a-9554-de33c687bf5f]='{2}'
 AND [Deprec_ Difference Bal Acct$ecb1100e-3081-4c6a-9554-de33c687bf5f]='{3}')
 THROW 51000, 'Posting-group account migration or idempotence failed', 1;
IF NOT EXISTS (
 SELECT 1 FROM [{0}$FA Ledger Entry$437dbf0e-84ff-417a-965d-ed2bb9650972] WHERE [Entry No_]={4}
 AND [Depreciation Difference Posted$ecb1100e-3081-4c6a-9554-de33c687bf5f]={5})
 THROW 51000, 'Ledger flag migration or idempotence failed', 1;
IF NOT EXISTS (
 SELECT 1 FROM [{0}$Source Code Setup$f3552374-a1f2-4356-848e-196002525837] WHERE [Primary Key]=''
 AND [Depreciation Difference Code$ecb1100e-3081-4c6a-9554-de33c687bf5f]='{6}')
 THROW 51000, 'Source-code migration or idempotence failed', 1;
IF NOT EXISTS (
 SELECT 1 FROM [Upgrade Tags$63ca2fa4-4f03-4f2b-a480-172fef340d3f]
 WHERE UPPER([Tag])='MS-DEPRECIATIONDIFFERENCESFIUPGRADETAG-20260711' AND UPPER([Company])=UPPER('{0}'))
 THROW 51000, 'Per-company upgrade tag was not registered', 1;
SELECT 1 AS Verified;
'@ -f $CompanyName, $code, $expectedAccount, $expectedBalAccount, $entryNo, $expectedPosted, $expectedSource
    Invoke-CheckedSql -Query $verify -SuccessColumn 'Verified' | Out-Null
    [pscustomobject]@{ pass = $pass; succeeded = $true; checkedFields = 4; upgradeTagVerified = $true } |
        ConvertTo-Json | Set-Content (Join-Path $OutputDirectory "result-$pass.json")
    Write-Host "Upgrade pass $pass verified all four fields and the company tag."
}

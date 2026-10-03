param(
    [string] $AbruptRoot,
    [string] $ConcurrentRoot,
    [int] $ConcurrentId
)

$ErrorActionPreference = 'Stop'

class ClientLogicalForm {}

class AITMockControl {
    [string] $StringValue
    AITMockControl([string] $Value) { $this.StringValue = $Value }
}

class ClientContext {
    [string[]] $Texts
    [string[]] $Paths
    [string[]] $Errors
    [int] $Index = -1
    [int] $ThrowAt = -1
    [int] $MissingErrorAt = -1
    [int] $ErrorReads = 0
    [scriptblock] $OnAction
    ClientContext([string[]] $Texts, [string[]] $Paths, [string[]] $Errors) {
        $this.Texts = $Texts
        $this.Paths = $Paths
        $this.Errors = $Errors
    }
    [object] GetActionByName([object] $Form, [string] $Name) {
        if ($Name -ne 'LoadAITRunDataFile') { throw "Unexpected action $Name." }
        return $Name
    }
    [void] InvokeAction([object] $Action) {
        $this.Index++
        if ($null -ne $this.OnAction) { & $this.OnAction $this.Index }
        if ($this.Index -eq $this.ThrowAt) { throw 'Task detail action failed.' }
        if ($this.Index -ge $this.Texts.Count) { throw 'Stream ended without a sentinel.' }
    }
    [object] GetControlByName([object] $Form, [string] $Name) {
        switch ($Name) {
            'AIT Run Data File' { return [AITMockControl]::new($this.Texts[$this.Index]) }
            'AIT Run Data File Path' { return [AITMockControl]::new($this.Paths[$this.Index]) }
            'AIT Run Data File Error' {
                $this.ErrorReads++
                if ($this.Index -eq $this.MissingErrorAt) { return $null }
                if ($this.Index -lt $this.Errors.Count) {
                    return [AITMockControl]::new($this.Errors[$this.Index])
                }
                return [AITMockControl]::new('')
            }
        }
        throw "Unexpected control $Name."
    }
}

$script:Messages = [System.Collections.Generic.List[string]]::new()
$script:OnLog = $null
$script:StatusLock = $null
$script:Clock = $null
function Write-HostWithTimestamp([string] $Message) {
    $script:Messages.Add($Message)
    if ($null -ne $script:OnLog) { & $script:OnLog $Message }
}
function Join-TestPath([string] $Path, [string] $ChildPath) { return [System.IO.Path]::Combine($Path, $ChildPath) }

# Load the production functions without the BC client DLLs or a server connection.
$ModulePath = Join-Path $PSScriptRoot '..\Internal\TestRunnerInternalForAIT.psm1'
$ParseErrors = $null
$Ast = [System.Management.Automation.Language.Parser]::ParseFile($ModulePath, [ref] $null, [ref] $ParseErrors)
if ($ParseErrors) { throw ($ParseErrors | Out-String) }
$Definitions = $Ast.FindAll({
    param($Node)
    $Node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $Node.Name -match '-AITRunData'
}, $true)
foreach ($Definition in $Definitions) { Invoke-Expression $Definition.Extent.Text }
$script:NoMoreAITRunDataFiles = 'No more AI Eval run data files.'
$script:AITRunDataExportTimeout = [timespan]::FromMinutes(20)
$script:AITRunDataFileEncodingWithoutBOM = [System.Text.UTF8Encoding]::new($false)

if ($ConcurrentRoot) {
    $Summary = '{"suite":"SUITE","version":7,"writer":' + $ConcurrentId + '}'
    $Context = [ClientContext]::new(@($Summary, $script:NoMoreAITRunDataFiles), @('SUITE\version-7\results.json', ''), @())
    $Context.OnAction = {
        param($Index)
        if ($Index -eq 0) {
            [System.IO.File]::WriteAllText((Join-TestPath $ConcurrentRoot "writer-$ConcurrentId-started"), '')
        }
        if ($ConcurrentId -eq 0 -and $Index -eq 1) {
            [System.IO.File]::WriteAllText((Join-TestPath $ConcurrentRoot 'writer-0-ready'), '')
            $WaitUntil = [datetime]::UtcNow.AddSeconds(20)
            while (-not [System.IO.File]::Exists((Join-TestPath $ConcurrentRoot 'writer-0-release'))) {
                if ([datetime]::UtcNow -ge $WaitUntil) { throw 'Concurrent export fixture timed out.' }
                Start-Sleep -Milliseconds 20
            }
        }
    }
    Export-AITRunData -SuiteCode 'SUITE' -AITRunDataFolder $ConcurrentRoot -ClientContext $Context -Form ([ClientLogicalForm]::new())
    exit
}
if ($AbruptRoot) {
    $Context = [ClientContext]::new(@('{}', '{}'), @('SUITE\version-7\results.json', ''), @())
    $Context.OnAction = { param($Index) if ($Index -eq 1) { [System.Environment]::Exit(23) } }
    Export-AITRunData -SuiteCode 'SUITE' -AITRunDataFolder $AbruptRoot -ClientContext $Context -Form ([ClientLogicalForm]::new())
    throw 'Abrupt child unexpectedly returned.'
}

$script:Checks = 0
$Processes = @()
$ConcurrentReleasePath = ''
$Scratch = Get-AITRunDataOutputRoot (Join-Path $PSScriptRoot ('.ait-export-tests-' + [guid]::NewGuid().ToString('N')))
[System.IO.Directory]::CreateDirectory($Scratch) | Out-Null
function Assert-True([bool] $Condition, [string] $Message) {
    $script:Checks++
    if (-not $Condition) { throw $Message }
}
function Assert-Throws([scriptblock] $Action, [string] $Message) {
    $Thrown = $false
    try { & $Action | Out-Null } catch { $Thrown = $true }
    Assert-True $Thrown $Message
}
function Wait-TestFile([string] $Path) {
    $WaitUntil = [datetime]::UtcNow.AddSeconds(15)
    while (-not [System.IO.File]::Exists($Path) -and [datetime]::UtcNow -lt $WaitUntil) {
        Start-Sleep -Milliseconds 20
    }
    Assert-True ([System.IO.File]::Exists($Path)) "Concurrent export did not reach '$Path'."
}
function New-TestRoot([string] $Name) {
    $Path = Join-TestPath $Scratch $Name
    [System.IO.Directory]::CreateDirectory($Path) | Out-Null
    return $Path
}
function Write-TestFile([string] $Path, [string] $Text = '{}') {
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($Path)) | Out-Null
    [System.IO.File]::WriteAllText($Path, $Text, $script:AITRunDataFileEncodingWithoutBOM)
}
function New-TestSummary([string] $Suite, [int] $Version = 7) {
    return ConvertTo-Json -Compress -InputObject ([ordered]@{
        suite = $Suite
        version = $Version
        exportStatusFile = 'export-status.json'
        evaluations = @()
    })
}
function Read-Status([string] $Root, [string] $Suite = 'SUITE') {
    return ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText((Join-TestPath $Root "$Suite\version-7\export-status.json")))
}
function Invoke-Export([string] $Root, [ClientContext] $Context, [string] $Suite = 'SUITE') {
    $Output = @(Export-AITRunData -SuiteCode $Suite -AITRunDataFolder $Root -ClientContext $Context -Form ([ClientLogicalForm]::new()))
    Assert-True ($Output.Count -eq 0) 'Export must not add success objects to the test-result pipeline.'
}
function Assert-RawFile([string] $Path, [string] $Expected) {
    $Actual = [System.IO.File]::ReadAllBytes($Path)
    $ExpectedBytes = $script:AITRunDataFileEncodingWithoutBOM.GetBytes($Expected)
    Assert-True ([Convert]::ToBase64String($Actual) -ceq [Convert]::ToBase64String($ExpectedBytes)) "Payload or UTF-8 encoding changed at $Path."
    Assert-True (-not ($Actual.Length -ge 3 -and $Actual[0] -eq 239 -and $Actual[1] -eq 187 -and $Actual[2] -eq 191)) "Unexpected BOM at $Path."
}
function Get-Date {
    if ($null -ne $script:Clock) { return $script:Clock }
    return Microsoft.PowerShell.Utility\Get-Date
}

try {
    $Sentinel = $script:NoMoreAITRunDataFiles
    $Root = New-TestRoot 'success'
    $RawSummary = "{`r`n  `"suite`": `"$([char]0x00c9)valuation`", `"exportStatusFile`": `"export-status.json`"`r`n}"
    $RawEvaluation = ' { "unicode": "' + [char]0x6f22 + [char]0x5b57 + ' ' + [char]::ConvertFromUtf32(0x1f603) + '", "number": 1.00, "escaped": "\u00E9", "evaluation": "Failed" } '
    $RawTask = "{`n `"message`": `"$([char]0x00f1)`", `"items`": [ 1, 2 ]`n}"
    $Context = [ClientContext]::new(
        @($RawSummary, $RawEvaluation, $RawTask, $Sentinel),
        @('SUITE\version-7\results.json', 'SUITE\version-7\group-1\evaluation-result-1.json', 'SUITE\version-7\group-1\agent-task-details\task-1.json', ''),
        @()
    )
    $script:ObservedStatuses = [System.Collections.Generic.List[string]]::new()
    $Context.OnAction = {
        param($Index)
        if ($Index -gt 0) { $script:ObservedStatuses.Add((Read-Status $Root).status) }
    }
    Invoke-Export $Root $Context
    $Status = Read-Status $Root
    Assert-True ($Status.status -ceq 'Completed' -and $Status.filesWritten -eq 3 -and $Status.errors.Count -eq 0) 'Successful transport must complete independently of evaluation failures.'
    Assert-True ($Status.suiteCode -ceq 'SUITE' -and $Status.suiteFolder -ceq 'SUITE' -and $Status.version -ceq 'version-7') 'Status identity is missing.'
    Assert-True (@($script:ObservedStatuses | Where-Object { $_ -ne 'InProgress' }).Count -eq 0) 'Export was completed before its terminal sentinel.'
    Assert-True ($Context.ErrorReads -eq 3) 'Read the error field on every nonsentinel response only.'
    Assert-RawFile (Join-TestPath $Root 'SUITE\version-7\results.json') $RawSummary
    Assert-RawFile (Join-TestPath $Root 'SUITE\version-7\group-1\evaluation-result-1.json') $RawEvaluation
    Assert-RawFile (Join-TestPath $Root 'SUITE\version-7\group-1\agent-task-details\task-1.json') $RawTask

    $Root = New-TestRoot 'literal-cleanup'
    $OwnStale = Join-TestPath $Root 'SUITE[1]\version-7\stale.json'
    $OtherSuite = Join-TestPath $Root 'SUITE1\version-7\keep.json'
    $OtherVersion = Join-TestPath $Root 'SUITE[1]\version-6\keep.json'
    foreach ($File in @($OwnStale, $OtherSuite, $OtherVersion)) { Write-TestFile $File }
    Write-TestFile (Join-TestPath $Root 'SUITE[1]\version-7\results.json') (New-TestSummary 'SUITE[1]')
    Write-TestFile (Join-TestPath $Root 'SUITE[1]\version-6\results.json') (New-TestSummary 'SUITE[1]' 6)
    Write-TestFile (Join-TestPath $Root 'SUITE1\version-7\results.json') (New-TestSummary 'SUITE1')
    $Context = [ClientContext]::new(@((New-TestSummary 'SUITE[1]'), $Sentinel), @('SUITE[1]\version-7\results.json', ''), @())
    Invoke-Export $Root $Context 'suite[1]'
    Assert-True (-not [System.IO.File]::Exists($OwnStale)) 'Literal cleanup left stale own-version files.'
    Assert-True ([System.IO.File]::Exists($OtherSuite) -and [System.IO.File]::Exists($OtherVersion)) 'Cleanup removed another suite or version.'
    Assert-True ((Read-Status $Root 'SUITE[1]').status -eq 'Completed') 'Bracketed suite directory was not preserved.'

    $Root = New-TestRoot 'occupied-version-file'
    $Guard = Join-TestPath $Root 'SUITE\version-7'
    Write-TestFile $Guard 'not an export folder'
    $Context = [ClientContext]::new(@('{}', $Sentinel), @('SUITE\version-7\results.json', ''), @())
    Invoke-Export $Root $Context
    Assert-True ([System.IO.File]::ReadAllText($Guard) -ceq 'not an export folder') 'Cleanup replaced an existing file with a version folder.'

    $Root = New-TestRoot 'detail-error'
    $ErrorText = 'Agent task 42 could not be read.'
    $Envelope = '{"agentTaskId":42,"exportStatus":"Failed","error":"Agent task 42 could not be read."}'
    $Context = [ClientContext]::new(
        @('{}', '{"id":1}', '{"id":2}', $Envelope, $RawTask, $Sentinel),
        @('SUITE\version-7\results.json', 'SUITE\version-7\group-1\evaluation-result-1.json', 'SUITE\version-7\group-1\evaluation-result-2.json', 'SUITE\version-7\group-1\agent-task-details\task-42.json', 'SUITE\version-7\group-1\agent-task-details\task-43.json', ''),
        @('', '', '', $ErrorText, '')
    )
    Invoke-Export $Root $Context
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'Partial' -and $Status.filesWritten -eq 5 -and $Status.errors.Count -eq 1) 'A detail error must remain partial after the sentinel.'
    Assert-True ($Status.errors[0].path -ceq $Context.Paths[3] -and $Status.errors[0].message -ceq $ErrorText) 'Detail failure path/message was lost.'
    Assert-RawFile (Join-TestPath $Root $Context.Paths[3]) $Envelope
    Assert-RawFile (Join-TestPath $Root $Context.Paths[4]) $RawTask

    $Root = New-TestRoot 'action-error'
    $Context.Index = -1
    $Context.ThrowAt = 3
    Invoke-Export $Root $Context
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'Partial' -and $Status.filesWritten -eq 3 -and $Context.Index -eq 3) 'Thrown actions must stop the loop with version-local partial status.'
    Assert-True ($Status.errors[0].message -like '*Task detail action failed*') 'Action exception was not recorded.'
    Assert-True ([System.IO.File]::Exists((Join-TestPath $Root $Context.Paths[2]))) 'Already-streamed compact evaluations were lost.'

    $Root = New-TestRoot 'incomplete'
    $Context = [ClientContext]::new(@('{}'), @('SUITE\version-7\results.json'), @())
    Invoke-Export $Root $Context
    Assert-True ((Read-Status $Root).status -eq 'Partial') 'An incomplete stream must not complete.'

    $Root = New-TestRoot 'abrupt'
    $PowerShellPath = (Get-Process -Id $PID).Path
    & $PowerShellPath -NoProfile -File $PSCommandPath -AbruptRoot $Root
    Assert-True ($LASTEXITCODE -eq 23) 'Abrupt-termination child did not exit at the intended action.'
    $global:LASTEXITCODE = 0
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'InProgress' -and $Status.filesWritten -eq 1) 'Abrupt termination must leave durable InProgress status.'

    $Root = New-TestRoot 'deadline'
    $script:Clock = [datetime]'2026-01-01T00:00:00Z'
    $Context = [ClientContext]::new(@('{}', $Sentinel), @('SUITE\version-7\results.json', ''), @())
    $Context.OnAction = { param($Index) if ($Index -eq 1) { $script:Clock = $script:Clock.AddMinutes(21) } }
    Invoke-Export $Root $Context
    $script:Clock = $null
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'Partial' -and $Status.errors[0].message -like '*20 minutes*') 'A synchronous action crossing the deadline must not complete.'
    $Root = New-TestRoot 'deadline-before-action'
    $script:AITRunDataExportTimeout = [timespan]::Zero
    $Context = [ClientContext]::new(@($Sentinel), @(''), @())
    Invoke-Export $Root $Context
    $script:AITRunDataExportTimeout = [timespan]::FromMinutes(20)
    Assert-True ($Context.Index -eq -1) 'The exporter invoked an action after its deadline.'
    $Diagnostic = @(Get-ChildItem -LiteralPath $Root -Filter 'export-error-*.json')
    Assert-True ($Diagnostic.Count -eq 1 -and (ConvertFrom-Json ([System.IO.File]::ReadAllText($Diagnostic[0].FullName))).status -eq 'Partial') 'A pre-version timeout needs a root diagnostic.'

    $Root = New-TestRoot 'invalid-paths'
    $Guard = Join-TestPath $Root 'OTHER\version-8\keep.json'
    Write-TestFile $Guard 'keep'
    $BadPaths = @(
        '', '..\version-7\results.json', 'C:\version-7\results.json',
        '\\host\share\version-7\results.json', 'SUITE\version-7\..\evaluation-result-2.json',
        'SUITE\version-7\group.\evaluation-result-2.json', 'SUITE\version-7\CON\evaluation-result-2.json',
        'SUITE\version-7\group\evaluation-result-2.json:stream', 'SUITE\version-7\export-status.json',
        'OTHER\version-8\results.json', 'SUITE\version-8\results.json', 'suite\version-7\results.json',
        ('SUITE\version-7\' + ('x' * 256) + '\evaluation-result-2.json')
    )
    $Texts = @('{}') + @($BadPaths | ForEach-Object { '{}' }) + @('{"ok":true}', $Sentinel)
    $Paths = @('SUITE\version-7\results.json') + $BadPaths + @('SUITE\version-7\group-1\evaluation-result-1.json', '')
    $Context = [ClientContext]::new($Texts, $Paths, @())
    Invoke-Export $Root $Context
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'Partial' -and $Status.errors.Count -eq $BadPaths.Count -and $Status.filesWritten -eq 2) 'Invalid paths must be skipped, recorded, and not block later valid files.'
    Assert-True ([System.IO.File]::ReadAllText($Guard) -ceq 'keep') 'An invalid response modified another suite/version.'
    Assert-True (-not [System.IO.Directory]::Exists((Join-TestPath $Root 'SUITE\version-8'))) 'Cross-version response created a directory.'

    $Root = New-TestRoot 'bad-first-response'
    $Context = [ClientContext]::new(@('{}', '{}', $Sentinel), @('SUITE\version-7\group-1\evaluation-result-1.json', 'SUITE\version-7\results.json', ''), @())
    Invoke-Export $Root $Context
    Assert-True ((Read-Status $Root).status -eq 'Partial') 'A late summary must not erase an earlier protocol failure.'
    Assert-True (@(Get-ChildItem -LiteralPath $Root -Filter 'export-error-*.json').Count -eq 1) 'A failure before the version was known lost its root diagnostic.'

    $Root = New-TestRoot 'empty-stream'
    $Context = [ClientContext]::new(@($Sentinel), @(''), @())
    Invoke-Export $Root $Context
    Assert-True (@(Get-ChildItem -LiteralPath $Root -Filter 'export-error-*.json').Count -eq 1) 'A sentinel without a summary must fail.'

    $Root = New-TestRoot 'invalid-responses'
    $Context = [ClientContext]::new(
        @('{}', '{"overwrite":true}', ' ', '{}', '{"later":true}', $Sentinel),
        @('SUITE\version-7\results.json', 'SUITE\version-7\results.json', 'SUITE\version-7\group-1\evaluation-result-1.json', 'SUITE\version-7\group-1\evaluation-result-2.json', 'SUITE\version-7\group-1\evaluation-result-3.json', ''),
        @()
    )
    $Context.MissingErrorAt = 3
    Invoke-Export $Root $Context
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'Partial' -and $Status.errors.Count -eq 3 -and $Status.filesWritten -eq 2) 'Duplicate, blank, and missing-control responses must not be successful.'
    Assert-RawFile (Join-TestPath $Root 'SUITE\version-7\results.json') '{}'

    $Root = New-TestRoot 'write-error'
    $Context = [ClientContext]::new(
        @('{}', '{}', '{"later":true}', $Sentinel),
        @('SUITE\version-7\results.json', 'SUITE\version-7\group-1\evaluation-result-1.json', 'SUITE\version-7\group-1\evaluation-result-2.json', ''),
        @()
    )
    $Context.OnAction = {
        param($Index)
        if ($Index -eq 1) { [System.IO.Directory]::CreateDirectory((Join-TestPath $Root 'SUITE\version-7\group-1\evaluation-result-1.json')) | Out-Null }
    }
    Invoke-Export $Root $Context
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'Partial' -and $Status.filesWritten -eq 2 -and $Status.errors.Count -eq 1) 'A file write failure must be recorded while allowing later files.'

    $Root = New-TestRoot 'status-write-error'
    $Context = [ClientContext]::new(@('{}', $Sentinel), @('SUITE\version-7\results.json', ''), @())
    $Context.OnAction = {
        param($Index)
        if ($Index -eq 1) {
            $Path = Join-TestPath $Root 'SUITE\version-7\export-status.json'
            Remove-Item -LiteralPath $Path -Force
            [System.IO.Directory]::CreateDirectory($Path) | Out-Null
        }
    }
    Assert-Throws { Invoke-Export $Root $Context } 'Status write failures must surface to the caller.'
    Assert-True (@($script:Messages | Where-Object { $_ -like 'Unable to persist AI Eval export status:*' }).Count -gt 0) 'Status write failure was not explicitly logged.'

    $Root = New-TestRoot 'transient-status-error'
    $Context = [ClientContext]::new(@('{}', $Sentinel), @('SUITE\version-7\results.json', ''), @())
    $Context.OnAction = {
        param($Index)
        if ($Index -eq 1) {
            $script:StatusLock = [System.IO.File]::Open((Join-TestPath $Root 'SUITE\version-7\export-status.json'), [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        }
    }
    $script:OnLog = {
        param($Message)
        if ($Message -like 'Unable to persist AI Eval export status:*' -and $null -ne $script:StatusLock) {
            $script:StatusLock.Dispose()
            $script:StatusLock = $null
        }
    }
    Assert-Throws { Invoke-Export $Root $Context } 'A transient diagnostic failure must surface even if the boundary can persist Partial status.'
    $script:OnLog = $null
    Assert-True ((Read-Status $Root).status -eq 'Partial') 'A retried diagnostic write must not mark the export Completed.'

    $Root = New-TestRoot 'reparse-points'
    $Target = New-TestRoot 'reparse-target'
    $Guard = Join-TestPath $Target 'version-7\keep.json'
    Write-TestFile $Guard 'keep'
    $LinkPath = Join-TestPath $Root 'SUITE'
    $NativeLinkPath = $LinkPath -replace '^\\\\\?\\', ''
    $NativeTarget = $Target -replace '^\\\\\?\\', ''
    New-Item -ItemType Junction -Path $NativeLinkPath -Target $NativeTarget | Out-Null
    $Context = [ClientContext]::new(@('{}', $Sentinel), @('SUITE\version-7\results.json', ''), @())
    Invoke-Export $Root $Context
    Assert-True ([System.IO.File]::ReadAllText($Guard) -ceq 'keep') 'A suite reparse point allowed cleanup outside the output root.'
    Assert-True (@(Get-ChildItem -LiteralPath $Root -Filter 'export-error-*.json').Count -eq 1) 'A refused reparse point needs a diagnostic.'
    [System.IO.Directory]::Delete($LinkPath)

    $Root = New-TestRoot 'max-dataset'
    $SuiteCode = '%' * 10
    $SuiteSegment = '%25' * 10
    $Dataset = 'g' * 255
    $Context = [ClientContext]::new(
        @((New-TestSummary $SuiteCode), $RawEvaluation, $RawTask, $Sentinel),
        @("$SuiteSegment\version-7\results.json", "$SuiteSegment\version-7\$Dataset\evaluation-result-1.json", "$SuiteSegment\version-7\$Dataset\agent-task-details\task-1.json", ''),
        @()
    )
    Invoke-Export $Root $Context $SuiteCode
    $Context.Index = -1
    Invoke-Export $Root $Context $SuiteCode
    Assert-RawFile (Join-TestPath $Root "$SuiteSegment\version-7\$Dataset\evaluation-result-1.json") $RawEvaluation
    Assert-RawFile (Join-TestPath $Root "$SuiteSegment\version-7\$Dataset\agent-task-details\task-1.json") $RawTask
    $Status = Read-Status $Root $SuiteSegment
    Assert-True ($Status.status -eq 'Completed' -and $Status.suiteFolder -ceq $SuiteSegment -and $Status.filesWritten -eq 3) 'A maximum-length dataset changed the suite segment or failed to export.'

    $Root = New-TestRoot 'oversized-suite'
    $Context = [ClientContext]::new(@('{}', $Sentinel), @((('x' * 256) + '\version-7\results.json'), ''), @())
    Invoke-Export $Root $Context
    $Diagnostic = @(Get-ChildItem -LiteralPath $Root -Filter 'export-error-*.json')
    $Status = ConvertFrom-Json ([System.IO.File]::ReadAllText($Diagnostic[0].FullName))
    Assert-True ($Status.status -eq 'Partial' -and $Status.filesWritten -eq 0 -and $Status.errors[0].message -like '*Invalid AI Eval export path component*') 'An oversized suite component did not fail explicitly.'
    Assert-True (@(Get-ChildItem -LiteralPath $Root -Directory).Count -eq 0) 'An oversized suite component created an output directory.'

    $Root = New-TestRoot 'concurrent-version'
    $ConcurrentReleasePath = Join-TestPath $Root 'writer-0-release'
    $ProcessOutputRoot = $Root
    if ($ProcessOutputRoot.StartsWith('\\?\')) { $ProcessOutputRoot = $ProcessOutputRoot.Substring(4) }
    for ($Index = 0; $Index -lt 2; $Index++) {
        $Arguments = @('-NoProfile', '-File', "`"$PSCommandPath`"", '-ConcurrentRoot', "`"$Root`"", '-ConcurrentId', $Index)
        $Process = Start-Process -FilePath $PowerShellPath -ArgumentList $Arguments -PassThru -RedirectStandardOutput (Join-TestPath $ProcessOutputRoot "child-$Index.out") -RedirectStandardError (Join-TestPath $ProcessOutputRoot "child-$Index.err")
        $null = $Process.Handle
        $Processes += $Process
        Wait-TestFile (Join-TestPath $Root "writer-$Index-started")
        if ($Index -eq 0) { Wait-TestFile (Join-TestPath $Root 'writer-0-ready') }
    }
    Start-Sleep -Milliseconds 200
    Assert-RawFile (Join-TestPath $Root 'SUITE\version-7\results.json') '{"suite":"SUITE","version":7,"writer":0}'
    Assert-True ((Read-Status $Root).status -eq 'InProgress') 'A concurrent writer replaced an active version export.'
    [System.IO.File]::WriteAllText($ConcurrentReleasePath, '')
    foreach ($Process in $Processes) { $Process.WaitForExit() }
    $ChildErrors = @(Get-ChildItem -LiteralPath $Root -Filter '*.err' | ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"
    foreach ($Process in $Processes) {
        Assert-True ($Process.ExitCode -eq 0) "Concurrent version writer failed with exit code $($Process.ExitCode). $ChildErrors"
    }
    Assert-RawFile (Join-TestPath $Root 'SUITE\version-7\results.json') '{"suite":"SUITE","version":7,"writer":1}'
    $Status = Read-Status $Root
    Assert-True ($Status.status -eq 'Completed' -and $Status.filesWritten -eq 1 -and $Status.errors.Count -eq 0) 'Serialized version exports did not finish cleanly.'
    Assert-True (@(Get-ChildItem -LiteralPath $Scratch -Recurse -Force -Filter '.ait-*.json').Count -eq 0) 'Atomic status staging files were not cleaned up.'
    Write-Host "Passed $script:Checks AI Eval export regression assertions."
}
finally {
    $script:Clock = $null
    if ($null -ne $script:StatusLock) { $script:StatusLock.Dispose() }
    if ($ConcurrentReleasePath) { [System.IO.File]::WriteAllText($ConcurrentReleasePath, '') }
    foreach ($Process in $Processes) {
        if (-not $Process.HasExited) { $Process.WaitForExit() }
        $Process.Dispose()
    }
    Remove-Item -LiteralPath $Scratch -Recurse -Force -ErrorAction Stop
}

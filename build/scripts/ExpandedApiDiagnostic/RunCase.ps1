param([hashtable]$Parameters, [string]$HelperPath, [string]$Directory)
$ErrorActionPreference = 'Stop'
Import-Module $HelperPath -DisableNameChecking
$started = [DateTime]::UtcNow.ToString('o')
$ticks = [Diagnostics.Stopwatch]::GetTimestamp()
$passed = $false
$transcript = Join-Path $Directory 'original-transcript.log'
try {
    if (Test-Path $Parameters.JUnitResultFileName) { throw 'Original test result already exists; refusing a replay.' }
    Start-Transcript -Path $transcript | Out-Null
    try {
        $passed = Run-TestsInBcContainer @Parameters
    } finally { Stop-Transcript | Out-Null }
    if ((Get-Content $transcript -Raw) -match 'ERROR DIALOG|database command was cancelled') { $passed = $false }
} catch {
    $passed = $false
    throw
} finally {
    if (Test-Path $Parameters.JUnitResultFileName) {
        Copy-Item $Parameters.JUnitResultFileName (Join-Path $Directory 'original.xml')
    } else { $passed = $false }
    @{ attempt = 1; passed = [bool]$passed; codeunitId = $Parameters.testCodeunit; tenant = $Parameters.tenant
        runId = $env:GITHUB_RUN_ID; sourceHead = $env:GITHUB_SHA; container = $Parameters.containerName
        runner = $Parameters.testRunnerCodeunitId; startedUtc = $started; endedUtc = [DateTime]::UtcNow.ToString('o')
        startedTicks = $ticks; endedTicks = [Diagnostics.Stopwatch]::GetTimestamp(); frequency = [Diagnostics.Stopwatch]::Frequency } |
        ConvertTo-Json | Set-Content (Join-Path $Directory 'original-attempt.json')
}
